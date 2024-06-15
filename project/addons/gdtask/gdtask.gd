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
	CANCELLED	# finished running by cancellation
}
#endregion

#region Signals
signal started
signal completed( product )
signal finished( status : Status )
#endregion

#region Properties
var callable : Callable
var bindings : Array = []
var product

static var next_id: int = 0
var id : int
var status : Status

var next : GDTask
var previous : GDTask
#endregion

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_POSTINITIALIZE:
			print("gdtask(%s) - post-initialise" %id )
		NOTIFICATION_PREDELETE:
			print("gdtask(%s) - pre-delete" %id )

#region Basic Methods
## by default the constructor does not action the callable, it simply creates the object.
func _init( _callable: Callable, _bindings : Array = [] ):
	next_id += 1
	
	id = next_id
	status = Status.PENDING
	callable = _callable
	bindings = _bindings
	
	#DEBUG PRINT
	if callable.is_custom():
		print("gdtask(%s) initialised | %s( %s ) " % [id,"<anonymous lambda>",bindings] )
	else:
		print("gdtask(%s) initialised | %s( %s ) " % [id,callable.get_method(),bindings] )


## Reset clears the product and sets the status to pending, as if it was just created.
func reset():
	status = Status.PENDING
	product = null


## Run the task, pending the completion of previous tasks
# run() is asynchronous
# await run() is synchronous
# repeated run() calls will just trigger a finished signal emission, or await the finished signal
func run() -> void:
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
		
	if previous && previous.status == Status.PENDING:
		await previous.run()
		if previous.status == Status.CANCELLED:
			status = Status.CANCELLED
			finished.emit( status )

	#DEBUG PRINT
	#var object = callable.get_object()
	#if object is Node: object = object.name
	#var method_name = "%s" % callable.get_method() if callable.is_standard() else "lambda"
	#var _indent = Util.printy( "run()", [], self )
	#Util.printy( "\t%s.%s( %s ) )", [object, method_name , bindings] )
	
	# Run our task
	product = await callable.callv( bindings )
	
	if status != Status.CANCELLED: status = Status.COMPLETED
	
	finished.emit( status )
	completed.emit( product )
	if status == Status.CANCELLED: return
	
	# if there is a next task, run it
	if next:
		# TODO it might be better to attach the product at the end of the bindings.
		# pass the product of this task to the next task
		if product && not next.bindings: next.bindings = [product]
		next.run()


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


## Await and retrieve the result
func result():
	match status:
		Status.PENDING: await run()
		Status.INPROGRESS: await finished
		Status.CANCELLED: return null
		Status.COMPLETED: pass
	return product
	

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
		if callable.callv( bindings ):
			status = Status.COMPLETED
			finished.emit( status )
			scene_tree.process_frame.disconnect( watcher )
			if next: next.run()
	
	func _on_started():
		if scene_tree: scene_tree.process_frame.connect( watcher )
		else: cancel()

	func _init( _callable: Callable, _bindings : Array ):
		super._init( _callable, _bindings )
		scene_tree = Engine.get_main_loop() as SceneTree
		if not scene_tree: printerr("Unable to get the SceneTree from Engine")


class NextFrame extends GDTask:
	var scene_tree : SceneTree
	var start_frame : int
	
	func cleanup( _status ):
		scene_tree.process_frame.disconnect( run )
	
	func run():
		if scene_tree.get_frame() >= start_frame+1: super.run()
		
	func _init( _callable : Callable, _bindings : Array = [] ):
		super._init( _callable, _bindings )
		scene_tree = Engine.get_main_loop() as SceneTree
		if not scene_tree: printerr("Unable to get the SceneTree from Engine"); return
		start_frame = scene_tree.get_frame()
		scene_tree.process_frame.connect( run )
		finished.connect( cleanup )

class Repeater extends GDTask:
	var scene_tree : SceneTree
	var seconds : float
	var ntimes : int = -1
	
	func run() -> void:
		match status:
			Status.PENDING:		status = Status.INPROGRESS
			Status.CANCELLED:	finished.emit( status )
			Status.COMPLETED:	finished.emit( status )
			Status.INPROGRESS:	pass
			
		if previous && previous.status == Status.PENDING:
			await previous.run()
			if previous.status == Status.CANCELLED:
				status = Status.CANCELLED
				finished.emit( status )

		#DEBUG PRINT
		#var object = callable.get_object()
		#if object is Node: object = object.name
		#var method_name = "%s" % callable.get_method() if callable.is_standard() else "lambda"
		#var _indent = Util.printy( "run()", [], self )
		#Util.printy( "\t%s.%s( %s ) )", [object, method_name , bindings] )
		
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
		

	func _init( _ntimes : int, _seconds: float, _callable : Callable, _bindings : Array = [] ):
		super._init( _callable, _bindings )
		seconds = _seconds
		ntimes = _ntimes
		scene_tree = Engine.get_main_loop() as SceneTree
		if not scene_tree: printerr("Unable to get the SceneTree from Engine"); return


class Delay extends GDTask:
	var scene_tree : SceneTree
	var seconds : float

	func _init( _seconds: float, _callable : Callable, _bindings : Array = [] ):
		super._init( _callable, _bindings )
		seconds = _seconds
		scene_tree = Engine.get_main_loop() as SceneTree
		if not scene_tree: printerr("Unable to get the SceneTree from Engine"); return
		scene_tree.create_timer(seconds).timeout.connect( run )

#TODO Timeout is in progress
class Timeout extends GDTask:
	var scene_tree : SceneTree
	var seconds : float
	var timeout : SceneTreeTimer
	
	func _on_started():
		timeout = scene_tree.create_timer( seconds )
		timeout.timeout.connect( cancel )
	
	func _on_finished( _status : Status ):
		timeout.timeout.disconnect( cancel )
	
	func _init( _seconds : float, _callable : Callable, _bindings : Array = [] ):
		super._init( _callable, _bindings )
		seconds = _seconds
		scene_tree = Engine.get_main_loop() as SceneTree
		if not scene_tree: printerr("Unable to get the SceneTree from Engine"); return
		started.connect( _on_started )
		finished.connect( _on_finished )
#endregion

#region Factory functions for specialisations

## WaitUntil
# waits till the result of the callable evaluates to true before completing
static func WaitUntil( _callable : Callable, _bindings : Array = [] ) -> GDTask:
	var task = Watcher.new( _callable, _bindings )
	task.run()
	return task

## WaitFrame
static func WaitFrame( _callable : Callable, _bindings = [] ) -> GDTask:
	var task = NextFrame.new( _callable, _bindings )
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

static func CancelAfter( seconds : float, _callable : Callable = func(): return, _bindings : Array = [] ):
	var task = Timeout.new( seconds, _callable, _bindings )
	task.run()
	return task

#endregion
