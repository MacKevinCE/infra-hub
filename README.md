# infra-hub v1.1.0 — TUI para b2c, gsync y jcloud

Interfaz de consola interactiva (TUI) que centraliza el acceso a las tres herramientas del ecosistema de infraestructura personal. Navegación con flechas, formularios guiados, sin necesidad de recordar comandos ni flags.

## ¿Qué es infra-hub?

`hub` agrupa en un solo punto de entrada a:

- **[b2c](../bin2text-cloud/)** — almacenamiento binario en la nube
- **[gsync](../gsync/)** — sincronización de repositorios git entre máquinas
- **[jcloud](../jcloud/)** — gestión de documentos y canales en la nube

No reemplaza a ninguna herramienta: las invoca como subprocesos y muestra el output en tiempo real. El objetivo es eliminar la necesidad de recordar subcomandos y flags.

## Requisitos

- macOS 13 (Ventura) o superior
- Swift 5.9 o superior (incluido con Xcode 15+)
- `b2c`, `gsync` y `jcloud` instalados en el PATH

## Compilación

```bash
cd ~/Swift/infra-hub
swift build -c release
```

El binario queda en `.build/release/hub`.

## Instalación

`infra-hub` se instala como un shell script que invoca `swift run`. Esto es necesario porque en macOS 14+ el kernel rechaza binarios Swift compilados fuera de Xcode (SIGKILL por firma inválida). El toolchain de Swift sí está firmado por Apple.

```bash
printf '#!/bin/bash\ncd "$HOME/Swift/infra-hub"\nexec swift run -c release hub "$@"\n' > /usr/local/bin/hub
chmod +x /usr/local/bin/hub
```

Verificar instalación:

```bash
hub
# Abre la interfaz TUI
```

## Uso

Ejecutar `hub` sin argumentos abre el menú principal:

```
  infra-hub v1.0.0
────────────────────────────────────────
  ▶ b2c    blob store
    gsync  git sync
    jcloud document cloud
    Quit

  ↑/↓ navigate   Enter select   q/ESC back
```

Navegá con ↑/↓, seleccioná con Enter, volvé con `q` o ESC.

### b2c

| Opción | Descripción |
|--------|-------------|
| upload | Subir archivo o directorio. Pide el path y tamaño de chunk opcional. |
| download | Bajar por Index ID. Vacío = usa el canal configurado. |
| delete | Eliminar el índice y todos los chunks asociados (cascade delete). |

### gsync

| Opción | Descripción |
|--------|-------------|
| push | Enviar commits al canal. Acepta rango opcional (ej. `HEAD~3..HEAD`). |
| pull | Recibir commits. Con ID o desde el canal. |
| mark | Setear el punto de sincronización (`HEAD` o hash). |
| status | Subir manifiesto del estado actual del repo. |
| snapshot | Comparar con manifiesto remoto y subir solo las diferencias. |
| sync | Bajar y aplicar el snapshot. |

### jcloud

| Opción | Descripción |
|--------|-------------|
| doc create | Crear documento (nombre + contenido). |
| doc read | Leer documento por ID. |
| doc update | Actualizar documento por ID. |
| doc delete | Eliminar documento por ID. |
| channel create | Crear canal nuevo. |
| channel set | Configurar canal existente. |
| channel show | Ver canal configurado. |
| channel clear | Limpiar configuración local. |
| channel slot-get | Obtener valor de un slot. |
| channel slot-set | Escribir valor en un slot. |
| publish | Publicar binarios al canal. |
| update | Descargar e instalar actualizaciones desde el canal. |

## Estructura del proyecto

```
infra-hub/
├── Package.swift
├── README.md
└── Sources/
    └── hub/
        ├── main.swift              Punto de entrada, signal handlers (SIGINT/SIGTERM)
        ├── Version.swift           Versión del hub y helper binaryVersion()
        ├── Terminal.swift          Modo raw (termios), ANSI, lectura de teclas
        ├── Menu.swift              Menú navegable con flechas, adaptativo al ancho
        ├── Form.swift              Formulario secuencial de campos con validación
        ├── Runner.swift            Ejecución de binarios con streaming de stdout/stderr
        └── Screens/
            ├── MainScreen.swift    Menú principal
            ├── B2CScreen.swift     Pantallas de b2c
            ├── GsyncScreen.swift   Pantallas de gsync
            └── JcloudScreen.swift  Pantallas de jcloud
```

### Arquitectura

- **Terminal** — gestión del modo raw vía `termios`, escape codes ANSI y lectura de teclas (flechas via secuencias ESC).
- **Menu** — componente reutilizable para menús con navegación por flechas. Adapta separadores e items al ancho real del terminal. Trunca hints con `…` en pantallas angostas.
- **Form** — componente reutilizable para formularios secuenciales. Alterna entre modo raw (navegación) y modo cooked (entrada de texto) por campo. Soporta campos opcionales y cancelación con `:q`.
- **Runner** — ejecuta los binarios como subprocesos con pipes para streaming de stdout/stderr en tiempo real. Muestra stderr en rojo y el exit code si es distinto de cero.
- **Screens** — orquestan Menu, Form y Runner para cada herramienta y subcomando. Obtienen la versión del binario al iniciar para mostrarla en el título.

## Notas técnicas

### Por qué usa `swift run` en lugar del binario directo

En macOS 14+, el kernel (taskgated) rechaza binarios Swift compilados fuera de Xcode con SIGKILL (`Code Signature Invalid`). El wrapper de shell invoca `swift run -c release`, que usa el toolchain de Apple (firmado) para ejecutar el paquete.

El binario se compila una vez y queda cacheado en `.build/release/`. Las ejecuciones siguientes son casi instantáneas si no hubo cambios en el código fuente.

### Modo raw y `\r\n`

En `termios` raw mode, `\n` solo mueve el cursor hacia abajo sin retornar a columna 1. Todas las escrituras de línea usan `\r\n` para el comportamiento correcto en cualquier emulador de terminal.

## Limitaciones

- Los paths de los binarios están hardcodeados a `/usr/local/bin/b2c`, `/usr/local/bin/gsync` y `/usr/local/bin/jcloud`.
- No tiene historial de entrada ni completado de texto dentro de los formularios.
- El wrapper agrega overhead en la primera ejecución si el código cambió desde el último build.

## Licencia

Proyecto personal. Usar bajo tu propia responsabilidad.
