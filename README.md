# Proxy Inventory Script

Este repositorio contiene un script en **PowerShell** para generar un inventario completo de tus Apps, API Products, Proxies y entradas KVM (KeyValueMap) en Apigee, incluyendo aquellos productos o proxies que no estén asociados a ninguna App.

## Descripción

`apigee-inventory.ps1` automatiza el mapeo de:

1. **Developers** y sus **Apps**.
2. **API Products** vinculados a cada App.
3. **Proxies** asociados a cada Product.
4. **Entradas KVM** cuyo nombre contenga `url`, que representan las URL destino activas.
5. **Productos y Proxies no asociados a Apps**, para asegurar cobertura completa.

El resultado se vuelca en un archivo **CSV** (`inventario_apigee_YYYYMMDD_HHmmss.csv`) con columnas:

- `App`
- `Developer`
- `APIProduct`
- `Proxy`
- `KVM` (nombre de la entrada)
- `Target` (valor de la entrada)

## Requisitos

- **PowerShell 5.1** (Windows) o **PowerShell Core 7+** (multiplataforma)
- Conexión de red al API de gestión de Apigee
- Permisos adecuados para leer Apps, Products, Proxies y KVMs

## Instalación y configuración

1. Clona este repositorio o descarga el script:
   ```powershell
   git clone https://github.com/tu-org/apigee-management.git
   cd apigee-management
   ```
2. Edita la parte superior de `apigee-proxy-inventory.ps1` y configura:
   ```powershell
   # URL base de tu organización Apigee
   $APIGEE_URL = 'https://api.enterprise.apigee.com/v1/organizations/tu-org'

   # Cabecera Authorization: Basic <base64(usuario:contraseña)>
   $headers = @{ Authorization = 'Basic QWxhZGRpbjpPcGVuU2VzYW1l' }
   ```
3. (Opcional) Ajusta el formato de timestamp o la ruta de salida si lo deseas.

## Uso

Desde PowerShell, en la carpeta del script:

```powershell
# Ejecutar el inventario
apigee-proxy-inventory.ps1
```

Al finalizar, verás en la consola un mensaje con la ruta del CSV generado.

## Ejemplo de salida CSV

```csv
App;Developer;APIProduct;Proxy;KVM;Target
myApp;alice@example.com;MyProduct;ordersProxy;urlEndpoint;https://backend.example.com/v1/orders
---;---;UnassignedProd;billingProxy;urlEndpoint;https://billing.example.com/api
---;---;---;auditProxy;urlEndpoint;https://audit.example.com/log
```

- Las filas con `---` en las primeras columnas corresponden a productos o proxies sin Apps asociadas.

## Manejo de errores y casos especiales

- El script detiene la ejecución en caso de errores HTTP o variables no definidas (`set -euo pipefail`).
- Usa `Invoke-RestMethod` que lanza excepciones en códigos de estado distintos de 2xx.
- Omite silenciosamente mapas o entradas KVM inexistentes mediante bloques `try/catch {}`.

## Futuras mejoras

- Publicación automática del CSV en Confluence o SharePoint.
- Integración con alarmas o notificaciones (Mail, Teams, Slack).  
- Versión que incluya recarga incremental y caché local.

## Contribuciones

1. Haz fork de este repositorio.
2. Crea una rama de característica: `git checkout -b feature/nombre-caracteristica`.
3. Añade y prueba tus cambios.
4. Haz commit con un mensaje descriptivo.
5. Abre un Pull Request.

Por favor sigue el estilo del script y añade comentarios en cada función nueva.
