# ===== Wallpaper Setter Backend Dockerfile =====
# Multi-stage:
#   - base      : runtime deps (openssl, libpq for Prisma 7 + pg)
#   - deps      : install ALL npm dependencies (dev + prod)
#   - dev       : run ts-node-dev with hot reload
#   - builder   : compile TypeScript to dist/
#   - prod      : run compiled JS, smallest final image
#
# Build targets:
#   docker build --target dev  -t wallpaper-setter-server:dev  .   (hot reload)
#   docker build --target prod -t wallpaper-setter-server:prod .   (production)

ARG NODE_VERSION=22-alpine

# ---------- base ----------
FROM node:${NODE_VERSION} AS base
WORKDIR /app

# System deps:
#   - openssl    : Prisma 7 engine binary requirement
#   - libpq      : pg client (used by @prisma/adapter-pg)
RUN apk add --no-cache openssl libpq

# Tell Prisma to skip the postinstall engine download (we copy engines in below)
ENV PRISMA_SKIP_POSTINSTALL_GENERATE=true

# ---------- deps ----------
FROM base AS deps
COPY package.json package-lock.json* ./
COPY prisma ./prisma
# Install ALL deps (incl. @prisma/client and prisma CLI) FIRST, then generate
# the client against node_modules. Order matters: prisma generate needs the
# @prisma/client runtime to resolve before it can write its output.
RUN npm ci
RUN npx prisma generate

# ---------- dev ----------
FROM deps AS dev
ENV NODE_ENV=development
# Mount source as a volume in dev profile; entrypoint runs ts-node-dev
COPY . .
EXPOSE 3000
CMD ["npx", "ts-node-dev", "--respawn", "--transpile-only", "src/index.ts"]

# ---------- builder ----------
FROM deps AS builder
ENV NODE_ENV=production
COPY . .
RUN npx tsc

# ---------- prod ----------
FROM base AS prod
ENV NODE_ENV=production
WORKDIR /app

# Copy compiled output + manifests + prisma artefacts (client + migrations)
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

EXPOSE 3000

# Healthcheck hits /health which index.ts already exposes
HEALTHCHECK --interval=10s --timeout=3s --start-period=20s --retries=5 \
  CMD wget -qO- http://localhost:3000/health || exit 1

ENTRYPOINT ["./entrypoint.sh"]
