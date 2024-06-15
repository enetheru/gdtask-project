class_name TestRunner extends RichTextLabel

enum Op {
	EQUAL, 
	NOT_EQUAL,
	GREATER_THAN_OR_EQUAL,
	GREATER_THAN,
	LESS_THAN_OR_EQUAL,
	LESS_THAN
}

func check( description : String, val1, op, val2  ) -> bool:
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
	print_rich( test, " - [b][color=%s]%s[/color][/b]" % ["green" if result else "red", "OK" if result else "FAIL"] )
	return result

func check_status( description : String, have : GDTask.Status, want : GDTask.Status ) -> bool:
	GDTask.Status.keys()
	var txt = "%s - have: %s, want: %s" % [description, GDTask.Status.keys()[have], GDTask.Status.keys()[want]]
	var result = have == want
	print_rich( txt, " - [b][color=%s]%s[/color][/b]" % ["green" if result else "red", "OK" if result else "FAIL"] )
	return result

func _ready():
	## Collect all the tests from the test directory
	var test_scripts : Array = []
	var path = "tests"
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() && file_name.ends_with(".gd") :
				test_scripts.append( file_name )
			file_name = dir.get_next()
	else:
		printerr("encountered an error accessing path: %s" % path )
	
	var results : Dictionary
	for script : String in test_scripts:
		print("\n")
		var test_object = load("res://%s/%s" % [path, script]).new(self)
		results[script.get_basename()] = await test_object.run()
	
	for test in results.keys():
		print_rich( "Script: %s.gd" % test, " - [color=%s][b]%s[/b][/color]" % ["red" if results[test] else "green", "FAIL" if results[test] else "OK"] )

	#get_tree().root.propagate_notification( NOTIFICATION_WM_CLOSE_REQUEST )
	#get_tree().quit()
	
	

	
	


	

	
	
	
	
	
	
