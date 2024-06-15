extends Object

var runner : RichTextLabel

#TODO use a lambda

var last_value : float

func generic( duration : float = 0, value : float = 0 ) -> float:
	#print_rich("[color=slate_grey]generic( duration: %s, value: %s ) -> %s[/color]" % [duration, value, duration + value] )
	if duration: await runner.get_tree().create_timer( duration ).timeout
	last_value = value
	return duration + value

func _init( test_runner : RichTextLabel ) -> void:
	print("base-tests init function")
	runner = test_runner

func run() -> int:
	print( "running Base GDTask Tests")
	
	last_value = 999
	var long_task = GDTask.new( generic, [1, 2] )
	
	# running a task is a non blocking operation
	long_task.run()
	runner.check( "task.run() is non blocking", last_value, runner.Op.EQUAL, 999 )
	
	# runnin an inprogress task is also non blocking, but has little effect.
	# the function is made, and awaits the finished result, but returns instantly.
	long_task.run()
	
	# calling await on an in-progress task will await the result
	await long_task.run()
	runner.check("await task.run() on task in progress", last_value, runner.Op.EQUAL, 2 )
	
	# awaiting the result of a completed task will return the product
	runner.check( "await task.result() on completed task is OK", await long_task.result(), runner.Op.EQUAL, 3 )
	
	# reset product and status, ie return to baseline
	long_task.reset()
	
	# awaiting the result of a fresh task will run it
	runner.check( "await task.result() runs task to get result", await long_task.result(), runner.Op.EQUAL, 3 )
	
	long_task.reset()
	long_task.run()
	
	# Cancelling a task cant stop a callable that is already in progress,
	# but it can propagate the call to previous and subsequent tasks, or tasks that repeat.
	long_task.cancel()
	runner.check_status( "task.cancel on task in progress", long_task.status, GDTask.Status.CANCELLED )
	return OK
