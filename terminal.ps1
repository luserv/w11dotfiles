# 1. Elevar privilegios automáticamente
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Reintentando con permisos de administrador..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. Instalación de aplicaciones con Winget
Write-Host "--- Instalando PowerShell 7 y Oh My Posh ---" -ForegroundColor Cyan
winget install --id Microsoft.PowerShell --source winget --silent
winget install --id JanDeDobbeleer.OhMyPosh --source winget --silent

# 3. Instalación de módulos
Write-Host "--- Instalando módulo Terminal-Icons ---" -ForegroundColor Cyan
Install-Module -Name Terminal-Icons -Repository PSGallery -Force -AllowClobber -Scope CurrentUser

# 4. Instalación de la fuente específica: Hack Nerd Font
Write-Host "--- Instalando Hack Nerd Font ---" -ForegroundColor Cyan
oh-my-posh font install Hack

# 5. Configuración del Perfil ($PROFILE)
Write-Host "--- Configurando el archivo de perfil ---" -ForegroundColor Cyan
$profileDir = Split-Path -Path $PROFILE
if (!(Test-Path -Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force }
if (!(Test-Path -Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }

$configLines = @(
    'oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression',
    'Import-Module -Name Terminal-Icons'
)

foreach ($line in $configLines) {
    if (!(Select-String -Path $PROFILE -Pattern [regex]::Escape($line))) {
        Add-Content -Path $PROFILE -Value "`n$line"
    }
}

Write-Host "`n[!] TODO LISTO. Reinicia la Terminal de Windows." -ForegroundColor Green
Write-Host "[!] RECUERDA: Cambia la fuente a 'Hack NF' en la configuración de la Terminal." -ForegroundColor Yellow