param(
    [ValidateSet('PowerShell','OhMyPosh','TerminalIcons','Fonts','All','Menu')]
    [string]$Only = 'Menu'
)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Este script debe ejecutarse como Administrador." -ForegroundColor Red
    Write-Host "Abre PowerShell como Administrador y vuelve a ejecutar el script." -ForegroundColor Yellow
    exit 1
}

# ── PowerShell ────────────────────────────────────────────────────────────────
function Get-Winget {
    $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    # winget vive en el perfil del usuario real, no en el del admin
    $realUser = (Get-CimInstance Win32_ComputerSystem).UserName -replace '.*\\'
    $candidate = "C:\Users\$realUser\AppData\Local\Microsoft\WindowsApps\winget.exe"
    if (Test-Path $candidate) { return $candidate }
    return $null
}

function Install-PowerShell {
    $winget = Get-Winget
    if ($winget) {
        & $winget install --id Microsoft.PowerShell --source winget --silent --accept-package-agreements --accept-source-agreements
        Write-Host "PowerShell instalado. Reinicia la terminal si es necesario." -ForegroundColor Green
        return
    }
    # Fallback: descarga directa del instalador MSI desde GitHub
    Write-Host "winget no encontrado. Descargando instalador desde GitHub..." -ForegroundColor Cyan
    $msi = "$env:TEMP\PowerShell-latest.msi"
    $api = Invoke-RestMethod "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
    $asset = $api.assets | Where-Object { $_.name -match 'win-x64\.msi$' } | Select-Object -First 1
    if (-not $asset) { Write-Host "No se pudo obtener la URL del instalador." -ForegroundColor Red; return }
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $msi
    Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /quiet /norestart ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1" -Wait
    Remove-Item $msi -Force
    Write-Host "PowerShell instalado. Reinicia la terminal." -ForegroundColor Green
}

function Remove-PowerShell {
    $winget = Get-Winget
    if ($winget) {
        & $winget uninstall --id Microsoft.PowerShell --source winget --silent --accept-package-agreements --accept-source-agreements
        Write-Host "Desinstalación solicitada para PowerShell." -ForegroundColor Yellow
    } else {
        Write-Host "winget no disponible. Desinstala PowerShell desde Configuración > Aplicaciones." -ForegroundColor Yellow
    }
}

# ── Oh My Posh ────────────────────────────────────────────────────────────────
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
    $profileDir = Split-Path $PROFILE -Parent
    if (!(Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
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

# ── Terminal Icons ────────────────────────────────────────────────────────────
function Install-TerminalIcons {
    if (!(Get-Command Install-Module -ErrorAction SilentlyContinue)) {
        Write-Host "PowerShellGet no está disponible. No se puede instalar Terminal-Icons automáticamente." -ForegroundColor Yellow
        return
    }
    if (!(Get-Module -ListAvailable -Name Terminal-Icons)) {
        try { Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue } catch {}
        Install-Module Terminal-Icons -Scope CurrentUser -Force -AllowClobber -Repository PSGallery -Confirm:$false
    }
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
}

function Remove-TerminalIcons {
    if (Get-Module -ListAvailable -Name Terminal-Icons) {
        Uninstall-Module Terminal-Icons -AllVersions -Force -ErrorAction SilentlyContinue
        Write-Host "Terminal-Icons desinstalado." -ForegroundColor Yellow
    } else {
        Write-Host "Terminal-Icons no está instalado." -ForegroundColor Yellow
    }
}

# ── Fonts ─────────────────────────────────────────────────────────────────────
function Get-FontsSourcePath {
    $root = if ($PSScriptRoot) { $PSScriptRoot } else { $PWD.Path }
    Join-Path $root "fonts"
}

function Get-FontsDestPath {
    Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
}

function Test-FontsInstalled {
    $src = Get-FontsSourcePath
    $dst = Get-FontsDestPath
    if (!(Test-Path $src)) { return $false }
    if (!(Test-Path $dst)) { return $false }
    $files = Get-ChildItem -Path $src -File -Include *.ttf, *.otf -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        if (Test-Path (Join-Path $dst $f.Name)) { return $true }
    }
    return $false
}

function Install-Fonts {
    $src = Get-FontsSourcePath
    $dst = Get-FontsDestPath
    if (!(Test-Path $src)) {
        Write-Host "No se encontró carpeta de fuentes: $src" -ForegroundColor Yellow
        return
    }
    if (!(Test-Path $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }
    $reg = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    $files = Get-ChildItem -Path $src -File -Include *.ttf, *.otf -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        Copy-Item -Path $f.FullName -Destination (Join-Path $dst $f.Name) -Force
        $suffix = if ($f.Extension -ieq ".ttf") { " (TrueType)" } else { " (OpenType)" }
        $name = "$($f.BaseName)$suffix"
        New-ItemProperty -Path $reg -Name $name -Value $f.Name -PropertyType String -Force | Out-Null
    }
    Write-Host "Fuentes instaladas para el usuario actual." -ForegroundColor Green
}

function Remove-Fonts {
    $src = Get-FontsSourcePath
    $dst = Get-FontsDestPath
    $reg = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    if (!(Test-Path $src)) { return }
    $files = Get-ChildItem -Path $src -File -Include *.ttf, *.otf -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        $suffix = if ($f.Extension -ieq ".ttf") { " (TrueType)" } else { " (OpenType)" }
        $name = "$($f.BaseName)$suffix"
        Remove-ItemProperty -Path $reg -Name $name -ErrorAction SilentlyContinue
        $target = Join-Path $dst $f.Name
        if (Test-Path $target) { Remove-Item $target -Force -ErrorAction SilentlyContinue }
    }
    Write-Host "Fuentes removidas para el usuario actual." -ForegroundColor Yellow
}

