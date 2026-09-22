# Adding a workspace format

Lurc keeps external file formats behind workspace adapters so the request UI does not need format-specific logic.

An adapter translates between an external representation and Lurc's neutral workspace model.

## Adapter responsibilities

A workspace adapter should handle the parts of the format it owns:

- detect whether a directory or file belongs to that format
- read and validate the format
- convert it into Lurc's workspace model
- write the format when writing is supported
- preserve unknown data where practical instead of silently discarding it

Adapters live under `lib/core/workspaces/` and implement the workspace adapter contract used by the core.

## Adding support

Add the adapter, then include representative fixtures and tests for detection, valid input, invalid input, and round-trip behavior where writing is supported.

Keep parsing and serialization inside the adapter. Flutter screens should consume Lurc models rather than importing external-format types directly.

If an external format has concepts Lurc does not understand, prefer adapter-specific preservation over adding fields to the core model. Add something to the core only when it represents a concept Lurc itself needs.

## Secrets

Do not copy secret values into portable workspace files unless the format explicitly requires it and the user has deliberately chosen that behavior.

For native Lurc workspaces, secret values remain device-local and are not written into `.lurc/`.
