![Preview](https://github.com/alvbencor/apigee-management/b64-csr-tool/img/b64-csr-tool.png)
# b64 Converter + CSR Generator

Esta herramienta es una aplicación web ligera en una sola pagina que ofrece las siguientes funcionalidades:

1. **Codificar y Decodificar Base64**
2. **Decodificar CSR (Certificate Signing Request)**
3. **Mostrar tamaño y exponente de Private Key RSA**
4. **Generar cadena `Usuario:Contraseña` en Base64**
5. **Generar CSR y Private Key RSA, y descargarlos en un ZIP**

---

## Tecnologías usadas

- **HTML5**
- **JavaScript (ES6+)**
- **[JSZip](https://stuk.github.io/jszip/)** para empaquetar CSR y clave en ZIP
- **[node-forge](https://github.com/digitalbazaar/forge)** para manejo de claves y CSR

---

## Estructura de la interfaz

- Un selector `mode` para elegir operación:
  - `Codificar Base64`
  - `Decodificar Base64`
  - `Decodificar CSR`
  - `Tamaño Private Key`
  - `Usuario:Password` (genera Base64 de `usuario:contraseña`)
- Un área de texto para entrada de datos (`inputText`).
- Campos extra para usuario y contraseña en modo `userpass`.
- Botón **Procesar** para ejecutar la operación.
- Área de resultado con textarea clicable para copiar al portapapeles.
- Sección **CSR generator**:
  - Selector `csrType` (público o privado).
  - Campo `dns` para especificar el Common Name.
  - Botón **Descargar CSR + Private KEY (ZIP)**.

---

## Instalación y uso

1. Clona o descarga los archivos en tu servidor o carpeta local.
2. Abre `index.html` en tu navegador preferido (no requiere servidor si todas las rutas CDN cargan correctamente).
3. Selecciona la operación deseada en la primera sección:
   - Para Base64, pega el texto y haz clic en **Procesar**.
   - Para CSR/Key decoding, pega el PEM y procesa.
   - Para generar usuario:password, ingresa credenciales y procesa.
4. Para generar un CSR + clave:
   1. Elige **Público** o **Privado**.
   2. Indica el **DNS** (Common Name).
   3. Haz clic en **Descargar CSR + Private KEY (ZIP)**.

---

## Personalización

- **Colores y estilos**: modifica las reglas CSS en `<style>`.
- **Metadatos del CSR**: edita el arreglo `csr.setSubject([...])` para cambiar campos como organización, localidad, país o correo.
- **Tipo y tamaño de clave**: ajusta `bits: 2048` en la llamada a `forge.pki.rsa.generateKeyPair` según tus necesidades.

---

## Compatibilidad

- Funciona en los principales navegadores modernos (Chrome, Firefox, Edge, Safari).
- Requiere conexión a los CDN de **JSZip** y **node-forge**, o puedes descargar localmente esas librerías.

---
