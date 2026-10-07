# I-Hub: monetización con keys dinámicas (servicios gratis)

Guía paso a paso para distribuir **I-Hub / MM2 Farm** con:

- **Keys únicas** por usuario (no una key global).
- **HWID** (un dispositivo por key, en la medida de lo posible).
- **LootLabs o Linkvertise** para ganar por anuncios (sin montar tu propia web).
- **KeyAuth** (plan gratis para empezar) como servidor de licencias.

No necesitas Luarmor ni una página con AdSense. Sí necesitas **un servicio en la nube** que valide keys (KeyAuth); eso no es “tu web”, es su panel + API.

---

## Antes de empezar: qué vas a tener al final

| Pieza | Función |
|--------|---------|
| **LootLabs / Linkvertise** | El usuario pasa anuncios; tú cobras como publisher. |
| **Rentry / paste** | Página de texto gratis **después** del locker (instrucciones). |
| **KeyAuth** | Generas **muchas keys distintas**; el Loader comprueba cada una + HWID. |
| **Loader.lua** | Pide key → valida con KeyAuth → si OK, descarga y ejecuta el juego. |
| **Discord** | Canal `#get-script` con el link monetizado. |

**Importante:** si `MM2Farm.lua` sigue en GitHub **público** en `main`, cualquiera puede saltarse tu locker. Para monetizar de verdad, más adelante conviene repo **privado**, URL firmada o script detrás de validación. Esta guía asume que primero montas el flujo de keys; luego ajustas dónde vive el `.lua`.

---

## Parte 1 — Cuenta KeyAuth (keys dinámicas)

### Paso 1.1: Registro

