# Laboratorio 4: Entrenamiento y Registro de Modelos desde Azure Databricks

**Duración:** 1 hora  
**Nivel:** Fundamentos

## Objetivo

Entrenar, registrar y versionar modelos de machine learning directamente desde Azure Databricks usando MLflow, implementando las mejores prácticas de reproducibilidad y gestión de experimentos.

## Prerrequisitos

- Workspace de Azure Databricks activo
- Cluster en ejecución
- Cuenta activa en Azure con permisos para crear recursos
- Conocimientos básicos de:
  - Python y SQL
  - Conceptos de Machine Learning
  - Big Data y Spark
- Completado Lab 3 (Feature Engineering) o tener datos procesados disponibles

## Contenido del Laboratorio

### 1. Introducción a MLflow en Azure Databricks

MLflow es una plataforma de código abierto para gestionar el ciclo de vida completo de machine learning, incluyendo experimentación, reproducibilidad, despliegue y registro central de modelos.

**Componentes principales de MLflow:**

- **MLflow Tracking**: Registra y consulta experimentos (parámetros, métricas, código, artefactos)
- **MLflow Projects**: Formato estándar para empaquetar código reutilizable
- **MLflow Models**: Convención para empaquetar modelos que pueden desplegarse en diversas plataformas
- **Model Registry**: Repositorio centralizado para gestionar el ciclo de vida de modelos

**Ventajas en Azure Databricks:**
- MLflow viene pre-instalado y configurado
- Integración nativa con el workspace
- UI integrada para visualizar experimentos
- Almacenamiento automático en Azure Blob Storage
- Soporte para modelos distribuidos con Spark MLlib

### 2. Configuración del Entorno MLflow

#### 2.1 Verificación de MLflow

```python
# Verificar versión de MLflow instalada
import mlflow
print(f"MLflow version: {mlflow.__version__}")

# Verificar URI de tracking (apunta al workspace de Databricks)
print(f"Tracking URI: {mlflow.get_tracking_uri()}")

# Importar librerías adicionales
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier, GradientBoostingRegressor
from sklearn.linear_model import LogisticRegression, LinearRegression
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
import matplotlib.pyplot as plt
import seaborn as sns
```

#### 2.2 Configuración de Experiment

```python
# Crear o configurar un experimento
experiment_name = "/Users/<tu-usuario>/energy-prediction-experiment"

# Alternativamente, usar el notebook actual como experimento
# MLflow automáticamente crea un experimento basado en la ruta del notebook

# Configurar el experimento
mlflow.set_experiment(experiment_name)

# Obtener información del experimento
experiment = mlflow.get_experiment_by_name(experiment_name)
print(f"Experiment ID: {experiment.experiment_id}")
print(f"Artifact Location: {experiment.artifact_location}")
```

### 3. Carga y Preparación de Datos

#### 3.1 Cargar Datos Procesados

```python
# Opción 1: Cargar desde Delta Lake (resultado del Lab 3)
df_energy = spark.read.format("delta").load("/delta/energy_features")

# Opción 2: Cargar desde archivo CSV original
# df_energy = spark.read.csv("/FileStore/tables/owid-energy-data.csv", header=True, inferSchema=True)

# Convertir a Pandas para este ejemplo
df = df_energy.toPandas()

print(f"Dataset shape: {df.shape}")
print(f"Columns: {df.columns.tolist()}")
display(df.head())
```

#### 3.2 Preparación de Datos para Modelado

```python
# Seleccionar features y target para un modelo de clasificación
# Objetivo: Predecir el nivel de desarrollo energético

# Filtrar datos completos
df_model = df[['year', 'population', 'gdp', 
               'primary_energy_consumption', 
               'renewables_consumption',
               'fossil_fuel_consumption',
               'renewable_ratio_imputed',
               'energy_per_capita_imputed',
               'energy_intensity',
               'fossil_dependency_index']].copy()

# Remover filas con valores nulos
df_model = df_model.dropna()

# Crear target: clasificar países por consumo per cápita
df_model['energy_class'] = pd.cut(
    df_model['energy_per_capita_imputed'], 
    bins=[0, 30, 70, 150, float('inf')],
    labels=['Low', 'Medium', 'High', 'Very High']
)

# Preparar features (X) y target (y)
feature_cols = [
    'year', 'population', 'gdp',
    'primary_energy_consumption',
    'renewables_consumption',
    'fossil_fuel_consumption',
    'renewable_ratio_imputed',
    'energy_intensity',
    'fossil_dependency_index'
]

X = df_model[feature_cols]
y = df_model['energy_class']

# Codificar target
from sklearn.preprocessing import LabelEncoder
le = LabelEncoder()
y_encoded = le.fit_transform(y)

print(f"Features shape: {X.shape}")
print(f"Target distribution:\n{pd.Series(y).value_counts()}")
```

