extends Viewport


var check = false


func _ready():
	pass # Replace with function body.


func _process(delta):
	if check == false:
		print("check false")
		check = true
	$vehicle.rotate_y(delta * 0.7)


