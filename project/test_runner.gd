class_name TestRunner extends RichTextLabel

enum Op {
	EQUAL,
	NOT_EQUAL,
	GREATER_THAN_OR_EQUAL,
	GREATER_THAN,
	LESS_THAN_OR_EQUAL,
	LESS_THAN
}

var title : String = "[center][color=gold]GDTask Testing Scene[/color][/center]"
var path = "tests"
var test_scripts : Array = []

func _ready():
	text = title
	## Collect all the tests from the test directory
	meta_clicked.connect( _on_meta_clicked )

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

	text += "\n[b]Tests:[/b]"
	text += "\n[url=all]All[/url]"
	for script in test_scripts:
		text += "\n[url=%s]%s[/url]" % [script, script.get_basename()]



	#get_tree().root.propagate_notification( NOTIFICATION_WM_CLOSE_REQUEST )
	#get_tree().quit()


func _on_meta_clicked( meta : Variant ):
	if meta == "all":
		for script : String in test_scripts:
			print("\n")
			var test_object = load("res://%s/%s" % [path, script]).new(self)
			var result = await test_object.run()
			print_rich( "\nScript: %s.gd" % script.get_basename(), " - [color=%s][b]%s[/b][/color]" % ["red" if result else "green", "FAIL" if result else "OK"] )
	else:
		print("\n")
		var test_object = load("res://%s/%s" % [path, meta]).new(self)
		var result = await test_object.run()
		print_rich( "\nScript: %s.gd" % meta.get_basename(), " - [color=%s][b]%s[/b][/color]" % ["red" if result else "green", "FAIL" if result else "OK"] )

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
