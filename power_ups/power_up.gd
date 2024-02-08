extends Spatial
class_name PowerUp


export var type: int = -1

enum State {
	MOVE=0, 
	CHECK_RAYCAST=1, 
	ACTIVE=2
}

var state = State.MOVE
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var initialised: bool = false
var activated: bool = false
var nuke_meshes: Resource = load(Global.nuke_meshes_scene_folder)
var shield_meshes: Resource = load(Global.shield_meshes_scene_folder)
var health_meshes: Resource = load(Global.health_meshes_scene_folder)


func _ready():
	set_physics_process(true)


func _process(delta):
	rotation_degrees.y += delta*30.0
	if initialised == false:
		if type == ConfigWeapons.PowerupType.NUKE:
			var new_mesh = nuke_meshes.instance()
			new_mesh.scale = Vector3(0.2, 0.2, 0.2)
			$Area.add_child(new_mesh)
		elif type == ConfigWeapons.PowerupType.SHIELD:
			var new_mesh = shield_meshes.instance()
			new_mesh.scale = Vector3(0.4, 0.4, 0.4)
			$Area.add_child(new_mesh)
		elif type == ConfigWeapons.PowerupType.HEALTH:
			var new_mesh = health_meshes.instance()
			new_mesh.scale = Vector3(0.4, 0.4, 0.4)
			$Area.add_child(new_mesh)
		else:
			Global.debug_print(3, "power_up "+str(type)+" unknown", "powerups")
			queue_free()
		initialised = true
	if activated == true and initialised == true:
		if $ActivationSound.playing == false and $MoveSound.playing == false:
			queue_free()

	if type == ConfigWeapons.PowerupType.HEALTH or type == ConfigWeapons.PowerupType.SHIELD:
		if state == State.MOVE:
			Global.debug_print(5, "Moving powerup "+str(name), "powerups")
			translation = Vector3(0.0+rng.randf()*600.0, 50.0, 0.0+rng.randf()*600.0)  # 600x600 covers the terrain
			state = State.CHECK_RAYCAST  # check the raycast collision on the next physics process
			set_physics_process(true)


func _physics_process(_delta):
	
	if type == ConfigWeapons.PowerupType.HEALTH or type == ConfigWeapons.PowerupType.SHIELD:
		# alternate between moving the powerup and checking its raycast - doing both at once seems to cause performance issues
		if state == State.CHECK_RAYCAST:
			if $RayCast.is_colliding():
				Global.debug_print(4, "Powerup "+str(name)+" raycast is colliding", "powerups")
				if "terrain" in $RayCast.get_collider().name.to_lower() and not "lava" in $RayCast.get_collider().name.to_lower():
					Global.debug_print(4, "Powerup "+str(name)+" raycast is colliding with the terrain. Setting powerup active...", "powerups")
					var collision_point = $RayCast.get_collision_point()
					translation = Vector3(collision_point.x, collision_point.y+0.5, collision_point.z)
					state = State.ACTIVE
					set_physics_process(false)  # stop processing physics, as the raycast not needed once we've placed the powerup
				else:
					Global.debug_print(4, "Powerup "+str(name)+" raycast is not colliding with the terrain. Moving...", "powerups")
					state = State.MOVE  # collided, but not where we want, so move it
			else:
				Global.debug_print(4, "Powerup "+str(name)+" raycast is not colliding with anything. Moving...", "powerups")
				state = State.MOVE  # no collision, so move it


func _on_Area_body_entered(body):
	if body is VehicleBody:
		Global.debug_print(5, "_on_Area_body_entered - VehicleBody", "powerups")
		body.power_up(type)
		activated = true
		$ActivationSound.play()
		$Area/GlowingSphere.hide()
		$Lights.hide()


func disable() -> void:
	Global.debug_print(4, "disabling NukePowerUp", "powerups")
	visible = false
	$Timer.start()
	transform.origin.x += 20.0


func _on_TimerPeriodicMove_timeout():
	Global.debug_print(5, "_on_TimerPeriodicMove_timeout()", "powerups")
	state = State.MOVE
	set_physics_process(true)  # start processing physics, so we can check raycasts
