# worker
### Launches and terminates a server process through a named 4D worker.

> worker.new (class : 4D.Class)

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| class | 4D.Class | -> | The server class to instantiate and manage |

## Description

`cs.workers.worker` is a thin coordinator that routes `start`, `terminate`, and `isRunning` calls through a named 4D worker process identified by the signal description `".workers"`. All three methods are synchronous from the caller's perspective — each creates a `4D.Signal`, dispatches via `CALL WORKER`, and blocks on `signal.wait()` until the worker thread completes the operation.

This ensures that the shared [`workers`](workers.md) registry is always mutated from a single worker context, preventing race conditions when multiple callers start or stop servers concurrently.

### Properties

| Property | Type | Description |
| --- | --- | --- |
| class | 4D.Class | The server class passed to the constructor |

### Methods

#### start (port : Integer; option : Object)

Dispatches a start request to the `.workers` named worker. If a non-terminated `4D.SystemWorker` is already registered for `port` the call is a no-op. Otherwise it instantiates `class`, calls `.start(option)` on it, and registers the resulting worker in the `workers` registry.

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| port | Integer | -> | Port the server should listen on |
| option | Object | -> | Options forwarded to the class's `start` method |

Returns immediately if `option` is `Null` or not an object.

#### terminate ()

Dispatches a terminate request to the `.workers` named worker, shutting down the managed server process.

#### isRunning (port : Integer) → Boolean

Checks whether a live (non-terminated) `4D.SystemWorker` is registered for `port`. The boolean result is returned via `signal.isRunning` after the worker thread completes the check.

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| port | Integer | -> | Port to query |
| Result | Boolean | <- | `True` if a running worker is registered for that port |

## See also

- [`workers`](workers.md) — the registry that tracks port → SystemWorker mappings
