# workers
### An in-memory registry that maps TCP ports to running `4D.SystemWorker` instances.

> workers.new ()

No parameters.

## Description

`cs.workers.workers` is a collection-backed registry. One shared instance (`__WORKER__`) is kept inside the `".workers"` named worker process, and it is only accessed through [`worker`](worker.md). Application code does not create or call `workers` directly.

The shared instance is created lazily, the first time a request reaches the `".workers"` worker.

There is at most one entry per port. Each entry is an object:

| Property | Type | Description |
| --- | --- | --- |
| port | Integer | The TCP port (1–65535) |
| worker | 4D.SystemWorker | The server process |
| class | 4D.Class | The class that started the server |
| instance | Object | The instance of `class` whose `start` returned the worker |
| token | Text | Identifies the `start` call that registered the entry, for its startup check |

Processes that were asked to terminate but had not exited yet are kept in a second collection, `stopping`, until they exit.

Classes are compared by name, plus an `OB Instance of` check on `instance`, because 4D 20.x cannot compare class references with `=`.

### Methods

| Method | Description |
| --- | --- |
| find (port) → 4D.SystemWorker | The worker registered for `port`, or `Null` (also `Null` for an invalid port) |
| entry (port) → Object | The entry registered for `port`, or `Null` |
| isAlive (entry) → Boolean | `True` if `entry` holds a `4D.SystemWorker` that is not terminated |
| owns (entry; class) → Boolean | `True` if `entry` was registered by `class` |
| unwrap (result) → 4D.SystemWorker | `result` if it is a `4D.SystemWorker`, its `worker` property if that is one, otherwise `Null` |
| dispose (result) | Calls `result.terminate()` if it exists. Used for results that cannot be registered |
| insert (port; worker; class; instance; token) | Adds an entry. Does nothing if the port is invalid, `worker` is not a `4D.SystemWorker`, or the port already has an entry (call `remove` first) |
| retire (entry) | Calls `terminate()` on the entry's worker if it is still running, and adds the entry to `stopping`. Does not remove it from the registry |
| stalled (port) → Boolean | `True` if a process on `port` is in `stopping` and has not exited yet |
| reap (class; port) → Integer | Forgets the processes in `stopping` that have exited, and returns how many of `class` (on `port`, or any port if `port` is `0`) are still running |
| remove (port) | Removes the entry for `port`, if any |

## See also

- [`worker`](worker.md): the coordinator that owns the shared `workers` instance and gates all access to it
