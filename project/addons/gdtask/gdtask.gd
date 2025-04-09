class_name GDTask extends RefCounted
# ██
# ██     ██████  ██████  ████████  █████  ███████ ██   ██
# ██    ██       ██   ██    ██    ██   ██ ██      ██  ██
# ██    ██   ███ ██   ██    ██    ███████ ███████ █████
# ██    ██    ██ ██   ██    ██    ██   ██      ██ ██  ██
# ██     ██████  ██████     ██    ██   ██ ███████ ██   ██
# ██
# █████████████████████████████████████████████████████████████████████████████
#
# Task object inspired by UniTask

## the counter from which to draw the next id from.
static var next_id: int = 0 :
	get:
		next_id += 1
		return next_id


# MARK: Defs
#   ██████  ███████ ███████ ███████
#   ██   ██ ██      ██      ██
#   ██   ██ █████   █████   ███████
#   ██   ██ ██      ██           ██
#   ██████  ███████ ██      ███████

## Status flag for the task
enum Status {
	PENDING,	# The default state, waiting to be run
	INPROGRESS,	# Currently running
	COMPLETED,	# finished running
	CANCELLED	# finished running by cancellation
}


# MARK: Signals
#   ███████ ██  ██████  ███    ██  █████  ██      ███████
#   ██      ██ ██       ████   ██ ██   ██ ██      ██
#   ███████ ██ ██   ███ ██ ██  ██ ███████ ██      ███████
#        ██ ██ ██    ██ ██  ██ ██ ██   ██ ██           ██
#   ███████ ██  ██████  ██   ████ ██   ██ ███████ ███████

signal started
signal completed( product )
signal finished( status : Status )


# MARK: Props
#   ██████  ██████   ██████  ██████  ███████
#   ██   ██ ██   ██ ██    ██ ██   ██ ██
#   ██████  ██████  ██    ██ ██████  ███████
#   ██      ██   ██ ██    ██ ██           ██
#   ██      ██   ██  ██████  ██      ███████

## A unique ID to use
var id : int

## The Status of the task
var status : Status

## The function that is the task we are running.
var callable : Callable

## The values to bind to the callable when running
var bindings : Array = []

## The result of our task
var product

## The task to run after we have successfully completed
var next : GDTask

## The task previous to us that must be successful for us to run.
var previous : GDTask


# MARK: _to_string()
#       ████████  ██████          ███████ ████████ ██████  ██ ███    ██  ██████
#          ██    ██    ██         ██         ██    ██   ██ ██ ████   ██ ██
#          ██    ██    ██         ███████    ██    ██████  ██ ██ ██  ██ ██   ███
#          ██    ██    ██              ██    ██    ██   ██ ██ ██  ██ ██ ██    ██
#  ███████ ██     ██████  ███████ ███████    ██    ██   ██ ██ ██   ████  ██████

## A String representation of the task
## "[id]status | callable signature(bindings, ...) -> result"
func _to_string() -> String:
	# Owner
	var object = callable.get_object()
	var owner : String = ("%s." % object.name) if object is Node else ""

	# Method Name
	var method_name : String = "%s" % callable.get_method() if callable.is_standard() else "lambda"
	var args : Array[String] = []
	for arg in bindings:
		args.append( "%s" % arg )

	var function : String = "%s%s(%s)" % [owner, method_name, ", ".join(args)]

	return "[%d]%s | %s -> %s" %[id, Status.keys()[status], function, product]


# MARK: _init()
#               ██ ███    ██ ██ ████████
#               ██ ████   ██ ██    ██
#               ██ ██ ██  ██ ██    ██
#               ██ ██  ██ ██ ██    ██
#       ███████ ██ ██   ████ ██    ██

## by default the constructor does not action the callable, it simply creates the object.
func _init( _callable: Callable, _bindings : Array = [] ):
	id = next_id
	status = Status.PENDING
	callable = _callable
	bindings = _bindings


# MARK: run()
#       ██████  ██    ██ ███    ██
#       ██   ██ ██    ██ ████   ██
#       ██████  ██    ██ ██ ██  ██
#       ██   ██ ██    ██ ██  ██ ██
#       ██   ██  ██████  ██   ████

## This is the actual runner that can be overloaded per specialisation
func _run():
	product = await callable.callv( bindings )