1. Entra en [https://keyauth.cc](https://keyauth.cc).
2. Crea cuenta → inicia sesión.
3. Elige el plan **Tester / Free** (límite bajo de usuarios; sirve para probar).

### Paso 1.2: Crear aplicación ✅ (ya lo tienes)

Si ves **Current Application: i-Hub** y el código Lua con `name`, `ownerid`, `version`:

1. Esos tres valores deben coincidir con `env.lua` en el repo:
   - `name = "i-Hub"`
   - `ownerid = "XAJER0bAfC"` (el tuyo del panel)
   - `version = "1.0"`
2. No hace falta crear otra app salvo que quieras un segundo producto.

Documentación oficial del snippet: botón **View Example** en el mismo panel.

### Paso 1.3: Seguridad (HWID) — dónde está en KeyAuth

No hay un menú que diga literalmente “Seguridad”. Está en **Settings de la aplicación**:

1. Entra en [KeyAuth](https://keyauth.cc/app/) e inicia sesión.
2. Arriba debe decir **Current Application: i-Hub** (si no, en **Manage Apps** elige **i-Hub** → **Selected**).
3. Menú lateral → abre **Settings** (configuración de la app).  
   - Doc: [dashboard/app/settings](https://docs.keyauth.cc/dashboard/app/settings)  
   - Si no ves “Settings”, prueba el enlace directo (logueado):  
     `https://keyauth.cc/app/?page=app-settings`
4. En esa página activa:
   - **HWID Lock** → **Enabled** (la key se ata al primer dispositivo que la use).
   - **Force HWID** → **Enabled** (recomendado; rechaza HWID vacío).
5. Guarda cambios si hay botón **Save** / **Update**.
6. Opcional: más abajo, mensajes personalizados (`hwid mismatch`, etc.).

**Nota:** El **Seller key** solo sale en Settings (sección seller). No lo pegues en GitHub ni en el Loader; el Loader solo usa `name` + `ownerid` + `version`.

Si no encuentras Settings, manda captura del menú lateral con la app **i-Hub** seleccionada.

### Paso 1.4: Generar keys únicas (SIGUIENTE PASO AHORA)

1. Menú lateral → **Licenses** (no “Users”).
2. **Create license** / **Add license** (el botón puede variar).
3. Rellena:
   - **Amount** / cantidad: ej. `10` para pruebas.
   - **Duration** / expiración: ej. 7 días o lifetime.
   - **Level** / subscription: la que tengas por defecto (plan free suele traer una).
4. Confirma → copia las keys generadas a un bloc **privado** (Notepad, no canal público de Discord).
5. Prueba **una** key en Roblox:
   ```lua
   loadstring(game:HttpGet("https://raw.githubusercontent.com/ihubreal/iHub/refs/heads/main/Loader.lua"))()
   ```
   (o `readfile` local si aún no subiste `Loader.lua` + `env.lua` + `auth/keyauth.lua`).

6. En el Loader: pega key → **Verify key** → debe decir **License OK** y cargar el juego.

Cada fila en **Licenses** = una key distinta (dinámico para repartir).

Cada key es **dinámica en el sentido de negocio**: un usuario = una key. No es una sola contraseña para todos.

### Paso 1.5: Cómo funciona la API (para el Loader)

El cliente (tu Loader) hace dos pasos contra `https://keyauth.win/api/1.3/` (la versión puede cambiar; mira la doc oficial):

1. **`type=init`** — abre sesión (`sessionid`).
2. **`type=license`** — envía `key` + `hwid` + `sessionid`.

Si `success == true`, el usuario puede usar el hub. Si no, muestras el `message` y paras.

Obtener HWID en executor (ejemplo genérico; depende del exploit):

```lua
local hwid = "unknown"
if type(gethwid) == "function" then
	hwid = gethwid()
elseif type(getsynapsehwid) == "function" then
	hwid = getsynapsehwid()
end
```

Consulta siempre la documentación actual de KeyAuth para Roblox/Lua en su web.

---

## Parte 2 — LootLabs o Linkvertise (dinero por anuncios)

### Paso 2.1: Elegir uno

- **LootLabs** — muy usado en scripts de Roblox.
- **Linkvertise** — alternativa clásica.

Con uno basta al principio.

### Paso 2.2: Cuenta publisher

1. Regístrate como **creator / publisher** (no como usuario que “desbloquea”).
2. Completa el perfil si lo piden.

### Paso 2.3: Contenido del destino (Rentry)

1. Abre [https://rentry.co](https://rentry.co) (sin cuenta).
2. Pega algo como:

```text
I-Hub MM2 Farm — acceso

1. Copia UNA key (cada key es de un solo dispositivo).
2. En Roblox, ejecuta el Loader de I-Hub.
3. Pega la key cuando te la pida.

KEY: (aquí NO pongas una key fija global en producción)

Loader:
loadstring(game:HttpGet("https://raw.githubusercontent.com/ihubreal/iHub/refs/heads/main/Loader.lua"))()

Soporte: (tu Discord)
```

3. Guarda → te dan URL tipo `https://rentry.co/xxxxx`.

**En producción** no dejes una key fija en Rentry. Usa una de las opciones del **Parte 4** (asignar keys tras el locker).

### Paso 2.4: Crear link monetizado

**Linkvertise (idea general):**

1. Dashboard → **Create link** / monetize.
2. **Destination URL** = tu Rentry (`https://rentry.co/xxxxx`).
3. Copia el link corto que te dan.

**LootLabs:**

1. Crea un **content locker** o link monetizado apuntando al mismo Rentry.
2. Copia el enlace para usuarios.

Ese enlace es el **único** que publicas en Discord (no el Rentry crudo si puedes evitarlo).

---

## Parte 3 — Discord (distribución gratis)

### Paso 3.1: Servidor

1. Crea servidor **I-Hub** (o usa uno existente).
2. Canales sugeridos:
   - `#anuncios` — solo tú escribes.
   - `#get-script` — link de LootLabs/Linkvertise **fijado**.
   - `#soporte` — dudas.
   - `#keys` — **no** pegues keys aquí en público.

### Paso 3.2: Mensaje fijado en `#get-script`

Ejemplo:

```text
MM2 Farm (I-Hub)

1. Abre el enlace de abajo y completa el paso (anuncio/espera).
2. Sigue las instrucciones para obtener TU key.
3. Ejecuta el Loader y pega la key.

[LINK MONETIZADO AQUÍ]
```

---

## Parte 4 — Cómo repartir keys dinámicas tras el locker (elige un método)

### Método A — Manual (0 código extra, escala baja)

1. Generas 50 keys en KeyAuth.
2. Cuando alguien dice “ya pasé el locker”, le envías **una** key por ticket DM (bot o tú).
3. Marcas la key como usada en el panel.

**Pros:** gratis, simple. **Contras:** no escala.

### Método B — Pool en Rentry que rotas tú (semi-dinámico)

1. Tras cada lote de usuarios, **cambias** el Rentry y pones “pide key en ticket”.
2. No es dinámico automático; evita una key global eterna.

### Método C — Bot de Discord gratis (keys del pool)

1. Guardas keys en un archivo privado o base del bot.
2. Comando `/claim` tras verificar reacción → el bot entrega **una** key no usada.
3. Keys siguen siendo las de KeyAuth (únicas).

### Método D — Automático (keys sin pegar): Cloudflare Worker gratis

Si más adelante quieres: usuario completa locker → key nueva sin DM.

1. Cuenta en Cloudflare → **Workers** (plan free).
2. Worker con KV:
   - `GET /start?hwid=...` → devuelve `session_id` + URL de LootLabs con `session_id` en el destino.
   - `GET /unlock?session=...` (destino del locker) → genera UUID, guarda en KV ligado al hwid.
   - `GET /poll?session=...` → el Loader pregunta hasta que haya key.
3. El Loader no muestra web; solo `HttpGet` a `*.workers.dev`.

Esto no es “tu página de marca”; es una API mínima. Detalle de código del Worker queda para otra guía si lo pides.

**Recomendación:** empieza con **Método A o C**; cuando tengas tráfico, **Método D**.

---

## Parte 5 — Integrar KeyAuth en `Loader.lua` (orden lógico)

Hoy tu Loader hace: UI Starlight → `fetch(games/...)` → ejecutar.

**Orden nuevo:**

```
1. Cargar Starlight (o UI mínima)
2. Pedir key al usuario (input / KeySystem)
3. init KeyAuth → license con key + hwid
4. Si falla → aviso y return
5. Si OK → fetch del juego como ahora
6. destroy loader → run hub
```

### Paso 5.1: Variables (ejemplo)

En el Loader, define (con **tus** valores del panel KeyAuth):

```lua
local KEYAUTH_NAME = "IHubMM2"      -- application name
local KEYAUTH_OWNERID = "TU_OWNER_ID"
local KEYAUTH_VERSION = "1.0"
```

### Paso 5.2: Función de validación (esquema)

Usa `HttpService:JSONDecode` y la URL base que indique la doc de KeyAuth (versión 1.3+).

```lua
local HttpService = game:GetService("HttpService")

local function keyauthLicense(key, hwid)
	-- 1) init → sessionid
	-- 2) license con key, hwid, sessionid
	-- 3) return success, message
end
```

No copies seller secret en el repo. Solo `name`, `ownerid`, `version` en cliente.

### Paso 5.3: Starlight KeySystem (opcional)

Starlight `CreateWindow` admite `KeySystem = { Enabled = true, Keys = {...} }` para lista fija. Para **keys dinámicas de KeyAuth**, es mejor un **Input** propio o KeySystem que llame a tu función `keyauthLicense` en el callback, no una lista hardcodeada en el script.

### Paso 5.4: Probar

1. Genera **una** key de prueba en KeyAuth.
2. Ejecuta Loader en MM2.
3. Key correcta → debe cargar el farm.
4. Key incorrecta / segunda PC con misma key (si HWID on) → debe fallar.

---

## Parte 6 — Proteger el script (después del flujo)

| Nivel | Qué hacer |
|--------|-----------|
| Básico | Keys KeyAuth + HWID; farm aún en GitHub público (filtrable). |
| Medio | Repo **privado** o rama privada; Loader solo si KeyAuth OK. |
| Alto | Ofuscar Loader + no publicar farm en raw; Luarmor u ofuscador + KeyAuth. |

La monetización del locker **no** protege el código si el `.lua` está en `raw.githubusercontent.com/.../MM2Farm.lua` público.

---

## Parte 7 — Ingresos y expectativas

- Linkvertise/LootLabs pagan por completados; CPM bajo.
- Necesitas **volumen** (Shorts, TikTok, servidor grande).
- KeyAuth gratis tiene **límite de usuarios**; al crecer, plan de pago o Worker propio.
- Muchos hubs mezclan: **gratis con locker** + **premium** (key de pago sin anuncios).

---

## Checklist rápido

- [ ] Cuenta KeyAuth + app creada
- [ ] HWID activado
- [ ] Lote de keys generadas (cada una única)
- [ ] Cuenta LootLabs o Linkvertise
- [ ] Rentry con instrucciones (sin key global fija)
- [ ] Link monetizado → Rentry
- [ ] Discord `#get-script` con link fijado
- [ ] Loader valida KeyAuth antes de `fetch`
- [ ] Prueba con 1 key real
- [ ] Plan para no dejar el farm en público cuando monetices en serio

---

## Enlaces útiles

- KeyAuth: [https://keyauth.cc](https://keyauth.cc) (documentación en su web)
- Rentry: [https://rentry.co](https://rentry.co)
- LootLabs: [https://lootlabs.com](https://lootlabs.com)
- Linkvertise: [https://linkvertise.com](https://linkvertise.com)
- Cloudflare Workers (opcional, automático): [https://workers.cloudflare.com](https://workers.cloudflare.com)

---

## Integración en este repo (ya hecha)

| Archivo | Uso |
|---------|-----|
| `env.lua` | `keyauth.enabled`, `name`, `ownerid`, `version` (como en el panel KeyAuth). |
| `env.example.lua` | Plantilla sin tus IDs. |
| `auth/keyauth.lua` | `init` + `license` + HWID. |
| `Loader.lua` | Input **Verify key** → luego descarga el juego. |

Para desactivar KeyAuth en pruebas locales: en `env.lua` pon `enabled = false`.

Sube a GitHub `env.lua`, `auth/keyauth.lua` y `Loader.lua` para que el Loader remoto valide keys.
