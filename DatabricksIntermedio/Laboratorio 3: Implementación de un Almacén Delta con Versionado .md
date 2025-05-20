# 🧪 Laboratorio 3: Implementación de un Almacén Delta con Versionado

## 🎯 Objetivo  
Optimizar el almacenamiento de datos con Delta Lake en Azure Databricks, aplicando comandos de mantenimiento como `OPTIMIZE` y `VACUUM`, y consultando versiones anteriores con Time Travel.

---

## 🕒 Duración estimada  
45 minutos

---

## ✅ Prerrequisitos  
- Haber ejecutado el Laboratorio 2 (datos en Bronze)  
- Clúster activo  
- Ruta disponible para almacenamiento en la capa Silver

---

## 📝 Pasos

### 1. Leer los datos desde la capa Bronze

    df_bronze = spark.read.format("delta").load("abfss://bronze@storageenergydemo.dfs.core.windows.net/energy")
    display(df_bronze)

![image](https://github.com/user-attachments/assets/f1277e70-b2db-40f0-94fb-247f52305599)

---

### 2. Seleccionar columnas relevantes y escribir en Silver

    df_silver = df_bronze.select(
        "Country", "Year",
        "Coal Consumption - EJ", "Oil Consumption - EJ", "Gas Consumption - EJ",
        "Nuclear Consumption - EJ", "Hydro Consumption - EJ",
        "Renewables Consumption - EJ", "Primary energy consumption (EJ)",
        "ingestion_date"
    ).dropna()

    df_silver.write.format("delta").mode("overwrite").save("abfss://silver@storageenergydemo.dfs.core.windows.net/energy")

![image](https://github.com/user-attachments/assets/10ed549e-ba1d-4b75-9187-e3c27ca74924)


---

### 3. Consultar tabla Silver y verificar datos

    df_ver = spark.read.format("delta").load("abfss://silver@storageenergydemo.dfs.core.windows.net/energy")
    display(df_ver)
    
![image](https://github.com/user-attachments/assets/b38d9afe-16de-4a4b-bb96-59bfc6e37c1c)

---

### 4. Ejecutar Time Travel: consultar versión anterior

1. Sobrescribe un registro para simular una modificación:

```
    from pyspark.sql.functions import lit

    df_mod = df_ver.withColumn("Nuclear Consumption - EJ", lit(0))
    df_mod.write.format("delta").mode("overwrite").save("abfss://silver@storageenergydemo.dfs.core.windows.net/energy")
```

📸 **Screenshot sugerido:** Confirmación del cambio

2. Consulta la versión anterior:

```
    df_version_0 = spark.read.format("delta") \
        .option("versionAsOf", 0) \
        .load("abfss://silver@storageenergydemo.dfs.core.windows.net/energy")

    display(df_version_0)
```

📸 **Screenshot sugerido:** Comparación entre versiones

---

### 5. Aplicar `OPTIMIZE` para compactar archivos pequeños

**Requiere cluster con Runtime 8.4+ y Delta Engine**

```
    spark.sql("""
    OPTIMIZE delta.`abfss://silver@storageenergydemo.dfs.core.windows.net/energy`
    """)
```

📸 **Screenshot sugerido:** Tabla con archivos optimizados

---

### 6. Aplicar `VACUUM` para eliminar archivos obsoletos

```
    spark.sql("""
    VACUUM delta.`abfss://silver@storageenergydemo.dfs.core.windows.net/energy` RETAIN 0 HOURS
    """)
```

⚠️ Asegúrate de que el Time Travel ya no sea necesario antes de eliminar versiones.

---

## 🧠 Conceptos clave aplicados

- Aplicación de la arquitectura medallion (Bronze → Silver)  
- Escritura eficiente en Delta Lake  
- Mantenimiento de tablas con `OPTIMIZE` y `VACUUM`  
- Uso de Time Travel para recuperación y auditoría de datos

---

## 📚 Recursos Oficiales Recomendados

- [Delta Lake Time Travel](https://learn.microsoft.com/azure/databricks/delta/delta-time-travel)  
- [Comando VACUUM](https://learn.microsoft.com/azure/databricks/delta/delta-utility#vacuum)  
- [OPTIMIZE en Delta Lake](https://learn.microsoft.com/azure/databricks/delta/optimizations/optimize)  
- [Best practices for Delta Lake](https://learn.microsoft.com/azure/databricks/delta/best-practices)

💡 **Consejo:** Delta Lake permite mantener datos confiables y auditables en cada capa de tu arquitectura analítica. Usa `OPTIMIZE` regularmente en tablas grandes para mejorar la performance.
