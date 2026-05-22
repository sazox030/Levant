# Mashriq Editions — Accessibility / SEO / i18n / RTL Audit

Target: `/home/user/Levant/Mashriq-Editions.html` (self-contained React 18 + Tailwind v4 browser + Babel-standalone, single page).

This is an audit only. No source files were edited. Every fix below is copy-pasteable. Line numbers refer to the current file.

---

## Priority 0 — Critical (blocks crawlers and core a11y)

1. **SEO: no `meta description`, no Open Graph / Twitter, no canonical, no JSON-LD.** (`<head>`, lines 3–45)
2. **SEO: 100% client-side render via Babel.** `#app` is empty (line 47); all content is injected by `ReactDOM.createRoot(...).render(<App/>)` at line 1040 *after* Babel transpiles in-browser. Most crawlers will see an empty page.
3. **A11y: DetailPanel modal has `role="dialog"`/`aria-modal` but no focus trap, no Escape-to-close, no return-focus, no `aria-labelledby`.** (lines 892–945)
4. **A11y: warmgrey `#8A7F6E` body text fails WCAG AA.** Used pervasively for descriptions, captions, prices labels.

## Priority 1 — High

5. **i18n: `lang`/`dir` are set only after JS runs** (lines 1012–1013). First paint and crawlers see `<html lang="en">` (line 2) with no `dir`, even for Arabic users.
6. **A11y: language switcher and 1900/Today/Overlay tabs are not exposed as a group/tablist and have no active-state semantics** (lines 730–734, 829–831).
7. **A11y: heading hierarchy** — only one `<h1>` exists but it lives in `Hero`; the brand wordmark and several section intros are styled headings that are not marked up.

## Priority 2 — Medium

8. **RTL: several hard-coded `left`/`right` and `flex-row-reverse` toggles** instead of logical properties (mostly handled well already, a few exceptions).
9. **A11y: archive image buttons have no accessible name** (line 866) — the thumbnail-open button wraps only an SVG.
10. **A11y: SVG `role="img"`+`aria-label` present on hero/featured maps but glyph SVGs (thumbnails) have none** (lines 424, 537).

---

## 1. SEO — `<head>` additions

### 1a. Static meta, Open Graph, Twitter, canonical

Insert immediately after the `<title>` (line 6). Replace `https://mashriq.editions/` with the real production origin and supply a real `og:image` (1200×630 PNG/JPG).

```html
<meta name="description" content="Mashriq Editions — historic maps of the Levant, 1850–1948. Public-domain survey plates of Beirut, Damascus, Jerusalem, Aleppo, Jaffa and more, reissued on cotton paper. Trilingual: English, العربية, Français." />
<link rel="canonical" href="https://mashriq.editions/" />
<meta name="robots" content="index,follow" />
<meta name="theme-color" content="#F4EEE4" />

<!-- Open Graph -->
<meta property="og:type" content="website" />
<meta property="og:site_name" content="Mashriq Editions" />
<meta property="og:title" content="Mashriq Editions — Historic Maps of the Levant" />
<meta property="og:description" content="Public-domain survey plates of the Levant coast, 1850–1948, reissued on cotton paper. EN / العربية / FR." />
<meta property="og:url" content="https://mashriq.editions/" />
<meta property="og:locale" content="en" />
<meta property="og:locale:alternate" content="ar" />
<meta property="og:locale:alternate" content="fr" />
<meta property="og:image" content="https://mashriq.editions/og-image.jpg" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
<meta property="og:image:alt" content="Plan of Beirut, 1900 — a Mashriq Editions plate" />

<!-- Twitter -->
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="Mashriq Editions — Historic Maps of the Levant" />
<meta name="twitter:description" content="Public-domain survey plates of the Levant coast, 1850–1948, reissued on cotton paper." />
<meta name="twitter:image" content="https://mashriq.editions/og-image.jpg" />

<!-- hreflang: only meaningful once each language is server-rendered at its own URL -->
<link rel="alternate" hreflang="en" href="https://mashriq.editions/" />
<link rel="alternate" hreflang="ar" href="https://mashriq.editions/ar/" />
<link rel="alternate" hreflang="fr" href="https://mashriq.editions/fr/" />
<link rel="alternate" hreflang="x-default" href="https://mashriq.editions/" />
```

### 1b. JSON-LD schema.org — Store + the 8 Product plates

