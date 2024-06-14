extends RefCounted

var runner : RichTextLabel

func _init( test_runner : RichTextLabel ) -> void:
	print("watcher-tests init function")
	runner = test_runner
	
	run()

func run() -> int:
	print( "running WaitUntil Tests")
	
	## GDTask.WaitUntil()
	
	return OK
