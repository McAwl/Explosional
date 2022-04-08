extends Spatial


var print_timer = 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	$CarBody/Explosion.visible = false


func get_carbody():
	return $CarBody


func get_camera():
	return $CarBody/CameraBase/Camera


func set_label(new_label):
	get_node( "../../CanvasLayer/Label").text = new_label


func get_player():
	return get_parent().get_parent().get_parent()


func reset_car():
	# print("reset_car()")
	get_player().lives_left -= 1
	if get_player().lives_left < 0:
		# get_parent().set_label("Player: "+str($Body.player_number)+" Game Over")
		visible = false
	else:
		get_player().set_label_player_name()
		get_player().set_label_lives_left()
		get_player().reset_health()
		$CarBody.global_transform.origin = get_player().get_parent().get_random_spawn_point()  # Vector3(0.0, 0.0, 0.0)
		$CarBody.linear_velocity = Vector3(0.0, 0.0, 0.0)
		$CarBody.speed = 0.0
		$CarBody.angular_velocity = Vector3(0.0, 0.0, 0.0)
		$CarBody.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	$CarBody.reset_vals()
	$CarBody.reset_car = false
	$CarBody.get_node("Wheel1").visible = true
	$CarBody.get_node("Wheel2").visible = true
	$CarBody.get_node("Wheel3").visible = true
	$CarBody.get_node("Wheel4").visible = true
	# $CarBody.get_node("Body").visible = true
	$CarBody.get_node("ParticlesSmoke").visible = true
	$CarBody.get_node("Flames3D").visible = true
	$CarBody.lifetime_so_far_sec = 0.0
	
	# delete old vehicle, instance new one
	for ch in get_children():
		if "vehicle_mesh" in ch.name:
			ch.queue_free()
	var vehicle_type = get_player().vehicle_type
	var new_vehicle_scene = get_player().vehicle_types[vehicle_type]["scene"]
	var new_vehicle = load(new_vehicle_scene).instance()
	new_vehicle.name = "vehicle_mesh"
	$CarBody.add_child(new_vehicle)


func _process(delta):
	
	if $CarBody.global_transform.origin.y < -50.0:
		reset_car()
			
	print_timer += delta


func _on_CarBody_body_entered(_body):
	# print("car_base: on_CarBody_body_entered, _body.name="+str(_body.name))
	if "Nuke" in _body.name:
		$CarBody.weapons[3].enabled = true
		_body.get_parent().disable()  # disable the nuke powerup on a timer
