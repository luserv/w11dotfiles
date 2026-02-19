function Install-PowerShell {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) { return }
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($winget) {
        winget install --id Microsoft.PowerShell --source winget --silent --accept-package-agreements --accept-source-agreements
        Write-Host "PowerShell instalado o en curso de instalación. Reinicia la terminal si es necesario." -ForegroundColor Green
    } else {
        Write-Host "winget no está disponible. Instala PowerShell manualmente desde GitHub." -ForegroundColor Yellow
    }
}

function Remove-PowerShell {
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($winget) {
        winget uninstall --id Microsoft.PowerShell --source winget --silent --accept-package-agreements --accept-source-agreements
        Write-Host "Desinstalación solicitada para PowerShell." -ForegroundColor Yellow
    } else {
        Write-Host "winget no está disponible para desinstalar PowerShell." -ForegroundColor Yellow
    }
}
