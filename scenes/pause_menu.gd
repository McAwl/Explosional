extends Label

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
#var show = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	if show == true:
#		visible = true
#		show = false
	
	
func _input(event):
	if event is InputEventKey and event.pressed:
		print("event.scancode="+str(event.scancode))
		if event.scancode != KEY_MASK_META and event.scancode != KEY_META and event.scancode != KEY_SUPER_L and event.scancode != KEY_SUPER_R:  # e.g. Windows key
			print("unpausing game")
			visible = false
			get_parent().get_node("MainMenu").set_visible(false)
			get_tree().paused = false

