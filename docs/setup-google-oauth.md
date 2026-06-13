# Google OAuth + Supabase Setup Guide

This guide walks a new developer through every manual step required to run the
`saa` app with Google Sign-In and Supabase authentication.

---

## Prerequisites

- Xcode 15+
- A Google Cloud account with permission to create OAuth credentials
- Access to the Supabase project (or ability to run `supabase start` locally)

---

## Part 1 — Google Cloud: Create an iOS OAuth Client

> **Joining an existing team?** Ask a teammate for the `GoogleService-Info.plist`
> and the `REVERSED_CLIENT_ID` value for `saa/Info.plist`, then jump to **Part 2**.
> The Google Cloud project + OAuth consent screen are already configured for the
> `saa` app — you only need to do Part 1 if you're bootstrapping from scratch
> or if your org's policy requires each developer to own their own iOS OAuth
> client ID.

1. Open [Google Cloud Console](https://console.cloud.google.com/) and select
   the project for this app. (Create a new one only if no project exists yet.)

2. _**(One-time per project — skip if the project already has a consent screen.)**_
   Navigate to **APIs & Services → OAuth consent screen**.
   - User type: **External** (any Google account can sign in).
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

2. **Populate `.env` at the repo root** so local Supabase (`supabase start`)
   picks up the Google OAuth values referenced by `supabase/config.toml`. Copy
   the template and edit it:
   ```bash
   cp .env.example .env
   ```
   Then fill in the two Google values:
   ```
   GOOGLE_CLIENT_ID=<CLIENT_ID from saa/GoogleService-Info.plist>
   GOOGLE_CLIENT_SECRET=unused-for-ios-id-token-flow
   ```
   > **Why this matters (and what fails if you skip it):** `supabase/config.toml`
   > references `env(GOOGLE_CLIENT_ID)`. If `.env` still contains the placeholder
   > `your_google_client_id`, GoTrue boots with that literal string as its
   > expected `aud`. The iOS ID token's real `aud` (your `CLIENT_ID` from
   > `GoogleService-Info.plist`) will never match → step 4 of the sign-in flow
   > fails with `400 Bad ID token` and the UI shows a generic error.
   >
   > The iOS `CLIENT_ID` is **not** a secret — it's embedded in the shipped app
   > bundle. `GOOGLE_CLIENT_SECRET` is required by config syntax but unused by
   > the native `signInWithIdToken` flow, so any non-empty value works.
   >
   > `.env` is gitignored — never commit it.

3. Start the local Supabase stack from the repo root:
   ```bash
   supabase start
   ```
   > If you edit `.env` after the stack is already running, restart it so GoTrue
   > picks up the new values: `supabase stop && supabase start`.

4. Copy the printed **API URL** and **anon key** (also available any time via
   `supabase status`).

5. Copy the xcconfig example to your local debug config:
   ```bash
   cp saa/Configuration/Sample.xcconfig.example saa/Configuration/Debug.xcconfig
   ```

6. Open `saa/Configuration/Debug.xcconfig` and fill in the values:
   ```
   SUPABASE_URL = http:/$()/127.0.0.1:54321
   SUPABASE_ANON_KEY = <anon key from supabase status>
   ```
   > `Debug.xcconfig` is gitignored — never commit it.

   > **xcconfig URL note:** Double-slash (`//`) is a comment in xcconfig, so the
   > `://` in a URL must be broken with `$()`. The sample file explains this —
   > `http:/$()/127.0.0.1:54321` resolves correctly at build time.

---

## Part 3 — Supabase: Remote Project _(optional — release/production only)_

> **Skip this whole section** if you only need local Google sign-in to work.
> Local dev (Part 2) is fully self-contained: GoTrue runs in Docker, reads
> `.env`, validates real Google ID tokens against your iOS client ID, and
> issues real Supabase sessions. No remote project, no `Release.xcconfig`,
> no dashboard changes needed.
>
> Do this section only when you're ready to ship a Release build pointing at
> a hosted Supabase project.

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

## Part 5 — Enable Google Sign-In in Supabase _(optional — remote project only)_

> **Skip this section for local dev.** Local GoTrue already picks up the
> Google provider from `supabase/config.toml` + `.env` (Part 2). The
> dashboard does not exist for local Supabase.
>
> **No Web OAuth client is required for this app.** `AuthService` uses
> `signInWithIdToken` with a token minted by the native iOS Google SDK, so
> GoTrue only needs the iOS `CLIENT_ID` configured as an allowed audience
> (which Part 2 already does via `GOOGLE_CLIENT_ID` in `.env`). A
> Web-application OAuth client and client secret are only needed if you
> later add a server-side redirect flow.

Only when configuring the remote Supabase project (Part 3):

1. In the Supabase dashboard, go to **Authentication → Providers → Google**.
2. Toggle **Enable Sign in with Google**.
3. Under **Authorized Client IDs**, paste the iOS `CLIENT_ID` from
   `saa/GoogleService-Info.plist` (the same value you put into local `.env`).
4. Leave the main **Client ID** / **Client Secret** fields blank unless you
   also want to support the web/server-side OAuth redirect flow.
5. Save.

---

## Verification Checklist

**Local dev (minimum to make Google sign-in work):**

- [ ] `GoogleService-Info.plist` present in `saa/` (not committed)
- [ ] `saa/Info.plist` has `REVERSED_CLIENT_ID` URL scheme set correctly
- [ ] `.env` at repo root has real `GOOGLE_CLIENT_ID` (iOS client ID from `GoogleService-Info.plist`)
- [ ] `saa/Configuration/Debug.xcconfig` has `SUPABASE_URL = http:/$()/127.0.0.1:54321` + local `SUPABASE_ANON_KEY`
- [ ] Xcode target uses custom `INFOPLIST_FILE = saa/Info.plist` (not `GENERATE_INFOPLIST_FILE`)
- [ ] Both SPM packages resolved (supabase-swift ≥ 2.5, GoogleSignIn-iOS ≥ 7.0)
- [ ] `supabase start` running
- [ ] `git status` shows no `.xcconfig`, `.env`, or `.plist` secret files staged

> To run the unit test suite and generate a coverage report locally or via CI, see [docs/ci-coverage.md](ci-coverage.md).

**Release / production (only when shipping):**

- [ ] Remote Supabase project created (Part 3)
- [ ] `saa/Configuration/Release.xcconfig` has remote `SUPABASE_URL` + `SUPABASE_ANON_KEY`
- [ ] Migrations pushed to remote (`supabase db push`)
- [ ] Remote Google provider has iOS `CLIENT_ID` in Authorized Client IDs (Part 5)
