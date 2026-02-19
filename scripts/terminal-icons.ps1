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
