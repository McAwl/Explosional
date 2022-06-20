extends Spatial

var initialised: bool = false
var activated: bool = false

export var type: int = -1
var nuke_meshes: Resource = load(Global.nuke_meshes_scene_folder)
var shield_meshes: Resource = load(Global.shield_meshes_scene_folder)
var health_meshes: Resource = load(Global.health_meshes_scene_folder)

func _ready():
	pass # Replace with function body.


func disable() -> void:
	# print("disabling NukePowerUp")
	visible = false
	$Timer.start()
	transform.origin.x += 20.0


func _on_Timer_timeout():
	# print("Setting NukePowerUp")
	visible = true
	transform.origin.x -= 20.0


func _process(delta):
	rotation_degrees.y += delta*30.0
	if initialised == false:
		if type == ConfigWeapons.PowerupType.NUKE:
			var new_mesh = nuke_meshes.instance()
			new_mesh.scale = Vector3(0.2, 0.2, 0.2)
			$Area.add_child(new_mesh)
		elif type == ConfigWeapons.PowerupType.SHIELD:
			var new_mesh = shield_meshes.instance()
			new_mesh.scale = Vector3(0.2, 0.2, 0.2)
			$Area.add_child(new_mesh)
		elif type == ConfigWeapons.PowerupType.HEALTH:
			var new_mesh = health_meshes.instance()
			new_mesh.scale = Vector3(0.2, 0.2, 0.2)
			$Area.add_child(new_mesh)
		else:
			print("power_up "+str(type)+" unknown")
			queue_free()
		initialised = true
	if activated == true and initialised == true:
		if $ActivationSound.playing == false:
			queue_free()


func _on_Area_body_entered(body):
	# print("_on_Area_body_entered")
	if body is VehicleBody:
		body.power_up(type)
		activated = true
		$ActivationSound.play()
		$Area/GlowingSphere.hide()
		$Lights.hide()

