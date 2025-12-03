# Laboratorio 2: Preparación y Procesamiento de Datos en Azure Databricks

**Duración:** 1 hora  
**Nivel:** Fundamentos

## Objetivo

Aprender a transformar, limpiar y estructurar datos para analítica y Machine Learning usando Azure Databricks, implementando pipelines ETL robustos y escalables con Delta Lake.

## Prerrequisitos

- Workspace de Azure Databricks activo
- Cluster en ejecución
- Cuenta activa en Azure con permisos para crear recursos
- Conocimientos básicos de:
  - Python y SQL
  - Conceptos de Big Data
  - Almacenamiento en la nube
- Acceso a:
  - Azure Portal
  - Workspace de Azure Databricks (con cluster disponible)

## Contenido del Laboratorio

### 1. Introducción a los Notebooks de Databricks

Azure Databricks soporta múltiples lenguajes dentro del mismo notebook, permitiendo flexibilidad y colaboración entre equipos de datos.

**Lenguajes soportados:**
- **Python (PySpark)**: Procesamiento de datos distribuido con API Python
- **SQL**: Consultas y análisis de datos estructurados
- **Scala**: Lenguaje nativo de Spark para máximo rendimiento
- **R**: Análisis estadístico y visualizaciones

**Comandos mágicos:**
- `%python` - Ejecutar código Python
- `%sql` - Ejecutar consultas SQL
- `%scala` - Ejecutar código Scala
- `%r` - Ejecutar código R
- `%md` - Markdown para documentación
- `%sh` - Comandos shell
- `%fs` - Sistema de archivos de Databricks

### 2. Exploración Inicial de Datos

#### 2.1 Carga de Datos con Spark

```python
# Cargar datos CSV con Spark
df = spark.read.format("csv") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .load("/FileStore/tables/owid-energy-data.csv")

# Mostrar esquema inferido
df.printSchema()

# Estadísticas básicas
display(df.describe())

# Conteo de registros
print(f"Total de registros: {df.count():,}")
print(f"Total de columnas: {len(df.columns)}")
```

#### 2.2 Exploración con SQL

```sql
-- Crear vista temporal para consultas SQL
CREATE OR REPLACE TEMP VIEW energy_data AS
SELECT * FROM df;

-- Consulta exploratoria
SELECT 
    country,
    year,
    population,
    gdp,
    primary_energy_consumption
FROM energy_data
WHERE year >= 2010
ORDER BY primary_energy_consumption DESC
LIMIT 10;
```

#### 2.3 Análisis de Calidad de Datos

```python
from pyspark.sql import functions as F

# Análisis de valores nulos
null_counts = df.select([
    F.count(F.when(F.col(c).isNull(), c)).alias(c) 
    for c in df.columns
])

display(null_counts)

# Duplicados por país y año
duplicates = df.groupBy("country", "year").count().filter(F.col("count") > 1)
print(f"Registros duplicados: {duplicates.count()}")
```

### 3. Ingesta de Datos con Auto Loader

Auto Loader es una funcionalidad de Databricks para ingesta incremental de datos de forma eficiente.

#### 3.1 Configuración de Auto Loader

```python
# Directorio de origen
source_path = "/FileStore/tables/raw_data/"

# Configurar Auto Loader
df_autoloader = spark.readStream \
    .format("cloudFiles") \
    .option("cloudFiles.format", "csv") \
    .option("cloudFiles.schemaLocation", "/tmp/schema_inference") \
    .option("header", "true") \
    .load(source_path)

# Escribir stream a Delta
query = df_autoloader.writeStream \
    .format("delta") \
    .option("checkpointLocation", "/tmp/checkpoint") \
    .outputMode("append") \
    .start("/delta/energy_raw")
```

#### 3.2 Ventajas de Auto Loader

- **Escalabilidad**: Maneja millones de archivos eficientemente
- **Schema inference**: Detecta automáticamente el esquema
- **Schema evolution**: Se adapta a cambios en el esquema
- **Exactamente una vez**: Garantiza que cada archivo se procesa una sola vez
- **Optimización de costos**: Usa notificaciones de eventos cuando es posible

### 4. Limpieza y Transformación con PySpark

#### 4.1 Limpieza de Datos

