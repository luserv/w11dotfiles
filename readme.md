# w11dotfiles

Configuración automatizada del entorno de terminal para Windows 11.

## Requisitos

- Windows 11
- PowerShell abierto **como Administrador**
- `winget` disponible (incluido por defecto en Windows 11)

## Instalación

1. Abre PowerShell como Administrador
2. Ejecuta:

```powershell
irm "https://raw.githubusercontent.com/luserv/w11dotfiles/main/terminal.ps1" | iex
```

## Componentes

| Componente | Descripción |
|---|---|
| **PowerShell** | Instala PowerShell 7+ via winget |
| **Oh My Posh** | Prompt personalizado con el tema `amro` por defecto. Incluye todos los temas oficiales |
| **Terminal Icons** | Iconos en el explorador de archivos de la terminal |
| **Fuentes** | Hack Nerd Font (Regular, Bold, Italic, Mono, Propo) |

## Uso

El script muestra un menú interactivo con el estado actual de cada componente:

```
Selecciona una opción:
[1] PowerShell - ✓ instalado
[2] Oh My Posh - ✗ no instalado
[3] Terminal Icons - ✗ no instalado
[4] Fuentes - ✗ no instalado
[5] Todo
[0] Salir
```

Para cada componente se puede **instalar**, **remover** o **reinstalar**.
