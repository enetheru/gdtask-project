extends Object

var runner : RichTextLabel

func _init( test_runner : RichTextLabel ) -> void:
	print("delay-tests init function")
	runner = test_runner

func run() -> int:
	var result : bool = true
	print( "running DelayFor Tests")

	# Lets start out the manual way using a timer
	var frame_before = runner.get_tree().get_frame()
	print( "Initial Frame: ", frame_before )
	var task = GDTask.new( func(): await runner.get_tree().create_timer(1).timeout )
	await task.run()
	var frame_after = runner.get_tree().get_frame()
	result = runner.check( "Frame number after delay should be larger", frame_before, runner.Op.NOT_EQUAL, frame_after ) && result


	## GDTask.DelayFor()

	#await GDTask.DelayFor(1)
	#var frame2 = runner.get_tree().get_frame()
	#result = runner.check( "Frame number after delay should be larger", frame, runner.Op.NOT_EQUAL, frame2 ) && result
	return !result
