# Lurc workspace format

A portable Lurc workspace lives in a `.lurc/` directory inside a project.
Version 1 uses JSON and keeps the format independent from Flutter UI.

```text
.lurc/
  workspace.json
  requests.json
  collections.json
  environments.json
```

`workspace.json` contains `{"version":1,"name":"..."}`. Requests and
collections use the same JSON records as Lurc's local models. Environment
records contain variable keys and a `secret` marker, but **secret values are
never written to the workspace**. A secret variable is serialized with an empty
value and must be supplied locally on each device.

App-local history, active-environment selection, and private secret values are
not workspace data.

Opening a workspace reads it in place through a format adapter. Importing is a
different operation: it converts another format into Lurc data. Future adapters
must implement the adapter contract without requiring request UI changes.
