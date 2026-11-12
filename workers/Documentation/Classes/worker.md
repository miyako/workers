# worker
### Launches and terminates server processes through a named 4D worker.

> worker.new (class : 4D.Class)

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| class | 4D.Class | -> | The server class to instantiate and manage |

## Description

`cs.workers.worker` is a thin coordinator that routes `start`, `terminate`, and `isRunning` calls to a named 4D worker process, `".workers"`. Each call creates a `4D.Signal`, dispatches the request with `CALL WORKER`, and waits on the signal for at most `timeout` seconds.

The shared [`workers`](workers.md) registry is only modified from that single worker, so there are no race conditions when several callers start or stop servers at the same time.

The server class must have a `start(option : Object)` function. It must return either a `4D.SystemWorker` or an object whose `worker` property is a `4D.SystemWorker`. It can also have an `isReady(port : Integer) : Boolean` function (see `start`).

`start` and `isRunning` code of the server class runs in the `".workers"` process. In compiled mode that process is preemptive, so this code must be thread-safe. Otherwise `start` returns `False` with the error raised by 4D (for example `-10529`, "Can't call not thread safe method from a preemptive process").

Every server is registered under its port, together with the class that started it. Each `worker` instance only sees and controls the servers of its own class.

### Properties

| Property | Type | Description |
| --- | --- | --- |
| class | 4D.Class | The server class passed to the constructor |
| timeout | Real | Maximum number of seconds a call may take (default `60`). For `start` this includes the startup check, for `terminate` the wait for the processes to exit |
| startupWait | Integer | Milliseconds `start` waits before checking that the new process is still running (default `500`). `option.startupWait` overrides it for one call |
| errors | Collection | Errors from the last call (empty when it succeeded) |
| owner | Text | Name of the other class that holds the port, after a conflict in `start`, `isRunning` or `terminate(port)` |

### Methods

#### start (port : Integer; option : Object) → Boolean

Starts a server on `port` by instantiating `class` and calling `.start(option)` on the instance. The resulting `4D.SystemWorker` is registered for `port`.

The server class receives a copy of `option` with a `port` property set to `port`, unless `option` already has a `port` property. The caller's object is not modified.

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| port | Integer | -> | Port the server should listen on (1–65535) |
| option | Object | -> | Options forwarded to the class's `start` function |
| Result | Boolean | <- | `True` if a server of this class is registered and running for `port` |