#### 3.3 Split de Datos

```python
# Split estratificado
X_train, X_test, y_train, y_test = train_test_split(
    X, y_encoded, 
    test_size=0.2, 
    random_state=42,
    stratify=y_encoded
)

print(f"Training set: {X_train.shape}")
print(f"Test set: {X_test.shape}")
print(f"Train class distribution: {np.bincount(y_train)}")
print(f"Test class distribution: {np.bincount(y_test)}")
```

### 4. Primer Experimento con MLflow Tracking

#### 4.1 Entrenamiento Básico con Logging Manual

```python
# Iniciar un run de MLflow
with mlflow.start_run(run_name="random_forest_baseline") as run:
    
    # 1. Log de parámetros
    n_estimators = 100
    max_depth = 10
    random_state = 42
    
    mlflow.log_param("model_type", "RandomForest")
    mlflow.log_param("n_estimators", n_estimators)
    mlflow.log_param("max_depth", max_depth)
    mlflow.log_param("random_state", random_state)
    mlflow.log_param("test_size", 0.2)
    
    # 2. Entrenar modelo
    model = RandomForestClassifier(
        n_estimators=n_estimators,
        max_depth=max_depth,
        random_state=random_state
    )
    model.fit(X_train, y_train)
    
    # 3. Predicciones
    y_pred_train = model.predict(X_train)
    y_pred_test = model.predict(X_test)
    
    # 4. Calcular métricas
    train_accuracy = accuracy_score(y_train, y_pred_train)
    test_accuracy = accuracy_score(y_test, y_pred_test)
    precision = precision_score(y_test, y_pred_test, average='weighted')
    recall = recall_score(y_test, y_pred_test, average='weighted')
    f1 = f1_score(y_test, y_pred_test, average='weighted')
    
    # 5. Log de métricas
    mlflow.log_metric("train_accuracy", train_accuracy)
    mlflow.log_metric("test_accuracy", test_accuracy)
    mlflow.log_metric("precision", precision)
    mlflow.log_metric("recall", recall)
    mlflow.log_metric("f1_score", f1)
    
    # 6. Log del modelo
    mlflow.sklearn.log_model(
        model, 
        "random_forest_model",
        registered_model_name="energy_classifier_rf"
    )
    
    # 7. Log de artefactos adicionales (matriz de confusión)
    from sklearn.metrics import confusion_matrix
    import matplotlib.pyplot as plt
    
    cm = confusion_matrix(y_test, y_pred_test)
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
    plt.title('Confusion Matrix')
    plt.ylabel('True Label')
    plt.xlabel('Predicted Label')
    plt.savefig("/tmp/confusion_matrix.png")
    mlflow.log_artifact("/tmp/confusion_matrix.png")
    plt.close()
    
    # 8. Feature importance
    feature_importance = pd.DataFrame({
        'feature': feature_cols,
        'importance': model.feature_importances_
    }).sort_values('importance', ascending=False)
    
    plt.figure(figsize=(10, 6))
    plt.barh(feature_importance['feature'], feature_importance['importance'])
    plt.xlabel('Importance')
    plt.title('Feature Importance')
    plt.tight_layout()
    plt.savefig("/tmp/feature_importance.png")
    mlflow.log_artifact("/tmp/feature_importance.png")
    plt.close()
    
    print(f"Run ID: {run.info.run_id}")
    print(f"Test Accuracy: {test_accuracy:.4f}")
    print(f"F1 Score: {f1:.4f}")
```

#### 4.2 Visualizar Resultados en MLflow UI

```python
# Obtener información del último run
print(f"Experiment ID: {experiment.experiment_id}")
print(f"Para ver los resultados, ve a:")
print(f"Workspace -> Experiments -> {experiment_name}")
```

