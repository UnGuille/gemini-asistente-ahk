#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
DetectHiddenWindows true
CoordMode "Mouse", "Screen"
; Las claves se guardan cifradas con Windows DPAPI, fuera del codigo.
global RutaConfig := A_ScriptDir "\gemini-config.json", RutaClaves := A_ScriptDir "\gemini-credentials.dat"
global Cfg := CargarConfiguracion(), Claves := CargarClaves(), DocContexto := ""
global GuiAjustes := 0, Campos := 0, GuiIcono := 0, GuiRespuesta := 0
global RespuestaVisible := false, UltimaRespuesta := "", UltimaX := 0, UltimaY := 0
global Solicitud := 0, Cerrando := false, ColoresElegidos := Buffer(64, 0)
global RespuestaSigueMouse := false, RespuestaEsFinal := false
global CursorRespuestaX := "", CursorRespuestaY := ""
global UltimoEstado := "Listo. Selecciona un proveedor y guarda tus preferencias."
OnExit(CerrarPrograma)
ConfigurarBandejaGemini()
if (Cfg["RecordarContexto"] && Cfg["Contexto"] != "" && FileExist(Cfg["Contexto"])) {
    try DocContexto := FileRead(Cfg["Contexto"], "UTF-8")
}
CrearIconoGemini()
if (!FileExist(RutaConfig) || !Cfg["IniciarMinimizado"])
    AbrirConfiguracion()
else
    MostrarIconoGemini()

#HotIf !ConfiguracionActiva()
^LButton::ConsultarSeleccion()
#HotIf
^Space::AlternarRespuesta()
^!g::AbrirConfiguracion()
^!j::AlternarConfiguracion()
^!f::SeleccionarContexto()

ConfiguracionActiva() {
    global GuiAjustes, Cerrando
    return IsSet(Cerrando) && !Cerrando && IsSet(GuiAjustes) && IsObject(GuiAjustes) && WinActive("ahk_id " GuiAjustes.Hwnd)
}
Predeterminados() {
    instrucciones := "Eres un asistente experto. Identifica el tipo de pregunta y responde de forma breve y precisa."
    instrucciones .= "`n1. Opcion multiple con incisos: responde solo con el inciso correcto."
    instrucciones .= "`n2. Verdadero o falso: responde solo V o F."
    instrucciones .= "`n3. Relacionar columnas: responde las parejas correctas, una por linea."
    instrucciones .= "`n4. Pregunta abierta: responde de forma completa, breve y directa."
    return Map("Proveedor", "Gemini", "ModeloGemini", "gemini-3.5-flash-lite", "ModeloOpenAI", "gpt-4.1-mini",
        "Fuente", 8, "Ancho", 400, "Color", "F2F2F2", "Opacidad", 100, "Duracion", 0,
        "SeguirMouse", 1, "Copiar", 1, "Progreso", 1, "IniciarMinimizado", 1, "Contexto", "", "RecordarContexto", 0, "Instrucciones", instrucciones)
}
CargarConfiguracion() {
    global RutaConfig
    c := Predeterminados()
    if FileExist(RutaConfig) {
        try {
            leido := JsonLeer(FileRead(RutaConfig, "UTF-8"))
            for k, defecto in c
                if leido.Has(k) && !IsObject(leido[k])
                    c[k] := leido[k]
        }
    }
    for k, rango in Map("Fuente", [6,24], "Ancho", [240,800], "Opacidad", [20,100], "Duracion", [0,120]) {
        try c[k] := Max(rango[1], Min(rango[2], Integer(c[k])))
        catch
            c[k] := Predeterminados()[k]
    }
    for k in ["SeguirMouse", "Copiar", "Progreso", "IniciarMinimizado", "RecordarContexto"]
        c[k] := c[k] ? 1 : 0
    if (c["Proveedor"] != "Gemini" && c["Proveedor"] != "OpenAI")
        c["Proveedor"] := "Gemini"
    if !RegExMatch(c["Color"], "i)^[0-9a-f]{6}$")
        c["Color"] := "F2F2F2"
    for k in ["ModeloGemini", "ModeloOpenAI"]
        if !RegExMatch(c[k], "^[a-zA-Z0-9._-]+$")
            c[k] := Predeterminados()[k]
    return c
}
CargarClaves() {
    global RutaClaves
    claves := Map("Gemini", EnvGet("GEMINI_API_KEY"), "OpenAI", EnvGet("OPENAI_API_KEY"))
    if FileExist(RutaClaves) {
        try {
            f := FileOpen(RutaClaves, "r"), b := Buffer(f.Length, 0)
            f.RawRead(b, b.Size), f.Close()
            guardadas := JsonLeer(ProteccionWindows(b, false))
            for k in ["Gemini", "OpenAI"]
                if guardadas.Has(k) && guardadas[k] != ""
                    claves[k] := guardadas[k]
        }
    }
    return claves
}
ProteccionWindows(datos, cifrar := true) {
    if cifrar {
        b := Buffer(StrPut(datos, "UTF-8"), 0)
        StrPut(datos, b, "UTF-8")
        cantidad := b.Size - 1
    } else
        b := datos, cantidad := b.Size
    offset := A_PtrSize = 8 ? 8 : 4
    entrada := Buffer(A_PtrSize = 8 ? 16 : 8, 0), salida := Buffer(entrada.Size, 0)
    NumPut("uint", cantidad, entrada), NumPut("ptr", b.Ptr, entrada, offset)
    if cifrar
        ok := DllCall("Crypt32\CryptProtectData", "ptr", entrada, "str", "Gemini AHK", "ptr", 0, "ptr", 0, "ptr", 0, "uint", 1, "ptr", salida)
    else
        ok := DllCall("Crypt32\CryptUnprotectData", "ptr", entrada, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "uint", 1, "ptr", salida)
    if !ok
        throw Error("Windows no pudo acceder a las claves cifradas. Vuelve a introducirlas en Ajustes.")
    puntero := NumGet(salida, offset, "ptr"), largo := NumGet(salida, 0, "uint")
    try {
        if cifrar {
            resultado := Buffer(largo, 0)
            DllCall("RtlMoveMemory", "ptr", resultado, "ptr", puntero, "uptr", largo)
            return resultado
        }
        return StrGet(puntero, largo, "UTF-8")
    } finally {
        DllCall("LocalFree", "ptr", puntero)
    }
}
GuardarPreferencias(c, claves) {
    global RutaConfig, RutaClaves
    cifrado := ProteccionWindows(JsonEscribir(claves))
    archivo := FileOpen(RutaClaves ".tmp", "w")
    archivo.RawWrite(cifrado, cifrado.Size), archivo.Close()
    archivo := FileOpen(RutaConfig ".tmp", "w", "UTF-8-RAW")
    archivo.Write(JsonEscribir(c)), archivo.Close()
    FileMove(RutaClaves ".tmp", RutaClaves, 1), FileMove(RutaConfig ".tmp", RutaConfig, 1)
}
ConfigurarBandejaGemini() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Configuracion  (Ctrl+Alt+G)", (*) => AbrirConfiguracion())
    A_TrayMenu.Add("Minimizar / expandir ajustes  (Ctrl+Alt+J)", (*) => AlternarConfiguracion())
    A_TrayMenu.Add("Cargar contexto  (Ctrl+Alt+F)", (*) => SeleccionarContexto())
    A_TrayMenu.Add("Mostrar / ocultar respuesta  (Ctrl+Espacio)", (*) => AlternarRespuesta())
    A_TrayMenu.Add()
    A_TrayMenu.Add("Salir", (*) => ExitApp())
    A_TrayMenu.Default := "Configuracion  (Ctrl+Alt+G)"
    A_IconTip := "Gemini / OpenAI - asistente de seleccion"
}
CrearIconoGemini() {
    global GuiIcono
    GuiIcono := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000", "Abrir configuracion del asistente")
    GuiIcono.BackColor := "243247", GuiIcono.MarginX := 0, GuiIcono.MarginY := 0
    GuiIcono.SetFont("s14 bold cDBEAFE", "Segoe UI")
    GuiIcono.AddText("x0 y0 w40 h36 Center +0x200 +0x100", "IA").OnEvent("Click", (*) => AbrirConfiguracion())
    GuiIcono.OnEvent("ContextMenu", (*) => AbrirConfiguracion())
}
MostrarIconoGemini() {
    global GuiIcono, Cerrando
    if !IsSet(Cerrando) || Cerrando || !IsObject(GuiIcono)
        return
    MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
    x := Round(r - 56 * A_ScreenDPI / 96), y := Round(t + 16 * A_ScreenDPI / 96)
    GuiIcono.Show("x" x " y" y " w40 h36 NoActivate")
}
MinimizarConfiguracion(*) {
    global GuiAjustes, Cerrando
    if !IsSet(Cerrando) || Cerrando
        return
    if IsObject(GuiAjustes)
        GuiAjustes.Hide()
    MostrarIconoGemini()
}
AlternarConfiguracion() {
    global GuiAjustes
    if IsObject(GuiAjustes) && DllCall("IsWindowVisible", "ptr", GuiAjustes.Hwnd)
        MinimizarConfiguracion()
    else
        AbrirConfiguracion()
}

