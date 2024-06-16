extends Object

var runner : RichTextLabel

func _init( test_runner : RichTextLabel ) -> void:
	print("delay-tests init function")
	runner = test_runner

func test_func():
	return runner.get_tree().get_frame()

func run() -> int:
	var result : bool = true
	print( "running DelayFor Tests")

	# Lets start out the manual way using a timer
	# I can delay execution in the current context simply using a timer.
	var frame_before = runner.get_tree().get_frame()
	await runner.get_tree().create_timer(1).timeout
	var frame_after = test_func()
	result = runner.check( "Frame number after awaiting timer should be larger", frame_before, runner.Op.LESS_THAN, frame_after ) && result

	# The problem is that I want to continue execution in the current context
	frame_before = runner.get_tree().get_frame()
	var timer =  runner.get_tree().create_timer(1)
	timer.timeout.connect( test_func )
	await timer.timeout
	# but I cant get the result of the function, I would have to create a variable, and have the function do side effects.

	# So I want to be able to continue the current context, and then execute the task after some predicate.
	# It seems to me that its the same as wait until, just using a timer, so pehraps I can delete it altogether.
	# I want to delay for a few reasons
	# signal needs to be triggered
	# some function needs to evaluate to true
	# I think I can cover both using delay for and delay until.
	#  - WaitFor( signal, callable, bindings )
	#  - waitUntil( callable, bindings )
	# examples using the above could be wait for timer signal

	var task = GDTask.new( func(): await runner.get_tree().create_timer(1).timeout ).then( test_func )
	frame_after = await task.result()
	result = runner.check( "Frame number after delay should be larger", frame_before, runner.Op.NOT_EQUAL, frame_after ) && result

	## GDTask.DelayFor()

	#await GDTask.DelayFor(1)
	#var frame2 = runner.get_tree().get_frame()
	#result = runner.check( "Frame number after delay should be larger", frame, runner.Op.NOT_EQUAL, frame2 ) && result
	return !result
