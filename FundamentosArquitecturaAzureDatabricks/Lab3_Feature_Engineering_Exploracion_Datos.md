# Laboratorio 3: Feature Engineering y Exploración de Datos en Azure Databricks

**Duración:** 1 hora  
**Nivel:** Fundamentos

## Objetivo

Desarrollar un pipeline reproducible de features listos para modelado usando Azure Databricks, aplicando técnicas de exploración de datos (EDA) y transformación de variables con el dataset de energía mundial.

## Requisitos Previos

- Workspace de Azure Databricks activo
- Cluster en ejecución
- Archivo `owid-energy-data.csv` cargado en DBFS o Azure Storage
- Conocimientos básicos de Python, Pandas y Spark

## Contenido del Laboratorio

### 1. Introducción al Feature Engineering

Feature Engineering es el proceso de transformar datos crudos en características (features) que mejor representan el problema a resolver, mejorando así el rendimiento de los modelos de machine learning.

**Componentes clave:**
- **EDA (Exploratory Data Analysis):** Análisis exploratorio para entender la distribución y relaciones de los datos
- **Transformaciones:** Creación de columnas derivadas, normalización, encoding
- **Imputación:** Manejo de valores faltantes
- **Selección de features:** Identificación de variables relevantes

### 2. Carga y Exploración Inicial de Datos

#### 2.1 Configuración del Entorno

```python
# Importar librerías necesarias
import pandas as pd
import numpy as np
from pyspark.sql import functions as F
from pyspark.sql.types import *
from pyspark.sql.window import Window
import matplotlib.pyplot as plt
import seaborn as sns

# Configuración para visualizaciones
plt.style.use('seaborn-v0_8-darkgrid')
sns.set_palette("husl")
```

#### 2.2 Carga de Datos

```python
# Cargar datos con Spark
df_spark = spark.read.csv(
    "/FileStore/tables/owid-energy-data.csv",
    header=True,
    inferSchema=True
)

# Mostrar esquema
df_spark.printSchema()

# Estadísticas básicas
display(df_spark.describe())

# Conteo de registros
print(f"Total de registros: {df_spark.count()}")
print(f"Total de columnas: {len(df_spark.columns)}")
```

#### 2.3 Conversión a Pandas para EDA Detallado

```python
# Convertir una muestra a Pandas para análisis exploratorio
# (Usar toda la data si es manejable en memoria)
df_pandas = df_spark.toPandas()

# Información general
print(df_pandas.info())
print("\n" + "="*50)
print("Primeras filas:")
display(df_pandas.head(10))
```

### 3. Análisis Exploratorio de Datos (EDA)

#### 3.1 Análisis de Valores Faltantes

```python
# Calcular porcentaje de valores nulos por columna
missing_data = pd.DataFrame({
    'column': df_pandas.columns,
    'missing_count': df_pandas.isnull().sum(),
    'missing_percent': (df_pandas.isnull().sum() / len(df_pandas)) * 100
})

missing_data = missing_data[missing_data['missing_count'] > 0].sort_values(
    'missing_percent', 
    ascending=False
)

print("Columnas con valores faltantes:")
display(missing_data)

# Visualización de valores faltantes
plt.figure(figsize=(12, 6))
top_missing = missing_data.head(20)
plt.barh(top_missing['column'], top_missing['missing_percent'])
plt.xlabel('Porcentaje de Valores Faltantes (%)')
plt.title('Top 20 Columnas con Valores Faltantes')
plt.tight_layout()
plt.show()
```

#### 3.2 Análisis de Variables Numéricas

```python
# Seleccionar columnas numéricas relevantes para análisis
numeric_cols = df_pandas.select_dtypes(include=[np.number]).columns.tolist()

# Estadísticas descriptivas detalladas
display(df_pandas[numeric_cols].describe().T)

# Distribución de variables clave
key_features = [
    'gdp', 
    'population', 
    'primary_energy_consumption',
    'renewables_consumption',
    'fossil_fuel_consumption',
    'greenhouse_gas_emissions'
]

# Filtrar solo las que existen
key_features = [col for col in key_features if col in df_pandas.columns]

# Crear histogramas
fig, axes = plt.subplots(3, 2, figsize=(15, 12))
axes = axes.ravel()

for idx, col in enumerate(key_features):
    if idx < len(axes):
        df_pandas[col].hist(bins=50, ax=axes[idx], edgecolor='black')
        axes[idx].set_title(f'Distribución de {col}')
        axes[idx].set_xlabel(col)
        axes[idx].set_ylabel('Frecuencia')

plt.tight_layout()
plt.show()
```

