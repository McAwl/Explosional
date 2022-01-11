extends MeshInstance


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func disable():
	print("disabling NukePowerUp")
	visible = false
	$Timer.start()
	transform.origin.x += 20.0

func _on_Timer_timeout():
	print("Setting NukePowerUp")
	visible = true
	transform.origin.x -= 20.0
