# Laboratorio 5: Despliegue, Pruebas y Monitoreo de Modelos desde Azure Databricks

**Duración:** 1 hora

## Objetivo

Aprender a desplegar modelos entrenados en Databricks de forma segura y escalable, implementando estrategias de monitoreo y buenas prácticas para mantener modelos en producción.

---

## Prerequisitos

- Laboratorio 4 completado (modelo registrado en MLflow)
- Azure Databricks workspace configurado
- Permisos para crear endpoints y recursos en Azure
- Familiaridad básica con APIs REST

---

## Parte 1: Tipos de Despliegue con Databricks y MLflow

### 1.1 Conceptos Fundamentales

#### Tipos de Despliegue

**1. Batch Scoring (Inferencia por Lotes)**
- Procesa grandes volúmenes de datos de forma periódica
- Ideal para predicciones no urgentes
- Ejecutado en clusters de Databricks
- Bajo costo operativo

**2. Real-time Endpoints (Inferencia en Tiempo Real)**
- Respuestas instantáneas a peticiones individuales
- Endpoints REST administrados
- Alta disponibilidad y escalabilidad automática
- Mayor costo por infraestructura dedicada

**3. Streaming Inference**
- Procesamiento continuo de datos en streaming
- Integración con Kafka, Event Hubs, etc.
- Latencia media entre batch y real-time

### 1.2 Comparación de Estrategias

| Característica | Batch Scoring | Real-time Endpoint | Streaming |
|----------------|---------------|-------------------|-----------|
| Latencia | Minutos/Horas | Milisegundos | Segundos |
| Volumen | Alto | Bajo-Medio | Continuo |
| Costo | Bajo | Alto | Medio |
| Complejidad | Baja | Media | Alta |
| Casos de uso | Reportes, ETL | Apps web, APIs | IoT, eventos |

---

## Parte 2: Batch Scoring - Predicciones por Lotes

### 2.1 Crear Notebook para Batch Scoring

Crea un nuevo notebook llamado `batch_scoring_demo`:

```python
# Databricks notebook source
# MAGIC %md
# MAGIC ## Batch Scoring con MLflow
# MAGIC Este notebook demuestra cómo realizar predicciones por lotes usando un modelo registrado en MLflow

# COMMAND ----------

import mlflow
import mlflow.pyfunc
from pyspark.sql import SparkSession
from pyspark.sql.functions import struct, col
import pandas as pd

# COMMAND ----------

# MAGIC %md
# MAGIC ### 1. Cargar Modelo desde MLflow Registry

# COMMAND ----------

# Configurar MLflow
mlflow.set_registry_uri("databricks")

# Nombre del modelo y versión
model_name = "diabetes_predictor"  # Ajusta según tu modelo
model_version = 1  # O "Production" para usar el stage

# Cargar modelo
model_uri = f"models:/{model_name}/{model_version}"
print(f"Cargando modelo desde: {model_uri}")

loaded_model = mlflow.pyfunc.load_model(model_uri)
print(f"✓ Modelo cargado exitosamente")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 2. Preparar Datos de Entrada

# COMMAND ----------

# Opción A: Crear datos de ejemplo
sample_data = pd.DataFrame({
    'age': [45, 52, 38, 61, 29],
    'bmi': [27.3, 32.1, 24.5, 28.9, 22.4],
    'blood_pressure': [120, 135, 110, 140, 115],
    'glucose': [95, 160, 88, 175, 82]
})

# Opción B: Cargar desde Delta Lake
# df = spark.read.format("delta").load("/mnt/data/inference_data")
# sample_data = df.toPandas()

display(sample_data)

# COMMAND ----------

# MAGIC %md
# MAGIC ### 3. Realizar Predicciones

# COMMAND ----------

# Predicciones con pandas DataFrame
predictions = loaded_model.predict(sample_data)

# Agregar predicciones al DataFrame
result_df = sample_data.copy()
result_df['prediction'] = predictions
result_df['prediction_timestamp'] = pd.Timestamp.now()

display(result_df)

# COMMAND ----------

# MAGIC %md
# MAGIC ### 4. Batch Scoring a Gran Escala con Spark UDF

# COMMAND ----------

from pyspark.sql.functions import pandas_udf, PandasUDFType
from pyspark.sql.types import DoubleType

# Crear Spark DataFrame
spark_df = spark.createDataFrame(sample_data)

# Definir UDF para predicciones distribuidas
@pandas_udf(DoubleType())
def predict_udf(*cols):
    # Reconstruir DataFrame desde columnas
    input_df = pd.concat(cols, axis=1)
    input_df.columns = sample_data.columns
    # Hacer predicción
    return pd.Series(loaded_model.predict(input_df))

# Aplicar predicciones
predictions_df = spark_df.withColumn(
    "prediction",
    predict_udf(*[col(c) for c in sample_data.columns])
)

display(predictions_df)

# COMMAND ----------

# MAGIC %md
# MAGIC ### 5. Guardar Resultados

# COMMAND ----------

# Guardar en Delta Lake
output_path = "/mnt/predictions/diabetes/batch_scoring"

predictions_df.write \
    .format("delta") \
    .mode("append") \
    .option("mergeSchema", "true") \
    .save(output_path)

print(f"✓ Predicciones guardadas en: {output_path}")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 6. Programar Job Recurrente

# COMMAND ----------

# MAGIC %md
# MAGIC **Para automatizar el batch scoring:**
# MAGIC 
# MAGIC 1. Ir a **Workflows** → **Jobs**
# MAGIC 2. Crear nuevo Job
# MAGIC 3. Configurar:
# MAGIC    - **Task**: Este notebook
# MAGIC    - **Cluster**: Cluster existente o job cluster
# MAGIC    - **Schedule**: Cron expression (ej: `0 0 * * *` para diario)
# MAGIC    - **Notifications**: Alertas por email
# MAGIC 4. Guardar y activar

# COMMAND ----------

# MAGIC %md
# MAGIC ### 7. Monitoreo de Batch Job

# COMMAND ----------

# Métricas del job
from datetime import datetime

# Contar predicciones generadas
prediction_count = predictions_df.count()

# Tiempo de ejecución (registrar en MLflow)
with mlflow.start_run(run_name="batch_scoring_metrics"):
    mlflow.log_metric("predictions_count", prediction_count)
    mlflow.log_metric("execution_timestamp", datetime.now().timestamp())
    mlflow.log_param("model_version", model_version)
    
print(f"✓ Métricas registradas en MLflow")
```