```python
from pyspark.sql import functions as F
from pyspark.sql.types import DoubleType, IntegerType

# 1. Eliminar duplicados
df_clean = df.dropDuplicates(["country", "year"])

# 2. Filtrar registros válidos
df_clean = df_clean.filter(
    (F.col("country").isNotNull()) & 
    (F.col("year").isNotNull()) &
    (F.col("year") >= 1900)
)

# 3. Manejar valores nulos - Estrategia por columna
# Imputar con 0 para consumos energéticos
energy_cols = [
    "primary_energy_consumption",
    "renewables_consumption",
    "fossil_fuel_consumption"
]

for col in energy_cols:
    df_clean = df_clean.withColumn(
        col,
        F.when(F.col(col).isNull(), 0).otherwise(F.col(col))
    )

# Imputar con mediana para variables demográficas
from pyspark.ml.feature import Imputer

imputer = Imputer(
    inputCols=["population", "gdp"],
    outputCols=["population_imputed", "gdp_imputed"]
).setStrategy("median")

df_clean = imputer.fit(df_clean).transform(df_clean)

# 4. Normalizar nombres de países
df_clean = df_clean.withColumn(
    "country",
    F.trim(F.upper(F.col("country")))
)

print(f"Registros después de limpieza: {df_clean.count():,}")
```

#### 4.2 Transformaciones de Datos

```python
# 1. Crear columnas calculadas
df_transformed = df_clean.withColumn(
    "renewable_ratio",
    F.when(F.col("primary_energy_consumption") > 0,
           F.col("renewables_consumption") / F.col("primary_energy_consumption")
    ).otherwise(0)
)

df_transformed = df_transformed.withColumn(
    "energy_per_capita",
    F.when(F.col("population_imputed") > 0,
           F.col("primary_energy_consumption") / F.col("population_imputed") * 1000000
    ).otherwise(0)
)

df_transformed = df_transformed.withColumn(
    "energy_intensity",
    F.when(F.col("gdp_imputed") > 0,
           F.col("primary_energy_consumption") / F.col("gdp_imputed")
    ).otherwise(0)
)

# 2. Categorización
df_transformed = df_transformed.withColumn(
    "decade",
    (F.floor(F.col("year") / 10) * 10).cast(IntegerType())
)

df_transformed = df_transformed.withColumn(
    "consumption_level",
    F.when(F.col("energy_per_capita") >= 100, "High")
     .when(F.col("energy_per_capita") >= 50, "Medium")
     .when(F.col("energy_per_capita") > 0, "Low")
     .otherwise("Unknown")
)

# 3. Agregaciones por región/década
df_aggregated = df_transformed.groupBy("country", "decade").agg(
    F.avg("primary_energy_consumption").alias("avg_energy_consumption"),
    F.avg("renewable_ratio").alias("avg_renewable_ratio"),
    F.sum("population_imputed").alias("total_population"),
    F.count("*").alias("record_count")
)

display(df_aggregated.orderBy("decade", "country").limit(20))
```

#### 4.3 Validación de Datos

```python
# Función de validación de calidad
def validate_data_quality(df, rules):
    """
    Valida reglas de calidad en el DataFrame
    
    Args:
        df: DataFrame de Spark
        rules: Diccionario con reglas de validación
    
    Returns:
        DataFrame con resultados de validación
    """
    validation_results = []
    
    for rule_name, rule_condition in rules.items():
        passed = df.filter(rule_condition).count()
        total = df.count()
        failed = total - passed
        
        validation_results.append({
            "rule": rule_name,
            "total_records": total,
            "passed": passed,
            "failed": failed,
            "pass_rate": (passed / total * 100) if total > 0 else 0
        })
    
    return spark.createDataFrame(validation_results)

# Definir reglas de validación
validation_rules = {
    "year_in_range": (F.col("year") >= 1900) & (F.col("year") <= 2025),
    "population_positive": F.col("population_imputed") >= 0,
    "energy_non_negative": F.col("primary_energy_consumption") >= 0,
    "renewable_ratio_valid": (F.col("renewable_ratio") >= 0) & (F.col("renewable_ratio") <= 1),
    "country_not_null": F.col("country").isNotNull()
}

# Ejecutar validación
validation_report = validate_data_quality(df_transformed, validation_rules)
display(validation_report)
```

### 5. Delta Lake: Almacenamiento ACID

Delta Lake es una capa de almacenamiento open-source que proporciona transacciones ACID, versionado y optimizaciones de performance sobre data lakes.

#### 5.1 Crear Tabla Delta

```python
# Definir ruta para Delta Lake
delta_path = "/delta/energy_processed"

# Escribir datos como tabla Delta
df_transformed.write \
    .format("delta") \
    .mode("overwrite") \
    .option("overwriteSchema", "true") \
    .save(delta_path)

print(f"✓ Tabla Delta creada en: {delta_path}")

# Crear tabla en metastore para consultas SQL
df_transformed.write \
    .format("delta") \
    .mode("overwrite") \
    .option("overwriteSchema", "true") \
    .saveAsTable("energy_processed")

print("✓ Tabla 'energy_processed' registrada en metastore")
```

