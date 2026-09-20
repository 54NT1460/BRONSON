# Checklist de setup por plataforma — Bronson Composites

Marca cada casilla según vayas obteniendo el acceso. Ninguna de estas es bloqueante para
las demás — el sistema simplemente deja ese canal inactivo hasta que llenes su sección en `.env`.

## Meta (Instagram + Facebook + WhatsApp Business API)
- [ ] Confirmar que la página de Facebook está conectada a una cuenta de **Meta Business Suite**
      (no personal). Si no existe, crear una en business.facebook.com.
- [ ] Confirmar que la cuenta de Instagram es **Business** o **Creator** (no personal) y está
      vinculada a la página de Facebook.
- [ ] Crear una app en developers.facebook.com, agregar los productos: **Instagram Graph API**,
      **Facebook Login**, **WhatsApp**.
- [ ] Generar un token de acceso de página de larga duración → `META_ACCESS_TOKEN`.
- [ ] Obtener `IG_BUSINESS_ACCOUNT_ID` y `FB_PAGE_ID` (Graph API Explorer o `/me/accounts`).
- [ ] Iniciar verificación de negocio para **WhatsApp Business API** (Meta pide: documento del
      negocio, número de teléfono dedicado). Puede tardar varios días.
- [ ] Obtener `WHATSAPP_PHONE_NUMBER_ID` y `WHATSAPP_BUSINESS_ACCOUNT_ID`.
- [ ] Configurar el webhook de comentarios (`meta-comments-webhook` en n8n) en el panel de la app.

## TikTok
- [ ] Crear cuenta en developers.tiktok.com.
- [ ] Crear app, solicitar acceso a **Content Posting API** y **Comment Kit / Display API**.
      (Algunos scopes requieren aprobación manual de TikTok — puede tardar días/semanas).
- [ ] Confirmar que la cuenta de TikTok del negocio es tipo **Business Account** (gratis, en
      Configuración de la app).

## Pinterest
- [ ] Convertir la cuenta a **Pinterest Business** (gratis, en Configuración).
- [ ] Crear app en developers.pinterest.com.
- [ ] Generar access token con scopes de `pins:write` y `boards:read`.

## Reddit
- [ ] Crear/confirmar cuenta de Reddit para el negocio (recomendado: con historial orgánico
      antes de postear, para evitar shadowban).
- [ ] Ir a reddit.com/prefs/apps → crear app tipo **script**.
- [ ] Guardar `client_id` y `client_secret`.
- [ ] Identificar 2-3 subreddits relevantes (ej. r/JeepWrangler, r/Jeep, r/OffRoad) y **leer sus
      reglas de auto-promoción** antes de postear nada — muchos requieren ratio 9:1 de contenido
      no-promocional.

## eBay
- [ ] Confirmar que la cuenta es **Seller (Vendedor)** con Seller Hub activo.
- [ ] Registrarse en developer.ebay.com, crear una app (Production keys).
- [ ] Generar OAuth token con scope de inventory/fulfillment.

## Amazon (Seller Central + SP-API)
- [ ] Confirmar cuenta de **Amazon Seller Central** (Professional plan requerido para API).
- [ ] Solicitar acceso a **SP-API** (requiere aprobación de Amazon — proceso más largo).
- [ ] Mientras tanto: gestionar listados manualmente, el CRM solo registra los pedidos.

## Etsy
- [ ] Confirmar cuenta de **Etsy Shop** activa.
- [ ] Crear app en Etsy Developers, solicitar acceso a la API v3.
- [ ] Mientras tanto: gestionar listados manualmente.

## Shopify
- [ ] Crear la tienda en shopify.com (o confirmar si ya existe una para Bronson).
- [ ] En el admin: Settings → Apps → Develop apps → crear **Custom App**.
- [ ] Dar permisos de `read_products`, `write_products`, `read_orders`, `write_orders`.
- [ ] Copiar el **Admin API access token** → `SHOPIFY_ADMIN_API_ACCESS_TOKEN`.

## Google Gemini
- [ ] Crear API key en aistudio.google.com/apikey.
- [ ] Confirmar que el modelo de generación de imágenes (Nano Banana / gemini-2.5-flash-image)
      esté disponible en tu región/cuenta.

## Servicio de edición de video
- [ ] Elegir uno: Shotstack, Creatomate, o JSON2Video (todos tienen tier gratuito/bajo costo y
      soportan templates + variables, que es lo que usa `content-scheduler-publish.json`).
- [ ] Crear el template de edición para "colab MiniTrucks" y otro para "Bronson HQ" (logo, intro,
      lower-thirds, música) directamente en la plataforma elegida.

## Railway
- [ ] Confirmar si usamos el mismo proyecto de TR4D3BOT o uno nuevo dedicado a Bronson.
- [ ] Desplegar servicio de **n8n** (imagen oficial `n8nio/n8n`).
- [ ] Desplegar plugin de **Postgres**.
- [ ] Configurar variable `TZ=America/Puerto_Rico` en el servicio de n8n.
