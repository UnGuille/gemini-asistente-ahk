# Asistente de selección · Gemini / OpenAI

Script para **AutoHotkey v2 en Windows**. Consulta texto seleccionado con **Ctrl + clic izquierdo** y presenta la respuesta como texto flotante pequeño, sin fondo visible, sin ventana de chat y sin cambiar el foco.

La interfaz visual está dedicada a la configuración. Al minimizarla queda un pequeño icono **IA** para abrirla de nuevo; las consultas siguen funcionando.

## Primer inicio

1. Instala [AutoHotkey v2](https://www.autohotkey.com/).
2. Descarga `gemini.ahk` en una carpeta donde puedas guardar archivos y ejecútalo.
3. En **Conexión**, elige **Gemini** u **OpenAI**, introduce tu propia clave y revisa el modelo.
4. Pulsa **Guardar**. Puedes usar **Probar conexión** para enviar una petición breve al proveedor seleccionado.
5. Minimiza la configuración con **−** en la esquina superior derecha o con el botón **Minimizar**. Haz clic en el icono **IA** para volver a abrirla.

Cada proveedor usa su propia clave y el acceso que tenga habilitado esa cuenta. La prueba de conexión y las consultas realizan solicitudes a su API.

## Configuración

- **Conexión:** proveedor activo, claves independientes de Gemini y OpenAI, modelos editables, claves ocultas por defecto y prueba de conexión.
- **Respuesta:** tamaño de letra de 6 a 24 pt, ancho de 240 a 800, color con selector de Windows o código HEX, opacidad del 20 al 100 % y duración de 0 a 120 segundos. Con duración `0`, la respuesta permanece hasta ocultarla manualmente.
- **Vista previa:** muestra un texto de ejemplo durante tres segundos, sin llamar a ninguna API. Restablecer apariencia carga los valores predeterminados en el formulario; pulsa Guardar para aplicarlos.
- **Contexto:** archivo `.txt` o `.md` opcional, carga al iniciar e instrucciones editables para el asistente. El contexto se envía al proveedor elegido junto con la consulta.
- **Atajos:** recordatorio de controles. Se eligieron atajos de configuración diferentes a los del mostrador de teclas.

Puedes activar o desactivar la copia automática de la respuesta al portapapeles, el indicador `...` y el inicio con los ajustes minimizados.

Los valores iniciales mantienen la apariencia del script original: letra de **8 pt**, color **F2F2F2**, ancho **400**, fondo transparente y duración indefinida. Ajusta el color o la opacidad y usa Vista previa para adaptarlos al fondo de tu pantalla.

**Guardar** aplica y conserva los cambios. Minimizar conserva lo que hayas escrito en el formulario, pero no lo aplica. **Cerrar ajustes** descarta los cambios pendientes y deja el icono IA; no cierra el programa. Usa **Salir** en la bandeja para terminarlo.

## Atajos

| Atajo | Acción |
|---|---|
| `Ctrl + clic izquierdo` | Consultar el texto seleccionado |
| `Ctrl + Espacio` | Ocultar / mostrar la última respuesta |
| `Ctrl + Alt + G` | Abrir configuración |
| `Ctrl + Alt + J` | Minimizar / expandir configuración |
| `Ctrl + Alt + F` | Cargar un archivo de contexto para esta sesión |

Para conservar la ruta de contexto entre sesiones, guarda la configuración y activa su carga al iniciar. El antiguo `Ctrl + Alt + L` se reemplazó por `Ctrl + Alt + F` para no interferir con el bloqueo del mostrador de teclas.

Cuando estás escribiendo en la configuración, `Ctrl + clic` mantiene su función normal y no envía consultas. Las respuestas flotantes permiten hacer clic a través de ellas. La última respuesta se conserva únicamente durante la sesión.

## Archivos locales y claves

- `gemini.ahk`: código del programa, sin claves incrustadas.
- `gemini-config.json`: preferencias personales.
- `gemini-credentials.dat`: claves cifradas mediante **Windows DPAPI**, asociadas al usuario de Windows. No es un archivo portable de claves entre equipos o cuentas.
- También se admiten `GEMINI_API_KEY` y `OPENAI_API_KEY` como valores iniciales si no hay una clave guardada para ese proveedor.

El `.gitignore` excluye configuración personal, credenciales, archivos temporales y respaldos. Al distribuir el programa, cada persona introduce sus claves desde la interfaz.

## API y modelos

- Gemini utiliza [generateContent](https://ai.google.dev/api/generate-content), con `x-goog-api-key` y el modelo inicial `gemini-flash-latest`.
- OpenAI utiliza la [Responses API](https://developers.openai.com/api/reference/resources/responses/methods/create), con `Authorization: Bearer`, `store: false` y el modelo inicial [gpt-4.1-mini](https://developers.openai.com/api/docs/models/gpt-4.1-mini).

El nombre del modelo es editable. Los errores de conexión, autenticación o cuota se muestran brevemente sin volcar las claves ni la respuesta técnica completa.

## Actualizar este repositorio

Si tu copia de uso diario está en la carpeta superior:

```powershell
Copy-Item "..\gemini.ahk" ".\gemini.ahk" -Force
git add -- gemini.ahk README.md .gitignore
git diff --cached --stat
git commit -m "Actualizar configuración y funcionamiento del asistente"
git push
```
