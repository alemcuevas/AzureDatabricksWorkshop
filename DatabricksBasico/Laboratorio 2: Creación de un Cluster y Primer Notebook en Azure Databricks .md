# 🧪 Laboratorio 2: Creación de un Cluster y Primer Notebook en Azure Databricks

## 🎯 Objetivo  
Configurar un clúster en Azure Databricks, crear un notebook y ejecutar comandos básicos en Python y SQL.

---

## 🕒 Duración estimada  
20 - 30 minutos

---

## ✅ Prerrequisitos  
- Haber creado y accedido a un workspace de Azure Databricks  
- Tener permisos para crear clústeres y notebooks

---

## 📝 Pasos

### 1. Acceder a la interfaz de Azure Databricks  
- Desde el portal de Azure, abre el recurso de Databricks  
- Haz clic en **"Iniciar área de trabajo"** para abrir la interfaz web  

![image](https://github.com/user-attachments/assets/7c03e222-98f5-4157-a669-29203bd56781)

---

### 2. Crear un clúster  
- En el menú lateral, haz clic en **Compute**  
- Haz clic en **Create Cluster**  
- Completa la configuración con los siguientes valores recomendados:

| Campo              | Valor sugerido                          |
|--------------------|-----------------------------------------|
| Cluster name       | `demo-cluster`                          |
| Cluster mode       | `Single Node`                           |
| Databricks runtime | `13.x LTS (Scala 2.12, Spark 3.x)`      |
| Autoscaling        | Activado                                |
| Auto termination   | 10 minutos                              |

- Haz clic en **Create Cluster**  
- Espera a que el estado cambie a **Running**

![image](https://github.com/user-attachments/assets/c8a3fcbe-506e-424a-b5df-06b221984934)
![image](https://github.com/user-attachments/assets/bdbacefc-4476-46a6-9450-abbac94e5fe1)
![image](https://github.com/user-attachments/assets/7895bbe6-fe12-476c-a17b-58e0cf33cab4)


---

### 3. Crear un Notebook  
- En el menú lateral, ve a **Workspace > tu carpeta de usuario**  
- Haz clic en **Create > Notebook**  
- Asigna un nombre, por ejemplo: `Primer Notebook`  
- Selecciona **Python** como lenguaje  
- Asocia el notebook al clúster `demo-cluster`

📸 **Screenshot sugerido:** Formulario de creación del notebook con clúster seleccionado

---

### 4. Ejecutar comandos básicos en Python

**Ejemplo 1 – Operación básica:**

    x = 5
    y = 7
    x + y

**Ejemplo 2 – Crear un DataFrame y mostrarlo:**

    data = [("Ana", 34), ("Luis", 28), ("Carmen", 45)]
    df = spark.createDataFrame(data, ["Nombre", "Edad"])
    df.display()

📸 **Screenshot sugerido:** Celda ejecutada mostrando la tabla con `.display()`

---

### 5. Ejecutar una consulta SQL  
- Agrega una nueva celda y cambia el tipo de celda a **SQL** (desde el menú desplegable donde dice Python)  
- Escribe lo siguiente:

    SELECT * FROM VALUES  
      ("Carlos", 30),  
      ("Lucía", 29),  
      ("Pedro", 50)  
    AS personas(nombre, edad)  
    WHERE edad > 30;

📸 **Screenshot sugerido:** Resultados de la consulta SQL mostrando filas filtradas

---

## 💡 Tipos de Clústeres en Azure Databricks

| Tipo                | Descripción                                                                   |
|---------------------|--------------------------------------------------------------------------------|
| **Standard**        | General-purpose. Permite múltiples usuarios y notebooks                       |
| **High Concurrency**| Optimizado para muchos usuarios concurrentes. Ideal para trabajo colaborativo |
| **Single Node**     | Para desarrollo o pruebas individuales. No requiere Spark distribuido         |

---

## 📚 ¿Qué aprendimos?  
- Crear un clúster en Azure Databricks  
- Crear un notebook y asociarlo a un clúster  
- Ejecutar comandos básicos en Python y SQL

---

## 📚 Recursos Oficiales Recomendados  
- [Crear clústeres en Azure Databricks](https://learn.microsoft.com/azure/databricks/clusters/)  
- [Notebooks en Azure Databricks](https://learn.microsoft.com/azure/databricks/notebooks/)  
- [Tipos de clústeres y modos de ejecución](https://learn.microsoft.com/azure/databricks/clusters/configure/)  
- [Uso de SQL en notebooks](https://learn.microsoft.com/azure/databricks/sql/)  
- [Lenguajes soportados en Databricks](https://learn.microsoft.com/azure/databricks/dev-tools/api/latest/languages/)

💡 **Consejo:** Si el clúster se detiene por inactividad, puedes reiniciarlo desde la sección *Compute*