The 8 plates come from `window.LEVANT_CONTENT.archive` (lines 122–131): `dam1893, jer1883, alp1912, jaf1878, bey1876, tri1898, ant1906, hai1925`. Each price is the base (digital from €25; the panel offers digital/print/framed at 25/75/145, lines 896 / 926–932). Below uses `priceSpecification` low-price plus an `offers` AggregateOffer to express the three finishes. Add this `<script>` block anywhere in `<head>` (or end of `<body>`). It is fully static, so crawlers get it regardless of the React render.

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Store",
      "@id": "https://mashriq.editions/#store",
      "name": "Mashriq Editions",
      "alternateName": ["إصدارات المشرق", "Éditions Mashriq"],
      "url": "https://mashriq.editions/",
      "image": "https://mashriq.editions/og-image.jpg",
      "description": "Historic maps of the Levant, 1850–1948, reissued on cotton paper from public-domain survey plates.",
      "email": "orders@mashriq.editions",
      "address": {
        "@type": "PostalAddress",
        "streetAddress": "Mar Mikhael",
        "addressLocality": "Beirut",
        "addressCountry": "LB"
      },
      "openingHours": "Mo-Fr 10:00-18:00",
      "currenciesAccepted": "EUR",
      "knowsLanguage": ["en", "ar", "fr"]
    },
    {
      "@type": "Product",
      "name": "Damascus, 1893 — the walled city",
      "sku": "dam1893",
      "image": "https://mashriq.editions/plates/dam1893.jpg",
      "description": "Surveyed by the Ottoman Ministry of Public Works ahead of the Hijaz Railway. The seven gates named in Arabic and transliterated to French.",
      "brand": { "@type": "Brand", "name": "Mashriq Editions" },
      "offers": {
        "@type": "AggregateOffer",
        "priceCurrency": "EUR", "lowPrice": "25", "highPrice": "145",
        "offerCount": "3", "availability": "https://schema.org/InStock",
        "url": "https://mashriq.editions/#dam1893"
      }
    },
    {
      "@type": "Product",
      "name": "Jerusalem, 1883 — the Old City",
      "sku": "jer1883",
      "image": "https://mashriq.editions/plates/jer1883.jpg",
      "description": "Charles Wilson’s Ordnance Survey of Jerusalem, reissued at the original scale.",
      "brand": { "@type": "Brand", "name": "Mashriq Editions" },
      "offers": { "@type": "AggregateOffer", "priceCurrency": "EUR", "lowPrice": "25", "highPrice": "145", "offerCount": "3", "availability": "https://schema.org/InStock", "url": "https://mashriq.editions/#jer1883" }
    },
    {
      "@type": "Product",
      "name": "Aleppo, 1912 — the citadel and souks",
      "sku": "alp1912",
      "image": "https://mashriq.editions/plates/alp1912.jpg",
      "description": "Drawn for the Baghdad Railway concession. Souks shown lane by lane.",
      "brand": { "@type": "Brand", "name": "Mashriq Editions" },
      "offers": { "@type": "AggregateOffer", "priceCurrency": "EUR", "lowPrice": "25", "highPrice": "145", "offerCount": "3", "availability": "https://schema.org/InStock", "url": "https://mashriq.editions/#alp1912" }
    },
    {
      "@type": "Product",
      "name": "Jaffa, 1878 — port and orchards",
      "sku": "jaf1878",
      "image": "https://mashriq.editions/plates/jaf1878.jpg",
      "description": "Lithograph plate from the Palestine Exploration Fund, before the German Colony expanded south.",
      "brand": { "@type": "Brand", "name": "Mashriq Editions" },
      "offers": { "@type": "AggregateOffer", "priceCurrency": "EUR", "lowPrice": "25", "highPrice": "145", "offerCount": "3", "availability": "https://schema.org/InStock", "url": "https://mashriq.editions/#jaf1878" }
    },
    {
      "@type": "Product",
      "name": "Beirut, 1876 — the free port",
      "sku": "bey1876",
      "image": "https://mashriq.editions/plates/bey1876.jpg",
      "description": "Julius Löytved’s plan of Beirut as a free port, with the silk khans of Bab Idriss labelled by family.",
      "brand": { "@type": "Brand", "name": "Mashriq Editions" },
      "offers": { "@type": "AggregateOffer", "priceCurrency": "EUR", "lowPrice": "25", "highPrice": "145", "offerCount": "3", "availability": "https://schema.org/InStock", "url": "https://mashriq.editions/#bey1876" }
    },
    {
      "@type": "Product",
      "name": "Tripoli, 1898 — the twin cities",
      "sku": "tri1898",
      "image": "https://mashriq.editions/plates/tri1898.jpg",
      "description": "Al-Mina and Tripoli proper, joined by the tramway of the Société des Tramways de Tripoli.",
      "brand": { "@type": "Brand", "name": "Mashriq Editions" },
      "offers": { "@type": "AggregateOffer", "priceCurrency": "EUR", "lowPrice": "25", "highPrice": "145", "offerCount": "3", "availability": "https://schema.org/InStock", "url": "https://mashriq.editions/#tri1898" }
    },
    {
      "@type": "Product",
      "name": "Antakya, 1906 — both banks of the Orontes",
      "sku": "ant1906",
      "image": "https://mashriq.editions/plates/ant1906.jpg",
      "description": "Antioch on both banks of the Orontes, with the Roman bridge still in service.",
      "brand": { "@type": "Brand", "name": "Mashriq Editions" },
      "offers": { "@type": "AggregateOffer", "priceCurrency": "EUR", "lowPrice": "25", "highPrice": "145", "offerCount": "3", "availability": "https://schema.org/InStock", "url": "https://mashriq.editions/#ant1906" }
    },
    {
      "@type": "Product",
      "name": "Haifa, 1925 — the bay and the new harbour",
      "sku": "hai1925",
      "image": "https://mashriq.editions/plates/hai1925.jpg",
      "description": "British Mandate cadastre showing the new harbour works at the foot of Mount Carmel.",
      "brand": { "@type": "Brand", "name": "Mashriq Editions" },
      "offers": { "@type": "AggregateOffer", "priceCurrency": "EUR", "lowPrice": "25", "highPrice": "145", "offerCount": "3", "availability": "https://schema.org/InStock", "url": "https://mashriq.editions/#hai1925" }
    }
  ]
}
</script>
```

### 1c. SEO LIMITATION — client-side render (must read)

The page ships **no server-rendered HTML**. `#app` is empty (line 47) and the entire DOM is produced at runtime by Babel-standalone transpiling `<script type="text/babel">` then `ReactDOM.createRoot(...).render(<App/>)` (line 1040). Consequences:

