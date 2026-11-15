# Asistente de selección · Gemini / OpenAI

Script para **AutoHotkey v2 en Windows**. Consulta texto seleccionado con **Ctrl + clic izquierdo** y presenta la respuesta como texto flotante pequeño, sin fondo visible, sin ventana de chat y sin cambiar el foco.

La interfaz visual está dedicada a la configuración. Al minimizarla queda un pequeño icono **◇** para abrirla de nuevo; las consultas siguen funcionando.

## Primer inicio

1. Instala [AutoHotkey v2](https://www.autohotkey.com/).
2. Descarga `gemini.ahk` en una carpeta donde puedas guardar archivos y ejecútalo.
3. En **Conexión**, elige **Gemini** u **OpenAI**, introduce tu propia clave y revisa el modelo.
4. Pulsa **Guardar**. Puedes usar **Probar conexión** para validar la clave y el acceso al modelo mediante una consulta de metadatos, sin generar texto.
5. Usa **Probar respuesta** para enviar una petición mínima de generación y comprobar que llega texto. Esta prueba usa la API de generación y su cuota. No envía tu contexto ni tus instrucciones personales.
6. Minimiza la configuración con **−** en la esquina superior derecha o con el botón **Minimizar**. Haz clic en el icono **◇** para volver a abrirla.

Cada proveedor usa su propia clave y el acceso que tenga habilitado esa cuenta. La prueba de conexión consulta metadatos; las consultas de texto sí generan respuestas. La prueba no confirma la cuota de generación.

## Icono discreto y móvil

Al minimizar queda un pequeño **◇**, circular y semitransparente, sin texto. Por defecto aparece pegado al borde derecho de la pantalla. Al pasar el cursor por encima se vuelve más visible.

- **Clic:** abrir ajustes.
- **Arrastrar con el botón izquierdo:** moverlo a cualquier lugar, sin abrir los ajustes al soltar.
- **Clic derecho:** abrir ajustes.

La posición se guarda automáticamente y se conserva al minimizar de nuevo o reiniciar. El icono se mantiene dentro del área de trabajo de un monitor para que pueda recuperarse si cambia la disposición de pantallas. La posición del icono se guarda por separado de los cambios pendientes del formulario.

## Configuración

- **Conexión:** proveedor activo, claves independientes de Gemini y OpenAI, modelos editables, claves ocultas por defecto y prueba de clave/modelo sin generación de texto.
- **Respuesta:** tamaño de letra de 6 a 24 pt, ancho de 240 a 800, color con selector de Windows o código HEX, opacidad del 20 al 100 % y duración de 0 a 120 segundos. Con duración `0`, la respuesta permanece hasta ocultarla manualmente.
- **Vista previa:** muestra un texto de ejemplo durante tres segundos, sin llamar a ninguna API. Restablecer apariencia carga los valores predeterminados en el formulario; pulsa Guardar para aplicarlos.
- **Contextos:** biblioteca de textos con nombre, editor integrado, importación de varios `.txt` o `.md` y casillas para combinar sólo los que elijas.
- **Instrucciones:** pestaña independiente para editar las instrucciones generales del asistente.
- **Atajos:** recordatorio de controles. Se eligieron atajos de configuración diferentes a los del mostrador de teclas.

Puedes activar o desactivar la copia automática de la respuesta al portapapeles, el indicador `...` y el inicio con los ajustes minimizados.

Los valores iniciales mantienen la apariencia del script original: letra de **8 pt**, color **F2F2F2**, ancho **400**, fondo transparente y duración indefinida. Ajusta el color o la opacidad y usa Vista previa para adaptarlos al fondo de tu pantalla.

**Guardar** aplica y conserva los cambios. Minimizar conserva lo que hayas escrito en el formulario, pero no lo aplica. **Cerrar ajustes** descarta los cambios pendientes y deja el icono ◇; no cierra el programa. Usa **Salir** en la bandeja para terminarlo.

## Respuesta junto al cursor

Por defecto, la respuesta de **Ctrl + clic** sigue al mouse mientras está visible, con una pequeña separación para permitir seguir haciendo clic normalmente. Se mantiene dentro del área de trabajo del monitor por el que pasa el cursor.

En **Configuración → Respuesta**, desactiva **La respuesta sigue al cursor** y pulsa **Guardar** para dejarla fija, como en el comportamiento anterior: aparece donde estaba el mouse al recibirse la respuesta. Si ya hay una respuesta visible, desactivar el seguimiento la deja junto a la posición actual del cursor. La preferencia queda guardada.

**Ctrl + Espacio** oculta o recupera la respuesta respetando el modo elegido. La vista previa también permite comprobar el seguimiento. Al ocultar la respuesta o cerrar el programa se detiene el temporizador de movimiento.

## Crear, editar y combinar contextos

Abre **Configuración → Contextos**:

1. Pulsa **Nuevo**, escribe un nombre y añade el texto directamente en el editor.
2. También puedes usar **Importar...** para elegir varios archivos `.txt` o `.md` a la vez (Ctrl o Shift en el selector de archivos).
3. Selecciona un contexto de la lista para editarlo. Cambiar de selección conserva lo escrito en el borrador.
4. **Marca las casillas de los contextos que quieras utilizar**. Puedes combinar varios; se enviarán separados por nombre y en el orden de la lista. Los desmarcados y los que no tienen texto quedan excluidos.
5. Pulsa **Guardar** para aplicar y conservar los cambios. Las consultas posteriores usarán sólo los contextos activos guardados.

**Quitar de la lista** retira un contexto del borrador; pulsa Guardar para aplicar la retirada. **Cerrar ajustes** descarta los cambios pendientes. Minimizar conserva el borrador abierto, sin aplicarlo.

Las instrucciones generales están en la pestaña **Instrucciones**. El archivo de contexto de versiones anteriores se incorpora a la biblioteca para poder editarlo; se conserva su activación al inicio anterior. Vaciar y guardar la biblioteca no vuelve a importar ese archivo.

Los contextos se guardan dentro de `gemini-config.json`, excluido de Git. Sólo se envían al proveedor al consultar con Ctrl+clic. **Probar conexión** y **Probar respuesta** no envían tus contextos.

## Atajos

| Atajo | Acción |
|---|---|
| `Ctrl + clic izquierdo` | Consultar el texto seleccionado |
| `Ctrl + Espacio` | Ocultar / mostrar la última respuesta |
| `Ctrl + Alt + G` | Abrir configuración |
| `Ctrl + Alt + J` | Minimizar / expandir configuración |
| `Ctrl + Alt + F` | Abrir Contextos e importar uno o varios archivos |

Para conservar los contextos, sus textos y las casillas activas entre sesiones, pulsa **Guardar**. Los archivos importados se copian a la biblioteca; editar un contexto no modifica su archivo original. El antiguo `Ctrl + Alt + L` se reemplazó por `Ctrl + Alt + F` para no interferir con el bloqueo del mostrador de teclas.

Cuando estás escribiendo en la configuración, `Ctrl + clic` mantiene su función normal y no envía consultas. Las respuestas flotantes permiten hacer clic a través de ellas. La última respuesta se conserva únicamente durante la sesión.

## Archivos locales y claves

- `gemini.ahk`: código del programa, sin claves incrustadas.
- `gemini-config.json`: preferencias personales y biblioteca de contextos, con nombres, textos y estado activo/inactivo.
- `gemini-credentials.dat`: claves cifradas mediante **Windows DPAPI**, asociadas al usuario de Windows. No es un archivo portable de claves entre equipos o cuentas.
- También se admiten `GEMINI_API_KEY` y `OPENAI_API_KEY` como valores iniciales si no hay una clave guardada para ese proveedor.

El `.gitignore` excluye configuración personal, credenciales, archivos temporales y respaldos. Al distribuir el programa, cada persona introduce sus claves desde la interfaz.

## API y modelos

- Gemini utiliza [generateContent](https://ai.google.dev/api/generate-content), con `x-goog-api-key` y el modelo inicial `gemini-3.5-flash-lite`.
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


## Si la conexión falla

**Probar conexión** consulta los metadatos del modelo con tu clave (`GET`), sin enviar preguntas ni generar respuestas. Un resultado correcto confirma el acceso a esos metadatos; la cuota y la disponibilidad de generación se comprueban al consultar texto.

Las consultas normales siguen siendo asíncronas. El programa usa `VT_BOOL` explícito al abrir la conexión COM, permite hasta 120 segundos para recibir datos y aplica un límite total de 150 segundos. La prueba muestra el tiempo transcurrido y tiene un botón **Cancelar**.

- **Tiempo agotado / 0x80072EE2:** no se obtuvo respuesta a tiempo; por sí solo no confirma que la clave o el saldo sean incorrectos. Revisa conexión al servidor de la API, proxy/VPN o firewall.
- **HTTP 400/401:** revisa el mensaje del proveedor y la clave seleccionada.
- **HTTP 403:** revisa permisos, restricciones o disponibilidad regional.
- **HTTP 404:** revisa el identificador del modelo.
- **HTTP 429:** revisa los límites o la cuota del proveedor.
- **HTTP 5xx:** el proveedor devolvió un error temporal.

El diagnóstico conserva el código HTTP y un mensaje breve del proveedor, sin mostrar las claves. No cambia automáticamente el modelo ni la facturación.


### Conexión correcta, pero no llega texto

**Probar conexión** y **Probar respuesta** comprueban cosas distintas. La primera valida acceso al modelo; la segunda genera una respuesta breve sin enviar tu contexto. Los errores y el último estado de consulta permanecen en la parte inferior de Ajustes aunque el panel esté minimizado o cerrado. Las respuestas de Ctrl+clic siguen siendo texto flotante.

Un **HTTP 503** con un aviso de alta demanda indica saturación del modelo. Puedes elegir otro modelo disponible desde Conexión. El modelo inicial es `gemini-3.5-flash-lite`; no se cambia automáticamente a otro proveedor ni se envían tus preguntas a OpenAI cuando tienes Gemini seleccionado.
