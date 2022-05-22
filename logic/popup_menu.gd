extends Popup


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
func _input(event):
	self.popup_centered()
	popup()  # this shows the popup 
	if event is InputEventKey and event.pressed:
		print("event.scancode="+str(event.scancode))
		if event.scancode != KEY_MASK_META and event.scancode != KEY_META and event.scancode != KEY_SUPER_L and event.scancode != KEY_SUPER_R:  # e.g. Windows key
			get_tree().paused = false

