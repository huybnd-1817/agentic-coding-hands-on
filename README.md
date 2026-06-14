# agentic-coding-hands-on

iOS app (SwiftUI, iOS 16+) demonstrating Google OAuth sign-in via Supabase, with Sun* domain restriction enforced by a Postgres trigger. See [docs/setup-google-oauth.md](docs/setup-google-oauth.md) to get started.

## Architecture

Feature-sliced Pragmatic 3-layer Clean Architecture (`Presentation` / `Domain` / `Data`). Domain is `Foundation`-only; SDK code is confined to Data. See [docs/system-architecture.md](docs/system-architecture.md) for layer rules and [docs/code-standards.md](docs/code-standards.md) for conventions.