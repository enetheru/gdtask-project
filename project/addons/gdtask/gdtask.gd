class_name GDTask extends RefCounted

# Task object inspired by UniTask
# Needs better documentation.

# TODO WhenAll( [] )
# TODO WhenAny( [] )

#region Local definitions
enum Status {
	PENDING,	# The default state, waiting to be run
	INPROGRESS,	# Currently running
	COMPLETED,	# finished running
	CANCELED	# finished running by cancellation
}
#endregion

#region Signals
signal finished( status : Status )
#endregion

#region Properties
var callable : Callable
var bindings : Array = []
var product

static var next_id: int = 0
var id : int
var status : Status = Status.PENDING

var next : GDTask
var previous : GDTask
#endregion

#region Basic Methods
## by default the constructor does not action the callable, it simply creates the object.
func _init( _callable: Callable, _bindings : Array = [] ):
	id = next_id
	next_id += 1
	callable = _callable
	bindings = _bindings


## Reset clears the product and sets the status to pending, as if it was just created.
func reset():
	status = Status.PENDING
	product = null


## Run the task, pending the completion of previous tasks
# wont run if the task is not in the pending state.
# Interestingly, if there is a next task, and no bindings associated with that task,
# then the product of the this task will be bound to it.
# TODO it might be better to attach the product at the end of the bindings.
# we can run the task synchronously by calling it with the await keyword.
# ie await run()
# else it is run as a coroutine in the background.
func run() -> void:
	if status != Status.PENDING: return
	if previous && previous.status == Status.PENDING: await previous.run()
	if status == Status.PENDING:
		status = Status.INPROGRESS
		
		#var object = callable.get_object()
		#if object is Node: object = object.name
		#var method_name = "%s" % callable.get_method() if callable.is_standard() else "lambda"
		#var _indent = Util.printy( "run()", [], self )
		#Util.printy( "\t%s.%s( %s ) )", [object, method_name , bindings] )
		
		product = await callable.callv( bindings )
		if status != Status.CANCELED: status = Status.COMPLETED
		finished.emit( status )
	if status == Status.CANCELED: return
	if next && next.status == Status.PENDING:
		if product && not next.bindings: next.bindings = [product]
		next.run()

## wait for any previous tasks in the chain to complete, before awaiting the finished signal
# This function does not trigger the gdtask to run.
func wait():
	if previous: await previous.wait()
	await finished


## Cancel the task, and propogate forward and backwards through the chain
# This only cancels tasks that have not started yet.
func cancel():
	if status != Status.PENDING: return
	status = Status.CANCELED
	finished.emit( status )
	# Propagate cancellation
	if previous && previous.status == Status.PENDING: previous.cancel()
	if next && not next.status == Status.PENDING: next.cancel()


## Await and retrieve the result
func result():
	match status:
		Status.PENDING: await run()
		Status.INPROGRESS: await finished
		Status.CANCELED: return null
		Status.COMPLETED: pass
	return product


## Attach a timeout to the task that cancels it
func timeout( seconds : float ):
	var scene_tree = Engine.get_main_loop() as SceneTree
	if not scene_tree: print("Unable to get the SceneTree from Engine")
	else: scene_tree.create_timer(seconds).timeout.connect( func(): cancel() )
	return self


## then attaches a new gdtask to perform after this one completes and returns the new task.
func then( _callable : Callable, _bindings : Array = [] ) -> GDTask:
	var task = GDTask.new( _callable, _bindings )
	next = task
	task.previous = self
	return next

#endregion


#region Specialisations
class Watcher extends GDTask:
	var scene_tree : SceneTree

	func watcher():
		if callable.callv(bindings):
			status = Status.COMPLETED
			finished.emit( status )
			scene_tree.process_frame.disconnect( watcher )
			if next: next.run()

	func _init( _callable: Callable, _bindings : Array ):
		super._init( _callable, _bindings )
		scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree: scene_tree.process_frame.connect( watcher )
		else: printerr("Unable to get the SceneTree from Engine")


class NextFrame extends GDTask:
	var scene_tree : SceneTree

	func _init( _callable : Callable, _bindings : Array = [] ):
		super._init( _callable, _bindings )
		scene_tree = Engine.get_main_loop() as SceneTree
		if not scene_tree: printerr("Unable to get the SceneTree from Engine")
		else:
			scene_tree.process_frame.connect( run )
			finished.connect(func(_product): scene_tree.process_frame.disconnect( run ) )

class Repeater extends GDTask:
	var scene_tree : SceneTree
	var seconds : float
	var ntimes : int = -1

	func repeat():
		if ntimes > 0: ntimes -= 1
		if not ntimes: status = Status.COMPLETED; return
		await run()
		scene_tree.create_timer(seconds).timeout.connect( repeat )

	func _init( _seconds: float, _callable : Callable, _bindings : Array = [] ):
		super._init( _callable, _bindings )
		seconds = _seconds
		scene_tree = Engine.get_main_loop() as SceneTree
		if not scene_tree: printerr("Unable to get the SceneTree from Engine"); return
		repeat()

class Delay extends GDTask:
	var scene_tree : SceneTree
	var seconds : float

	func _init( _seconds: float, _callable : Callable, _bindings : Array = [] ):
		super._init( _callable, _bindings )
		seconds = _seconds
		scene_tree = Engine.get_main_loop() as SceneTree
		if not scene_tree: printerr("Unable to get the SceneTree from Engine"); return
		scene_tree.create_timer(seconds).timeout.connect( run )

#endregion

#region Factory functions for specialisations

## WaitUntil
static func WaitUntil( _callable : Callable, _bindings : Array = [] ) -> GDTask:
	return Watcher.new( _callable, _bindings )

## WaitFrame
static func WaitFrame( _callable : Callable, _bindings = [] ) -> GDTask:
	return NextFrame.new( _callable, _bindings )

## RepeatEvery
static func RepeatEvery( seconds : float, _callable : Callable, _bindings : Array = [] ):
	return Repeater.new( seconds, _callable, _bindings )

## DelayFor
static func DelayFor( seconds : float, _callable : Callable = func(): return, _bindings : Array = [] ):
	return Delay.new( seconds, _callable, _bindings )

#endregion