### 2.2 Ejercicio: Batch Scoring Optimizado

**Tarea:** Implementa un proceso de batch scoring que:
1. Lea datos desde una tabla Delta
2. Aplique el modelo usando Spark UDF
3. Guarde predicciones con particionamiento por fecha
4. Registre métricas de performance (tiempo de ejecución, throughput)

---

## Parte 3: Real-time Endpoints con MLflow

### 3.1 Desplegar Modelo como Endpoint REST

#### Opción 1: Endpoint Administrado en Databricks (Serverless)

```python
# Databricks notebook source
# MAGIC %md
# MAGIC ## Despliegue de Endpoint en Tiempo Real

# COMMAND ----------

import mlflow
from mlflow.deployments import get_deploy_client

# Configurar cliente de despliegue
client = get_deploy_client("databricks")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 1. Crear Endpoint

# COMMAND ----------

# Configuración del endpoint
endpoint_name = "diabetes-predictor-endpoint"
model_name = "diabetes_predictor"
model_version = 1

# Crear endpoint
endpoint_config = {
    "served_models": [{
        "model_name": model_name,
        "model_version": model_version,
        "workload_size": "Small",  # Small, Medium, Large
        "scale_to_zero_enabled": True  # Escalar a 0 cuando no hay tráfico
    }]
}

try:
    endpoint = client.create_endpoint(
        name=endpoint_name,
        config=endpoint_config
    )
    print(f"✓ Endpoint creado: {endpoint_name}")
except Exception as e:
    print(f"Endpoint ya existe o error: {e}")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 2. Verificar Estado del Endpoint

# COMMAND ----------

endpoint_details = client.get_endpoint(endpoint_name)
print(f"Estado: {endpoint_details['state']['ready']}")
print(f"URL: {endpoint_details['url']}")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 3. Actualizar Endpoint (Despliegue Blue-Green)

# COMMAND ----------

# Actualizar a nueva versión con traffic splitting
update_config = {
    "served_models": [
        {
            "model_name": model_name,
            "model_version": 1,
            "workload_size": "Small",
            "scale_to_zero_enabled": True,
            "traffic_percentage": 90  # 90% del tráfico
        },
        {
            "model_name": model_name,
            "model_version": 2,  # Nueva versión
            "workload_size": "Small",
            "scale_to_zero_enabled": True,
            "traffic_percentage": 10  # 10% del tráfico (canary)
        }
    ]
}

# Aplicar actualización
# client.update_endpoint(endpoint_name, config=update_config)
print("✓ Configuración de canary deployment lista")
```

### 3.2 Configuración de Autenticación y Seguridad

```python
# COMMAND ----------

# MAGIC %md
# MAGIC ### Seguridad del Endpoint

# COMMAND ----------

# Generar token de acceso
import databricks.sdk
from databricks.sdk import WorkspaceClient

w = WorkspaceClient()

# Crear token con permisos limitados
token_comment = "Token para endpoint de ML"
# token = w.tokens.create(comment=token_comment, lifetime_seconds=3600)

print("""
Para producción:
1. Usar Azure AD authentication
2. Implementar API Gateway (Azure API Management)
3. Rate limiting y quotas
4. Encriptación TLS/SSL
5. Logging de todas las peticiones
""")

# COMMAND ----------

# MAGIC %md
# MAGIC ### Variables de Entorno Seguras

# COMMAND ----------

# Usar Databricks Secrets para credenciales
# dbutils.secrets.get(scope="ml-endpoints", key="api-token")

# Ejemplo de configuración
endpoint_url = f"https://<databricks-instance>/serving-endpoints/{endpoint_name}/invocations"
# auth_token = dbutils.secrets.get(scope="production", key="endpoint-token")

print("✓ Usar secrets para credenciales en producción")
```

### 3.3 Consumir Endpoint desde Aplicaciones

