# Bronson Composites — CRM & Automatización de Contenido

Sistema de CRM + automatización de leads + scheduler de contenido para Bronson Composites
(piezas custom en fiberglass y carbon fiber para Jeep).

## Resumen de decisiones (confirmadas contigo)

| Área | Decisión |
|---|---|
| Hosting | Railway (mismo lugar que TR4D3BOT) |
| CRM | Custom, sobre Postgres (no Airtable, no GoHighLevel) |
| Website / tienda | Shopify |
| DMs a leads detectados por comentarios | **Siempre con tu aprobación** — el bot nunca envía solo |
| Aprobación de contenido (3 videos/día) | WhatsApp Business API |
| Imágenes IA (mockups en carros de clientes) | Gemini (Nano Banana) |
| Edición de video | Template automático (n8n + servicio de edición) sobre tu raw footage |
| Reddit / Pinterest | Contenido orgánico, venta suave — nunca "se vende X a $Y" |
| Presupuesto mensual objetivo | ~$50-100 base + costo variable de WhatsApp Business API (ver abajo) |
| Cuentas existentes | IG, WhatsApp, Facebook, TikTok, eBay, YouTube — falta confirmar si son cuentas Business/Developer |

**Nota de presupuesto:** pediste WhatsApp Business API sí o sí. Eso tiene dos costos que no están
en el rango "bajo": (1) verificación de negocio en Meta (gratis, pero toma días) y (2) costo por
conversación iniciada (varía por país, típicamente $0.03–$0.10 USD por conversación en LATAM/US).
Con volumen bajo-moderado esto normalmente cae bajo $20-30/mes, pero avisa si el volumen de DMs
sube mucho. No hay forma de evitar este costo si WhatsApp API es un requisito duro.

---

## 1. Arquitectura general

```
┌─────────────────────────────────────────────────────────────────────┐
│                         RAILWAY (hosting)                            │
│  ┌──────────────┐   ┌──────────────────┐   ┌──────────────────────┐ │
│  │   n8n         │   │   Postgres CRM    │   │  (futuro) mini-API   │ │
│  │  (orquesta)   │──▶│   (leads, orders, │◀──│  para dashboard      │ │
│  │               │   │   content_queue)  │   │                      │ │
│  └──────┬────────┘   └──────────────────┘   └──────────────────────┘ │
└─────────┼──────────────────────────────────────────────────────────-─┘
          │
   ┌──────┴───────────────────────────────────────────────────────┐
   │                                                                │
   ▼                ▼              ▼             ▼            ▼    ▼
 Meta Graph API   TikTok API   Pinterest API  Reddit API   eBay API  Shopify API
 (IG/FB/WhatsApp)                                          Amazon(MWS/SP-API)*
                                                            Etsy API*

* Amazon y Etsy requieren aprobación de cuenta de vendedor antes de tener acceso API;
  hasta entonces se publican/gestionan manualmente y n8n solo lleva el registro en el CRM.
```

### Flujos principales (n8n)

1. **`comment-lead-detection`** — escucha comentarios en IG/FB/TikTok, detecta intención de
   compra/precio con keywords + un paso de clasificación por LLM, crea/actualiza el lead en
   Postgres, redacta un borrador de DM, y te lo manda a WhatsApp para aprobar antes de enviar.
2. **`whatsapp-approval-gate`** — workflow reusable: cualquier acción que salga hacia afuera
   (DM a un lead, publicar contenido) pasa por aquí. Te manda el mensaje/video a WhatsApp con
   botones "Aprobar" / "Editar" / "Rechazar". Nada se publica ni se envía sin tu aprobación
   mientras "nos vamos conociendo" (como pediste).
3. **`content-scheduler-publish`** — corre 3 veces al día (12:15, 5:15pm, 9:30pm hora PR) según
   tu horario real de grabación, revisa `content_queue`, arma el post (con o sin colaboración de
   MiniTrucks), pide tu aprobación por WhatsApp, y publica en las plataformas que correspondan
   según el tipo de contenido.
4. **`ai-vehicle-mockup`** — para clientes previos: toma la foto de su Jeep, genera con Gemini
   una versión con las piezas de Bronson instaladas, y la deja lista en el `content_queue` como
   contenido de remarketing (con tu aprobación antes de enviarse al cliente).
5. **`marketplace-sync`** (fase 2) — sincroniza inventario/pedidos entre Shopify ↔ eBay ↔
   Amazon ↔ Etsy una vez tengas las cuentas de vendedor confirmadas.

---

## 2. Horario de contenido (tal como lo describiste)

