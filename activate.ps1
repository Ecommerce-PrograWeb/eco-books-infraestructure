# Script de activación del entorno virtual para PowerShell
# Uso: .\activate.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Eco-Books Infrastructure Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar si Python está instalado
Write-Host "Verificando Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✓ $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Python no encontrado. Instala Python desde https://www.python.org/" -ForegroundColor Red
    exit 1
}

# Verificar si el entorno virtual existe
if (-Not (Test-Path ".venv")) {
    Write-Host ""
    Write-Host "Creando entorno virtual..." -ForegroundColor Yellow
    python -m venv .venv
    Write-Host "✓ Entorno virtual creado" -ForegroundColor Green
}

# Activar entorno virtual
Write-Host ""
Write-Host "Activando entorno virtual..." -ForegroundColor Yellow

$activateScript = ".venv\Scripts\Activate.ps1"

if (Test-Path $activateScript) {
    try {
        & $activateScript
        Write-Host "✓ Entorno virtual activado" -ForegroundColor Green
        Write-Host ""
        Write-Host "Ahora puedes ejecutar:" -ForegroundColor Cyan
        Write-Host "  pip install -r requirements.txt" -ForegroundColor White
        Write-Host ""
    } catch {
        Write-Host "✗ Error al activar. Intenta ejecutar:" -ForegroundColor Red
        Write-Host "  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
        Write-Host "  Luego ejecuta este script nuevamente." -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ No se encontró el script de activación" -ForegroundColor Red
}
