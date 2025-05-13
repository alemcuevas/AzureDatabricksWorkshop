## 🧱 Políticas de clúster predefinidas en Azure Databricks

Cuando creas un clúster en Azure Databricks, puedes seleccionar entre diferentes **Cluster Policies preconfiguradas**. Estas políticas ayudan a estandarizar y controlar el uso de recursos según el perfil del usuario.

A continuación se describen las más comunes:

---

### 🔓 `Unrestricted`

**Descripción:**  
Permite a los usuarios configurar el clúster **sin restricciones**. Todas las opciones están disponibles.

**Uso recomendado:**  
- Solo para administradores o entornos de desarrollo aislado  
- No se recomienda para ambientes de producción

---

### 👤 `Personal Compute`

**Descripción:**  
Política diseñada para que los usuarios creen **clústeres personales de bajo costo**, de un solo nodo.

**Restricciones comunes:**
- Modo Single Node
- Auto-terminación habilitada
- No permite autoscaling

**Uso recomendado:**
- Desarrollo individual
- Pruebas ligeras y notebooks personales

---

### ⚡ `Power User Compute`

**Descripción:**  
Permite a usuarios avanzados crear clústeres con más flexibilidad, pero bajo parámetros controlados.

**Restricciones comunes:**
- Límites máximos en número de nodos
- Runtime controlado
- Autoscaling permitido pero con topes

**Uso recomendado:**
- Data scientists o analistas con cargas medianas
- Entrenamiento de modelos, procesamiento por lotes

---

### 🤝 `Shared Compute`

**Descripción:**  
Clústeres compartidos entre varios usuarios, configurados para mantener estabilidad y eficiencia.

**Restricciones comunes:**
- Alta concurrencia (High Concurrency Mode)
- Autoterminación habilitada
- Escalado automático limitado

**Uso recomendado:**
- Ambientes colaborativos
- Uso de recursos compartidos para equipos

---

### 🕰️ `Legacy Shared Compute`

**Descripción:**  
Política anterior (versión heredada) para clústeres compartidos. Puede estar presente en workspaces antiguos.

**Uso recomendado:**
- Solo si ya está en uso en tu entorno
- Considera migrar a `Shared Compute` si es posible

---

## ✅ ¿Cuál elegir?

| Política             | Restricción | Ideal para                         |
|----------------------|-------------|------------------------------------|
| `Unrestricted`       | Ninguna     | Administradores, pruebas aisladas  |
| `Personal Compute`   | Alta        | Desarrolladores, notebooks ligeros |
| `Power User Compute` | Media       | Usuarios técnicos con necesidades más amplias |
| `Shared Compute`     | Controlada  | Colaboración, eficiencia en equipo |
| `Legacy Shared Compute` | Variable | Workspaces antiguos, compatibilidad |

---

## 📚 Recursos oficiales

- [Documentación oficial: Cluster Policies](https://learn.microsoft.com/azure/databricks/administration-guide/clusters/policies/)
- [Configurar y aplicar políticas](https://learn.microsoft.com/azure/databricks/administration-guide/clusters/policies#create-cluster-policies)

