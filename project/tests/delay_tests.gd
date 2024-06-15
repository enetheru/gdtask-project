extends Object

var runner : RichTextLabel

func _init( test_runner : RichTextLabel ) -> void:
	print("delay-tests init function")
	runner = test_runner

func run() -> int:
	print( "running DelayFor Tests")
	
	## GDTask.DelayFor()
	var frame = runner.get_tree().get_frame()
	await GDTask.DelayFor(1)
	var frame2 = runner.get_tree().get_frame()
	runner.check( "Frame number after delay should be larger", frame, runner.Op.NOT_EQUAL, frame2 )
	
	return OK
