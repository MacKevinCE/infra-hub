# infra-hub v1.4.0 — TUI para b2c, gsync y jcloud

Interfaz de consola interactiva (TUI) que centraliza el acceso a las tres herramientas del ecosistema de infraestructura personal. Navegación con flechas, formularios guiados, sin necesidad de recordar comandos ni flags.

## ¿Qué es infra-hub?

`hub` agrupa en un solo punto de entrada a:

- **[b2c](../bin2text-cloud/)** — almacenamiento binario en la nube
- **[gsync](../gsync/)** — sincronización de repositorios git entre máquinas
- **[jcloud](../jcloud/)** — gestión de documentos y canales en la nube
- **[seed](../seed/)** — distribución de binarios entre máquinas

No reemplaza a ninguna herramienta: las invoca como subprocesos y muestra el output en tiempo real. El objetivo es eliminar la necesidad de recordar subcomandos y flags.

## Requisitos

- macOS 13 (Ventura) o superior
- Swift 5.9 o superior (incluido con Xcode 15+)
- `b2c`, `gsync`, `jcloud` y `seed` instalados en el PATH

## Compilación

```bash
cd ~/Swift/infra-hub
swift build -c release
```

El binario queda en `.build/release/hub`.

## Instalación

`infra-hub` se instala como un shell script que ejecuta el binario compilado directamente. Solo compila si el binario no existe.

```bash
printf '#!/bin/bash\nBIN="$HOME/Swift/infra-hub/.build/release/hub"\n[ -x "$BIN" ] || (cd "$HOME/Swift/infra-hub" && swift build -c release >&2)\n"$BIN" "$@"\n' > /usr/local/bin/hub
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
  infra-hub v1.4.0
────────────────────────────────────────
  ▶ b2c    - blob store
    gsync  - git sync
    jcloud - document cloud

    doctor - check tools and config

    Quit

  ↑/↓ navigate   Enter select   q/ESC back
```

Navegá con ↑/↓, seleccioná con Enter, volvé con `q`, ESC o seleccionando "Back".

### b2c

| Opción | Descripción |
|--------|-------------|
| upload | Subir archivo o directorio. Pide el path y tamaño de chunk opcional. |
| download | Bajar por Index ID. Vacío = usa el canal configurado. |
| list | Ver historial local de uploads. |
| info | Ver metadatos del índice (nombre, partes, encriptación, checksum). |
| delete | Eliminar el índice y todos los chunks asociados (cascade delete). |

### gsync

| Opcion | Descripcion |
|--------|-------------|
| init | Wizard de configuracion inicial (sync point + canal). |
| push | Enviar commits al canal. Acepta rango opcional (ej. `HEAD~3..HEAD`). |
| pull | Recibir commits. Con ID o desde el canal. |
| mark | Setear el punto de sincronizacion (`HEAD` o hash). |
| check | Verificar canal por actualizaciones pendientes. |
| status | Subir manifiesto del estado actual del repo. Soporta `--local` para solo ver conteo. |
| snapshot | Comparar con manifiesto remoto y subir solo las diferencias. |
| diff | Previsualizar cambios sin aplicar. |
| sync | Bajar y aplicar el snapshot. Acepta mensaje de commit personalizado. |
| log | Mostrar historial de operaciones de sync. |
| ignore | Submenu: show, add (auto-detectar o patron), remove. |

### jcloud

| Opción | Descripción |
|--------|-------------|
| channel | Submenú: create, set, show, clear, slot-get, slot-set. |
| backup | Exportar datos del canal a archivo o stdout. |
| restore | Importar datos del canal desde archivo. |
| doc | Submenú: create, read, update, delete. |

Los submenús de jcloud agrupan operaciones relacionadas y muestran "Back" para volver al menú padre.

### seed

| Opción | Descripción |
|--------|-------------|
| publish | Publicar binarios al canal. |
| update | Descargar e instalar actualizaciones desde el canal. |
| replicate | Bootstrap completo para nueva máquina. |

## Estructura del proyecto

```
infra-hub/
├── Package.swift
├── README.md
└── Sources/
    └── hub/
        ├── main.swift              Punto de entrada, signal handlers, alternate screen
        ├── Version.swift           Versión del hub, findBinary() y binaryVersion()
        ├── GitInfo.swift           Información de git del repositorio actual
        ├── Terminal.swift          Modo raw (termios), ANSI, alternate screen buffer
        ├── Menu.swift              Menú navegable con closures, separadores y quit
        ├── Form.swift              Formulario secuencial de campos con validación
        ├── Runner.swift            Ejecución de binarios con streaming de stdout/stderr
        └── Screens/
            ├── DoctorScreen.swift  Diagnóstico de herramientas y configuración
            ├── MainScreen.swift    Menú principal
            ├── B2CScreen.swift     Pantallas de b2c
            ├── GsyncScreen.swift   Pantallas de gsync (con submenú ignore)
            ├── JcloudScreen.swift  Pantallas de jcloud (con submenús channel y doc)
            └── SeedScreen.swift   Pantallas de seed (publish, update, replicate)
```

### Arquitectura

- **Terminal** — gestión del modo raw vía `termios`, escape codes ANSI, alternate screen buffer (como vim/less: al salir, la terminal queda como estaba) y lectura de teclas (flechas via secuencias ESC).
- **Menu** — componente reutilizable. Items con closures de acción se ejecutan directo. Items sin acción y `isQuit` terminan el menú. Separadores agrupan visualmente y se saltan al navegar. Adapta al ancho del terminal y trunca con `…`.
- **Form** — formularios secuenciales. Alterna entre modo raw (navegación) y modo cooked (entrada de texto) por campo. Soporta campos opcionales y cancelación con `:q`.
- **Runner** — ejecuta los binarios como subprocesos con pipes para streaming de stdout/stderr en tiempo real. Muestra stderr en rojo y el exit code si es distinto de cero.
- **Screens** — orquestan Menu, Form y Runner. Usan `findBinary()` para localizar binarios dinámicamente vía `which` (fallback a `/usr/local/bin/`). Obtienen la versión del binario al iniciar para mostrarla en el título.

## Notas técnicas

### Alternate screen buffer

Al iniciar, hub cambia a un buffer de pantalla alternativo (`\e[?1049h`). Al salir, restaura el buffer original (`\e[?1049l`). Esto preserva el contenido previo de la terminal, igual que `vim` o `less`. Las secuencias de escape se envían antes de restaurar `termios` para evitar conflictos con prompts como Starship.

### Modo raw y `\r\n`

En `termios` raw mode, `\n` solo mueve el cursor hacia abajo sin retornar a columna 1. Todas las escrituras de línea usan `\r\n` para el comportamiento correcto en cualquier emulador de terminal.

### Búsqueda dinámica de binarios

`findBinary()` usa `which` para localizar `b2c`, `gsync` y `jcloud` en el PATH del usuario. Si `which` no encuentra el binario, usa `/usr/local/bin/<name>` como fallback.

## Limitaciones

- No tiene historial de entrada ni completado de texto dentro de los formularios.
- El wrapper agrega overhead en la primera compilación si el binario no existe.

## Licencia

Proyecto personal. Usar bajo tu propia responsabilidad.
