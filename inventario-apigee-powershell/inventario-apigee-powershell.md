# Inventario de APIs en Apigee

Este script PowerShell genera un CSV con el inventario de proxies y productos de Apigee, detallando qué apps los usan, el developer de la app, y exponiendo las URLs configuradas en los KVM correspondientes.

---

## Requisitos

- **PowerShell 5.1+** (Windows) o **PowerShell Core 6+** (Linux/macOS)
- Módulo **`Invoke-RestMethod`** disponible (parte del núcleo de PowerShell)
- Acceso de red al endpoint de Apigee
- Variables de entorno o parámetros para:
  - `APIGEE_URL` (p. ej. `https://api.enterprise.apigee.com/v1/organizations/MI_ORG`)
  - `headers` con la cabecera `Authorization: Basic BASE64(user:pass)`

---

## Variables de configuración

Antes de ejecutar el script, exporta o define estas dos variables:

```powershell
# URL base de la organización en Apigee
$APIGEE_URL    = 'https://api.enterprise.apigee.com/v1/organizations/MiOrganizacion'

# Encabezados HTTP para autenticación
# Debe incluirse la línea: @{ 'Authorization' = 'Basic BASE64(user:pass)' }
$headers = @{
  'Authorization' = 'Basic <base64(apigeeUser:apigeepassword)>'
}
```

---

## Cómo ejecutar

Descarga `inventario-apigee-powershell.ps1`, y ejecútalo desde PowerShell:

```powershell
.\inventario-apigee-powershell.ps1
```

El script desplegará mensajes en pantalla indicando:
- “Escribiendo apps”
- “Escribiendo Productos no asociados a apps”
- “Escribiendo Proxies sin asociar”

Y al final mostrará:

```
Archivo CSV generado: inventario_apigee_<timestamp>.csv
```

El fichero se creará en el directorio actual al finalizar el script. 

---

## Qué hace el script

1. **Recoge**:
   - Todos los _developers_.
   - Todos los _entornos_.
   - Todos los _proxies_ y _API products_.

2. **Asocia**:
   - Recorre cada developer y sus apps, luego cada producto de cada app y sus proxies asociadas.
   - Para cada proxy, busca en cada entorno el KVM `ConfigProxy_<proxy>` y extrae las entradas que contengan “url”.

3. **Añade** al CSV:
   - **Filas completas** (`App;Developer;APIProduct;Proxy;KVM;Target`) para proxies asociados a apps.
   - **Filas parciales** (`;;APIProduct;Proxy;KVM;Target`) para productos no suscritos a apps.
   - **Filas mínimas** (`;;;Proxy;KVM;Target`) para proxies no asociados a ningún producto ni app.

4. **Exporta** el array PowerShell a CSV con delimitador `;` y codificación UTF-8.

---

## Ejemplo de salida

```csv
App;Developer;APIProduct;Proxy;KVM;Target
MyApp;alice@example.com;OrderAPI;order-proxy;urlEndpoint;https://orders.example.com
;;BillingAPI;billing-proxy;urlEndpoint;https://billing.example.com
;;;legacy-proxy;urlEndpoint;https://legacy.example.com
```

---

## Notas

- El script ignora errores en llamadas a KVM ausentes (`try { … } catch {}`).
- El timestamp en el nombre de fichero sigue el formato `yyyyMMdd_HHmmss`.
- Ajusta permisos del archivo si lo distribuyes en un repositorio.
- la salida está optiizada para leerse comodamente con el [front de este repositorio.](https://github.com/alvbencor/apigee-management/blob/main/api-inventory-filter-front/readme.md) 
