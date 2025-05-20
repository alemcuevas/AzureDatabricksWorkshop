# 🧪 Laboratorio 5: Entrenamiento y Deploy de Modelos con MLflow

## 🎯 Objetivo  
Entrenar un modelo de regresión con Spark MLlib, realizar seguimiento de experimentos con MLflow y registrar el modelo en Model Registry para despliegue en producción.

---

## 🕒 Duración estimada  
45 minutos

---

## ✅ Prerrequisitos  
- Haber ejecutado el Laboratorio 4 (dataset limpio con columna `Primary_energy_consumption_TWh`)  
- Clúster con Databricks Runtime ML (o MLflow instalado)  
- Acceso al Model Registry habilitado

---

## 📝 Pasos

### 1. Leer los datos transformados desde Delta

    df = spark.read.format("delta").load("abfss://silver@storageenergydemo.dfs.core.windows.net/energy_partitioned")
    display(df)

---

### 2. Preparar columnas para entrenamiento

```
from pyspark.sql.functions import col
from pyspark.ml.feature import VectorAssembler

# Lista de columnas a usar
cols = [
    "coal_consumption",
    "oil_consumption",
    "gas_consumption",
    "Nuclear_Consumption_EJ",
    "hydro_consumption",
    "renewables_consumption",
    "primary_energy_consumption"
]

# Convertir columnas a tipo float
df_ml = df.select(cols)
for c in cols:
    df_ml = df_ml.withColumn(c, col(c).cast("float"))

# Eliminar filas con valores nulos después del casteo
df_ml = df_ml.dropna()

# Crear el vector de características
assembler = VectorAssembler(
    inputCols=cols[:-1],  # Todas excepto la última (que es la variable objetivo)
    outputCol="features"
)

# Crear el DataFrame final para ML
df_final = assembler.transform(df_ml).select("features", col("primary_energy_consumption").alias("label"))

# Mostrar
display(df_final)
```

---

### 3. Dividir datos en entrenamiento y prueba

    train, test = df_final.randomSplit([0.8, 0.2], seed=42)

---

### 4. Activar MLflow para tracking

    import mlflow
    import mlflow.spark
    from pyspark.ml.regression import LinearRegression

    mlflow.set_experiment("/Experimentos/energia")

    with mlflow.start_run():
        lr = LinearRegression(
            featuresCol="features",
            labelCol="Primary_energy_consumption_TWh"
        )
        model = lr.fit(train)

        predictions = model.transform(test)

        rmse = RegressionEvaluator(
            labelCol="Primary_energy_consumption_TWh",
            predictionCol="prediction",
            metricName="rmse"
        ).evaluate(predictions)

        mlflow.log_metric("rmse", rmse)
        mlflow.spark.log_model(model, "modelo_regresion_energia")

![image](https://github.com/user-attachments/assets/d6abf04e-e5f2-46c6-a252-824a4bcfef3f)

---

### 5. Visualizar el experimento en MLflow UI

1. Ve al menú lateral > **Experiments**  
2. Abre `/Experimentos/energia`  
3. Observa métricas, artefactos y parámetros registrados

![image](https://github.com/user-attachments/assets/1c2d385a-59e5-4c76-b2e1-9ec6b0aaf70c)

![image](https://github.com/user-attachments/assets/101b3a7b-6dbe-447a-895d-9e9c41129c9a)

---

### 6. Registrar el modelo entrenado

1. En la UI de MLflow, haz clic en el modelo entrenado  
2. Selecciona **Register Model**  
3. Crea un nuevo modelo llamado `regresion_energia`  
4. Confirma el registro

![image](https://github.com/user-attachments/assets/21747957-dc2a-4d66-9c58-9780a8eaaec8)

![image](https://github.com/user-attachments/assets/2784a1fa-8d6d-42b2-a876-00759eda457f)

![image](https://github.com/user-attachments/assets/ad2d91a8-ea37-44e2-987c-89d35e009bdd)

![image](https://github.com/user-attachments/assets/0c00af01-74cf-4897-87c0-950d95206e9e)

![image](https://github.com/user-attachments/assets/ab316a93-2ed9-4188-b114-759c0cd9cf34)

---

### 7. Cargar modelo desde el registro para inferencia

    model_uri = "models:/regresion_energia/1"
    loaded_model = mlflow.spark.load_model(model_uri)
    loaded_model.transform(test).select("prediction").show(5)

![image](https://github.com/user-attachments/assets/8603dfa0-81b0-45f7-948e-647d91b810e8)

---

## 🧠 Conceptos clave aplicados

- Tracking automático de métricas con MLflow  
- Serialización y versionado de modelos  
- Registro en Model Registry  
- Inferencia a partir de un modelo versionado

---

## 📚 Recursos Oficiales Recomendados

- [MLflow en Azure Databricks](https://learn.microsoft.com/azure/databricks/mlflow/)  
- [Tracking con MLflow](https://mlflow.org/docs/latest/tracking.html)  
- [Model Registry en Databricks](https://learn.microsoft.com/azure/databricks/mlflow/models/)  
- [Deploy de modelos MLflow](https://learn.microsoft.com/azure/databricks/mlflow/model-serving/)

💡 **Consejo:** Usar MLflow te permite tener trazabilidad completa de tus experimentos, ideal para reproducibilidad y control de versiones en producción.
