# Android release checklist

Lurc's Android release builds are signed with the project release keystore and produced by GitHub Actions.

## Release inputs

Repository Actions secrets:

- `LURC_KEYSTORE_BASE64`
- `LURC_KEYSTORE_PASSWORD`
- `LURC_KEY_ALIAS`
- `LURC_KEY_PASSWORD`

The release keystore itself must never be committed. Keep at least one private backup outside the development device.

## Android review

Lurc currently requests only `android.permission.INTERNET`.

`android:usesCleartextTraffic="true"` is intentional. Lurc is an API client and must be able to call local-development and explicitly HTTP endpoints as well as HTTPS endpoints. Users should prefer HTTPS for sensitive traffic.

No storage, contacts, camera, microphone, location, or notification permission is required by the current feature set.

## Local storage review

History, saved requests, environments, and preferences are stored locally through `shared_preferences`.

Request history:

- is stored under the `request_history_v1` preferences key;
- retains at most 100 request records;
- stores request method, URL, headers, query parameters, request body, status code, and duration;
- does not persist response bodies.

Saved requests and environments are also persisted as JSON-backed preference values. This data is app-private on Android but is not an encrypted secrets store. Sensitive headers, request bodies, and environment values should therefore be treated as local application data rather than hardware-backed secret storage.

## Before tagging

1. Confirm `flutter analyze` passes.
2. Confirm `flutter test` passes.
3. Confirm the signed ARM64 release APK installs and launches on a physical Android device.
4. Send a request and verify response rendering.
5. Verify history, saved requests/collections, environments, and theme switching.
6. Confirm the version in `pubspec.yaml` matches the intended tag.
7. Confirm the release workflow contains no temporary development-branch trigger.
8. Tag the merged commit as `v<version>`, for example `v0.1.0`.

The tag-triggered release workflow produces separate universal, ARM64, ARMv7, and x86_64 APK artifacts, an Android App Bundle, and SHA-256 checksums.
