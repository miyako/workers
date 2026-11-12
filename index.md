---
layout: default
---

![version](https://img.shields.io/badge/version-20%2B-E23089)
![platform](https://img.shields.io/static/v1?label=platform&message=mac-intel%20|%20mac-arm%20|%20win-64&color=blue)
[![license](https://img.shields.io/github/license/miyako/workers)](LICENSE)
![downloads](https://img.shields.io/github/downloads/miyako/workers/total)

# workers

#### Abstract

This component exports utility classes in the `cs.workers` namespace.

The classes implement an abstraction layer on top of a process array to manage running `4D.SystemWorker` instances which are not sharable.


#### Usage

```4d
var $w : cs.workers.worker
$w:=cs.workers.worker.new(cs.myServer) //myServer.start($option) returns a 4D.SystemWorker

If ($w.start(8080; {}))
    //running
Else 
    //$w.errors explains why; $w.owner names the class holding the port, if any
End if 

$w.terminate(8080) //or $w.terminate() for every server of cs.myServer
```

`start`, `isRunning` and `terminate` return `False` instead of hanging when the server class fails. They never wait longer than `$w.timeout` seconds (default 60). Each `worker` only controls servers started by its own class. The server class receives the port as `$option.port`.

`start` returns `False` if the process exits during startup (error `-8`, with its exit code and standard error), or if the class's optional `isReady(port)` function does not return `True` in time (`-10`). `terminate` returns once the processes have exited, so the port can be reused right away (`-9` if they do not exit in time).

Call `terminate()` from `On Exit` so that no server outlives 4D. Servers that daemonise (`nohup`, double fork...) are not tracked. See [worker](workers/Documentation/Classes/worker.md) for details and error codes.
