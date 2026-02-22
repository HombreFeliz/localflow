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
- **Limpieza de texto con IA local** — elimina muletillas, repeticiones y añade puntuación usando Ollama (opcional)
- **Vive en la barra de menú** — sin icono en el Dock, sin ventanas que estorben
- **Todo configurable desde el menú** — idioma, modo de grabación y limpieza de texto sin abrir ninguna ventana
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
git clone https://github.com/HombreFeliz/localflow.git
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

### El menú de la barra

Haz clic en el icono de onda de sonido en la barra de menú para ver todas las opciones:

```
✓ Mejorar texto con IA       ← activa/desactiva la limpieza con Ollama
  ● Ollama listo             ← verde si Ollama está corriendo
  ○ Ollama no detectado...   ← rojo con enlace a instrucciones si no está

─────────────────────────
  Idioma              ▶   ✓ Detectar automáticamente / Español / English / ...
  Modo de grabación   ▶   ✓ Mantener presionado / Alternar

─────────────────────────
  Salir de LocalFlow   ⌘Q
```

---

## Limpieza de texto con IA (opcional)

LocalFlow puede pasar el texto transcrito por un modelo de lenguaje local para eliminar muletillas, corregir puntuación y mejorar la redacción — todo sin conexión a internet.

### ¿Qué mejora?

- Elimina muletillas y rellenos ("o sea", "bueno", "pues", "eh", "a ver"...)
- Quita repeticiones y tartamudeos
- Añade puntuación y mayúsculas correctas
- Corrige errores obvios de transcripción usando el contexto
- Formatea automáticamente listas si el hablante enumera elementos

### Configuración (una sola vez)

**1. Instalar Ollama**

Descarga e instala Ollama desde [ollama.com](https://ollama.com) — es una app gratuita, arrástrala a `/Applications`.

**2. Descargar el modelo de IA**

Abre Terminal y ejecuta:
```bash
ollama pull llama3.2:1b
```

Esto descarga el modelo Llama 3.2 1B (~1.3 GB). Solo se hace una vez.

**3. Activar en LocalFlow**

Haz clic en el icono de LocalFlow en la barra de menú → activa **"Mejorar texto con IA"**.

Verás un indicador verde "● Ollama listo" cuando todo esté funcionando.

### Degradación elegante

| Situación | Comportamiento |
|-----------|----------------|
| Ollama activo y modelo descargado | Limpieza completa |
| Ollama no está abierto | Texto sin limpiar (sin error, sin bloqueo) |
| Tarda más de 10 segundos | Texto sin limpiar (sin espera) |
| Limpieza desactivada | Comportamiento original |

> 💡 Si ves "○ Ollama no detectado", asegúrate de que la app Ollama esté abierta. Puedes abrirla desde Finder o ejecutar `ollama serve` en Terminal.

---

## Compatibilidad de apps

| App | Funciona |
|-----|----------|
| Safari, Mail, Notas, Pages | ✅ Directo |
| Terminal, Xcode | ✅ Directo |
| Microsoft Word, Excel | ✅ Directo |
| VS Code, Chrome, Slack, Discord | ⚠️ Activar "Usar portapapeles" en el menú |

Para apps Electron (VS Code, Chrome, Slack): haz clic en el menú de LocalFlow → activa la opción de portapapeles si el texto no aparece directamente.

---

## Solución de problemas

**El texto no aparece al transcribir**
→ Asegúrate de que LocalFlow tiene permiso de Accesibilidad: **Ajustes del Sistema → Privacidad y Seguridad → Accesibilidad**

**En VS Code o Chrome el texto no se inserta**
→ Abre el menú de LocalFlow y activa "Usar portapapeles (compatible con todas las apps)"

**La tecla Globe no funciona como hotkey**
→ Ve al menú de LocalFlow → Modo de grabación → prueba con un atajo personalizado como `Ctrl+Espacio`

**"Ollama no detectado" aunque lo tengo instalado**
→ Ollama debe estar abierto y corriendo. Ábrelo desde `/Applications/Ollama.app` o ejecuta `ollama serve` en Terminal. También verifica que hayas descargado el modelo con `ollama pull llama3.2:1b`.

**El modelo tarda mucho en cargar la primera vez**
→ Normal — Whisper Medium son 1.5 GB. Con una buena conexión tarda unos minutos. Solo ocurre una vez.

**La app no aparece en el Dock**
→ Es intencionado. LocalFlow vive en la barra de menú (arriba a la derecha). Busca el icono de onda de sonido.

---

## Tecnología

- **[WhisperKit](https://github.com/argmaxinc/WhisperKit)** — Implementación de Whisper optimizada para Apple Silicon con Core ML y Neural Engine
- **[KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)** — Gestión de atajos de teclado globales
- **[Ollama](https://ollama.com)** — Motor de LLMs locales para la limpieza de texto (opcional)
- **AVAudioEngine** — Captura de audio a 16kHz mono Float32
- **CGEventTap** — Detección de la tecla Globe/Fn
- **CGEvent.keyboardSetUnicodeString** — Inyección de texto sin pasar por el portapapeles
- **SwiftUI + NSPanel** — Interfaz flotante que no roba el foco

---

## Licencia

MIT — úsalo, modifícalo y compártelo libremente.
