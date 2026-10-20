# TapCard — free NFC digital business cards

A mobile-friendly MVP with public NFC links, customer accounts, editable digital profiles, downloadable vCards and a private administrator dashboard.

## Start here (iPad compatible)

1. Download this project's ZIP and unzip it in the iPad Files app.
2. On GitHub, create a repository (e.g. `business-cards`). In Safari, open the repository, tap **Add file → Upload files** and upload the project files. GitHub's web upload may not preserve folders in all browsers; this project keeps source files in the root for easier upload.
3. Create a free Supabase project at https://supabase.com. Open **SQL Editor**, paste `schema.sql`, and run it.
4. In Supabase **Authentication → Providers → Email**, configure email sign-in and verification. Add your eventual Cloudflare website URL to **Authentication → URL Configuration**.
5. In Cloudflare **Workers & Pages → Create → Pages → Connect to Git**, select the GitHub repository. Framework preset: **Vite**. Build command: `npm run build`. Build output directory: `dist`.
6. In Cloudflare project settings, add environment variables `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` using the project URL and public publishable/anon key from Supabase. **Never use a service-role/secret key in browser code.** Redeploy after adding variables.
7. Create your account at `/login`, confirm your email, and create a profile at `/dashboard`.
8. In Supabase SQL Editor, run the admin grant below with YOUR email (do not put this SQL in the GitHub repository with your real email):

```sql
insert into public.admins(user_id)
select id from auth.users where email = 'YOUR_ADMIN_EMAIL'
on conflict do nothing;
```

9. Refresh `/dashboard` to see **Admin tools**. Create a card and assign it to the email of a registered customer who has already created a profile. Copy the generated `/c/TOKEN` URL to NFC Tools → Write → URL/URI. Customers can edit their own profile without rewriting the card.

## Security and deployment notes

- Row-level security prevents customers from editing other accounts. Only a verified admin can create, assign, enable or disable NFC cards.
- Public card/profile endpoints reveal data only when a customer selects **Publish**. Customers should get explicit consent before making phone numbers or email addresses public.
- An NFC card stores only a URL; it cannot be written directly by iPad Safari. Use NFC Tools on a compatible NFC phone or a supported external NFC writer.
- Use a custom domain before mass programming cards, if possible: changing domains later requires rewriting existing cards unless you maintain redirects.
- This is an MVP, not a production-audited commercial service. Before selling at scale add abuse prevention, rate limiting, backups, customer account recovery, legal/privacy notices, tests, and email-delivery configuration.
- The free plans have limits and may change. No payment integration is included.
- Do not commit real customer contact information to a public GitHub repository. This project contains no customer seed data.