#### 3.3 Análisis de Correlaciones

```python
# Seleccionar subconjunto de variables para análisis de correlación
energy_features = [col for col in df_pandas.columns 
                   if any(keyword in col.lower() for keyword in 
                   ['energy', 'consumption', 'electricity', 'renewables', 'fossil'])]

# Agregar variables contextuales
correlation_cols = ['year', 'gdp', 'population'] + energy_features[:15]
correlation_cols = [col for col in correlation_cols if col in df_pandas.columns]

# Calcular matriz de correlación
correlation_matrix = df_pandas[correlation_cols].corr()

# Visualizar matriz de correlación
plt.figure(figsize=(16, 14))
sns.heatmap(
    correlation_matrix, 
    annot=True, 
    fmt='.2f', 
    cmap='coolwarm',
    center=0,
    square=True,
    linewidths=0.5
)
plt.title('Matriz de Correlación - Variables de Energía', fontsize=16)
plt.tight_layout()
plt.show()

# Identificar correlaciones fuertes
threshold = 0.7
high_corr = []
for i in range(len(correlation_matrix.columns)):
    for j in range(i+1, len(correlation_matrix.columns)):
        if abs(correlation_matrix.iloc[i, j]) > threshold:
            high_corr.append({
                'Feature 1': correlation_matrix.columns[i],
                'Feature 2': correlation_matrix.columns[j],
                'Correlation': correlation_matrix.iloc[i, j]
            })

print("\nCorrelaciones Fuertes (|r| > 0.7):")
display(pd.DataFrame(high_corr).sort_values('Correlation', ascending=False))
```

#### 3.4 Análisis Temporal y por País

```python
# Análisis de evolución temporal
if 'year' in df_pandas.columns and 'country' in df_pandas.columns:
    # Top 10 países por consumo energético reciente
    recent_year = df_pandas['year'].max()
    top_countries = df_pandas[
        df_pandas['year'] == recent_year
    ].nlargest(10, 'primary_energy_consumption')['country'].tolist()
    
    # Evolución temporal de consumo energético
    plt.figure(figsize=(14, 6))
    for country in top_countries:
        country_data = df_pandas[df_pandas['country'] == country]
        plt.plot(
            country_data['year'], 
            country_data['primary_energy_consumption'],
            label=country,
            marker='o',
            markersize=3
        )
    
    plt.xlabel('Año')
    plt.ylabel('Consumo de Energía Primaria (TWh)')
    plt.title('Evolución del Consumo de Energía - Top 10 Países')
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()
```

### 4. Feature Engineering con PySpark

#### 4.1 Creación de Variables Derivadas

