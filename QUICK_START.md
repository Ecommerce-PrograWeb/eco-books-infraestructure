# 🚀 Quick Start - Comandos Principales

## 📦 Setup Inicial

```powershell
# 1. Navegar a la carpeta de infraestructura
cd "eco-books-infrastructure"

# 2. Crear entorno virtual de Python
python -m venv .venv

# 3. Activar entorno virtual
.venv\Scripts\activate

# 4. Instalar dependencias de Python
pip install -r requirements.txt

# 5. Instalar AWS CDK CLI (global)
npm install -g aws-cdk

# 6. Configurar AWS (si aún no lo has hecho)
aws configure
```

## 🏗️ Comandos CDK Principales

```powershell
# Bootstrap CDK (solo primera vez)
cdk bootstrap

# Sintetizar (generar CloudFormation template)
cdk synth

# Ver diferencias con lo desplegado
cdk diff

# Desplegar todo
cdk deploy

# Destruir toda la infraestructura
cdk destroy
```

## 🐳 Docker + ECR

### Backend

```powershell
# Variables (reemplaza con tus valores)
$REGION = "us-east-1"
$ACCOUNT_ID = "123456789012"
$BACKEND_REPO = "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/eco-books-backend"

# Login a ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $BACKEND_REPO

# Construir y subir
cd ..\eco-books-backend
docker build -t eco-books-backend .
docker tag eco-books-backend:latest ${BACKEND_REPO}:latest
docker push ${BACKEND_REPO}:latest

# Actualizar servicio ECS
aws ecs update-service --cluster eco-books-cluster --service <backend-service-name> --force-new-deployment
```

### Frontend

```powershell
# Variables
$FRONTEND_REPO = "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/eco-books-frontend"

# Login a ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $FRONTEND_REPO

# Construir y subir
cd ..\eco-books-frontend
docker build -t eco-books-frontend .
docker tag eco-books-frontend:latest ${FRONTEND_REPO}:latest
docker push ${FRONTEND_REPO}:latest

# Actualizar servicio ECS
aws ecs update-service --cluster eco-books-cluster --service <frontend-service-name> --force-new-deployment
```

## 📊 Comandos de Monitoreo

```powershell
# Ver servicios en ECS
aws ecs list-services --cluster eco-books-cluster

# Ver detalles de servicios
aws ecs describe-services --cluster eco-books-cluster --services <service-name>

# Ver tareas en ejecución
aws ecs list-tasks --cluster eco-books-cluster
aws ecs describe-tasks --cluster eco-books-cluster --tasks <task-arn>

# Ver logs (requiere nombre del log group)
aws logs tail /ecs/backend --follow
aws logs tail /ecs/frontend --follow

# Ver imágenes en ECR
aws ecr list-images --repository-name eco-books-backend
aws ecr list-images --repository-name eco-books-frontend

# Ver secretos
aws secretsmanager list-secrets
aws secretsmanager get-secret-value --secret-id eco-books-db-credentials
```

## 🔧 Obtener Información del Stack

```powershell
# Obtener outputs del stack
aws cloudformation describe-stacks --stack-name InfraEcoBooksStack --query "Stacks[0].Outputs"

# Obtener URL del backend
aws cloudformation describe-stacks --stack-name InfraEcoBooksStack --query "Stacks[0].Outputs[?OutputKey=='BackendURL'].OutputValue" --output text

# Obtener URL del frontend
aws cloudformation describe-stacks --stack-name InfraEcoBooksStack --query "Stacks[0].Outputs[?OutputKey=='FrontendURL'].OutputValue" --output text

# Obtener endpoint de la base de datos
aws cloudformation describe-stacks --stack-name InfraEcoBooksStack --query "Stacks[0].Outputs[?OutputKey=='DatabaseEndpoint'].OutputValue" --output text
```

## 🔑 GitHub Secrets (configurar en GitHub.com)

### Para eco-books-backend:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` = `us-east-1`
- `ECR_REPOSITORY` = `eco-books-backend`
- `ECS_CLUSTER` = `eco-books-cluster`
- `ECS_SERVICE` = (nombre completo del servicio backend)

### Para eco-books-frontend:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` = `us-east-1`
- `ECR_REPOSITORY` = `eco-books-frontend`
- `ECS_CLUSTER` = `eco-books-cluster`
- `ECS_SERVICE` = (nombre completo del servicio frontend)

## 🔄 Workflow CI/CD

Después de configurar los secrets, cada push a `main` automáticamente:
1. ✅ Construye la imagen Docker
2. ✅ La sube a ECR
3. ✅ Actualiza el servicio ECS
4. ✅ Espera que el servicio esté estable

## 🆘 Troubleshooting Rápido

```powershell
# Limpiar Docker local
docker system prune -a

# Ver por qué una tarea no inicia
aws ecs describe-tasks --cluster eco-books-cluster --tasks <task-arn> --query "tasks[0].stoppedReason"

# Reiniciar un servicio
aws ecs update-service --cluster eco-books-cluster --service <service-name> --force-new-deployment

# Verificar health check de Load Balancer
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## 📝 Variables de Entorno Importantes

### Backend (.env)
```env
DB_HOST=<endpoint-from-cdk-output>
DB_PORT=3306
DB_NAME=ecobooks
DB_USER=admin
DB_PASS=<from-secrets-manager>
NODE_ENV=production
PORT=3000
JWT_SECRET=<tu-secret>
```

### Frontend (.env.local)
```env
NEXT_PUBLIC_API_URL=<backend-url-from-cdk-output>
```

## 💡 Tips

- Siempre ejecuta `cdk diff` antes de `cdk deploy` para ver los cambios
- Guarda los outputs de CDK, los necesitarás constantemente
- Los logs de CloudWatch son tu mejor amigo para debugging
- Usa `--force-new-deployment` para forzar actualización de servicios

## 🔗 URLs Útiles

Después del deploy, visita:
- **Frontend**: Output `FrontendURL`
- **Backend**: Output `BackendURL`
- **Backend Health**: `<BackendURL>/health`
- **AWS Console ECS**: https://console.aws.amazon.com/ecs/
- **AWS Console RDS**: https://console.aws.amazon.com/rds/
- **AWS Console CloudWatch**: https://console.aws.amazon.com/cloudwatch/
