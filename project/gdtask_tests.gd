extends RichTextLabel

# Examples need to include
	# Awaiting
	# Cancellable
	#	- Manually
	#	- Timeout
	# Specialistions
	#	- [Partial] WaitFrame / Physics Frame
	#	- [Done]    WaitUntil - callable evaluates to true
	#	- Repeat with frequency
	#	- Delay
	#	- WaitChange - watch a variable for changes, might be the same as WaitUntil
	#	- NetworkRequest	- keep track of rpc calls that have results

var last_value : float

func generic( duration : float = 0, value : float = 0 ) -> float:
	#print_rich("[color=slate_grey]generic( duration: %s, value: %s ) -> %s[/color]" % [duration, value, duration + value] )
	if duration: await get_tree().create_timer( duration ).timeout
	last_value = value
	return duration + value

static var repeat_count = 0

func repeat_func() -> void:
	repeat_count += 1
	print( "repeater: %s" % repeat_count )
	
func check( test : String, have, want ):
	var txt = "[b]%s - have: %s, want: %s[/b]" % [test, have, want]
	if have == want:
		print_rich( txt, " - [color=green]OK[/color]" )
	else:
		printerr(txt)

func _ready():
	var long_task = GDTask.new( generic, [1, 2] )
	
	last_value = 999
	
	# running a task is a non blocking operation
	long_task.run()
	check( "task.run() is non blocking", last_value, 999 )
	
	# runnin an inprogress task is also non blocking, but has little effect.
	# the function is made, and awaits the finished result, but returns instantly.
	long_task.run()
	
	# calling await on an in-progress task will await the result
	await long_task.run()
	check("await task.run() on task in progress", last_value, 2 )
	
	# awaiting the result of a completed task will return the product
	check( "await task.result() on completed task is OK", await long_task.result(), 3 )
	
	# reset product and status, ie return to baseline
	long_task.reset()
	
	# awaiting the result of a fresh task will run it
	check( "await task.result() runs task to get result", await long_task.result(), 3 )
	
	long_task.reset()
	long_task.run()
	
	# Cancelling a task cant stop a callable that is already in progress,
	# but it can propagate the call to previous and subsequent tasks, or tasks that repeat.
	long_task.cancel()
	check( "task.cancel on task in progress", long_task.status, GDTask.Status.CANCELLED )

	
	## GDTask.CancelAfter
	# creating a task doesnt run it.
	var timeout_task : GDTask = GDTask.CancelAfter( 1, generic, [2, 3])
	check( "status before task.run() on timeout", timeout_task.status, GDTask.Status.PENDING )
	timeout_task.run()
	check( "status after task.run() on timeout", timeout_task.status, GDTask.Status.INPROGRESS )
	await timeout_task.run()
	check( "status after await task.run() on timeout", timeout_task.status, GDTask.Status.CANCELLED )
	
	
	## GDTask.RepeaterEvery
	await GDTask.RepeatEvery( 0.1, 5, repeat_func ).finished
	check( "Repeat count is correct", repeat_count,  5 )
	
	# next frame
	var current_frame = get_tree().get_frame()
	print("frame: ", current_frame )
	var frame = await GDTask.WaitFrame( func(): return get_tree().get_frame() ).result()
	print( "frame: ", frame )
	
	## GDTask.DelayFor()
	## GDTask.WaitFrame()
	## GDTask.WaitUntil()
	
	GDTask.DelayFor(1, func():
		print_rich("[color=purple]quitting[/color]")
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit()
		)
	
	
	
	
	
	
