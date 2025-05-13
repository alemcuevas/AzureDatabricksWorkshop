# 🧪 Laboratorio 3: Carga y Exploración de Datos Energéticos en Azure Databricks

## 🎯 Objetivo  
Conectar Azure Databricks a Azure Data Lake Storage Gen2 usando la clave de acceso, cargar el dataset `energy-consumption-by-source.csv`, explorarlo y guardarlo en formato Delta Lake.

---

## 🕒 Duración estimada  
45 minutos

---

## ✅ Prerrequisitos  
- Workspace de Azure Databricks activo  
- Clúster en estado **Running**  
- Archivo `energy-consumption-by-source.csv` subido al contenedor `energia` del Storage Account `storageenergydemo`  
- Clave de acceso disponible desde el portal de Azure

---

## 📝 Pasos

### 1. Establecer la clave de acceso en la configuración de Spark

Reemplaza `<clave_de_acceso>` con el valor de `key1` obtenido en el portal de Azure:

    spark.conf.set(
        "fs.azure.account.key.storageenergydemo.dfs.core.windows.net",
        "<clave_de_acceso>"
    )

📸 **Screenshot sugerido:** Celda con `spark.conf.set` ejecutada sin errores

---

### 2. Cargar el archivo CSV en un DataFrame

    df = spark.read.option("header", True).csv("abfss://energia@storageenergydemo.dfs.core.windows.net/energy-consumption-by-source.csv")
    display(df)

📸 **Screenshot sugerido:** Primeras filas del DataFrame cargado correctamente

---

### 3. Verificar el esquema

    df.printSchema()

Deberías ver columnas como:
- `Country`
- `Code`
- `Year`
- `Coal Consumption - EJ`
- `Oil Consumption - EJ`
- `Gas Consumption - EJ`
- `Nuclear Consumption - EJ`
- `Hydro Consumption - EJ`
- `Renewables Consumption - EJ`
- `Other Renewables Consumption - EJ`
- `Primary energy consumption (EJ)`

📸 **Screenshot sugerido:** Salida de `printSchema()` mostrando los tipos

---

### 4. Filtrar y explorar los datos

Mostrar los países únicos:

    df.select("Country").distinct().show(10)

Ver los datos de México:

    df.filter(df["Country"] == "Mexico").display()

📸 **Screenshot sugerido:** Resultados del filtro por país

---
## 💾 ¿Por qué guardar los datos en formato Delta Lake?

Guardar los datos en formato **Delta Lake** te ofrece múltiples beneficios que no tienes con formatos como CSV o Parquet. A continuación se explican sus ventajas principales:

---

### 🔁 1. Soporte para transacciones ACID

Delta Lake permite realizar **transacciones atómicas** sobre los datos, lo que significa que:
- Si una operación falla, los datos no quedan en estado inconsistente
- Puedes hacer `update`, `delete`, `merge` de forma segura

---

### ⏮️ 2. Time Travel (viaje en el tiempo)

Puedes **consultar versiones anteriores** de la tabla con una sola línea de código, útil para:
- Auditar cambios en los datos
- Restaurar datos eliminados o modificados por error
- Comparar estados históricos

---

### ⚡ 3. Rendimiento optimizado

- Delta Lake organiza los archivos internamente en un formato columnar (basado en Parquet)
- Mejora la velocidad de lectura, filtrado y agregaciones
- Soporta operaciones de **auto-compaction** y **Z-Ordering** para performance

---

### 🧼 4. Integridad y limpieza de datos

Puedes combinar Delta Lake con operaciones como:
- `MERGE INTO` para hacer upserts (actualizar si existe, insertar si no)
- `VACUUM` para eliminar archivos obsoletos
- `OPTIMIZE` para compactar pequeños archivos y mejorar el rendimiento

---

### 🧠 5. Integración con SQL y DataFrames

Las tablas Delta pueden ser consultadas directamente usando SQL o Spark DataFrames, como si fueran tablas de base de datos, sin importar el volumen de datos.

---

## ✅ En resumen

Usar Delta Lake te da:
- Seguridad al escribir y actualizar datos
- Versionado automático
- Rendimiento superior
- Facilidad para trabajar con Spark SQL y ML pipelines

💡 **Recomendación:** siempre que vayas a realizar análisis exploratorio, procesamiento o machine learning con Spark, convierte tus datos a Delta desde el inicio.

---

### 5. Guardar los datos en formato Delta

Escribe el DataFrame completo como tabla Delta:

    df.write.format("delta").mode("overwrite").save("abfss://energia@storageenergydemo.dfs.core.windows.net/delta/energy-data")

📸 **Screenshot sugerido:** Confirmación de escritura exitosa

---

### 6. Leer los datos desde Delta Lake

    df_delta = spark.read.format("delta").load("abfss://energia@storageenergydemo.dfs.core.windows.net/delta/energy-data")
    display(df_delta)

📸 **Screenshot sugerido:** Vista de los datos cargados desde Delta

---

### 7. Consultar los datos con SQL

1. Registrar el DataFrame como vista temporal:

        df_delta.createOrReplaceTempView("energia")

2. Consulta: países con mayor consumo de energía en 2020

        %sql
        SELECT Country, Year, `Primary energy consumption (EJ)`
        FROM energia
        WHERE Year = 2020
        ORDER BY `Primary energy consumption (EJ)` DESC
        LIMIT 10

📸 **Screenshot sugerido:** Tabla ordenada con los países de mayor consumo

---

## 🧠 Conceptos clave aplicados

- Conexión directa a ADLS Gen2 vía `spark.conf.set`  
- Lectura y visualización de archivos CSV con columnas reales del dataset  
- Escritura optimizada en formato Delta Lake  
- Consulta de datos energéticos con Spark SQL

---

## 📚 Recursos Oficiales Recomendados

- [Leer datos desde Azure Data Lake Gen2](https://learn.microsoft.com/azure/databricks/data/data-sources/azure/azure-datalake-gen2)  
- [Documentación oficial de Delta Lake](https://learn.microsoft.com/azure/databricks/delta/)  
- [Consultas SQL en Databricks](https://learn.microsoft.com/azure/databricks/sql/)  
- [Funciones de Spark SQL](https://spark.apache.org/docs/latest/api/sql/index.html)

💡 **Consejo:** Siempre inspecciona el esquema y los nombres de columnas al cargar datasets CSV. El encabezado original puede contener espacios, símbolos o unidades.
