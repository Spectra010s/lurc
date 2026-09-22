# Lurc workspace format

A Lurc workspace is a portable project representation that can live beside source code and be version-controlled with normal Git tooling.

A workspace uses a `.lurc/` directory:

```text
.lurc/
  workspace.json
  requests.json
  collections.json
  environments.json
```

The current format version is **1**.

## `workspace.json`

Describes the workspace itself.

```json
{
  "version": 1,
  "name": "Example API"
}
```

The `version` field identifies the workspace schema version. Readers should reject unsupported versions instead of silently interpreting them as a different format.

## Requests and collections

`requests.json` contains the requests saved in the workspace. `collections.json` contains the collections used to organize them.

Workspace requests preserve the same request information Lurc needs to reopen and send them: method, URL, query parameters, headers, body, and body type.

## Environments and secrets

`environments.json` contains workspace environment definitions.

Environment entries may identify a variable as secret, but secret values are not written into the portable workspace. A secret is serialized without its private value and must be supplied locally on each device.

This keeps a version-controlled workspace from becoming a place where API tokens or other credentials are accidentally committed.

## Local state versus workspace state

A workspace is portable project data. It does not contain every piece of Lurc's app-local state.

Request history, the currently selected environment, and locally supplied secret values remain local to the app.

## Opening and importing

Opening a native Lurc workspace reads the project in place.

Importing another format is different: an adapter converts that external representation into Lurc's neutral workspace model. This distinction allows Lurc to support other API-client formats without coupling the request UI to any one of them.