```python
# COMMAND ----------

# MAGIC %md
# MAGIC ## Consumir Endpoint REST

# COMMAND ----------

import requests
import json
import os

# COMMAND ----------

# MAGIC %md
# MAGIC ### Opción 1: Desde Python (Databricks)

# COMMAND ----------

# Configuración
workspace_url = spark.conf.get("spark.databricks.workspaceUrl")
token = dbutils.notebook.entry_point.getDbutils().notebook().getContext().apiToken().get()

endpoint_url = f"https://{workspace_url}/serving-endpoints/{endpoint_name}/invocations"

# Datos de entrada
data = {
    "dataframe_records": [
        {"age": 45, "bmi": 27.3, "blood_pressure": 120, "glucose": 95},
        {"age": 52, "bmi": 32.1, "blood_pressure": 135, "glucose": 160}
    ]
}

# Headers
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

# Realizar petición
response = requests.post(
    endpoint_url,
    headers=headers,
    json=data
)

# Procesar respuesta
if response.status_code == 200:
    predictions = response.json()
    print("✓ Predicciones recibidas:")
    print(json.dumps(predictions, indent=2))
else:
    print(f"✗ Error: {response.status_code}")
    print(response.text)

# COMMAND ----------

# MAGIC %md
# MAGIC ### Opción 2: Desde aplicación externa (Python)

# COMMAND ----------

# MAGIC %md
# MAGIC ```python
# MAGIC # Script para ejecutar fuera de Databricks
# MAGIC import requests
# MAGIC import json
# MAGIC import os
# MAGIC 
# MAGIC # Configuración
# MAGIC DATABRICKS_HOST = os.environ['DATABRICKS_HOST']  # https://<workspace>.azuredatabricks.net
# MAGIC DATABRICKS_TOKEN = os.environ['DATABRICKS_TOKEN']
# MAGIC ENDPOINT_NAME = "diabetes-predictor-endpoint"
# MAGIC 
# MAGIC # URL del endpoint
# MAGIC url = f"{DATABRICKS_HOST}/serving-endpoints/{ENDPOINT_NAME}/invocations"
# MAGIC 
# MAGIC # Datos de entrada
# MAGIC payload = {
# MAGIC     "dataframe_records": [
# MAGIC         {"age": 45, "bmi": 27.3, "blood_pressure": 120, "glucose": 95}
# MAGIC     ]
# MAGIC }
# MAGIC 
# MAGIC # Realizar petición
# MAGIC response = requests.post(
# MAGIC     url,
# MAGIC     headers={
# MAGIC         "Authorization": f"Bearer {DATABRICKS_TOKEN}",
# MAGIC         "Content-Type": "application/json"
# MAGIC     },
# MAGIC     json=payload,
# MAGIC     timeout=60
# MAGIC )
# MAGIC 
# MAGIC # Procesar respuesta
# MAGIC if response.status_code == 200:
# MAGIC     predictions = response.json()
# MAGIC     print(f"Predicción: {predictions['predictions'][0]}")
# MAGIC else:
# MAGIC     print(f"Error: {response.status_code} - {response.text}")
# MAGIC ```

# COMMAND ----------

# MAGIC %md
# MAGIC ### Opción 3: Desde aplicación web (JavaScript/Node.js)

# COMMAND ----------

# MAGIC %md
# MAGIC ```javascript
# MAGIC // Ejemplo para frontend o Node.js
# MAGIC const ENDPOINT_URL = 'https://<workspace>.azuredatabricks.net/serving-endpoints/diabetes-predictor-endpoint/invocations';
# MAGIC const API_TOKEN = process.env.DATABRICKS_TOKEN;
# MAGIC 
# MAGIC async function getPrediction(patientData) {
# MAGIC   try {
# MAGIC     const response = await fetch(ENDPOINT_URL, {
# MAGIC       method: 'POST',
# MAGIC       headers: {
# MAGIC         'Authorization': `Bearer ${API_TOKEN}`,
# MAGIC         'Content-Type': 'application/json'
# MAGIC       },
# MAGIC       body: JSON.stringify({
# MAGIC         dataframe_records: [patientData]
# MAGIC       })
# MAGIC     });
# MAGIC     
# MAGIC     if (!response.ok) {
# MAGIC       throw new Error(`HTTP error ${response.status}`);
# MAGIC     }
# MAGIC     
# MAGIC     const result = await response.json();
# MAGIC     return result.predictions[0];
# MAGIC   } catch (error) {
# MAGIC     console.error('Error al obtener predicción:', error);
# MAGIC     throw error;
# MAGIC   }
# MAGIC }
# MAGIC 
# MAGIC // Uso
# MAGIC const prediction = await getPrediction({
# MAGIC   age: 45,
# MAGIC   bmi: 27.3,
# MAGIC   blood_pressure: 120,
# MAGIC   glucose: 95
# MAGIC });
# MAGIC console.log('Predicción:', prediction);
# MAGIC ```
```

---

## Parte 4: Monitoreo de Modelos en Producción

### 4.1 Métricas de Endpoint

```python
# Databricks notebook source
# MAGIC %md
# MAGIC ## Monitoreo de Endpoints y Modelos

# COMMAND ----------

import mlflow
import pandas as pd
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
import seaborn as sns

# COMMAND ----------

# MAGIC %md
# MAGIC ### 1. Métricas de Servicio (Endpoint)

# COMMAND ----------

from mlflow.deployments import get_deploy_client

client = get_deploy_client("databricks")
endpoint_name = "diabetes-predictor-endpoint"

# Obtener métricas del endpoint
endpoint_metrics = client.get_endpoint(endpoint_name)

print("📊 Métricas del Endpoint:")
print(f"Estado: {endpoint_metrics['state']}")
print(f"Modelos servidos: {len(endpoint_metrics['config']['served_models'])}")

# Métricas de latencia y throughput (disponibles en Databricks UI)
print("""
Métricas disponibles en Databricks:
- Latencia P50, P90, P99
- Throughput (requests/segundo)
- Tasa de error
- Utilización de recursos
""")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 2. Logging de Predicciones

# COMMAND ----------