```python
# Volver a trabajar con Spark DataFrame para transformaciones escalables
from pyspark.sql import functions as F
from pyspark.sql.window import Window

# 1. Ratio de energías renovables vs total
df_features = df_spark.withColumn(
    'renewable_ratio',
    F.when(F.col('primary_energy_consumption') > 0,
           F.col('renewables_consumption') / F.col('primary_energy_consumption')
    ).otherwise(0)
)

# 2. Consumo per cápita
df_features = df_features.withColumn(
    'energy_per_capita',
    F.when(F.col('population') > 0,
           F.col('primary_energy_consumption') / F.col('population') * 1000000
    ).otherwise(0)
)

# 3. Intensidad energética (energía por unidad de PIB)
df_features = df_features.withColumn(
    'energy_intensity',
    F.when(F.col('gdp') > 0,
           F.col('primary_energy_consumption') / F.col('gdp')
    ).otherwise(0)
)

# 4. Índice de dependencia de combustibles fósiles
df_features = df_features.withColumn(
    'fossil_dependency_index',
    F.when(F.col('primary_energy_consumption') > 0,
           F.col('fossil_fuel_consumption') / F.col('primary_energy_consumption')
    ).otherwise(0)
)

# 5. Variación año a año (usando Window Functions)
windowSpec = Window.partitionBy('country').orderBy('year')

df_features = df_features.withColumn(
    'energy_yoy_change',
    F.col('primary_energy_consumption') - F.lag('primary_energy_consumption').over(windowSpec)
)

df_features = df_features.withColumn(
    'energy_yoy_pct_change',
    F.when(F.lag('primary_energy_consumption').over(windowSpec) > 0,
           ((F.col('primary_energy_consumption') - F.lag('primary_energy_consumption').over(windowSpec)) / 
            F.lag('primary_energy_consumption').over(windowSpec)) * 100
    ).otherwise(0)
)

# 6. Categorización de países por nivel de desarrollo energético
df_features = df_features.withColumn(
    'energy_development_level',
    F.when(F.col('energy_per_capita') >= 100, 'High')
     .when(F.col('energy_per_capita') >= 50, 'Medium')
     .when(F.col('energy_per_capita') > 0, 'Low')
     .otherwise('Unknown')
)

# Mostrar resultados
display(df_features.select(
    'country', 'year', 'population', 'gdp',
    'renewable_ratio', 'energy_per_capita', 'energy_intensity',
    'fossil_dependency_index', 'energy_development_level'
).orderBy(F.desc('year')))
```

#### 4.2 Imputación de Valores Faltantes

```python
from pyspark.ml.feature import Imputer

# Identificar columnas numéricas con valores nulos
numeric_columns = [field.name for field in df_features.schema.fields 
                   if isinstance(field.dataType, (DoubleType, FloatType, IntegerType, LongType))]

# Estrategia 1: Imputación por media (para variables continuas)
imputer_mean = Imputer(
    inputCols=['gdp', 'population', 'primary_energy_consumption'],
    outputCols=['gdp_imputed', 'population_imputed', 'energy_imputed']
).setStrategy('mean')

# Estrategia 2: Imputación por mediana (más robusta a outliers)
imputer_median = Imputer(
    inputCols=['renewable_ratio', 'energy_per_capita'],
    outputCols=['renewable_ratio_imputed', 'energy_per_capita_imputed']
).setStrategy('median')

# Aplicar imputación
df_imputed = imputer_mean.fit(df_features).transform(df_features)
df_imputed = imputer_median.fit(df_imputed).transform(df_imputed)

# Estrategia 3: Forward fill por país y año (para series temporales)
windowSpec = Window.partitionBy('country').orderBy('year').rowsBetween(Window.unboundedPreceding, 0)

df_imputed = df_imputed.withColumn(
    'gdp_filled',
    F.last('gdp', ignorenulls=True).over(windowSpec)
)

display(df_imputed.select('country', 'year', 'gdp', 'gdp_imputed', 'gdp_filled').limit(20))
```

#### 4.3 Encoding de Variables Categóricas

```python
from pyspark.ml.feature import StringIndexer, OneHotEncoder

# String Indexer para 'country'
country_indexer = StringIndexer(
    inputCol='country',
    outputCol='country_index',
    handleInvalid='keep'
)

df_encoded = country_indexer.fit(df_imputed).transform(df_imputed)

# One-Hot Encoding para nivel de desarrollo
level_indexer = StringIndexer(
    inputCol='energy_development_level',
    outputCol='development_level_index',
    handleInvalid='keep'
)

df_encoded = level_indexer.fit(df_encoded).transform(df_encoded)

encoder = OneHotEncoder(
    inputCols=['development_level_index'],
    outputCols=['development_level_vec']
)

df_encoded = encoder.fit(df_encoded).transform(df_encoded)

display(df_encoded.select(
    'country', 'country_index', 
    'energy_development_level', 'development_level_index', 'development_level_vec'
).limit(10))
```

#### 4.4 Escalado y Normalización

