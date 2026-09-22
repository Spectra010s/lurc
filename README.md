<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/branding/lurc-banner-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="docs/branding/lurc-banner-light.svg">
    <img alt="Lurc — API client for your phone" src="docs/branding/lurc-banner-light.svg" width="720">
  </picture>
</p>

Lurc is a local-first Android API client built for developers who want to build, send, inspect, save, and revisit HTTP requests directly from a phone.

Requests are sent from the device through Dio; Lurc does not proxy them through a remote backend.

## Current features

- GET, POST, PUT, PATCH, and DELETE requests.
- Query parameters and request headers.
- JSON/text request bodies.
- Response status, timing, headers, and formatted body inspection.
- Local request history with reopen/resend flows.
- Saved requests and collections.
- Environments and variable resolution across URLs, query parameters, headers, and bodies.
- Light/dark theme support with Lurc branding.
- Native Android launcher icon and splash screen.

## Status

Lurc v0.1.0 is the first public Android release. Core request, history, collection, environment, and mobile workspace flows are implemented, and active development continues with authentication and broader API-client capabilities next.

## Architecture

```text
Flutter UI
    |
Riverpod application state
    |
HTTP core
    |
Dio
    |
Android networking
    |
Internet / local network
```

Lurc is intentionally local-first: request data and HTTP traffic stay on the device unless the user explicitly sends data to the target API.

## Development

Lurc currently targets Flutter 3.47.3 and Dart 3.13.3.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Android CI runs analysis and tests before producing build artifacts.

## Contributing

Work should normally start from a GitHub issue and land through a focused pull request. Keep unrelated fixes separate when practical so changes remain reviewable and the roadmap stays clear.

## Tech

- Flutter
- Dart
- Riverpod
- Dio
- SharedPreferences
- Very Good Analysis
- Android
