#!/bin/sh
# =============================================================================
# Wallpaper Setter server container entrypoint
# - Waits for PostgreSQL to accept connections
# - Re-generates the Prisma client (in case schema changed in this build)
# - Applies pending Prisma migrations; if no migration history exists yet,
#   falls back to `prisma db push` so first-run works on a brand-new database
# - Hands off to the main process (node dist/index.js)
# =============================================================================
set -e

echo "============================================================"
echo "  Wallpaper Setter backend container starting"
echo "  NODE_ENV=${NODE_ENV:-production}"
echo "  PORT=${PORT:-3000}"
echo "============================================================"

# -----------------------------------------------------------------------------
# 1. Wait for PostgreSQL
#    We parse the host out of DATABASE_URL (which is a libpq URL).
#    Connection failures are normal during compose boot — retry.
# -----------------------------------------------------------------------------
DB_HOST="$(node -e "
  const url = require('url').parse(process.env.DATABASE_URL || '');
  process.stdout.write(url.hostname || 'localhost');
")"
DB_PORT="$(node -e "
  const url = require('url').parse(process.env.DATABASE_URL || '');
  process.stdout.write(String(url.port || 5432));
")"

echo "[entrypoint] Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT} ..."
ATTEMPTS=0
MAX_ATTEMPTS=60
until node -e "
  const net = require('net');
  const s = net.createConnection({ host: process.env.DB_HOST || '${DB_HOST}', port: Number(process.env.DB_PORT || ${DB_PORT}) });
  s.on('connect', () => { s.end(); process.exit(0); });
  s.on('error', () => process.exit(1));
  setTimeout(() => process.exit(1), 2000);
" >/dev/null 2>&1; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
    echo "[entrypoint] ❌ PostgreSQL not reachable after ${MAX_ATTEMPTS} attempts, giving up."
    exit 1
  fi
  echo "[entrypoint]   not ready yet (attempt $ATTEMPTS/$MAX_ATTEMPTS), retrying in 2s ..."
  sleep 2
done
echo "[entrypoint] ✅ PostgreSQL is reachable."

# -----------------------------------------------------------------------------
# 2. Generate the Prisma client
#    The image already ships a generated client, but if the schema was edited
#    locally and the image rebuilt, re-generate to be safe.
# -----------------------------------------------------------------------------
echo "[entrypoint] Generating Prisma client ..."
npx prisma generate >/dev/null

# -----------------------------------------------------------------------------
# 3. Apply migrations
#    - If `_prisma_migrations` table exists → use `migrate deploy` (production-safe)
#    - Otherwise (first run on empty DB) → use `db push` to create the schema
# -----------------------------------------------------------------------------
echo "[entrypoint] Applying database schema ..."
HAS_MIGRATIONS=$(node -e "
  const { Client } = require('pg');
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  c.connect()
    .then(() => c.query(\"SELECT to_regclass('public._prisma_migrations') IS NOT NULL AS exists\"))
    .then(r => { process.stdout.write(r.rows[0].exists ? 'yes' : 'no'); return c.end(); })
    .catch(() => { process.stdout.write('no'); });
" 2>/dev/null || echo "no")

if [ "$HAS_MIGRATIONS" = "yes" ]; then
  echo "[entrypoint] Migration history found → running 'prisma migrate deploy' ..."
  npx prisma migrate deploy
else
  echo "[entrypoint] No migration history → running 'prisma db push' (first-time schema sync) ..."
  npx prisma db push --accept-data-loss
fi

echo "[entrypoint] ✅ Database ready."

# -----------------------------------------------------------------------------
# 4. Hand off to the main process
# -----------------------------------------------------------------------------
echo "[entrypoint] Starting application ..."
exec node dist/index.js
