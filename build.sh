#!/usr/bin/env bash
# Vercel build step.
#
# WHY THIS EXISTS: Vercel defaults its Output Directory to `public`. This
# repository is the finished site at its root, so the first deploy failed with
#   Error: No Output Directory named "public" found after the Build completed.
# The build itself had run fine; Vercel just looked in public/ and found
# nothing. This script populates that directory so a fresh clone builds
# correctly without any dashboard configuration.
#
# It publishes ONLY the website. Repo internals — build.sh, package.json,
# vercel.json, .gitignore, .env.example — are deliberately NOT copied, because
# this directory becomes public URLs. In particular a second copy of
# vercel.json inside the output would be served to the public and would also
# point outputDirectory at a directory that does not exist inside itself.
set -euo pipefail

echo "goosefire-shop build"
echo "  node:   $(node --version 2>/dev/null || echo 'not found')"
echo "  commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"

if [ ! -f index.html ]; then
  echo "ERROR: index.html is missing at the repo root — nothing to publish." >&2
  exit 1
fi

OUT=public
rm -rf "$OUT"
mkdir -p "$OUT"

# 1. Pages and 404.
for page in index.html 404.html sitemap.xml robots.txt; do
  [ -f "$page" ] && cp "$page" "$OUT/"
done

# 2. Directories that make up the public site.
for dir in brand media shared; do
  [ -d "$dir" ] && cp -R "$dir" "$OUT/"
done

# 3. One directory per inner page.
for dir in makers work process journal contact; do
  [ -d "$dir" ] && cp -R "$dir" "$OUT/"
done

# Deliberately excluded: build.sh, package.json, vercel.json, .gitignore,
# .env.example, .env*, node_modules, .git — none of these belong at a public URL.

# 4. Never publish real secrets, even if one was created locally.
rm -f "$OUT"/.env "$OUT"/.env.local "$OUT"/.env.production 2>/dev/null || true

# 5. Fail loudly rather than shipping a broken site.
missing=0
for required in index.html 404.html sitemap.xml shared/tokens.css shared/site.css brand/mark.png; do
  if [ ! -f "$OUT/$required" ]; then
    echo "ERROR: expected $required in the output." >&2
    missing=1
  fi
done
[ "$missing" -eq 0 ] || exit 1

echo "  published: $(find "$OUT" -type f | wc -l) files, $(du -sh "$OUT" | cut -f1)"
echo "build complete"