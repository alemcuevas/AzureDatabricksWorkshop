# 🧪 Laboratorio Opcional: Lazy Session y Lazy Operations en Spark

## 🎯 Objetivo

Explorar el comportamiento de ejecución diferida (lazy evaluation) y cómo Spark gestiona la ejecución de transformaciones y acciones dentro de una sesión activa (lazy session).

---

## 🕒 Duración estimada

15 – 20 minutos

---

## ✅ Prerrequisitos

- Clúster en ejecución en Azure Databricks
- Familiaridad básica con transformaciones y acciones en Spark DataFrames

---

## 🔹 ¿Qué es una Lazy Session?

Una **lazy session** en Spark es una sesión activa donde las operaciones declaradas (transformaciones) no se ejecutan de inmediato. Spark **espera hasta que se invoque una acción** (como `.count()` o `.write()`) para disparar la ejecución real del plan lógico acumulado.

---

## 📝 Pasos

### Paso 1: Crear un DataFrame sin ejecutar nada

df = spark.range(1, 100000000)

Esto solo define el DataFrame. No hay ejecución aún. Puedes verificar en el Spark UI que no hay tareas activas.

---

### Paso 2: Aplicar transformaciones encadenadas

df2 = df.withColumn("triple", df["id"] * 3).filter("triple % 7 == 0")

Todavía no se ejecuta nada. Spark sigue agregando al plan lógico de forma perezosa (lazy).

---

### Paso 3: Ejecutar una acción

df2.count()

Aquí es cuando Spark ejecuta realmente todo el pipeline: crea el rango, calcula la columna `triple`, aplica el filtro y cuenta los resultados.

Observa cómo ahora aparece actividad en el Spark UI.

---

### Paso 4: Ejecutar otra acción

df2.limit(5).display()

Aunque Spark ya ejecutó `.count()`, como el DataFrame es inmutable, volverá a ejecutar toda la lógica desde el inicio (a menos que se haya hecho `.cache()`).

---

## 🔍 Observaciones

- Spark no ejecuta nada hasta que se llama a una **acción**
- Las **transformaciones** son perezosas (lazy)
- Las **acciones** son el disparador real de ejecución
- Este comportamiento permite optimizaciones internas automáticas

---

## 💡 Consejo

Si vas a reutilizar el resultado de un DataFrame complejo, usa `.cache()` o `.persist()` después de la primera ejecución para evitar re-calcular todo.

---

## 📚 Recursos recomendados

- [Documentación de Spark sobre ejecución diferida](https://spark.apache.org/docs/latest/rdd-programming-guide.html#lazy-evaluation)
- [Guía de transformaciones y acciones en DataFrames](https://learn.microsoft.com/azure/databricks/dataframes/datasets)

---

