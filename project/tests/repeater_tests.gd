extends Object

var runner : RichTextLabel

static var repeat_count = 0

func repeat_func() -> void:
	repeat_count += 1
	print( "repeater: %s" % repeat_count )

func _init( test_runner : RichTextLabel ) -> void:
	print("repeater-tests init function")
	runner = test_runner

func run() -> int:
	print( "running RepeatEvery Tests")

	## GDTask.RepeaterEvery
	await GDTaskMgr.RepeatEvery( 0.1, 5, repeat_func ).finished
	runner.check( "Repeat count is correct", repeat_count, runner.Op.EQUAL,  5 )


	return OK