#### 5.2 Versionado y Time Travel

```python
from delta.tables import DeltaTable

# Obtener tabla Delta
delta_table = DeltaTable.forPath(spark, delta_path)

# Ver historial de versiones
history = delta_table.history()
display(history.select("version", "timestamp", "operation", "operationMetrics"))

# Time Travel: Leer versión anterior
df_version_0 = spark.read \
    .format("delta") \
    .option("versionAsOf", 0) \
    .load(delta_path)

print(f"Registros en versión 0: {df_version_0.count():,}")

# Time Travel: Leer datos de una fecha específica
from datetime import datetime, timedelta

yesterday = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
# df_yesterday = spark.read.format("delta").option("timestampAsOf", yesterday).load(delta_path)
```

#### 5.3 Operaciones ACID

```python
# 1. UPDATE: Actualizar registros específicos
delta_table.update(
    condition="year = 2020 AND country = 'UNITED STATES'",
    set={"consumption_level": "'Updated'"}
)

# 2. DELETE: Eliminar registros
delta_table.delete(condition="year < 1950")

# 3. MERGE (UPSERT): Combinar datos nuevos
new_data = spark.createDataFrame([
    ("BRAZIL", 2024, 5000.0, 0.45, "High"),
    ("INDIA", 2024, 6000.0, 0.35, "Medium")
], ["country", "year", "primary_energy_consumption", "renewable_ratio", "consumption_level"])

delta_table.alias("target").merge(
    new_data.alias("source"),
    "target.country = source.country AND target.year = source.year"
).whenMatchedUpdateAll() \
 .whenNotMatchedInsertAll() \
 .execute()

print("✓ Operación MERGE completada")

# Verificar historial después de operaciones
display(delta_table.history().select("version", "operation", "operationMetrics").limit(5))
```

### 6. Optimización de Delta Tables

#### 6.1 Particionamiento

```python
# Escribir tabla Delta con particionamiento
df_transformed.write \
    .format("delta") \
    .mode("overwrite") \
    .partitionBy("decade", "consumption_level") \
    .option("overwriteSchema", "true") \
    .save("/delta/energy_partitioned")

print("✓ Tabla particionada creada")

# Ventajas del particionamiento:
# - Mejora performance de queries con filtros en columnas de partición
# - Facilita data lifecycle management
# - Reduce costos de lectura al escanear solo particiones relevantes
```

#### 6.2 OPTIMIZE y Z-ORDER

```python
# OPTIMIZE: Compacta archivos pequeños
spark.sql("""
    OPTIMIZE delta.`/delta/energy_processed`
""")

# Z-ORDER: Optimiza para queries frecuentes en columnas específicas
spark.sql("""
    OPTIMIZE delta.`/delta/energy_processed`
    ZORDER BY (country, year)
""")

print("✓ Optimización completada")

# Beneficios:
# - OPTIMIZE reduce el número de archivos pequeños
# - Z-ORDER agrupa datos relacionados para mejorar data skipping
# - Mejora significativa en performance de lectura
```

#### 6.3 VACUUM: Limpieza de Archivos Antiguos

```python
# Ver archivos que se pueden limpiar (dry run)
spark.sql("""
    VACUUM delta.`/delta/energy_processed` RETAIN 168 HOURS DRY RUN
""")

# Ejecutar limpieza (elimina archivos con más de 7 días)
# CUIDADO: Esto elimina versiones antiguas permanentemente
spark.sql("""
    VACUUM delta.`/delta/energy_processed` RETAIN 168 HOURS
""")

print("✓ Limpieza de archivos antiguos completada")
```

### 7. Esquema Evolutivo (Schema Evolution)

#### 7.1 Agregar Nuevas Columnas

```python
# Habilitar schema evolution
spark.conf.set("spark.databricks.delta.schema.autoMerge.enabled", "true")

# DataFrame con nuevas columnas
df_new_schema = df_transformed.withColumn(
    "carbon_intensity",
    F.when(F.col("primary_energy_consumption") > 0,
           F.col("fossil_fuel_consumption") / F.col("primary_energy_consumption")
    ).otherwise(0)
).withColumn(
    "data_quality_score",
    F.lit(1.0)
)

# Escribir con merge de esquema
df_new_schema.write \
    .format("delta") \
    .mode("append") \
    .option("mergeSchema", "true") \
    .save(delta_path)

print("✓ Esquema actualizado con nuevas columnas")

# Verificar nuevo esquema
delta_table_updated = DeltaTable.forPath(spark, delta_path)
display(spark.read.format("delta").load(delta_path).limit(5))
```

