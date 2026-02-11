# 1. Elevar privilegios
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. Rutas locales
$installDir = "$env:LOCALAPPDATA\Programs\oh-my-posh"
$binPath = "$installDir\bin"
$themesPath = "$installDir\themes"

# Crear carpetas si no existen
if (!(Test-Path $binPath)) { New-Item -ItemType Directory -Path $binPath -Force }
if (!(Test-Path $themesPath)) { New-Item -ItemType Directory -Path $themesPath -Force }

# 3. Descargar ejecutable Oh My Posh
Write-Host "--- Descargando Oh My Posh ---" -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.exe" -OutFile "$binPath\oh-my-posh.exe"

# 4. DESCARGAR TODOS LOS TEMAS
Write-Host "--- Descargando todos los temas oficiales ---" -ForegroundColor Cyan
$themesUri = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip"
$zipFile = "$themesPath\themes.zip"
Invoke-WebRequest -Uri $themesUri -OutFile $zipFile
Expand-Archive -Path $zipFile -DestinationPath $themesPath -Force
Remove-Item $zipFile # Limpiar el zip

# 5. Agregar al PATH y establecer Variable de Entorno para temas
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*oh-my-posh\bin*") {
    [System.Environment]::SetEnvironmentVariable("Path", $currentPath + ";$binPath", "User")
    $env:Path += ";$binPath"
}
# Definir POSH_THEMES_PATH permanentemente para tu usuario
[System.Environment]::SetEnvironmentVariable("POSH_THEMES_PATH", $themesPath, "User")
$env:POSH_THEMES_PATH = $themesPath

# 6. Instalar Fuente y Módulo
Write-Host "--- Instalando Terminal-Icons y Fuente Hack ---" -ForegroundColor Cyan
Install-Module -Name Terminal-Icons -Repository PSGallery -Force -AllowClobber -Scope CurrentUser
& "$binPath\oh-my-posh.exe" font install Hack --admin

# 7. Configurar Perfil
Write-Host "--- Configurando perfil ---" -ForegroundColor Cyan
$profileDir = Split-Path -Path $PROFILE
if (!(Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force }

# Usaremos el tema 'amro' que mencionaste antes, ya que ahora están todos locales
$configLines = @(
    '# Configuración Oh My Posh',
    '$env:POSH_THEMES_PATH = [System.Environment]::GetEnvironmentVariable("POSH_THEMES_PATH", "User")',
    'oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\amro.omp.json" | Invoke-Expression',
    '',
    '# Iconos',
    'Import-Module -Name Terminal-Icons'
)

Set-Content -Path $PROFILE -Value ($configLines -join "`r`n")

Write-Host "`n[!] TODO LISTO. Reinicia la terminal." -ForegroundColor Green