# Security & QA Review — Mashriq Editions

Reviewer: security/QA agent
Date: 2026-05-22
Scope reviewed:
- `/home/user/Levant/Mashriq-Editions.html` (self-contained React + Tailwind + Babel via CDN)
- `/home/user/Levant/supabase/schema.sql`
- `/home/user/Levant/vercel.json`

## Summary

The storefront is a static, client-only single page. It has a **clean XSS posture**: no
`dangerouslySetInnerHTML`, no `innerHTML` / `eval` / `document.write` / `insertAdjacentHTML`,
no `target="_blank"` links, and **no secrets/API keys** in the HTML. All user-visible content
comes from a static `window.LEVANT_CONTENT` object rendered through React's auto-escaping JSX.
The HTML makes **no network calls** (no `fetch`/XHR/Supabase client) — the cart is in-memory only.

The main risks are operational/production-readiness rather than active vulnerabilities:
runtime Babel + CDN dependencies are not production-grade, there is **no Content-Security-Policy**,
the **Tailwind `<script>` lacks SRI**, and the React/ReactDOM tags load **development builds**.
The Supabase RLS posture is correct for orders (insert-only, not publicly readable) but
`order_items` and `newsletter_subscribers` have integrity gaps worth tightening.

Priorities: **P0** = fix before/at production launch; **P1** = important hardening; **P2** = polish.

---

## P0 — Fix before production

### P0-1. Runtime Babel + CDN dependencies are not production-grade
`Mashriq-Editions.html` lines 49–51 and the `<script type="text/babel">` block (line 185)
compile JSX **in the browser at every page load** via `@babel/standalone`. This is slow
(multi-hundred-KB Babel download + client-side transpile on every visit) and a supply-chain
exposure: the site executes whatever those CDN URLs serve.

Additionally, lines 49–50 load the **development** builds of React/ReactDOM
(`react.development.js`, `react-dom.development.js`) — these are larger, slower, and emit dev
warnings; they should never ship to production.

Fix: introduce a real build step.
- Use Vite (or similar) to bundle React + the app into static JS/CSS, transpiling JSX at build time (remove Babel-standalone entirely).
- Pin dependencies in `package.json` + lockfile; ship self-hosted, fingerprinted assets instead of CDN script tags.
- Use the **production** React build (`react.production.min.js`) — or just let the bundler tree-shake/minify.
- Compile Tailwind at build time (Tailwind CLI / PostCSS) instead of the browser runtime (`@tailwindcss/browser`, line 7).

### P0-2. No Content-Security-Policy
There is no CSP anywhere (no `<meta http-equiv="Content-Security-Policy">` and none in
`vercel.json`). `vercel.json` sets `X-Content-Type-Options`, `Referrer-Policy`, and
`X-Frame-Options`, but no CSP — so any injected/compromised script can run freely.

Fix: add a CSP. Prefer the HTTP header form in `vercel.json` (do not edit it as part of this
review — see proposals below) so it covers all responses. Two tiers are proposed in the
"Proposed CSP" section: one for the **current CDN setup** and a **stricter** one for the
bundled build (P0-1). Ship the strict one once bundled.

---

## P1 — Important hardening

### P1-1. Tailwind `<script>` has no SRI / crossorigin
`Mashriq-Editions.html` line 7:
```html
<script src="https://unpkg.com/@tailwindcss/browser@4.1.5/dist/index.global.js"></script>
```
Unlike the React/ReactDOM/Babel tags, this one has **no `integrity` and no `crossorigin`**.
It is version-pinned, but a tampered/compromised CDN response would execute unverified.

