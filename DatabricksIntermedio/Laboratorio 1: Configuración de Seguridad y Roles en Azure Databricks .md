# 🧪 Laboratorio 1: Configuración de Seguridad y Roles en Azure Databricks

## 🎯 Objetivo  
Configurar controles de seguridad en Azure Databricks, incluyendo permisos a nivel de recursos, acceso a notebooks, y conexión segura a secretos a través de Azure Key Vault.

---

## 🕒 Duración estimada  
30 minutos

---

## ✅ Prerrequisitos  
- Tener rol de **Workspace Admin**  
- Tener permisos para crear y administrar usuarios, grupos y configuraciones en Azure  
- Haber creado un Azure Key Vault con un secreto de prueba

---

## 📝 Pasos

### 1. Crear grupos de usuarios en Azure Databricks

1. Entra al workspace de Azure Databricks  
2. En el panel lateral, haz clic en **Admin Settings**  
3. Ve a la pestaña **Identity and access**  
4. Crea dos grupos:
    - `data_engineers`
    - `data_scientists`

![image](https://github.com/user-attachments/assets/ca3430f8-7f39-4475-8b8f-c0803f846920)

![image](https://github.com/user-attachments/assets/473461be-c1c3-48f7-b6d6-d103d0dc5188)

![image](https://github.com/user-attachments/assets/6f5b962b-21c3-4a81-842d-feb9b9810014)

![image](https://github.com/user-attachments/assets/2b2bb4ce-f255-4290-a988-3b81a9cf72d2)

![image](https://github.com/user-attachments/assets/2279432c-0161-49be-a8bf-1e8ab8a2dbf1)

---

### 2. Asignar usuarios a los grupos

1. Selecciona el grupo creado (ej. `data_engineers`)  
2. Haz clic en **Add Members**  
3. Agrega usuarios de prueba al grupo

![image](https://github.com/user-attachments/assets/07d8e458-c057-4b85-acab-2167f37acf96)

---

### 3. Asignar permisos sobre carpetas y notebooks

1. Ve al menú lateral > **Workspace**  
2. Haz clic en los tres puntos de una carpeta o notebook  
3. Selecciona **Permissions**  
4. Da acceso:
    - `Can Edit` para `data_engineers`
    - `Can View` para `data_scientists`

![image](https://github.com/user-attachments/assets/cf5ba0e5-9c25-426f-bcd1-1614557c3315)

![image](https://github.com/user-attachments/assets/0ff93e42-9346-4a81-90ae-c258fc00d14b)

![image](https://github.com/user-attachments/assets/d9621f4e-91d5-4d45-8a3a-08e3faacdfc6)

![image](https://github.com/user-attachments/assets/6f4cab25-68df-45ea-9a85-0c8d6d91a734)

![image](https://github.com/user-attachments/assets/b0631b4b-92f4-424d-9601-23f38277d662)

![image](https://github.com/user-attachments/assets/2a642b27-bbfd-4689-9e3b-34dbb1804833)

---

## 🧠 Conceptos clave aplicados

- Gestión de acceso con grupos de Databricks  
- Seguridad basada en roles (RBAC)  
- Uso de Azure Key Vault para almacenamiento seguro de secretos  
- Creación de Secret Scopes administrados

---

## 📚 Recursos Oficiales Recomendados

- [Databricks Access Control](https://learn.microsoft.com/azure/databricks/security/access-control/)  
- [Databricks integration with Azure Key Vault](https://learn.microsoft.com/azure/databricks/security/secrets/secret-scopes)  
- [Configurar RBAC en Azure](https://learn.microsoft.com/azure/role-based-access-control/overview)  

💡 **Consejo:** Usa los grupos para controlar permisos de forma centralizada y facilitar el cumplimiento de estándares de seguridad en tu organización.

