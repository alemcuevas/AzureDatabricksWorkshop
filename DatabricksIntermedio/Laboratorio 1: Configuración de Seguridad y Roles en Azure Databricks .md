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
3. Ve a la pestaña **Groups**  
4. Crea dos grupos:
    - `data_engineers`
    - `data_scientists`

📸 **Screenshot sugerido:** Lista de grupos creados

---

### 2. Asignar usuarios a los grupos

1. Selecciona el grupo creado (ej. `data_engineers`)  
2. Haz clic en **Add Members**  
3. Agrega usuarios de prueba al grupo

📸 **Screenshot sugerido:** Usuarios dentro del grupo

---

### 3. Asignar permisos sobre carpetas y notebooks

1. Ve al menú lateral > **Workspace**  
2. Haz clic en los tres puntos de una carpeta o notebook  
3. Selecciona **Permissions**  
4. Da acceso:
    - `Can Edit` para `data_engineers`
    - `Can View` para `data_scientists`

📸 **Screenshot sugerido:** Configuración de permisos sobre un recurso

---

### 4. Crear un Key Vault en Azure y registrar un secreto

1. Desde el portal de Azure, crea un recurso tipo **Key Vault**  
2. Dentro del Key Vault, ve a **Secrets** > **+ Generate/Import**  
3. Nombre del secreto: `storage-key`  
4. Valor: alguna clave de prueba o texto ficticio

📸 **Screenshot sugerido:** Pantalla de secreto creado

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