## Run the task, pending the completion of previous tasks
# run() is asynchronous
# await run() is synchronous
# repeated run() calls will just trigger a finished signal emission, or await the finished signal
func run() -> void:
	# update our status
	match status:
		Status.PENDING:
			status = Status.INPROGRESS
			started.emit()
		Status.INPROGRESS:
			await finished
			return
		_:
			finished.emit( status )
			return

	# Run the previous task if we have one.
	if previous && previous.status == Status.PENDING:
		await previous.run()
		if previous.status == Status.CANCELLED:
			status = Status.CANCELLED
			finished.emit( status )

	# Run our actual task
	await _run()

	# post run checks
	if status != Status.CANCELLED: status = Status.COMPLETED

	# Notify
	finished.emit( status )
	completed.emit( product )

	# Quit if cancelled
	if status == Status.CANCELLED: return

	# Run the next task if it exists
	if next:
		# TODO it might be better to attach the product at the end of the bindings.
		# pass the product of this task to the next task
		if product && not next.bindings: next.bindings = [product]
		next.run()


# MARK: cancel()
#        ██████  █████  ███    ██  ██████ ███████ ██
#       ██      ██   ██ ████   ██ ██      ██      ██
#       ██      ███████ ██ ██  ██ ██      █████   ██
#       ██      ██   ██ ██  ██ ██ ██      ██      ██
#        ██████ ██   ██ ██   ████  ██████ ███████ ███████

## Cancel the task, and propogate forward and backwards through the chain
# This cannot stop an in-progress callable.call()
# But it can prevent further run calls to next and previous tasks
# I am going to leave the ability to cancel a completed job for now.
func cancel():
	status = Status.CANCELLED
	finished.emit( status )
	# Propagate cancellation
	if previous && previous.status == Status.PENDING: previous.cancel()
	if next && not next.status == Status.PENDING: next.cancel()


# MARK: result()
#       ██████  ███████ ███████ ██    ██ ██      ████████
#       ██   ██ ██      ██      ██    ██ ██         ██
#       ██████  █████   ███████ ██    ██ ██         ██
#       ██   ██ ██           ██ ██    ██ ██         ██
#       ██   ██ ███████ ███████  ██████  ███████    ██

## Await and retrieve the result
func result():
	match status:
		Status.PENDING: await run()
		Status.INPROGRESS: await finished
		Status.CANCELLED: return null
		Status.COMPLETED: pass
	return product


# MARK: then()
#       ████████ ██   ██ ███████ ███    ██
#          ██    ██   ██ ██      ████   ██
#          ██    ███████ █████   ██ ██  ██
#          ██    ██   ██ ██      ██  ██ ██
#          ██    ██   ██ ███████ ██   ████

## then attaches a new gdtask to perform after this one completes and returns the new task.
func then( _callable : Callable, _bindings : Array = [] ) -> GDTask:
	var task = GDTask.new( _callable, _bindings )
	next = task
	task.previous = self
	return next


# MARK: reset()
#       ██████  ███████ ███████ ███████ ████████
#       ██   ██ ██      ██      ██         ██
#       ██████  █████   ███████ █████      ██
#       ██   ██ ██           ██ ██         ██
#       ██   ██ ███████ ███████ ███████    ██

## Reset clears the product and sets the status to pending, as if it was just created.
func reset( _prev : bool = false, _next : bool = false):
	status = Status.PENDING
	product = null
	if _prev: previous.reset()
	if _next: next.reset()


# MARK: Specialisations
#       ███████ ██████  ███████  ██████ ██  █████  ██      ██ ███████  █████  ████████ ██  ██████  ███    ██ ███████
#       ██      ██   ██ ██      ██      ██ ██   ██ ██      ██ ██      ██   ██    ██    ██ ██    ██ ████   ██ ██
#       ███████ ██████  █████   ██      ██ ███████ ██      ██ ███████ ███████    ██    ██ ██    ██ ██ ██  ██ ███████
#            ██ ██      ██      ██      ██ ██   ██ ██      ██      ██ ██   ██    ██    ██ ██    ██ ██  ██ ██      ██
#       ███████ ██      ███████  ██████ ██ ██   ██ ███████ ██ ███████ ██   ██    ██    ██  ██████  ██   ████ ███████

## Below are the specialisations of GDTask which extend the functionality to perform more elaborate tasks.
# Ones that require overloading the primary functions and perhaps adding more.
# There is one paradigm I am targeting, resettability


# MARK: Watcher
#       ██     ██  █████  ████████  ██████ ██   ██ ███████ ██████
#       ██     ██ ██   ██    ██    ██      ██   ██ ██      ██   ██
#       ██  █  ██ ███████    ██    ██      ███████ █████   ██████
#       ██ ███ ██ ██   ██    ██    ██      ██   ██ ██      ██   ██
#        ███ ███  ██   ██    ██     ██████ ██   ██ ███████ ██   ██

