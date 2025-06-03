# api-inventory-filter-front

**`api-inventory-filter-front`** es una herramienta web de código abierto diseñada para visualizar, filtrar y explorar la relación completa entre **Apps**, **Developers**, **Products**, **Proxies**, **KVMs** y **Targets** de todas las APIs. Permite:

- Mostrar en una tabla jerárquica (con `rowspan`) la estructura App → Producto → Proxy → (KVM, Target).  
- Filtrar por campos individuales (cada columna) o por categorías de producto.  
- Detectar “Productos huérfanos” (aquellos sin proxies asociados).  
- Detectar “Productos _default_” que deberían haberse eliminado.  

Gracias a su interfaz sencilla de arrastrar/soltar (drag & drop) o carga desde URL, es ideal para analizar inventarios de APIs en formato CSV.




## 📋 Características principales

1. **Carga de CSV por Drag & Drop o Selector de Archivo**  
   - Arrastra un archivo `.csv` sobre la zona de carga o haz clic para seleccionarlo desde tu disco.  
2. **Carga desde URL**  
   - Introduce una URL HTTP(S) que apunte a un CSV público. Se convierte a `Blob` y se parsea con [PapaParse](https://www.papaparse.com/).  
3. **Vista jerárquica con rowspan**  
   - **App** (cubre todas las filas pertenecientes a esa app).  
   - **Developer** (se agrupa junto a la App).  
   - **APIProduct** (cubre todas las filas de ese producto).  
   - **Proxy** (cubre todas las filas KVM/Target asociadas).  
   - **KVM** y **Target** se muestran en columnas individuales.  
4. **Filtrado por Producto** (radios)  
   - **Todo**: muestra todas las filas.  
   - **Sólo productos sin app**: `App === ''`  
   - **Sólo proxies sin producto**: `APIProduct === ''`  
   - **Productos huérfanos**: productos que no tienen ningún proxy asociado.  
   - **Productos descartables**: productos que acaban en `_default`, sin Apps asociadas y cuyo único proxy coincide (sin `_default`).  
5. **Filtrado por Campo** (checkboxes + búsqueda global)  
   - Elige qué columnas incluir en la búsqueda global (Apps, Developers, Productos, Proxies, KVM, Target).  
   - Botones “Seleccionar todos” / “Deseleccionar todos”.  
6. **Búsqueda por Columna (Cabeceras)**  
   - Al hacer clic en una cabecera (`<th>`), aparece un `<input>` para filtrar exclusivamente esa columna.  
   - Automáticamente se marca el checkbox de esa columna y se borra el buscador global.  
   - Solo hay un input abierto a la vez: al abrir uno nuevo, se cierra (y limpia) cualquier otro.  
7. **Conteo Dinámico (“Resultado de búsqueda: X apps, Y productos, Z proxies”)**  
   - Se muestra junto a los botones “Copiar tabla” / “Exportar a CSV”.  
   - Emplea singular/plural según corresponda (1 app vs. 2 apps, 1 proxy vs. 3 proxies).  
8. **Copia al Portapapeles**  
   - Botón “Copiar tabla” genera HTML + texto plano (tabulado) y lo escribe en el portapapeles.  
9. **Exportar a CSV**  
   - Botón “Exportar a CSV” toma el contenido filtrado (array `filtered`) y lo descarga como CSV separado por `;`.  




## 🚀 Cómo ejecutar

1. **Abrir el archivo HTML en el navegador**  
   - Simplemente abre `api-inventory-filter-front.html` con tu navegador preferido (Chrome, Firefox, Edge, etc.).  
   - No se necesita servidor local: es un proyecto estático.  
   - 
2. **Importa el CSV con los datos**  
   - Puedes encontrar el mock `inventarioCSVmock.csv` en la carpeta de este proyecto.  




## 📂 Estructura de archivos

```
api-inventory-filter-front/
├── api-inventory-filter-front.html
├── inventarioCSVmock.csv
└── README.md               ← (esta documentación)
```

- **`api-inventory-filter-front.html`**: Archivo principal. Incluye todo el HTML, CSS y JavaScript necesarios (sin dependencias de compilación).  
- **`inventarioCSVmock.csv`**: Ejemplo de inventario que contiene columnas y datos mock para testear.



## 🔧 Detalles de implementación

- **PapaParse**


  PapaParse es una librería JavaScript de código abierto diseñada para leer y procesar archivos CSV (Comma-Separated Values) de forma eficiente, tanto en navegadores como en entornos Node.js
  Se incluye vía CDN:  
  ```html
  <script src="https://unpkg.com/papaparse@5.4.1/papaparse.min.js"></script>
  

## 📖 Uso básico

1. **Abrir `api-inventory-filter-front.html`** en tu navegador (no se requiere servidor).  
2. **Cargar CSV**:  
   - Opción A: Arrastra `inventarioCSVmock.csv` sobre la zona punteada.  
   - Opción B: Haz clic en la zona, selecciona el archivo desde tu disco.  
   - Opción C: Copia una URL pública que apunte al CSV (por ejemplo, un raw de GitHub) y haz clic en “Cargar inventario”.  
3. **Explorar tabla**:  
   - Observa la jerarquía: App → Developer → Producto → Proxy → (KVM / Target).  
4. **Filtrar**:  
   - **Radios “Filtrado por producto”**: selecciona la casilla deseada (ej. “Productos huérfanos”).  
   - **Checkboxes** (“Filtrado por campo”): marca/desmarca columnas para la búsqueda global.  
   - **Buscar global**: escribe un texto que aparezca en alguna de las columnas habilitadas.  
   - **Buscar por columna**: haz clic en un `<th>`, escribe el término en ese input, y observa cómo filtra solo esa columna.  
5. **Acciones**:  
   - “Copiar tabla” añade al portapapeles la tabla completa (HTML + texto tabulado).  
   - “Exportar a CSV” descarga un archivo CSV con el contenido filtrado.  
