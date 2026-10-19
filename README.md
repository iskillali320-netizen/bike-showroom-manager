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

## Using the app
- **Sign-in screens:** Continue with Google, sign in, create account (with email confirmation), forgot password and set a new password. Errors are shown next to the field that needs fixing.
- **Sections (left menu, or the menu button on phones):** Overview, Stock, Sales & invoices, Payments, Dealers & customers, Instalments, Reports, FBR / Tax, Settings.
- **Search everything:** press Ctrl+K (or the Search button) and type a chassis/engine number, invoice number, name, phone or CNIC.
- **Print:** invoices (with amount in words), payment receipts, customer statements and daily/monthly summaries.
- **Reports:** daily summary and monthly day-by-day totals. *Gross profit* = sales before tax − purchase cost of bikes sold; expenses are not recorded yet, so it is not net profit.
- **Edit:** bikes (sold bikes: only cost and challan) and contacts (old invoices keep the details they were printed with).
- Deleting a bike, payment, invoice, contact or team member always asks for confirmation, and only the owner can do it.

## Google sign-in (setup)
The app has a **Continue with Google** button. It works once Google is enabled in Supabase:

1. **Google Cloud Console** (console.cloud.google.com) → create or select a project.
2. **Google Auth Platform / OAuth consent screen:** User type *External*; app name *Bike Showroom Manager*; your support email; add `supabase.co` and `github.io` under authorized domains if asked; scopes `openid`, `email`, `profile`. Publish the app (in *Testing* mode only listed test users can sign in).
3. **Clients / Credentials → Create OAuth client ID → Web application**
   - Authorized JavaScript origins: `https://iskillali320-netizen.github.io`
   - Authorized redirect URIs: `https://jebszemeaycpkwzgznov.supabase.co/auth/v1/callback`
   - Copy the **Client ID** and **Client secret**.
4. **Supabase → Authentication → Sign In / Providers → Google:** turn it on, paste the Client ID and Client secret, save. The client secret stays in Supabase; never put it in this repository.
5. **Supabase → Authentication → URL Configuration:** Site URL `https://iskillali320-netizen.github.io/bike-showroom-manager/`, and add the same address under Redirect URLs.

A Google account with the same email as an existing email/password account signs in to that same account.

## Emails and staff invitations (setup)
Supabase's built-in email service only delivers to members of your Supabase project team and only a few emails per hour. Confirmation, password-reset and invitation emails to anyone else fail with "Email address not authorized". For real use:

1. **Supabase → Authentication → Emails → SMTP Settings:** enable custom SMTP with an email provider (for example Brevo, Resend, SendGrid or Amazon SES), using a sender address on a domain you control.
2. **Authentication → Emails → Templates:** optionally edit *Magic Link* and *Confirm signup* (these are what invited staff receive) to say "You've been invited to Bike Showroom Manager".
3. **Authentication → Rate Limits:** raise the email limit if you invite many people.

How invitations work: the owner adds an email under **Settings → Team**. The app saves the invitation and emails that address a sign-in link. When the person opens it (or signs up, or uses Google with the same address), the database adds them to that showroom only. This happens only if a matching, unexpired invitation exists and the email is confirmed. Invitations expire after 14 days; the owner can resend or renew them. Staff can set a password later under **Settings → Your account**.

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