## This task runs every frame, and finishes when the result of the callable is true
class Watcher extends GDTask:
	signal success
	var scene_tree : SceneTree

	func _init( _callable: Callable, _bindings : Array = [] ):
		super._init( _callable, _bindings )
		scene_tree = Engine.get_main_loop() as SceneTree
		if not scene_tree: printerr("Unable to get the SceneTree from Engine")
		started.connect( _on_started )

	func watcher():
		if callable.callv( bindings ):
			scene_tree.process_frame.disconnect( watcher )
			success.emit()

	func _on_started():
		if scene_tree: scene_tree.process_frame.connect( watcher )
		else: cancel()

	func _run() -> void:
		await success


# MARK: Repeater
#       ██████  ███████ ██████  ███████  █████  ████████ ███████ ██████
#       ██   ██ ██      ██   ██ ██      ██   ██    ██    ██      ██   ██
#       ██████  █████   ██████  █████   ███████    ██    █████   ██████
#       ██   ██ ██      ██      ██      ██   ██    ██    ██      ██   ██
#       ██   ██ ███████ ██      ███████ ██   ██    ██    ███████ ██   ██

class Repeater extends GDTask:
	var scene_tree : SceneTree
	var seconds : float
	var ntimes : int = -1

	func _init( _ntimes : int, _seconds: float, _callable : Callable, _bindings : Array = [] ):
		super._init( _callable, _bindings )
		seconds = _seconds
		ntimes = _ntimes
		scene_tree = Engine.get_main_loop() as SceneTree
		if not scene_tree: printerr("Unable to get the SceneTree from Engine"); return

	func run() -> void:
		match status:
			Status.PENDING:		status = Status.INPROGRESS; started.emit()
			Status.CANCELLED:	finished.emit( status )
			Status.COMPLETED:	finished.emit( status )
			Status.INPROGRESS:	pass # TODO Reset Counter?

		if previous && previous.status == Status.PENDING:
			await previous.run()
			if previous.status == Status.CANCELLED:
				status = Status.CANCELLED
				finished.emit( status )

		# Run our task
		if ntimes:
			product = await callable.callv( bindings )
			completed.emit( product )
			ntimes -= 1

		if ntimes:
			scene_tree.create_timer(seconds).timeout.connect( run )
		elif status == Status.CANCELLED:
			finished.emit( status )
			return
		else:
			status = Status.COMPLETED;
			finished.emit( status )

		# if there is a next task, run it
		if status != Status.CANCELLED and next:
			# pass the product of this task to the next task
			if product && not next.bindings: next.bindings = [product]
			next.run()


# MARK: Delay
#       ██████  ███████ ██       █████  ██    ██
#       ██   ██ ██      ██      ██   ██  ██  ██
#       ██   ██ █████   ██      ███████   ████
#       ██   ██ ██      ██      ██   ██    ██
#       ██████  ███████ ███████ ██   ██    ██

class Delay extends GDTask:
	var scene_tree : SceneTree
	var seconds : float

	func _init( _seconds: float, _callable : Callable, _bindings : Array = [] ):
		super._init( _callable, _bindings )
		seconds = _seconds
		scene_tree = Engine.get_main_loop() as SceneTree
		if not scene_tree: printerr("Unable to get the SceneTree from Engine"); return
		scene_tree.create_timer(seconds).timeout.connect( run, CONNECT_ONE_SHOT )


# MARK: Timeout
#       ████████ ██ ███    ███ ███████  ██████  ██    ██ ████████
#          ██    ██ ████  ████ ██      ██    ██ ██    ██    ██
#          ██    ██ ██ ████ ██ █████   ██    ██ ██    ██    ██
#          ██    ██ ██  ██  ██ ██      ██    ██ ██    ██    ██
#          ██    ██ ██      ██ ███████  ██████   ██████     ██

#TODO Timeout is in progress
class Timeout extends GDTask:
	var scene_tree : SceneTree
	var seconds : float
	var timeout : SceneTreeTimer

	func _init( _seconds : float, _callable : Callable, _bindings : Array = [] ):
		super._init( _callable, _bindings )
		seconds = _seconds
		scene_tree = Engine.get_main_loop() as SceneTree
		if not scene_tree: printerr("Unable to get the SceneTree from Engine"); return
		started.connect( _on_started )
		finished.connect( _on_finished )

	func _on_started():
		timeout = scene_tree.create_timer( seconds )
		timeout.timeout.connect( cancel )

	func _on_finished( _status : Status ):
		timeout.timeout.disconnect( cancel )


# MARK: Signal
#   ███████ ██  ██████  ███    ██  █████  ██
#   ██      ██ ██       ████   ██ ██   ██ ██
#   ███████ ██ ██   ███ ██ ██  ██ ███████ ██
#        ██ ██ ██    ██ ██  ██ ██ ██   ██ ██
#   ███████ ██  ██████  ██   ████ ██   ██ ███████