### 5. Experimentos con Múltiples Modelos

#### 5.1 Función para Entrenamiento Parametrizado

```python
def train_and_log_model(model, model_name, params, X_train, X_test, y_train, y_test):
    """
    Función para entrenar y registrar modelos con MLflow
    """
    with mlflow.start_run(run_name=model_name):
        
        # Log de parámetros
        mlflow.log_param("model_type", model_name)
        for param_name, param_value in params.items():
            mlflow.log_param(param_name, param_value)
        
        # Entrenar modelo
        model.fit(X_train, y_train)
        
        # Predicciones
        y_pred_train = model.predict(X_train)
        y_pred_test = model.predict(X_test)
        y_pred_proba = model.predict_proba(X_test) if hasattr(model, 'predict_proba') else None
        
        # Métricas
        train_accuracy = accuracy_score(y_train, y_pred_train)
        test_accuracy = accuracy_score(y_test, y_pred_test)
        precision = precision_score(y_test, y_pred_test, average='weighted')
        recall = recall_score(y_test, y_pred_test, average='weighted')
        f1 = f1_score(y_test, y_pred_test, average='weighted')
        
        # Log de métricas
        mlflow.log_metric("train_accuracy", train_accuracy)
        mlflow.log_metric("test_accuracy", test_accuracy)
        mlflow.log_metric("precision", precision)
        mlflow.log_metric("recall", recall)
        mlflow.log_metric("f1_score", f1)
        mlflow.log_metric("overfitting", train_accuracy - test_accuracy)
        
        # Log del modelo
        mlflow.sklearn.log_model(
            model, 
            f"{model_name}_model",
            registered_model_name=f"energy_classifier_{model_name.lower().replace(' ', '_')}"
        )
        
        # Log de artefactos
        from sklearn.metrics import classification_report
        report = classification_report(y_test, y_pred_test, target_names=le.classes_)
        with open("/tmp/classification_report.txt", "w") as f:
            f.write(report)
        mlflow.log_artifact("/tmp/classification_report.txt")
        
        print(f"✓ {model_name} - Test Accuracy: {test_accuracy:.4f}, F1: {f1:.4f}")
        
        return model, test_accuracy, f1

print("✓ Función de entrenamiento definida")
```

#### 5.2 Comparación de Múltiples Modelos

```python
# Diccionario de modelos a probar
models_config = {
    "Random Forest": {
        "model": RandomForestClassifier(random_state=42),
        "params": {
            "n_estimators": 100,
            "max_depth": 15,
            "min_samples_split": 5
        }
    },
    "Gradient Boosting": {
        "model": GradientBoostingClassifier(random_state=42),
        "params": {
            "n_estimators": 100,
            "learning_rate": 0.1,
            "max_depth": 5
        }
    },
    "Logistic Regression": {
        "model": LogisticRegression(max_iter=1000, random_state=42),
        "params": {
            "max_iter": 1000,
            "C": 1.0,
            "solver": "lbfgs"
        }
    }
}

# Entrenar todos los modelos
results = {}

for model_name, config in models_config.items():
    model = config["model"]
    params = config["params"]
    
    # Configurar parámetros del modelo
    model.set_params(**params)
    
    # Entrenar y registrar
    trained_model, accuracy, f1 = train_and_log_model(
        model, model_name, params, 
        X_train, X_test, y_train, y_test
    )
    
    results[model_name] = {
        "accuracy": accuracy,
        "f1": f1,
        "model": trained_model
    }

print("\n" + "="*50)
print("RESUMEN DE RESULTADOS")
print("="*50)
results_df = pd.DataFrame(results).T
display(results_df)
```

### 6. Búsqueda de Hiperparámetros con MLflow

#### 6.1 Grid Search con Logging

