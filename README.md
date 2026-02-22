# LocalFlow

**Transcripción de voz a texto local para macOS — sin suscripción, sin servidores, 100% privado.**

Una alternativa open source a Wispr Flow que funciona completamente en tu Mac usando el modelo Whisper de OpenAI. Todo el procesamiento ocurre en tu máquina — tu voz nunca sale de tu ordenador.

![macOS](https://img.shields.io/badge/macOS-14.0+-black)
![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-M1%2FM2%2FM3%2FM4-blue)
![Swift](https://img.shields.io/badge/Swift-5.10-orange)
![Licencia](https://img.shields.io/badge/licencia-MIT-green)

---

## ¿Cómo funciona?

1. Tienes el cursor en cualquier app (un email, un chat, un documento...)
2. Mantienes pulsada la tecla **Globe/Fn** y hablas
3. Sueltas la tecla
4. El texto transcrito aparece donde estaba el cursor, como si lo hubieras escrito

Mientras grabas, aparece un pequeño panel flotante con las ondas de audio en tiempo real.

---

## Características

- **100% local** — usa [WhisperKit](https://github.com/argmaxinc/WhisperKit), optimizado para Apple Silicon
- **Multiidioma** — español, inglés, catalán, francés, alemán, portugués, italiano, japonés, chino y más (detección automática)
- **Dos modos de grabación** — mantener pulsado (push-to-talk) o alternar (pulsar una vez para empezar, otra para parar)
- **Hotkey configurable** — Globe/Fn por defecto, o elige tu propio atajo
- **Vive en la barra de menú** — sin icono en el Dock, sin ventanas que estorben
- **Compatible con todas las apps** — inyección directa de texto, con opción de fallback por portapapeles para apps como VS Code, Chrome o Slack
- **Sin cuenta, sin registro, sin internet** (tras la descarga inicial del modelo)

---

## Requisitos

| | |
|---|---|
| **Mac** | Apple Silicon (M1, M2, M3, M4) |
| **macOS** | 14.0 Sonoma o superior |
| **Xcode** | 16.0 o superior (para compilar) |
| **Espacio** | ~1.5 GB para el modelo Whisper Medium |
| **RAM** | 8 GB mínimo (recomendado 16 GB+) |

> ⚠️ No funciona en Macs con Intel. Whisper Medium requiere Apple Neural Engine.

---

## Instalación

### Paso 1 — Instalar Xcode

Descarga Xcode gratis desde la Mac App Store:
👉 [Xcode en la App Store](https://apps.apple.com/app/xcode/id497799835)

Es una descarga grande (~10 GB). Mientras se descarga, continúa con el paso 2.

### Paso 2 — Descargar LocalFlow

Haz clic en el botón verde **"Code"** de esta página → **"Download ZIP"**

O si tienes git instalado:
```bash
git clone https://github.com/TU_USUARIO/localflow.git
```

### Paso 3 — Abrir el proyecto

Abre el archivo `LocalFlow.xcodeproj` haciendo doble clic, o desde Terminal:
```bash
open "/ruta/a/LocalFlow/LocalFlow.xcodeproj"
```

Xcode abrirá el proyecto y empezará a descargar las dependencias automáticamente (WhisperKit y KeyboardShortcuts). Verás "Resolving package dependencies..." en la barra de estado — espera a que termine.

### Paso 4 — Compilar y ejecutar

1. En la barra superior de Xcode, asegúrate de que el esquema es **LocalFlow** y el destino es **My Mac**
2. Pulsa **▶** o `Cmd+R`
3. La primera vez que se ejecute, aparecerá una ventana descargando el **modelo Whisper Medium (~1.5 GB)**. Solo ocurre una vez — después se guarda en tu Mac.

### Paso 5 — Dar permisos

macOS pedirá dos permisos la primera vez:

- **Micrófono** — para grabar tu voz
- **Accesibilidad** — para insertar el texto en otras apps

Ve a **Ajustes del Sistema → Privacidad y Seguridad** y actívalos. Sin el permiso de Accesibilidad el texto no se puede insertar.

### Paso 6 (opcional) — Instalar como app permanente

Para no tener que abrir Xcode cada vez:

1. En Xcode: **Product → Show Build Products in Finder**
2. Copia `LocalFlow.app` a tu carpeta `/Applications`
3. La primera vez que lo abras desde Finder, haz **clic derecho → Abrir → Abrir** (macOS avisa porque la app no está firmada con una cuenta de desarrollador de pago)
4. Para que se abra automáticamente al encender el Mac: **Ajustes del Sistema → General → Elementos de inicio de sesión** → añade `LocalFlow.app`

---

## Uso

### Grabación (modo por defecto: mantener pulsado)

| Acción | Resultado |
|--------|-----------|
| Mantener **Globe/Fn** | Empieza a grabar |
| Soltar **Globe/Fn** | Para y transcribe |

### Grabación (modo alternar)

| Acción | Resultado |
|--------|-----------|
| Pulsar **Globe/Fn** | Empieza a grabar |
| Pulsar **Globe/Fn** de nuevo | Para y transcribe |

### Ajustes

Haz clic derecho en el icono de la barra de menú → **Ajustes...**

Desde ahí puedes cambiar:
- **Hotkey** — Globe/Fn o un atajo personalizado
- **Modo** — mantener pulsado o alternar
- **Idioma** — auto-detectar o fijar uno concreto
- **Inyección de texto** — directo (por defecto) o via portapapeles (para VS Code, Chrome, Slack)

---

## Compatibilidad de apps

| App | Funciona |
|-----|----------|
| Safari, Mail, Notas, Pages | ✅ Directo |
| Terminal, Xcode | ✅ Directo |
| Microsoft Word, Excel | ✅ Directo |
| VS Code, Chrome, Slack, Discord | ⚠️ Activar "Usar portapapeles" en Ajustes |

---

## Solución de problemas

**El texto no aparece al transcribir**
→ Asegúrate de que LocalFlow tiene permiso de Accesibilidad en Ajustes del Sistema → Privacidad y Seguridad → Accesibilidad

**En VS Code o Chrome el texto no se inserta**
→ Abre Ajustes de LocalFlow y activa "Usar portapapeles (compatible con todas las apps)"

**La tecla Globe no funciona como hotkey**
→ Ve a Ajustes → desactiva "Usar tecla Globe" → pon un atajo personalizado como `Ctrl+Espacio`

**El modelo tarda mucho en cargar la primera vez**
→ Normal — Whisper Medium son 1.5 GB. Con una buena conexión tarda unos minutos. Solo ocurre una vez.

**La app no aparece en el Dock**
→ Es intencionado. LocalFlow vive en la barra de menú (arriba a la derecha). Busca el icono de onda de sonido.

---

## Tecnología

- **[WhisperKit](https://github.com/argmaxinc/WhisperKit)** — Implementación de Whisper optimizada para Apple Silicon con Core ML y Neural Engine
- **[KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)** — Gestión de atajos de teclado globales
- **AVAudioEngine** — Captura de audio a 16kHz mono Float32
- **CGEventTap** — Detección de la tecla Globe/Fn
- **CGEvent.keyboardSetUnicodeString** — Inyección de texto sin pasar por el portapapeles
- **SwiftUI + NSPanel** — Interfaz flotante que no roba el foco

---

## Licencia

MIT — úsalo, modifícalo y compártelo libremente.
