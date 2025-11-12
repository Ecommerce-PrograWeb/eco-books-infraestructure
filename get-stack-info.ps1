# Script para obtener información del stack desplegado

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ECO-BOOKS - Stack Information" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$stackName = "InfraEcoBooksStack"
$region = "us-east-2"

Write-Host "Obteniendo información del stack: $stackName (región: $region)" -ForegroundColor Yellow
Write-Host ""

try {
    # Obtener outputs del stack
    $outputs = aws cloudformation describe-stacks --stack-name $stackName --region $region --query "Stacks[0].Outputs" | ConvertFrom-Json
    
    Write-Host "📦 REPOSITORIOS ECR:" -ForegroundColor Green
    Write-Host "─────────────────────────────────────────" -ForegroundColor Gray
    $backendRepo = ($outputs | Where-Object { $_.OutputKey -eq "BackendRepositoryUri" }).OutputValue
    $frontendRepo = ($outputs | Where-Object { $_.OutputKey -eq "FrontendRepositoryUri" }).OutputValue
    Write-Host "Backend:  $backendRepo" -ForegroundColor White
    Write-Host "Frontend: $frontendRepo" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🌐 URLs DE LA APLICACIÓN:" -ForegroundColor Green
    Write-Host "─────────────────────────────────────────" -ForegroundColor Gray
    $backendURL = ($outputs | Where-Object { $_.OutputKey -eq "BackendURL" }).OutputValue
    $frontendURL = ($outputs | Where-Object { $_.OutputKey -eq "FrontendURL" }).OutputValue
    Write-Host "Backend:  $backendURL" -ForegroundColor White
    Write-Host "Frontend: $frontendURL" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🗄️  BASE DE DATOS:" -ForegroundColor Green
    Write-Host "─────────────────────────────────────────" -ForegroundColor Gray
    $dbEndpoint = ($outputs | Where-Object { $_.OutputKey -eq "DatabaseEndpoint" }).OutputValue
    $dbSecretArn = ($outputs | Where-Object { $_.OutputKey -eq "DatabaseSecretArn" }).OutputValue
    Write-Host "Endpoint: $dbEndpoint" -ForegroundColor White
    Write-Host "Secret:   $dbSecretArn" -ForegroundColor White
    Write-Host ""
    
    # Obtener credenciales de la base de datos
    Write-Host "🔐 CREDENCIALES DE LA BASE DE DATOS:" -ForegroundColor Green
    Write-Host "─────────────────────────────────────────" -ForegroundColor Gray
    $secret = aws secretsmanager get-secret-value --secret-id $dbSecretArn --region $region --query SecretString --output text | ConvertFrom-Json
    Write-Host "Usuario:     $($secret.username)" -ForegroundColor White
    Write-Host "Contraseña:  $($secret.password)" -ForegroundColor White
    Write-Host ""
    
    # Obtener servicios ECS
    Write-Host "🚀 SERVICIOS ECS:" -ForegroundColor Green
    Write-Host "─────────────────────────────────────────" -ForegroundColor Gray
    $services = aws ecs list-services --cluster eco-books-cluster --region $region --query "serviceArns" | ConvertFrom-Json
    foreach ($service in $services) {
        $serviceName = $service -replace ".*service/", ""
        Write-Host "  • $serviceName" -ForegroundColor White
    }
    Write-Host ""
    
    Write-Host "📋 VARIABLES DE ENTORNO PARA BACKEND (.env):" -ForegroundColor Green
    Write-Host "─────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "DB_HOST=$dbEndpoint" -ForegroundColor Cyan
    Write-Host "DB_PORT=3306" -ForegroundColor Cyan
    Write-Host "DB_NAME=ecobooks" -ForegroundColor Cyan
    Write-Host "DB_USER=$($secret.username)" -ForegroundColor Cyan
    Write-Host "DB_PASS=$($secret.password)" -ForegroundColor Cyan
    Write-Host "NODE_ENV=production" -ForegroundColor Cyan
    Write-Host "PORT=3000" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "📋 VARIABLES DE ENTORNO PARA FRONTEND (.env.local):" -ForegroundColor Green
    Write-Host "─────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "NEXT_PUBLIC_API_URL=$backendURL" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "🔧 GITHUB SECRETS NECESARIOS:" -ForegroundColor Green
    Write-Host "─────────────────────────────────────────" -ForegroundColor Gray
    $accountId = aws sts get-caller-identity --query Account --output text
    Write-Host "AWS_ACCESS_KEY_ID=<tu-access-key>" -ForegroundColor Magenta
    Write-Host "AWS_SECRET_ACCESS_KEY=<tu-secret-key>" -ForegroundColor Magenta
    Write-Host "AWS_REGION=$region" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Para Backend:" -ForegroundColor Yellow
    Write-Host "  ECR_REPOSITORY=eco-books-backend" -ForegroundColor Magenta
    Write-Host "  ECS_CLUSTER=eco-books-cluster" -ForegroundColor Magenta
    Write-Host "  ECS_SERVICE=$($services[0] -replace '.*service/', '')" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Para Frontend:" -ForegroundColor Yellow
    Write-Host "  ECR_REPOSITORY=eco-books-frontend" -ForegroundColor Magenta
    Write-Host "  ECS_CLUSTER=eco-books-cluster" -ForegroundColor Magenta
    Write-Host "  ECS_SERVICE=$($services[1] -replace '.*service/', '')" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  ✅ Información obtenida exitosamente" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Asegúrate de que:" -ForegroundColor Yellow
    Write-Host "  1. El stack '$stackName' esté desplegado" -ForegroundColor White
    Write-Host "  2. AWS CLI esté configurado correctamente" -ForegroundColor White
    Write-Host "  3. Tengas permisos para acceder a los recursos" -ForegroundColor White
}
