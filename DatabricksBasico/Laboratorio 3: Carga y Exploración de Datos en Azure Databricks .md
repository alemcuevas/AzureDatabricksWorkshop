# 🧪 Laboratorio 3: Carga y Exploración de Datos en Azure Databricks

## 🎯 Objetivo  
Conectar Databricks a un almacenamiento de Azure (ADLS o Blob), cargar datos en un DataFrame de Spark, y realizar lectura/escritura en formato Delta Lake.

---

## 🕒 Duración estimada  
45 minutos

---

## ✅ Prerrequisitos  
- Tener acceso a un Workspace de Azure Databricks  
- Tener un clúster en estado **Running**  
- Tener acceso a una cuenta de almacenamiento (ADLS Gen2 o Blob)  
- Haber configurado permisos (con *access key*, *SAS token*, o *OAuth via managed identity*)

---

## 📝 Pasos

### 1. Montar el almacenamiento (opcional)

Si deseas montar un contenedor de almacenamiento en Databricks para facilitar el acceso, usa el siguiente formato:

    dbutils.fs.mount(
        source = "wasbs://<container>@<account>.blob.core.windows.net/",
        mount_point = "/mnt/datalake",
        extra_configs = {
          "fs.azure.account.key.<account>.blob.core.windows.net": dbutils.secrets.get(scope = "kv_scope", key = "storage-key")
        }
    )

📸 **Screenshot sugerido:** Notebook mostrando el montaje exitoso del contenedor

---

### 2. Verificar archivos disponibles

Verifica el contenido del contenedor o carpeta usando:

    display(dbutils.fs.ls("/mnt/datalake/datos"))

📸 **Screenshot sugerido:** Resultado de la visualización del contenido de la carpeta montada

---

### 3. Cargar un archivo CSV a un DataFrame

Usa `spark.read` para cargar un archivo CSV con encabezado:

    df = spark.read.option("header", True).csv("/mnt/datalake/datos/ventas.csv")
    display(df)

📸 **Screenshot sugerido:** Primeras filas del DataFrame mostradas con `display()`

---

### 4. Escribir datos en formato Delta

Escribe el DataFrame en formato Delta para habilitar transacciones ACID y consultas eficientes:

    df.write.format("delta").mode("overwrite").save("/mnt/datalake/delta/ventas")

📸 **Screenshot sugerido:** Celda de escritura completada sin errores

---

### 5. Leer datos desde formato Delta

Vuelve a cargar los datos desde la ruta Delta:

    df_delta = spark.read.format("delta").load("/mnt/datalake/delta/ventas")
    display(df_delta)

📸 **Screenshot sugerido:** Resultados cargados desde formato Delta

---

### 6. Ejecutar una consulta SQL sobre los datos

Registra temporalmente el DataFrame como vista SQL y consulta desde SQL:

    df_delta.createOrReplaceTempView("ventas")

    %sql
    SELECT * FROM ventas WHERE cantidad > 10

📸 **Screenshot sugerido:** Resultados de la consulta SQL con filtro aplicado

---

## 🧠 Conceptos clave aplicados

- **Montaje de almacenamiento**: Conexión segura a ADLS/Blob desde Databricks  
- **Lectura de CSV**: Carga de datos semiestructurados  
- **Delta Lake**: Escritura y lectura con formato optimizado  
- **SQL sobre Spark**: Consultas interactivas para exploración de datos

---

## 📚 Recursos Oficiales Recomendados

- [Leer y escribir datos en Databricks](https://learn.microsoft.com/azure/databricks/data/data-sources/)  
- [Conexión a ADLS Gen2](https://learn.microsoft.com/azure/databricks/data/data-sources/azure/azure-datalake-gen2)  
- [Documentación oficial de Delta Lake](https://learn.microsoft.com/azure/databricks/delta/)  
- [Usar SQL en notebooks de Databricks](https://learn.microsoft.com/azure/databricks/sql/)

💡 **Consejo:** Usa Delta Lake siempre que necesites integridad transaccional o consultas rápidas sobre grandes volúmenes de datos

