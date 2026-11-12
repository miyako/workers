# worker
### Launches and terminates server processes through a named 4D worker.

> worker.new (class : 4D.Class)

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| class | 4D.Class | -> | The server class to instantiate and manage |

## Description

`cs.workers.worker` is a thin coordinator that routes `start`, `terminate`, and `isRunning` calls to a named 4D worker process, `".workers"`. Each call creates a `4D.Signal`, dispatches the request with `CALL WORKER`, and waits on the signal for at most `timeout` seconds.

The shared [`workers`](workers.md) registry is only modified from that single worker, so there are no race conditions when several callers start or stop servers at the same time.

The server class must have a `start(option : Object)` function. It must return either a `4D.SystemWorker` or an object whose `worker` property is a `4D.SystemWorker`.

Every server is registered under its port, together with the class that started it. Each `worker` instance only sees and controls the servers of its own class.

### Properties

| Property | Type | Description |
| --- | --- | --- |
| class | 4D.Class | The server class passed to the constructor |
| timeout | Real | Maximum number of seconds to wait for the `".workers"` worker (default `60`) |
| errors | Collection | Errors from the last call (empty when it succeeded) |
| owner | Text | Name of the other class that holds the port, after a conflict in `start`, `isRunning` or `terminate(port)` |

### Methods

#### start (port : Integer; option : Object) → Boolean

Starts a server on `port` by instantiating `class` and calling `.start(option)` on the instance. The resulting `4D.SystemWorker` is registered for `port`.

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| port | Integer | -> | Port the server should listen on (1–65535) |
| option | Object | -> | Options forwarded to the class's `start` function |
| Result | Boolean | <- | `True` if a server of this class is registered and running for `port` |

- If this class already has a running server on `port`, the call does nothing and returns `True`.
- If another class holds `port`, nothing is launched. The call returns `False`, sets `owner`, and reports error `-5`.
- If the class's `start` returns anything other than a `4D.SystemWorker` (or a wrapper with a `worker` property), the result is not registered. If the result has a `terminate()` function, it is called so that nothing leaks. The call returns `False` with error `-3`.
- `True` means the process was launched. It does not mean the server has bound its port.

#### terminate ({port : Integer}) → Boolean

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| port | Integer | -> | Optional. Port of the server to terminate |
| Result | Boolean | <- | `True` if no error occurred |

- Without a parameter, terminates every server started by **this class**. Servers of other classes are left running. *(Behaviour change: versions up to 20.0.20 terminated every registered server, whatever its class.)*
- With `port`, terminates the server on that port, but only if this class owns it. Otherwise it returns `False`, sets `owner`, and reports error `-5`.
- Terminating a port with no registered server, or calling it before any `start`, does nothing and returns `True`.
- `4D.SystemWorker.terminate()` is asynchronous, so the process may still hold its port for a short time after the call returns.

#### isRunning (port : Integer) → Boolean

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| port | Integer | -> | Port to query |
| Result | Boolean | <- | `True` if a running server started by this class is registered for `port` |

If another class holds the port, returns `False` and sets `owner`.

### Errors

Each call clears `errors` and fills it when something fails. Elements have the same shape as `Last errors` (`errCode`, `message`, `componentSignature`). Errors raised inside the server class are included as reported by 4D.

| errCode | Meaning |
| --- | --- |
| -1 | Timed out waiting for the `".workers"` worker (see `timeout`) |
| -2 | The request was aborted by an error that no handler caught (typically an error in the server class) |
| -3 | The server class's `start` did not return a `4D.SystemWorker` |
| -4 | Invalid port (must be 1–65535) |
| -5 | The port is held by another class (see `owner`) |
| -6 | `class` is not a `4D.Class` |
| -7 | `option` is not an object |

Notes:

- An error raised inside the server class cannot be trapped by the component's error handler. It aborts the request in the worker, and the call returns `False` with error `-2`. In headless or server mode, 4D may also end the `".workers"` process, which terminates the servers it owns.
- After a timeout (`-1`), the request may still complete later in the worker.
- Calls made from inside the `".workers"` process run directly instead of being dispatched, so there is no deadlock. This covers a server class's `start` and `4D.SystemWorker` callbacks such as `onTerminate`.

## Examples

```4d
var $w : cs.workers.worker
$w:=cs.workers.worker.new(cs.myApp.myServer)

If (Not($w.isRunning(8080)))
    If (Not($w.start(8080; {option1: "value"})))
        ALERT(JSON Stringify($w.errors))
    End if
End if
```

```4d
var $w : cs.workers.worker
$w:=cs.workers.worker.new(cs.myApp.myServer)
$w.terminate(8080) //this server only
$w.terminate() //every server of cs.myApp.myServer
```

## See also

- [`workers`](workers.md): the registry that tracks port → SystemWorker mappings
