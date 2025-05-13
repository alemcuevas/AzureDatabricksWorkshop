# 🧪 Laboratorio 3: Carga y Exploración de Datos en Azure Databricks

## 🎯 Objetivo  
Conectar Azure Databricks a Azure Data Lake Storage Gen2 usando la clave de acceso, cargar el dataset `energy-consumption-by-source.csv`, explorarlo y guardarlo en formato Delta Lake.

---

## 🕒 Duración estimada  
45 minutos

---

## ✅ Prerrequisitos  
- Workspace de Azure Databricks activo  
- Clúster en estado **Running**  
- Archivo `energy-consumption-by-source.csv` subido al contenedor `energia` del Storage Account `storageenergydemo`  
- Clave de acceso disponible desde el portal de Azure

---

## 📝 Pasos

### 1. Establecer la clave de acceso en la configuración de Spark

Reemplaza los valores `<storage_account>` y `<access_key>` con los reales:

    spark.conf.set(
        "fs.azure.account.key.storageenergydemo.dfs.core.windows.net",
        "<clave_de_acceso>"
    )

📸 **Screenshot sugerido:** Celda con `spark.conf.set` ejecutada sin errores

---

### 2. Cargar el archivo CSV en un DataFrame

    df = spark.read.option("header", True).csv("abfss://energia@storageenergydemo.dfs.core.windows.net/energy-consumption-by-source.csv")
    display(df)

📸 **Screenshot sugerido:** Primeras filas del DataFrame cargado correctamente

---

### 3. Explorar los datos

- Ver el esquema:

        df.printSchema()

- Mostrar países únicos:

        df.select("Entity").distinct().show(10)

- Filtrar datos por país (ejemplo: México):

        df.filter(df.Entity == "Mexico").display()

📸 **Screenshot sugerido:** Resultados del filtro por país

---

### 4. Guardar los datos en formato Delta

    df.write.format("delta").mode("overwrite").save("abfss://energia@storageenergydemo.dfs.core.windows.net/delta/energy-data")

📸 **Screenshot sugerido:** Confirmación de escritura exitosa

---

### 5. Leer los datos desde Delta Lake

    df_delta = spark.read.format("delta").load("abfss://energia@storageenergydemo.dfs.core.windows.net/delta/energy-data")
    display(df_delta)

📸 **Screenshot sugerido:** Vista de los datos cargados en formato Delta

---

### 6. Ejecutar una consulta SQL

1. Registrar una vista temporal:

        df_delta.createOrReplaceTempView("energia")

2. Ejecutar la siguiente consulta para ver los 10 países con mayor consumo energético en 2020:

        %sql
        SELECT Entity, Year, `Primary energy consumption`
        FROM energia
        WHERE Year = 2020
        ORDER BY `Primary energy consumption` DESC
        LIMIT 10

📸 **Screenshot sugerido:** Tabla con resultados ordenados

---

## 🧠 Conceptos clave aplicados

- Conexión directa a ADLS Gen2 vía `spark.conf.set`  
- Lectura y visualización de archivos CSV en Databricks  
- Almacenamiento optimizado con Delta Lake  
- Análisis exploratorio con SQL sobre Spark

---

## 📚 Recursos Oficiales Recomendados

- [Leer datos desde Azure Data Lake Gen2](https://learn.microsoft.com/azure/databricks/data/data-sources/azure/azure-datalake-gen2)  
- [Documentación oficial de Delta Lake](https://learn.microsoft.com/azure/databricks/delta/)  
- [Conexiones seguras con claves](https://learn.microsoft.com/azure/databricks/data/data-sources/azure/azure-storage#--access-using-an-account-key)  
- [Consultas SQL en Databricks](https://learn.microsoft.com/azure/databricks/sql/)

💡 **Consejo:** Usa esta opción solo en entornos de desarrollo. Para producción, se recomienda usar **Azure Key Vault** o **Managed Identity** para mayor seguridad.