# Configurar logging de todas las predicciones
class PredictionLogger:
    def __init__(self, model, log_table_path):
        self.model = model
        self.log_table_path = log_table_path
    
    def predict_and_log(self, input_data, request_id=None):
        """Realiza predicción y registra entrada/salida"""
        import uuid
        from datetime import datetime
        
        # Generar ID único
        if request_id is None:
            request_id = str(uuid.uuid4())
        
        # Realizar predicción
        prediction = self.model.predict(input_data)
        
        # Preparar log
        log_entry = input_data.copy()
        log_entry['prediction'] = prediction
        log_entry['request_id'] = request_id
        log_entry['timestamp'] = datetime.now()
        log_entry['model_version'] = self.model.metadata.run_id
        
        # Guardar en Delta Lake
        log_df = spark.createDataFrame([log_entry])
        log_df.write \
            .format("delta") \
            .mode("append") \
            .save(self.log_table_path)
        
        return prediction, request_id

# Uso
log_path = "/mnt/ml-monitoring/prediction-logs"
logger = PredictionLogger(loaded_model, log_path)

# Ejemplo
sample_input = {'age': 45, 'bmi': 27.3, 'blood_pressure': 120, 'glucose': 95}
pred, req_id = logger.predict_and_log(sample_input)
print(f"✓ Predicción registrada: {req_id}")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 3. Detección de Data Drift

# COMMAND ----------

from scipy import stats
import numpy as np

def calculate_drift(reference_data, current_data, features, threshold=0.05):
    """
    Detecta drift usando Kolmogorov-Smirnov test
    """
    drift_detected = {}
    
    for feature in features:
        # KS test
        statistic, p_value = stats.ks_2samp(
            reference_data[feature],
            current_data[feature]
        )
        
        # Drift si p-value < threshold
        drift_detected[feature] = {
            'statistic': statistic,
            'p_value': p_value,
            'drift': p_value < threshold
        }
    
    return drift_detected

# Cargar datos de referencia (training data)
reference_df = spark.read.format("delta").load("/mnt/data/training_data").toPandas()

# Cargar predicciones recientes
current_df = spark.read.format("delta").load(log_path) \
    .filter("timestamp >= current_date() - 7") \
    .toPandas()

# Detectar drift
features = ['age', 'bmi', 'blood_pressure', 'glucose']
drift_results = calculate_drift(reference_df, current_df, features)

# Mostrar resultados
print("🔍 Detección de Data Drift:")
for feature, result in drift_results.items():
    status = "⚠️ DRIFT DETECTADO" if result['drift'] else "✓ Sin drift"
    print(f"{feature}: {status} (p-value: {result['p_value']:.4f})")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 4. Monitoreo de Performance del Modelo

# COMMAND ----------

# Calcular métricas de performance sobre predicciones
# (requiere ground truth labels)

def calculate_model_metrics(predictions_df, actuals_df):
    """
    Calcula métricas de performance comparando predicciones con valores reales
    """
    from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score
    
    # Join predicciones con actuals
    merged = predictions_df.merge(actuals_df, on='request_id')
    
    # Calcular métricas
    metrics = {
        'accuracy': accuracy_score(merged['actual'], merged['prediction']),
        'precision': precision_score(merged['actual'], merged['prediction'], average='weighted'),
        'recall': recall_score(merged['actual'], merged['prediction'], average='weighted'),
        'f1_score': f1_score(merged['actual'], merged['prediction'], average='weighted')
    }
    
    return metrics

# Registrar métricas en MLflow
with mlflow.start_run(run_name="production_monitoring"):
    mlflow.log_metrics({
        "production_accuracy": 0.89,  # Ejemplo
        "production_latency_p99": 150,  # ms
        "daily_predictions": 10000
    })
    
print("✓ Métricas de producción registradas")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 5. Dashboard de Monitoreo

# COMMAND ----------

# Crear visualizaciones para dashboard

fig, axes = plt.subplots(2, 2, figsize=(15, 10))

# 1. Distribución de predicciones por día
daily_predictions = current_df.groupby(current_df['timestamp'].dt.date).size()
axes[0, 0].plot(daily_predictions.index, daily_predictions.values, marker='o')
axes[0, 0].set_title('Predicciones Diarias')
axes[0, 0].set_xlabel('Fecha')
axes[0, 0].set_ylabel('Cantidad')
axes[0, 0].tick_params(axis='x', rotation=45)

# 2. Distribución de valores predichos
axes[0, 1].hist(current_df['prediction'], bins=30, edgecolor='black')
axes[0, 1].set_title('Distribución de Predicciones')
axes[0, 1].set_xlabel('Valor Predicho')
axes[0, 1].set_ylabel('Frecuencia')

# 3. Feature drift visualization
features_to_plot = ['age', 'bmi']
for idx, feature in enumerate(features_to_plot):
    axes[1, idx].hist(reference_df[feature], alpha=0.5, label='Training', bins=20)
    axes[1, idx].hist(current_df[feature], alpha=0.5, label='Production', bins=20)
    axes[1, idx].set_title(f'Drift Detection: {feature}')
    axes[1, idx].set_xlabel(feature)
    axes[1, idx].set_ylabel('Frecuencia')
    axes[1, idx].legend()

plt.tight_layout()
plt.savefig('/tmp/monitoring_dashboard.png')
display(plt.gcf())

# Registrar dashboard en MLflow
mlflow.log_artifact('/tmp/monitoring_dashboard.png')

print("✓ Dashboard generado y registrado")
```

### 4.2 Alertas Automatizadas

```python
# COMMAND ----------

# MAGIC %md
# MAGIC ### Configuración de Alertas

# COMMAND ----------

