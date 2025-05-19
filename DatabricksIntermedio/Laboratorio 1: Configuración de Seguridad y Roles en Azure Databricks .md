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

### 4. Crear un Key Vault en Azure y registrar un secreto

1. Desde el portal de Azure, crea un recurso tipo **Key Vault**  
2. Dentro del Key Vault, ve a **Secrets** > **+ Generate/Import**  
3. Nombre del secreto: `storage-key`  
4. Valor: alguna clave de prueba o texto ficticio

![image](https://github.com/user-attachments/assets/c9d317bc-6c28-413c-b7b2-e074c8986f1e)

![image](https://github.com/user-attachments/assets/7c82b0dc-86dd-4a37-b015-4f469bafe46d)

![image](https://github.com/user-attachments/assets/ae6e69ee-1585-40c0-8aa4-2abd9c34255b)

![image](https://github.com/user-attachments/assets/03bef3df-03c2-435e-80b4-917220c93c3b)

---

### 5. Crear un Secret Scope en Databricks para Key Vault

1. Abre un notebook en Databricks  
2. Ejecuta:

    %sh
    databricks secrets create-scope --scope kv_scope --scope-backend-type AZURE_KEYVAULT --resource-id <RESOURCE_ID> --dns-name <KEY_VAULT_URL>

Reemplaza:
- `<RESOURCE_ID>` por el resource ID del Key Vault (desde "Propiedades" en Azure)
- `<KEY_VAULT_URL>` por la URL pública del Key Vault (ej. `https://<nombre>.vault.azure.net/`)

📸 **Screenshot sugerido:** Confirmación del scope creado

---

### 6. Leer el secreto desde un notebook

    secret = dbutils.secrets.get(scope="kv_scope", key="storage-key")
    print("Secreto leído con éxito")

📸 **Screenshot sugerido:** Resultado correcto (sin mostrar el secreto)

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

