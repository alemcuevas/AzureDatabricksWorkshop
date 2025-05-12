## 🔐 ¿Qué es una Cluster Policy en Azure Databricks?

Una **Cluster Policy** (política de clúster) es una plantilla que define y restringe los parámetros de configuración permitidos al momento de crear clústeres en Azure Databricks. Sirve para **estandarizar**, **controlar costos** y **garantizar el cumplimiento de reglas corporativas**.

---

### 🎯 ¿Para qué sirven las Cluster Policies?

- ✅ Establecer configuraciones predefinidas para que los usuarios no las modifiquen
- 💰 Restringir el uso de máquinas costosas (por ejemplo, instancias `GPU`)
- 🧱 Definir límites de recursos (número máximo de nodos, duración, tipo de escalado)
- 🔐 Garantizar que todos los clústeres usen configuraciones seguras y aprobadas por el equipo de TI

---

### 📌 ¿Cuándo deberías usar Cluster Policies?

- En **ambientes compartidos** donde múltiples usuarios crean clústeres
- Cuando se necesita **controlar costos** y evitar sobredimensionamiento
- En entornos **regulados** donde la configuración debe ser consistente
- Si se quiere aplicar un nivel de **gobernanza automatizada**

---

### 🛠 Ejemplo de uso

Un administrador puede crear una política que:

- Obligue a que todos los clústeres usen el runtime `LTS`
- Fije el `Auto Termination` a máximo 30 minutos
- Permita solo nodos `Standard_DS3_v2` o inferiores
- Prohíba la desactivación del autoscaling

Esto garantiza que todos los clústeres creados bajo esa política sean **seguros, eficientes y aprobados**.

---

### 📚 Recursos oficiales

- [Cluster Policies – Azure Databricks](https://learn.microsoft.com/azure/databricks/administration-guide/clusters/policies/)
- [Ejemplos de configuración de políticas](https://learn.microsoft.com/azure/databricks/administration-guide/clusters/policies#--examples)

