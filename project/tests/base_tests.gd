extends Object

var runner : RichTextLabel

# GDTask basic Interface 

# Run
# Cancel
# Result
# Then
# Reset
#TODO use a lambda as the function

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
	
	# Creating a task does not start it
	var task = GDTask.new( generic, [1, 2] )
	runner.check_status("Status after construction", task.status, GDTask.Status.PENDING )
	
	# running a task is a non blocking operation
	task.run()
	runner.check_status("Status after run()", task.status, GDTask.Status.INPROGRESS )
	
	# runnin an inprogress task is also non blocking, but has little effect.
	# the function is made, and awaits the finished result, but returns instantly.
	task.run()
	runner.check_status("Status after subsequent run()'s", task.status, GDTask.Status.INPROGRESS )
	
	# calling await on an in-progress task will await the result
	await task.run()
	runner.check_status("Status after await run()'s", task.status, GDTask.Status.COMPLETED )
	
	# awaiting the result of a completed task will return the product
	runner.check( "await task.result() on completed task is OK", await task.result(), runner.Op.EQUAL, 3 )
	
	# reset product and status, ie return to baseline
	task.reset()
	
	# awaiting the result of a fresh task will run it
	runner.check( "await task.result() runs task to get result", await task.result(), runner.Op.EQUAL, 3 )
	
	task.reset()
	task.run()
	
	# Cancelling a task cant stop a callable that is already in progress,
	# but it can propagate the call to previous and subsequent tasks, or tasks that repeat.
	task.cancel()
	runner.check_status( "task.cancel on task in progress", task.status, GDTask.Status.CANCELLED )
	return OK
