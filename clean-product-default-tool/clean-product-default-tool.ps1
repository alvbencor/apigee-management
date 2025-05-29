# Apigee cleanup: filtrar productos '_default' y determinar descartables (PowerShell)

param(
    [string]$APIGEE_URL = "",
    [string]$AUTH_TOKEN = ""
)

# Headers REST
$headers = @{ Authorization = $AUTH_TOKEN }

# 0) Listas y mappings
$developers    = Invoke-RestMethod -Uri "$APIGEE_URL/developers"   -Headers $headers
$allProducts   = Invoke-RestMethod -Uri "$APIGEE_URL/apiproducts" -Headers $headers

# Mappings
$productosAsociados = @{}                 # producto -> $true si está en alguna app
$appsPorProducto    = @{}                 # producto -> lista de apps
$proxiesPorProducto = @{}                 # producto -> lista de proxies

# 1) Recolectar apps, productos y proxies de productos asociados a apps
foreach ($dev in $developers) {
    $apps = Invoke-RestMethod -Uri "$APIGEE_URL/developers/$dev/apps" -Headers $headers
    foreach ($app in $apps) {
        $appDetails = Invoke-RestMethod -Uri "$APIGEE_URL/developers/$dev/apps/$app" -Headers $headers
        foreach ($cred in $appDetails.credentials) {
            foreach ($prod in $cred.apiProducts.apiproduct) {
                # Marcar producto como asociado a app
                $productosAsociados[$prod] = $true
                # Trackear apps por producto
                if (-not $appsPorProducto.ContainsKey($prod)) { $appsPorProducto[$prod]=[System.Collections.ArrayList]@() }
                if (-not $appsPorProducto[$prod].Contains($app)) { $appsPorProducto[$prod].Add($app)|Out-Null }
                # Obtener proxies del producto
                $detail = Invoke-RestMethod -Uri "$APIGEE_URL/apiproducts/$prod" -Headers $headers
                if (-not $proxiesPorProducto.ContainsKey($prod)) { $proxiesPorProducto[$prod]=[System.Collections.ArrayList]@() }
                foreach ($proxy in $detail.proxies) {
                    if (-not $proxiesPorProducto[$prod].Contains($proxy)) { $proxiesPorProducto[$prod].Add($proxy)|Out-Null }
                }
            }
        }
    }
}

# 2) Completar proxiesPorProducto para productos no asociados (sin apps)
foreach ($prod in $allProducts) {
    if (-not $productosAsociados.ContainsKey($prod)) {
        $detail = Invoke-RestMethod -Uri "$APIGEE_URL/apiproducts/$prod" -Headers $headers
        if (-not $proxiesPorProducto.ContainsKey($prod)) { $proxiesPorProducto[$prod]=[System.Collections.ArrayList]@() }
        foreach ($proxy in $detail.proxies) {
            if (-not $proxiesPorProducto[$prod].Contains($proxy)) { $proxiesPorProducto[$prod].Add($proxy)|Out-Null }
        }
    }
}

# 3) Construir mapping inverso proxy -> productos
$productosPorProxy = @{}
foreach ($prod in $proxiesPorProducto.Keys) {
    foreach ($proxy in $proxiesPorProducto[$prod]) {
        if (-not $productosPorProxy.ContainsKey($proxy)) { $productosPorProxy[$proxy]=[System.Collections.ArrayList]@() }
        if (-not $productosPorProxy[$proxy].Contains($prod)) { $productosPorProxy[$proxy].Add($prod)|Out-Null }
    }
}

# 4) Filtrar solo productos '..._default'
$defaultProdAll = $allProducts | Where-Object { $_ -match '_default$' }

# 5) Evaluar cada producto '_default'
$resultados = @()
foreach ($prod in $defaultProdAll) {
    $base    = $prod -replace '_default$',''
    $apps    = @()
    $proxies = $proxiesPorProducto[$prod]
    $isAssoc = $productosAsociados.ContainsKey($prod)
    if ($isAssoc) { $apps = $appsPorProducto[$prod] }

    # Inicializar descartable y razón
    $desc   = $false
    $reason = ''

    if ($isAssoc) {
        # Asociado a alguna app -> no descartable
        $desc   = $false
        $reason = 'Producto está asociado a apps'
    } else {
        if ($proxies.Count -eq 0) {
            # Sin proxies
            $desc   = $true
            $reason = 'No tiene proxies'
        }
        elseif ($proxies.Count -eq 1 -and $proxies[0] -eq $base) {
            # Un único proxy igual al base
            $subsCount = $productosPorProxy[$base].Count
            if ($subsCount -eq 0) {
                $desc   = $true
                $reason = 'Su proxy base no está suscrito a ningún producto (subsCount=0)'
            }
            elseif ($subsCount -gt 1) {
                $desc   = $true
                $reason = "Proxy base compartido con otros productos (subsCount=$subsCount)"
            }
            else {
                # SubsCount == 1 -> único en este producto, no descartable
                $desc   = $false
                $reason = 'Único proxy base suscrito sólo a este producto'
            }
        }
        else {
            # Múltiples proxies o mismatch -> no se evalúa para CSV
            continue
        }
    }

    # Agregar al arreglo de resultados
    $resultados += [PSCustomObject]@{
        Producto    = $prod
        Apps        = if ($apps) { $apps -join ',' } else { '' }
        Proxies     = if ($proxies) { $proxies -join ',' } else { '' }
        Descartable = if ($desc) { 'Yes' } else { 'No' }
        Razon       = $reason
    }
}

# 6) Exportar CSV
$ts      = Get-Date -Format 'yyyyMMdd_HHmm'
$csvFile = "productos_default_inventario_$ts.csv"
$resultados | Export-Csv -Path $csvFile -Delimiter ';' -NoTypeInformation -Encoding UTF8
Write-Host "CSV generado: $csvFile"

# 7) Resumen
$totalDesc = ($resultados | Where-Object { $_.Descartable -eq 'Yes' }).Count
Write-Host "Total de productos descartables: $totalDesc"
