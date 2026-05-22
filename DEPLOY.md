# Deploying Mashriq Editions

This is a static storefront (`Mashriq-Editions.html`) deployed to Vercel with a
Supabase backend. Follow the steps below once you have the necessary accounts.

## 1. Set up Supabase

1. Create a new project at [supabase.com](https://supabase.com).
2. Open the **SQL Editor** in your project dashboard.
3. Run `supabase/schema.sql` to create the tables/schema.
4. Run `supabase/seed.sql` to load initial data.

## 2. Get your project credentials

In **Project Settings → API**, copy:

- **Project URL** → `SUPABASE_URL`
- **anon public key** → `SUPABASE_ANON_KEY`

See `.env.example` for the full list of variables. Never commit real values —
they belong in the Vercel/Supabase dashboards.

## 3. Deploy to Vercel

```bash
# Install the Vercel CLI (one time)
npm i -g vercel

# Link this directory to a Vercel project
vercel link

# Add environment variables (you'll be prompted for each value + environment)
vercel env add SUPABASE_URL
vercel env add SUPABASE_ANON_KEY

# Deploy to production
vercel --prod
```

`vercel.json` rewrites `/` to `/Mashriq-Editions.html` so the site loads at the
root, and applies baseline security headers.

## 4. Future steps

- **Higgsfield media**: add `HIGGSFIELD_API_KEY` (via `vercel env add`) when
  wiring up generated imagery.
- **Stripe checkout**: add `STRIPE_PUBLISHABLE_KEY` and `STRIPE_SECRET_KEY` when
  enabling payments.
