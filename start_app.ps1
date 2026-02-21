# ============================================================
# START_APP.PS1 — Script maestro para arrancar la aplicación
# Abre DOS ventanas PowerShell separadas:
#   1. Backend  → FastAPI en http://localhost:8000
#   2. Frontend → Flutter en Chrome
#
# USO: Clic derecho sobre este archivo → "Run with PowerShell"
#      O desde una terminal: .\start_app.ps1
#
# NOTA: El backend usa "uv run uvicorn" porque uvicorn está
#       instalado dentro del entorno virtual de uv, NO globalmente.
# ============================================================

$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $rootDir "backend"
$frontendDir = Join-Path $rootDir "frontend"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   INICIANDO APP COMPLETA (Chat IA)      " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 Backend  → $backendDir" -ForegroundColor Yellow
Write-Host "📱 Frontend → $frontendDir" -ForegroundColor Yellow
Write-Host ""

# ----------------------------------------------------------
# 1. Ventana del BACKEND (FastAPI)
#    IMPORTANTE: Usar "uv run uvicorn" — NO "uvicorn" solo,
#    porque uvicorn vive dentro del venv de uv.
# ----------------------------------------------------------
$backendCmd = @"
`$host.UI.RawUI.WindowTitle = 'BACKEND - FastAPI :8000'
Set-Location '$backendDir'
Write-Host '=====================================' -ForegroundColor Green
Write-Host '  SERVIDOR FASTAPI                   ' -ForegroundColor Green
Write-Host '  URL    : http://localhost:8000      ' -ForegroundColor Green
Write-Host '  Docs   : http://localhost:8000/docs ' -ForegroundColor Green
Write-Host '  Salud  : http://localhost:8000/health' -ForegroundColor Green
Write-Host '=====================================' -ForegroundColor Green
Write-Host ''
uv run uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd
Write-Host "✅ Ventana del Backend abierta." -ForegroundColor Green

# Esperar 4 segundos para que el backend levante antes que Flutter
Write-Host "⏳ Esperando 4 segundos antes de abrir Flutter..." -ForegroundColor Gray
Start-Sleep -Seconds 4

# ----------------------------------------------------------
# 2. Ventana del FRONTEND (Flutter Web en Chrome)
# ----------------------------------------------------------
$frontendCmd = @"
`$host.UI.RawUI.WindowTitle = 'FRONTEND - Flutter Chrome'
Set-Location '$frontendDir'
Write-Host '=====================================' -ForegroundColor Magenta
Write-Host '  FLUTTER WEB - Chrome               ' -ForegroundColor Magenta
Write-Host '  Backend: http://localhost:8000      ' -ForegroundColor Magenta
Write-Host '=====================================' -ForegroundColor Magenta
Write-Host ''
flutter run -d chrome
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCmd
Write-Host "✅ Ventana del Frontend abierta." -ForegroundColor Green
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Todo listo. Revisa las dos ventanas.   " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