```python
from sklearn.model_selection import GridSearchCV

# Definir grid de parámetros
param_grid = {
    'n_estimators': [50, 100, 200],
    'max_depth': [5, 10, 15],
    'min_samples_split': [2, 5, 10]
}

# Iniciar parent run
with mlflow.start_run(run_name="rf_grid_search") as parent_run:
    
    mlflow.log_param("search_type", "GridSearch")
    mlflow.log_param("param_grid", str(param_grid))
    
    # Grid Search
    rf = RandomForestClassifier(random_state=42)
    grid_search = GridSearchCV(
        rf, param_grid, 
        cv=3, 
        scoring='f1_weighted',
        n_jobs=-1
    )
    
    grid_search.fit(X_train, y_train)
    
    # Log mejores parámetros
    mlflow.log_params(grid_search.best_params_)
    
    # Log mejor score
    mlflow.log_metric("best_cv_score", grid_search.best_score_)
    
    # Evaluar en test
    y_pred = grid_search.predict(X_test)
    test_f1 = f1_score(y_test, y_pred, average='weighted')
    test_accuracy = accuracy_score(y_test, y_pred)
    
    mlflow.log_metric("test_f1", test_f1)
    mlflow.log_metric("test_accuracy", test_accuracy)
    
    # Log del mejor modelo
    mlflow.sklearn.log_model(
        grid_search.best_estimator_,
        "best_rf_model",
        registered_model_name="energy_classifier_rf_optimized"
    )
    
    # Log de resultados de grid search
    cv_results = pd.DataFrame(grid_search.cv_results_)
    cv_results.to_csv("/tmp/grid_search_results.csv", index=False)
    mlflow.log_artifact("/tmp/grid_search_results.csv")
    
    print(f"Mejores parámetros: {grid_search.best_params_}")
    print(f"Mejor CV Score: {grid_search.best_score_:.4f}")
    print(f"Test F1 Score: {test_f1:.4f}")
```

### 7. Modelo de Regresión con PySpark MLlib

#### 7.1 Preparar Datos para Spark MLlib

```python
from pyspark.ml.feature import VectorAssembler
from pyspark.ml.regression import RandomForestRegressor as SparkRFRegressor
from pyspark.ml.evaluation import RegressionEvaluator

# Crear target de regresión: predecir consumo energético
df_regression = df[['year', 'population', 'gdp', 
                     'renewables_consumption',
                     'fossil_fuel_consumption',
                     'primary_energy_consumption']].dropna()

# Convertir a Spark DataFrame
spark_df = spark.createDataFrame(df_regression)

# Ensamblar features
feature_cols_spark = ['year', 'population', 'gdp', 
                      'renewables_consumption', 'fossil_fuel_consumption']

assembler = VectorAssembler(
    inputCols=feature_cols_spark,
    outputCol='features'
)

spark_df_assembled = assembler.transform(spark_df)

# Split de datos
train_spark, test_spark = spark_df_assembled.randomSplit([0.8, 0.2], seed=42)

print(f"Training set: {train_spark.count()}")
print(f"Test set: {test_spark.count()}")
```

#### 7.2 Entrenamiento con Spark MLlib y MLflow

```python
# Entrenar modelo con Spark MLlib
with mlflow.start_run(run_name="spark_rf_regression") as run:
    
    # Parámetros
    num_trees = 100
    max_depth = 10
    
    mlflow.log_param("model_type", "SparkMLlib RandomForest")
    mlflow.log_param("num_trees", num_trees)
    mlflow.log_param("max_depth", max_depth)
    mlflow.log_param("feature_cols", feature_cols_spark)
    
    # Crear y entrenar modelo
    rf_spark = SparkRFRegressor(
        featuresCol='features',
        labelCol='primary_energy_consumption',
        numTrees=num_trees,
        maxDepth=max_depth,
        seed=42
    )
    
    model_spark = rf_spark.fit(train_spark)
    
    # Predicciones
    predictions = model_spark.transform(test_spark)
    
    # Evaluar
    evaluator_rmse = RegressionEvaluator(
        labelCol="primary_energy_consumption",
        predictionCol="prediction",
        metricName="rmse"
    )
    
    evaluator_r2 = RegressionEvaluator(
        labelCol="primary_energy_consumption",
        predictionCol="prediction",
        metricName="r2"
    )
    
    evaluator_mae = RegressionEvaluator(
        labelCol="primary_energy_consumption",
        predictionCol="prediction",
        metricName="mae"
    )
    
    rmse = evaluator_rmse.evaluate(predictions)
    r2 = evaluator_r2.evaluate(predictions)
    mae = evaluator_mae.evaluate(predictions)
    
    # Log métricas
    mlflow.log_metric("rmse", rmse)
    mlflow.log_metric("r2", r2)
    mlflow.log_metric("mae", mae)
    
    # Log del modelo Spark
    mlflow.spark.log_model(
        model_spark,
        "spark_rf_model",
        registered_model_name="energy_consumption_predictor_spark"
    )
    
    # Feature importance
    feature_importances = model_spark.featureImportances.toArray()
    importance_df = pd.DataFrame({
        'feature': feature_cols_spark,
        'importance': feature_importances
    }).sort_values('importance', ascending=False)
    
    print(f"RMSE: {rmse:.2f}")
    print(f"R²: {r2:.4f}")
    print(f"MAE: {mae:.2f}")
    print("\nFeature Importance:")
    display(importance_df)
```

