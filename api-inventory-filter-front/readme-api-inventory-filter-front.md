# api-inventory-filter-front

**`api-inventory-filter-front`** es una herramienta web de código abierto diseñada para visualizar, filtrar y explorar la relación completa entre **Apps**, **Developers**, **Products**, **Proxies**, **KVMs** y **Targets** de todas las APIs. Permite:

- Mostrar en una tabla jerárquica (con `rowspan`) la estructura App → Producto → Proxy → (KVM, Target).  
- Filtrar por campos individuales (cada columna) o por categorías de producto.  
- Detectar “Productos huérfanos” (aquellos sin proxies asociados).  
- Detectar “Productos _default_” que deberían haberse eliminado.  

Gracias a su interfaz sencilla de arrastrar/soltar (drag & drop) o carga desde URL, es ideal para analizar inventarios de APIs en formato CSV (separado por `;`).

---

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

---

## 🚀 Cómo ejecutar

1. **Clona o descarga el repositorio**  
   ```bash
   git clone https://github.com/tu-usuario/api-inventory-filter-front.git
   cd api-inventory-filter-front
   ```

2. **Asegúrate de tener el archivo mock en la misma carpeta**  
   - Coloca `inventarioCSVmock.csv` (en la raíz del proyecto).  

3. **Abrir el archivo HTML en el navegador**  
   - Simplemente abre `api-inventory-filter-front.html` con tu navegador preferido (Chrome, Firefox, Edge, etc.).  
   - No se necesita servidor local: es un proyecto estático.  

4. **Probar con el CSV mock**  
   - Dentro de la carpeta del proyecto, arrastra `inventarioCSVmock.csv` sobre la zona “Arrastra tu CSV o haz clic”  
   - O, en lugar de arrastrar, haz clic en la zona blanca y selecciona el archivo `inventarioCSVmock.csv` desde el diálogo de archivos.  

---

## 📂 Estructura de archivos

```
api-inventory-filter-front/
├── api-inventory-filter-front.html
├── inventarioCSVmock.csv   ← Archivo CSV de ejemplo para pruebas
└── README.md               ← (esta documentación)
```

- **`api-inventory-filter-front.html`**: Archivo principal. Incluye todo el HTML, CSS y JavaScript necesarios (sin dependencias de compilación).  
- **`inventarioCSVmock.csv`**: Ejemplo de inventario que contiene columnas:  
  ```
  App;Developer;APIProduct;Proxy;KVM;Target
  MusicApp;EquipoAudio;music_v1;music-proxy;kvm1;target1
  MusicApp;EquipoAudio;music_v1;music-proxy;kvm2;target2
  VideoApp;EquipoVideo;video_v1;video-proxy;kvmX;targetX
  VideoApp;EquipoVideo;video_v1;video-proxy;kvmY;targetY
  ;;orphan_prod;;;
  ;;test_default;test;;  ← Producto default “descartable”
  StandaloneApp;OtroDev;standalone;standalone-proxy;kvmSolo;targetSolo
  ```
  (Asegúrate de usar `;` como separador y no dejar líneas vacías que confundan el parser).

---

## 🔧 Detalles de implementación

- **PapaParse**  
  Se incluye vía CDN:  
  ```html
  <script src="https://unpkg.com/papaparse@5.4.1/papaparse.min.js"></script>
  ```
  - Cuando cargamos un archivo local o Blob, usamos:
    ```js
    Papa.parse(file, {
      header: true,
      delimiter: ';',
      skipEmptyLines: true,
      complete: res => {
        data = res.data;
        init();
      }
    });
    ```
