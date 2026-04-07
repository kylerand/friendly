# Friendly Admin Portal (Web)

React + Vite admin portal for managing users, connections, and admin access.

## Local development

```bash
cd web
npm install
npm run dev
```

Create a `.env.local`:

```
VITE_SUPABASE_URL=your-supabase-url
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key
VITE_ADMIN_API_URL=http://localhost:8000
```

The portal expects an authenticated Supabase session and verifies access via
`/tester/me` on the backend. Access is granted for admins (`admin_users`) and
pilot/tester users (`user_roles`).

## Admin access

Admins are defined in the `public.admin_users` table (see Supabase migrations).
Pilot/tester users are defined in `public.user_roles` with `pilot` or `tester`.
Add rows with the user ID to grant access.

## Vercel

Deploy with the Vercel root set to `web/`. Configure the same environment
variables in the Vercel dashboard.
