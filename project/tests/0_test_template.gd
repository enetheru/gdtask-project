extends Object

var runner : RichTextLabel

func _init( test_runner : RichTextLabel ) -> void:
	#print("template init function")
	runner = test_runner

func run() -> int:
	print( "running template Tests")
	
	return OK