#### 7.2 Cambiar Tipos de Datos

```python
# Cambiar tipo de columna
spark.sql(f"""
    ALTER TABLE delta.`{delta_path}`
    ALTER COLUMN energy_per_capita TYPE DECIMAL(18,4)
""")

print("✓ Tipo de columna actualizado")
```

### 8. Pipeline ETL Completo

#### 8.1 Función de Pipeline End-to-End

```python
def etl_pipeline(source_path, target_path, partition_cols=None):
    """
    Pipeline ETL completo: Extract, Transform, Load
    
    Args:
        source_path: Ruta al archivo fuente
        target_path: Ruta de destino para Delta Table
        partition_cols: Lista de columnas para particionar
    
    Returns:
        Número de registros procesados
    """
    print("="*60)
    print("INICIANDO PIPELINE ETL")
    print("="*60)
    
    # EXTRACT
    print("\n[1/4] EXTRACT - Cargando datos...")
    df_raw = spark.read.format("csv") \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .load(source_path)
    
    initial_count = df_raw.count()
    print(f"✓ Registros cargados: {initial_count:,}")
    
    # TRANSFORM - Limpieza
    print("\n[2/4] TRANSFORM - Limpiando datos...")
    df_clean = df_raw.dropDuplicates(["country", "year"]) \
        .filter((F.col("country").isNotNull()) & (F.col("year").isNotNull()))
    
    # Imputar valores nulos
    for col_name in ["population", "gdp", "primary_energy_consumption"]:
        if col_name in df_clean.columns:
            df_clean = df_clean.withColumn(
                col_name,
                F.when(F.col(col_name).isNull(), 0).otherwise(F.col(col_name))
            )
    
    clean_count = df_clean.count()
    print(f"✓ Registros después de limpieza: {clean_count:,} ({initial_count - clean_count:,} eliminados)")
    
    # TRANSFORM - Features
    print("\n[3/4] TRANSFORM - Creando features...")
    df_transformed = df_clean \
        .withColumn("renewable_ratio",
                   F.when(F.col("primary_energy_consumption") > 0,
                         F.col("renewables_consumption") / F.col("primary_energy_consumption"))
                   .otherwise(0)) \
        .withColumn("decade", (F.floor(F.col("year") / 10) * 10).cast(IntegerType())) \
        .withColumn("processing_timestamp", F.current_timestamp())
    
    print(f"✓ Features creados: renewable_ratio, decade, processing_timestamp")
    
    # LOAD
    print("\n[4/4] LOAD - Guardando en Delta Lake...")
    writer = df_transformed.write \
        .format("delta") \
        .mode("overwrite") \
        .option("overwriteSchema", "true")
    
    if partition_cols:
        writer = writer.partitionBy(*partition_cols)
        print(f"✓ Particionado por: {', '.join(partition_cols)}")
    
    writer.save(target_path)
    
    # OPTIMIZE
    print("\n[5/4] BONUS - Optimizando Delta Table...")
    spark.sql(f"OPTIMIZE delta.`{target_path}` ZORDER BY (country, year)")
    
    print("\n" + "="*60)
    print("PIPELINE ETL COMPLETADO CON ÉXITO")
    print("="*60)
    print(f"📊 Registros procesados: {clean_count:,}")
    print(f"📁 Ubicación: {target_path}")
    print(f"⚡ Optimizado con Z-ORDER")
    
    return clean_count

# Ejecutar pipeline
records_processed = etl_pipeline(
    source_path="/FileStore/tables/owid-energy-data.csv",
    target_path="/delta/energy_final",
    partition_cols=["decade"]
)
```

#### 8.2 Monitoreo y Logging

```python
# Función de monitoreo
def monitor_delta_table(delta_path):
    """
    Genera reporte de salud de tabla Delta
    """
    delta_table = DeltaTable.forPath(spark, delta_path)
    
    # Estadísticas de la tabla
    df = spark.read.format("delta").load(delta_path)
    
    report = {
        "total_records": df.count(),
        "total_columns": len(df.columns),
        "table_size_mb": spark.sql(f"DESCRIBE DETAIL delta.`{delta_path}`").select("sizeInBytes").first()[0] / (1024*1024),
        "number_of_files": spark.sql(f"DESCRIBE DETAIL delta.`{delta_path}`").select("numFiles").first()[0],
        "latest_version": delta_table.history().select("version").first()[0]
    }
    
    print("="*60)
    print("REPORTE DE SALUD - DELTA TABLE")
    print("="*60)
    for key, value in report.items():
        print(f"{key.replace('_', ' ').title()}: {value:,.2f}" if isinstance(value, float) else f"{key.replace('_', ' ').title()}: {value:,}")
    print("="*60)
    
    return report

# Generar reporte
health_report = monitor_delta_table("/delta/energy_final")
```