## Waits for a given signal before running.
class SigResponse extends GDTask:
	var sig : Signal

	func run():
		await sig
		super.run()

	func _init( _sig : Signal, _callable : Callable, _bindings : Array = [] ):
		super._init( _callable, _bindings )
		sig = _sig


# MARK: Any
#    █████  ███    ██ ██    ██
#   ██   ██ ████   ██  ██  ██
#   ███████ ██ ██  ██   ████
#   ██   ██ ██  ██ ██    ██
#   ██   ██ ██   ████    ██

class Any extends GDTask:
	signal any

	var tasks : Array[GDTask]

	func _to_string() -> String:
		return "[%d]%s | sub_tasks: %d" %[id, Status.keys()[status], tasks.size()]

	func _on_task_finished( sub_status : Status ):
		if status != Status.INPROGRESS: return # we dont care, as our task isnt running.
		if sub_status == Status.COMPLETED:
			any.emit()

	func _init( _tasks : Array[GDTask] ):
		id = next_id
		status = Status.PENDING
		tasks = _tasks
		for task : GDTask in tasks:
			task.finished.connect(_on_task_finished)
			# If we happen to pass this task a completed task
			# then we should mark it as completed too.
			if task.status == Status.COMPLETED:
				status == Status.COMPLETED

	## Runs all the subtasks given to it.
	func _run() -> void:
		for task in tasks:
			task.run()

		await any


# MARK: All
#    █████  ██      ██
#   ██   ██ ██      ██
#   ███████ ██      ██
#   ██   ██ ██      ██
#   ██   ██ ███████ ███████

class All extends GDTask:
	signal all

	var tasks : Array[GDTask]
	var counter : int = -1

	func _to_string() -> String:
		return "[%d]%s | sub_tasks: %d" %[id, Status.keys()[status], tasks.size()]

	func _on_task_finished( sub_status : Status ):
		counter -= 1

		if status != Status.INPROGRESS: return # we dont care, as our task isnt running.

		if counter <= 0:
			all.emit()

		if sub_status == Status.CANCELLED:
			status = Status.CANCELLED

	func _init( _tasks : Array[GDTask] ):
		id = next_id
		status = Status.PENDING
		tasks = _tasks
		counter = tasks.size()
		for task : GDTask in tasks:
			# completed tasks dont count to the total
			if task.status == Status.COMPLETED:
				counter -= 1
				continue
			# Oneshot is used so a task cant be counted twice.
			task.finished.connect(_on_task_finished, CONNECT_ONE_SHOT)

	## Runs all the subtasks given to it.
	func _run() -> void:
		for task in tasks:
			task.run()

		await all


# MARK: Factories
#       ███████  █████   ██████ ████████  ██████  ██████  ██ ███████ ███████
#       ██      ██   ██ ██         ██    ██    ██ ██   ██ ██ ██      ██
#       █████   ███████ ██         ██    ██    ██ ██████  ██ █████   ███████
#       ██      ██   ██ ██         ██    ██    ██ ██   ██ ██ ██           ██
#       ██      ██   ██  ██████    ██     ██████  ██   ██ ██ ███████ ███████

# The thing factories all have in common are that they do not await.
# So to run synchronously, either awaiting a second run() or awaiting the finish signal is necessary.
## WaitUntil
# waits till the result of the callable evaluates to true before completing
static func WaitUntil( _callable : Callable, _bindings : Array = [] ) -> GDTask:
	var task = Watcher.new( _callable, _bindings )
	task.run()
	return task

## RepeatEvery
static func RepeatEvery( seconds : float, ntimes : int, _callable : Callable, _bindings : Array = [] ):
	var task = Repeater.new( ntimes, seconds, _callable, _bindings )
	task.run()
	return task

## DelayFor
static func DelayFor( seconds : float, _callable : Callable = func(): return, _bindings : Array = [] ):
	var task = Delay.new( seconds, _callable, _bindings )
	task.run()
	return task

##
static func CancelAfter( seconds : float, _callable : Callable = func(): return, _bindings : Array = [] ):
	var task = Timeout.new( seconds, _callable, _bindings )
	task.run()
	return task

## Waits for the given signal before calling the callable.
static func WaitForSignal( sig : Signal, _callable : Callable = func(): return, _bindings : Array = [] ):
	var task = SigResponse.new( sig, _callable, _bindings )
	task.run()
	return task

## Waits for all subtasks to be completed
static func WhenAll( tasks : Array[GDTask] ):
	var task = All.new( tasks )
	task.run()
	return task

## Waits for any subtask to be completed.
static func WhenAny( tasks : Array[GDTask] ):
	var task = Any.new( tasks )
	task.run()
	return task
