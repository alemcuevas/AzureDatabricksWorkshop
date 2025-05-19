# 🧪 Laboratorio 6: Orquestación de Pipelines con Databricks Workflows

## 🎯 Objetivo  
Crear un Workflow (job) en Databricks para orquestar tareas secuenciales de procesamiento de datos. Integrar la ejecución del workflow con Azure Data Factory para automatización de extremo a extremo.

---

## 🕒 Duración estimada  
30 minutos

---

## ✅ Prerrequisitos  
- Haber ejecutado los laboratorios anteriores  
- Al menos dos notebooks creados en Databricks (ej. `Ingesta_AutoLoader`, `Transformacion_Energia`)  
- Permisos para crear Workflows en el workspace  
- Tener acceso al portal de Azure y permisos para editar Azure Data Factory

---

## 📝 Pasos

### 1. Crear notebooks base

1. En Databricks, crea dos notebooks:
   - `Ingesta_AutoLoader`: contiene código del Lab 2
   - `Transformacion_Energia`: contiene código del Lab 3 (o posteriores)

📸 **Screenshot sugerido:** Notebooks listos en tu Workspace

---

### 2. Crear un Workflow en Databricks

1. Ve al menú lateral > **Workflows**  
2. Haz clic en **Create Job**  
3. Asigna el nombre: `Pipeline_Energia`  
4. Agrega una primera tarea:
   - Task name: `Ingesta`
   - Type: Notebook
   - Notebook: `Ingesta_AutoLoader`
   - Cluster: escoge un cluster existente o configura uno nuevo

5. Agrega una segunda tarea:
   - Task name: `Transformacion`
   - Notebook: `Transformacion_Energia`
   - Establece dependencia: **"Runs after Ingesta"**

📸 **Screenshot sugerido:** Diagrama del flujo con las dos tareas

---

### 3. Probar ejecución del Workflow

1. Haz clic en **Run now**  
2. Espera a que las tareas se ejecuten correctamente  
3. Observa el output y duración de cada paso

📸 **Screenshot sugerido:** Pantalla de ejecución exitosa con status verde

---

### 4. Integrar con Azure Data Factory (ADF)

1. Abre Azure Data Factory > tu pipeline  
2. Agrega una actividad de tipo **Databricks notebook/job**  
3. Configura lo siguiente:
   - **Databricks Linked Service** apuntando a tu workspace
   - Tipo: Job
   - Job name: `Pipeline_Energia`

4. Guarda y publica el pipeline en ADF  
5. Ejecuta el pipeline manualmente o con un trigger programado

📸 **Screenshot sugerido:** Actividad de Databricks dentro de ADF

---

## 🧠 Conceptos clave aplicados

- Encadenamiento de notebooks en Databricks Workflows  
- Automatización de flujos ETL y ML  
- Integración con herramientas de orquestación externas como Azure Data Factory  
- Control de ejecución y monitoreo de tareas programadas

---

## 📚 Recursos Oficiales Recomendados

- [Workflows en Azure Databricks](https://learn.microsoft.com/azure/databricks/workflows/)  
- [Configurar Jobs programados](https://learn.microsoft.com/azure/databricks/jobs/)  
- [Conectar Azure Data Factory con Databricks](https://learn.microsoft.com/azure/data-factory/connector-azure-databricks)  
- [Best practices para pipelines de producción](https://learn.microsoft.com/azure/databricks/dev-tools/best-practices#orchestration)

💡 **Consejo:** Usa Workflows para manejar la lógica de dependencias entre tareas, y ADF para agendar y monitorear flujos orquestados desde un solo punto de control.
