# 🔧 Actualización de Conexiones Backend-Frontend

## ⚠️ Importante: Actualizar después del primer deploy

Después de ejecutar `cdk deploy` por primera vez, necesitarás actualizar las conexiones entre el frontend y el backend.

---

## 📝 Paso 1: Obtener URLs del Deploy

Después de `cdk deploy`, verás outputs como estos:

```
Outputs:
InfraEcoBooksStack.BackendURL = http://infra-backe-xxxxx.us-east-1.elb.amazonaws.com
InfraEcoBooksStack.FrontendURL = http://infra-front-xxxxx.us-east-1.elb.amazonaws.com
```

O ejecuta el script:
```powershell
.\get-stack-info.ps1
```

---

## 🔄 Paso 2: Actualizar Frontend

### Opción A: Variable de Entorno en ECS (Recomendado)

Ya está configurado en el CDK stack. El frontend recibe automáticamente:
```javascript
NEXT_PUBLIC_API_URL=http://<backend-alb-url>
```

### Opción B: Si necesitas cambiar la URL manualmente

Edita el archivo de configuración API en el frontend:

**Archivo**: `eco-books-frontend/src/app/lib/api.ts`

```typescript
// Antes (desarrollo local)
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

// Después (producción)
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://infra-backe-xxxxx.us-east-1.elb.amazonaws.com';
```

---

## 🔧 Paso 3: Verificar Conexiones en el Código

### Frontend - Revisar archivos de API

Busca en tu código del frontend dónde se hacen las llamadas al backend:

```powershell
cd eco-books-frontend
# Buscar llamadas a localhost o URLs hardcodeadas
grep -r "localhost:3000" src/
grep -r "http://localhost" src/
```

Asegúrate de que todas usen la variable de entorno:

```typescript
// ✅ CORRECTO - Usa variable de entorno
const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/books`);

// ❌ INCORRECTO - URL hardcodeada
const response = await fetch('http://localhost:3000/api/books');
```

---

## 🔍 Paso 4: Verificar CORS en el Backend

El backend debe permitir requests desde el frontend en AWS.

**Archivo**: `eco-books-backend/src/app.js`

Busca la configuración de CORS:

```javascript
import cors from 'cors';

