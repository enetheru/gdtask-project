extends Node

const Constant = preload( 'res://addons/enetheru.gdtask/defs.gd' ).Constant

@rpc("any_peer", "call_local", "reliable")
func mock_rpc_method(task_id: int, value: int) -> void:
	GDTaskMgr.respond(multiplayer.get_remote_sender_id(), task_id, Constant.ACK, var_to_bytes([value]))
