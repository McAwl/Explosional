extends Particles


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# We reparent the smoke so the parent explosion can destroy itself
# without worrying it will stop the smoke
func reparent(from_parent: Node):
	var old_global_transform_origin = global_transform.origin
	var new_parent = get_tree().root.get_node("MainScene")
	from_parent.remove_child(self)
	new_parent.add_child(self)
	set_as_toplevel(true)
	global_transform.origin = old_global_transform_origin