- **Agrupación con `rowSpan`**  
  1. **App**  
     - Se calcula un array `appsUnicos = Array.from(new Set(filtered.map(r => r.App)))`.  
     - Cada grupo `app` ocupa `rowSpan = número de filas pertenecientes a esa App`.  
  2. **Producto**  
     - Dentro de cada `app`, se agrupa por `APIProduct`.  
     - Su celda ocupa `rowSpan = filasPorProducto.length`.  
  3. **Proxy**  
     - Dentro de cada `producto`, se agrupan las filas por `r.Proxy`.  
     - Cada celda “Proxy” abarca `rowSpan = cantidad de filas con ese mismo `Proxy` (combinaciones de KVM/Target).  
  4. **KVM / Target**  
     - Se pintan sin `rowSpan` porque cambian en cada fila.  

- **Sombreado alterno (“zebra”)**  
  - Se asigna a cada grupo de **App** una clase CSS:
    ```css
    .group-even td { background-color: #52675b; }
    .group-odd  td { background-color: #3d5a4f; }
    ```
    de modo que todas las filas de la misma App compartan el mismo color de fondo.

- **Filtros**  
  - **Radios** (`name="mode"`) definen el filtro por producto/proxy.  
  - **Checkboxes** (`chkApp`, `chkDev`, ...) controlan qué columnas entran en la búsqueda global.  
  - **Buscador global** (`#search`):  
    - Se ejecuta solo si no hay ningún “filtro por columna” activo.  
    - Convierte `searchInput.value` a minúsculas y filtra cualquier fila que tenga el término en alguna de las columnas marcadas.  
  - **Búsqueda por columna** (clic en `<th>`)  
    - Inserta dinámicamente un `<input>` dentro de la cabecera.  
    - Bloquea los otros inputs (solo hay uno visible).  
    - Al escribir, hace `columnFilters[columnName] = texto.toLowerCase()` y filtra exclusivamente esa columna.  
    - Al perder foco, restaura el `<th>` y limpia `columnFilters[columnName]`.  

- **Conteo dinámico**  
  - Tras filtrar (`applyFilters()`), se calculan:  
    ```js
    const countApps    = filtered.reduce(...);
    const countProds   = filtered.reduce(...);
    const countProxies = filtered.reduce(...);
    ```
  - Se concatena en `resultCountDiv.textContent = 'Resultado de búsqueda: X apps, Y productos, Z proxies'`.

- **Copiar / Exportar**  
  - **Copiar**:  
    ```js
    btnCopy.onclick = async () => {
      const tbl = document.getElementById('inventoryTable');
      const html = tbl.outerHTML;
      let text = '';
      tbl.querySelectorAll('tr').forEach(row => {
        text += Array.from(row.children).map(td => td.innerText).join("\t") + "\n";
      });
      await navigator.clipboard.write([ new ClipboardItem({ ... }) ]);
      alert('Tabla copiada con formato');
    };
    ```  
  - **Exportar**:  
    ```js
    btnExport.onclick = () => {
      const hdr  = isDefault 
                     ? ['Producto','Apps','Proxies','Descartable','Razón']
                     : ['App','Developer','APIProduct','Proxy','KVM','Target'];
      const rows = filtered.map(r => hdr.map(c => r[c] || ''));
      const csv  = [hdr, ...rows].map(a => a.join(';')).join("\n");
      const blob = new Blob([csv], { type: 'text/csv' });
      const link = document.createElement('a');
      link.href     = URL.createObjectURL(blob);
      link.download = isDefault
                       ? 'productos_default.csv'
                       : 'inventario.csv';
      link.click();
    };
    ```

---

## 🧪 Archivo de pruebas (`inventarioCSVmock.csv`)

Incluye un CSV de ejemplo para que compruebes todas las funcionalidades inmediatamente:

```csv
App;Developer;APIProduct;Proxy;KVM;Target
MusicApp;EquipoAudio;music_v1;music-proxy;kvm1;target1
MusicApp;EquipoAudio;music_v1;music-proxy;kvm2;target2
MusicApp;EquipoAudio;music_v2;music-proxy-v2;kvmA;targetA
VideoApp;EquipoVideo;video_v1;video-proxy;kvmX;targetX
VideoApp;EquipoVideo;video_v1;video-proxy;kvmY;targetY
;;orphan_prod;;;
;;test_default;test;;  ← Producto default “descartable”
StandaloneApp;OtroDev;standalone;standalone-proxy;kvmSolo;targetSolo
```

- **Productos huérfanos**:  
  - `orphan_prod` no tiene Proxy asociado (para el radio “Productos huérfanos”).  
- **Productos descartables**:  
  - `test_default` termina en `_default`, App vacía y Proxy es `test`.  
- **Agrupación jerárquica**:  
  - Dos filas de `MusicApp → music_v1 → music-proxy` (simula dos KVM distintos).  
  - Dos filas de `VideoApp → video_v1 → video-proxy`.  
  - Un caso `StandaloneApp → standalone → standalone-proxy` (sin grouping complejo).  

---

## 📖 Uso básico

1. **Abrir `api-inventory-filter-front.html`** en tu navegador (no se requiere servidor).  
2. **Cargar CSV**:  
   - Opción A: Arrastra `inventarioCSVmock.csv` sobre la zona punteada.  
   - Opción B: Haz clic en la zona, selecciona el archivo desde tu disco.  
   - Opción C: Copia una URL pública que apunte al CSV (por ejemplo, un raw de GitHub) y haz clic en “Cargar inventario”.  
3. **Explorar tabla**:  
   - Observa la jerarquía: App → Developer → Producto → Proxy → (KVM / Target).  
   - El sombreado alterno se aplica por grupo de App.  
4. **Filtrar**:  
   - **Radios “Filtrado por producto”**: selecciona la casilla deseada (ej. “Productos huérfanos”).  
   - **Checkboxes** (“Filtrado por campo”): marca/desmarca columnas para la búsqueda global.  
   - **Buscar global**: escribe un texto que aparezca en alguna de las columnas habilitadas.  
   - **Buscar por columna**: haz clic en un `<th>`, escribe el término en ese input, y observa cómo filtra solo esa columna.  
5. **Acciones**:  
   - “Copiar tabla” añade al portapapeles la tabla completa (HTML + texto tabulado).  
   - “Exportar a CSV” descarga un archivo CSV con el contenido filtrado.  
