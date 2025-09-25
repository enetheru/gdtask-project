```gdscript
# ╒═════════════════════════════════════════════════════════════════════════╕
# │             ██████  ██████  ████████  █████  ███████ ██   ██            │
# │            ██       ██   ██    ██    ██   ██ ██      ██  ██             │
# │            ██   ███ ██   ██    ██    ███████ ███████ █████              │
# │            ██    ██ ██   ██    ██    ██   ██      ██ ██  ██             │
# │             ██████  ██████     ██    ██   ██ ███████ ██   ██            │
# ╘═════════════════════════════════════════════════════════════════════════╛
```

Task object inspired by UniTask

Inspired by C#'s UniTask, GDTask provides a flexible system for managing asynchronous tasks in Godot, with support for task chaining, cancellation, and multiplayer RPCs. It includes a task manager, specialized task types, and an editor panel for debugging.

## Features

- **Pure GDScript**: No external dependencies, easy to integrate.
- **GDTask Class**: Core task object with async/sync execution, cancellation, and chaining (e.g., `then()`).
  - Subclasses: `Delay`, `Repeater`, `Timeout`, `SigResponse`, `Watcher`, `All`, `Any`.
- **Task Manager**: `GDTaskMgr` orchestrates tasks, especially for multiplayer RPCs with response handling.
- **Multiplayer RPCs**: `RPCTask` supports remote method calls with response tracking.
- **Editor Integration**: A bottom panel (`GDTaskPanel`) visualizes active tasks with refresh and cleanup options.
- **Utilities**: Centralized constants and helpers in `defs.gd`.

## Usage

### Creating and Running Tasks
```gdscript
# Create a task (does not start automatically)
var task = GDTask.new(func(): print("Task executed!"))

# Run non-blocking
task.run()

# Run blocking (waits for completion)
await task.run()

# Chain tasks
task.then(GDTask.new(func(): print("Next task!")))
```

### Specialized Tasks
```gdscript
# Wait until a condition is true
var task = GDTaskMgr.WaitUntil(func(): return some_node.is_ready())
await task.run()

# Repeat a task every 2 seconds, 5 times
GDTaskMgr.RepeatEvery(2.0, 5, func(): print("Repeated!"))

# Delay a task by 3 seconds
GDTaskMgr.DelayFor(3.0, func(): print("Delayed!"))

# Wait for a signal
GDTaskMgr.WaitForSignal(some_node.signal_name, func(): print("Signal received!"))

# RPC with response
var response = await GDTaskMgr.rpc_response(peer_id, some_node, "remote_method", [arg1, arg2])
print(response.code, response.data)
```


### Task Manager
```gdscript
# Add a task to the manager
var mgr = GDTaskMgr.new()
add_child(mgr)
mgr.add_task(GDTask.new(func(): print("Managed task!")), true) # Auto-remove on completion
```

## Limitations
- **Main Thread Only**: Tasks must run on the main thread due to Godot's `await` and signal limitations (see [Godot Issue #79637](https://github.com/godotengine/godot/issues/79637)).

## Acknowledgements
- ASCII art generated using [patorjk.com](http://www.patorjk.com/software/taag).
- Inspired by [UniTask](https://github.com/Cysharp/UniTask).
