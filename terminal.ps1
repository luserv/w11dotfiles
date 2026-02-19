# 1. Elevar privilegios
param(
    [ValidateSet('PowerShell','OhMyPosh','TerminalIcons','Fonts','All','Menu')]
    [string]$Only = 'Menu'
)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $argsList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Only `"$Only`""
    Start-Process powershell -ArgumentList $argsList -Verb RunAs
    exit
}

. "$PSScriptRoot\scripts\powershell.ps1"
. "$PSScriptRoot\scripts\oh-my-posh.ps1"
. "$PSScriptRoot\scripts\terminal-icons.ps1"
. "$PSScriptRoot\scripts\fonts.ps1"

function Test-PowerShellInstalled { [bool](Get-Command pwsh -ErrorAction SilentlyContinue) }
function Test-OhMyPoshInstalled {
    $local = Test-Path "$env:LOCALAPPDATA\Programs\oh-my-posh\bin\oh-my-posh.exe"
    $path = [bool](Get-Command oh-my-posh -ErrorAction SilentlyContinue)
    $local -or $path
}
function Test-TerminalIconsInstalled { [bool](Get-Module -ListAvailable -Name Terminal-Icons) }

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