### 8. MLflow Model Registry

#### 8.1 Registrar Modelo en Model Registry

```python
# El modelo ya fue registrado durante el entrenamiento con registered_model_name
# Ahora gestionamos su ciclo de vida

# Obtener el modelo del registro
from mlflow.tracking import MlflowClient

client = MlflowClient()

# Listar todos los modelos registrados
registered_models = client.search_registered_models()
print("Modelos Registrados:")
for rm in registered_models:
    print(f"  - {rm.name}")
```

#### 8.2 Transiciones de Stage

```python
# Promover modelo a diferentes stages
model_name = "energy_classifier_rf_optimized"

# Obtener última versión
latest_versions = client.get_latest_versions(model_name)
for version in latest_versions:
    print(f"Version: {version.version}, Stage: {version.current_stage}")

# Transición a "Staging"
latest_version = latest_versions[0].version
client.transition_model_version_stage(
    name=model_name,
    version=latest_version,
    stage="Staging",
    archive_existing_versions=True
)

print(f"✓ Model {model_name} v{latest_version} promovido a Staging")

# Agregar descripción y tags
client.update_model_version(
    name=model_name,
    version=latest_version,
    description="Random Forest optimizado con GridSearch para clasificación de consumo energético"
)

client.set_model_version_tag(
    name=model_name,
    version=latest_version,
    key="validation_status",
    value="passed"
)

print("✓ Metadata actualizada")
```

#### 8.3 Cargar Modelo desde Registry

```python
# Cargar modelo desde Model Registry
model_uri = f"models:/{model_name}/Staging"

loaded_model = mlflow.sklearn.load_model(model_uri)

# Hacer predicciones
sample_data = X_test[:5]
predictions = loaded_model.predict(sample_data)

print("Predicciones con modelo cargado desde Registry:")
for i, pred in enumerate(predictions):
    print(f"  Sample {i+1}: {le.inverse_transform([pred])[0]}")
```

### 9. Gestión de Artefactos y Dependencias

#### 9.1 Log de Artefactos Personalizados

```python
with mlflow.start_run(run_name="model_with_custom_artifacts") as run:
    
    # Entrenar modelo simple
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    # 1. Log de datos de ejemplo
    sample_data = X_test[:100].copy()
    sample_data.to_csv("/tmp/sample_test_data.csv", index=False)
    mlflow.log_artifact("/tmp/sample_test_data.csv", "data")
    
    # 2. Log de preprocessing pipeline
    preprocessing_info = {
        "label_encoder_classes": le.classes_.tolist(),
        "feature_columns": feature_cols,
        "scaling_applied": False,
        "date_processed": "2025-12-03"
    }
    
    import json
    with open("/tmp/preprocessing_info.json", "w") as f:
        json.dump(preprocessing_info, f, indent=2)
    mlflow.log_artifact("/tmp/preprocessing_info.json", "preprocessing")
    
    # 3. Log de código fuente
    with open("/tmp/training_script.py", "w") as f:
        f.write("""
# Training script for energy classification
from sklearn.ensemble import RandomForestClassifier

def train_model(X_train, y_train, n_estimators=100):
    model = RandomForestClassifier(n_estimators=n_estimators, random_state=42)
    model.fit(X_train, y_train)
    return model
""")
    mlflow.log_artifact("/tmp/training_script.py", "code")
    
    # Log del modelo
    mlflow.sklearn.log_model(model, "model_with_artifacts")
    
    print(f"✓ Artefactos personalizados registrados en run: {run.info.run_id}")
```

#### 9.2 Gestión de Dependencias

