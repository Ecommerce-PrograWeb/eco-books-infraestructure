# 📚 Eco-Books - Resumen del Proyecto AWS

## 🎯 Objetivo
Desplegar la aplicación Eco-Books (backend + frontend) en AWS usando infraestructura como código con AWS CDK.

---

## 📁 Estructura del Proyecto

```
Ecommerce-PW/
├── eco-books-backend/          # API Node.js/Express
│   ├── .github/workflows/      # ✅ CI/CD configurado
│   ├── Dockerfile              # ✅ Listo para ECR
│   └── src/
├── eco-books-frontend/         # App Next.js
│   ├── .github/workflows/      # ✅ CI/CD configurado
│   ├── Dockerfile              # ✅ Listo para ECR
│   └── src/
└── eco-books-infrastructure/   # 🆕 Infraestructura CDK
    ├── app.py                  # Punto de entrada CDK
    ├── cdk.json                # Configuración CDK
    ├── requirements.txt        # Dependencias Python
    ├── infra_eco_books/
    │   └── infra_eco_books_stack.py  # Stack principal
    ├── README.md               # Documentación técnica
    ├── DEPLOYMENT_GUIDE.md     # Guía paso a paso completa
    ├── QUICK_START.md          # Comandos rápidos
    └── get-stack-info.ps1      # Script para obtener info
```

---

## 🏗️ Arquitectura AWS

### Recursos Creados

1. **VPC (Virtual Private Cloud)**
   - 2 Availability Zones para alta disponibilidad
   - Subredes públicas y privadas
   - 1 NAT Gateway

2. **RDS MySQL**
   - Instancia db.t3.small
   - Base de datos: `ecobooks`
   - En subred privada (seguridad)
   - Backups automáticos (7 días)
   - Auto-scaling de almacenamiento (20-100 GB)

3. **ECR (Elastic Container Registry)**
   - Repositorio: `eco-books-backend`
   - Repositorio: `eco-books-frontend`
   - Escaneo automático de vulnerabilidades

4. **ECS Fargate**
   - Cluster: `eco-books-cluster`
   - Servicio Backend (0.25 vCPU, 0.5 GB RAM)
   - Servicio Frontend (0.25 vCPU, 0.5 GB RAM)
   - Sin servidores que administrar

5. **Application Load Balancers**
   - ALB para Backend
   - ALB para Frontend
   - Health checks configurados

6. **Secrets Manager**
   - Credenciales de base de datos
   - Rotación automática disponible

7. **CloudWatch**
   - Logs centralizados
   - Container Insights habilitado
   - Métricas automáticas

---

## 🚀 Proceso de Despliegue

### Fase 1: Preparación (Primera vez - 30 min)
```powershell
# 1. Configurar AWS CLI
aws configure

# 2. Setup infraestructura
cd eco-books-infrastructure
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
npm install -g aws-cdk

# 3. Bootstrap CDK
cdk bootstrap
```

### Fase 2: Despliegue de Infraestructura (15-20 min)
```powershell
# 1. Sintetizar
cdk synth

# 2. Revisar cambios
cdk diff

# 3. Desplegar
cdk deploy
# ⚠️ Guardar los outputs!
```

### Fase 3: Subir Imágenes Docker (10 min por repo)
```powershell
# Backend
cd eco-books-backend
aws ecr get-login-password | docker login ...
docker build -t eco-books-backend .
docker tag eco-books-backend:latest <REPO_URI>:latest
docker push <REPO_URI>:latest

# Frontend
cd eco-books-frontend
# ... mismo proceso
```

### Fase 4: Configurar CI/CD (5 min)
En GitHub.com, configurar secrets en cada repositorio:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION
- ECR_REPOSITORY
- ECS_CLUSTER
- ECS_SERVICE

---

## 🔄 Flujo CI/CD Automatizado

### Después de la configuración inicial:

```
1. Developer hace push a 'main'
   ↓
2. GitHub Actions se activa
   ↓
3. Se construye imagen Docker
   ↓
4. Se sube a ECR
   ↓
5. Se actualiza servicio ECS
   ↓
6. Despliegue automático completo! ✅
```

**Tiempo total**: ~5-10 minutos por despliegue

---

## 📊 Comandos Esenciales