```python
from pyspark.ml.feature import VectorAssembler, StandardScaler, MinMaxScaler

# Seleccionar features para escalado
features_to_scale = [
    'energy_per_capita_imputed',
    'renewable_ratio_imputed',
    'energy_intensity',
    'fossil_dependency_index'
]

# Ensamblar features en un vector
assembler = VectorAssembler(
    inputCols=features_to_scale,
    outputCol='features_raw'
)

df_assembled = assembler.transform(df_encoded)

# StandardScaler (Z-score normalization: media=0, std=1)
standard_scaler = StandardScaler(
    inputCol='features_raw',
    outputCol='features_standardized',
    withMean=True,
    withStd=True
)

scaler_model = standard_scaler.fit(df_assembled)
df_scaled = scaler_model.transform(df_assembled)

# MinMaxScaler (escalado a rango [0,1])
minmax_scaler = MinMaxScaler(
    inputCol='features_raw',
    outputCol='features_normalized'
)

minmax_model = minmax_scaler.fit(df_assembled)
df_scaled = minmax_model.transform(df_scaled)

display(df_scaled.select(
    'country', 'year', 
    'features_raw', 'features_standardized', 'features_normalized'
).limit(10))
```

### 5. Selección de Features

#### 5.1 Análisis de Importancia con Spark

```python
# Calcular varianza de features
from pyspark.ml.stat import Correlation

# Correlación de Pearson
correlation_matrix = Correlation.corr(df_scaled, 'features_raw', 'pearson')
print("Matriz de Correlación:")
correlation_matrix.show(truncate=False)

# Filtrar features con baja varianza
from pyspark.ml.feature import VarianceThresholdSelector

# Las features con varianza muy baja tienen poco poder predictivo
variance_selector = VarianceThresholdSelector(
    featuresCol='features_standardized',
    outputCol='features_selected',
    varianceThreshold=0.1
)

# Aplicar selector
variance_model = variance_selector.fit(df_scaled)
df_selected = variance_model.transform(df_scaled)

print(f"Features originales: {len(features_to_scale)}")
print(f"Features después de filtrar por varianza: {len(variance_model.selectedFeatures)}")
```

#### 5.2 Creación de Dataset Final para Modelado

```python
# Seleccionar features finales y target
final_features = [
    'country', 'year', 
    'renewable_ratio_imputed',
    'energy_per_capita_imputed',
    'energy_intensity',
    'fossil_dependency_index',
    'energy_yoy_pct_change',
    'country_index',
    'development_level_index',
    'features_standardized'
]

# Crear dataset final
df_final = df_scaled.select(final_features)

# Filtrar registros completos (opcional)
df_final = df_final.na.drop(subset=['renewable_ratio_imputed', 'energy_per_capita_imputed'])

# Estadísticas del dataset final
print(f"Registros finales: {df_final.count()}")
print(f"Features: {len(final_features)}")

display(df_final.limit(20))
```

### 6. Persistencia en Delta Lake

#### 6.1 Guardar Features en Delta Table

```python
# Definir ruta para Delta Table
delta_path = "/delta/energy_features"

# Guardar como Delta Table con particionamiento
df_final.write \
    .format("delta") \
    .mode("overwrite") \
    .partitionBy("year") \
    .option("overwriteSchema", "true") \
    .save(delta_path)

print(f"Features guardados en Delta Lake: {delta_path}")

# Crear tabla en el metastore
df_final.write \
    .format("delta") \
    .mode("overwrite") \
    .partitionBy("year") \
    .saveAsTable("energy_features_table")

print("Tabla 'energy_features_table' creada exitosamente")
```

#### 6.2 Verificar Delta Table

```python
# Leer desde Delta Table
df_from_delta = spark.read.format("delta").load(delta_path)

print("Esquema de la tabla Delta:")
df_from_delta.printSchema()

# Contar registros por año
display(df_from_delta.groupBy("year").count().orderBy("year"))

# Verificar historial de versiones
from delta.tables import DeltaTable

delta_table = DeltaTable.forPath(spark, delta_path)
display(delta_table.history())
```

### 7. Buenas Prácticas de Feature Engineering

#### 7.1 Control de Data Drift

