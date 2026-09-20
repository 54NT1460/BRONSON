-- Bronson Composites CRM — Postgres schema
-- Diseñado para correr en Railway (Postgres plugin) y ser consumido desde n8n.

CREATE EXTENSION IF NOT EXISTS pgcrypto; -- gen_random_uuid()

-- ─────────────────────────────────────────────────────────────────────────
-- PLATAFORMAS Y CUENTAS
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE platform_accounts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform        TEXT NOT NULL CHECK (platform IN (
                        'instagram','facebook','tiktok','pinterest','reddit',
                        'whatsapp','telegram','ebay','amazon','etsy','shopify','youtube'
                    )),
    account_handle  TEXT NOT NULL,
    account_type    TEXT CHECK (account_type IN ('business','developer','personal','seller','unknown')) DEFAULT 'unknown',
    is_active       BOOLEAN NOT NULL DEFAULT true,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(platform, account_handle)
);

-- ─────────────────────────────────────────────────────────────────────────
-- LEADS Y CLIENTES
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE leads (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_platform     TEXT NOT NULL CHECK (source_platform IN (
                            'instagram','facebook','tiktok','pinterest','reddit','whatsapp','telegram','website','ebay','amazon','etsy'
                        )),
    source_handle       TEXT,                    -- @usuario en la plataforma de origen
    source_post_url     TEXT,                    -- post/reel donde comentó
    source_comment_text TEXT,                    -- el comentario original que lo detonó
    detected_intent     TEXT CHECK (detected_intent IN ('price_question','purchase_intent','general_interest','support','spam','unknown')) DEFAULT 'unknown',
    funnel_stage        TEXT NOT NULL DEFAULT 'new' CHECK (funnel_stage IN (
                            'new','dm_drafted','dm_pending_approval','dm_sent',
                            'engaged','quoted','negotiating','won','lost','ignored'
                        )),
    jeep_model          TEXT,                    -- modelo del Jeep si se conoce
    interested_products TEXT[],                  -- piezas mencionadas/interesadas
    contact_whatsapp    TEXT,
    contact_telegram    TEXT,
    contact_email       TEXT,
    assigned_funnel     TEXT,                     -- referencia a qué "oferta" se le dirige
    is_previous_customer BOOLEAN NOT NULL DEFAULT false,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_leads_funnel_stage ON leads(funnel_stage);
CREATE INDEX idx_leads_source_platform ON leads(source_platform);

CREATE TABLE customers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id         UUID REFERENCES leads(id),
    full_name       TEXT,
    whatsapp        TEXT,
    email           TEXT,
    jeep_model      TEXT,
    jeep_year       INT,
    vehicle_photo_url TEXT,                      -- foto base para mockups IA
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────
-- INTERACCIONES / LOG DE DMs (con estado de aprobación)
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE dm_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id         UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    channel         TEXT NOT NULL CHECK (channel IN ('instagram','facebook','tiktok','whatsapp','telegram')),
    direction       TEXT NOT NULL CHECK (direction IN ('draft','outbound','inbound')),
    message_text    TEXT NOT NULL,
    approval_status TEXT NOT NULL DEFAULT 'pending' CHECK (approval_status IN (
                        'pending','approved','edited_and_approved','rejected','sent'
                    )),
    approved_by     TEXT,                        -- 'santiago' vía WhatsApp bot
    approved_at     TIMESTAMPTZ,
    sent_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_dm_log_lead ON dm_log(lead_id);
CREATE INDEX idx_dm_log_status ON dm_log(approval_status);

-- ─────────────────────────────────────────────────────────────────────────
-- CONTENIDO Y SCHEDULER
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE content_queue (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slot                TEXT NOT NULL CHECK (slot IN ('turno_1','turno_2','turno_3')),
    scheduled_publish_at TIMESTAMPTZ NOT NULL,
    raw_file_url        TEXT,                    -- video/foto crudo que subiste
    edited_file_url      TEXT,                    -- después del template de edición
    caption              TEXT,
    collab_with_minitrucks BOOLEAN NOT NULL DEFAULT false,
    target_platforms    TEXT[] NOT NULL DEFAULT '{}', -- ej. {instagram,tiktok,facebook}
    content_type         TEXT CHECK (content_type IN ('video','photo','carousel')) DEFAULT 'video',
    status               TEXT NOT NULL DEFAULT 'raw_uploaded' CHECK (status IN (
                            'raw_uploaded','editing','pending_approval','approved',
                            'rejected','published','failed'
                        )),
    approval_status      TEXT NOT NULL DEFAULT 'pending' CHECK (approval_status IN (
                            'pending','approved','rejected'
                        )),
    published_at         TIMESTAMPTZ,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_content_queue_status ON content_queue(status);
CREATE INDEX idx_content_queue_schedule ON content_queue(scheduled_publish_at);

-- Mockups IA de vehículos de clientes previos (remarketing)
CREATE TABLE vehicle_mockups (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id     UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    original_photo_url TEXT NOT NULL,
    products_shown  TEXT[] NOT NULL,             -- piezas que se le "instalaron" con IA
    generated_image_url TEXT,
    approval_status TEXT NOT NULL DEFAULT 'pending' CHECK (approval_status IN ('pending','approved','rejected')),
    sent_to_customer BOOLEAN NOT NULL DEFAULT false,
    sent_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────
-- PRODUCTOS, PEDIDOS, PUNTOS DE VENTA
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE products (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku             TEXT UNIQUE NOT NULL,
    name            TEXT NOT NULL,
    material        TEXT CHECK (material IN ('fiberglass','carbon_fiber','hybrid')),
    fits_jeep_models TEXT[],
    price_usd       NUMERIC(10,2),
    is_active       BOOLEAN NOT NULL DEFAULT true,
    shopify_product_id TEXT,
    ebay_listing_id     TEXT,
    amazon_asin         TEXT,
    etsy_listing_id      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE orders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id     UUID REFERENCES customers(id),
    lead_id         UUID REFERENCES leads(id),
    channel         TEXT NOT NULL CHECK (channel IN (
                        'website','ebay','amazon','etsy','facebook_marketplace',
                        'clasificados_online','whatsapp','direct'
                    )),
    total_usd       NUMERIC(10,2),
    status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
                        'pending','paid','in_production','shipped','delivered','cancelled','refunded'
                    )),
    external_order_id TEXT,                       -- id del pedido en Shopify/eBay/etc.
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id),
    quantity        INT NOT NULL DEFAULT 1,
    unit_price_usd  NUMERIC(10,2) NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────────
-- EMBUDOS / OFERTAS (para dirigir leads según lo que se discuta después)
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE funnels (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT UNIQUE NOT NULL,
    description     TEXT,
    landing_url     TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- trigger simple para updated_at en leads
CREATE OR REPLACE FUNCTION touch_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_leads_updated_at
    BEFORE UPDATE ON leads
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
