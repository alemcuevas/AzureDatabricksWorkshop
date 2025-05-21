## Laboratorio (Opcional): Spark Execution Plan y Catalyst Optimizer

### 🌟 Objetivo
Entender cómo Spark transforma operaciones de alto nivel en un plan lógico, luego en un plan físico, y cómo el optimizador Catalyst mejora la ejecución de consultas.

### ⏰ Duración estimada
10 – 15 minutos

### 🔹 Descripción
Este laboratorio explica cómo Spark analiza y optimiza consultas utilizando el optimizador Catalyst. Verás cómo inspeccionar el plan de ejecución y cómo las transformaciones no se ejecutan de inmediato, sino que son convertidas en un plan optimizado justo antes de ser ejecutadas.

---

### 🔹 Pasos

#### 1. Crear un DataFrame simple con transformaciones encadenadas

df = spark.range(1, 1000000)  
df_transformed = df.withColumn("doble", df["id"] * 2).filter("doble % 5 == 0").withColumn("final", df["id"] + 10)

#### 2. Mostrar el plan lógico y físico

df_transformed.explain(True)

Este método muestra:
- El **plan lógico**: operaciones tal como fueron escritas
- El **plan optimizado**: después de aplicar reglas de Catalyst
- El **plan físico**: operaciones específicas que Spark ejecutará en los workers

#### 3. Ejecutar una acción

df_transformed.limit(5).display()

Observa que es aquí cuando Spark ejecuta el plan físico generado por Catalyst.

---

### 📌 ¿Qué optimiza Catalyst?

- Reordenamiento de expresiones
- Eliminación de columnas no utilizadas
- Simplificación de filtros
- Combinación de proyecciones
- Empuje de predicados (predicate pushdown)

---

### 🧠 ¿Por qué importa?

Catalyst ayuda a Spark a:
- Reducir la cantidad de datos procesados
- Evitar cálculos innecesarios
- Ejecutar las consultas de forma más eficiente

---

### 🔍 Observaciones

- Puedes usar `.explain(True)` en cualquier DataFrame para ver los tres niveles del plan
- También puedes acceder al **Spark UI** para ver los stages ejecutados físicamente
- Las optimizaciones de Catalyst ocurren **antes** de que empiece la ejecución real

---

### ✅ Consejo

Cuando tengas transformaciones complejas, usa `.explain(True)` para entender qué está haciendo Spark realmente. Esto puede ayudarte a detectar operaciones innecesarias o mal ubicadas en tu pipeline.