```python
# Calcular estadísticas por período
from pyspark.sql import functions as F

# Dividir datos en períodos
df_with_period = df_final.withColumn(
    'period',
    F.when(F.col('year') < 2000, 'pre_2000')
     .when(F.col('year') < 2010, '2000-2009')
     .when(F.col('year') < 2020, '2010-2019')
     .otherwise('2020+')
)

# Comparar distribuciones por período
drift_analysis = df_with_period.groupBy('period').agg(
    F.mean('energy_per_capita_imputed').alias('avg_energy_per_capita'),
    F.stddev('energy_per_capita_imputed').alias('std_energy_per_capita'),
    F.mean('renewable_ratio_imputed').alias('avg_renewable_ratio'),
    F.stddev('renewable_ratio_imputed').alias('std_renewable_ratio'),
    F.count('*').alias('record_count')
).orderBy('period')

print("Análisis de Drift por Período:")
display(drift_analysis)
```

#### 7.2 Validación de Calidad de Datos

```python
from pyspark.sql.functions import col, isnan, when, count

# Función de validación de calidad
def data_quality_check(df, columns_to_check):
    """
    Genera reporte de calidad de datos
    """
    quality_metrics = []
    
    for column in columns_to_check:
        # Conteo de valores nulos
        null_count = df.filter(col(column).isNull()).count()
        
        # Conteo de valores negativos (si es numérico)
        negative_count = df.filter(col(column) < 0).count()
        
        # Valores únicos
        distinct_count = df.select(column).distinct().count()
        
        quality_metrics.append({
            'column': column,
            'null_count': null_count,
            'null_percentage': (null_count / df.count()) * 100,
            'negative_count': negative_count,
            'distinct_values': distinct_count
        })
    
    return spark.createDataFrame(quality_metrics)

# Aplicar validación
columns_to_validate = [
    'renewable_ratio_imputed',
    'energy_per_capita_imputed',
    'energy_intensity',
    'fossil_dependency_index'
]

quality_report = data_quality_check(df_final, columns_to_validate)
display(quality_report)
```

#### 7.3 Documentación de Features

```python
# Crear diccionario de features
feature_dictionary = {
    'renewable_ratio': {
        'description': 'Ratio de energías renovables vs consumo total de energía',
        'formula': 'renewables_consumption / primary_energy_consumption',
        'range': '[0, 1]',
        'type': 'numeric - continuous',
        'imputation': 'median'
    },
    'energy_per_capita': {
        'description': 'Consumo de energía por persona en kWh',
        'formula': '(primary_energy_consumption / population) * 1000000',
        'range': '[0, +inf]',
        'type': 'numeric - continuous',
        'imputation': 'median'
    },
    'energy_intensity': {
        'description': 'Consumo de energía por unidad de PIB',
        'formula': 'primary_energy_consumption / gdp',
        'range': '[0, +inf]',
        'type': 'numeric - continuous',
        'imputation': 'mean'
    },
    'fossil_dependency_index': {
        'description': 'Índice de dependencia de combustibles fósiles',
        'formula': 'fossil_fuel_consumption / primary_energy_consumption',
        'range': '[0, 1]',
        'type': 'numeric - continuous',
        'imputation': 'mean'
    },
    'energy_development_level': {
        'description': 'Nivel de desarrollo energético del país',
        'formula': 'Categorización basada en energy_per_capita',
        'categories': ['Low', 'Medium', 'High', 'Unknown'],
        'type': 'categorical',
        'encoding': 'one-hot'
    }
}

# Guardar diccionario como JSON
import json

# Convertir a JSON y mostrar
feature_dict_json = json.dumps(feature_dictionary, indent=2)
print("Diccionario de Features:")
print(feature_dict_json)

# Guardar en DBFS
dbutils.fs.put(
    "/FileStore/energy_features_dictionary.json",
    feature_dict_json,
    overwrite=True
)
```

### 8. Feature Store de Databricks (Opcional)

#### 8.1 Creación de Feature Store

