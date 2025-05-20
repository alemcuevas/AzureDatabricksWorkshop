## 🧪 Mini-Lab Opcional: Lazy Evaluation en Spark (Lazy Session / Lazy Operation)

### 🎯 Objetivo
Demostrar cómo funciona la **ejecución diferida (lazy evaluation)** en Spark dentro de Azure Databricks, y cómo afecta al rendimiento y flujo de trabajo.

---

### 🧠 ¿Qué es Lazy Evaluation?

En Spark, todas las transformaciones sobre un DataFrame (como `.select()`, `.filter()`, `.withColumn()`, etc.) **no se ejecutan inmediatamente**. Spark construye un plan lógico que se ejecuta **solo cuando se necesita un resultado final**, como con `.show()`, `.count()`, `.collect()`, etc.

Esto se conoce como **evaluación diferida** o **lazy evaluation**.

---

### 🚶‍♂️ Pasos del Mini-Lab

#### Paso 1: Crear un DataFrame simple

df = spark.range(1, 1000000)

Este comando solo define el plan lógico. No ejecuta nada aún.

---

#### Paso 2: Agregar transformaciones encadenadas

df_transformed = df.withColumn("doble", df["id"] * 2).filter("doble % 5 == 0")

Nuevamente, **no se ejecuta nada todavía**. Spark sigue construyendo el plan de ejecución.

---

#### Paso 3: Ejecutar una acción para forzar la ejecución

df_transformed.count()

Aquí Spark ejecuta todo el pipeline anterior: crea el rango, aplica la columna, filtra, y cuenta los resultados. Solo ahora se inicia el trabajo real.

---

### 🔍 Observaciones

- Puedes abrir el **Spark UI** después de `.count()` para ver que el trabajo se ejecutó completo en ese momento.
- Si haces más transformaciones pero no llamas a ninguna acción, **Spark no hace nada hasta que lo necesite**.

---

### ✅ Conclusión

La lazy evaluation permite que Spark:

- Optimice el plan de ejecución completo antes de correrlo
- Evite trabajo innecesario
- Combine transformaciones para ejecutarlas de forma más eficiente

---

### 💡 Consejo

Para forzar una ejecución y evaluar rendimiento o resultados, usa acciones como:

- `.show()`
- `.count()`
- `.collect()`
- `.write()`

Evita asumir que algo ya se ejecutó solo por haber definido un DataFrame.

---