Verification of the other three tags (lines 49–51): I recomputed the SHA-384 hashes from the
live unpkg files and **all three integrity hashes match exactly** — they are valid:
- `react@18.3.1/umd/react.development.js` → `sha384-hD6/rw4ppMLGNu3tX5cjIb+uRZ7UkRJ6BPkLpg4hAu/6onKUg4lLsHAs9EBPT82L` ✔
- `react-dom@18.3.1/umd/react-dom.development.js` → `sha384-u6aeetuaXnQ38mYT8rp6sbXaQe3NL9t+IBXmnYxwkUI2Hw4bsp2Wvmx4yRQF1uAm` ✔
- `@babel/standalone@7.29.0/babel.min.js` → `sha384-m08KidiNqLdpJqLq95G/LEi8Qvjl/xUYll3QILypMoQ65QorJ9Lvtp2RXYGBFj1y` ✔

Fix (interim, while still on CDN): add SRI + crossorigin to the Tailwind tag, e.g.
```html
<script src="https://unpkg.com/@tailwindcss/browser@4.1.5/dist/index.global.js"
        integrity="sha384-<computed-hash>" crossorigin="anonymous"></script>
```
Compute the hash with:
`curl -sL <url> | openssl dgst -sha384 -binary | openssl base64 -A`
(Note: `@tailwindcss/browser` is itself a dev/runtime convenience build — the real fix is P0-1,
compiling Tailwind at build time, after which this tag goes away entirely.)

### P1-2. `order_items` RLS allows forged prices and orphan/cross-order inserts
`supabase/schema.sql` lines 149–154: the `order_items` insert policy is `with check (true)`.
Combined with the `orders` insert policy (also `with check (true)`), an anon client can:
- insert `order_items` with an **arbitrary `unit_price_eur`** (e.g. €0), and
- insert items referencing **any `order_id`**, including orders it did not create.

For a v1 cart-capture flow this means client-supplied prices/line items cannot be trusted.

Fix: do not trust client-sent money. Either
- compute order totals and line-item prices **server-side** (Edge Function / service_role) and
  remove the public INSERT policies on `orders`/`order_items` so all writes go through trusted
  backend code; **or**
- if keeping direct anon inserts, validate prices server-side against `material_prices` via a
  trigger/RPC, and tie `order_items` inserts to the caller's just-created order (e.g. a
  `SECURITY DEFINER` RPC that creates the order and its items atomically with server-priced lines).

### P1-3. `newsletter_subscribers` insert policy enables enumeration / spam
`schema.sql` lines 158–163: anon `INSERT` with `with check (true)` on a table whose primary key
is `email`. No `SELECT` is exposed (good — list cannot be harvested), but:
- a unique-violation error on insert leaks **whether an email is already subscribed** (enumeration), and
- there is no rate limiting, so the table can be flooded with arbitrary/garbage emails.

Fix: route signup through an RPC / Edge Function that uses `insert ... on conflict do nothing`
(so it returns success regardless of prior state, removing the enumeration oracle), add basic
email-format validation (`check (email ~* '^...$')`), and apply rate limiting (captcha / per-IP
throttle at the function or gateway level).

---

## P2 — Polish / defense-in-depth

### P2-1. Add HSTS and tighten security headers
`vercel.json` (lines 6–14) is missing `Strict-Transport-Security`. Add
`Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`. The existing
`X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, and
`X-Frame-Options: SAMEORIGIN` are good; once a CSP exists, also add `frame-ancestors 'self'`
to the CSP (the modern equivalent of `X-Frame-Options`).

### P2-2. External links / `target="_blank"` — currently clean
No `target="_blank"` anchors and no external `http(s)` `href`s exist in the page (footer
contact/legal items are plain text, not links). **No action needed now.** If outbound links
are added later (e.g. the four provenance sources in `LEVANT_CONTENT.provenance.sources`,
or social links), any `target="_blank"` MUST include `rel="noopener noreferrer"`.

### P2-3. Confirmed: no secrets in client code
No API keys, tokens, Supabase URL/anon key, or credentials are present in
`Mashriq-Editions.html`. Keep it that way: when the cart is wired to Supabase, only the
**anon public key** (designed to be public and gated by RLS) should ever reach the client —
never the `service_role` key. Server-only secrets belong in Vercel/Supabase environment
variables and Edge Functions.

### P2-4. `unpkg.com` "latest"/range drift — already pinned (good)
All four CDN tags use exact pinned versions (`react@18.3.1`, `react-dom@18.3.1`,
`@babel/standalone@7.29.0`, `@tailwindcss/browser@4.1.5`). No floating ranges. No action;
noted as a positive that should be preserved if anyone updates the tags.

---

## Proposed Content-Security-Policy

### A) For the CURRENT CDN + runtime-Babel setup (interim)
Babel-standalone evaluates strings, and Tailwind's runtime build injects styles, so the
interim policy must permit `unsafe-eval` and inline styles. This is weak by design — treat it
as a stopgap until P0-1 lands.

```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' https://unpkg.com 'unsafe-eval';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data:;
  font-src 'self';
  connect-src 'self' https://*.supabase.co;
  frame-ancestors 'self';
  base-uri 'self';
  form-action 'self';
  object-src 'none'
