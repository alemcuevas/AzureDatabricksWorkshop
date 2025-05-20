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

---

### 5. Visualizar el experimento en MLflow UI

1. Ve al menú lateral > **Experiments**  
2. Abre `/Experimentos/energia`  
3. Observa métricas, artefactos y parámetros registrados

📸 **Screenshot sugerido:** Tabla con el RMSE y artefactos registrados

---

### 6. Registrar el modelo entrenado

1. En la UI de MLflow, haz clic en el modelo entrenado  
2. Selecciona **Register Model**  
3. Crea un nuevo modelo llamado `regresion_energia`  
4. Confirma el registro

📸 **Screenshot sugerido:** Modelo registrado en el Model Registry

---

### 7. Cargar modelo desde el registro para inferencia

    model_uri = "models:/regresion_energia/1"
    loaded_model = mlflow.spark.load_model(model_uri)
    loaded_model.transform(test).select("prediction").show(5)

📸 **Screenshot sugerido:** Resultado de predicciones usando el modelo cargado del registro

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
