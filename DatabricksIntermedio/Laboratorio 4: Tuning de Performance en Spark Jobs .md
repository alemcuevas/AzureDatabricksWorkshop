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

![image](https://github.com/user-attachments/assets/1184ed71-1cc3-4677-a6c1-6d992a45e5e9)

---

### 4. Aplicar cache para reutilización

    df.cache()
    df.count()  # Obligamos materialización del cache

Repite una consulta para observar mejora de tiempo:

    df.groupBy("Year").count().show()

![image](https://github.com/user-attachments/assets/8b799c6e-4d67-4f09-b0ac-a8a4c8e71f81)

---

### 5. Aplicar particionamiento para escritura optimizada

    df.write.format("delta") \
      .mode("overwrite") \
      .partitionBy("Year") \
      .save("abfss://silver@storageenergydemo.dfs.core.windows.net/energy_partitioned")

![image](https://github.com/user-attachments/assets/cbd32759-6296-483b-ab60-d392e801519e)

---

### 6. Consultar con filtro sobre partición

    df_part = spark.read.format("delta").load("abfss://silver@storageenergydemo.dfs.core.windows.net/energy_partitioned")
    df_part.filter("Year = 2020").display()

✅ Spark ahora puede hacer **partition pruning** para leer solo archivos del año 2020

## 🌲 ¿Qué es Partition Pruning?

**Partition Pruning** es una técnica de optimización en Apache Spark y Azure Databricks que permite **leer solo las particiones necesarias** de una tabla cuando se aplica un filtro en una consulta. Esto mejora considerablemente el rendimiento, especialmente en tablas muy grandes.

---

### ✅ ¿Cómo funciona?

Si una tabla Delta está particionada por una columna como `Year`, y haces una consulta con un filtro como `WHERE Year = 2022`, Spark identifica automáticamente que solo necesita acceder a la carpeta `Year=2022`, y **evita leer todas las demás particiones**.

---

### 📦 Ejemplo práctico

Supón que tienes una tabla Delta guardada en la siguiente ruta:

abfss://silver@storageaccount.dfs.core.windows.net/energy_partitioned

Y que esa tabla fue escrita usando `.partitionBy("Year")`.

Al ejecutar este código:

**Leer datos particionados:**

df = spark.read.format("delta").load("abfss://silver@storageaccount.dfs.core.windows.net/energy_partitioned")

**Filtrar por año:**

df.filter("Year = 2020").display()

Spark automáticamente aplicará **partition pruning** y solo leerá los archivos de la carpeta `/Year=2020/`.

---

### 📌 Buenas prácticas para aprovechar partition pruning

- Siempre que sea posible, escribe los datos con `.partitionBy("columna")` en el `DataFrameWriter`.
- Aplica filtros directos sobre columnas particionadas (por ejemplo, `Year = 2022`).
- Evita transformar la columna particionada en la consulta (por ejemplo, `YEAR(fecha)` evita el pruning).
- Puedes confirmar que el pruning se aplica usando `.explain(True)` en el DataFrame.

---

### 🚫 Cosas que pueden romper el pruning

- Usar funciones como `year(fecha)` en lugar de filtrar directamente por `Year`
- No definir correctamente la columna como partición al escribir los datos
- Cargar datos sin especificar un formato particionado o sin respetar la estructura

---

### 💡 Consejo

Partition pruning es especialmente útil en arquitecturas con particionamiento por tiempo (año, mes, día) o regiones. Úsalo para minimizar el volumen de lectura y acelerar los tiempos de ejecución en Databricks.

---

### 7. Comparar planes de ejecución

Usa el método `.explain(True)` para visualizar el efecto de AQE:

    df.groupBy("Country").agg(avg("Primary_energy_consumption_TWh")).explain(True)

![image](https://github.com/user-attachments/assets/cbe25b8c-d9ce-43c3-b393-18c5288ecb75)

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
