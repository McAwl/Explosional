extends Label


# Built-in methods

func _ready():
	pass # Replace with function body.


func _input(event):
	if event is InputEventKey and event.pressed:
		print("event.scancode="+str(event.scancode))
		if event.scancode != KEY_MASK_META and event.scancode != KEY_META and event.scancode != KEY_SUPER_L and event.scancode != KEY_SUPER_R:  # e.g. Windows key
			print("unpausing game")
			visible = false
			get_parent().get_node("MainMenu").set_visible(false)
			get_tree().paused = false