| Bloque | Horario | Qué generas tú | Qué hace el sistema |
|---|---|---|---|
| Turno 1 (raw) | 8:00–12:00 | Grabas videos/fotos (colab MiniTrucks) | — |
| Publicación 1 | 12:15 | — | Edita con template, te manda a WhatsApp a aprobar, publica al aprobar |
| Turno 2 (raw) | 13:00–17:00 | Grabas videos/fotos (colab MiniTrucks) | — |
| Publicación 2 | 17:15 | — | Edita, aprobación por WhatsApp, publica |
| Turno 3 (raw) | 18:00–21:00 | Grabas en Bronson HQ (sin colab) | — |
| Publicación 3 | 21:30 | — | Edita, aprobación por WhatsApp, publica |

Todo esto vive en `config/content-schedule.json` — se puede ajustar sin tocar los workflows.
El sistema decide **en qué plataformas** publicar cada pieza (IG/TikTok siempre; FB, Pinterest,
Reddit según el tipo de contenido) — configurable en el mismo archivo.

---

## 3. Reglas de venta (para que el bot nunca las rompa)

- **Nunca** publicar "se vende [pieza] a $[precio]" como post o caption.
- El contenido es de marca/proceso/instalación — la venta ocurre en DM, uno a uno.
- El bot **detecta** comentarios de intención de compra (keywords: precio, cuánto, disponible,
  cotización, interesado, "dm please", etc. + clasificación semántica) pero **nunca envía el DM
  solo**: siempre se te presenta el borrador por WhatsApp primero.
- Reddit/Pinterest: solo contenido de valor (builds, tips de instalación, behind-the-scenes).
  Nunca precios ni "cómpralo aquí" directo — el link al perfil/bio es el único CTA permitido.

---

## 4. Qué falta de tu lado antes de que esto funcione end-to-end

1. **Meta Business Suite**: confirmar que IG y FB están conectadas a una cuenta Business (no
   personal) — es requisito para la API de comentarios/DM y para WhatsApp Business API.
2. **WhatsApp Business API**: iniciar verificación de negocio en Meta (usamos el número que ya
   usas o uno nuevo dedicado a Bronson). Esto no es instantáneo — puede tomar días.
3. **TikTok for Developers**: crear app y solicitar acceso a Content Posting API + Comment API.
4. **Pinterest**: crear cuenta de negocio + app en Pinterest Developers.
5. **Reddit**: crear app en reddit.com/prefs/apps (tipo "script") para leer/postear con tu cuenta.
6. **eBay**: confirmar que la cuenta es de vendedor (Seller Hub) y crear app en eBay Developers
   Program.
7. **Amazon / Etsy**: estas requieren aprobación de cuenta de vendedor antes de dar acceso API —
   por ahora se gestionan manualmente, el CRM solo registra los pedidos que reportes.
8. **Shopify**: crear la tienda (o confirmar si ya existe) y generar un Custom App con API
   access token para que n8n pueda crear productos/pedidos.
9. **Gemini API key** (Google AI Studio) para los mockups de vehículos.
10. **Railway**: cuenta y proyecto nuevo (o el mismo de TR4D3BOT) para desplegar n8n + Postgres.

Todo esto va en `.env.example` — copia ese archivo a `.env` y rellena según vayas obteniendo
cada credencial. Nada bloquea a lo demás: el sistema arranca con lo que tengas y lo demás queda
desactivado hasta que agregues la credencial.

---

## 5. Estructura del repo

```
bronson-composites-crm/
├── README.md                     ← este archivo
├── .env.example                  ← todas las credenciales necesarias
├── mcp-config.json               ← MCPs recomendados para Claude Code
├── setup.sh                      ← bootstrap: crea todo, corre desde Claude Code
├── db/
│   └── schema.sql                ← esquema completo del CRM (Postgres)
├── n8n-workflows/
│   ├── comment-lead-detection.json
│   ├── whatsapp-approval-gate.json
│   ├── content-scheduler-publish.json
│   └── ai-vehicle-mockup.json
├── config/
│   └── content-schedule.json     ← horarios y reglas de publicación
├── content/                      ← (vacío) aquí caen tus raw videos/fotos localmente si quieres
└── docs/
    └── platform-setup-checklist.md
```

## 6. Cómo arrancar

```bash
cd bronson-composites-crm
cp .env.example .env        # rellena lo que ya tengas
./setup.sh                  # valida estructura, opcionalmente levanta Postgres local para probar
```

Luego, en n8n (una vez esté corriendo en Railway):
1. Importa los 4 workflows de `n8n-workflows/`.
2. Configura las credenciales de cada nodo con los valores de tu `.env`.
3. Activa primero `whatsapp-approval-gate` (es dependencia de los otros 3).
4. Activa `comment-lead-detection` y `content-scheduler-publish`.
5. Deja `ai-vehicle-mockup` en modo manual/test hasta tener tu primer cliente previo confirmado.

Ver `docs/platform-setup-checklist.md` para el detalle plataforma por plataforma.
