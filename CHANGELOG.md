# LocalFlow — Changelog

## v3.3 (2026-02-26)
- **Chat local**: nueva ventana de chat que responde preguntas sobre tus transcripciones usando Apple Intelligence (FoundationModels, macOS 15.1+). Recuperación semántica RAG con los embeddings existentes.
- **Fix spinner toolbar**: el contenedor/fondo redondeado del ToolbarItem ya no queda visible cuando el índice semántico termina de calcularse.
- **Versión centralizada**: `appVersion` es la única fuente de verdad para el número de versión mostrado en onboarding y ajustes.

## v3.2 (2026-02-26)
- **Color de interfaz elegible**: selector de color en el toolbar (rojo, azul, naranja, morado, verde, teal). Se aplica al pill de grabación, ondas, círculo de transcripción, chips de filtro y onboarding. Persiste entre sesiones.
- **Contraste adaptativo**: colores claros (naranja, verde, teal) usan texto oscuro automáticamente para cumplir WCAG.
- **Embeddings por frases (chunks)**: cada transcripción se divide en frases con `NLTokenizer` y se vectoriza por separado. La búsqueda semántica devuelve el registro con el chunk más relevante.
- **Fix Swift 6**: `var chunkVecs` capturado por closure `@Sendable` → copiado a `let builtVecs` antes de `await MainActor.run`.

## v3.1 (2026-02-25)
- **Fix búsqueda semántica vacía**: lógica híbrida — siempre evalúa keyword match además del score semántico. Cualquier registro con score > 0 aparece en resultados.
- **Toolbar limpio**: eliminado el contenedor visible alrededor del botón `?` (separados en ToolbarItems individuales en v3.2).
- **Más padding en Onboarding**: icono y versión con más separación de los bordes.
- **Overlay simplificado**: eliminados botones de pausa y stop del pill de grabación (solo waveform visible).

## v3.0 (2026-02-25)
- **Indicador de indexación**: spinner en el toolbar mientras los embeddings se calculan en background.
- **Versión en Onboarding**: texto `"LocalFlow v2.9"` en la pantalla de onboarding.
- **Botón `?` en toolbar**: reemplaza el icono de engranaje. Abre onboarding como sheet de ayuda.
- **Settings simplificado**: eliminada la sección "Atajo de teclado" (Globe hold-to-talk es el único modo).
- **Fix Swift 6 concurrencia**: `var index` → `let builtIndex` antes de `await MainActor.run` en el bloque de embedding de startup.

## v2.9 (2026-02-25)
- **Búsqueda semántica local**: reemplaza la búsqueda por keywords con vectorización on-device usando `NLEmbedding.sentenceEmbedding`. Índice en memoria, calculado en background al iniciar la app y tras cada transcripción.
- **EmbeddingEngine**: actor que gestiona el modelo de embeddings (caché por idioma, cosine similarity).
- **HistoryStore**: índice semántico `[UUID: [Float]]` (ampliado a `[[Float]]` en v3.2).

## v2.6 (anterior)
- Grabación con Globe (hold-to-talk)
- Transcripción local con WhisperKit (modelo Whisper tiny)
- Historial de transcripciones con agrupación por día
- Inyección de texto en la app activa (Accessibility API + clipboard fallback)
- Overlay flotante (pill con waveform animado → círculo transcribiendo)
- Panel de settings con selector de idioma
- Onboarding en primer arranque
- Barra de menú con icono de estado