- Googlebot *can* render JS, but in-browser Babel transpilation is slow/fragile and frequently times out or is skipped; Bing, social-card scrapers (Open Graph/Twitter crawlers do **not** run JS), and most others will index an **empty body**. Your card preview and snippet will be blank without the static meta + JSON-LD above.
- Performance: three large CDN scripts (`react.development.js`, `react-dom.development.js`, `@babel/standalone`, lines 49–51) plus runtime transpile = poor LCP and a flash of empty parchment.

**Recommendation — add a build/pre-render step:**

1. Move the JSX out of the inline `text/babel` block into a real module and compile it with esbuild/Vite at build time. Ship the *development* React builds (`react.development.js`) only in dev; use `react.production.min.js` in prod.
2. Pre-render to static HTML so the body is populated on first byte. Options, simplest first:
   - `ReactDOMServer.renderToString(<App/>)` in a tiny Node script, write the output into `#app` at build time (SSG). Hydrate on the client.
   - Or migrate to a static framework (Astro/Next export/Vite SSG) that emits one HTML file per language at `/`, `/ar/`, `/fr/` so the `hreflang` set in 1a becomes valid.
3. Keep `LEVANT_CONTENT` as the single source of truth and generate both the JSON-LD and the rendered HTML from it so they never drift.

---

## 2. i18n — `lang` / `dir` defaults

Today (lines 1012–1013) `App` sets `document.documentElement.lang` and `.dir` inside a `useEffect`, i.e. **only after React mounts**. The static `<html lang="en">` (line 2) has **no `dir`** attribute at all.

Implications:
- **First paint**: Arabic content (if Arabic is the default/persisted choice) renders LTR until JS runs — visible layout jump.
- **Crawlers / no-JS / OG scrapers**: see `lang="en"`, no direction. Arabic and French pages are never advertised at the document level.
- **Accessibility**: screen readers pick the wrong pronunciation/voice for the brief pre-hydration window, and permanently if JS fails.

Fixes:

