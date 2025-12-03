# Azure Databricks Workshop

![Azure Databricks](https://img.shields.io/badge/Azure-Databricks-FF6C37?style=for-the-badge&logo=databricks&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.8+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Spark](https://img.shields.io/badge/Apache_Spark-E25A1C?style=for-the-badge&logo=apachespark&logoColor=white)
![MLflow](https://img.shields.io/badge/MLflow-0194E2?style=for-the-badge&logo=mlflow&logoColor=white)

## 📋 Descripción

Workshop completo de **Azure Databricks** diseñado para llevar a los participantes desde los fundamentos hasta técnicas avanzadas de Big Data, Machine Learning y MLOps. Este repositorio contiene laboratorios prácticos, notebooks interactivos y documentación detallada para dominar el ecosistema de Databricks en Azure.

## 🎯 Objetivos del Workshop

- Dominar los fundamentos de Azure Databricks y Apache Spark
- Implementar pipelines de datos escalables y eficientes
- Aplicar feature engineering y análisis exploratorio de datos
- Entrenar, registrar y desplegar modelos de Machine Learning
- Implementar prácticas de MLOps con MLflow
- Optimizar performance y gestionar recursos en producción

## 📚 Estructura del Proyecto

```
AzureDatabricksWorkshop/
│
├── 📁 DatabricksBasico/                    # Nivel 1: Fundamentos
│   ├── Laboratorio 1: Creación de Workspace
│   ├── Laboratorio 2: Creación de Cluster y Primer Notebook
│   ├── Laboratorio 3: Carga y Exploración de Datos
│   ├── Laboratorio 4: Procesamiento de Datos con Spark
│   ├── Laboratorio Preparatorio: Azure Storage Account
│   ├── ¿Por qué guardar datos en formato Delta Lake?
│   └── Políticas de clúster predefinidas
│
├── 📁 DatabricksIntermedio/                # Nivel 2: Intermedio
│   ├── Laboratorio 1: Configuración de Seguridad y Roles
│   ├── Laboratorio 2: Pipeline de Ingesta con Auto Loader
│   ├── Laboratorio 3: Almacén Delta con Versionado
│   ├── Laboratorio 4: Tuning de Performance en Spark
│   ├── Laboratorio 5: Entrenamiento y Deploy con MLflow
│   ├── Laboratorio 6: Orquestación con Databricks Workflows
│   ├── Caching y Persistencia en Spark
│   ├── Lazy Evaluation en Spark
│   └── Spark Execution Plan y Catalyst Optimizer
│
├── 📁 DatabricksAvanzado/                  # Nivel 3: Avanzado
│   ├── Lab 1: Seguridad y Monitoreo
│   ├── Lab 2: Pipeline Streaming con Kafka
│   ├── Lab 3: Arquitectura Lakehouse
│   ├── Lab 4: Optimización de Jobs Spark
│   ├── Lab 5: MLOps con MLflow y DevOps
│   ├── Lab 6: Orquestación de Workflows
│   ├── Lab 7: Análisis con MLflow
│   ├── Lab 8: Configuración Ramas Databricks-GitHub
│   └── Lab 9-11: Cluster Avanzado (Partes 1-3)
│
└── 📁 FundamentosArquitecturaAzureDatabricks/   # Serie especializada
    ├── Lab 1: Fundamentos de Arquitectura
    ├── Lab 3: Feature Engineering y Exploración de Datos
    ├── Lab 4: Entrenamiento y Registro de Modelos con MLflow
    └── owid-energy-data.csv (Dataset de ejemplo)
```

## 🚀 Guía de Inicio Rápido

### Prerrequisitos

- **Cuenta de Azure** con permisos para crear recursos
- **Azure Databricks Workspace** activo
- **Conocimientos básicos** de:
  - Python
  - SQL
  - Conceptos de Machine Learning
  - Big Data (recomendado)

### Instalación

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/alemcuevas/AzureDatabricksWorkshop.git
   cd AzureDatabricksWorkshop
   ```

2. **Configurar Azure Databricks:**
   - Sigue el `Laboratorio Preparatorio` en DatabricksBasico
   - Crea un workspace en Azure Portal
   - Configura un cluster de Databricks

3. **Importar notebooks:**
   - Sube los archivos `.ipynb` a tu workspace de Databricks
   - O utiliza la integración con Git (ver Lab 8 - Avanzado)

## 📖 Rutas de Aprendizaje

### 🟢 Ruta 1: Principiante (2-3 semanas)

**Objetivo:** Fundamentos de Databricks y Spark

1. **DatabricksBasico** - Completar todos los laboratorios (1-4)
2. **FundamentosArquitecturaAzureDatabricks/Lab1** - Arquitectura básica
3. Práctica: Crear tu primer pipeline de datos

**Duración estimada:** 15-20 horas

### 🟡 Ruta 2: Intermedio (3-4 semanas)

**Objetivo:** Pipelines de producción y ML

1. **DatabricksIntermedio** - Laboratorios 1-6
2. **FundamentosArquitecturaAzureDatabricks/Lab3-4** - Feature Engineering y MLflow
3. Conceptos avanzados: Caching, Lazy Evaluation, Catalyst Optimizer
4. Proyecto: Pipeline completo de ML

**Duración estimada:** 25-30 horas

### 🔴 Ruta 3: Avanzado (4-6 semanas)

**Objetivo:** MLOps y arquitecturas empresariales

1. **DatabricksAvanzado** - Labs 1-11
2. Implementar CI/CD con Azure DevOps
3. Arquitectura Lakehouse completa
4. Streaming en tiempo real con Kafka
5. Proyecto final: Sistema MLOps end-to-end

**Duración estimada:** 35-40 horas

## 🎓 Laboratorios Destacados

### 📊 Lab 3: Feature Engineering y Exploración de Datos

**Duración:** 1 hora | **Nivel:** Intermedio

Aprende a desarrollar pipelines reproducibles de features para modelos de ML:
- EDA con Pandas y Spark
- Creación de variables derivadas
- Imputación y encoding
- Persistencia en Delta Lake
- Control de data drift

**Archivos:**
- `FundamentosArquitecturaAzureDatabricks/Lab3_Feature_Engineering_Exploracion_Datos.ipynb`
- `FundamentosArquitecturaAzureDatabricks/Lab3_Feature_Engineering_Exploracion_Datos.md`

### 🤖 Lab 4: Entrenamiento y Registro de Modelos con MLflow

**Duración:** 1 hora | **Nivel:** Intermedio

Domina MLflow para gestionar el ciclo de vida completo de modelos ML:
- Configuración de experimentos
- Tracking de métricas y parámetros
- Model Registry y versionado
- Comparación de modelos
- Búsqueda de hiperparámetros
- Deployment desde Registry

**Archivos:**
- `FundamentosArquitecturaAzureDatabricks/Lab4_Entrenamiento_Registro_Modelos_MLflow.ipynb`
- `FundamentosArquitecturaAzureDatabricks/Lab4_Entrenamiento_Registro_Modelos_MLflow.md`

### 🏗️ Lab 3 Avanzado: Arquitectura Lakehouse

**Duración:** 2 horas | **Nivel:** Avanzado

Implementa una arquitectura Lakehouse moderna:
- Bronze, Silver, Gold layers
- Medallion Architecture
- Data governance
- Performance optimization

**Archivo:**
- `DatabricksAvanzado/Lab3_Arquitectura_Lakehouse.ipynb`

### 🔄 Lab 5 Avanzado: MLOps con MLflow y DevOps

**Duración:** 2 horas | **Nivel:** Avanzado

Integra MLflow con Azure DevOps para pipelines CI/CD:
- Automatización de entrenamiento
- Testing de modelos
- Deployment continuo
- Monitoreo en producción

**Archivo:**
- `DatabricksAvanzado/Lab5_MLOps_MLflow_DevOps.ipynb`

## 🛠️ Tecnologías Utilizadas

| Tecnología | Descripción | Uso en el Workshop |
|------------|-------------|-------------------|
| **Azure Databricks** | Plataforma de análisis unificada | Entorno principal de desarrollo |
| **Apache Spark** | Motor de procesamiento distribuido | Procesamiento de Big Data |
| **PySpark** | API Python para Spark | Análisis y transformación de datos |
| **Delta Lake** | Capa de almacenamiento ACID | Gestión de datos confiable |
| **MLflow** | Plataforma MLOps | Tracking, registro y deployment de modelos |
| **Pandas** | Librería de análisis de datos | EDA y manipulación de datos |
| **Scikit-learn** | Framework de Machine Learning | Algoritmos y métricas de ML |
| **Matplotlib/Seaborn** | Visualización de datos | Gráficos y análisis visual |
| **Apache Kafka** | Streaming de eventos | Pipelines en tiempo real |
| **Azure DevOps** | CI/CD y gestión de proyectos | Automatización y MLOps |

## 📊 Dataset de Ejemplo

El workshop utiliza el dataset **Our World in Data - Energy** (`owid-energy-data.csv`) que contiene:

- 🌍 Datos de consumo energético mundial
- 📅 Series temporales por país y año
- ⚡ Variables de energías renovables y fósiles
- 🌱 Emisiones de gases de efecto invernadero
- 📈 Indicadores económicos (GDP, población)

**Ideal para:**
- Feature engineering
- Análisis de series temporales
- Modelos de clasificación y regresión
- Visualizaciones interactivas

## 💡 Mejores Prácticas Implementadas

### 📝 Código
- ✅ Notebooks bien documentados con markdown
- ✅ Código modular y reutilizable
- ✅ Funciones parametrizadas
- ✅ Manejo de errores

### 🔒 Seguridad
- ✅ Control de acceso basado en roles (RBAC)
- ✅ Secrets management con Azure Key Vault
- ✅ Network isolation
- ✅ Auditoría y logging

### 🚀 Performance
- ✅ Particionamiento de datos
- ✅ Caching estratégico
- ✅ Broadcast joins
- ✅ Optimización de Spark SQL

### 🔄 MLOps
- ✅ Versionado de modelos
- ✅ Reproducibilidad con MLflow
- ✅ CI/CD pipelines
- ✅ Monitoreo de drift

## 🎯 Casos de Uso Cubiertos

1. **Data Engineering**
   - ETL/ELT pipelines
   - Data quality checks
   - Incremental processing
   - Change Data Capture (CDC)

2. **Data Science**
   - Exploratory Data Analysis (EDA)
   - Feature engineering
   - Model training y tuning
   - A/B testing

3. **Machine Learning Operations**
   - Experiment tracking
   - Model registry
   - Automated deployment
   - Model monitoring

4. **Real-time Analytics**
   - Streaming ingestion
   - Real-time transformations
   - Event-driven architectures

## 🤝 Contribución

¡Las contribuciones son bienvenidas! Si deseas mejorar este workshop:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Guías de Contribución

- Mantén el formato y estructura existente
- Documenta claramente los nuevos laboratorios
- Incluye ejemplos prácticos y casos de uso
- Actualiza el README si es necesario

## 📝 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👥 Autor

**Alejandro Cuevas** - [@alemcuevas](https://github.com/alemcuevas)

## 🙏 Agradecimientos

- Comunidad de Azure Databricks
- Documentación oficial de Apache Spark
- Equipo de MLflow
- Contribuidores y estudiantes del workshop

## 📞 Soporte y Contacto

- 📧 **Issues:** [GitHub Issues](https://github.com/alemcuevas/AzureDatabricksWorkshop/issues)
- 💬 **Discusiones:** [GitHub Discussions](https://github.com/alemcuevas/AzureDatabricksWorkshop/discussions)
- 📚 **Wiki:** [Project Wiki](https://github.com/alemcuevas/AzureDatabricksWorkshop/wiki)

## 🗺️ Roadmap

### En Desarrollo
- [ ] Lab 2: Data Quality Framework
- [ ] Lab 5: AutoML con Databricks
- [ ] Integración con Azure Synapse Analytics
- [ ] Módulo de Deep Learning con TensorFlow

### Planeado
- [ ] Workshop en video
- [ ] Certificaciones recomendadas
- [ ] Casos de uso por industria
- [ ] Templates de proyectos

---

⭐ **Si este workshop te resulta útil, considera darle una estrella en GitHub** ⭐

## 📈 Estado del Proyecto

![GitHub last commit](https://img.shields.io/github/last-commit/alemcuevas/AzureDatabricksWorkshop)
![GitHub issues](https://img.shields.io/github/issues/alemcuevas/AzureDatabricksWorkshop)
![GitHub stars](https://img.shields.io/github/stars/alemcuevas/AzureDatabricksWorkshop)
![GitHub forks](https://img.shields.io/github/forks/alemcuevas/AzureDatabricksWorkshop)

**Última actualización:** Diciembre 2025  
**Versión:** 1.0.0  
**Estado:** Activo y en continuo desarrollo

---

<div align="center">
  <strong>Happy Learning! 🚀📊🤖</strong>
</div>