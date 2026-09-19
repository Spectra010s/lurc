# Adding a workspace format

Implement `WorkspaceAdapter` under `lib/core/workspaces/`. Keep parsing and
serialization in the adapter: Flutter screens must only consume
`LurcWorkspace`.

Provide fixtures for valid and invalid workspaces and tests for detection,
reading, validation, and writing if the format supports writing. Preserve data
you do not understand where practical rather than silently destroying it.

External formats should get their own adapter and compatibility issue. Do not
add format-specific fields to the core model unless they represent a concept
Lurc itself needs.
