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

## 🆚 Diferencia entre `abfss://` y `wasbs://`

Cuando trabajas con Azure Databricks y accedes a datos en Azure Storage, verás dos esquemas comunes en las rutas:

### 🔹 abfss:// – Azure Blob File System Secure

- Significa: **Azure Blob File System Secure**
- Usa el conector nativo de **ADLS Gen2**
- Optimizado para análisis con Spark y Databricks
- Soporta estructura jerárquica de carpetas y ACLs
- **Recomendado para entornos modernos y productivos**

Ejemplo de uso:  
abfss://container@storageaccount.dfs.core.windows.net/ruta/

---

### 🔸 wasbs:// – Windows Azure Storage Blob Secure

- Significa: **Windows Azure Storage Blob Secure**
- Protocolo antiguo usado con cuentas **Blob Storage Gen1**
- No soporta carpetas jerárquicas ni ACLs
- Rendimiento y compatibilidad más limitados
- Útil solo para **compatibilidad heredada**

Ejemplo de uso:  
wasbs://container@storageaccount.blob.core.windows.net/ruta/

---

### ✅ Comparación rápida

| Característica                        | abfss:// (ADLS Gen2) | wasbs:// (Blob Gen1) |
|--------------------------------------|----------------------|----------------------|
| Jerarquía de carpetas                | ✅ Sí               | ❌ No               |
| ACLs (control de acceso granular)    | ✅ Sí               | ❌ No               |
| Rendimiento con Spark                | ✅ Óptimo           | ⚠️ Limitado         |
| Recomendado en Databricks            | ✅ Sí               | ❌ No               |
| Seguridad y autenticación moderna    | ✅ Mejor soporte     | ⚠️ Básico           |

---

💡 **Consejo**: Siempre que puedas, usa `abfss://` con cuentas **ADLS Gen2**. Ofrece más seguridad, mejor rendimiento y compatibilidad total con funcionalidades analíticas modernas como Auto Loader y Delta Lake.

---

## 📝 Pasos

### 1. Establecer la clave de acceso (si no usas Key Vault)

    spark.conf.set(
        "fs.azure.account.key.storageenergydemo.dfs.core.windows.net",
        "<clave_de_acceso>"
    )

---

### 2. Verificar los archivos en la zona landing

    display(dbutils.fs.ls("abfss://landing@storageenergydemo.dfs.core.windows.net/"))

---
## 🚀 ¿Para qué sirve Auto Loader en Azure Databricks?

Auto Loader es una funcionalidad de Databricks diseñada para facilitar la **ingesta automática de archivos nuevos** desde almacenamiento en la nube, como Azure Data Lake Storage (ADLS) o Blob Storage, sin necesidad de procesos manuales o programación compleja.

### ✅ Beneficios clave

- **Detección automática de archivos nuevos** sin necesidad de hacer polling intensivo
- **Escalabilidad automática**: maneja millones de archivos de forma eficiente
- **Soporte nativo para formatos comunes** como CSV, JSON, Parquet, Avro, etc.
- Compatible con pipelines de **Structured Streaming** para procesamiento en tiempo real o cuasi-real

### 🧠 ¿Cuándo usarlo?

Usa Auto Loader cuando necesitas:

- Procesar archivos nuevos que llegan continuamente a una carpeta en ADLS
- Automatizar la carga de datos en una arquitectura de tipo Bronze → Silver → Gold
- Construir pipelines de datos confiables y fáciles de mantener en Databricks

### 🔁 Comparado con otras opciones

| Método             | Auto Loader              | read.format(\"csv\") o manual |
|--------------------|--------------------------|-------------------------------|
| Detección de nuevos archivos | ✅ Automática              | ❌ Manual                     |
| Escalable a millones de archivos | ✅ Sí                  | ❌ Limitado                  |
| Integración con streaming | ✅ Nativo                   | ⚠️ No recomendado            |
| Uso en producción | ✅ Recomendado             | ❌ Solo para pruebas puntuales |

### 📌 Ejemplo básico

```python
df = (
  spark.readStream
  .format("cloudFiles")
  .option("cloudFiles.format", "csv")
  .load("abfss://landing@<storage>.dfs.core.windows.net/datos/")
)
```

Este código permite que tu pipeline procese automáticamente cualquier archivo nuevo que llegue a la carpeta datos/ en tu contenedor landing.

---

### 3. Crear una lectura continua con Auto Loader

from pyspark.sql.functions import *

```
df_auto = (
    spark.readStream
    .format("cloudFiles")
    .option("cloudFiles.format", "csv")
    .option("header", "true")
    .option("cloudFiles.schemaLocation", "abfss://landing@storageenergydemo.dfs.core.windows.net/_schemas/")
    .load("abfss://landing@storageenergydemo.dfs.core.windows.net/")
)
```

![image](https://github.com/user-attachments/assets/16ec13ce-eb55-4696-b127-6f2b1156e792)

---

### 4. Agregar columna de fecha de carga

    df_transformed = df_auto.withColumn("ingestion_date", current_timestamp())

![image](https://github.com/user-attachments/assets/6074f4c6-5a92-4ee0-a1d6-a57440766230)

---

### 5. Escribir los datos transformados en formato Delta (Bronze Layer)

    (
        df_transformed.writeStream
        .format("delta")
        .outputMode("append")
        .option("checkpointLocation", "abfss://bronze@storageenergydemo.dfs.core.windows.net/_checkpoints/energy")
        .start("abfss://bronze@storageenergydemo.dfs.core.windows.net/energy")
    )

![image](https://github.com/user-attachments/assets/116e2dc1-3184-477c-963d-6cdce34f58a0)

---

### 6. Verificar que se estén generando datos en la ruta Bronze

    display(spark.read.format("delta").load("abfss://bronze@storageenergydemo.dfs.core.windows.net/energy"))

![image](https://github.com/user-attachments/assets/bce3b10e-cdff-49f8-9a0e-efec29c5625e)

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

