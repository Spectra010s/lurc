# Lurc

Lurc is a native Android API client built for developers who need to inspect, build, send, and revisit HTTP requests directly from a phone.

The project is built with Flutter and Dart. HTTP requests are handled locally on-device; Lurc does not require a remote backend to send requests.

## Status

Lurc is in active early development. The request pipeline works on Android and has been tested against a local HTTP server, but the request workspace, persistence, organization, UI, and release experience still need substantial work.

## Development roadmap

Development is organized into phases. Each phase is tracked by GitHub issues and implemented through focused branches and pull requests. If implementation exposes a separate bug or prerequisite, it should be tracked as a linked issue instead of silently expanding the original task.

### Phase 0 — Foundation and cleanup

- Adopt Riverpod for application and request state management.
- Adopt Very Good Analysis and establish project lint rules.
- Remove the temporary APK installation control project and its CI steps.
- Keep Android CI producing an installable Lurc debug APK.
- Establish the initial Lurc theme and replace temporary/default branding assets.

### Phase 1 — Request workspace

- Refine the method and URL request bar.
- Build a proper query-parameter editor.
- Build a proper request-header editor.
- Add request-body modes, beginning with JSON/text and expanding where useful.
- Improve request validation, loading, cancellation, and error handling.
- Build a useful response viewer for status, timing, headers, and body.
- Add readable JSON formatting and response presentation.

### Phase 2 — History and local persistence

- Persist sent requests locally.
- Build request history.
- Reopen, edit, and resend historical requests.
- Search/filter history and clear individual or all entries.
- Preserve enough response metadata for useful inspection without uncontrolled storage growth.

### Phase 3 — Saved requests and organization

- Save reusable requests.
- Organize saved requests into collections/folders.
- Add environments and variables for reusable values.
- Define import/export behavior for portable request data.

### Phase 4 — Mobile UX and polish

- Finalize Lurc's visual language, colors, typography, spacing, and component states.
- Add the final launcher/adaptive icon from the authoritative Lurc logo.
- Add a native splash screen using the final logo asset.
- Improve keyboard, scrolling, tab switching, editing, and small-screen behavior.
- Add settings and theme preferences where useful.
- Improve empty, loading, success, and failure states throughout the app.

### Phase 5 — Quality and release readiness

- Expand unit and widget tests around request construction, state, persistence, and critical UI flows.
- Add CI analysis/tests alongside Android builds.
- Configure proper Android release signing.
- Produce release APK/AAB artifacts.
- Review performance, storage behavior, permissions, error reporting, and release metadata.

## Current architecture

```text
Flutter UI
    |
request / application state
    |
HTTP core
    |
Dio
    |
Android networking
    |
Internet / local network
```

The architecture will evolve as features are implemented, but Lurc should remain local-first: requests are sent from the device rather than proxied through a Lurc server.

## Contributing / workflow

Work should normally start from a GitHub issue. Keep each implementation focused enough to review in a pull request. When a task reveals a distinct bug, prerequisite, or follow-up, create and link another issue, resolve it separately when appropriate, then return to the phase roadmap.

## Tech

- Flutter
- Dart
- Dio
- Riverpod (planned foundation)
- Android
