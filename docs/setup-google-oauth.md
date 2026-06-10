# Google OAuth + Supabase Setup Guide

This guide walks a new developer through every manual step required to run the
`saa` app with Google Sign-In and Supabase authentication.

---

## Prerequisites

- Xcode 15+
- A Google account with access to the Sun* Google Cloud organisation
- Access to the Supabase project (or ability to run `supabase start` locally)

---

## Part 1 — Google Cloud: Create an iOS OAuth Client

1. Open [Google Cloud Console](https://console.cloud.google.com/) and select
   (or create) the project for this app under the `sun-asterisk.com` organisation.

2. Navigate to **APIs & Services → OAuth consent screen**.
   - User type: **Internal** (restricts sign-in to `@sun-asterisk.com` accounts automatically).
   - Fill in App name, support email, and developer contact email.
   - Save and continue through Scopes (no extra scopes needed for basic auth).

3. Navigate to **APIs & Services → Credentials → + Create Credentials → OAuth client ID**.
   - Application type: **iOS**
   - Bundle ID: `com.sun-asterisk.saa`
   - Click **Create**.

4. Click the download button (↓) next to your new iOS client to download
   `GoogleService-Info.plist`.

5. In Xcode, drag `GoogleService-Info.plist` into the `saa/` folder in the project
   navigator. Make sure:
   - "Copy items if needed" is **checked**
   - Target membership: `saa` is **checked**

6. Open `saa/Info.plist` in Xcode (or a text editor) and replace
   `com.googleusercontent.apps.REPLACE_WITH_REVERSED_CLIENT_ID` under
   `CFBundleURLTypes → CFBundleURLSchemes` with the value of `REVERSED_CLIENT_ID`
   from your downloaded `GoogleService-Info.plist`.

   Example:
   ```xml
   <string>com.googleusercontent.apps.123456789-abcdefghijklmnop</string>
   ```

> **Note — custom Info.plist is already configured:** `GENERATE_INFOPLIST_FILE = NO`
> and `INFOPLIST_FILE = saa/Info.plist` are already set in `project.pbxproj` for the
> `saa` target. No manual Xcode build-settings change is required. The `saaTests` and
> `saaUITests` targets intentionally remain at `GENERATE_INFOPLIST_FILE = YES` — do
> not change them.

---

## Part 2 — Supabase: Local Development

1. Install the [Supabase CLI](https://supabase.com/docs/guides/cli) if you
   haven't already:
   ```bash
   brew install supabase/tap/supabase
   ```

2. Start the local Supabase stack from the repo root:
   ```bash
   supabase start
   ```

3. Copy the printed **API URL** and **anon key** (also available any time via
   `supabase status`).

4. Copy the xcconfig example to your local debug config:
   ```bash
   cp saa/Configuration/Sample.xcconfig.example saa/Configuration/Debug.xcconfig
   ```

5. Open `saa/Configuration/Debug.xcconfig` and fill in the values:
   ```
   SUPABASE_URL = http:/$()/127.0.0.1:54321
   SUPABASE_ANON_KEY = <anon key from supabase status>
   ```
   > `Debug.xcconfig` is gitignored — never commit it.

   > **xcconfig URL note:** Double-slash (`//`) is a comment in xcconfig, so the
   > `://` in a URL must be broken with `$()`. The sample file explains this —
   > `http:/$()/127.0.0.1:54321` resolves correctly at build time.

---

## Part 3 — Supabase: Remote Project

1. Create a new project at [app.supabase.com](https://app.supabase.com) (or
   use the team project if one already exists).

2. Navigate to **Settings → API**.
   - Copy the **Project URL** (e.g. `https://abc123.supabase.co`)
   - Copy the **anon public** key

3. Copy the xcconfig example to your local release config:
   ```bash
   cp saa/Configuration/Sample.xcconfig.example saa/Configuration/Release.xcconfig
   ```

4. Open `saa/Configuration/Release.xcconfig` and fill in:
   ```
   SUPABASE_URL = https:/$()/abc123.supabase.co
   SUPABASE_ANON_KEY = <anon key from Supabase dashboard>
   ```
   > Same `$()` URL-escaping rule applies for HTTPS — see Part 2 Step 5 note.

5. Apply database migrations to the remote project:
   ```bash
   supabase db push --db-url "postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres"
   ```

---

## Part 4 — Swift Package Dependencies (manual, via Xcode UI)

> **Why manual?** Editing `project.pbxproj` by hand for SPM packages is
> error-prone. Use Xcode's built-in resolver instead.

1. In Xcode, go to **File → Add Package Dependencies…**

2. Add **Supabase Swift SDK**:
   - URL: `https://github.com/supabase/supabase-swift`
   - Dependency rule: **Up to Next Major Version** from `2.5.0`
   - Add to target: `saa`

3. Add **Google Sign-In for iOS**:
   - URL: `https://github.com/google/GoogleSignIn-iOS`
   - Dependency rule: **Up to Next Major Version** from `7.0.0`
   - Add to target: `saa`

4. Wait for Xcode to resolve and download both packages. Verify in
   **Project navigator → Package Dependencies** that both appear.

---

## Part 5 — Enable Google Sign-In in Supabase

1. In the Supabase dashboard, go to **Authentication → Providers → Google**.
2. Toggle **Enable Sign in with Google**.
3. Paste your **Client ID** and **Client Secret** from the Google Cloud OAuth
   client (Web application type — needed for the server-side token exchange).
4. Save.

---

## Verification Checklist

- [ ] `GoogleService-Info.plist` present in `saa/` (not committed)
- [ ] `saa/Info.plist` has `REVERSED_CLIENT_ID` URL scheme set correctly
- [ ] `saa/Configuration/Debug.xcconfig` has real `SUPABASE_URL` + `SUPABASE_ANON_KEY`
- [ ] Xcode target uses custom `INFOPLIST_FILE = saa/Info.plist` (not `GENERATE_INFOPLIST_FILE`)
- [ ] Both SPM packages resolved in Xcode (supabase-swift ≥ 2.5, GoogleSignIn-iOS ≥ 7.0)
- [ ] `supabase start` running (local) or remote project URL accessible
- [ ] `git status` shows no `.xcconfig` or `.plist` secret files staged
