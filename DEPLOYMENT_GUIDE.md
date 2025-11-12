# 🚀 Guía de Despliegue Completo - Eco-Books en AWS

Esta guía te llevará paso a paso para desplegar tu aplicación completa en AWS.

## 📋 Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Paso 1: Configurar AWS CLI](#paso-1-configurar-aws-cli)
3. [Paso 2: Desplegar Infraestructura con CDK](#paso-2-desplegar-infraestructura-con-cdk)
4. [Paso 3: Obtener Información de los Recursos](#paso-3-obtener-información-de-los-recursos)
5. [Paso 4: Subir Imágenes Docker a ECR](#paso-4-subir-imágenes-docker-a-ecr)
6. [Paso 5: Configurar GitHub Secrets](#paso-5-configurar-github-secrets)
7. [Paso 6: Actualizar Variables de Entorno](#paso-6-actualizar-variables-de-entorno)
8. [Paso 7: Verificar el Despliegue](#paso-7-verificar-el-despliegue)

---

## Requisitos Previos

Asegúrate de tener instalado:

- ✅ Python 3.9+
- ✅ Node.js 18+
- ✅ Docker Desktop
- ✅ AWS CLI
- ✅ Git
- ✅ Cuenta de AWS con permisos de administrador

---

## Paso 1: Configurar AWS CLI

### 1.1 Instalar AWS CLI (si no lo tienes)

```powershell
# Descargar e instalar desde:
# https://awscli.amazonaws.com/AWSCLIV2.msi
```

### 1.2 Configurar Credenciales

```powershell
aws configure
```

Te pedirá:
- **AWS Access Key ID**: Tu clave de acceso de AWS
- **AWS Secret Access Key**: Tu clave secreta de AWS
- **Default region name**: `us-east-1` (recomendado)
- **Default output format**: `json`

### 1.3 Verificar la Configuración

```powershell
aws sts get-caller-identity
```

Deberías ver tu información de cuenta de AWS.

---

## Paso 2: Desplegar Infraestructura con CDK

### 2.1 Navegar al directorio de infraestructura

```powershell
cd "c:\Users\georg\OneDrive - Universidad Rafael Landivar\2025 Segundo Semestre\Programación Web\Ecommerce-PW\eco-books-infrastructure"
```

### 2.2 Crear y activar entorno virtual

```powershell
# Crear entorno virtual
python -m venv .venv

# Activar (Windows)
.venv\Scripts\activate
```

### 2.3 Instalar dependencias

```powershell
pip install -r requirements.txt
```

### 2.4 Instalar AWS CDK CLI

```powershell
npm install -g aws-cdk
```

### 2.5 Verificar instalación de CDK

```powershell
cdk --version
```

### 2.6 Bootstrap CDK (solo la primera vez)

```powershell
cdk bootstrap aws://ACCOUNT-ID/us-east-1
```

Reemplaza `ACCOUNT-ID` con tu ID de cuenta de AWS (lo puedes obtener con `aws sts get-caller-identity`).

### 2.7 Sintetizar la plantilla

```powershell
cdk synth
```

### 2.8 Revisar cambios

```powershell
cdk diff
```

### 2.9 Desplegar la infraestructura

```powershell
cdk deploy
```

⏱️ Este proceso tomará aproximadamente **15-20 minutos**.

Cuando se te pregunte `Do you wish to deploy these changes (y/n)?`, escribe `y` y presiona Enter.

---

## Paso 3: Obtener Información de los Recursos

Después del despliegue, verás outputs similares a estos:

```
Outputs:
InfraEcoBooksStack.BackendRepositoryUri = 123456789012.dkr.ecr.us-east-1.amazonaws.com/eco-books-backend
InfraEcoBooksStack.FrontendRepositoryUri = 123456789012.dkr.ecr.us-east-1.amazonaws.com/eco-books-frontend
InfraEcoBooksStack.BackendURL = http://infra-backe-xxxxx.us-east-1.elb.amazonaws.com
InfraEcoBooksStack.FrontendURL = http://infra-front-xxxxx.us-east-1.elb.amazonaws.com
InfraEcoBooksStack.DatabaseEndpoint = ecobooks-xxxxx.us-east-1.rds.amazonaws.com
```

**¡IMPORTANTE! Guarda estos valores, los necesitarás más adelante.**

### 3.1 Obtener nombres de servicios ECS

```powershell
# Listar servicios en el cluster
aws ecs list-services --cluster eco-books-cluster

# Ver detalles de los servicios
aws ecs describe-services --cluster eco-books-cluster --services <service-arn>
```

Guarda los nombres de los servicios (algo como `InfraEcoBooksStack-BackendService-xxxxx`).

---

## Paso 4: Subir Imágenes Docker a ECR

### 4.1 Backend

```powershell
# Navegar al backend
cd "..\eco-books-backend"

# Variables (reemplaza con tus valores de los outputs)
$REGION = "us-east-1"
$BACKEND_REPO = "123456789012.dkr.ecr.us-east-1.amazonaws.com/eco-books-backend"

# Login a ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $BACKEND_REPO

# Construir imagen
docker build -t eco-books-backend .

# Tag
docker tag eco-books-backend:latest ${BACKEND_REPO}:latest

# Push
docker push ${BACKEND_REPO}:latest
```

### 4.2 Frontend

```powershell
# Navegar al frontend
cd "..\eco-books-frontend"

# Variables (reemplaza con tus valores)
$FRONTEND_REPO = "123456789012.dkr.ecr.us-east-1.amazonaws.com/eco-books-frontend"

# Login a ECR (si cerraste la sesión)
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $FRONTEND_REPO

# Construir imagen
docker build -t eco-books-frontend .

# Tag
docker tag eco-books-frontend:latest ${FRONTEND_REPO}:latest

# Push
docker push ${FRONTEND_REPO}:latest
```

### 4.3 Forzar nuevo despliegue de los servicios

```powershell
# Backend
aws ecs update-service --cluster eco-books-cluster --service <backend-service-name> --force-new-deployment

# Frontend
aws ecs update-service --cluster eco-books-cluster --service <frontend-service-name> --force-new-deployment
```

Reemplaza `<backend-service-name>` y `<frontend-service-name>` con los nombres que obtuviste en el paso 3.1.

---

## Paso 5: Configurar GitHub Secrets

### 5.1 Repositorio Backend (eco-books-backend)

Ve a: `https://github.com/TU-USUARIO/eco-books-backend/settings/secrets/actions`

Agrega los siguientes secrets:

| Secret Name | Valor |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Tu AWS Access Key ID |
| `AWS_SECRET_ACCESS_KEY` | Tu AWS Secret Access Key |
| `AWS_REGION` | `us-east-1` |
| `ECR_REPOSITORY` | `eco-books-backend` |
| `ECS_CLUSTER` | `eco-books-cluster` |
| `ECS_SERVICE` | `InfraEcoBooksStack-BackendService-xxxxx` (el nombre completo del servicio) |

### 5.2 Repositorio Frontend (eco-books-frontend)

Ve a: `https://github.com/TU-USUARIO/eco-books-frontend/settings/secrets/actions`

Agrega los siguientes secrets:

| Secret Name | Valor |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Tu AWS Access Key ID |
| `AWS_SECRET_ACCESS_KEY` | Tu AWS Secret Access Key |
| `AWS_REGION` | `us-east-1` |
| `ECR_REPOSITORY` | `eco-books-frontend` |
| `ECS_CLUSTER` | `eco-books-cluster` |
| `ECS_SERVICE` | `InfraEcoBooksStack-FrontendService-xxxxx` (el nombre completo del servicio) |

### 5.3 Cómo agregar secrets en GitHub

1. Ve al repositorio en GitHub
2. Click en **Settings** (⚙️)
3. En el menú lateral: **Secrets and variables** → **Actions**
4. Click en **New repository secret**
5. Ingresa el **Name** y el **Value**
6. Click en **Add secret**

---

## Paso 6: Actualizar Variables de Entorno

### 6.1 Backend

Actualiza el archivo `.env` del backend con los valores de la base de datos:

```env
# Database
DB_HOST=<DatabaseEndpoint del output de CDK>
DB_PORT=3306
DB_NAME=ecobooks
DB_USER=admin
DB_PASSWORD=<obtener desde AWS Secrets Manager>

# JWT
JWT_SECRET=tu-jwt-secret-aqui

# Node
NODE_ENV=production
PORT=3000
```

Para obtener la contraseña de la base de datos:

```powershell
aws secretsmanager get-secret-value --secret-id eco-books-db-credentials --query SecretString --output text
```

### 6.2 Frontend

Actualiza el archivo `.env.local` del frontend:

```env
NEXT_PUBLIC_API_URL=<BackendURL del output de CDK>
```

---

## Paso 7: Verificar el Despliegue

### 7.1 Verificar Backend

```powershell
# Probar el endpoint de salud
curl <BackendURL>/health
```

### 7.2 Verificar Frontend

Abre tu navegador y ve a la `<FrontendURL>` del output de CDK.

### 7.3 Verificar Logs

```powershell
# Ver logs del backend
aws logs tail /ecs/backend --follow

# Ver logs del frontend
aws logs tail /ecs/frontend --follow
```

### 7.4 Verificar Estado de los Servicios

```powershell
# Estado del cluster
aws ecs describe-clusters --clusters eco-books-cluster

# Estado de los servicios
aws ecs describe-services --cluster eco-books-cluster --services <backend-service-name> <frontend-service-name>
```

---

## 🎉 ¡Listo!

Tu aplicación ahora está desplegada en AWS. Cada vez que hagas push a la rama `main` en cualquiera de los repositorios, GitHub Actions automáticamente:

1. Construirá una nueva imagen Docker
2. La subirá a ECR
3. Actualizará el servicio ECS
4. Desplegará la nueva versión

---

## 🔧 Comandos Útiles

### Ver estado de las tareas ECS
```powershell
aws ecs list-tasks --cluster eco-books-cluster
aws ecs describe-tasks --cluster eco-books-cluster --tasks <task-arn>
```

### Ver imágenes en ECR
```powershell
aws ecr list-images --repository-name eco-books-backend
aws ecr list-images --repository-name eco-books-frontend
```

### Conectarse a la base de datos
```powershell
# Necesitarás un bastion host o VPN para conectarte directamente
# La base de datos está en una subred privada por seguridad
```

### Ver costos aproximados
```powershell
aws ce get-cost-and-usage --time-period Start=2025-11-01,End=2025-11-11 --granularity DAILY --metrics BlendedCost
```

---

## 🆘 Troubleshooting

### Error: "No space left on device" al construir Docker
```powershell
docker system prune -a
```

### Error: Tasks no inician en ECS
1. Verifica los logs en CloudWatch
2. Verifica que la imagen exista en ECR con el tag `latest`
3. Verifica las variables de entorno en la task definition

### Error: No puedo conectarme a la base de datos
- La base de datos está en subredes privadas
- Solo el backend puede conectarse directamente
- Para acceso administrativo, necesitas un bastion host

### Error: GitHub Actions falla
1. Verifica que todos los secrets estén configurados correctamente
2. Verifica los nombres de los servicios ECS
3. Revisa los logs de GitHub Actions para más detalles

---

## 📚 Siguientes Pasos

- [ ] Configurar un dominio personalizado con Route 53
- [ ] Agregar certificado SSL/TLS con ACM
- [ ] Configurar auto-scaling para los servicios
- [ ] Agregar alarmas de CloudWatch
- [ ] Configurar backups automáticos de la base de datos
- [ ] Implementar CI/CD para la infraestructura

---

## 💰 Estimación de Costos (Aproximada)

- **RDS db.t3.small**: ~$30/mes
- **ECS Fargate** (2 servicios, 0.25 vCPU, 0.5 GB RAM): ~$15/mes
- **Application Load Balancer** (2): ~$35/mes
- **NAT Gateway**: ~$35/mes
- **Data Transfer**: Variable
- **CloudWatch Logs**: ~$5/mes

**Total aproximado**: $120-150/mes

Para reducir costos:
- Usa db.t3.micro para la base de datos
- Reduce las tareas de ECS cuando no estés usando
- Usa solo 1 NAT Gateway
- Configura lifecycle policies en ECR para eliminar imágenes antiguas
