extends Object

var runner : RichTextLabel

func _init( test_runner : RichTextLabel ) -> void:
	print("watcher-tests init function")
	runner = test_runner

func test_func( duration: float ):
	await runner.get_tree().create_timer(duration).timeout
	return 42

func run() -> int:
	print( "running WaitUntil Tests")

	var value = 0
	# Create a basic GDTask
	print("Create a standard task")
	var task = GDTask.new( test_func, [2] )
	runner.check_status("Status After creation", task.status, GDTask.Status.PENDING )
	runner.get_tree().physics_frame

	await task.run()

	## GDTask.WaitUntil()
	return OK
