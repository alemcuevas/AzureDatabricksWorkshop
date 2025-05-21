## Laboratorio (Opcional): Caching y Persistencia en Spark

### 🌟 Objetivo
Comprender cómo funcionan las operaciones de caching y persistencia en Spark y cómo se relacionan con la ejecución perezosa (lazy evaluation).

### ⏰ Duración estimada
10 – 15 minutos

### 🔹 Descripción
Spark recalcula el pipeline completo cada vez que se ejecuta una acción sobre un DataFrame no almacenado. Este laboratorio explora cómo usar `.cache()` y `.persist()` para mejorar la eficiencia.

---

### 🔹 Pasos

#### 1. Crear un DataFrame con transformaciones pesadas

df = spark.range(1, 10000000)  
df_transformed = df.withColumn("cuadrado", df["id"] * df["id"]).filter("cuadrado % 3 == 0")

#### 2. Ejecutar una acción sin cache

df_transformed.count()

Verifica el tiempo de ejecución. Luego vuelve a ejecutar otra acción:

df_transformed.limit(5).display()

Spark vuelve a recalcular todo el pipeline.

#### 3. Aplicar cache y ejecutar nuevamente

df_transformed.cache()  
df_transformed.count()  
df_transformed.limit(5).display()

Esta vez, la segunda acción será mucho más rápida.

#### 4. Usar persistencia (en disco o memoria)

from pyspark import StorageLevel  
df_transformed.persist(StorageLevel.MEMORY_AND_DISK)

Esto es útil cuando los datos no caben completamente en memoria.

---

### 🔍 Observaciones

- `.cache()` es equivalente a `.persist(StorageLevel.MEMORY_AND_DISK)` por defecto  
- Usa `.unpersist()` para liberar memoria cuando ya no se necesita  
- Cache solo tiene efecto tras la primera acción  

---

### ✅ Consejo
Aplica cache o persistencia únicamente a resultados intermedios que serán reutilizados varias veces en un flujo de trabajo.