def check_alerts_and_notify(drift_results, metrics, thresholds):
    """
    Verifica condiciones y envía alertas
    """
    alerts = []
    
    # 1. Verificar drift
    drift_features = [f for f, r in drift_results.items() if r['drift']]
    if drift_features:
        alerts.append({
            'type': 'DATA_DRIFT',
            'severity': 'WARNING',
            'message': f'Drift detectado en: {", ".join(drift_features)}'
        })
    
    # 2. Verificar degradación de performance
    if metrics.get('accuracy', 1.0) < thresholds['min_accuracy']:
        alerts.append({
            'type': 'PERFORMANCE_DEGRADATION',
            'severity': 'CRITICAL',
            'message': f'Accuracy bajo: {metrics["accuracy"]:.2f}'
        })
    
    # 3. Verificar latencia
    if metrics.get('latency_p99', 0) > thresholds['max_latency_ms']:
        alerts.append({
            'type': 'HIGH_LATENCY',
            'severity': 'WARNING',
            'message': f'Latencia alta: {metrics["latency_p99"]}ms'
        })
    
    # Enviar alertas (integración con servicios de notificación)
    if alerts:
        send_alerts(alerts)
    
    return alerts

def send_alerts(alerts):
    """
    Envía alertas por múltiples canales
    """
    for alert in alerts:
        print(f"🚨 {alert['severity']}: {alert['message']}")
        
        # Integración con servicios externos
        # - Email via SendGrid/SMTP
        # - Slack webhook
        # - Teams webhook
        # - PagerDuty
        # - Azure Monitor
        
        # Ejemplo: Slack webhook
        # import requests
        # slack_webhook = dbutils.secrets.get("monitoring", "slack-webhook")
        # requests.post(slack_webhook, json={"text": alert['message']})

# Configurar thresholds
thresholds = {
    'min_accuracy': 0.85,
    'max_latency_ms': 200,
    'max_drift_pvalue': 0.05
}

# Ejecutar verificación
alerts = check_alerts_and_notify(
    drift_results, 
    {'accuracy': 0.89, 'latency_p99': 150}, 
    thresholds
)

print(f"\n✓ Verificación completada: {len(alerts)} alertas generadas")

# COMMAND ----------

# MAGIC %md
# MAGIC ### Job de Monitoreo Automatizado

# COMMAND ----------

# MAGIC %md
# MAGIC **Crear Job de Monitoreo Diario:**
# MAGIC 
# MAGIC 1. Workflows → Create Job
# MAGIC 2. Configuración:
# MAGIC    - **Name**: `model-monitoring-daily`
# MAGIC    - **Task**: Notebook de monitoreo
# MAGIC    - **Schedule**: `0 8 * * *` (diario a las 8 AM)
# MAGIC    - **Notifications**: Email on failure
# MAGIC    - **Parameters**: 
# MAGIC      ```json
# MAGIC      {
# MAGIC        "model_name": "diabetes_predictor",
# MAGIC        "lookback_days": 7,
# MAGIC        "drift_threshold": 0.05
# MAGIC      }
# MAGIC      ```
```

---

## Parte 5: Buenas Prácticas para Producción

### 5.1 Model Tagging y Versionado

```python
# COMMAND ----------

# MAGIC %md
# MAGIC ## Buenas Prácticas - Gestión de Modelos

# COMMAND ----------

import mlflow
from mlflow.tracking import MlflowClient

client = MlflowClient()

# COMMAND ----------

# MAGIC %md
# MAGIC ### 1. Sistema de Tags Robusto

# COMMAND ----------

# Tags recomendados para modelos en producción
production_tags = {
    # Metadata técnica
    "model_type": "classification",
    "framework": "sklearn",
    "framework_version": "1.3.0",
    
    # Información del dataset
    "training_data_version": "v2.3",
    "training_date": "2025-12-08",
    "training_samples": "100000",
    
    # Métricas de validación
    "validation_accuracy": "0.89",
    "validation_f1": "0.87",
    
    # Deployment info
    "deployed_by": "data-science-team",
    "deployment_date": "2025-12-08",
    "environment": "production",
    
    # Business context
    "use_case": "diabetes-prediction",
    "business_owner": "healthcare-analytics",
    "compliance": "HIPAA-compliant",
    
    # Monitoring
    "monitoring_enabled": "true",
    "alert_threshold_accuracy": "0.85"
}

# Aplicar tags al modelo
model_name = "diabetes_predictor"
model_version = 1

for key, value in production_tags.items():
    client.set_model_version_tag(model_name, model_version, key, value)

print("✓ Tags aplicados al modelo")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 2. Estrategia de Staging

# COMMAND ----------

# Flujo de promoción de modelos
def promote_model(model_name, version, target_stage):
    """
    Promueve modelo a través de stages con validaciones
    """
    stages_flow = {
        "None": "Staging",
        "Staging": "Production",
        "Production": "Archived"
    }
    
    # Validaciones antes de promoción
    if target_stage == "Production":
        # Verificar que pasó pruebas en Staging
        model_version = client.get_model_version(model_name, version)
        tags = model_version.tags
        
        if not tags.get("staging_tests_passed") == "true":
            raise ValueError("Modelo no ha pasado pruebas en Staging")
        
        if not tags.get("security_scan") == "passed":
            raise ValueError("Modelo no ha pasado escaneo de seguridad")
    
    # Transicionar stage
    client.transition_model_version_stage(
        name=model_name,
        version=version,
        stage=target_stage,
        archive_existing_versions=True  # Archivar versiones anteriores
    )
    
    print(f"✓ Modelo {model_name} v{version} promovido a {target_stage}")

# Ejemplo: Promover a Staging
# promote_model("diabetes_predictor", 1, "Staging")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 3. Documentación Automática

