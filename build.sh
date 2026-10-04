#!/usr/bin/env bash
# Vercel build step.
#
# WHY THIS EXISTS: Vercel defaults its Output Directory to `public`. This
# repository is the finished site at its root, so the first deploy failed with
#   Error: No Output Directory named "public" found after the Build completed.
# Fixing it here rather than only in the dashboard means a fresh clone builds
# correctly for anyone, including Vercel's own build machines and CI.
#
# The site itself stays at the repo root. This copies it into public/ so the
# default configuration works, and so an explicit Output Directory of `.`
# still works too (public/ is simply ignored in that case).
set -euo pipefail

echo "goosefire-shop build"
echo "  node:   $(node --version 2>/dev/null || echo 'not found')"
echo "  commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"

if [ ! -f index.html ]; then
  echo "ERROR: index.html is missing at the repo root — nothing to publish." >&2
  exit 1
fi

# Populate the directory Vercel looks for by default.
rm -rf public
mkdir -p public

# Everything except Vercel's own output dir, git internals, and env files.
# Using tar keeps dotfiles (.gitignore, .env.example, _headers) in the copy.
tar --exclude='./public' \
    --exclude='./.git' \
    --exclude='./.env' \
    --exclude='./.env.local' \
    --exclude='./node_modules' \
    -cf - . | tar -xf - -C public

# Never publish real secrets, even if someone added one locally.
rm -f public/.env public/.env.local public/.env.production 2>/dev/null || true

echo "  published: $(find public -type f | wc -l) files, $(du -sh public | cut -f1)"
echo "build complete"