```python
from databricks import feature_store
from databricks.feature_store import feature_table

# Inicializar Feature Store client
fs = feature_store.FeatureStoreClient()

# Preparar DataFrame con primary keys
df_feature_store = df_final.select(
    'country',
    'year',
    'renewable_ratio_imputed',
    'energy_per_capita_imputed',
    'energy_intensity',
    'fossil_dependency_index',
    'energy_yoy_pct_change'
)

# Crear Feature Table
try:
    fs.create_table(
        name='default.energy_features_fs',
        primary_keys=['country', 'year'],
        df=df_feature_store,
        partition_columns=['year'],
        description='Features de energía mundial para modelado predictivo'
    )
    print("Feature Table creada exitosamente")
except Exception as e:
    print(f"Feature Table ya existe o error: {e}")
    # Actualizar si ya existe
    fs.write_table(
        name='default.energy_features_fs',
        df=df_feature_store,
        mode='overwrite'
    )
    print("Feature Table actualizada")
```

#### 8.2 Consultar Feature Store

```python
# Leer features desde Feature Store
features_from_fs = fs.read_table(name='default.energy_features_fs')

display(features_from_fs.limit(20))

# Obtener metadata
feature_table_metadata = fs.get_table('default.energy_features_fs')
print(f"Descripción: {feature_table_metadata.description}")
print(f"Primary Keys: {feature_table_metadata.primary_keys}")
print(f"Particiones: {feature_table_metadata.partition_columns}")
```

### 9. Pipeline Completo Reproducible

#### 9.1 Función de Pipeline End-to-End

```python
def energy_feature_pipeline(input_path, output_path, imputation_strategy='median'):
    """
    Pipeline completo de feature engineering para datos de energía
    
    Args:
        input_path: Ruta al archivo CSV de entrada
        output_path: Ruta de salida para Delta Table
        imputation_strategy: Estrategia de imputación ('mean', 'median')
    
    Returns:
        DataFrame con features procesados
    """
    from pyspark.ml.feature import Imputer, StringIndexer, VectorAssembler, StandardScaler
    
    # 1. Carga de datos
    df = spark.read.csv(input_path, header=True, inferSchema=True)
    print(f"✓ Datos cargados: {df.count()} registros")
    
    # 2. Feature Engineering
    df = df.withColumn(
        'renewable_ratio',
        F.when(F.col('primary_energy_consumption') > 0,
               F.col('renewables_consumption') / F.col('primary_energy_consumption')
        ).otherwise(0)
    )
    
    df = df.withColumn(
        'energy_per_capita',
        F.when(F.col('population') > 0,
               F.col('primary_energy_consumption') / F.col('population') * 1000000
        ).otherwise(0)
    )
    
    df = df.withColumn(
        'energy_intensity',
        F.when(F.col('gdp') > 0,
               F.col('primary_energy_consumption') / F.col('gdp')
        ).otherwise(0)
    )
    
    df = df.withColumn(
        'fossil_dependency_index',
        F.when(F.col('primary_energy_consumption') > 0,
               F.col('fossil_fuel_consumption') / F.col('primary_energy_consumption')
        ).otherwise(0)
    )
    
    print("✓ Features derivados creados")
    
    # 3. Imputación
    imputer = Imputer(
        inputCols=['renewable_ratio', 'energy_per_capita', 'energy_intensity'],
        outputCols=['renewable_ratio_imputed', 'energy_per_capita_imputed', 'energy_intensity_imputed']
    ).setStrategy(imputation_strategy)
    
    df = imputer.fit(df).transform(df)
    print(f"✓ Imputación completada (estrategia: {imputation_strategy})")
    
    # 4. Encoding
    indexer = StringIndexer(inputCol='country', outputCol='country_index', handleInvalid='keep')
    df = indexer.fit(df).transform(df)
    print("✓ Encoding completado")
    
    # 5. Escalado
    assembler = VectorAssembler(
        inputCols=['renewable_ratio_imputed', 'energy_per_capita_imputed', 'energy_intensity_imputed'],
        outputCol='features_raw'
    )
    df = assembler.transform(df)
    
    scaler = StandardScaler(inputCol='features_raw', outputCol='features_scaled', withMean=True, withStd=True)
    df = scaler.fit(df).transform(df)
    print("✓ Escalado completado")
    
    # 6. Persistencia
    df.write.format("delta").mode("overwrite").partitionBy("year").save(output_path)
    print(f"✓ Datos guardados en: {output_path}")
    
    return df

# Ejecutar pipeline
result_df = energy_feature_pipeline(
    input_path="/FileStore/tables/owid-energy-data.csv",
    output_path="/delta/energy_features_pipeline",
    imputation_strategy='median'
)

print("\n" + "="*50)
print("PIPELINE COMPLETADO EXITOSAMENTE")
print("="*50)
```

