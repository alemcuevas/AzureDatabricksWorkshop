# 🧪 Laboratorio 4: Tuning de Performance en Spark Jobs

## 🎯 Objetivo  
Aplicar técnicas de optimización en Spark: uso de cache, particionamiento eficiente, y ajuste dinámico de planes de ejecución con Adaptive Query Execution (AQE).

---

## 🕒 Duración estimada  
45 minutos

---

## ✅ Prerrequisitos  
- Laboratorio 3 completado  
- Datos disponibles en la capa Silver:  
  `abfss://silver@storageenergydemo.dfs.core.windows.net/energy`  
- Clúster en estado **Running**, preferentemente con Databricks Runtime 8.4 o superior

---

## 📝 Pasos

### 1. Leer los datos de Silver

    df = spark.read.format("delta").load("abfss://silver@storageenergydemo.dfs.core.windows.net/energy")
    display(df)

---

### 2. Activar Adaptive Query Execution (AQE)

    spark.conf.set("spark.sql.adaptive.enabled", "true")

✅ AQE permite que Spark ajuste automáticamente particiones y uniones según estadísticas observadas en tiempo de ejecución.

---

### 3. Analizar sin optimización

Realiza una agregación sin caché ni particionamiento:

    from pyspark.sql.functions import avg

    df.groupBy("Country").agg(avg("Primary_energy_consumption_TWh")).show(10)

📸 **Screenshot sugerido:** Plan de ejecución sin cache

---

### 4. Aplicar cache para reutilización

    df.cache()
    df.count()  # Obligamos materialización del cache

Repite una consulta para observar mejora de tiempo:

    df.groupBy("Year").count().show()

📸 **Screenshot sugerido:** Comparativa de tiempo entre consulta antes y después del cache

---

### 5. Aplicar particionamiento para escritura optimizada

    df.write.format("delta") \
      .mode("overwrite") \
      .partitionBy("Year") \
      .save("abfss://silver@storageenergydemo.dfs.core.windows.net/energy_partitioned")

📸 **Screenshot sugerido:** Tiempo de carga reducido al filtrar por año

---

### 6. Consultar con filtro sobre partición

    df_part = spark.read.format("delta").load("abfss://silver@storageenergydemo.dfs.core.windows.net/energy_partitioned")
    df_part.filter("Year = 2020").display()

✅ Spark ahora puede hacer **partition pruning** para leer solo archivos del año 2020

---

### 7. Comparar planes de ejecución

Usa el método `.explain(True)` para visualizar el efecto de AQE:

    df.groupBy("Country").agg(avg("Primary_energy_consumption_TWh")).explain(True)

📸 **Screenshot sugerido:** Plan de ejecución con AQE activo

---

## 🧠 Conceptos clave aplicados

- Uso de `cache()` para acelerar consultas repetidas  
- Escritura con `partitionBy()` para habilitar filtros eficientes  
- Activación de AQE para ajuste dinámico de planes de ejecución  
- Análisis de rendimiento con planes de ejecución detallados

---

## 📚 Recursos Oficiales Recomendados

- [Optimización con Spark Cache](https://spark.apache.org/docs/latest/sql-performance-tuning.html#caching-data)  
- [Particiones en Delta Lake](https://learn.microsoft.com/azure/databricks/delta/optimizations/file-mgmt#data-skipping)  
- [Adaptive Query Execution (AQE)](https://spark.apache.org/docs/latest/sql-performance-tuning.html#adaptive-query-execution)  
- [Databricks Performance Tuning Guide](https://learn.microsoft.com/azure/databricks/delta/performance/)

💡 **Consejo:** Estas técnicas deben aplicarse una vez que se ha estabilizado el esquema de tus tablas y entiendes el patrón de acceso típico.
