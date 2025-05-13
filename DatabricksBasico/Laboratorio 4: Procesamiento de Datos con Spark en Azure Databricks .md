# 🧪 Laboratorio 4: Procesamiento de Datos con Spark en Azure Databricks

## 🎯 Objetivo  
Aplicar transformaciones y agregaciones sobre el dataset energético usando Spark DataFrames y consultas SQL, utilizando como fuente una tabla Delta creada previamente.

---

## 🕒 Duración estimada  
45 minutos

---

## ✅ Prerrequisitos  
- Haber ejecutado correctamente el Laboratorio 3  
- Clúster en estado **Running**  
- Archivo Delta en:  
  `abfss://energia@storageenergydemo.dfs.core.windows.net/delta/energy-data`

---

## 📝 Pasos

### 1. Leer los datos Delta

    df = spark.read.format("delta").load("abfss://energia@storageenergydemo.dfs.core.windows.net/delta/energy-data")
    display(df)

📸 **Screenshot sugerido:** Vista de los datos cargados desde Delta

---

### 2. Verificar el esquema y las columnas

    df.printSchema()
    df.columns

Revisa que las columnas incluyan:
- `Country`
- `Year`
- `Coal Consumption - EJ`
- `Oil Consumption - EJ`
- ...
- `Primary energy consumption (EJ)`

📸 **Screenshot sugerido:** Resultado de `printSchema`

---

### 3. Limpiar datos: eliminar valores nulos

Eliminar registros donde no haya valor para la energía primaria consumida:

    df_clean = df.na.drop(subset=["Primary energy consumption (EJ)"])
    df_clean.count()

📸 **Screenshot sugerido:** Conteo de registros después de limpieza

---

### 4. Agregar columna: consumo en TWh

Convertimos de exajulios (EJ) a teravatios-hora (TWh), usando la equivalencia:

> 1 EJ = 277.778 TWh

    from pyspark.sql.functions import col

    df_transformed = df_clean.withColumn(
        "Primary energy consumption (TWh)",
        col("Primary energy consumption (EJ)") * 277.778
    )

📸 **Screenshot sugerido:** Nuevas columnas visualizadas con `display()`

---

### 5. Agrupar por país: consumo total

    df_transformed.groupBy("Country") \
        .sum("Primary energy consumption (TWh)") \
        .orderBy("sum(Primary energy consumption (TWh))", ascending=False) \
        .show(10)

📸 **Screenshot sugerido:** Tabla de países con mayor consumo total

---

### 6. Crear vista temporal para SQL

    df_transformed.createOrReplaceTempView("energia")

Consulta: consumo promedio por década para México

    %sql
    SELECT
        FLOOR(Year/10)*10 AS Decada,
        AVG(`Primary energy consumption (TWh)`) AS Promedio_TWh
    FROM energia
    WHERE Country = 'Mexico'
    GROUP BY Decada
    ORDER BY Decada

📸 **Screenshot sugerido:** Tabla mostrando consumo promedio por década

---

### 7. Guardar resultados transformados

    df_transformed.write.format("delta") \
        .mode("overwrite") \
        .save("abfss://energia@storageenergydemo.dfs.core.windows.net/delta/energy-data-limpio")

📸 **Screenshot sugerido:** Celda de escritura completada correctamente

---

## 🧠 Conceptos clave aplicados

- Limpieza de datos con Spark (`na.drop`)  
- Creación de columnas nuevas con `withColumn`  
- Conversión de unidades  
- Agrupaciones con `groupBy` y `agg`  
- Consultas SQL sobre vistas temporales  
- Escritura de resultados como tabla Delta optimizada

---

## 📚 Recursos Oficiales Recomendados

- [Spark DataFrames en Azure Databricks](https://learn.microsoft.com/azure/databricks/data/dataframes)  
- [Transformaciones con PySpark](https://spark.apache.org/docs/latest/api/python/reference/index.html)  
- [Consultas SQL en notebooks](https://learn.microsoft.com/azure/databricks/sql/)  
- [Conversión de formatos y escritura en Delta](https://learn.microsoft.com/azure/databricks/delta/delta-batch#write-to-a-table)

💡 **Consejo:** Este tipo de procesamiento es ideal como paso intermedio antes de realizar análisis de tendencias o entrenar modelos de machine learning.

