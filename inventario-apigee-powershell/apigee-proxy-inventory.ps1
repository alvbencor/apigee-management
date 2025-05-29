#!/usr/bin/env bash

$APIGEE_URL=""
$headers = @{
    Authorization = ""
}

$CSV = @()
$proxiesAsociados = @{}
$productosAsociados = @{}

# Obtener developers, entornos y proxies ——
$developers = Invoke-RestMethod -Uri "$APIGEE_URL/developers" -Headers $headers
$environments = Invoke-RestMethod -Uri "$APIGEE_URL/environments" -Headers $headers
$allProxies = Invoke-RestMethod -Uri "$APIGEE_URL/apis" -Headers $headers
$allProducts = Invoke-RestMethod -Uri "$APIGEE_URL/apiproducts" -Headers $headers

Write-Host "Escribiendo apps"

foreach ($developer in $developers) {
    $apps = Invoke-RestMethod -Uri "$APIGEE_URL/developers/$developer/apps" -Headers $headers

    foreach ($app in $apps) {
        $appDetails = Invoke-RestMethod -Uri "$APIGEE_URL/developers/$developer/apps/$app" -Headers $headers

        foreach ($cred in $appDetails.credentials) {
            foreach ($apiproductName in $cred.apiProducts.apiproduct) {

                $productosAsociados[$apiproductName]= $true

                $product = Invoke-RestMethod -Uri "$APIGEE_URL/apiproducts/$apiproductName" -Headers $headers

                foreach ($proxyName in $product.proxies) {
                    $proxiesAsociados[$proxyName] = $true

                    foreach ($environment in $environments) {
                        $kvmName = "ConfigProxy_$proxyName"
                        try {
                            $kvmList = Invoke-RestMethod -Uri "$APIGEE_URL/environments/$environment/keyvaluemaps" -Headers $headers
                            if ($kvmList -contains $kvmName) {
                                $kvmDetails = Invoke-RestMethod -Uri "$APIGEE_URL/environments/$environment/keyvaluemaps/$kvmName" -Headers $headers
                                foreach ($entry in $kvmDetails.entry) {
                                    if ($entry.name -match "url") {

                                        $CSV += [PSCustomObject]@{
                                            App        = $app
                                            Developer  = $developer
                                            APIProduct = $apiproductName
                                            Proxy      = $proxyName
                                            KVM        = $entry.name
                                            Target     = $entry.value
                                        }
                                    }
                                }
                            }
                        } catch {}
                    }
                }
            }
        }
    }
}

# — Productos sin suscribir a apps ——

Write-Host "Escribiendo Productos no asociados a apps"

foreach ($product in $allProducts) {

    if (-not $productosAsociados.ContainsKey($product)) {

        $productFree = Invoke-RestMethod -Uri "$APIGEE_URL/apiproducts/$product" -Headers $headers
    
        foreach ($proxyName in $productFree.proxies) {

            foreach ($environment in $environments) {
            $kvmName = "ConfigProxy_$proxyName"
            try {
                $kvmList = Invoke-RestMethod -Uri "$APIGEE_URL/environments/$environment/keyvaluemaps" -Headers $headers
                if ($kvmList -contains $kvmName) {
                    $kvmDetails = Invoke-RestMethod -Uri "$APIGEE_URL/environments/$environment/keyvaluemaps/$kvmName" -Headers $headers
                    foreach ($entry in $kvmDetails.entry) {
                        if ($entry.name -match "url") {

                            $CSV += [PSCustomObject]@{
                                App        = ""
                                Developer  = ""
                                APIProduct = $product
                                Proxy      = $proxyName
                                KVM        = $entry.name
                                Target     = $entry.value
                            }
                        }
                    }
                }
            } catch {}
        }
        }
    }
}

# —  Proxies sin productos asociados ——

Write-Host "Escribiendo Proxies sin asociar"

foreach ($proxy in $allProxies) {
    if (-not $proxiesAsociados.ContainsKey($proxy)) {
        foreach ($environment in $environments) {
            $kvmName = "ConfigProxy_$proxy"
            try {
                $kvmList = Invoke-RestMethod -Uri "$APIGEE_URL/environments/$environment/keyvaluemaps" -Headers $headers
                if ($kvmList -contains $kvmName) {
                    $kvmDetails = Invoke-RestMethod -Uri "$APIGEE_URL/environments/$environment/keyvaluemaps/$kvmName" -Headers $headers
                    foreach ($entry in $kvmDetails.entry) {
                        if ($entry.name -match "url") {

                            $CSV += [PSCustomObject]@{
                                App        = ""
                                Developer  = ""
                                APIProduct = ""
                                Proxy      = $proxy
                                KVM        = $entry.name
                                Target     = $entry.value
                            }
                        }
                    }
                }
            } catch {}
        }
    }
}
$timestamp = Get-Date -Format "yyyMMdd_HHmmss"

# Exportar CSV
$CSV | Export-Csv -Path ".\inventario_apigee_$timestamp.csv" -Delimiter ";" -NoTypeInformation -Encoding UTF8
Write-Host "Archivo CSV generado: inventario_apigee_PRO_$timestamp.csv"
