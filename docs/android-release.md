# Android releases

Lurc publishes signed Android builds from GitHub Actions.

A release is triggered by pushing a version tag that matches `v*`. The release workflow builds the Android packages, computes checksums, and publishes the resulting files to a GitHub Release.

## Release artifacts

Each tagged release produces:

- `lurc-arm64-v8a.apk` for most modern Android phones
- `lurc-armeabi-v7a.apk` for older 32-bit ARM devices
- `lurc-x86_64.apk` for x86_64 Android devices and emulators
- `lurc-universal.apk` as an architecture-independent fallback
- `lurc-release.aab` for store distribution
- `SHA256SUMS.txt` containing the SHA-256 checksum of every release artifact

GitHub Actions also keeps the build outputs as workflow artifacts.

## Signing

Release builds are signed with Lurc's Android release key. The key itself is never committed to the repository.

The workflow reads these repository secrets:

- `LURC_KEYSTORE_BASE64`
- `LURC_KEYSTORE_PASSWORD`
- `LURC_KEY_ALIAS`
- `LURC_KEY_PASSWORD`

`LURC_KEYSTORE_BASE64` is simply the release keystore encoded as Base64 so GitHub Actions can reconstruct the binary file during a build. The original keystore must be kept in a secure private backup. Losing it would prevent future builds from updating existing installations signed with that key.

For local signing, copy `android/key.properties.example` to `android/key.properties` and fill in the local values. Neither the keystore nor `key.properties` should be committed.

## Publishing a release

Before creating a version tag, make sure the version in `pubspec.yaml` is the version being released and that the current main branch has passed CI.

Create and push the tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The tag starts `.github/workflows/release-android.yml`. The workflow runs analysis and tests, builds the signed APKs and AAB, generates checksums, and creates the GitHub Release with generated release notes and the files attached.

If the workflow fails, fix the failure before recreating or moving the release tag.

## Android networking

Lurc requests only the Android Internet permission.

Cleartext HTTP traffic is intentionally allowed because an API client must be able to reach local-development and explicitly HTTP endpoints. HTTPS should still be used for sensitive traffic.