# COMMAND ----------

def document_model_deployment(model_name, version):
    """
    Genera documentación completa del modelo
    """
    # Obtener información del modelo
    model_version = client.get_model_version(model_name, version)
    run = client.get_run(model_version.run_id)
    
    documentation = f"""
# Documentación del Modelo: {model_name} v{version}

## Información General
- **Nombre**: {model_name}
- **Versión**: {version}
- **Stage**: {model_version.current_stage}
- **Creado**: {model_version.creation_timestamp}
- **Run ID**: {model_version.run_id}

## Métricas de Entrenamiento
"""
    
    # Agregar métricas
    for key, value in run.data.metrics.items():
        documentation += f"- **{key}**: {value:.4f}\n"
    
    documentation += "\n## Parámetros\n"
    
    # Agregar parámetros
    for key, value in run.data.params.items():
        documentation += f"- **{key}**: {value}\n"
    
    documentation += "\n## Tags\n"
    
    # Agregar tags
    for key, value in model_version.tags.items():
        documentation += f"- **{key}**: {value}\n"
    
    # Guardar documentación
    doc_path = f"/dbfs/mnt/ml-models/docs/{model_name}_v{version}.md"
    with open(doc_path, 'w') as f:
        f.write(documentation)
    
    print(f"✓ Documentación generada: {doc_path}")
    return documentation

# Generar documentación
# doc = document_model_deployment("diabetes_predictor", 1)
# print(doc[:500] + "...")
```

### 5.2 Logs Centralizados

```python
# COMMAND ----------

# MAGIC %md
# MAGIC ### Sistema de Logging Estructurado

# COMMAND ----------

import logging
import json
from datetime import datetime

class StructuredLogger:
    """
    Logger estructurado para modelos en producción
    """
    def __init__(self, model_name, model_version):
        self.model_name = model_name
        self.model_version = model_version
        self.logger = logging.getLogger(f"{model_name}_v{model_version}")
        
        # Configurar handler para Delta Lake
        self.setup_delta_handler()
    
    def setup_delta_handler(self):
        """Configura logging a Delta Lake"""
        # Handler personalizado que escribe a Delta
        pass
    
    def log_prediction(self, request_id, input_data, prediction, latency_ms):
        """Log de predicción individual"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "model_name": self.model_name,
            "model_version": self.model_version,
            "request_id": request_id,
            "input": input_data,
            "prediction": prediction,
            "latency_ms": latency_ms,
            "log_type": "prediction"
        }
        
        # Escribir a Delta Lake
        log_df = spark.createDataFrame([log_entry])
        log_df.write \
            .format("delta") \
            .mode("append") \
            .save("/mnt/ml-monitoring/structured-logs")
        
        return log_entry
    
    def log_error(self, request_id, error_type, error_message):
        """Log de errores"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "model_name": self.model_name,
            "model_version": self.model_version,
            "request_id": request_id,
            "error_type": error_type,
            "error_message": error_message,
            "log_type": "error"
        }
        
        # Escribir a Delta Lake
        log_df = spark.createDataFrame([log_entry])
        log_df.write \
            .format("delta") \
            .mode("append") \
            .save("/mnt/ml-monitoring/structured-logs")
        
        return log_entry

# Usar logger
logger = StructuredLogger("diabetes_predictor", 1)

# Ejemplo de uso
import uuid
request_id = str(uuid.uuid4())
logger.log_prediction(
    request_id=request_id,
    input_data={"age": 45, "bmi": 27.3},
    prediction=0.72,
    latency_ms=45
)

print("✓ Log estructurado registrado")
```

### 5.3 Monitoreo de Costos

```python
# COMMAND ----------

# MAGIC %md
# MAGIC ### Tracking de Costos

# COMMAND ----------

def calculate_deployment_costs(endpoint_name, period_days=30):
    """
    Estima costos de operación del endpoint
    """
    # Obtener métricas de uso
    endpoint_details = client.get_endpoint(endpoint_name)
    
    # Parámetros de costo (ejemplo Azure)
    costs = {
        "Small": 0.07,   # USD por hora
        "Medium": 0.28,
        "Large": 1.12
    }
    
    workload_size = endpoint_details['config']['served_models'][0]['workload_size']
    hourly_cost = costs[workload_size]
    
    # Calcular costo total
    total_hours = period_days * 24
    total_cost = hourly_cost * total_hours
    
    # Si scale-to-zero está habilitado, ajustar por utilización
    if endpoint_details['config']['served_models'][0].get('scale_to_zero_enabled'):
        # Estimar utilización (ejemplo: 50%)
        utilization = 0.5
        total_cost *= utilization
    
    print(f"📊 Estimación de Costos - {endpoint_name}")
    print(f"Tamaño: {workload_size}")
    print(f"Costo por hora: ${hourly_cost:.2f}")
    print(f"Período: {period_days} días")
    print(f"Costo total estimado: ${total_cost:.2f}")
    
    # Registrar en MLflow
    with mlflow.start_run(run_name="cost_tracking"):
        mlflow.log_metric("monthly_cost_usd", total_cost)
        mlflow.log_param("workload_size", workload_size)
    
    return total_cost

# Calcular costos
# monthly_cost = calculate_deployment_costs("diabetes-predictor-endpoint", 30)
```

---

## Parte 6: Demo Completa - End-to-End

### 6.1 Escenario Completo

Vamos a implementar un flujo completo desde el despliegue hasta el monitoreo:

```python
# COMMAND ----------

