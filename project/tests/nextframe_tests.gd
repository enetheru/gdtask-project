extends RefCounted

var runner : RichTextLabel

func _init( test_runner : RichTextLabel ) -> void:
	print("next_frame-tests init function")
	runner = test_runner
	
	run()

func run() -> int:
	print( "running WaitFrame Tests")
	
	## GDTask.WaitFrame()
	
	var current_frame = runner.get_tree().get_frame()
	print("frame: ", current_frame )
	var frame = await GDTask.WaitFrame( func(): return runner.get_tree().get_frame() ).result()
	print( "frame: ", frame )
	
	return OK
