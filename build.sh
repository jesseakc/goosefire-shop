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

# 2. Directories that make up the public site. media is copied
#    SELECTIVELY below (whole-dir copies once published unapproved photos
#    that simply sat in a referenced folder); brand and shared are whole-tree
#    and contain only published assets.
for dir in brand shared; do
  [ -d "$dir" ] && cp -R "$dir" "$OUT/"
done

# 2b. media: only files the pages and code actually reference (src, srcset,
#     poster, og:image in HTML; fallback poster paths in CSS/JS). Anything
#     not named never reaches a public URL. Whole-dir copies once published
#     unapproved photos that merely sat in a referenced folder.
mkdir -p "$OUT/media"
# -I skips binaries (.git objects, image files). CSS uses the same /media/
# paths for the no-JS hero poster fallback, so it must be scanned too.
grep -rhoI --include='*.html' --include='*.css' --include='*.js' \
    -E '/media/[A-Za-z0-9_./-]+' . \
  | sed -E 's/^\///' | sort -u > /tmp/gf_media_refs.txt
published_media=0
missing_media=0
while IFS= read -r ref; do
  if [ ! -f "$ref" ]; then
    echo "WARN: referenced media missing on disk: $ref" >&2
    missing_media=$((missing_media + 1))
    continue
  fi
  mkdir -p "$OUT/$(dirname "$ref")"
  cp "$ref" "$OUT/$ref"
  published_media=$((published_media + 1))
done < /tmp/gf_media_refs.txt
rm -f /tmp/gf_media_refs.txt
if [ "$missing_media" -gt 0 ]; then
  echo "ERROR: $missing_media referenced media file(s) missing — refusing to publish." >&2
  exit 1
fi

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
for required in index.html 404.html sitemap.xml shared/site.css shared/contact.js brand/mark.png; do
  if [ ! -f "$OUT/$required" ]; then
    echo "ERROR: expected $required in the output." >&2
    missing=1
  fi
done
[ "$missing" -eq 0 ] || exit 1

echo "  published: $(find "$OUT" -type f | wc -l) files, $(du -sh "$OUT" | cut -f1)"
echo "build complete"