# MAGIC %md
# MAGIC ## Demo End-to-End: Despliegue y Monitoreo

# COMMAND ----------

# MAGIC %md
# MAGIC ### Paso 1: Preparar Modelo para Producción

# COMMAND ----------

import mlflow
from mlflow.tracking import MlflowClient

client = MlflowClient()
model_name = "diabetes_predictor_demo"

# Cargar modelo del Lab 4
model_uri = "models:/diabetes_predictor/1"

# Copiar a nuevo nombre para demo
# (en producción, usarías el mismo modelo)

print(f"✓ Modelo preparado: {model_name}")

# COMMAND ----------

# MAGIC %md
# MAGIC ### Paso 2: Aplicar Tags y Documentación

# COMMAND ----------

# Tags de producción
production_tags = {
    "environment": "production",
    "deployed_by": "ml-team",
    "deployment_date": "2025-12-08",
    "monitoring_enabled": "true",
    "sla_latency_ms": "200",
    "min_accuracy": "0.85"
}

for key, value in production_tags.items():
    client.set_model_version_tag(model_name, "1", key, value)

print("✓ Tags aplicados")

# COMMAND ----------

# MAGIC %md
# MAGIC ### Paso 3: Desplegar Endpoint

# COMMAND ----------

from mlflow.deployments import get_deploy_client

deploy_client = get_deploy_client("databricks")
endpoint_name = "diabetes-demo-endpoint"

# Configuración del endpoint
endpoint_config = {
    "served_models": [{
        "model_name": model_name,
        "model_version": "1",
        "workload_size": "Small",
        "scale_to_zero_enabled": True
    }]
}

# Crear endpoint
try:
    endpoint = deploy_client.create_endpoint(
        name=endpoint_name,
        config=endpoint_config
    )
    print(f"✓ Endpoint creado: {endpoint_name}")
except Exception as e:
    print(f"Endpoint ya existe: {e}")

# Esperar a que esté listo
import time
for i in range(30):
    status = deploy_client.get_endpoint(endpoint_name)
    if status['state'].get('ready') == 'READY':
        print("✓ Endpoint listo para recibir tráfico")
        break
    print(f"Esperando... ({i+1}/30)")
    time.sleep(10)

# COMMAND ----------

# MAGIC %md
# MAGIC ### Paso 4: Probar Endpoint con Datos de Ejemplo

# COMMAND ----------

import requests
import json

# Configuración
workspace_url = spark.conf.get("spark.databricks.workspaceUrl")
token = dbutils.notebook.entry_point.getDbutils().notebook().getContext().apiToken().get()

endpoint_url = f"https://{workspace_url}/serving-endpoints/{endpoint_name}/invocations"

# Datos de prueba
test_data = {
    "dataframe_records": [
        {"age": 45, "bmi": 27.3, "blood_pressure": 120, "glucose": 95},
        {"age": 52, "bmi": 32.1, "blood_pressure": 135, "glucose": 160},
        {"age": 38, "bmi": 24.5, "blood_pressure": 110, "glucose": 88}
    ]
}

# Realizar petición
import time
start_time = time.time()

response = requests.post(
    endpoint_url,
    headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    },
    json=test_data
)

latency = (time.time() - start_time) * 1000  # ms

# Procesar respuesta
if response.status_code == 200:
    predictions = response.json()
    print("✓ Predicciones recibidas:")
    print(json.dumps(predictions, indent=2))
    print(f"\nLatencia: {latency:.2f} ms")
else:
    print(f"✗ Error: {response.status_code}")
    print(response.text)

# COMMAND ----------

# MAGIC %md
# MAGIC ### Paso 5: Configurar Monitoreo

# COMMAND ----------

# Crear tabla para logs
logs_table_path = "/mnt/ml-monitoring/demo-predictions"

# Simular múltiples predicciones con logging
import pandas as pd
import uuid
from datetime import datetime

def make_prediction_with_monitoring(input_data):
    """Predicción con logging completo"""
    request_id = str(uuid.uuid4())
    
    # Preparar request
    payload = {"dataframe_records": [input_data]}
    
    # Medir latencia
    start = time.time()
    response = requests.post(
        endpoint_url,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        },
        json=payload
    )
    latency_ms = (time.time() - start) * 1000
    
    if response.status_code == 200:
        prediction = response.json()['predictions'][0]
        
        # Log a Delta Lake
        log_entry = {
            **input_data,
            'prediction': prediction,
            'request_id': request_id,
            'timestamp': datetime.now(),
            'latency_ms': latency_ms,
            'status': 'success'
        }
        
        log_df = spark.createDataFrame([log_entry])
        log_df.write.format("delta").mode("append").save(logs_table_path)
        
        return prediction, request_id, latency_ms
    else:
        return None, request_id, latency_ms

# Generar tráfico de prueba
print("Generando tráfico de prueba...")
for i in range(10):
    test_input = {
        'age': 40 + i * 2,
        'bmi': 25 + i * 0.5,
        'blood_pressure': 115 + i * 3,
        'glucose': 90 + i * 5
    }
    pred, req_id, lat = make_prediction_with_monitoring(test_input)
    print(f"Request {i+1}: Prediction={pred:.3f}, Latency={lat:.1f}ms")

print("\n✓ Tráfico de prueba completado")

# COMMAND ----------

# MAGIC %md
# MAGIC ### Paso 6: Analizar Logs y Métricas

# COMMAND ----------

# Leer logs
logs_df = spark.read.format("delta").load(logs_table_path)

print(f"📊 Total de predicciones: {logs_df.count()}")

