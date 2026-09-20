#!/usr/bin/env bash
# Bronson Composites — bootstrap script
# Diseñado para correr desde Claude Code (o cualquier shell) al clonar este repo.
# No asume que ya tengas Railway/n8n desplegado — valida lo que puede validar localmente
# y te dice exactamente qué falta para el resto.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

echo "==> Bronson Composites CRM — setup"
echo "Directorio: $REPO_DIR"
echo

# ── 1. Verificar .env ────────────────────────────────────────────────────
if [ ! -f .env ]; then
  echo "⚠️  No existe .env — copiando desde .env.example"
  cp .env.example .env
  echo "   Edita .env con tus credenciales reales antes de continuar."
else
  echo "✅ .env encontrado"
fi

# ── 2. Cargar variables (solo las que existan) ───────────────────────────
set -a
# shellcheck disable=SC1091
source .env 2>/dev/null || true
set +a

# ── 3. Validar estructura del repo ───────────────────────────────────────
echo
echo "==> Validando estructura del proyecto"
required_files=(
  "db/schema.sql"
  "n8n-workflows/comment-lead-detection.json"
  "n8n-workflows/whatsapp-approval-gate.json"
  "n8n-workflows/content-scheduler-publish.json"
  "n8n-workflows/ai-vehicle-mockup.json"
  "config/content-schedule.json"
)
missing=0
for f in "${required_files[@]}"; do
  if [ -f "$f" ]; then
    echo "  ✅ $f"
  else
    echo "  ❌ FALTA: $f"
    missing=1
  fi
done
if [ "$missing" -eq 1 ]; then
  echo "Faltan archivos del andamiaje — revisa el repo antes de continuar."
  exit 1
fi

# ── 4. Validar JSON de los workflows ──────────────────────────────────────
echo
echo "==> Validando JSON de workflows n8n"
for f in n8n-workflows/*.json; do
  if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" 2>/dev/null; then
    echo "  ✅ $f es JSON válido"
  else
    echo "  ❌ $f tiene un error de sintaxis JSON"
    exit 1
  fi
done

# ── 5. Postgres local opcional (para probar el schema antes de Railway) ──
echo
if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
  echo "==> Se encontró psql y DATABASE_URL — ¿aplicar schema.sql ahora? (y/N)"
  read -r -t 10 answer || answer="n"
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    psql "$DATABASE_URL" -f db/schema.sql
    echo "  ✅ Schema aplicado"
  else
    echo "  ⏭️  Omitido — aplica luego con: psql \$DATABASE_URL -f db/schema.sql"
  fi
else
  echo "==> psql no disponible o DATABASE_URL vacío — omite este paso."
  echo "   Una vez tengas Postgres en Railway, corre:"
  echo "   psql \$DATABASE_URL -f db/schema.sql"
fi

# ── 6. Resumen de próximos pasos ──────────────────────────────────────────
echo
echo "==> Setup local completo. Próximos pasos:"
echo "  1. Revisa docs/platform-setup-checklist.md y ve marcando cuentas/tokens."
echo "  2. Despliega n8n + Postgres en Railway (mismo proyecto de TR4D3BOT o uno nuevo)."
echo "  3. Corre: psql \$DATABASE_URL -f db/schema.sql  (contra la DB de Railway)."
echo "  4. En n8n: Settings > Import from File, sube los 4 archivos de n8n-workflows/."
echo "  5. Configura las credenciales de cada nodo (postgres, whatsApp, tikTok, openAi) con tu .env."
echo "  6. Activa primero 'whatsapp-approval-gate', luego los demás."
echo "  7. Manda un comentario de prueba en un post para validar el flujo completo."
