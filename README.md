<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/branding/lurc-banner-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="docs/branding/lurc-banner-light.svg">
    <img alt="Lurc — API client for your phone" src="docs/branding/lurc-banner-light.svg" width="720">
  </picture>
</p>

<p align="center">
  <a href="https://github.com/Spectra010s/lurc/actions/workflows/android.yml">
    <img alt="Android build" src="https://github.com/Spectra010s/lurc/actions/workflows/android.yml/badge.svg">
  </a>
</p>

Lurc is a local-first Android API client for building, sending, inspecting, saving, and revisiting HTTP requests directly from your phone.

Requests are sent from your device through Dio. Lurc does not proxy them through a remote backend.

## Features

- GET, POST, PUT, PATCH, and DELETE requests
- Query parameters and custom headers
- JSON and text request bodies
- Response status, timing, headers, and formatted body inspection
- Local request history with reopen and resend flows
- Saved requests and collections
- Environments and variable resolution across URLs, query parameters, headers, and bodies
- Light and dark themes
- Native Android launcher icon and splash screen
- Signed Android release builds

## Install

Android releases are published on the [GitHub Releases](https://github.com/Spectra010s/lurc/releases) page.

Choose the APK that matches your device:

- **ARM64** — recommended for most modern Android phones
- **ARMv7** — older 32-bit ARM devices
- **x86_64** — x86_64 Android devices and emulators
- **Universal** — works across supported Android architectures, but is larger

An Android App Bundle is also produced for store distribution.

> Android may warn before installing an APK downloaded outside an app store. Verify that the APK came from this repository's Releases page before installing it.

## Authentication

Lurc can already send authenticated requests through custom headers. For example:

```text
Authorization: Bearer <token>
```

Dedicated authentication presets such as Bearer Token, Basic Auth, and API Key are not included yet.

## Local-first by design

Lurc keeps request data on your device and sends requests directly to the target API.

Request history, saved requests, environments, and preferences are stored in the app's local Android data. Request history is capped at 100 entries and does not persist response bodies.

HTTP endpoints are supported intentionally for local development and API testing. Prefer HTTPS when sending sensitive data.

## Development

Lurc currently targets Flutter 3.47.3 and Dart 3.13.3.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Android CI runs static analysis and tests before build artifacts are accepted.

For local release signing, see [docs/android-release.md](docs/android-release.md).

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
```

## Contributing

Open an issue before starting larger changes so the work can stay focused and easy to review.

For smaller fixes, a focused pull request is welcome.

## Tech

Flutter · Dart · Riverpod · Dio · SharedPreferences · Android