```python
# MLflow automáticamente registra las dependencias de conda/pip
# Podemos especificar dependencias personalizadas

with mlflow.start_run(run_name="model_with_conda_env") as run:
    
    model = RandomForestClassifier(n_estimators=50, random_state=42)
    model.fit(X_train, y_train)
    
    # Definir environment personalizado
    conda_env = {
        'channels': ['defaults', 'conda-forge'],
        'dependencies': [
            f'python=3.8',
            'pip',
            {
                'pip': [
                    f'mlflow=={mlflow.__version__}',
                    'scikit-learn==1.3.0',
                    'pandas==2.0.3',
                    'numpy==1.24.3'
                ]
            }
        ],
        'name': 'energy_model_env'
    }
    
    # Log modelo con environment específico
    mlflow.sklearn.log_model(
        model,
        "model",
        conda_env=conda_env,
        registered_model_name="energy_classifier_with_env"
    )
    
    print("✓ Modelo registrado con environment personalizado")
```

### 10. Búsqueda y Comparación de Experimentos

#### 10.1 Búsqueda de Runs

```python
# Buscar runs por métricas
runs = mlflow.search_runs(
    experiment_ids=[experiment.experiment_id],
    filter_string="metrics.test_accuracy > 0.7",
    order_by=["metrics.test_accuracy DESC"],
    max_results=10
)

print("Top 10 runs por accuracy:")
display(runs[['run_id', 'params.model_type', 'metrics.test_accuracy', 
              'metrics.f1_score', 'start_time']])
```

#### 10.2 Comparación Visual de Experimentos

```python
# Comparar métricas de diferentes runs
runs_comparison = mlflow.search_runs(
    experiment_ids=[experiment.experiment_id],
    filter_string="params.model_type != ''",
    order_by=["start_time DESC"],
    max_results=20
)

# Visualizar comparación
plt.figure(figsize=(12, 6))

plt.subplot(1, 2, 1)
runs_comparison.plot(
    x='params.model_type', 
    y='metrics.test_accuracy', 
    kind='bar',
    ax=plt.gca(),
    legend=False
)
plt.title('Test Accuracy por Tipo de Modelo')
plt.xlabel('Tipo de Modelo')
plt.ylabel('Accuracy')
plt.xticks(rotation=45)

plt.subplot(1, 2, 2)
runs_comparison.plot(
    x='params.model_type', 
    y='metrics.f1_score', 
    kind='bar',
    ax=plt.gca(),
    legend=False,
    color='orange'
)
plt.title('F1 Score por Tipo de Modelo')
plt.xlabel('Tipo de Modelo')
plt.ylabel('F1 Score')
plt.xticks(rotation=45)

plt.tight_layout()
plt.savefig("/tmp/models_comparison.png")
plt.show()

print("✓ Visualización guardada")
```

### 11. Autologging con MLflow

#### 11.1 Activar Autologging

```python
# MLflow puede registrar automáticamente parámetros, métricas y modelos
# para frameworks populares

# Autologging para scikit-learn
mlflow.sklearn.autolog()

# Entrenar modelo con autologging
with mlflow.start_run(run_name="autolog_random_forest"):
    model = RandomForestClassifier(
        n_estimators=100,
        max_depth=10,
        random_state=42
    )
    
    model.fit(X_train, y_train)
    
    # MLflow automáticamente registra:
    # - Parámetros del modelo
    # - Métricas de training
    # - Modelo serializado
    # - Signature del modelo
    
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    print(f"✓ Modelo entrenado con autologging - Accuracy: {accuracy:.4f}")

# Desactivar autologging
mlflow.sklearn.autolog(disable=True)
```

#### 11.2 Autologging con PySpark MLlib

```python
# Autologging para Spark MLlib
mlflow.spark.autolog()

with mlflow.start_run(run_name="autolog_spark_rf"):
    
    rf_spark = SparkRFRegressor(
        featuresCol='features',
        labelCol='primary_energy_consumption',
        numTrees=50,
        maxDepth=8,
        seed=42
    )
    
    model_spark = rf_spark.fit(train_spark)
    predictions = model_spark.transform(test_spark)
    
    rmse = evaluator_rmse.evaluate(predictions)
    
    print(f"✓ Modelo Spark entrenado con autologging - RMSE: {rmse:.2f}")

# Desactivar autologging
mlflow.spark.autolog(disable=True)
```

