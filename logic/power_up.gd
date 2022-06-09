extends Spatial

signal power_up
var activated = false

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


func _process(delta):
	rotation_degrees.y += delta*30.0
	if activated == true:
		if $ActivationSound.playing == false:
			queue_free()


func _on_Area_body_entered(body):
	print("_on_Area_body_entered")
	if body is VehicleBody:
		body.power_up("nuke")
		activated = true
		$ActivationSound.play()
		$Meshes.hide()
		$Lights.hide()

