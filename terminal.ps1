# 1. Elevar privilegios automáticamente
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Reintentando con permisos de administrador..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. Instalación de aplicaciones con Winget
Write-Host "--- Instalando PowerShell 7 y Oh My Posh ---" -ForegroundColor Cyan
winget install --id Microsoft.PowerShell --source winget --silent

# 2.1. Crear carpeta de aplicaciones en tu usuario (no requiere admin)
$binPath = "$env:LOCALAPPDATA\Programs\oh-my-posh\bin"
if (!(Test-Path $binPath)) { New-Item -ItemType Directory -Path $binPath -Force }

# 2.2. Descargar el ejecutable directamente de GitHub
Write-Host "Descargando Oh My Posh manualmente..." -ForegroundColor Cyan
invoke-webrequest -uri "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.exe" -OutFile "$binPath\oh-my-posh.exe"

# 2.3. Agregar la carpeta al PATH de tu usuario (para que Windows lo encuentre)
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*oh-my-posh*") {
    [System.Environment]::SetEnvironmentVariable("Path", $currentPath + ";$binPath", "User")
    $env:Path += ";$binPath"
}

Write-Host "Instalación binaria completada." -ForegroundColor Green


# 3. Instalación de módulos
Write-Host "--- Instalando módulo Terminal-Icons ---" -ForegroundColor Cyan
Install-Module -Name Terminal-Icons -Repository PSGallery -Force -AllowClobber -Scope CurrentUser

# 4. Configuración del Perfil ($PROFILE)
Write-Host "--- Configurando el archivo de perfil ---" -ForegroundColor Cyan
$profileDir = Split-Path -Path $PROFILE
if (!(Test-Path -Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force }
if (!(Test-Path -Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }

# Usamos comillas simples para las cadenas para evitar problemas con las variables internas
$configLines = @(
    'oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression',
    'Import-Module -Name Terminal-Icons'
)

foreach ($line in $configLines) {
    # Usamos -Quiet para que devuelva booleano y escapamos la línea correctamente
    $exists = Select-String -Path $PROFILE -Pattern ([regex]::Escape($line)) -Quiet
    
    if (-not $exists) {
        Add-Content -Path $PROFILE -Value "`n$line"
        Write-Host "Añadido al perfil: $line" -ForegroundColor Gray
    }
}

Write-Host "`n[!] TODO LISTO. Reinicia la Terminal." -ForegroundColor Green