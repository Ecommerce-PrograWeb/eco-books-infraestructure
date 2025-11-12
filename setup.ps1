# Script de Setup Completo para PowerShell
# Ejecuta todo el proceso de configuración inicial

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Eco-Books Infrastructure Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar Python
Write-Host "[1/6] Verificando Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "      ✓ $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "      ✗ Python no encontrado" -ForegroundColor Red
    Write-Host "      Descarga Python desde: https://www.python.org/" -ForegroundColor Yellow
    exit 1
}

# 2. Crear entorno virtual
Write-Host ""
Write-Host "[2/6] Creando entorno virtual..." -ForegroundColor Yellow
if (Test-Path ".venv") {
    Write-Host "      ✓ Ya existe" -ForegroundColor Green
} else {
    python -m venv .venv
    Write-Host "      ✓ Creado" -ForegroundColor Green
}

# 3. Activar entorno virtual
Write-Host ""
Write-Host "[3/6] Activando entorno virtual..." -ForegroundColor Yellow
$activateScript = ".venv\Scripts\Activate.ps1"

try {
    & $activateScript
    Write-Host "      ✓ Activado" -ForegroundColor Green
} catch {
    Write-Host "      ⚠ Error de permisos. Ejecutando fix..." -ForegroundColor Yellow
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    & $activateScript
    Write-Host "      ✓ Activado" -ForegroundColor Green
}

# 4. Actualizar pip
Write-Host ""
Write-Host "[4/6] Actualizando pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip --quiet
Write-Host "      ✓ pip actualizado" -ForegroundColor Green

# 5. Instalar dependencias
Write-Host ""
Write-Host "[5/6] Instalando dependencias..." -ForegroundColor Yellow
pip install -r requirements.txt --quiet
Write-Host "      ✓ Dependencias instaladas" -ForegroundColor Green

# 6. Instalar dependencias de desarrollo
Write-Host ""
Write-Host "[6/6] Instalando dependencias de desarrollo..." -ForegroundColor Yellow
pip install -r requirements-dev.txt --quiet
Write-Host "      ✓ Dependencias de desarrollo instaladas" -ForegroundColor Green

# Verificar CDK CLI
Write-Host ""
Write-Host "Verificando AWS CDK CLI..." -ForegroundColor Yellow
try {
    $cdkVersion = cdk --version 2>&1
    Write-Host "      ✓ $cdkVersion" -ForegroundColor Green
} catch {
    Write-Host "      ⚠ CDK CLI no encontrado" -ForegroundColor Yellow
    Write-Host "      Instálalo con: npm install -g aws-cdk" -ForegroundColor White
}

# Verificar AWS CLI
Write-Host ""
Write-Host "Verificando AWS CLI..." -ForegroundColor Yellow
try {
    $awsVersion = aws --version 2>&1
    Write-Host "      ✓ AWS CLI instalado" -ForegroundColor Green
} catch {
    Write-Host "      ⚠ AWS CLI no encontrado" -ForegroundColor Yellow
    Write-Host "      Descarga desde: https://aws.amazon.com/cli/" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✓ Setup Completo!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Cyan
Write-Host "  1. Configura AWS CLI: aws configure" -ForegroundColor White
Write-Host "  2. Bootstrap CDK: cdk bootstrap" -ForegroundColor White
Write-Host "  3. Despliega: cdk deploy" -ForegroundColor White
Write-Host ""
Write-Host "Ver guía completa en: SETUP_COMPLETE.md" -ForegroundColor Gray
Write-Host ""