```
Notes:
- `script-src` includes `https://unpkg.com` (CDN tags) and `'unsafe-eval'` (Babel transpiles at runtime). The inline `<script type="text/babel">` and `window.LEVANT_CONTENT` block are *transformed*, not eval-classified as inline-`<script>` after Babel runs, but if blocked you may need a nonce/hash on those tags — prefer eliminating them via P0-1 rather than allowing `'unsafe-inline'` for scripts.
- `style-src 'unsafe-inline'` is required by runtime Tailwind + the inline `<style>` blocks and React inline `style={{...}}`.
- `connect-src` includes `https://*.supabase.co` ahead of wiring the cart to Supabase; drop it until then if you want it tighter.

### B) STRICTER policy for the BUNDLED build (target — after P0-1)
Once JSX/Tailwind are compiled at build time and assets are self-hosted, remove `unsafe-eval`,
drop the unpkg origin, and (ideally) eliminate inline scripts so no `'unsafe-inline'` is needed
for `script-src`. Inline `style={{...}}` from React still needs either `'unsafe-inline'` styles
or per-render nonces; the cleanest path is hashed/nonce'd styles, but `'unsafe-inline'` for
*styles only* is an acceptable, common compromise.

```
Content-Security-Policy:
  default-src 'self';
  script-src 'self';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data:;
  font-src 'self';
  connect-src 'self' https://*.supabase.co;
  frame-ancestors 'self';
  base-uri 'self';
  form-action 'self';
  object-src 'none';
  upgrade-insecure-requests
```
Deliver via the `headers` array in `vercel.json` (same shape as the existing entries) so it
applies to every response.

---

## Checklist results

| Check | Result |
|---|---|
| `dangerouslySetInnerHTML` / unsanitized HTML | None found — clean (React JSX auto-escaping) |
| `innerHTML` / `eval` / `document.write` / `insertAdjacentHTML` | None found |
| Secrets / API keys in HTML | None found |
| External links / `target="_blank"` rel="noopener" | No external/blank links present — N/A now; flagged for future |
| React / ReactDOM / Babel SRI hashes | Present, `crossorigin` set, **all 3 verified correct** |
| Tailwind tag SRI | **Missing** (P1-1) |
| React build channel | **Development build in use** (P0-1) |
| Runtime Babel + CDN deps | Present — **not production-grade** (P0-1) |
| Content-Security-Policy | **Absent** (P0-2); proposals provided |
| Supabase orders: insert-only for anon, not publicly readable | Correct (insert-only, no SELECT; reads need service_role) |
| Supabase order_items integrity | **Gap** — forgeable prices / cross-order inserts (P1-2) |
| Supabase newsletter | Insert-only but enumeration + spam risk (P1-3) |
| Security headers (vercel.json) | nosniff / Referrer-Policy / X-Frame-Options present; **HSTS + CSP missing** (P0-2, P2-1) |
