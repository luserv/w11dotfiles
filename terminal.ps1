# 1. Elevar privilegios
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. Definir rutas (Usaremos una ruta estándar para evitar confusiones)
$installDir = "$env:LOCALAPPDATA\Programs\oh-my-posh"
$binPath = "$installDir\bin"
$themesPath = "$installDir\themes"

# Crear carpetas
if (!(Test-Path $themesPath)) { New-Item -ItemType Directory -Path $themesPath -Force }

# 3. Asegurar que el ejecutable existe (Descarga rápida si no está)
if (!(Test-Path "$binPath\oh-my-posh.exe")) {
    Write-Host "Re-descargando ejecutable..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.exe" -OutFile "$binPath\oh-my-posh.exe"
}

# 4. DESCARGAR TEMAS (Método Robusto)
Write-Host "--- Descargando todos los temas oficiales ---" -ForegroundColor Cyan
# Descargamos el zip de temas directamente de la fuente de la release
$themesUrl = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip"
Invoke-WebRequest -Uri $themesUrl -OutFile "$themesPath\themes.zip"

# Descomprimir (Usando -Force para sobreescribir si hay algo corrupto)
Expand-Archive -Path "$themesPath\themes.zip" -DestinationPath $themesPath -Force
Remove-Item "$themesPath\themes.zip"

# 5. Configurar Variables de Entorno
[System.Environment]::SetEnvironmentVariable("POSH_THEMES_PATH", $themesPath, "User")
$env:POSH_THEMES_PATH = $themesPath

# 6. Actualizar el Perfil para que use la ruta LOCAL
Write-Host "--- Actualizando perfil ---" -ForegroundColor Cyan
$profileContent = @"
# Variable de temas
`$env:POSH_THEMES_PATH = '$themesPath'

# Inicialización de Oh My Posh (Usando tema Amro por defecto)
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "`$env:POSH_THEMES_PATH\amro.omp.json" | Invoke-Expression
}

# Iconos de Terminal
if (Get-Module -ListAvailable Terminal-Icons) {
    Import-Module Terminal-Icons
}
"@

Set-Content -Path $PROFILE -Value $profileContent

Write-Host "`n[!] PROCESO COMPLETADO." -ForegroundColor Green
Write-Host "Para verificar los temas instalados, escribe: Get-ChildItem `$env:POSH_THEMES_PATH" -ForegroundColor Yellow