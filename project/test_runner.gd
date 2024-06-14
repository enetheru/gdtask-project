class_name TestRunner extends RichTextLabel

func check( test : String, have, want ):
	var txt = "%s - have: %s, want: %s" % [test, have, want]
	if have == want:
		print_rich( "[b]%s[/b]" % txt, " - [color=green]OK[/color]" )
	else:
		printerr(txt)

func check_status( test : String, have : GDTask.Status, want : GDTask.Status ):
	GDTask.Status.keys()
	var txt = "%s - have: %s, want: %s" % [test, GDTask.Status.keys()[have], GDTask.Status.keys()[want]]
	if have == want:
		print_rich( "[b]%s[/b]" % txt, " - [color=green]OK[/color]" )
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
				tests.append( load("res://%s/%s" % [path, file_name]) )
			file_name = dir.get_next()
	else:
		printerr("encountered an error accessing path: %s" % path )
	
	for test in tests:
		await test.new( self )
	
	
	#get_tree().root.propagate_notification( NOTIFICATION_WM_CLOSE_REQUEST )
	#get_tree().quit()
	
	

	
	


	

	
	
	
	
	
	
