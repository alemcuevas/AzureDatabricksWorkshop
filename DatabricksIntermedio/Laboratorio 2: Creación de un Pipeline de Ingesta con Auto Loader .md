# 🧪 Laboratorio 2: Creación de un Pipeline de Ingesta con Auto Loader

## 🎯 Objetivo  
Configurar Auto Loader en Azure Databricks para leer datos nuevos automáticamente desde un contenedor en ADLS Gen2, y aplicar procesamiento con Structured Streaming.

---

## 🕒 Duración estimada  
45 minutos

---

## ✅ Prerrequisitos  
- Clúster en estado **Running**  
- Conexión válida al Storage Account configurada con clave o Key Vault  
- Un archivo CSV de ejemplo ya cargado en el contenedor `landing` del Storage Account `storageenergydemo`  
- Permisos para escribir en rutas Delta dentro del contenedor `bronze`

---

## 📝 Pasos

### 1. Establecer la clave de acceso (si no usas Key Vault)

    spark.conf.set(
        "fs.azure.account.key.storageenergydemo.dfs.core.windows.net",
        "<clave_de_acceso>"
    )

📸 **Screenshot sugerido:** Confirmación de configuración sin errores

---

### 2. Verificar los archivos en la zona landing

    display(dbutils.fs.ls("abfss://landing@storageenergydemo.dfs.core.windows.net/"))

📸 **Screenshot sugerido:** Lista de archivos disponibles para lectura

---

### 3. Crear una lectura continua con Auto Loader

    from pyspark.sql.functions import *

    df_auto = (
        spark.readStream
        .format("cloudFiles")
        .option("cloudFiles.format", "csv")
        .option("header", "true")
        .load("abfss://landing@storageenergydemo.dfs.core.windows.net/")
    )

📸 **Screenshot sugerido:** Esquema detectado por Auto Loader

---

### 4. Agregar columna de fecha de carga

    df_transformed = df_auto.withColumn("ingestion_date", current_timestamp())

---

### 5. Escribir los datos transformados en formato Delta (Bronze Layer)

    (
        df_transformed.writeStream
        .format("delta")
        .outputMode("append")
        .option("checkpointLocation", "abfss://bronze@storageenergydemo.dfs.core.windows.net/_checkpoints/energy")
        .start("abfss://bronze@storageenergydemo.dfs.core.windows.net/energy")
    )

📸 **Screenshot sugerido:** Celda ejecutada mostrando que el stream está activo

---

### 6. Verificar que se estén generando datos en la ruta Bronze

    display(spark.read.format("delta").load("abfss://bronze@storageenergydemo.dfs.core.windows.net/energy"))

📸 **Screenshot sugerido:** Registros cargados con columna `ingestion_date`

---

## 🧠 Conceptos clave aplicados

- Lectura continua con Auto Loader desde ADLS  
- Detección automática de archivos nuevos sin polling tradicional  
- Estructura de zonas de ingesta: `landing → bronze`  
- Almacenamiento en Delta Lake optimizado para análisis posteriores

---

## 📚 Recursos Oficiales Recomendados

- [Auto Loader en Azure Databricks](https://learn.microsoft.com/azure/databricks/ingestion/auto-loader/)  
- [Lectura de archivos con Structured Streaming](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html)  
- [Delta Lake en streaming](https://learn.microsoft.com/azure/databricks/delta/delta-streaming/)  

💡 **Consejo:** Usa Auto Loader con checkpointing y Delta para crear pipelines escalables y tolerantes a fallos. Las capas `bronze`, `silver` y `gold` son buenas prácticas en arquitectura de lagos de datos.

