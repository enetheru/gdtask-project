class_name TestRunner extends RichTextLabel

enum Op {
	EQUAL, 
	NOT_EQUAL,
	GREATER_THAN_OR_EQUAL,
	GREATER_THAN,
	LESS_THAN_OR_EQUAL,
	LESS_THAN
}

func check( description : String, val1, op, val2  ):
	var symbol = "?"
	var result = false
	match op:
		Op.EQUAL:
			symbol = '='
			result = val1 == val2
		Op.NOT_EQUAL:
			symbol = '!='
			result = val1 != val2
		Op.GREATER_THAN_OR_EQUAL:
			symbol = '>='
			result = val1 >= val2
		Op.GREATER_THAN:
			symbol = '>'
			result = val1 > val2
		Op.LESS_THAN_OR_EQUAL:
			symbol = '<='
			result = val1 <= val2
		Op.LESS_THAN:
			symbol = '<'
			result = val1 < val2
		
	var test = "%s - is: %s %s %s" % [description, val1, symbol, val2]

	if result:
		print_rich( test, " - [b][color=green]OK[/color][/b]" )
	else:
		print_rich( test, " - [b][color=red]FAIL[/color][/b]" )

func check_status( test : String, have : GDTask.Status, want : GDTask.Status ):
	GDTask.Status.keys()
	var txt = "%s - have: %s, want: %s" % [test, GDTask.Status.keys()[have], GDTask.Status.keys()[want]]
	if have == want:
		print_rich( txt, " - [b][color=green]OK[/color][/b]" )
	else:
		printerr(txt)

func _ready():
	## Collect all the tests from the test directory
	var tests : Array = []
	var path = "tests"
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() && file_name.ends_with(".gd") :
				tests.append( load("res://%s/%s" % [path, file_name]).new(self) )
			file_name = dir.get_next()
	else:
		printerr("encountered an error accessing path: %s" % path )
	
	for test in tests:
		print("\n")
		var result = await test.run()
	

	#get_tree().root.propagate_notification( NOTIFICATION_WM_CLOSE_REQUEST )
	#get_tree().quit()
	
	

	
	


	

	
	
	
	
	
	