# ── Tests ─────────────────────────────────────────────────────────────────────
function Test-PowerShellInstalled { [bool](Get-Command pwsh -ErrorAction SilentlyContinue) }
function Test-OhMyPoshInstalled {
    $local = Test-Path "$env:LOCALAPPDATA\Programs\oh-my-posh\bin\oh-my-posh.exe"
    $path = [bool](Get-Command oh-my-posh -ErrorAction SilentlyContinue)
    $local -or $path
}
function Test-TerminalIconsInstalled { [bool](Get-Module -ListAvailable -Name Terminal-Icons) }

# ── Menú ──────────────────────────────────────────────────────────────────────
function Show-Menu {
    while ($true) {
        $psStatus = if (Test-PowerShellInstalled) { "✓ instalado" } else { "✗ no instalado" }
        $ompStatus = if (Test-OhMyPoshInstalled) { "✓ instalado" } else { "✗ no instalado" }
        $tiStatus = if (Test-TerminalIconsInstalled) { "✓ instalado" } else { "✗ no instalado" }
        $fontsStatus = if (Test-FontsInstalled) { "✓ instalado" } else { "✗ no instalado" }
        Write-Host "Selecciona una opción:" -ForegroundColor Cyan
        Write-Host "[1] PowerShell - $psStatus"
        Write-Host "[2] Oh My Posh - $ompStatus"
        Write-Host "[3] Terminal Icons - $tiStatus"
        Write-Host "[4] Fuentes - $fontsStatus"
        Write-Host "[5] Todo"
        Write-Host "[0] Salir"
        $choice = Read-Host "Opción"
        switch ($choice) {
            '1' { return 'PowerShell' }
            '2' { return 'OhMyPosh' }
            '3' { return 'TerminalIcons' }
            '4' { return 'Fonts' }
            '5' { return 'All' }
            '0' { exit }
            default { Write-Host "Opción inválida" -ForegroundColor Yellow }
        }
    }
}

if ($Only -eq 'Menu') { $Only = Show-Menu }

function Prompt-Action {
    param([string]$name,[bool]$installed)
    if ($installed) {
        Write-Host "$name está instalado. Opciones:" -ForegroundColor Cyan
        Write-Host "[S] Saltar"
        Write-Host "[R] Remover"
        Write-Host "[I] Reinstalar"
        $ans = Read-Host "Selecciona S/R/I"
        switch ($ans.ToUpper()) {
            'S' { return 'skip' }
            'R' { return 'remove' }
            'I' { return 'reinstall' }
            default { return 'skip' }
        }
    } else {
        Write-Host "$name no está instalado. Opciones:" -ForegroundColor Cyan
        Write-Host "[I] Instalar"
        Write-Host "[0] Cancelar"
        $ans = Read-Host "Selecciona I/0"
        switch ($ans.ToUpper()) {
            'I' { return 'install' }
            default { return 'skip' }
        }
    }
}

function Handle-Step {
    param([string]$name,[scriptblock]$Install,[scriptblock]$Remove,[scriptblock]$Test)
    $installed = & $Test
    $action = Prompt-Action $name $installed
    switch ($action) {
        'skip'      { }
        'install'   { & $Install }
        'remove'    { & $Remove }
        'reinstall' { & $Remove; & $Install }
    }
}

switch ($Only) {
    'PowerShell'     { Handle-Step 'PowerShell' { Install-PowerShell } { Remove-PowerShell } { Test-PowerShellInstalled } }
    'OhMyPosh'       { Handle-Step 'Oh My Posh' { Install-OhMyPosh } { Remove-OhMyPosh } { Test-OhMyPoshInstalled } }
    'TerminalIcons'  { Handle-Step 'Terminal-Icons' { Install-TerminalIcons } { Remove-TerminalIcons } { Test-TerminalIconsInstalled } }
    'Fonts'          { Handle-Step 'Fuentes' { Install-Fonts } { Remove-Fonts } { Test-FontsInstalled } }
    'All'            {
        Handle-Step 'PowerShell' { Install-PowerShell } { Remove-PowerShell } { Test-PowerShellInstalled }
        Handle-Step 'Oh My Posh' { Install-OhMyPosh } { Remove-OhMyPosh } { Test-OhMyPoshInstalled }
        Handle-Step 'Terminal-Icons' { Install-TerminalIcons } { Remove-TerminalIcons } { Test-TerminalIconsInstalled }
        Handle-Step 'Fuentes' { Install-Fonts } { Remove-Fonts } { Test-FontsInstalled }
    }
}