### 9. Buenas Prácticas

#### Checklist de ETL con Delta Lake

- [ ] **Validación de datos**: Implementar quality checks antes y después de transformaciones
- [ ] **Particionamiento inteligente**: Particionar por columnas usadas frecuentemente en filtros
- [ ] **OPTIMIZE regular**: Programar OPTIMIZE para mantener performance óptimo
- [ ] **Z-ORDER estratégico**: Aplicar en columnas de alta cardinalidad usadas en joins y filtros
- [ ] **VACUUM periódico**: Limpiar archivos antiguos balanceando Time Travel vs storage costs
- [ ] **Schema evolution controlado**: Documentar cambios de esquema y usar mergeSchema con cuidado
- [ ] **Monitoreo**: Trackear métricas de performance y tamaño de tablas
- [ ] **Documentación**: Mantener catálogo de datos actualizado
- [ ] **Testing**: Validar pipelines con datos de prueba
- [ ] **Idempotencia**: Diseñar pipelines que puedan re-ejecutarse sin efectos secundarios

### 10. Comparación: CSV vs Parquet vs Delta Lake

| Característica | CSV | Parquet | Delta Lake |
|----------------|-----|---------|------------|
| **Formato** | Texto plano | Columnar binario | Parquet + Transaction log |
| **Compresión** | Limitada | Alta | Alta |
| **Performance lectura** | Lenta | Rápida | Muy rápida |
| **Soporte ACID** | ❌ | ❌ | ✅ |
| **Schema evolution** | Manual | Limitado | Automático |
| **Time Travel** | ❌ | ❌ | ✅ |
| **Upserts/Merges** | ❌ | ❌ | ✅ |
| **Optimización** | ❌ | Limitada | Avanzada (Z-ORDER) |
| **Streaming** | Limitado | Parcial | Nativo |
| **Uso recomendado** | Intercambio simple | Data warehouse | Data lakehouse |

### 11. Ejercicios Prácticos

#### Ejercicio 1: Pipeline ETL Personalizado
Crea un pipeline ETL que:
- Lea datos de múltiples fuentes CSV
- Aplique reglas de limpieza específicas
- Cree al menos 5 features derivados
- Guarde en Delta Lake particionado por año
- Genere reporte de calidad

#### Ejercicio 2: Optimización de Performance
Optimiza una tabla Delta existente:
- Identifica columnas para Z-ORDER
- Implementa particionamiento efectivo
- Mide improvement en query performance
- Documenta resultados

#### Ejercicio 3: Schema Evolution
Simula evolución de esquema:
- Agrega nuevas columnas
- Cambia tipos de datos
- Maneja datos legacy
- Mantén compatibilidad hacia atrás

#### Ejercicio 4: Time Travel y Auditoría
Implementa sistema de auditoría:
- Trackea cambios en datos críticos
- Usa Time Travel para recuperar versiones anteriores
- Crea reporte de cambios históricos
- Implementa rollback strategy

### 12. Recursos Adicionales

- **Delta Lake Documentation**: https://docs.delta.io/
- **Databricks Best Practices**: https://docs.databricks.com/delta/best-practices.html
- **PySpark SQL Guide**: https://spark.apache.org/docs/latest/sql-programming-guide.html
- **Auto Loader**: https://docs.databricks.com/ingestion/auto-loader/index.html

### 13. Próximos Pasos

En los siguientes laboratorios aprenderás:
- Feature engineering avanzado (Lab 3)
- Entrenamiento de modelos ML con MLflow (Lab 4)
- Deployment de pipelines en producción
- Monitoreo y alertas automatizadas
- CI/CD para data pipelines

---

## Conclusión

¡Felicitaciones! Has completado el laboratorio de Preparación y Procesamiento de Datos en Azure Databricks.

### Habilidades Adquiridas:

✅ Exploración de datos con múltiples lenguajes  
✅ Ingesta eficiente con Auto Loader  
✅ Limpieza y transformación con PySpark  
✅ Implementación de Delta Lake con ACID  
✅ Versionado y Time Travel  
✅ Optimización con OPTIMIZE y Z-ORDER  
✅ Schema evolution y escalabilidad  
✅ Pipelines ETL reproducibles  

**¡Excelente trabajo!** Ahora tienes las bases para construir pipelines de datos robustos y escalables en producción.
