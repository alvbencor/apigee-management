# Documentación del script PowerShell: Apigee cleanup de productos `_default`

Este documento describe el uso, la configuración y el funcionamiento interno del script PowerShell que filtra productos terminados en `_default` en Apigee, determinando cuáles pueden ser descartados.

---

## 1. Propósito

Identificar en tu organización Apigee todos los **API Products** que:

* Terminan en `_default`.
* No están asociados a ninguna **app**.
* Tienen o no tienen proxies, y si sus proxies coinciden con su nombre base.

Genera un CSV con las siguientes columnas:

| Campo           | Descripción                                                                     |
| --------------- | ------------------------------------------------------------------------------- |
| **Producto**    | Nombre del API Product (`*_default`).                                           |
| **Apps**        | Lista de apps que usan este producto (vacío si no está suscrito a apps).        |
| **Proxies**     | Lista de proxies suscritos a este producto (puede estar vacío).                 |
| **Descartable** | `Yes` si el producto se podría eliminar según criterios; `No` en caso contrario. |
| **Razon**       | Motivo por el que se considera descartable o no.                                |

En cualquier caso se recomienda hacer un doble check en la documentacion de los despliegues oportunos. 

---

## 2. Parámetros

| Parámetro     | Tipo   | Descripción                                                                           | Requerido |
| ------------- | ------ | ------------------------------------------------------------------------------------- | :-------: |
| `$APIGEE_URL` | String | URL base del API Management de Apigee (e.g., `https://api.enterprise.apigee.com/v1`). |     Sí    |
| `$AUTH_TOKEN` | String | Token de autorización o credenciales en formato `Basic ...`.                          |     Sí    |

Invocación típica:

```powershell
.\\cleanup_default.ps1 -APIGEE_URL "https://api.enterprise.apigee.com/v1" -AUTH_TOKEN "Basic ABC..."
```

---

## 3. Flujo de ejecución

1. **Carga de datos**

   * Obtiene la lista de developers y de todos los API Products.

2. **Recorrido de productos asociados a apps**

   * Para cada developer y cada app: marca productos como asociados y guarda qué apps usan cada producto.
   * Para cada producto asociado: obtiene y almacena sus proxies.

3. **Proxies de productos no asociados**

   * Para los productos que no están en ninguna app, consulta sus proxies.

4. **Mapping inverso proxy → productos**

   * Construye un diccionario que, dada cada proxy, lista los productos que lo usan.

5. **Filtrado de productos `_default` y lógica de descarte**

   * Para cada producto `_default` se determina:

     * Si está asociado a apps → **No descartable**.
     * Si no está asociado:

       * **Sin proxies** → *Descartable* (`No tiene proxies`).
       * **Un único proxy igual a nombre base**:

         * Suscrito a 0 o >1 productos → *Descartable*.
         * Suscrito solo a este producto → *No descartable*.
       * **Otros casos** (múltiples proxies o mismatch de nombre) → se omiten.

6. **Generación del CSV y resumen final**

   * Exporta `productos_default_inventario_<timestamp>.csv` con columnas `Producto;Apps;Proxies;Descartable;Razon`.
   * Muestra en consola el total de productos descartables.

---

## 4. Ejemplo de salida CSV

```csv
Producto;Apps;Proxies;Descartable;Razon
miAPI_default; ; ;Yes;No tiene proxies
otroAPI_default;app1,app2;otroAPI;No;Producto está asociado a apps
test_default; ;test;Yes;Proxy base compartido con otros productos (subsCount=2)
```

---

## 5. Consideraciones

* **Credenciales**: Usa un token con permisos de lectura en Apigee.
* **Rendimiento**: En organizaciones con muchos developers/apps/products el script puede tardar. Valora ejecutar por entorno o en paralelo.
* **Extensibilidad**: Puedes adaptar los criterios de descarte en el `switch` de la sección 5.

---

> **Nota**: Ajusta rutas y parámetros según tu entorno. Este script es de ejemplo y debe probarse en entornos de staging antes de usar en producción.
