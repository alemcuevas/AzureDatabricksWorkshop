# Laboratorio 1: Fundamentos y Arquitectura en Azure Databricks

**Duración:** 1 hora  
**Nivel:** Fundamentos  
**Objetivo:** Comprender cómo Databricks encaja dentro de una arquitectura moderna de datos en Azure y aplicar buenas prácticas de seguridad, costos y conectividad.

---

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Arquitectura de Referencia para Analítica en Azure](#arquitectura-de-referencia)
3. [Integración con Storage Accounts y Seguridad](#integración-con-storage-accounts)
4. [Buenas Prácticas](#buenas-prácticas)
5. [Demo Práctica: Configuración de Azure Databricks Workspace](#demo-práctica)
6. [Ejercicios Adicionales](#ejercicios-adicionales)
7. [Recursos Adicionales](#recursos-adicionales)

---

## Introducción

Azure Databricks es una plataforma de análisis de datos unificada y optimizada para Big Data y Machine Learning. Construida sobre Apache Spark, Databricks se integra nativamente con los servicios de Azure para proporcionar una solución completa de arquitectura Lakehouse.

### ¿Qué es una Arquitectura Lakehouse?

El **Lakehouse** combina las mejores características de:
- **Data Lakes**: Almacenamiento flexible y económico de datos estructurados y no estructurados.
- **Data Warehouses**: Rendimiento de consultas y transacciones ACID.

Azure Databricks implementa esta arquitectura usando **Delta Lake**, que proporciona:
- Transacciones ACID en Data Lakes
- Versionado de datos (Time Travel)
- Esquema enforced y schema evolution
- Optimizaciones de rendimiento (Z-Ordering, Data Skipping)

---

## Arquitectura de Referencia

### Arquitectura Lakehouse con Azure Databricks

```
┌─────────────────────────────────────────────────────────────────┐
│                    INGESTA DE DATOS                              │
├─────────────────────────────────────────────────────────────────┤
│  IoT Hub  │  Event Hubs  │  Azure Data Factory  │  APIs         │
└──────┬───────────┬───────────────┬──────────────────┬───────────┘
       │           │               │                  │
       └───────────┴───────────────┴──────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│               AZURE DATABRICKS WORKSPACE                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │   Bronze     │───▶│    Silver    │───▶│     Gold     │     │
│  │  (Raw Data)  │    │  (Cleaned)   │    │ (Aggregated) │     │
│  └──────────────┘    └──────────────┘    └──────────────┘     │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐      │
│  │           Delta Lake (ACID Transactions)             │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                 AZURE DATA LAKE STORAGE GEN2                     │
├─────────────────────────────────────────────────────────────────┤
│  /bronze/    │  /silver/    │  /gold/    │  /checkpoints/       │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CONSUMO DE DATOS                              │
├─────────────────────────────────────────────────────────────────┤
│  Power BI  │  Azure Synapse  │  ML Models  │  Applications      │
└─────────────────────────────────────────────────────────────────┘
```

### Componentes Clave

1. **Control Plane (Microsoft-managed)**
   - Portal web de Databricks
   - Cluster management
   - Notebooks y workflows
   - Jobs scheduler

2. **Data Plane (Customer subscription)**
   - Spark clusters (VMs)
   - Storage (ADLS Gen2)
   - Networking (VNet, NSG, Private Endpoints)

---

## Integración con Storage Accounts

### Azure Data Lake Storage Gen2 (ADLS Gen2)

ADLS Gen2 es el almacenamiento recomendado para Databricks por:
- Jerarquía de archivos optimizada
- Rendimiento superior
- Integración nativa con seguridad de Azure

### Métodos de Autenticación

#### 1. **Managed Identity (Recomendado)**

```python
# Configuración usando Managed Identity
spark.conf.set(
    "fs.azure.account.auth.type.<storage-account-name>.dfs.core.windows.net",
    "OAuth"
)
spark.conf.set(
    "fs.azure.account.oauth.provider.type.<storage-account-name>.dfs.core.windows.net",
    "org.apache.hadoop.fs.azurebfs.oauth2.MsiTokenProvider"
)
spark.conf.set(
    "fs.azure.account.oauth2.msi.tenant.<storage-account-name>.dfs.core.windows.net",
    "<tenant-id>"
)

# Leer datos
df = spark.read.parquet("abfss://<container>@<storage-account-name>.dfs.core.windows.net/data/")
```

**Ventajas:**
- No se requieren credenciales en el código
- Rotación automática de secretos
- Integración con Azure RBAC

#### 2. **Service Principal**

```python
# Configuración con Service Principal (secretos en Key Vault)
spark.conf.set(
    "fs.azure.account.auth.type.<storage-account-name>.dfs.core.windows.net",
    "OAuth"
)
spark.conf.set(
    "fs.azure.account.oauth.provider.type.<storage-account-name>.dfs.core.windows.net",
    "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider"
)
spark.conf.set(
    "fs.azure.account.oauth2.client.id.<storage-account-name>.dfs.core.windows.net",
    dbutils.secrets.get(scope="<scope-name>", key="client-id")
)
spark.conf.set(
    "fs.azure.account.oauth2.client.secret.<storage-account-name>.dfs.core.windows.net",
    dbutils.secrets.get(scope="<scope-name>", key="client-secret")
)
spark.conf.set(
    "fs.azure.account.oauth2.client.endpoint.<storage-account-name>.dfs.core.windows.net",
    "https://login.microsoftonline.com/<tenant-id>/oauth2/token"
)
```

#### 3. **Account Key (No recomendado para producción)**

```python
# Solo para desarrollo/testing
spark.conf.set(
    "fs.azure.account.key.<storage-account-name>.dfs.core.windows.net",
    dbutils.secrets.get(scope="<scope-name>", key="storage-key")
)
```

### Integración con Azure Key Vault

Azure Key Vault se usa para almacenar secretos de forma segura:

```bash
# Crear un secret scope en Databricks (desde CLI)
databricks secrets create-scope --scope <scope-name> --scope-backend-type AZURE_KEYVAULT \
  --resource-id /subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.KeyVault/vaults/<keyvault-name> \
  --dns-name https://<keyvault-name>.vault.azure.net/
```

```python
# Usar secretos en notebooks
storage_key = dbutils.secrets.get(scope="my-scope", key="storage-account-key")
db_password = dbutils.secrets.get(scope="my-scope", key="sql-password")
```

### Control de Acceso (RBAC)

Roles principales para Storage Accounts:

| Rol | Permisos | Uso |
|-----|----------|-----|
| **Storage Blob Data Owner** | Lectura, escritura, eliminación, ACLs | Administradores |
| **Storage Blob Data Contributor** | Lectura, escritura, eliminación | Aplicaciones y servicios |
| **Storage Blob Data Reader** | Solo lectura | Usuarios de solo consulta |

```bash
# Asignar rol a Managed Identity de Databricks
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee <databricks-managed-identity-principal-id> \
  --scope /subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.Storage/storageAccounts/<storage-name>
```

---

## Buenas Prácticas

### 1. Elección de Regiones

**Consideraciones:**

- **Latencia**: Colocar Databricks y Storage en la misma región
- **Compliance**: Regulaciones de residencia de datos (GDPR, etc.)
- **Costos**: Variación de precios entre regiones
- **Disponibilidad**: No todas las regiones tienen todos los servicios

**Recomendación:**
```
Databricks Workspace → Misma región que ADLS Gen2
                    → Misma región que usuarios principales
                    → Región con Availability Zones
```

### 2. Optimización de Costos

#### Tipos de Instancias

| Workload | Tipo de VM Recomendado | Características |
|----------|------------------------|-----------------|
| **ETL/Batch Processing** | Memory Optimized (E-series) | Mayor RAM, bueno para transformaciones |
| **Streaming** | Compute Optimized (F-series) | Alto CPU, baja latencia |
| **Machine Learning** | GPU (NC-series) | Aceleración de entrenamiento |
| **General Purpose** | D-series | Balance CPU/memoria |

#### Estrategias de Ahorro

1. **Auto-scaling de clusters**
```python
# Configurar cluster con autoscaling
{
  "autoscale": {
    "min_workers": 2,
    "max_workers": 8
  },
  "autotermination_minutes": 20
}
```

2. **Usar Spot VMs (hasta 80% de ahorro)**
```python
{
  "azure_attributes": {
    "first_on_demand": 1,
    "availability": "SPOT_WITH_FALLBACK_AZURE",
    "spot_bid_max_price": -1  # Precio on-demand como máximo
  }
}
```

3. **Pools de instancias** para reducir tiempo de inicio

4. **Políticas de cluster** para limitar configuraciones costosas

### 3. Conectividad Privada

#### VNet Injection

Inyectar el workspace de Databricks en tu propia VNet:

**Beneficios:**
- Control completo sobre networking
- Conexión privada a recursos on-premises
- Cumplimiento de políticas corporativas

**Requisitos de subnets:**
```
- Subnet para hosts privados: /26 o mayor (64+ IPs)
- Subnet para hosts públicos: /26 o mayor (64+ IPs)
- Delegación a Microsoft.Databricks/workspaces
- NSG con reglas específicas
```

#### Private Endpoints

Conexión privada entre Databricks y Storage:

```bash
# Crear Private Endpoint para Storage Account
az network private-endpoint create \
  --name pe-storage-databricks \
  --resource-group <rg-name> \
  --vnet-name <vnet-name> \
  --subnet <subnet-name> \
  --private-connection-resource-id <storage-account-id> \
  --group-id blob \
  --connection-name storage-connection
```

#### Diagrama de Arquitectura Segura

```
┌────────────────────────────────────────────────────────┐
│                  Corporate Network                      │
│                                                         │
│  ┌──────────────┐         VPN/ExpressRoute             │
│  │   On-Prem    │──────────────┐                       │
│  │   Resources  │              │                       │
│  └──────────────┘              │                       │
└────────────────────────────────┼───────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────┐
│              Azure Virtual Network (VNet)                │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌───────────────────────────────────────────────┐     │
│  │      Databricks Workspace (VNet Injected)     │     │
│  │                                                │     │
│  │  Private Subnet      Public Subnet            │     │
│  │  ┌──────────────┐   ┌──────────────┐         │     │
│  │  │   Workers    │   │   Workers    │         │     │
│  │  └──────────────┘   └──────────────┘         │     │
│  └───────────────────────────────────────────────┘     │
│                      │                                  │
│                      │ Private Endpoint                 │
│                      ▼                                  │
│  ┌─────────────────────────────────────────────┐       │
│  │    Private Endpoint Subnet                  │       │
│  │  ┌────────────────────────────────────┐     │       │
│  │  │  PE → Storage Account (ADLS Gen2)  │     │       │
│  │  └────────────────────────────────────┘     │       │
│  └─────────────────────────────────────────────┘       │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### 4. Seguridad en Capas

**Checklist de seguridad:**

- [ ] Managed Identity para autenticación
- [ ] Key Vault para secretos
- [ ] RBAC en Storage Accounts
- [ ] VNet Injection del workspace
- [ ] Private Endpoints para conectividad
- [ ] NSG rules restrictivos
- [ ] Azure Firewall para egress filtering
- [ ] Encryption at rest y in transit
- [ ] Unity Catalog para data governance
- [ ] Audit logs habilitados

---

## Demo Práctica

### Paso 1: Crear Resource Group

```bash
# Definir variables
$LOCATION = "eastus2"
$RG_NAME = "rg-databricks-workshop"
$STORAGE_NAME = "stdatabricksworkshop"
$DATABRICKS_WS_NAME = "dbws-analytics-prod"
$KEYVAULT_NAME = "kv-databricks-secrets"

# Crear resource group
az group create `
  --name $RG_NAME `
  --location $LOCATION
```

### Paso 2: Crear Storage Account (ADLS Gen2)

```bash
# Crear storage account con hierarchical namespace (ADLS Gen2)
az storage account create `
  --name $STORAGE_NAME `
  --resource-group $RG_NAME `
  --location $LOCATION `
  --sku Standard_LRS `
  --kind StorageV2 `
  --hierarchical-namespace true `
  --enable-large-file-share

# Crear contenedores
az storage container create `
  --name bronze `
  --account-name $STORAGE_NAME `
  --auth-mode login

az storage container create `
  --name silver `
  --account-name $STORAGE_NAME `
  --auth-mode login

az storage container create `
  --name gold `
  --account-name $STORAGE_NAME `
  --auth-mode login

az storage container create `
  --name checkpoints `
  --account-name $STORAGE_NAME `
  --auth-mode login
```

### Paso 3: Crear Azure Key Vault

```bash
# Crear Key Vault
az keyvault create `
  --name $KEYVAULT_NAME `
  --resource-group $RG_NAME `
  --location $LOCATION `
  --enable-rbac-authorization false

# Agregar secretos de ejemplo
az keyvault secret set `
  --vault-name $KEYVAULT_NAME `
  --name "storage-account-name" `
  --value $STORAGE_NAME

# Obtener storage account key y guardarlo
$STORAGE_KEY = (az storage account keys list `
  --resource-group $RG_NAME `
  --account-name $STORAGE_NAME `
  --query "[0].value" -o tsv)

az keyvault secret set `
  --vault-name $KEYVAULT_NAME `
  --name "storage-account-key" `
  --value $STORAGE_KEY
```

### Paso 4: Crear Azure Databricks Workspace

```bash
# Crear workspace (Standard tier para comenzar)
az databricks workspace create `
  --name $DATABRICKS_WS_NAME `
  --resource-group $RG_NAME `
  --location $LOCATION `
  --sku standard

# Obtener URL del workspace
$WORKSPACE_URL = (az databricks workspace show `
  --name $DATABRICKS_WS_NAME `
  --resource-group $RG_NAME `
  --query "workspaceUrl" -o tsv)

Write-Host "Databricks Workspace URL: https://$WORKSPACE_URL"
```

### Paso 5: Configurar Permisos RBAC

```bash
# Obtener el principal ID de la Managed Identity del workspace
$DATABRICKS_PRINCIPAL_ID = (az databricks workspace show `
  --name $DATABRICKS_WS_NAME `
  --resource-group $RG_NAME `
  --query "managedResourceGroupId" -o tsv)

# Asignar rol de Storage Blob Data Contributor al workspace
az role assignment create `
  --role "Storage Blob Data Contributor" `
  --assignee-object-id $DATABRICKS_PRINCIPAL_ID `
  --assignee-principal-type ServicePrincipal `
  --scope "/subscriptions/<subscription-id>/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_NAME"

# Dar acceso a Key Vault
az keyvault set-policy `
  --name $KEYVAULT_NAME `
  --object-id $DATABRICKS_PRINCIPAL_ID `
  --secret-permissions get list
```

### Paso 6: Configurar Databricks CLI

```bash
# Instalar Databricks CLI
pip install databricks-cli

# Configurar autenticación (requiere Azure CLI logueado)
databricks configure --aad-token

# Verificar conexión
databricks workspace list /
```

### Paso 7: Crear Secret Scope en Databricks

```bash
# Obtener Key Vault resource ID y DNS name
$KV_RESOURCE_ID = (az keyvault show `
  --name $KEYVAULT_NAME `
  --resource-group $RG_NAME `
  --query "id" -o tsv)

$KV_DNS_NAME = "https://$KEYVAULT_NAME.vault.azure.net/"

# Crear secret scope vinculado a Key Vault
databricks secrets create-scope `
  --scope storage-secrets `
  --scope-backend-type AZURE_KEYVAULT `
  --resource-id $KV_RESOURCE_ID `
  --dns-name $KV_DNS_NAME
```

### Paso 8: Crear y Configurar Cluster

Crear un cluster con esta configuración JSON:

```json
{
  "cluster_name": "analytics-cluster",
  "spark_version": "13.3.x-scala2.12",
  "node_type_id": "Standard_DS3_v2",
  "autoscale": {
    "min_workers": 2,
    "max_workers": 8
  },
  "autotermination_minutes": 20,
  "spark_conf": {
    "spark.databricks.delta.preview.enabled": "true"
  },
  "azure_attributes": {
    "first_on_demand": 1,
    "availability": "ON_DEMAND_AZURE"
  }
}
```

Desde CLI:

```bash
# Guardar configuración en archivo cluster-config.json
databricks clusters create --json-file cluster-config.json
```

### Paso 9: Probar Conectividad al Storage

Crear un notebook en Databricks y ejecutar:

```python
# Configurar autenticación con Managed Identity
storage_account_name = "stdatabricksworkshop"

spark.conf.set(
    f"fs.azure.account.auth.type.{storage_account_name}.dfs.core.windows.net",
    "OAuth"
)
spark.conf.set(
    f"fs.azure.account.oauth.provider.type.{storage_account_name}.dfs.core.windows.net",
    "org.apache.hadoop.fs.azurebfs.oauth2.MsiTokenProvider"
)
spark.conf.set(
    f"fs.azure.account.oauth2.msi.tenant.{storage_account_name}.dfs.core.windows.net",
    "<your-tenant-id>"
)

# Probar conexión
path = f"abfss://bronze@{storage_account_name}.dfs.core.windows.net/"

# Crear datos de prueba
data = [(1, "Alice", 25), (2, "Bob", 30), (3, "Charlie", 35)]
columns = ["id", "name", "age"]
df = spark.createDataFrame(data, columns)

# Escribir en Delta Lake
df.write.format("delta").mode("overwrite").save(f"{path}/test_data/")

# Leer datos
df_read = spark.read.format("delta").load(f"{path}/test_data/")
display(df_read)

print("✅ Conexión exitosa al Storage Account")
```

---

## Ejercicios Adicionales

### Ejercicio 1: Implementar Medallion Architecture

Crea tres notebooks que implementen:
1. **Bronze**: Ingestión de datos raw desde una fuente externa
2. **Silver**: Limpieza y transformación de datos
3. **Gold**: Agregaciones y tablas analíticas

### Ejercicio 2: Configurar Unity Catalog

1. Habilitar Unity Catalog en tu workspace
2. Crear un metastore
3. Crear catálogos para bronze, silver, gold
4. Configurar permisos granulares

### Ejercicio 3: Implementar CI/CD

1. Conectar Databricks con Azure DevOps o GitHub
2. Crear un pipeline de deployment para notebooks
3. Implementar testing automático

### Ejercicio 4: Monitoreo y Alertas

1. Configurar Azure Monitor para Databricks
2. Crear alertas para:
   - Costo de cluster excedido
   - Jobs fallidos
   - Uso de storage
3. Crear dashboards en Azure Portal

---

## Recursos Adicionales

### Documentación Oficial

- [Azure Databricks Documentation](https://docs.microsoft.com/azure/databricks/)
- [Delta Lake Documentation](https://docs.delta.io/)
- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)

### Arquitecturas de Referencia

- [Modern Analytics Architecture with Azure Databricks](https://docs.microsoft.com/azure/architecture/solution-ideas/articles/azure-databricks-modern-analytics-architecture)
- [Real-time Analytics on Big Data](https://docs.microsoft.com/azure/architecture/solution-ideas/articles/real-time-analytics)

### Cursos y Certificaciones

- [Microsoft Learn: Azure Databricks](https://docs.microsoft.com/learn/paths/data-engineer-azure-databricks/)
- [Databricks Academy](https://academy.databricks.com/)

### Herramientas

- [Databricks CLI](https://docs.databricks.com/dev-tools/cli/index.html)
- [Databricks Terraform Provider](https://registry.terraform.io/providers/databricks/databricks/latest/docs)
- [Azure CLI](https://docs.microsoft.com/cli/azure/)

### Comunidad

- [Databricks Community Edition](https://community.cloud.databricks.com/)
- [Stack Overflow - Azure Databricks Tag](https://stackoverflow.com/questions/tagged/azure-databricks)
- [GitHub - Databricks Samples](https://github.com/databricks)

---

## Conclusión

En este laboratorio has aprendido:

✅ Arquitectura Lakehouse con Azure Databricks  
✅ Integración segura con ADLS Gen2 usando Managed Identity  
✅ Gestión de secretos con Azure Key Vault  
✅ Buenas prácticas de costos, regiones y networking  
✅ Configuración práctica de un workspace completo  

**Próximos pasos:**
- Profundizar en Delta Lake y optimizaciones
- Implementar streaming con Structured Streaming
- Explorar MLflow para Machine Learning
- Configurar Unity Catalog para governance

---

**Laboratorio creado para Azure Databricks Workshop**  
*Versión 1.0 - Noviembre 2025*
