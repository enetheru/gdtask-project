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

enum Values {
	NONE,
	SHORT,
	LONG
}

@onready var value = Values.NONE
func print_value( wanted ) -> void:
	var _wanted = Values.keys()[wanted]
	var _value = Values.keys()[value]
	if wanted == value: print( "wanted: %s, got: %s" % [_wanted, _value] )
	else: printerr( "wanted: %s, got: %s" % [_wanted, _value] )

func short_func() -> void:
	print( "short func")
	value = Values.SHORT
	
func long_func() -> void:
	await get_tree().create_timer(1).timeout
	print( "long_func")
	value = Values.LONG

func _ready():
	var short_task = GDTask.new( short_func )
	var long_task = GDTask.new( long_func )
	if value != Values.NONE:
		printerr("Initial conditions not met")
		return
	
	long_task.run()
	print_value(Values.NONE)
	short_task.run()
	print_value(Values.SHORT)
	await long_task.result()
	print_value(Values.LONG)
	
	
	
	