AbrirConfiguracion() {
    global GuiAjustes, Campos, GuiIcono, Cfg, Claves, Cerrando, UltimoEstado
    if !IsSet(Cerrando) || Cerrando
        return
    GuiIcono.Hide()
    if IsObject(GuiAjustes) {
        GuiAjustes.Show("Restore")
        return
    }
    g := Gui("+AlwaysOnTop +ToolWindow +MinimizeBox", "Configuracion · asistente Gemini / OpenAI")
    GuiAjustes := g
    g.BackColor := "F4F6FA", g.SetFont("s10", "Segoe UI")
    g.AddText("x24 y18 w500 h24", "ASISTENTE DE SELECCION")
    g.AddText("x24 y45 w510 h25", "Configura la conexion y la apariencia del texto flotante.")
    g.AddButton("x554 y17 w40 h30", "−").OnEvent("Click", MinimizarConfiguracion)
    tabs := g.AddTab3("x18 y86 w584 h464", ["Conexion", "Respuesta", "Contexto", "Atajos"])
    camposNuevos := Map()
    tabs.UseTab(1)
    g.AddText("x40 y127 w130 h24", "Proveedor activo")
    camposNuevos["Proveedor"] := g.AddDropDownList("x190 y123 w220", ["Gemini", "OpenAI"])
    camposNuevos["Proveedor"].Choose(Cfg["Proveedor"] = "Gemini" ? 1 : 2)
    g.AddText("x40 y169 w320 h22", "Clave API de Gemini")
    camposNuevos["ClaveGemini"] := g.AddEdit("x40 y195 w535 h26 Password", Claves["Gemini"])
    g.AddText("x40 y232 w130 h22", "Modelo Gemini")
    camposNuevos["ModeloGemini"] := g.AddEdit("x190 y228 w385 h26", Cfg["ModeloGemini"])
    g.AddText("x40 y275 w320 h22", "Clave API de OpenAI")
    camposNuevos["ClaveOpenAI"] := g.AddEdit("x40 y301 w535 h26 Password", Claves["OpenAI"])
    g.AddText("x40 y338 w130 h22", "Modelo OpenAI")
    camposNuevos["ModeloOpenAI"] := g.AddEdit("x190 y334 w385 h26", Cfg["ModeloOpenAI"])
    ver := g.AddCheckbox("x40 y375 w230 h24", "Mostrar claves")
    ver.OnEvent("Click", (*) => MostrarClavesFormulario(ver.Value))
    g.AddLink("x40 y413 w530 h24", '<a href="https://aistudio.google.com/apikey">Crear clave Gemini</a>     <a href="https://platform.openai.com/api-keys">Crear clave OpenAI</a>')
    g.AddButton("x40 y458 w150 h30", "Probar conexion").OnEvent("Click", (*) => ProbarConexion())
    g.AddButton("x208 y458 w110 h30", "Cancelar").OnEvent("Click", (*) => CancelarSolicitud())
    g.AddText("x332 y458 w243 h43", "Valida clave y modelo sin generar texto.")
    g.AddButton("x40 y500 w170 h28", "Probar respuesta").OnEvent("Click", (*) => ProbarRespuesta())
    g.AddText("x228 y500 w347 h35", "Las claves se guardan cifradas para tu usuario de Windows.")
    tabs.UseTab(2)
    g.AddText("x40 y130 w180 h24", "Tamano de letra (pt)")
    camposNuevos["Fuente"] := g.AddEdit("x250 y126 w90 Number", Cfg["Fuente"])
    g.AddUpDown("Range6-24", Cfg["Fuente"])
    g.AddText("x40 y174 w180 h24", "Ancho del texto")
    camposNuevos["Ancho"] := g.AddEdit("x250 y170 w90 Number", Cfg["Ancho"])
    g.AddUpDown("Range240-800", Cfg["Ancho"])
    g.AddText("x40 y218 w180 h24", "Color del texto (HEX)")
    camposNuevos["Color"] := g.AddEdit("x250 y214 w110 Limit7", Cfg["Color"])
    g.AddButton("x380 y213 w130 h27", "Elegir color...").OnEvent("Click", (*) => ElegirColorRespuesta())
    g.AddText("x40 y262 w180 h24", "Opacidad del texto")
    camposNuevos["Opacidad"] := g.AddSlider("x240 y252 w250 h34 Range20-100 ToolTip", Cfg["Opacidad"])
    camposNuevos["EtiquetaOpacidad"] := g.AddText("x500 y260 w72 h24", Cfg["Opacidad"] "%")
    camposNuevos["Opacidad"].OnEvent("Change", (*) => ActualizarOpacidadFormulario())
    g.AddText("x40 y309 w200 h24", "Ocultar despues de (seg)")
    camposNuevos["Duracion"] := g.AddEdit("x250 y305 w90 Number", Cfg["Duracion"])
    g.AddUpDown("Range0-120", Cfg["Duracion"])
    g.AddText("x360 y309 w215 h24", "0 = hasta Ctrl + Espacio")
    for k, spec in Map("SeguirMouse", [340,"La respuesta sigue al cursor"], "Copiar", [370,"Copiar respuesta al portapapeles"], "Progreso", [400,"Mostrar ... mientras consulta"], "IniciarMinimizado", [430,"Iniciar con los ajustes minimizados"]) {
        camposNuevos[k] := g.AddCheckbox("x40 y" spec[1] " w530 h26", spec[2])
        camposNuevos[k].Value := Cfg[k]
    }
    g.AddButton("x40 y472 w160 h30", "Vista previa").OnEvent("Click", (*) => VistaPreviaRespuesta())
    g.AddButton("x215 y472 w190 h30", "Restablecer apariencia").OnEvent("Click", (*) => RestablecerApariencia())
    tabs.UseTab(3)
    g.AddText("x40 y129 w535 h25", "Archivo de contexto opcional (.txt o .md)")
    camposNuevos["Contexto"] := g.AddEdit("x40 y160 w400 ReadOnly", Cfg["Contexto"])
    g.AddButton("x452 y158 w123 h28", "Examinar...").OnEvent("Click", (*) => SeleccionarContexto(true))
    camposNuevos["RecordarContexto"] := g.AddCheckbox("x40 y203 w535 h25", "Cargar este archivo al iniciar")
    camposNuevos["RecordarContexto"].Value := Cfg["RecordarContexto"]
    g.AddButton("x40 y240 w150 h28", "Quitar contexto").OnEvent("Click", (*) => QuitarContextoFormulario())
    g.AddText("x40 y285 w535 h25", "Instrucciones para el asistente")
    camposNuevos["Instrucciones"] := g.AddEdit("x40 y317 w535 h171 Multi WantTab", Cfg["Instrucciones"])
    g.AddText("x40 y501 w535 h34", "El contexto solo se envia al hacer una consulta.")
    tabs.UseTab(4)
    g.AddText("x42 y134 w520 h245", "Ctrl + clic izquierdo: consultar el texto seleccionado.`n`nCtrl + Espacio: ocultar o recuperar la ultima respuesta.`n`nCtrl + Alt + G: abrir configuracion.`n`nCtrl + Alt + J: minimizar / expandir ajustes.`n`nCtrl + Alt + F: cargar un archivo de contexto.")
    g.AddText("x42 y400 w520 h95", "Minimizar los ajustes deja un icono IA; la consulta sigue funcionando.`n`nLas respuestas no abren esta ventana y no reciben el foco. Los atajos evitan los del mostrador de teclas.")
    tabs.UseTab()
    camposNuevos["Estado"] := g.AddText("x24 y565 w570 h36", UltimoEstado)
    g.AddButton("x24 y609 w150 h32", "Minimizar").OnEvent("Click", MinimizarConfiguracion)
    g.AddButton("x340 y609 w126 h32 Default", "Guardar").OnEvent("Click", (*) => GuardarFormulario())
    g.AddButton("x478 y609 w116 h32", "Cerrar ajustes").OnEvent("Click", (*) => DescartarConfiguracion())
    Campos := camposNuevos
    g.OnEvent("Close", (*) => DescartarConfiguracion())
    g.OnEvent("Escape", MinimizarConfiguracion)
    g.OnEvent("Size", AlCambiarVentanaAjustes)
    g.Show("w620 h660")
}
AlCambiarVentanaAjustes(gui, estado, ancho, alto) {
    if estado = -1
        MinimizarConfiguracion()
}
DescartarConfiguracion() {
    global GuiAjustes, Campos, Cerrando
    if !IsSet(Cerrando) || Cerrando
        return
    GuiAjustes.Destroy(), GuiAjustes := 0, Campos := 0
    MostrarIconoGemini()
}
MostrarClavesFormulario(ver) {
    global Campos
    for k in ["ClaveGemini", "ClaveOpenAI"]
        Campos[k].Opt(ver ? "-Password" : "+Password")
}
ActualizarOpacidadFormulario() {
    global Campos
    Campos["EtiquetaOpacidad"].Text := Campos["Opacidad"].Value "%"
}
QuitarContextoFormulario() {
    global Campos
    Campos["Contexto"].Text := "", Campos["RecordarContexto"].Value := 0
}
SeleccionarContexto(formulario := false) {
    global DocContexto, Cfg, Campos
    ruta := FileSelect(1, , "Selecciona el contexto", "Texto (*.txt; *.md)")
    if ruta = ""
        return
    if formulario {
        Campos["Contexto"].Text := ruta
        EstadoAjustes("Contexto seleccionado. Pulsa Guardar para aplicarlo.")
        return
    }
    try DocContexto := FileRead(ruta, "UTF-8")
    catch {
        AvisoSutil("No se pudo abrir el archivo de contexto.")
        return
    }
    Cfg["Contexto"] := ruta
    if IsObject(Campos)
        Campos["Contexto"].Text := ruta
    AvisoSutil("Contexto cargado.")
}
LeerFormulario() {
    global Campos
    c := Map(), c["Proveedor"] := Campos["Proveedor"].Text
    for k in ["ModeloGemini", "ModeloOpenAI", "Contexto", "Instrucciones"]
        c[k] := Trim(Campos[k].Text)
    for k in ["ModeloGemini", "ModeloOpenAI"]
        if !RegExMatch(c[k], "^[a-zA-Z0-9._-]+$")
            throw Error("Revisa el nombre del modelo: " k)
    for k, rango in Map("Fuente", [6,24], "Ancho", [240,800], "Duracion", [0,120]) {
        valor := Campos[k].Text
        if !RegExMatch(valor, "^\d+$") || Integer(valor) < rango[1] || Integer(valor) > rango[2]
            throw Error(k ": usa un valor entre " rango[1] " y " rango[2] ".")
        c[k] := Integer(valor)
    }
    c["Color"] := StrUpper(LTrim(Trim(Campos["Color"].Text), "#"))
    if !RegExMatch(c["Color"], "^[0-9A-F]{6}$")
        throw Error("El color debe tener seis caracteres HEX, por ejemplo F2F2F2.")
    c["Opacidad"] := Campos["Opacidad"].Value
    for k in ["SeguirMouse", "Copiar", "Progreso", "IniciarMinimizado", "RecordarContexto"]
        c[k] := Campos[k].Value
    return c
}
ClavesFormulario() {
    global Campos
    return Map("Gemini", Trim(Campos["ClaveGemini"].Text), "OpenAI", Trim(Campos["ClaveOpenAI"].Text))
}
GuardarFormulario() {
    global Cfg, Claves, DocContexto
    try {
        c := LeerFormulario(), clavesNuevas := ClavesFormulario(), contexto := ""
        if c["Contexto"] != ""
            contexto := FileRead(c["Contexto"], "UTF-8")
        GuardarPreferencias(c, clavesNuevas)
        Cfg := c, Claves := clavesNuevas, DocContexto := contexto
        AplicarSeguimientoRespuesta()
        EstadoAjustes("Preferencias guardadas. Las respuestas siguen siendo texto flotante.")
    } catch as err {
        EstadoAjustes("No se guardo: " LimpiarError(err.Message))
    }
}
EstadoAjustes(texto) {
    global Campos, Cerrando, UltimoEstado
    if !IsSet(Cerrando) || Cerrando
        return
    UltimoEstado := texto
    if IsSet(Cerrando) && !Cerrando && IsSet(Campos) && IsObject(Campos)
        Campos["Estado"].Text := texto
}
RestablecerApariencia() {
    global Campos
    d := Predeterminados()
    for k in ["Fuente", "Ancho", "Color", "Duracion"]
        Campos[k].Text := d[k]
    for k in ["Opacidad", "SeguirMouse", "Copiar", "Progreso", "IniciarMinimizado"]
        Campos[k].Value := d[k]
    ActualizarOpacidadFormulario()
    EstadoAjustes("Apariencia predeterminada cargada. Pulsa Guardar para aplicarla.")
}
VistaPreviaRespuesta() {
    try {
        c := LeerFormulario(), MouseGetPos(&x, &y)
        MostrarTextoSutil("Vista previa de una respuesta breve.", x, y, 3000, c)
    } catch as err {
        EstadoAjustes(err.Message)
    }
}
ElegirColorRespuesta() {
    global Campos, GuiAjustes, ColoresElegidos
    color := LTrim(Trim(Campos["Color"].Text), "#")
    if !RegExMatch(color, "i)^[a-f0-9]{6}$")
        color := "F2F2F2"
    rgb := Integer("0x" color)
    bgr := ((rgb & 255) << 16) | (rgb & 0xFF00) | ((rgb >> 16) & 255)
    cc := Buffer(A_PtrSize = 8 ? 72 : 36, 0)
    NumPut("uint", cc.Size, cc), NumPut("ptr", GuiAjustes.Hwnd, cc, A_PtrSize = 8 ? 8 : 4)
    NumPut("uint", bgr, cc, A_PtrSize = 8 ? 24 : 12)
    NumPut("ptr", ColoresElegidos.Ptr, cc, A_PtrSize = 8 ? 32 : 16)
    NumPut("uint", 3, cc, A_PtrSize = 8 ? 40 : 20)
    if DllCall("Comdlg32\ChooseColorW", "ptr", cc) {
        rgb := NumGet(cc, A_PtrSize = 8 ? 24 : 12, "uint")
        Campos["Color"].Text := Format("{:02X}{:02X}{:02X}", rgb & 255, (rgb >> 8) & 255, (rgb >> 16) & 255)
    }
}