**a. Always declare a base direction in static HTML** (line 2):
```html
<html lang="en" dir="ltr">
```

**b. If a language preference is persisted, set lang/dir before paint** — add this *before* the React scripts (before line 49), so it runs synchronously:
```html
<script>
  (function () {
    try {
      var l = localStorage.getItem("mashriq.lang");
      if (!l) {
        var nav = (navigator.language || "en").slice(0, 2);
        l = (nav === "ar" || nav === "fr") ? nav : "en";
      }
      document.documentElement.lang = l;
      document.documentElement.dir = (l === "ar") ? "rtl" : "ltr";
    } catch (e) {}
  })();
</script>
```
Then in `App`, initialise from the same key and persist on change:
```jsx
const [lang, setLang] = useState(
  () => (typeof localStorage !== "undefined" && localStorage.getItem("mashriq.lang")) || "en"
);
useEffect(() => {
  document.documentElement.lang = lang;
  document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";
  try { localStorage.setItem("mashriq.lang", lang); } catch (e) {}
}, [lang]);
```

**c. Best fix (with the build step from 1c):** render each language to its own URL with `<html lang dir>` already correct in the static file. No flash, valid `hreflang`.

---

## 3. Accessibility

### 3a. Colour contrast (WCAG 2.1; computed, sRGB)

Backgrounds in use: parchment `#F4EEE4`, parchdeep `#EBE2D2` (lines 10–11). AA needs **4.5:1** for normal text, **3:1** for large text (≥24px, or ≥18.66px bold) and UI components.

| Foreground | Background | Ratio | Normal AA (4.5) | Large AA (3.0) |
|---|---|---|---|---|
| ink `#1F1A14` | parchment | **14.96:1** | PASS | PASS |
| ink `#1F1A14` | parchdeep | **13.44:1** | PASS | PASS |
| **warmgrey `#8A7F6E`** | parchment | **3.41:1** | **FAIL** | PASS |
| **warmgrey `#8A7F6E`** | parchdeep | **3.06:1** | **FAIL** | PASS (barely) |
| indigo `#3A4A66` | parchment | 7.74:1 | PASS | PASS |
| rust `#9C4A2E` | parchment | 5.30:1 | PASS | PASS |
| parchment | ink (buttons/active tabs) | 14.96:1 | PASS | PASS |
| ink/70 (≈`#5F5A52`) | parchment | 5.93:1 | PASS | PASS |
| ink/75 (≈`#544F48`) | parchment | 7.03:1 | PASS | PASS |
| ink/80 | parchment | 8.32:1 | PASS | PASS |

**Failures to fix — `warmgrey` text.** It is used at small sizes (11–14px) all over: tagline (716), section-rule labels (703), plate counts (800), card "edition of 200"/"view plate" (876, 880), prices ship-note (938), provenance source notes (963), footer everything (982, 984, 989, 998), detail `dt` labels (919, 925), smallcaps captions (772, 906). All of these are well under 24px → they need **4.5:1** and currently sit at **3.41:1** (or 3.06:1 on parchdeep).

Fix — darken the warmgrey token so it passes at small sizes. Verified replacement: use **`#675C4B`**, which clears AA on *both* backgrounds (5.67:1 on parchment, 5.09:1 on parchdeep). Change the token at line 15:
```css
--color-warmgrey: #675C4B;  /* was #8A7F6E (3.41:1 fail) -> 5.67:1 on parchment, 5.09:1 on parchdeep */
```
This is a single-token change and propagates to every `text-warmgrey`. (Re-verify the few warmgrey-on-parchdeep spots — footer/collections sit on `parchdeep/50–60`.)

Note: ink at reduced opacity (`text-ink/70` and up, used in card descriptions line 802, 859, 911) all pass — no change needed.

### 3b. Heading hierarchy

- `<h1>` — hero title (line 756). Good, exactly one.
- `<h2>` — Collections (789), Featured (823), Archive (858), Provenance (956). Good.
- `<h3>` — collection names (799), archive card titles (871), detail title (910), glyph labels are SVG text (fine). Good.
- **Gaps:** the brand wordmark (line 715) and the footer brand (981) are visually prominent but plain `<span>`/`<div>` — acceptable (a logo need not be a heading). The `SectionRule` smallcaps labels (703) are decorative eyebrows, correctly *not* headings. The editorial "From the press" eyebrow (772) is decorative — fine.
- **One real issue:** the modal's plate title is an `<h3>` (910) but the modal is a separate landmark; when open it should expose its own labelled region (see 3d). Otherwise hierarchy is sound — no insertion needed beyond the modal label.

