# 1. Elevar privilegios
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Reintentando con permisos de administrador..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. Instalación de aplicaciones
Write-Host "--- Instalando PowerShell 7 ---" -ForegroundColor Cyan
winget install --id Microsoft.PowerShell --source winget --silent

# 2.1. Instalación manual de Oh My Posh (Para saltar bloqueos de política)
$binPath = "$env:LOCALAPPDATA\Programs\oh-my-posh\bin"
if (!(Test-Path $binPath)) { New-Item -ItemType Directory -Path $binPath -Force }

Write-Host "--- Descargando Oh My Posh manualmente ---" -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.exe" -OutFile "$binPath\oh-my-posh.exe"

# 2.2. Agregar al PATH
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*oh-my-posh*") {
    [System.Environment]::SetEnvironmentVariable("Path", $currentPath + ";$binPath", "User")
    $env:Path += ";$binPath"
}

# 3. Instalación de Módulos y Fuentes
Write-Host "--- Instalando Terminal-Icons y Fuente Hack ---" -ForegroundColor Cyan
Install-Module -Name Terminal-Icons -Repository PSGallery -Force -AllowClobber -Scope CurrentUser
& "$binPath\oh-my-posh.exe" font install Hack --admin

# 4. Configuración del Perfil ($PROFILE)
Write-Host "--- Configurando el archivo de perfil ---" -ForegroundColor Cyan
$profileDir = Split-Path -Path $PROFILE
if (!(Test-Path -Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force }
if (!(Test-Path -Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }

# NOTA: Como instalamos manual, NO existe $env:POSH_THEMES_PATH por defecto. 
# Usamos una URL directa al tema para que siempre funcione.
$configLines = @(
    'oh-my-posh init pwsh --config "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/jandedobbeleer.omp.json" | Invoke-Expression',
    'Import-Module -Name Terminal-Icons'
)

foreach ($line in $configLines) {
    $exists = Select-String -Path $PROFILE -Pattern ([regex]::Escape($line)) -Quiet
    if (-not $exists) {
        Add-Content -Path $PROFILE -Value "`n$line"
        Write-Host "Añadido al perfil: $line" -ForegroundColor Gray
    }
}

Write-Host "`n[!] TODO LISTO. Cierra esta ventana y abre 'PowerShell 7' (icono negro)." -ForegroundColor Green
Write-Host "[!] RECUERDA: En Configuración > Apariencia, elige la fuente 'Hack NF'." -ForegroundColor Yellow