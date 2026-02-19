function Install-OhMyPosh {
    $installDir = "$env:LOCALAPPDATA\Programs\oh-my-posh"
    $binPath = "$installDir\bin"
    $themesPath = "$installDir\themes"
    if (!(Test-Path $binPath)) { New-Item -ItemType Directory -Path $binPath -Force }
    if (!(Test-Path $themesPath)) { New-Item -ItemType Directory -Path $themesPath -Force }
    if (!(Test-Path "$binPath\oh-my-posh.exe")) {
        Write-Host "Re-descargando ejecutable..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.exe" -OutFile "$binPath\oh-my-posh.exe"
    }
    Write-Host "--- Descargando todos los temas oficiales ---" -ForegroundColor Cyan
    $themesUrl = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip"
    Invoke-WebRequest -Uri $themesUrl -OutFile "$themesPath\themes.zip"
    Expand-Archive -Path "$themesPath\themes.zip" -DestinationPath $themesPath -Force
    Remove-Item "$themesPath\themes.zip"
    [System.Environment]::SetEnvironmentVariable("POSH_THEMES_PATH", $themesPath, "User")
    $env:POSH_THEMES_PATH = $themesPath
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
}

function Remove-OhMyPosh {
    $installDir = "$env:LOCALAPPDATA\Programs\oh-my-posh"
    if (Test-Path $installDir) {
        Remove-Item $installDir -Recurse -Force
        Write-Host "Oh My Posh removido del directorio local." -ForegroundColor Yellow
    } else {
        Write-Host "No se encontró instalación local de Oh My Posh." -ForegroundColor Yellow
    }
}