### 12. Buenas Prácticas de Reproducibilidad

#### 12.1 Registro Completo de Metadata

```python
def train_reproducible_model(model, model_name, X_train, X_test, y_train, y_test):
    """
    Función con todas las mejores prácticas de reproducibilidad
    """
    with mlflow.start_run(run_name=model_name) as run:
        
        # 1. Tags descriptivos
        mlflow.set_tag("model_family", "tree_based")
        mlflow.set_tag("problem_type", "classification")
        mlflow.set_tag("dataset", "owid_energy")
        mlflow.set_tag("developer", "data_science_team")
        mlflow.set_tag("version", "1.0.0")
        
        # 2. Metadata del dataset
        mlflow.log_param("train_samples", len(X_train))
        mlflow.log_param("test_samples", len(X_test))
        mlflow.log_param("n_features", X_train.shape[1])
        mlflow.log_param("n_classes", len(np.unique(y_train)))
        mlflow.log_param("random_state", 42)
        
        # 3. Información del ambiente
        import sys
        import sklearn
        mlflow.log_param("python_version", sys.version.split()[0])
        mlflow.log_param("sklearn_version", sklearn.__version__)
        mlflow.log_param("mlflow_version", mlflow.__version__)
        
        # 4. Parámetros del modelo
        model_params = model.get_params()
        for param, value in model_params.items():
            mlflow.log_param(f"model_{param}", value)
        
        # 5. Entrenar
        import time
        start_time = time.time()
        model.fit(X_train, y_train)
        training_time = time.time() - start_time
        
        mlflow.log_metric("training_time_seconds", training_time)
        
        # 6. Métricas completas
        y_pred_train = model.predict(X_train)
        y_pred_test = model.predict(X_test)
        
        metrics = {
            "train_accuracy": accuracy_score(y_train, y_pred_train),
            "test_accuracy": accuracy_score(y_test, y_pred_test),
            "precision": precision_score(y_test, y_pred_test, average='weighted'),
            "recall": recall_score(y_test, y_pred_test, average='weighted'),
            "f1_score": f1_score(y_test, y_pred_test, average='weighted')
        }
        
        for metric_name, metric_value in metrics.items():
            mlflow.log_metric(metric_name, metric_value)
        
        # 7. Signature del modelo
        from mlflow.models.signature import infer_signature
        signature = infer_signature(X_train, y_pred_train)
        
        # 8. Input example
        input_example = X_train[:5]
        
        # 9. Log modelo con toda la metadata
        mlflow.sklearn.log_model(
            model,
            "model",
            signature=signature,
            input_example=input_example,
            registered_model_name=f"{model_name}_reproducible"
        )
        
        # 10. Guardar configuración completa
        config = {
            "model_config": model_params,
            "training_config": {
                "train_size": len(X_train),
                "test_size": len(X_test),
                "random_state": 42
            },
            "performance": metrics,
            "training_time": training_time
        }
        
        with open("/tmp/model_config.json", "w") as f:
            json.dump(config, f, indent=2)
        mlflow.log_artifact("/tmp/model_config.json")
        
        print(f"✓ Modelo {model_name} entrenado de forma reproducible")
        print(f"  Run ID: {run.info.run_id}")
        print(f"  Test Accuracy: {metrics['test_accuracy']:.4f}")
        
        return model, run.info.run_id

# Ejecutar entrenamiento reproducible
model_rf = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42)
trained_model, run_id = train_reproducible_model(
    model_rf, 
    "rf_reproducible",
    X_train, X_test, y_train, y_test
)
```

### 13. Deployment y Predicciones

#### 13.1 Cargar y Usar Modelo para Predicciones

```python
# Cargar modelo específico por Run ID
loaded_model = mlflow.sklearn.load_model(f"runs:/{run_id}/model")

# Hacer predicciones
sample = X_test.iloc[:10]
predictions = loaded_model.predict(sample)
predictions_labels = le.inverse_transform(predictions)

print("Predicciones:")
for i, (pred, label) in enumerate(zip(predictions, predictions_labels)):
    print(f"  Sample {i+1}: {label}")
```

#### 13.2 Crear Función de Predicción como Servicio