# Estadísticas de latencia
logs_pd = logs_df.toPandas()
print(f"\nLatencia:")
print(f"  Media: {logs_pd['latency_ms'].mean():.2f} ms")
print(f"  P50: {logs_pd['latency_ms'].quantile(0.5):.2f} ms")
print(f"  P95: {logs_pd['latency_ms'].quantile(0.95):.2f} ms")
print(f"  P99: {logs_pd['latency_ms'].quantile(0.99):.2f} ms")

# Distribución de predicciones
print(f"\nPredicciones:")
print(f"  Media: {logs_pd['prediction'].mean():.3f}")
print(f"  Min: {logs_pd['prediction'].min():.3f}")
print(f"  Max: {logs_pd['prediction'].max():.3f}")

# Visualizar
import matplotlib.pyplot as plt

fig, axes = plt.subplots(1, 2, figsize=(12, 4))

axes[0].hist(logs_pd['latency_ms'], bins=20, edgecolor='black')
axes[0].set_title('Distribución de Latencia')
axes[0].set_xlabel('Latencia (ms)')
axes[0].set_ylabel('Frecuencia')

axes[1].scatter(logs_pd['age'], logs_pd['prediction'], alpha=0.6)
axes[1].set_title('Predicciones vs Edad')
axes[1].set_xlabel('Edad')
axes[1].set_ylabel('Predicción')

plt.tight_layout()
display(plt.gcf())

# COMMAND ----------

# MAGIC %md
# MAGIC ### Paso 7: Configurar Alertas

# COMMAND ----------

# Verificar SLAs
sla_latency = 200  # ms
sla_accuracy = 0.85

# Verificar latencia
p95_latency = logs_pd['latency_ms'].quantile(0.95)
if p95_latency > sla_latency:
    print(f"⚠️ ALERTA: Latencia P95 ({p95_latency:.1f}ms) excede SLA ({sla_latency}ms)")
else:
    print(f"✓ Latencia dentro de SLA: {p95_latency:.1f}ms")

# Verificar drift (simulado)
print(f"\n✓ Sistema de monitoreo configurado")
print("  - Logs centralizados en Delta Lake")
print("  - Métricas de latencia tracked")
print("  - Alertas configuradas")

# COMMAND ----------

# MAGIC %md
# MAGIC ### Paso 8: Limpieza (Opcional)

# COMMAND ----------

# MAGIC %md
# MAGIC ```python
# MAGIC # Eliminar endpoint para evitar costos
# MAGIC # deploy_client.delete_endpoint(endpoint_name)
# MAGIC # print(f"✓ Endpoint {endpoint_name} eliminado")
# MAGIC ```

# COMMAND ----------

print("✅ Demo completa finalizada!")
print("""
Resumen:
1. ✓ Modelo preparado y tagged
2. ✓ Endpoint desplegado
3. ✓ Tráfico de prueba generado
4. ✓ Logs registrados en Delta Lake
5. ✓ Métricas analizadas
6. ✓ Alertas configuradas
""")
```

---

## Ejercicios Prácticos

### Ejercicio 1: Implementar A/B Testing

**Objetivo:** Configurar un endpoint que sirva dos versiones del modelo y compare sus resultados.

**Tareas:**
1. Entrenar dos versiones del modelo con parámetros diferentes
2. Desplegar endpoint con traffic splitting (80/20)
3. Generar tráfico y comparar métricas
4. Decidir qué versión promover a 100%

### Ejercicio 2: Sistema de Monitoreo Completo

**Objetivo:** Implementar un pipeline de monitoreo automatizado.

**Tareas:**
1. Crear job que corra diariamente
2. Detectar drift en features
3. Calcular métricas de performance
4. Generar dashboard automático
5. Enviar alertas por Slack/Email

### Ejercicio 3: Optimización de Costos

**Objetivo:** Reducir costos de operación manteniendo SLAs.

**Tareas:**
1. Analizar patrones de tráfico
2. Configurar scale-to-zero
3. Implementar caching de predicciones
4. Comparar costos antes/después

---

## Recursos Adicionales

### Documentación Oficial
- [Databricks Model Serving](https://docs.databricks.com/machine-learning/model-serving/index.html)
- [MLflow Deployments](https://mlflow.org/docs/latest/deployment/index.html)
- [Model Monitoring Best Practices](https://www.databricks.com/blog/2022/04/19/model-monitoring-best-practices.html)

### Herramientas Complementarias
- **Evidently AI**: Detección de drift y monitoreo
- **Seldon Core**: Serving de modelos en Kubernetes
- **Azure Monitor**: Integración para alertas y métricas

### Próximos Pasos
- Laboratorio 6: Orquestación de Pipelines End-to-End
- Laboratorio 7: MLflow Avanzado - Experiments y Registry

---

## Conclusión

En este laboratorio has aprendido a:

✅ Desplegar modelos con batch scoring y endpoints REST  
✅ Configurar autenticación y seguridad  
✅ Implementar monitoreo de métricas y drift  
✅ Configurar alertas automatizadas  
✅ Aplicar buenas prácticas de MLOps en producción  

**Puntos Clave:**
- El despliegue es solo el comienzo; el monitoreo continuo es esencial
- Usar tags y documentación para facilitar la gestión de modelos
- Implementar detección de drift para mantener calidad del modelo
- Automatizar alertas y respuestas a incidentes
- Considerar costos vs. performance en decisiones de arquitectura

---

**¡Felicitaciones!** Has completado el laboratorio de Despliegue y Monitoreo de Modelos. Ahora tienes las habilidades para llevar modelos de ML a producción de forma profesional y escalable.
