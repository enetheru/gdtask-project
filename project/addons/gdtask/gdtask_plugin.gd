@tool
extends EditorPlugin


func _enter_tree() -> void:
	print( "gdtask enabled")
	pass


func _exit_tree() -> void:
	print( "gdtask disabled")
	pass