```python
def predict_energy_class(model_name, model_stage, input_data):
    """
    Función de predicción que carga modelo desde Registry
    
    Args:
        model_name: Nombre del modelo en Registry
        model_stage: Stage del modelo (Production, Staging, etc.)
        input_data: DataFrame con features de entrada
    
    Returns:
        Array con predicciones
    """
    # Cargar modelo
    model_uri = f"models:/{model_name}/{model_stage}"
    model = mlflow.sklearn.load_model(model_uri)
    
    # Predecir
    predictions = model.predict(input_data)
    
    return predictions

# Ejemplo de uso
sample_input = X_test.iloc[:5]
predictions = predict_energy_class(
    "energy_classifier_rf_optimized",
    "Staging",
    sample_input
)

print("Predicciones desde función de servicio:")
print(le.inverse_transform(predictions))
```

### 14. Ejercicios Prácticos

#### Ejercicio 1: Experimentación Avanzada
Crea un experimento que:
- Pruebe al menos 5 algoritmos diferentes
- Use validación cruzada
- Registre todas las métricas y artefactos
- Compare resultados visualmente

#### Ejercicio 2: Pipeline Completo
Implementa un pipeline end-to-end que:
- Cargue datos desde Delta Lake
- Aplique feature engineering
- Entrene múltiples modelos
- Registre el mejor modelo en Production

#### Ejercicio 3: Modelo de Regresión
Crea un modelo de regresión para predecir:
- Consumo energético futuro
- Emisiones de CO2
- Uso de métricas apropiadas (RMSE, MAE, R²)

#### Ejercicio 4: Deployment Simulation
Simula un escenario de deployment:
- Registra un modelo en Staging
- Valida su performance
- Promociónalo a Production
- Documenta el proceso de transición

### 15. Resumen y Mejores Prácticas

#### Checklist de MLflow

- [ ] **Experiments organizados**: Usa nombres descriptivos y jerarquías claras
- [ ] **Logging completo**: Registra parámetros, métricas, artefactos y modelo
- [ ] **Reproducibilidad**: Incluye random seeds, versiones de librerías, environment
- [ ] **Documentación**: Agrega tags, descripciones y comentarios
- [ ] **Model Registry**: Usa stages para gestionar el ciclo de vida
- [ ] **Comparación**: Analiza múltiples runs antes de decidir
- [ ] **Artefactos**: Guarda visualizaciones, reports y datos de ejemplo
- [ ] **Signatures**: Define input/output schema del modelo
- [ ] **Versionado**: Mantén historial de todas las versiones
- [ ] **Cleanup**: Archiva o elimina experimentos obsoletos

#### Flujo de Trabajo Recomendado

```
1. Exploración → 2. Feature Engineering → 3. Experimentación
        ↓                                          ↓
   Lab 1-2                 Lab 3              Lab 4 (actual)
        ↓                                          ↓
4. Model Registry → 5. Validation → 6. Production → 7. Monitoring
```

### 16. Recursos Adicionales

- **MLflow Documentation**: https://mlflow.org/docs/latest/index.html
- **Azure Databricks MLflow**: https://docs.databricks.com/mlflow/index.html
- **MLflow Model Registry**: https://mlflow.org/docs/latest/model-registry.html
- **Best Practices**: https://mlflow.org/docs/latest/tracking.html#best-practices

### 17. Próximos Pasos

En los siguientes laboratorios aprenderás:
- Deployment de modelos en producción (Azure ML, AKS)
- Monitoreo de modelos en tiempo real
- Reentrenamiento automático
- MLOps con Azure DevOps y Databricks
- Serving de modelos con REST APIs

---

## Conclusión

¡Felicitaciones! Has completado el laboratorio de entrenamiento y registro de modelos con MLflow en Azure Databricks.

### Habilidades Adquiridas:

✅ Configuración de experimentos en MLflow  
✅ Entrenamiento de modelos con tracking completo  
✅ Uso de MLflow Model Registry  
✅ Comparación de múltiples modelos  
✅ Gestión de artefactos y dependencias  
✅ Implementación de reproducibilidad  
✅ Búsqueda de hiperparámetros con logging  
✅ Deployment de modelos desde Registry  

**¡Excelente trabajo!** Ahora tienes las bases para gestionar todo el ciclo de vida de modelos ML en producción.
