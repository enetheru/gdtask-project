@tool
extends EditorScript

signal test_signal

var editor_tree = EditorInterface.get_base_control().get_tree()

# test function that pretends to be long running.
func test_func():
	var delay = randf_range(0.1, 3)
	var timer =  editor_tree.create_timer(delay, true, false, true)
	# Unfortunately there appears to be a problem with awaiting the timeout signal of the timer.
	# But I can hook it upto a custom signal and it works as expected.
	timer.timeout.connect(func(): test_signal.emit() )
	await test_signal
	print("\ntest_func() has finished after a delay of %f" % delay)

func _run() -> void:
	await test_basic()
	await test_all()
	await test_any()

func test_basic():
	print( "\n\n== Test GDTask ==")
	# Creating a task does not start it
	var task = GDTask.new( test_func )
	print( "\n'task' has just been created:")
	print( task )

	# non blocking, triggers the start of the task
	task.run()
	print( "\n'task.run()' has just been called:" )
	print( task )

	# blocking, waits for the completion of the task
	await task.run()
	print( "\n'await task.run()' has just been called:")
	print( task )

func test_any():
	print( "\n\n== Test GDTask.Any ==")
	var task = GDTask.WhenAny([])
	print( task )

	var tasks : Array[GDTask] = []
	for i in range(10):
		tasks.append( GDTask.new( test_func ) )

	task = GDTask.Any.new( tasks )
	print( task )

	await task.run()
	print( "\n'await task.run()' has just been called:")
	print( task )

func test_all():
	print( "\n\n== Test GDTask.All ==")
	var task = GDTask.WhenAny([])
	print( task )

	var tasks : Array[GDTask] = []
	for i in range(10):
		tasks.append( GDTask.new( test_func ) )

	task = GDTask.All.new( tasks )
	print( task )

	await task.run()
	print( "\n'await task.run()' has just been called:")
	print( task )
