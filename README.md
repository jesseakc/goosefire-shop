# goosefire.shop

The public website for **Goose Fire Ceramics** — a small ceramics studio in Staunton,
Illinois, run by Alesha (artist) and Jesse (her partner; kiln, video, and ornaments).

The studio is **not selling online yet**. This site exists to introduce people to Alesha
and the things she loves making, and to give visitors a way to follow along.

---

## What this is

A **static website**. Plain HTML, plain CSS, no framework, no build dependencies, no
JavaScript. That is a deliberate choice: the site has to keep working in five years, be
editable by two people who are not developers, and cost nothing to host.

```
_site/
├── index.html            home
├── makers/               Alesha, the artist
├── work/                 the pieces
├── process/              how things are made
├── journal/              working notes
├── contact/              contact
├── 404.html
├── brand/                logo mark + favicon
├── media/                web-optimised images (AVIF + JPEG, 800w + 1600w)
├── shared/               tokens.css (the brand palette) + site.css
├── sitemap.xml
├── vercel.json           static-host config
└── _headers              cache headers
```

**Brand is defined once**, in `shared/tokens.css`. Changing a colour there changes it on
every page. The three future Goose Fire domains (`luxuryornaments.xyz`,
`ceramicchristmas.com`) are meant to import the same file, so the brand cannot drift.

---

## Run it locally

Any static server works. From this directory:

```bash
python3 -m http.server 8901
# then open http://localhost:8901/
```

There is nothing to install and nothing to compile.

---

## Deploy to Vercel

### ⚠ Read this first: the Hobby plan is not available for a business

Vercel's own Fair Use Guidelines state:

> "Hobby teams are restricted to non-commercial personal use only. All commercial usage of the
> platform requires either a Pro or Enterprise plan. Commercial usage is defined as any
> Deployment that is used for the purpose of financial gain of anyone involved in any part of the
> production of the project…"

— <https://vercel.com/docs/limits/fair-use-guidelines> (page last updated 2026-07-29)

Their named examples include *"Advertising the sale of a product or service"* and *"Any method of
requesting or processing payment from visitors of the site."*

**Goose Fire is a ceramics studio that intends to sell.** That is commercial use by their own
definition, so **the free Hobby plan is not the right plan for this site** — Hobby is $0 but
Vercel restricts it to non-commercial personal projects, and enforcement can mean suspension.

**Choose one:**

| Option | Cost | Notes |
|---|---|---|
| **Vercel Pro** | **$20/month** | Simplest. Removes the restriction outright. |
| **Cloudflare Pages** | **$0** | No commercial restriction, unlimited bandwidth on the free tier. Static site, no server. This is the recommendation in `.planning/research/web-tech-stack-2026.md`. |
| **Netlify** | $0–$ | **Check current terms** — bandwidth is now credit-metered (~15 GB/month effective), which is tight for a media site. |

Nothing in this repository requires Vercel specifically. It is plain static HTML with a
`vercel.json` for cache headers.

### If you use Vercel

1. Import the repository.
2. Settings:

| Setting | Value |
|---|---|
| **Framework Preset** | `Other` |
| **Build Command** | `npm run build` |
| **Output Directory** | `.` |
| **Install Command** | leave blank |

3. Add the domain **goosefire.shop** in **Settings → Domains**, then point DNS at whatever Vercel
   shows you. *(DNS changes are yours to make.)*

### Environment variables

**None are required to build or serve this site.** It is entirely static.

There is a `.env.example` in this repo as a placeholder for when the forms are connected.
It contains no real values and nothing reads it yet.

| Variable | Needed? | Purpose |
|---|---|---|
| `CONTACT_FORM_ENDPOINT` | no | Where the contact form POSTs. Not yet configured. |
| `NEWSLETTER_ENDPOINT` | no | Where the signup form POSTs. Not yet configured. |

**The signup and contact forms are deliberately disabled.** Both targets
(`buttondown.email`, `form.goosefire.shop`) do not currently resolve, and a form that
silently discards a real person's message is worse than no form. The inputs are visibly
greyed out and say so. To enable them, set the endpoints above, then remove the
`signup--off` class and the `onsubmit="return false;"` guard from the form in
`index.html` and `contact/index.html`.

---

## How to update the site

### Change a colour or a font

Edit `shared/tokens.css`. It is the single source of truth for the palette and type.
Everything else inherits from it.

### Add a photograph

1. Put the original in the media library (the `Media/` folder in the studio repo — the
   full-quality masters live there and are deliberately **not** part of this repository).
2. Generate web versions:
   ```bash
   convert original.jpg -auto-orient -resize "1600x1600>" -strip -quality 62  out-1600.avif
   convert original.jpg -auto-orient -resize "800x800>"   -strip -quality 62  out-800.avif
   convert original.jpg -auto-orient -resize "1600x1600>" -strip -interlace Plane -quality 82 out-1600.jpg
   convert original.jpg -auto-orient -resize "800x800>"   -strip -interlace Plane -quality 82 out-800.jpg
   ```
   Place all four in `media/<name>/`.
3. Reference it in a page as `<img src="/media/<name>/<name>-1600.jpg" ...>`. The build
   rewrites that automatically into a `<picture>` with AVIF + JPEG srcsets at both widths.

### Add a page

Create `mypage/index.html` and copy the `<head>` and `<footer>` from an existing page.
Then rebuild (below) so the sitemap and canonical URL pick it up.

---

## Rebuilding from source

This repo contains the built output. If you ever want to regenerate it from the studio
repo, that repo holds the sources and the tooling:

```bash
cd "~/goose fire"
node tools/build-site.mjs goosefire-shop   # writes dist/
node tools/media-pipeline.mjs --photo <file>   # make derivatives
```

**Originals are never modified.** Web versions are always generated into a separate
folder, next to the originals rather than over them.

---

## Credits

- Ornament mould designs: **[Old Forge Creations](https://oldforgecreations.co.uk/)** —
  used with thanks. The plaster casting, trimming and glazing are Alesha's own work.
- Photography: the studio's own. Studio images are photographs of real work.
- Three images are **computer-generated illustrations** and are labelled as such
  wherever they appear, in line with the studio's rule that AI imagery must never be
  presented as documentary evidence of work that exists.

---

## Accessibility and performance notes

- All text meets WCAG AA contrast; the hero scrim is tuned against the measured
  luminance of the actual hero images.
- Every image has descriptive alt text, and the logo uses empty alt (it is
  decorative — the wordmark carries the name).
- Video, if added, must have a poster frame, captions, and must respect
  `prefers-reduced-motion`. No video autoplays with sound.
- Images are AVIF with a JPEG fallback, sized 800w/1600w, so phones never download the
  12-megapixel originals.