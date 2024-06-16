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
	#runner.get_tree().physics_frame
	var signal_as_variable : Signal = Signal()
	#test_func2( signal_as_variable )
	signal_as_variable.connect( Callable( self, "test_func3") )
	signal_as_variable.emit()


	## GDTask.WaitUntil()
	return OK