### 3c. SVG `role="img"` + `aria-label` — verification

- `HeroBeirut1900` (line 263): `role="img" aria-label="Plan of Beirut, 1900"` — PRESENT. But the label is **English-only and static**; it does not switch with `lang`. Pass `aria-label` from content so AR/FR users get a translated label.
- `BeirutLayered` (line 406): `role="img" aria-label={\`Beirut, ${mode}\`}` — PRESENT, but again English city name and the mode key (`1900/today/overlay`) is partly raw. Prefer the localized `f.heading[lang]` + localized tab label.
- **Missing:** `CollectionThumb` (line 424) and `ArchiveMap` (line 537) SVGs have **no** `role`/`aria-label`. These are the decorative-ish map glyphs inside cards. Because each card already has a real text title (`col.name`, `card.city`+`year`) right next to it, the cleanest fix is to mark these SVGs **decorative** so they are not announced as unlabeled graphics:
```jsx
// CollectionThumb <svg ...>  and  ArchiveMap <svg ...>
<svg ... role="presentation" aria-hidden="true">
```
For the hero/featured, localize instead of hiding (they carry meaning):
```jsx
// HeroBeirut1900 — accept a label prop and pass localized text from Hero
<svg ... role="img" aria-label={ariaLabel}>
// Hero: <HeroBeirut1900 ariaLabel={lang==="ar"?"مخطّط بيروت، ١٩٠٠":lang==="fr"?"Plan de Beyrouth, 1900":"Plan of Beirut, 1900"} />
```

### 3d. DetailPanel modal — focus trap, Escape, return focus, label

Current state (lines 892–945): `role="dialog"` + `aria-modal="true"` PRESENT (line 901); body scroll is locked (1016). **Missing: no `aria-labelledby`, no focus trap, focus is never moved into the dialog on open, Escape does not close, focus is not returned to the trigger on close.** The overlay closes on click (line 902) but that `<div>` is not keyboard reachable (see 3e).

Drop-in replacement for the `DetailPanel` body (keep the same props). Adds: label association, initial focus, focus restoration, Escape handler, and a Tab focus trap.

```jsx
function DetailPanel({ card, lang, onClose, onAdd }) {
  if (!card) return null;
  const rtl = isAr(lang);
  const note = C.detail.notes[card.id]?.[lang] || "";
  const materialOptions = [{key:"digital",price:25},{key:"print",price:75},{key:"framed",price:145}];
  const [picked, setPicked] = useState(card.material);
  useEffect(() => { setPicked(card.material); }, [card.id, card.material]);
  const pickedPrice = materialOptions.find(m => m.key === picked)?.price;

  const panelRef = useRef(null);
  const titleId = useId();
  // Move focus in on open; restore on close.
  useEffect(() => {
    const prevFocus = document.activeElement;
    const panel = panelRef.current;
    const focusables = () => panel.querySelectorAll(
      'a[href], button:not([disabled]), input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    const first = focusables()[0];
    if (first) first.focus();

    function onKey(e) {
      if (e.key === "Escape") { e.preventDefault(); onClose(); return; }
      if (e.key === "Tab") {
        const f = focusables();
        if (!f.length) return;
        const a = f[0], z = f[f.length - 1];
        if (e.shiftKey && document.activeElement === a) { e.preventDefault(); z.focus(); }
        else if (!e.shiftKey && document.activeElement === z) { e.preventDefault(); a.focus(); }
      }
    }
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("keydown", onKey);
      if (prevFocus && prevFocus.focus) prevFocus.focus(); // return focus
    };
  }, [card.id, onClose]);

  return (
    <div className="fixed inset-0 z-50" role="dialog" aria-modal="true" aria-labelledby={titleId}>
      <div className="absolute inset-0 bg-ink/40" onClick={onClose}></div>
      <div ref={panelRef}
           className={`absolute top-0 ${rtl?"left-0":"right-0"} h-full w-full md:w-[640px] bg-parchment border-ink/30 overflow-y-auto`}
           dir={rtl?"rtl":"ltr"}>
        <div className="p-5 md:p-8">
          <div className={`flex items-center justify-between mb-5 ${rtl?"flex-row-reverse":""}`}>
            <span className="smallcaps text-warmgrey text-[11px]">{lang==="en"?"Plate detail":lang==="ar"?"تفاصيل اللوحة":"Détail de la planche"}</span>
            <button onClick={onClose} className="font-serif text-[13px] text-ink hover:text-rust border border-ink/30 hover:border-rust px-3 py-1 transition-colors">{C.detail.close[lang]}</button>
          </div>
          <div className="border border-ink/25 bg-parchment p-2"><div className="border border-ink/15 p-1"><ArchiveMap kind={card.kind}/></div></div>
          <h3 id={titleId} className="mt-6 font-serif text-ink text-[28px]">{card.city[lang]}, <span className="num">{card.year}</span></h3>
          {/* ...rest unchanged... */}
        </div>
      </div>
    </div>
  );
}
```
Key points: `aria-labelledby={titleId}` ties the dialog to the `<h3>` title (line 910); `useId` is already imported (line 187); the cleanup function restores focus to the element that opened the panel; Escape works anywhere in the dialog; Tab is trapped between first and last focusables.

