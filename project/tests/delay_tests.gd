extends RefCounted

var runner : RichTextLabel

func _init( test_runner : RichTextLabel ) -> void:
	print("delay-tests init function")
	runner = test_runner
	
	run()

func run() -> int:
	print( "running DelayFor Tests")
	
	## GDTask.DelayFor()
	GDTask.DelayFor(1, func():
		print_rich("[color=purple]quitting[/color]")
	)
	
	return OK
