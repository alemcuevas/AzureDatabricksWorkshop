# 🧪 Laboratorio Preparatorio: Configuración de Azure Storage Account para Databricks

## 🎯 Objetivo  
Crear un Azure Storage Account y un contenedor, y obtener los datos necesarios para conectarlo con Azure Databricks (usando key o managed identity).

---

## 🕒 Duración estimada  
15 - 25 minutos

---

## ✅ Prerrequisitos  
- Tener acceso al portal de Azure  
- Rol de Contributor o superior sobre un grupo de recursos  
- Dataset descargado desde Kaggle:  
  `energy-consumption-by-source.csv`

---

## 📝 Pasos

### 1. Descargar el dataset desde Kaggle

1. Accede a este enlace:  
   https://www.kaggle.com/datasets/whisperingkahuna/energy-consumption-dataset-by-our-world-in-data  
2. Descarga el archivo:  
   `energy-consumption-by-source.csv`  
3. Guarda el archivo en tu equipo para subirlo en pasos posteriores

---

### 2. Crear un Storage Account

1. Entra al portal de Azure: https://portal.azure.com  
2. Haz clic en **"Crear un recurso"**  
3. Busca **"Storage Account"**  
4. Configura lo siguiente:

| Campo                     | Valor recomendado             |
|---------------------------|-------------------------------|
| Nombre de la cuenta       | `storageenergydemo`           |
| Grupo de recursos         | Usa uno existente o crea uno  |
| Región                    | La misma que tu Databricks    |
| Rendimiento               | Standard                      |
| Redundancia               | LRS                           |
| Nivel de cuenta           | V2                            |

5. Haz clic en **Revisar y Crear**  
6. Luego haz clic en **Crear**
7. 
![image](https://github.com/user-attachments/assets/4e5650f8-1280-489a-807f-4d0683b8b796)

---

### 3. Crear un contenedor privado

1. Dentro del Storage Account, ve a la sección **Contenedores**  
2. Haz clic en **+ Contenedor**  
3. Asigna el nombre: `energia`  
4. Nivel de acceso: **Privado (sin acceso anónimo)**  
5. Haz clic en **Crear**

![image](https://github.com/user-attachments/assets/d62ca484-0499-4e27-b422-8b1eb48a3d58)

---

### 4. Subir el dataset CSV

1. Haz clic en el contenedor `energia`  
2. Haz clic en **Cargar**  
3. Selecciona el archivo `energy-consumption-by-source.csv`  
4. Haz clic en **Cargar**

![image](https://github.com/user-attachments/assets/2fd4e70d-ca7e-43f9-8ee7-e1d5ee622ecb)

---

### 5. Obtener los datos de conexión

Ve al Storage Account > pestaña **Claves de acceso**:

- Copia el valor de **key1**  
- Anota también:
  - `account_name = storageenergydemo`
  - `container_name = energia`
  - `file_path = energy-consumption-by-source.csv`

![image](https://github.com/user-attachments/assets/1c8085ff-4ab5-4eee-bd56-ebcd3e2a0d63)

---

## 📚 ¿Qué aprendimos?

- Cómo crear un Storage Account compatible con Databricks  
- Cómo subir un archivo desde Kaggle a un contenedor privado  
- Cómo obtener la información necesaria para conectar desde un notebook de Databricks

---

## 📚 Recursos oficiales

- [Crear Storage Account](https://learn.microsoft.com/azure/storage/common/storage-account-create)  
- [Contenedores en Azure Blob Storage](https://learn.microsoft.com/azure/storage/blobs/storage-blobs-introduction)  
- [Carga de archivos en Azure Storage](https://learn.microsoft.com/azure/storage/blobs/storage-quickstart-blobs-portal)  
- [Conectar Databricks a Azure Storage](https://learn.microsoft.com/azure/databricks/data/data-sources/azure/azure-storage)

💡 **Consejo:** En entornos productivos, evita incluir claves directamente en notebooks. Usa Key Vault o Managed Identity para mayor seguridad.