### 10. Ejercicios Prácticos

#### Ejercicio 1: Crear Nuevos Features
Crea los siguientes features adicionales:
- Ratio de energía nuclear vs total
- Tasa de crecimiento poblacional año a año
- Índice de electrificación (electricidad vs energía total)

#### Ejercicio 2: Análisis de Outliers
Identifica y maneja outliers en las variables numéricas usando:
- Método IQR (Rango Intercuartílico)
- Z-score
- Visualizaciones box plot

#### Ejercicio 3: Feature Selection Avanzado
Implementa selección de features usando:
- Chi-squared test para variables categóricas
- Correlación con variable objetivo
- Recursive Feature Elimination (RFE)

#### Ejercicio 4: Validación Temporal
Crea una función que valide que no haya data leakage temporal:
- Features calculados solo con datos históricos
- Validación de fechas
- Split temporal para train/test

### 11. Resumen y Mejores Prácticas

#### Checklist de Feature Engineering

- [ ] **EDA Completo**: Entender distribuciones, correlaciones y patrones
- [ ] **Manejo de Nulos**: Estrategia documentada de imputación
- [ ] **Features Derivados**: Crear variables con significado de negocio
- [ ] **Escalado**: Normalizar features para algoritmos sensibles a escala
- [ ] **Encoding**: Convertir variables categóricas correctamente
- [ ] **Documentación**: Diccionario de features actualizado
- [ ] **Validación**: Quality checks y detección de drift
- [ ] **Versionado**: Features guardados en Delta Lake con historial
- [ ] **Reproducibilidad**: Pipeline automatizado y parametrizado
- [ ] **Particionamiento**: Datos particionados por fecha para eficiencia

#### Métricas de Calidad

```python
# Reporte final de calidad
def generate_quality_report(df):
    """Genera reporte de calidad de features"""
    report = {
        'total_records': df.count(),
        'total_features': len(df.columns),
        'null_percentage': (df.select([
            F.count(F.when(F.col(c).isNull(), c)).alias(c) 
            for c in df.columns
        ]).first().asDict()),
        'numeric_features': len([f for f in df.schema.fields 
                                if isinstance(f.dataType, (DoubleType, FloatType))]),
        'categorical_features': len([f for f in df.schema.fields 
                                    if isinstance(f.dataType, StringType)])
    }
    return report

quality_metrics = generate_quality_report(df_final)
print("Reporte de Calidad Final:")
print(json.dumps(quality_metrics, indent=2))
```

### 12. Recursos Adicionales

- **Documentación de PySpark ML**: https://spark.apache.org/docs/latest/ml-guide.html
- **Delta Lake Best Practices**: https://docs.delta.io/latest/best-practices.html
- **Databricks Feature Store**: https://docs.databricks.com/machine-learning/feature-store/
- **Feature Engineering Book**: "Feature Engineering for Machine Learning" by Alice Zheng

### 13. Próximos Pasos

En el siguiente laboratorio aprenderás:
- Construcción de modelos de ML con los features creados
- Integración con MLflow para tracking de experimentos
- Deployment de modelos en producción
- Monitoreo de performance y drift en producción

---

## Conclusión

Has completado exitosamente el laboratorio de Feature Engineering y Exploración de Datos. Ahora tienes las habilidades para:

✅ Realizar análisis exploratorio completo con Pandas y Spark  
✅ Crear features derivados con significado de negocio  
✅ Implementar pipelines reproducibles de transformación  
✅ Manejar valores faltantes y outliers  
✅ Persistir features en Delta Lake y Feature Store  
✅ Validar calidad y detectar drift en datos  

**¡Excelente trabajo!** Estos features están listos para ser utilizados en modelos de machine learning.