ConsultarSeleccion() {
    global Solicitud, Cfg, Claves, DocContexto
    if IsObject(Solicitud)
        return
    copia := ClipboardAll()
    try {
        A_Clipboard := "", Send("^c")
        if !ClipWait(1)
            throw Error("Selecciona primero el texto que quieres consultar.")
        pregunta := Trim(A_Clipboard)
        if pregunta = ""
            throw Error("La seleccion esta vacia.")
    } catch as err {
        AvisoSutil(err.Message)
        return
    } finally {
        A_Clipboard := copia
    }
    prompt := Cfg["Instrucciones"]
    if DocContexto != ""
        prompt .= "`n`nUsa preferentemente este contexto. Si no contiene la respuesta, usa tu conocimiento general.`n--- CONTEXTO ---`n" DocContexto
    prompt .= "`n`n--- PREGUNTA ---`n" pregunta
    IniciarSolicitud(prompt, Cfg, Claves, false)
}
ProbarConexion() {
    try {
        c := LeerFormulario()
        IniciarSolicitud("", c, ClavesFormulario(), true)
    } catch as err {
        EstadoAjustes(err.Message)
    }
}
ProbarRespuesta() {
    try {
        c := LeerFormulario()
        IniciarSolicitud("Responde unicamente OK.", c, ClavesFormulario(), false, true)
    } catch as err {
        EstadoAjustes(err.Message)
    }
}
IniciarSolicitud(prompt, c, claves, prueba := false, pruebaTexto := false) {
    global Solicitud
    if IsObject(Solicitud) {
        EstadoAjustes("Hay una consulta en curso. Espera a que termine.")
        return
    }
    proveedor := c["Proveedor"], clave := claves[proveedor]
    if clave = "" {
        if (prueba || pruebaTexto)
            EstadoAjustes("Introduce la clave API del proveedor seleccionado.")
        else
            AvisoSutil("Falta la clave API. Abre ajustes con Ctrl+Alt+G.")
        return
    }
    modelo := c[proveedor = "Gemini" ? "ModeloGemini" : "ModeloOpenAI"]
    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.SetTimeouts(10000, 15000, 30000, 120000)
        if proveedor = "Gemini" {
            url := "https://generativelanguage.googleapis.com/v1beta/models/" modelo ":generateContent"
            cuerpo := '{"contents":[{"parts":[{"text":' JsonTexto(prompt) '}]}]}'
        } else {
            url := "https://api.openai.com/v1/responses"
            cuerpo := '{"model":' JsonTexto(modelo) ',"input":' JsonTexto(prompt) ',"store":false}'
        }
        if prueba {
            url := proveedor = "Gemini"
                ? "https://generativelanguage.googleapis.com/v1beta/models/" modelo
                : "https://api.openai.com/v1/models/" modelo
        }
        ; VT_BOOL explicito para que el objeto COM abra siempre en modo asincrono.
        http.Open(prueba ? "GET" : "POST", url, ComValue(0xB, -1))
        http.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
        http.SetRequestHeader(proveedor = "Gemini" ? "x-goog-api-key" : "Authorization", proveedor = "Gemini" ? clave : "Bearer " clave)
        Solicitud := {http: http, proveedor: proveedor, prueba: prueba, inicio: A_TickCount,
            estilo: c.Clone(), clave: clave, ultimoEstado: -1, pruebaTexto: pruebaTexto}
        if prueba
            http.Send()
        else
            http.Send(cuerpo)
        SetTimer(RevisarSolicitud, 100)
        EstadoAjustes((prueba ? "Validando conexion con " : "Generando respuesta con ") proveedor "...")
        if (!prueba && !pruebaTexto && c["Progreso"])
            AvisoSutil("...", 5000)
    } catch as err {
        Solicitud := 0
        texto := DescribirErrorRed(err, clave)
        EstadoAjustes("No se pudo iniciar: " texto)
        if (!prueba && !pruebaTexto)
            AvisoSutil(texto)
    }
}
RevisarSolicitud() {
    global Solicitud, UltimaRespuesta, UltimaX, UltimaY, Cerrando
    if !IsSet(Cerrando) || Cerrando || !IsObject(Solicitud)
        return
    req := Solicitud
    try {
        segundos := Floor((A_TickCount - req.inicio) / 1000)
        if segundos >= 150 {
            req.http.Abort()
            throw Error("Sin respuesta de " req.proveedor " tras 150 s. Revisa la conexion a su API, proxy/VPN o firewall; todavia no se ha confirmado un problema de clave o cuota.")
        }
        ; Una espera de cero devuelve false mientras la respuesta sigue pendiente.
        if !req.http.WaitForResponse(0) {
            if segundos != req.ultimoEstado {
                req.ultimoEstado := segundos
                EstadoAjustes((req.prueba ? "Validando " : "Generando con ") req.proveedor "... " segundos " s. Puedes cancelar desde ajustes.")
            }
            return
        }
        status := req.http.Status
        if !status
            throw Error("No se recibio una respuesta HTTP del proveedor. Revisa la conexion, proxy/VPN o firewall.")
        datos := 0
        try datos := JsonLeer(req.http.ResponseText)
        if status < 200 || status >= 300 {
            mensaje := IsObject(datos) && datos.Has("error") && IsObject(datos["error"]) && datos["error"].Has("message") ? datos["error"]["message"] : "El proveedor rechazo la solicitud."
            throw Error(DescribirEstadoHTTP(status, mensaje))
        }
        if !IsObject(datos)
            throw Error("El proveedor respondio HTTP " status ", pero el contenido no es JSON valido.")
        if req.prueba {
            if (!datos.Has("name") && !datos.Has("id"))
                throw Error("El proveedor respondio, pero no devolvio los metadatos del modelo.")
            SetTimer(RevisarSolicitud, 0), Solicitud := 0
            EstadoAjustes("Clave y modelo confirmados con " req.proveedor ". La cuota de generacion se comprueba al consultar.")
            return
        }
        respuesta := ExtraerRespuesta(datos, req.proveedor)
        SetTimer(RevisarSolicitud, 0), Solicitud := 0
        if req.pruebaTexto {
            EstadoAjustes("Generacion correcta con " req.proveedor ": " SubStr(respuesta, 1, 100))
            return
        }
        UltimaRespuesta := respuesta
        EstadoAjustes("Respuesta recibida de " req.proveedor " (" StrLen(respuesta) " caracteres). Ctrl+Espacio para ocultar o recuperar.")
        MouseGetPos(&UltimaX, &UltimaY)
        if req.estilo["Copiar"]
            A_Clipboard := respuesta
        MostrarTextoSutil(respuesta, UltimaX, UltimaY, req.estilo["Duracion"] * 1000, req.estilo, true)
    } catch as err {
        SetTimer(RevisarSolicitud, 0), Solicitud := 0
        mensaje := DescribirErrorRed(err, req.clave)
        EstadoAjustes("Fallo de " req.proveedor ": " mensaje)
        if (!req.prueba && !req.pruebaTexto)
            AvisoSutil(mensaje, 6000)
    }
}
ExtraerRespuesta(datos, proveedor) {
    texto := ""
    if proveedor = "Gemini" {
        if !datos.Has("candidates") || datos["candidates"].Length = 0
            throw Error("Gemini no devolvio texto. Revisa el contenido o el modelo.")
        candidato := datos["candidates"][1]
        if candidato.Has("content") && candidato["content"].Has("parts")
            for parte in candidato["content"]["parts"]
                if parte.Has("text") && (!parte.Has("thought") || !parte["thought"])
                    texto .= parte["text"]
    } else if datos.Has("output") {
        for item in datos["output"]
            if item.Has("type") && item["type"] = "message" && item.Has("content")
                for parte in item["content"]
                    if parte.Has("type") && parte["type"] = "output_text" && parte.Has("text")
                        texto .= parte["text"]
    }
    texto := Trim(texto, " `t`n`r")
    if texto = ""
        throw Error("El proveedor no devolvio una respuesta de texto utilizable.")
    return texto
}
LimpiarError(texto, clave := "") {
    global Claves
    if clave != ""
        texto := StrReplace(texto, clave, "[clave oculta]")
    if IsSet(Claves)
        for k, valor in Claves
            if valor != ""
                texto := StrReplace(texto, valor, "[clave oculta]")
    return SubStr(texto, 1, 350)
}
MostrarTextoSutil(texto, x, y, duracion := 0, estilo := 0, esRespuesta := false) {
    global GuiRespuesta, RespuestaVisible, Cfg, Cerrando
    global RespuestaSigueMouse, RespuestaEsFinal, CursorRespuestaX, CursorRespuestaY
    if !IsSet(Cerrando) || Cerrando
        return
    OcultarRespuesta()
    if !IsObject(estilo)
        estilo := Cfg
    g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000020")
    GuiRespuesta := g
    g.BackColor := "010203"
    g.SetFont("s" estilo["Fuente"] " c" estilo["Color"], "Segoe UI")
    g.AddText("w" estilo["Ancho"] " BackgroundTrans", texto)
    WinSetTransColor("010203 " Round(255 * estilo["Opacidad"] / 100), g)
    g.Show("x" (x + 15) " y" (y + 10) " NoActivate")
    RespuestaVisible := true
    RespuestaEsFinal := esRespuesta
    RespuestaSigueMouse := estilo.Has("SeguirMouse") ? estilo["SeguirMouse"] : true
    CursorRespuestaX := "", CursorRespuestaY := ""
    if RespuestaSigueMouse {
        SeguirCursorRespuesta()
        SetTimer(SeguirCursorRespuesta, 16)
    } else
        PosicionarRespuesta(x, y)
    if duracion > 0
        SetTimer(OcultarRespuesta, -duracion)
}
AvisoSutil(texto, duracion := 3500) {
    MouseGetPos(&x, &y)
    MostrarTextoSutil(texto, x, y, duracion)
}
OcultarRespuesta() {
    global GuiRespuesta, RespuestaVisible, RespuestaSigueMouse, RespuestaEsFinal
    SetTimer(SeguirCursorRespuesta, 0)
    RespuestaSigueMouse := false, RespuestaEsFinal := false
    SetTimer(OcultarRespuesta, 0)
    if IsSet(GuiRespuesta) && IsObject(GuiRespuesta)
        GuiRespuesta.Destroy()
    GuiRespuesta := 0, RespuestaVisible := false
}
AlternarRespuesta() {
    global UltimaRespuesta, UltimaX, UltimaY, RespuestaVisible, Cfg
    if UltimaRespuesta = ""
        return
    if RespuestaVisible
        OcultarRespuesta()
    else
        MostrarTextoSutil(UltimaRespuesta, UltimaX, UltimaY, Cfg["Duracion"] * 1000, Cfg, true)
}
CerrarPrograma(*) {
    global Cerrando, Solicitud, GuiAjustes, GuiIcono
    Cerrando := true
    SetTimer(RevisarSolicitud, 0), SetTimer(OcultarRespuesta, 0)
    SetTimer(SeguirCursorRespuesta, 0)
    if IsObject(Solicitud) {
        try Solicitud.http.Abort()
    }
    Solicitud := 0
    OcultarRespuesta()
    if IsObject(GuiAjustes)
        GuiAjustes.Destroy()
    if IsObject(GuiIcono)
        GuiIcono.Destroy()
    GuiAjustes := 0, GuiIcono := 0
}
; JSON local: escapes, Unicode y estructuras anidadas sin librerias externas.
JsonTexto(texto) {
    salida := Chr(34)
    Loop Parse texto {
        ch := A_LoopField, n := Ord(ch)
        if (n = 34 || n = 92)
            salida .= Chr(92) ch
        else if n < 32
            salida .= Format("\u{:04X}", n)
        else
            salida .= ch
    }
    return salida Chr(34)
}
JsonEscribir(valor) {
    if valor is Map {
        s := "{", i := 0
        for k, v in valor
            s .= (i++ ? "," : "") JsonTexto(k) ":" JsonEscribir(v)
        return s "}"
    }
    if valor is Array {
        s := "["
        for i, v in valor
            s .= (i = 1 ? "" : ",") JsonEscribir(v)
        return s "]"
    }
    return (Type(valor) = "Integer" || Type(valor) = "Float") ? valor : JsonTexto(valor)
}
JsonLeer(texto) {
    lector := LectorJsonGemini(texto), valor := lector.Valor()
    lector.Espacios()
    if lector.pos <= StrLen(lector.s)
        throw Error("La respuesta JSON contiene datos adicionales.")
    return valor
}
class LectorJsonGemini {
    __New(texto) {
        this.s := texto, this.pos := 1
    }
    Espacios() {
        while (this.pos <= StrLen(this.s) && RegExMatch(SubStr(this.s, this.pos, 1), "\s"))
            this.pos++
    }
    Valor() {
        this.Espacios(), ch := SubStr(this.s, this.pos, 1)
        if ch = Chr(34)
            return this.Cadena()
        if ch = "{" {
            this.pos++, resultado := Map(), this.Espacios()
            if SubStr(this.s, this.pos, 1) = "}" {
                this.pos++
                return resultado
            }
            loop {
                this.Espacios(), clave := this.Cadena(), this.Espacios()
                if SubStr(this.s, this.pos++, 1) != ":"
                    throw Error("Objeto JSON no valido.")
                resultado[clave] := this.Valor(), this.Espacios()
                fin := SubStr(this.s, this.pos++, 1)
                if fin = "}"
                    return resultado
                if fin != ","
                    throw Error("Objeto JSON incompleto.")
            }
        }
        if ch = "[" {
            this.pos++, resultado := [], this.Espacios()
            if SubStr(this.s, this.pos, 1) = "]" {
                this.pos++
                return resultado
            }
            loop {
                resultado.Push(this.Valor()), this.Espacios()
                fin := SubStr(this.s, this.pos++, 1)
                if fin = "]"
                    return resultado
                if fin != ","
                    throw Error("Lista JSON incompleta.")
            }
        }
        for palabra, valor in Map("true", true, "false", false, "null", "")
            if SubStr(this.s, this.pos, StrLen(palabra)) = palabra {
                this.pos += StrLen(palabra)
                return valor
            }
        if RegExMatch(SubStr(this.s, this.pos), "^-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?", &m) {
            this.pos += StrLen(m[0])
            return Number(m[0])
        }
        throw Error("No se pudo interpretar la respuesta JSON.")
    }
    Cadena() {
        if SubStr(this.s, this.pos++, 1) != Chr(34)
            throw Error("Cadena JSON no valida.")
        resultado := ""
        while this.pos <= StrLen(this.s) {
            ch := SubStr(this.s, this.pos++, 1)
            if ch = Chr(34)
                return resultado
            if ch != Chr(92) {
                resultado .= ch
                continue
            }
            esc := SubStr(this.s, this.pos++, 1)
            switch esc {
                case Chr(34), Chr(92), "/": resultado .= esc
                case "n": resultado .= "`n"
                case "r": resultado .= "`r"
                case "t": resultado .= "`t"
                case "b": resultado .= Chr(8)
                case "f": resultado .= Chr(12)
                case "u":
                    digitos := SubStr(this.s, this.pos, 4)
                    if !RegExMatch(digitos, "i)^[a-f0-9]{4}$")
                        throw Error("Escape Unicode no valido.")
                    cp := Integer("0x" digitos), this.pos += 4
                    if (cp >= 0xD800 && cp <= 0xDBFF && SubStr(this.s, this.pos, 2) = Chr(92) "u") {
                        bajos := SubStr(this.s, this.pos + 2, 4)
                        if RegExMatch(bajos, "i)^[a-f0-9]{4}$") {
                            low := Integer("0x" bajos)
                            if (low >= 0xDC00 && low <= 0xDFFF) {
                                cp := 0x10000 + (cp - 0xD800) * 1024 + low - 0xDC00, this.pos += 6
                            }
                        }
                    }
                    resultado .= Chr(cp)
                default: throw Error("Escape JSON no valido.")
            }
        }
        throw Error("Cadena JSON sin cierre.")
    }
}