### 3e. Overlay close must be keyboard reachable

The backdrop `<div ... onClick={onClose}>` (line 902) is mouse-only — a keyboard user cannot trigger it. With the Escape handler added in 3d this is resolved (Escape is the standard keyboard equivalent of clicking the scrim). Do **not** add `tabIndex`/`role="button"` to the scrim — that creates a confusing extra tab stop. Escape + the existing "Close" button (907, already a real `<button>`) are the correct keyboard paths.

### 3f. Language switcher — keyboard + semantics

The buttons (lines 730–734) are real `<button>`s, so they are already focusable and Enter/Space-activatable. Missing: group semantics and pressed-state for screen readers. Enhancements:
```jsx
<div role="group"
     aria-label={lang==="ar"?"اللغة":lang==="fr"?"Langue":"Language"}
     className="flex items-center text-[13px] font-serif border border-ink/30">
  {langs.map((L,i)=>(
    <button key={L} onClick={()=>setLang(L)}
      aria-pressed={lang===L}
      lang={L}
      className={`px-2.5 py-1.5 ${i>0?"border-l border-ink/25":""} ${lang===L?"bg-ink text-parchment":"text-ink hover:bg-ink/10"} transition-colors`}>
      {C.langLabel[L]}
    </button>
  ))}
</div>
```
Note `lang={L}` on each so "ع" / "EN" / "FR" are pronounced correctly. (`border-l` here is a hard direction — see RTL §4.)

### 3g. 1900 / Today / Overlay tabs — tab semantics

These (lines 829–831) toggle a single view, so the ARIA tabs pattern fits. Minimal accessible version using `aria-pressed` (simplest, robust) — or full `role="tablist"`/`role="tab"`+`aria-selected` if you also wire arrow-key roving. Simplest correct fix:
```jsx
<div role="group" aria-label={lang==="en"?"Map layer":lang==="ar"?"طبقة الخريطة":"Couche de carte"} className="inline-flex border border-ink/35">
  {tabs.map((t,i)=>(
    <button key={t.id} onClick={()=>setMode(t.id)}
      aria-pressed={mode===t.id}
      className={`px-4 md:px-5 py-2 font-serif text-[13.5px] ${i>0?"border-s border-ink/30":""} ${mode===t.id?"bg-ink text-parchment":"text-ink hover:bg-ink/10"} transition-colors`}>
      {t.label}
    </button>
  ))}
</div>
```
These are already keyboard-operable (real buttons); `aria-pressed` is the missing piece so the active state is announced (today it is conveyed by colour only — also a contrast/“colour-as-only-cue” concern, which `aria-pressed` resolves for AT).

### 3h. Archive thumbnail button has no accessible name

Line 866: `<button onClick={()=>onOpen(card)} className="block text-start">` wraps only the SVG. A redundant open button below it has the visible title, but this image button is an empty, unlabeled control to a screen reader. Add a label:
```jsx
<button onClick={()=>onOpen(card)} className="block text-start w-full"
        aria-label={`${lang==="en"?"View plate":lang==="ar"?"اعرض اللوحة":"Voir la planche"}: ${card.city[lang]}, ${card.year}`}>
  <div className="border border-ink/15 bg-parchment overflow-hidden"><ArchiveMap kind={card.kind}/></div>
</button>
```
(Combined with marking `ArchiveMap` decorative in 3c.)