### Para obtener información del stack:
```powershell
.\get-stack-info.ps1
```

### Para redesplegar manualmente:
```powershell
# Después de cambios en código
docker build -t <service> .
docker push <REPO_URI>:latest
aws ecs update-service --cluster eco-books-cluster --service <service-name> --force-new-deployment
```

### Para ver logs:
```powershell
aws logs tail /ecs/backend --follow
aws logs tail /ecs/frontend --follow
```

### Para actualizar infraestructura:
```powershell
cdk diff    # Ver cambios
cdk deploy  # Aplicar cambios
```

---

## 🔐 Seguridad

✅ **Implementado:**
- Base de datos en subred privada
- Secretos en AWS Secrets Manager
- Security Groups con mínimo privilegio
- Escaneo de vulnerabilidades en ECR
- HTTPS en ALB (configurar certificado)

---

## 💰 Costos Estimados

### Mensual (24/7)
- RDS db.t3.small: ~$30
- ECS Fargate (2 servicios): ~$15
- ALB (2): ~$35
- NAT Gateway: ~$35
- CloudWatch: ~$5
- **Total: ~$120-150/mes**

### Optimizaciones para desarrollo:
- Parar servicios cuando no se usen
- Usar db.t3.micro (~$15/mes)
- Reducir a 1 NAT Gateway (ya configurado)
- Configurar lifecycle policies en ECR

---

## 📝 Variables de Entorno Críticas

### Backend
```env
DB_HOST=<from-cdk-output>
DB_PORT=3306
DB_NAME=ecobooks
DB_USER=admin
DB_PASS=<from-secrets-manager>
```

### Frontend
```env
NEXT_PUBLIC_API_URL=<backend-url-from-cdk-output>
```

---

## 🆘 Solución de Problemas Comunes

### 1. Servicios no inician
```powershell
# Ver logs
aws logs tail /ecs/backend --follow

# Ver por qué falló
aws ecs describe-tasks --cluster eco-books-cluster --tasks <task-arn>
```

### 2. Errores de conexión a BD
- Verificar Security Groups
- Verificar credenciales en Secrets Manager
- Verificar que backend tenga acceso al secreto

### 3. GitHub Actions falla
- Verificar todos los secrets estén configurados
- Verificar nombres de servicios sean correctos
- Ver logs en GitHub Actions

---

## 📚 Documentación Completa

1. **README.md** - Información técnica y comandos
2. **DEPLOYMENT_GUIDE.md** - Guía paso a paso detallada
3. **QUICK_START.md** - Referencia rápida de comandos
4. **Este archivo** - Visión general del proyecto

---

## ✅ Checklist de Despliegue

### Inicial (hacer una vez):
- [ ] AWS CLI instalado y configurado
- [ ] Python 3.9+ instalado
- [ ] Node.js 18+ instalado
- [ ] Docker Desktop instalado
- [ ] AWS CDK CLI instalado
- [ ] Cuenta AWS con permisos adecuados

### Por cada despliegue:
- [ ] `cdk synth` ejecutado sin errores
- [ ] `cdk deploy` completado exitosamente
- [ ] Outputs guardados
- [ ] Imágenes Docker subidas a ECR
- [ ] Servicios ECS actualizados
- [ ] GitHub Secrets configurados
- [ ] Variables de entorno actualizadas
- [ ] Health checks pasando
- [ ] Aplicación accesible desde URLs

---

## 🎓 Siguientes Pasos Recomendados

1. **Dominio Personalizado**
   - Registrar dominio en Route 53
   - Crear certificado SSL en ACM
   - Configurar alias records

2. **Monitoreo Avanzado**
   - Configurar alarmas de CloudWatch
   - Implementar dashboards
   - Configurar notificaciones SNS

3. **Optimización**
   - Implementar auto-scaling
   - Configurar CDN con CloudFront
   - Optimizar costos

4. **CI/CD Mejorado**
   - Agregar tests automáticos
   - Implementar blue-green deployment
   - Agregar rollback automático

---

## 📞 Contacto y Soporte

- AWS Documentation: https://docs.aws.amazon.com/
- CDK Documentation: https://docs.aws.amazon.com/cdk/
- ECS Best Practices: https://docs.aws.amazon.com/ecs/

---

**¡Éxito con tu despliegue! 🚀**
