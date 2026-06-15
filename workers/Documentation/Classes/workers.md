# workers
### An in-memory registry that maps TCP ports to active `4D.SystemWorker` instances.

> workers.new ()

No parameters.

## Description

`cs.workers.workers` is a collection-backed registry. One shared instance (`__WORKER__`) is maintained inside the `.workers` named worker process and accessed exclusively through [`worker`](worker.md). Application code does not instantiate or call `workers` directly.

Each entry in the internal collection is an object with two properties:

| Property | Type | Description |
| --- | --- | --- |
| port | Integer | The TCP port the server is listening on |
| worker | 4D.SystemWorker | The associated system worker process |

The shared instance is lazily initialized — it is created the first time `worker.start` is called inside the named worker context.

### Properties

| Property | Type | Description |
| --- | --- | --- |
| workers | Collection | Collection of `{port, worker}` entries |

### Methods

#### find (port : Integer) → 4D.SystemWorker

Returns the `4D.SystemWorker` registered for `port`, or `Null` if none exists. Returns `Null` immediately for invalid port values (`≤ 0` or `> 65535`).

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| port | Integer | -> | Port to look up |
| Result | 4D.SystemWorker | <- | Registered worker, or `Null` |

#### insert (port : Integer; worker : 4D.SystemWorker)

Adds a `{port, worker}` entry to the registry. If an entry for `port` already exists the call is a no-op — no duplicate entries are created.

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| port | Integer | -> | Port to register |
| worker | 4D.SystemWorker | -> | Worker to associate with the port |

#### remove (port : Integer)

Removes the entry for `port` from the registry. If no entry exists the call is a no-op.

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| port | Integer | -> | Port whose entry should be removed |

## See also

- [`worker`](worker.md) — the coordinator that owns the shared `workers` instance and gates all access to it
