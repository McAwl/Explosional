extends Viewport


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var check = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _process(delta):
	if check == false:
		print("check false")
		check = true
	$vehicle.rotate_y(delta * 0.7)


