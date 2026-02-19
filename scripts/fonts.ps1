function Get-FontsSourcePath {
    $root = Split-Path $PSScriptRoot -Parent
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
