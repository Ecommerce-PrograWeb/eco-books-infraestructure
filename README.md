# 🏗️ Eco-Books AWS Infrastructure

> Infraestructura como código (IaC) para desplegar Eco-Books en AWS usando AWS CDK (Python)

[![AWS](https://img.shields.io/badge/AWS-ECS_Fargate-orange)](https://aws.amazon.com/ecs/)
[![CDK](https://img.shields.io/badge/AWS_CDK-2.167.0-blue)](https://aws.amazon.com/cdk/)
[![Python](https://img.shields.io/badge/Python-3.9+-green)](https://www.python.org/)

---

## 📖 Documentación Completa

| Documento | Descripción |
|-----------|-------------|
| **[SETUP_COMPLETE.md](SETUP_COMPLETE.md)** | 🎯 **¡EMPIEZA AQUÍ!** Guía rápida con checklist completo |
| **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** | 📚 Guía detallada paso a paso (15+ páginas) |
| **[QUICK_START.md](QUICK_START.md)** | ⚡ Referencia rápida de comandos |
| **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** | 📊 Resumen ejecutivo del proyecto |
| **[CONNECTIONS_GUIDE.md](CONNECTIONS_GUIDE.md)** | 🔧 Configurar conexiones backend-frontend |

---

## 🏗️ Arquitectura AWS

Esta infraestructura despliega automáticamente:

### Infraestructura de Red
- **VPC** con 2 Availability Zones para alta disponibilidad
- Subredes públicas y privadas
- NAT Gateway para salida a internet

### Servicios de Aplicación
- **ECS Fargate** - Backend Node.js/Express
- **ECS Fargate** - Frontend Next.js
- **Application Load Balancers** (2) con health checks

### Datos y Almacenamiento
- **RDS MySQL** 8.0 (db.t3.small) en subred privada
- **ECR** - Repositorios Docker para backend y frontend
- **Secrets Manager** - Credenciales de base de datos

### Monitoreo y Seguridad
- **CloudWatch** - Logs y Container Insights
- **Security Groups** configurados correctamente
- **IAM Roles** con mínimo privilegio

## 🚀 Requisitos Previos

### Local
- Python 3.9 o superior
- Node.js 18 o superior (para AWS CDK CLI)
- AWS CLI configurado con credenciales
- Cuenta de AWS con permisos adecuados

### Instalar AWS CDK CLI
```powershell
npm install -g aws-cdk
```

## 📦 Instalación

### 1. Crear y activar entorno virtual

```powershell
# Crear entorno virtual
python -m venv .venv

# Activar entorno virtual
.venv\Scripts\activate

# O simplemente usar:
.\source.bat
```

### 2. Instalar dependencias

```powershell
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

## 🔧 Configuración

### Variables de Entorno AWS

Asegúrate de tener configuradas tus credenciales de AWS:

```powershell
# Configurar AWS CLI (si no lo has hecho)
aws configure

# O establecer variables de entorno
$env:AWS_ACCESS_KEY_ID="tu-access-key"
$env:AWS_SECRET_ACCESS_KEY="tu-secret-key"
$env:AWS_DEFAULT_REGION="us-east-1"
```

## 🚀 Despliegue

### 1. Bootstrap CDK (solo la primera vez)

```powershell
cdk bootstrap
```

Este comando configura los recursos necesarios en tu cuenta de AWS para usar CDK.

### 2. Sintetizar la plantilla de CloudFormation

```powershell
cdk synth
```

Esto genera la plantilla de CloudFormation que CDK usará para crear los recursos.

### 3. Ver los cambios que se aplicarán

```powershell
cdk diff
```

### 4. Desplegar la infraestructura

```powershell
cdk deploy
```

Este proceso tomará aproximadamente 10-15 minutos. Al finalizar, verás los outputs con:
- URLs de los repositorios ECR
- URLs de los Load Balancers
- Endpoint de la base de datos

### 5. Confirmar el despliegue

Cuando se te pregunte si deseas desplegar los cambios, escribe `y` y presiona Enter.

## 📤 Subir imágenes Docker a ECR

Después del despliegue, necesitas construir y subir las imágenes Docker:

### Backend

```powershell
# Navegar al directorio del backend
cd ..\eco-books-backend

# Obtener el URI del repositorio ECR (desde los outputs del deploy)
$BACKEND_REPO_URI="<tu-account-id>.dkr.ecr.us-east-1.amazonaws.com/eco-books-backend"

# Login a ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $BACKEND_REPO_URI

# Construir la imagen
docker build -t eco-books-backend .

# Tag de la imagen
docker tag eco-books-backend:latest ${BACKEND_REPO_URI}:latest

# Push a ECR
docker push ${BACKEND_REPO_URI}:latest
```

### Frontend

```powershell
# Navegar al directorio del frontend
cd ..\eco-books-frontend

# Obtener el URI del repositorio ECR
$FRONTEND_REPO_URI="<tu-account-id>.dkr.ecr.us-east-1.amazonaws.com/eco-books-frontend"

# Login a ECR (si no lo has hecho)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $FRONTEND_REPO_URI

# Construir la imagen
docker build -t eco-books-frontend .

# Tag de la imagen
docker tag eco-books-frontend:latest ${FRONTEND_REPO_URI}:latest

# Push a ECR
docker push ${FRONTEND_REPO_URI}:latest
```

### Actualizar los servicios ECS

Después de subir las imágenes, fuerza la actualización de los servicios:

```powershell
# Actualizar backend
aws ecs update-service --cluster eco-books-cluster --service <backend-service-name> --force-new-deployment

# Actualizar frontend
aws ecs update-service --cluster eco-books-cluster --service <frontend-service-name> --force-new-deployment
```

## 🔄 CI/CD con GitHub Actions

Para automatizar el despliegue, configura GitHub Actions (ver archivos en `.github/workflows/`).

### Secrets necesarios en GitHub:

Para **eco-books-backend**:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` (ejemplo: us-east-1)
- `ECR_REPOSITORY` (ejemplo: eco-books-backend)
- `ECS_CLUSTER` (ejemplo: eco-books-cluster)
- `ECS_SERVICE` (ejemplo: el nombre del servicio de backend)

Para **eco-books-frontend**:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `ECR_REPOSITORY` (ejemplo: eco-books-frontend)
- `ECS_CLUSTER` (ejemplo: eco-books-cluster)
- `ECS_SERVICE` (ejemplo: el nombre del servicio de frontend)

## 🗑️ Destruir la infraestructura

Para eliminar todos los recursos creados:

```powershell
cdk destroy
```

⚠️ **Advertencia**: Esto eliminará todos los recursos, pero la base de datos se guardará como snapshot debido a la configuración de `RemovalPolicy.SNAPSHOT`.

## 📊 Outputs del Stack

Después del despliegue, obtendrás:

- **BackendRepositoryUri**: URI del repositorio ECR del backend
- **FrontendRepositoryUri**: URI del repositorio ECR del frontend
- **BackendURL**: URL del Load Balancer del backend
- **FrontendURL**: URL del Load Balancer del frontend
- **DatabaseEndpoint**: Endpoint de la base de datos RDS
- **DatabaseSecretArn**: ARN del secreto con las credenciales de la base de datos

## 🔍 Comandos Útiles

- `cdk ls` - Lista todos los stacks en la app
- `cdk synth` - Sintetiza la plantilla de CloudFormation
- `cdk deploy` - Despliega el stack a AWS
- `cdk diff` - Compara el stack local con el desplegado
- `cdk destroy` - Elimina el stack de AWS
- `cdk docs` - Abre la documentación de CDK

## 📝 Notas

- La base de datos se crea en subredes privadas por seguridad
- Los servicios ECS usan Fargate (sin servidores que administrar)
- Se incluye auto-scaling de almacenamiento para RDS
- Los logs se envían automáticamente a CloudWatch
- Las imágenes Docker se escanean automáticamente en ECR

## 🆘 Troubleshooting

### Error: "Resource already exists"
Si obtienes un error indicando que un recurso ya existe, verifica que no tengas un stack anterior sin eliminar.

### Error de credenciales AWS
Asegúrate de que tus credenciales de AWS estén configuradas correctamente con `aws configure`.

### Los servicios no inician
Verifica que las imágenes Docker estén correctamente subidas a ECR con el tag `latest`.

## 📚 Recursos Adicionales

- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