// Configuración recomendada para producción
const corsOptions = {
  origin: process.env.FRONTEND_URL || '*', // En producción, especifica la URL del frontend
  credentials: true,
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
```

### Agregar variable de entorno al backend

En el stack de CDK, ya está preparado para recibir variables. Si necesitas agregar FRONTEND_URL:

**Edita**: `infra_eco_books_stack.py`

```python
# En la sección de backend_container
environment={
    "NODE_ENV": "production",
    "DB_HOST": database.db_instance_endpoint_address,
    "DB_PORT": "3306",
    "DB_NAME": "ecobooks",
    "FRONTEND_URL": f"http://{frontend_service.load_balancer.load_balancer_dns_name}",  # Agregar esto
},
```

⚠️ **Nota**: Esto crea una dependencia circular. Mejor opción: permitir todas las URLs en desarrollo y especificar en producción después.

---

## 🚀 Paso 5: Redesplegar con las Nuevas Configuraciones

### Si modificaste el código:

```powershell
# Backend
cd eco-books-backend
docker build -t eco-books-backend .
docker tag eco-books-backend:latest <BACKEND_REPO_URI>:latest
docker push <BACKEND_REPO_URI>:latest
aws ecs update-service --cluster eco-books-cluster --service <backend-service> --force-new-deployment

# Frontend
cd eco-books-frontend
docker build -t eco-books-frontend .
docker tag eco-books-frontend:latest <FRONTEND_REPO_URI>:latest
docker push <FRONTEND_REPO_URI>:latest
aws ecs update-service --cluster eco-books-cluster --service <frontend-service> --force-new-deployment
```

### Si modificaste la infraestructura:

```powershell
cd eco-books-infrastructure
cdk diff    # Ver cambios
cdk deploy  # Aplicar cambios
```

---

## ✅ Paso 6: Probar las Conexiones

### Probar Backend

```powershell
# Health check
$backendUrl = "<BackendURL del output>"
curl "${backendUrl}/health"

# Probar un endpoint de API
curl "${backendUrl}/api/books"
```

### Probar Frontend

```powershell
# Abrir en navegador
$frontendUrl = "<FrontendURL del output>"
Start-Process $frontendUrl
```

### Verificar en Consola del Navegador

1. Abre las Developer Tools (F12)
2. Ve a la pestaña Network
3. Navega por la aplicación
4. Verifica que las llamadas API vayan a la URL correcta del ALB

---

## 🔧 Configuración Completa de Variables de Entorno

### Backend (ECS Task Definition)

Ya configuradas en el CDK:
```
NODE_ENV=production
DB_HOST=<rds-endpoint>
DB_PORT=3306
DB_NAME=ecobooks
DB_USER=<from-secrets-manager>
DB_PASS=<from-secrets-manager>
```

Si necesitas agregar más:
```python
# En infra_eco_books_stack.py
environment={
    # ... las que ya están
    "JWT_SECRET": "tu-secret-aqui",  # Mejor: usar Secrets Manager
    "FRONTEND_URL": "http://...",
}
```

### Frontend (ECS Task Definition)

Ya configuradas en el CDK:
```
NODE_ENV=production
NEXT_PUBLIC_API_URL=<backend-url>
```

---

## 🔐 Configuración de HTTPS (Opcional pero Recomendado)

Para producción, considera agregar HTTPS:

1. **Obtener un dominio** (Route 53 o externo)
2. **Crear certificado SSL** (AWS Certificate Manager)
3. **Actualizar el ALB** para usar HTTPS

En el stack de CDK:

```python
# Importar certificado
from aws_cdk import aws_certificatemanager as acm

# En el código del stack
certificate = acm.Certificate.from_certificate_arn(
    self, "Certificate",
    certificate_arn="arn:aws:acm:region:account:certificate/xxx"
)

# En los servicios Fargate
backend_service = ecs_patterns.ApplicationLoadBalancedFargateService(
    # ... configuración existente
    listener_port=443,  # Cambiar de 80 a 443
    protocol=elbv2.ApplicationProtocol.HTTPS,
    certificate=certificate,
)
```

---

## 📊 Checklist de Conexiones

- [ ] Frontend usa `process.env.NEXT_PUBLIC_API_URL`
- [ ] Backend tiene CORS configurado
- [ ] Variables de entorno configuradas en ECS
- [ ] Health check del backend responde
- [ ] Frontend puede hacer llamadas al backend
- [ ] No hay errores de CORS en consola del navegador
- [ ] Tokens JWT se envían correctamente (si aplica)
- [ ] Cookies se manejan correctamente (si aplica)

---

## 🆘 Troubleshooting de Conexiones

### Error: "Failed to fetch" en Frontend

**Causa**: No puede conectarse al backend

**Solución**:
1. Verificar que `NEXT_PUBLIC_API_URL` esté configurada
2. Verificar que el backend esté corriendo (health check)
3. Verificar Security Groups permitan tráfico

### Error: CORS Policy

**Causa**: Backend no permite requests desde el frontend

**Solución**:
```javascript
// En backend/src/app.js
app.use(cors({
  origin: process.env.FRONTEND_URL || '*',
  credentials: true
}));
```

### Error: 504 Gateway Timeout

**Causa**: Backend tarda mucho en responder

**Solución**:
1. Aumentar timeout del ALB target group
2. Optimizar queries del backend
3. Verificar conexión a base de datos

### Variables de entorno no se cargan

**Causa**: Next.js necesita que las variables `NEXT_PUBLIC_*` estén en build time

**Solución**:
1. Reconstruir la imagen Docker
2. Asegurarse de que estén en el Dockerfile:
```dockerfile
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
```

---

## 💡 Mejores Prácticas

1. **Usa variables de entorno** - Nunca hardcodees URLs
2. **Configura CORS apropiadamente** - Permite solo orígenes conocidos en producción
3. **Usa HTTPS** - Siempre en producción
4. **Monitorea las conexiones** - Usa CloudWatch para ver errores
5. **Implementa retry logic** - En el frontend para requests fallidos
6. **Usa health checks** - Para verificar que el backend esté disponible

---

## 📞 Verificación Final

Ejecuta este script para verificar todas las conexiones:

```powershell
# Obtener URLs
.\get-stack-info.ps1

# Probar backend
$backend = "<BackendURL>"
curl "${backend}/health"

# Probar frontend (abre navegador)
$frontend = "<FrontendURL>"
Start-Process $frontend

# Ver logs en tiempo real
aws logs tail /ecs/backend --follow
```

---

**¡Todo listo! Tu aplicación ahora está conectada correctamente en AWS! 🎉**
