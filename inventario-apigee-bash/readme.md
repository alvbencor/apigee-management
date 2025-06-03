# API Inventory Shell Script

Este script recopila información de aplicaciones (Apps), desarrolladores (Developers), productos de API (APIProducts), proxies (Proxies) y valores de KVM (Key-Value Maps) en un entorno de Apigee, y genera un CSV con la siguiente cabecera:

```
App;Developer;APIProduct;Proxy;KVM;Target
```

A continuación se explican los detalles para su uso.

---

## 1. Descripción general

1. Se obtiene la lista de entornos (`environments`) configurados en Apigee.  
2. Se obtiene la lista de desarrolladores (`developers`) registrados en Apigee.  
3. Se obtiene la lista de todos los proxies (`allProxies`) y de todos los productos de API (`allProducts`).  
4. Para cada desarrollador:
   - Se listan todas sus aplicaciones (Apps).  
   - Para cada App, se extraen los productos de API (APIProducts) a los que está suscrita.  
   - Para cada APIProduct asociado, se extraen los proxies configurados.  
   - Para cada proxy vinculado, se busca en cada entorno un Key-Value Map llamado `ConfigProxy_<proxy>`.  
     - Si existe, se recorren sus entradas.  
     - Si el nombre de la entrada coincide (case-insensitive) con “url” (por ej. `targetUrl`, `secondUrl`, etc.), se obtiene el valor y se escribe una línea en el CSV con `App;Developer;APIProduct;Proxy;KVM;Target`.  
5. Se identifican los productos (APIProducts) que **no** están asociados a ninguna App:  
   - Para cada uno, se extraen sus proxies configurados.  
   - A cada proxy extraído, se realiza el mismo procedimiento de KVM por entorno.  
   - Se registra cada línea en el CSV dejando App y Developer como `---`.  
6. Se identifican los proxies que **no** están asociados ni a Apps ni a productos:  
   - Para cada proxy “huérfano”, se busca en cada entorno el Key-Value Map `ConfigProxy_<proxy>`.  
   - Si existe, se recorren sus entradas “url” y se registran con `App;Developer;APIProduct` igual a `---`.  

Al final, se genera un archivo CSV con timestamp en el nombre:  
```
resultado_YYYYMMDD_HHMM.csv
```

---

## 2. Requisitos previos

- **Sistema operativo**: Linux / macOS / WSL (soporta bash).  
- **Herramientas necesarias**:
  - `bash` (versión moderna, compatible con `set -euo pipefail`).  
  - `wget` (para realizar peticiones HTTPS).  
  - `jq` (para parsear JSON).  
  - `date` (para generar timestamp).  
- **Credenciales Apigee**:
  - Variable `APIGEE_URL`: URL base de la API de Apigee (por ejemplo `https://api.enterprise.apigee.com/v1`).  
  - Variable `AUTH`: credenciales en Base64 para la cabecera `Authorization: Basic <AUTH>`.  

---

## 3. Configuración

1. **Asignar permisos**  
   El script debe ser ejecutable. Ejecute:
   ```bash
   chmod +x collect_inventory.sh
   ```

2. **Configurar variables de entorno**  
   Antes de ejecutar, exporte las siguientes variables (o modifíquelas directamente en el script):
   ```bash
   export APIGEE_URL="https://api.enterprise.apigee.com/v1"
   export AUTH="TU_CREDENCIAL_BASE64"
   ```
   - `APIGEE_URL`: sustituya por la URL de su organización Apigee (sin espacios finales).  
   - `AUTH`: credencial codificada en Base64 con formato `username:password` para Apigee. Ejemplo:
     ```bash
     export AUTH=$(echo -n "usuario:contraseña" | base64)
     ```

---

## 4. Uso

```bash
./collect_inventory.sh
```

Al ejecutarlo, se irán mostrando en pantalla mensajes de progreso como:
- `Recorremos apps`
- `Productos sin asociar`
- `proxies sin asociar`

Y se generará, en el directorio actual, el fichero:
```
resultado_YYYYMMDD_HHMM.csv
```
donde `YYYYMMDD_HHMM` corresponde a la fecha y hora de ejecución.

---

## 5. Estructura del CSV de salida

El CSV resultante está separado por `;` y tiene la siguiente cabecera:

```
App;Developer;APIProduct;Proxy;KVM;Target
```

- **App**: nombre de la aplicación (de un desarrollador).  
- **Developer**: dirección de correo del desarrollador.  
- **APIProduct**: nombre del producto de API al que está suscrita la App.  
- **Proxy**: nombre del proxy asociado al producto de API.  
- **KVM**: nombre de la entrada del Key-Value Map (por ejemplo `targetUrl`, `secondUrl`, etc.).  
- **Target**: valor de la entrada “url” dentro del Key-Value Map.

Para productos no asociados a ninguna App, los campos `App` y `Developer` aparecen como `---`.  
Para proxies no asociados ni a Apps ni a productos, `App`, `Developer` y `APIProduct` aparecen como `---`.

Ejemplo de líneas del CSV:

```
miApp;dev@example.com;MiProductoAPI;MiProxy;targetUrl;example.com/service
---;---;OtroProducto;/OtroProxy;secondUrl;nr-otroproxy.aws.example.com
---;---;---;/ProxyHuérfano;url;micro-proxy.internal.local
```

---

## 6. Detalle de pasos internos