---

## 4. RTL — logical properties audit

Overall the author already uses logical Tailwind utilities in most places — good. Confirmed correct usage:
- `me-auto` on the brand link (714), `border-s` on tabs (830, 928 area) and collections grid (791), `text-start` (866), `text-end` (920, 963), `ps-/pe-` not needed but `px-` is symmetric so fine.
- Directional layout that *should* flip is handled with `isAr(lang)` toggles + `dir={...}` on subtrees (798, 903, 1026) and `flex-row-reverse` (700, 822, 870, 874, 878, 905, 935, 979, 986, 996) and `md:[direction:rtl]` (954, 986).

**Hard-coded directions to flag/fix:**

1. **`border-l` in the language switcher** (line 732): `${i>0?"border-l border-ink/25":""}`. This is a physical left border; in RTL the dividers should sit on the logical start side. Use the logical equivalent:
   ```jsx
   ${i>0?"border-s border-ink/25":""}
   ```
   (Compare line 830 which correctly uses `border-s`.) This is the one genuine physical-property bug.

2. **`absolute left-…/right-…` positioning** in the Hero corner labels (lines 761–762): `top-3 left-4 md:left-6` and `top-3 right-4 md:right-6`. These are fixed plate-corner ornaments ("Plate I" top-left, brand top-right). They are *not* mirrored for RTL, so in Arabic the "اللوحة الأولى" caption stays top-left rather than top-right. If the intent is that the plate number always hugs the leading corner, switch to logical:
   ```jsx
   // was: className="absolute top-3 left-4 md:left-6 ..."
   className="absolute top-3 start-4 md:start-6 ..."
   // was: className="absolute top-3 right-4 md:right-6 ..."
   className="absolute top-3 end-4 md:end-6 ..."
   ```
   (Decorative, low priority — flag, your call on whether plate corners should mirror.)

3. **`-bottom-5 right-0 / left-0` toast** (line 725): already conditional on `isAr(lang)` (`${isAr(lang)?"right-0":"left-0"}`) — functionally correct, but could be simplified to `start-0`. Not a bug.

4. **`absolute top-0 left-0/right-0`** on the modal panel (line 903): conditional on `rtl` (`${rtl?"left-0":"right-0"}`) so the drawer slides from the correct edge — correct. Could be `end-0` (LTR drawer enters from the right = end) for brevity; not a bug.

5. **Inline `textAlign:"right"/"left"`** driven by `isAr(lang)` (773, 789, 802, 823, 824, 858, 859, 956, 957, 984) — functionally correct but verbose; `text-start` utility would replace all of them. Not a bug, a simplification.

6. **`border-l border-ink/25` does not exist elsewhere** — the only physical-axis utility in the file is the line-732 case above. SVG internals (x/y coords, `textAnchor`) are intrinsic to the map artwork and correctly *not* mirrored (a map should not flip).

**Net RTL verdict:** one real fix (item 1, `border-l` → `border-s`); items 2 is a judgement call for decorative corners; the rest are correct-but-verbose and could migrate to `text-start`/`start-`/`end-` for maintainability.

---

## Quick-fix checklist (in priority order)

- [ ] P0 SEO: add static `<meta description>` + OG/Twitter/canonical (§1a) and JSON-LD `@graph` Store+8 Products (§1b).
- [ ] P0 SEO: introduce a pre-render/SSG build step; ship production React, drop in-browser Babel (§1c).
- [ ] P0 A11y: add focus trap + Escape + return-focus + `aria-labelledby` to DetailPanel (§3d, §3e).
- [ ] P0 A11y: darken `--color-warmgrey` `#8A7F6E` → `#675C4B` to pass AA at small sizes (§3a).
- [ ] P1 i18n: set `dir` in static `<html>` + pre-paint lang/dir script + persist (§2).
- [ ] P1 A11y: `aria-pressed` on lang switcher & layer tabs; `role="group"` + per-button `lang` (§3f, §3g).
- [ ] P1 RTL: `border-l` → `border-s` in language switcher (§4 item 1).
- [ ] P2 A11y: label the archive thumbnail button; mark thumbnail/glyph SVGs decorative; localize hero/featured SVG `aria-label` (§3c, §3h).
- [ ] P2 RTL: optionally migrate inline `textAlign` and Hero corner `left/right` to logical utilities (§4 items 2,5).
