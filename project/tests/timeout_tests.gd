extends RefCounted

var runner : RichTextLabel

func _init( test_runner : RichTextLabel ) -> void:
	print("timeout-tests init function")
	runner = test_runner
	
	run()

func long_job( duration : float ) -> int:
	await runner.get_tree().create_timer( duration ).timeout
	return 42

func run() -> int:
	print( "running CancelAfter Tests")
	## GDTask.CancelAfter
	
	# A task that takes two seconds, but is set to cancel after one
	# creating a task doesnt run it.
	var timeout_task : GDTask = GDTask.CancelAfter( 1, long_job, [2])
	runner.check_status( "status before task.run() on timeout", timeout_task.status, GDTask.Status.PENDING )
	
	# Running the task without await is async
	timeout_task.run()
	runner.check_status( "status after task.run() on timeout", timeout_task.status, GDTask.Status.INPROGRESS )
	
	# running the task with await will call it synchronously
	# repeated run()'s are OK, they will just await the finished signal, or trigger the signal
	await timeout_task.run()
	runner.check_status( "status after await task.run() on timeout", timeout_task.status, GDTask.Status.CANCELLED )
	
	return OK