1. **Obtener entornos**  
   ```bash
   wget --quiet --no-check-certificate      --header="Authorization: Basic $AUTH"      -O - "$APIGEE_URL/environments"
   ```
   Se guarda en `environmentsJson` y luego cada entorno se extrae para iterar.

2. **Obtener desarrolladores**  
   ```bash
   wget --quiet --no-check-certificate      --header="Authorization: Basic $AUTH"      -O - "$APIGEE_URL/developers"
   ```
   Se almacena en el array `developers`.

3. **Obtener todos los proxies**  
   ```bash
   wget --quiet --no-check-certificate      --header="Authorization: Basic $AUTH"      -O - "$APIGEE_URL/apis"
   ```
   Se guarda la lista en `allProxies`.

4. **Obtener todos los productos**  
   ```bash
   wget --quiet --no-check-certificate      --header="Authorization: Basic $AUTH"      -O - "$APIGEE_URL/apiproducts"
   ```
   Se guarda la lista en `allProducts`.

5. **Recorrer cada desarrollador para extraer sus Apps**  
   - Para cada `dev` en `developers`:
     ```bash
     wget --quiet --no-check-certificate        --header="Authorization: Basic $AUTH"        -O - "$APIGEE_URL/developers/$dev/apps"
     ```
     → obtiene lista de Apps (`appsList`).

6. **Para cada App, obtener productos asociados**  
   ```bash
   wget --quiet --no-check-certificate      --header="Authorization: Basic $AUTH"      -O - "$APIGEE_URL/developers/$dev/apps/$app"
   ```
   → En `appDetails` está la sección `credentials[].apiProducts[].apiproduct`.

7. **Para cada producto, obtener proxies asociados**  
   ```bash
   wget --quiet --no-check-certificate      --header="Authorization: Basic $AUTH"      -O - "$APIGEE_URL/apiproducts/$product"
   ```
   → Extrae `proxies[]`.

8. **Para cada proxy asociado, buscar Key-Value Map `ConfigProxy_<proxy>` en cada entorno**  
   - Primero lista KVMs:
     ```bash
     wget --quiet --no-check-certificate        --header="Authorization: Basic $AUTH"        -O - "$APIGEE_URL/environments/$env/keyvaluemaps/"
     ```
     → Si `ConfigProxy_<proxy>` existe, se obtiene:
     ```bash
     wget --quiet --no-check-certificate        --header="Authorization: Basic $AUTH"        -O - "$APIGEE_URL/environments/$env/keyvaluemaps/ConfigProxy_$proxy"
     ```
     → Extrae `entry[] .name`.
   - Para cada `entry` cuyo nombre coincide con `/url/i`, se solicita:
     ```bash
     wget --quiet --no-check-certificate        --header="Authorization: Basic $AUTH"        -O - "$APIGEE_URL/environments/$env/keyvaluemaps/ConfigProxy_$proxy/entries/$entry"
     ```
     → En `url[]` está el valor real.

9. **Registrar línea en CSV**  
   - Si el proxy pertenece a un producto y a una App, se escriben:  
     ```
     App;Developer;APIProduct;Proxy;KVM;Target;
     ```
   - Si el producto no estaba asociado a ninguna App, se usa `---;---;APIProduct;Proxy;KVM;Target`.  
   - Si el proxy no estaba asociado a ningún producto ni App, se usa `---;---;---;Proxy;KVM;Target`.

10. **Productos huérfanos (no asociados a Apps)**  
    - Se compara `allProducts` con `associatedProducts`.  
    - Los que no se hayan visto quedan en `nonAssociatedProducts`.  
    - Para cada uno, se repite el paso de obtener proxies y KVMs, dejando `App` y `Developer` como `---`.

11. **Proxies huérfanos (no asociados ni a Apps ni a productos)**  
    - Se compara `allProxies` con `associatedProxies`.  
    - Los que no se hayan visto quedan en `nonAssociatedProxies`.  
    - Para cada proxy huérfano, se busca su KVM en cada entorno y se registra con `App;Developer;APIProduct` igual a `---`.

---

## 7. Ejemplo de ejecución

```bash
# Asignar permisos al script (solo la primera vez)
chmod +x collect_inventory.sh

# Definir variables de entorno
export APIGEE_URL="https://api.enterprise.apigee.com/v1"
export AUTH=$(echo -n "usuario:contraseña" | base64)

# Ejecutar
./collect_inventory.sh
```

Salida esperada en terminal:
```
Recorremos apps
... (varias líneas de progreso)
Productos sin asociar
... (varias líneas de progreso)
proxies sin asociar
... (varias líneas de progreso)
```
Archivo generado:  
```
resultado_20230815_1430.csv
```

---

## 8. Notas y recomendaciones

- **Errores comunes**:
  - Si `jq` no está instalado, saldrá un error al intentar parsear JSON.
  - Si `wget` no puede conectarse a la URL, revise `APIGEE_URL` y credenciales.
  - Para endpoints con certificados autofirmados, se usa `--no-check-certificate`, pero en producción conviene usar certificados válidos.
- **Ajustes**:
  - Para cambiar nombre de KVM (si no sigue el patrón `ConfigProxy_`), modifique las comprobaciones `grep -qx "ConfigProxy_$proxy"`.
  - Si Apigee devuelve grandes volúmenes de datos, considere paginación u optimización de llamadas.
- **Formato del CSV**:
  - Separador `;`.  
  - Cada línea finaliza en `;` (puede editarse si no se desea el último delimitador).
