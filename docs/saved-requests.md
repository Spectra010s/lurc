# Saved requests and collections

Lurc can keep requests you want to reuse instead of rebuilding them every time.

## Saving a request

A saved request keeps the request method, URL, query parameters, headers, body, and body type. Saving a request does not send it.

Saved requests can be reopened in the request workspace, edited, and sent again.

## Collections

Collections are folders for organizing saved requests. A request can belong to one collection or remain unfiled.

Renaming a collection keeps its requests in place. Deleting a collection does not delete the requests inside it; those requests become unfiled instead.

## What is stored locally

Saved requests and collections are stored on the device as Lurc application data.

This storage is intended for normal API-client state, not as a secure secrets vault. If a saved request contains sensitive headers, tokens, or request-body values, those values remain part of the local saved request.

Uninstalling Lurc removes its app-private local data unless Android restores it through a platform backup mechanism.