- If this class already has a running server on `port`, the call does nothing and returns `True`.
- If another class holds `port`, nothing is launched. The call returns `False`, sets `owner`, and reports error `-5`.
- If the class's `start` returns anything other than a `4D.SystemWorker` (or a wrapper with a `worker` property), the result is not registered. If the result has a `terminate()` function, it is called so that nothing leaks. The call returns `False` with error `-3`.
- After launching, `start` waits `startupWait` milliseconds and checks that the process is still running. If it has already exited (for example because its port is in use or its arguments are wrong), it is unregistered and the call returns `False` with error `-8`. The error element also has `exitCode` and `stderr` properties (the process's standard error, or its standard output if that is empty, up to 1000 characters), and both appear in `message`.
- If the server class has an `isReady(port)` function, `start` then calls it (in the `".workers"` process) about every 100 ms until it returns `True`. If that does not happen before `timeout`, the process is terminated and the call returns `False` with error `-10`. If the process exits in the meantime, the error is `-8`. Errors raised by `isReady` also make `start` fail, and the process is terminated.
- Without `isReady`, `True` means the process was launched and was still running after `startupWait`. It does not mean the server has bound its port.
- If the previous server on `port` was terminated but has not exited yet (after a `terminate` that returned `-9`), nothing is launched and the call returns `False` with error `-9`.
- If the call times out (`-1`) while the server class's `start` is still running, the request is cancelled. When `start` returns later, its server is terminated instead of being registered. A request that has not started yet is dropped.

#### terminate ({port : Integer}) → Boolean

| Parameter | Type | | Description |
| --- | --- | --- | --- |
| port | Integer | -> | Optional. Port of the server to terminate |
| Result | Boolean | <- | `True` if no error occurred |

- Without a parameter, terminates every server started by **this class**. Servers of other classes are left running. *(Behaviour change: versions up to 20.0.20 terminated every registered server, whatever its class.)*
- With `port`, terminates the server on that port, but only if this class owns it. Otherwise it returns `False`, sets `owner`, and reports error `-5`.
- Terminating a port with no registered server, or calling it before any `start`, does nothing and returns `True`.
- `4D.SystemWorker.terminate()` is asynchronous. `terminate` waits (at most `timeout` seconds) until the processes have actually exited, so the port can be reused as soon as it returns `True`. If a process is still running at the deadline, the call returns `False` with error `-9`. The process stays tracked: `isRunning` returns `False`, `start` on its port fails with `-9` until it exits, and calling `terminate` again waits for it again.
- `4D.SystemWorker.terminate()` stops the process with `SIGKILL` (on macOS it kills the whole process group). There is no graceful shutdown: a server's `SIGTERM` handler never runs, so it cannot flush data or clean up. If a server needs that, ask it to shut down itself (for example through its own API) before calling `terminate`.

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
| -2 | The request was aborted by an error that no handler caught (typically an error in the server class, including a `4D.SystemWorker.new()` whose binary is missing or not executable) |
| -3 | The server class's `start` did not return a `4D.SystemWorker` |
| -4 | Invalid port (must be 1–65535) |
| -5 | The port is held by another class (see `owner`) |
| -6 | `class` is not a `4D.Class` |
| -7 | `option` is not an object |
| -8 | The process exited during startup (see `exitCode` and `stderr` in the error element), or it was terminated by another call before `start` could check it |
| -9 | `terminate`: a process did not exit within `timeout`. `start`: the previous process on this port has not exited yet |
| -10 | The server class's `isReady(port)` did not return `True` within `timeout` |

Notes:

- An error raised inside the server class cannot be trapped by the component's error handler. It aborts the request in the worker, and the call returns `False` with error `-2`. This includes a missing or non-executable binary: `4D.SystemWorker.new()` raises its error in the server class, so `start` reports the generic `-2` rather than `-8`. In headless or server mode, 4D may also end the `".workers"` process, which terminates the servers it owns.
- After a timeout (`-1`) in `start`, a server that is launched later is terminated rather than registered (see `start`). `terminate` and `isRunning` requests may still complete later in the worker.
- Calls made from inside the `".workers"` process run directly instead of being dispatched, so there is no deadlock. This covers a server class's `start` and `4D.SystemWorker` callbacks such as `onTerminate`. These calls cannot wait inside that process, so `start` skips the startup check (`startupWait`, `isReady`) and `terminate` returns without waiting for the processes to exit.
- The `".workers"` process never waits on a `4D.SystemWorker`, because `SystemWorker.wait()` would run its other queued requests re-entrantly. The startup check and the wait for exit run in the calling process, which polls the `".workers"` process with short requests. If the server class's own code calls `wait()`, requests queued for `".workers"` run inside that call; `start` handles this.

### Quitting 4D

Servers started with `4D.SystemWorker` are child processes of 4D. Terminate them before 4D quits, typically from the `On Exit` database method:

```4d
//On Exit
cs.workers.worker.new(cs.myApp.myServer).terminate()
```

Only the process returned by `start` is tracked. A server that detaches itself (daemonises, `nohup ... &`, double fork, `setsid`, or hands off to a service manager such as `launchd`) is not tracked. `terminate` and `isRunning` do not see it, and it keeps running after 4D quits. Run such servers in the foreground.

## Examples

```4d
var $w : cs.workers.worker
$w:=cs.workers.worker.new(cs.myApp.myServer)

If (Not($w.isRunning(8080)))
    If (Not($w.start(8080; {option1: "value"}))) //myServer.start() receives {option1: "value"; port: 8080}
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

A server class that reports when it is ready:

```4d
//cs.myApp.myServer
Class constructor

Function start($option : Object) : 4D.SystemWorker
    return 4D.SystemWorker.new("/usr/local/bin/myserver --port "+String($option.port))

Function isReady($port : Integer) : Boolean
    //must be thread-safe and must not raise errors
    var $request : 4D.HTTPRequest
    $request:=4D.HTTPRequest.new("http://127.0.0.1:"+String($port)+"/health"; {timeout: 1}).wait()
    return ($request.response#Null) && ($request.response.status=200)
```

## See also

- [`workers`](workers.md): the registry that tracks port → SystemWorker mappings