CancelarSolicitud() {
    global Solicitud
    if !IsObject(Solicitud)
        return
    req := Solicitud
    SetTimer(RevisarSolicitud, 0)
    Solicitud := 0
    try req.http.Abort()
    EstadoAjustes("Solicitud cancelada. Puedes revisar los ajustes y volver a probar.")
    if (!req.prueba && !req.pruebaTexto)
        AvisoSutil("Consulta cancelada.")
}

DescribirEstadoHTTP(status, mensaje) {
    switch status {
        case 400: causa := "Solicitud o clave no aceptada"
        case 401: causa := "Autenticacion no aceptada; revisa la clave del proveedor"
        case 402: causa := "El proveedor indica un requisito de facturacion"
        case 403: causa := "Acceso denegado; revisa permisos, restricciones de la clave o region"
        case 404: causa := "Modelo o recurso no disponible; revisa el nombre del modelo"
        case 429: causa := "Limite de solicitudes o cuota del proveedor alcanzado"
        case 500, 502, 503, 504: causa := "Error temporal del proveedor"
        default: causa := "Solicitud rechazada por el proveedor"
    }
    return "HTTP " status " - " causa ". " mensaje
}

DescribirErrorRed(err, clave := "") {
    numero := 0
    try numero := err.Number & 0xFFFF
    switch numero {
        case 12002: texto := "Tiempo de espera agotado (0x80072EE2). No se confirmo si la clave es valida. Revisa la conexion a la API, proxy/VPN o firewall."
        case 12007: texto := "No se pudo resolver el nombre del servidor. Revisa DNS y la conexion a Internet."
        case 12029, 12030, 12031: texto := "No se pudo conectar con la API o se interrumpio la conexion. Revisa red, proxy/VPN o firewall."
        case 12037, 12038, 12045, 12175: texto := "No se pudo establecer una conexion HTTPS segura. Revisa fecha/hora del equipo, certificados o inspeccion HTTPS de la red."
        default: texto := err.Message
    }
    return LimpiarError(texto, clave)
}


