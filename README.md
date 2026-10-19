# Bike Showroom Manager

Online software for motorcycle showrooms: stock received from the factory, bikes given to dealers and sold to customers, sales tax invoices with FBR invoice numbers, money received, pending balances, instalments and a monthly FBR sales report.

- **Website:** plain HTML/JS (`index.html`), hosted free on GitHub Pages.
- **Database and logins:** [Supabase](https://supabase.com) (Postgres). Every showroom has its own account and can only see its own data (Row Level Security in `supabase/schema.sql`).
- **Roles:** *Owner* can do everything, including delete, business details and team. *Staff* can add stock, parties, invoices and payments.

## One-time setup

### 1. Database (Supabase)
1. Create a project at supabase.com (region: Singapore).
2. Open **SQL Editor → New query**, paste all of `supabase/schema.sql`, click **Run**. Run it again whenever `schema.sql` is updated in this repo; it is safe to re-run and does not delete data.
3. **Authentication → URL Configuration**: set **Site URL** to your website address (step 3 below), e.g. `https://YOUR-USERNAME.github.io/bike-showroom-manager/`, and add the same address under **Redirect URLs**.
4. **Project Settings → API**: copy the **Project URL** and the **publishable** (or legacy *anon public*) key into `config.js`. Never put the *secret* / *service_role* key or the database password in this repo.
5. **Authentication → Sign In / Providers → Email**: keep **Confirm email** turned on. Staff invites only work for confirmed emails.

### 2. Website (GitHub Pages)
1. In the GitHub repository: **Settings → Pages**.
2. Source: **Deploy from a branch**, Branch: `main`, folder `/ (root)` → **Save**.
3. After about a minute the site is live at `https://YOUR-USERNAME.github.io/bike-showroom-manager/`.

### 3. First use
1. Open the website → **Create an account** → confirm the email.
2. Sign in → enter the showroom name → the first account becomes the **Owner**.
3. Settings → fill business name, NTN, STRN, tax rate. Add staff under **Team**.

## Adding a new showroom (customer)
Each customer opens the same website, creates an account and creates their own showroom. Their data is separate from everyone else's.

## FBR Digital Invoicing (next phase)
Sending invoices to FBR needs, per showroom: sales tax registration (NTN/STRN), integration through a licensed integrator (PRAL is free), sandbox testing, then a production token. The token must be kept on the server (a Supabase Edge Function), never in `index.html`. Until then, invoices have a field for the FBR invoice number and the FBR / Tax tab exports the monthly sales data.

## Files
- `index.html` — the whole app
- `config.js` — Supabase address and public key
- `supabase/schema.sql` — tables, security rules and functions

## Before selling to customers
- Supabase **free plan** pauses a project after a week with no activity and has no automatic daily backups. Move to the **Pro plan** before real customers rely on it.
- Add your own domain (e.g. `yourapp.pk`) in GitHub Pages settings and in Supabase Site URL.
