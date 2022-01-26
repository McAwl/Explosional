extends MeshInstance


func _ready():
	pass # Replace with function body.


func disable():
	print("disabling NukePowerUp")
	visible = false
	$Timer.start()
	transform.origin.x += 20.0


func _on_Timer_timeout():
	print("Setting NukePowerUp")
	visible = true
	transform.origin.x -= 20.0