; Mover la misma ventana conserva el texto y evita parpadeos o cambios de foco.
SeguirCursorRespuesta() {
    global GuiRespuesta, RespuestaVisible, RespuestaSigueMouse, RespuestaEsFinal, Cerrando
    global CursorRespuestaX, CursorRespuestaY, UltimaX, UltimaY
    if (!IsSet(Cerrando) || Cerrando || !RespuestaVisible || !RespuestaSigueMouse || !IsObject(GuiRespuesta)) {
        SetTimer(SeguirCursorRespuesta, 0)
        return
    }
    punto := Buffer(8, 0)
    if !DllCall("GetCursorPos", "ptr", punto)
        return
    x := NumGet(punto, 0, "int"), y := NumGet(punto, 4, "int")
    if (x = CursorRespuestaX && y = CursorRespuestaY)
        return
    PosicionarRespuesta(x, y)
    CursorRespuestaX := x, CursorRespuestaY := y
    if RespuestaEsFinal
        UltimaX := x, UltimaY := y
}

PosicionarRespuesta(x, y) {
    global GuiRespuesta
    if !IsObject(GuiRespuesta)
        return
    rc := Buffer(16, 0)
    DllCall("GetWindowRect", "ptr", GuiRespuesta.Hwnd, "ptr", rc)
    w := NumGet(rc, 8, "int") - NumGet(rc, 0, "int")
    h := NumGet(rc, 12, "int") - NumGet(rc, 4, "int")
    punto := (x & 0xFFFFFFFF) | ((y & 0xFFFFFFFF) << 32)
    monitor := DllCall("MonitorFromPoint", "int64", punto, "uint", 2, "ptr")
    info := Buffer(40, 0)
    NumPut("uint", 40, info)
    nx := x + 15, ny := y + 10
    if DllCall("GetMonitorInfoW", "ptr", monitor, "ptr", info) {
        nx := Max(NumGet(info, 20, "int"), Min(nx, NumGet(info, 28, "int") - w))
        ny := Max(NumGet(info, 24, "int"), Min(ny, NumGet(info, 32, "int") - h))
    }
    DllCall("SetWindowPos", "ptr", GuiRespuesta.Hwnd, "ptr", 0, "int", nx, "int", ny,
        "int", 0, "int", 0, "uint", 0x15) ; NOSIZE | NOZORDER | NOACTIVATE
}

AplicarSeguimientoRespuesta() {
    global Cfg, RespuestaVisible, RespuestaSigueMouse, CursorRespuestaX, CursorRespuestaY
    global RespuestaEsFinal, UltimaX, UltimaY
    if !RespuestaVisible
        return
    RespuestaSigueMouse := Cfg["SeguirMouse"]
    SetTimer(SeguirCursorRespuesta, 0)
    if RespuestaSigueMouse {
        CursorRespuestaX := "", CursorRespuestaY := ""
        SeguirCursorRespuesta()
        SetTimer(SeguirCursorRespuesta, 16)
    } else if RespuestaEsFinal {
        ; Al desactivarlo, dejarla exactamente donde estaba el cursor.
        MouseGetPos(&UltimaX, &UltimaY)
        PosicionarRespuesta(UltimaX, UltimaY)
    }
}
