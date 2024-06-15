extends Object

var runner : RichTextLabel

func _init( test_runner : RichTextLabel ) -> void:
	print("timeout-tests init function")
	runner = test_runner

func long_job( duration : float ) -> int:
	await runner.get_tree().create_timer( duration ).timeout
	return 42

func run() -> int:
	print_rich( "[b]running GDTask.Timeout Tests[/b]")
	
	# Using timeout on a standard task.
	print_rich( "Create standard GDTask task")
	var task = GDTask.new( long_job, [5] )
	# connect a timer to the cancel function
	print_rich( "Connect task.cancel to short timer.timeout signal")
	runner.get_tree().create_timer(1).timeout.connect( task.cancel )
	runner.check_status( "Status after construction", task.status, GDTask.Status.PENDING )
	task.run()
	runner.check_status( "Status after run()", task.status, GDTask.Status.INPROGRESS )
	await task.run()
	runner.check_status( "Status after await run()", task.status, GDTask.Status.CANCELLED )
	print("")
	
	# That might appeat to work in principle, but there are two problems that I can see
	# 1. I can't reset the task and repeat the job, the timeout needs to be added each time.
	# 2. The timer will still trigger a cancel, even after the job is completed.
	
	# To mitigate the two issues above, the task needs to keep track of
	# - the timeout period
	# - the timer, so it can disconnect from the timeout signal
	
	## Timeout Manual creation
	# re-stating the above case
	# creating the task does not start the job
	print("Create a GDTask.Timeout task")
	var timeout_task = GDTask.Timeout.new( 1, long_job, [3] )
	runner.check_status( "Status after construction", timeout_task.status, GDTask.Status.PENDING )
	timeout_task.run()
	runner.check_status( "Status after run()", timeout_task.status, GDTask.Status.INPROGRESS )
	await timeout_task.run()
	runner.check_status( "Status after await run()", timeout_task.status, GDTask.Status.CANCELLED )
	print("")
	
	print("Reset the existing task and run again")
	timeout_task.reset()
	runner.check_status( "Status after reset", timeout_task.status, GDTask.Status.PENDING )
	timeout_task.run()
	runner.check_status( "Status after run()", timeout_task.status, GDTask.Status.INPROGRESS )
	await timeout_task.run()
	runner.check_status( "Status after await run()", timeout_task.status, GDTask.Status.CANCELLED )
	print("")
	
	print("Create a GDTask.Timeout task that completes before the timeout")
	timeout_task = GDTask.Timeout.new( 2, long_job, [1] )
	runner.check_status( "Status after construction", timeout_task.status, GDTask.Status.PENDING )
	timeout_task.run()
	runner.check_status( "Status after run()", timeout_task.status, GDTask.Status.INPROGRESS )
	await timeout_task.run()
	runner.check_status( "Status after await run()", timeout_task.status, GDTask.Status.COMPLETED )
	print("")
	
	## GDTask.CancelAfter
	# While making this I got confused as to why I have
	# a static factory function to create these that just does the same thing but runs the job.
	# If I work it out I will add the GDTask.CancelAfter call.

	return OK
