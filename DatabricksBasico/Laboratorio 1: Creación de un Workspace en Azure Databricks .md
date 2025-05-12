# 🧪 Laboratorio 1: Creación de un Workspace en Azure Databricks

## 🎯 Objetivo
Aprender a crear un Workspace de Azure Databricks desde el portal de Azure, comprender su estructura y conocer las opciones de configuración básicas.

## 🕒 Duración estimada
15 - 20 minutos

## ✅ Prerrequisitos
- Acceso al portal de Azure con permisos para crear recursos.
- Tener una suscripción activa de Azure.
- Rol de **Owner** o **Contributor** sobre el grupo de recursos.

---

## 📝 Pasos

### 1. Iniciar sesión en el portal de Azure
- Navega a: [https://portal.azure.com](https://portal.azure.com)

![image](https://github.com/user-attachments/assets/e3d88532-7cc6-44c1-bc7f-40dea669d09c)

---

### 2. Crear un nuevo recurso de Databricks
1. Haz clic en **"Crear un recurso"**.
2. Busca **"Azure Databricks"** y selecciónalo.
3. Da clic en **"Crear"**.

![image](https://github.com/user-attachments/assets/8ca91aec-e84e-456c-b2f9-49e8a6fdbace)
![image](https://github.com/user-attachments/assets/9e745758-7110-4bc4-8649-93763b7f46d2)
![image](https://github.com/user-attachments/assets/8242ba38-ee7f-44fd-aef7-1d6b61c6538e)

---

### 3. Configurar la instancia de Databricks

Completa el formulario con la siguiente información:

| Campo                | Valor recomendado           |
|----------------------|-----------------------------|
| Nombre del workspace | `databricks-ws-demo`        |
| Suscripción          | (Selecciona tu suscripción) |
| Grupo de recursos    | `rg-databricks-demo`        |
| Ubicación            | Región más cercana          |
| Pricing Tier         | `Standard` (para talleres)  |

![image](https://github.com/user-attachments/assets/75f4b039-2d51-4c40-b68c-adf146dcc882)

## 💳 Niveles de Pricing (Tiers) de Azure Databricks

Azure Databricks ofrece distintos **niveles de precios (tiers)** que determinan las características disponibles en el workspace. Estos niveles afectan tanto la funcionalidad como el costo por hora de los clusters.

### 🔸 Standard Tier
- **Enfocado a:** Desarrollo, pruebas, POCs.
- **Incluye:**
  - Clústeres compartidos y por trabajos.
  - Notebooks colaborativos.
  - APIs de acceso a datos y computación.
- **Limitaciones:**
  - No incluye características empresariales avanzadas como control de acceso detallado o soporte para compliance.
- **Cuándo usarlo:**
  - En talleres, cursos, proyectos personales, entornos de desarrollo sin requisitos de seguridad avanzados.

---

### 🔸 Premium Tier
- **Enfocado a:** Uso empresarial.
- **Incluye todo lo de Standard**, además de:
  - **Role-Based Access Control (RBAC)** más granular a nivel de notebooks, jobs, clústeres.
  - Soporte para **Auditing** (auditoría de acciones de usuario).
  - Soporte para integración con **Azure AD Passthrough**.
  - **Job isolation** y mayor seguridad en ejecución de trabajos.
- **Cuándo usarlo:**
  - En entornos empresariales que manejan datos sensibles o regulados.
  - Cuando se requiere trazabilidad de acciones y control fino de permisos.

---

### 🔸 Trial (evaluación gratuita)
- **Enfocado a:** Nuevos usuarios.
- **Incluye:** Acceso limitado al tier Premium por 14 días (sujeto a disponibilidad).
- **Cuándo usarlo:**  
  - Ideal para explorar las capacidades avanzadas de Databricks sin compromiso financiero.


---

### 4. Configurar opciones avanzadas (opcional)
- Puedes habilitar la opción de **VNet injection** si estás en un entorno empresarial.
- Recomendado: habilita el monitoreo con Azure Monitor si se requiere trazabilidad extendida.

![image](https://github.com/user-attachments/assets/16ee0e0b-cf7c-4088-a9bc-48f9304e6a82)


---

## 📌 Cuándo usar las opciones avanzadas

Las opciones avanzadas son recomendables cuando:

- 🔐 **Seguridad de red**: Si tu organización requiere que todo el tráfico entre Databricks y otros recursos de Azure esté contenido en una red privada, debes habilitar **VNet injection** para integrar el workspace a una red virtual controlada.
  
- 📈 **Monitoreo centralizado**: Si necesitas enviar métricas, logs y auditorías al mismo lugar que otros servicios de Azure (como Log Analytics), habilita **Azure Monitor** para facilitar la trazabilidad y cumplimiento de políticas de gobierno.

- 🏷️ **Etiquetas de recursos**: Si quieres aplicar etiquetas (`tags`) para controlar costos o clasificar entornos por proyecto, equipo, aplicación o dueño del recurso.

- 💰 **Control de costos compartido**: Si tienes múltiples equipos usando el mismo workspace y quieres segmentar el consumo, puedes habilitar opciones para integración con herramientas de facturación y control de costos.

En escenarios de **producción o multinivel** (DEV/QA/PROD), es muy recomendable configurar estas opciones desde el inicio para evitar reprovisionamientos.

---

### 5. Revisar y crear
1. Haz clic en **"Revisar y crear"**.
2. Valida que todos los campos estén correctos.
3. Haz clic en **"Crear"** para iniciar la implementación.

![image](https://github.com/user-attachments/assets/4df48b50-dd9d-48fc-ab8a-006b75d24dbd)

---

### 6. Esperar a que el recurso se cree
- Puede tardar entre 2 y 5 minutos.
- Cuando termine, haz clic en **"Ir al recurso"**.

![image](https://github.com/user-attachments/assets/091bdd9c-9081-4f14-90aa-cb02c2e2fa9d)
![image](https://github.com/user-attachments/assets/75bcba86-ca40-48a8-917f-87ad3bab7e89)

---

### 7. Acceder a la interfaz de Azure Databricks
1. Dentro del recurso, haz clic en el botón **"Iniciar área de trabajo"**.
2. Se abrirá una nueva pestaña con la interfaz de usuario de Databricks.
3. La URL tendrá el siguiente formato:  
   `https://<region>.azuredatabricks.net`

![image](https://github.com/user-attachments/assets/de13b739-d982-4fc8-a7bb-1a4e1dc8cfc0)

---

## 📚 ¿Qué aprendimos?
- Cómo crear un Workspace de Azure Databricks desde el portal de Azure.
- Cómo acceder a la interfaz de usuario para comenzar a trabajar con notebooks, clústeres y datos.

---

## 📚 Recursos Oficiales Recomendados

Si deseas aprender más sobre Azure Databricks y sus componentes, aquí tienes algunos recursos oficiales que puedes consultar:

- 🔹 [Documentación oficial de Azure Databricks](https://learn.microsoft.com/azure/databricks/)  
  Guía completa sobre cómo usar Databricks en Azure, desde conceptos básicos hasta prácticas avanzadas.

- 🔹 [Tutorial: Crear un workspace de Azure Databricks](https://learn.microsoft.com/azure/databricks/getting-started/create-databricks-workspace)  
  Paso a paso oficial para crear un workspace desde el portal de Azure.

- 🔹 [Introducción a Delta Lake en Azure Databricks](https://learn.microsoft.com/azure/databricks/delta/)  
  Información sobre cómo Delta Lake mejora el manejo de datos con transacciones ACID, versionado y rendimiento.

- 🔹 [Azure Databricks Pricing](https://azure.microsoft.com/pricing/details/databricks/)  
  Detalles de costos y diferencias entre los niveles Standard y Premium.

- 🔹 [Guía de seguridad y control de acceso](https://learn.microsoft.com/azure/databricks/administration-guide/access-control/)  
  Para configurar permisos y seguridad a nivel de cluster, notebook y datos.

- 🔹 [Integración con Git en Databricks](https://learn.microsoft.com/azure/databricks/repos/)  
  Documentación sobre cómo conectar repositorios Git a tu workspace de Databricks.
