extends VehicleBody


const STEER_SPEED = 1.5
const STEER_LIMIT = 0.6 #0.4
const EXPLOSION_STRENGTH = 50.0
const ENGINE_FORCE_VALUE = 60
var steer_target = 0

export var engine_force_value = ENGINE_FORCE_VALUE  #40
var player_number
var camera
export var speed = 0.0
var speed_low_limit = 5
var rng = RandomNumberGenerator.new()

const COOLDOWN_TIMER_DEFAULTS = {"mine": 5.0, "rocket": 5.0, "missile": 60.0, "nuke": 10.0}
var cooldown_timer = COOLDOWN_TIMER_DEFAULTS["mine"]
var timer_0_1_sec = 0.1
var timer_1_sec = 1.0  # timer to eg: check if car needs to turn light on 
var lifetime_so_far_sec = 0.0  # to eg disable air strikes for a bit after re-spawn
var hit_by_missile = {"active": false, "homing": null, "origin": null, "velocity": null, "direct_hit": null, "distance": null}
var max_damage = 10.0
var total_damage = 0.0
var take_damage = true
var wheel_positions = []
var wheels = []
var reset_car = false
var weapons = {0: {"name": "mine", "damage": 2, "active": false, "cooldown_timer": COOLDOWN_TIMER_DEFAULTS["mine"], "scene": "res://scenes/explosive.tscn", "enabled": true}, \
			   1: {"name": "rocket", "damage": 5, "indirect_damage": 1, "active": false, "cooldown_timer": COOLDOWN_TIMER_DEFAULTS["rocket"], "scene": "res://scenes/missile.tscn", "enabled": true}, \
			   2: {"name": "missile", "damage": 5, "indirect_damage": 1, "active": false, "cooldown_timer": COOLDOWN_TIMER_DEFAULTS["missile"], "scene": "res://scenes/missile.tscn", "enabled": true}, \
			   3: {"name": "nuke", "damage": 10, "active": false, "cooldown_timer": COOLDOWN_TIMER_DEFAULTS["nuke"], "scene": "res://scenes/explosive.tscn", "enabled": false, "test_mode": false}}
var weapon_select = 0
var lights_disabled = false


func _ready():
	cooldown_timer = weapons[weapon_select]["cooldown_timer"]
	lights_disabled = false
	check_lights()
	$ParticlesSmoke.emitting = false
	$ParticlesSmoke.amount = 1

	
func check_lights():
	if get_node("/root/TownScene/DirectionalLight").light_energy < 0.2:
		# print("turning lights on")
		lights_on()
	else:
		# print("turning lights off")
		lights_off()


func flicker_damaged_lights():
	# damaged lights
	# small chance of turning off when damaged. slightly bigger chance of turing back on (should flicker)
	
	if rng.randf() < 0.1*total_damage/max_damage:
		# print("damaged LightFrontLeft flickering off")
		$Lights/LightFrontLeft.spot_range = 10  #100.0*(max_damage-total_damage)
	elif rng.randf() < 0.5*total_damage/max_damage:
		# print("damaged LightFrontLeft flickering on")
		$Lights/LightFrontLeft.spot_range = 100.0

	if rng.randf() < 0.1*total_damage/max_damage:
		# print("damaged LightFrontRight flickering off")
		$Lights/LightFrontRight.spot_range = 10  # 100.0*(max_damage-total_damage)
	elif rng.randf() < 0.5*total_damage/max_damage:
		# print("damaged LightFrontRight flickering on")
		$Lights/LightFrontRight.spot_range = 100.0


func get_raycast(wheel_num):
	return get_wheel(wheel_num).get_node("RayCastWheel"+str(wheel_num))


func check_ongoing_damage():
	if total_damage < max_damage:
		for raycast in [get_raycast(1), get_raycast(2), get_raycast(3), get_raycast(4), $OtherRaycasts/RayCastCentreDown, $OtherRaycasts/RayCastBonnetUp, $OtherRaycasts/RayCastForward, $OtherRaycasts/RayCastBackward, $OtherRaycasts/RayCastLeft, $OtherRaycasts/RayCastRight]:
			if check_raycast("lava", raycast) == true:
				# print("Player taking damage 1")
				return 1
		$LavaLight1.visible = false
		return 0


func check_raycast(substring_in_hit_name, raycast):
	if raycast.is_colliding():
		if substring_in_hit_name.to_lower() in raycast.get_collider().name.to_lower():
			# print("Vehicle raycast "+str(raycast.name)+": collision matches substring: "+str(substring_in_hit_name))
			$LavaLight1.visible = true
			return true
	return false


func _process(delta):
	
	if reset_car == true and $Explosion/AnimationPlayer.current_animation != "explosion":
		print("reset_car == true and $Explosion/AnimationPlayer.current_animation != 'explosion'")
		reset_vals()
		get_parent().reset_car()
		
	if total_damage >= max_damage:
		return
		
	timer_1_sec -= delta
	if timer_1_sec <= 0.0:
		timer_1_sec = 1.0
		check_lights()
		var ongoing_damage = check_ongoing_damage()
		if ongoing_damage > 0:
			damage(ongoing_damage)

	timer_0_1_sec -= delta
	if timer_0_1_sec <= 0.0:
		flicker_damaged_lights()
		timer_0_1_sec = 0.1
		if not ("instance" in weapons[weapon_select]):
			#print(str(weapons[weapon_select]["name"])+" not in dict")
			weapons[weapon_select]["active"] = false
			cooldown_timer = weapons[weapon_select]["cooldown_timer"]
		elif weapons[weapon_select]["instance"] == null:
			#print(str(weapons[weapon_select]["name"])+" is null")
			weapons[weapon_select]["active"] = false
			cooldown_timer = weapons[weapon_select]["cooldown_timer"]
		elif not is_instance_valid(weapons[weapon_select]["instance"]):
			#print(str(weapons[weapon_select]["name"])+" is invalid instance")
			weapons[weapon_select]["active"] = false
			cooldown_timer = weapons[weapon_select]["cooldown_timer"]
		#else:
		#	print(str(weapons[weapon_select]["name"])+" in dict. Lifetime="+str(weapons[weapon_select]["instance"].lifetime_seconds))
		get_player().set_label(player_number, get_player().lives_left, total_damage, weapons[weapon_select].damage)
		get_player().get_canvaslayer().get_node("cooldown").max_value = COOLDOWN_TIMER_DEFAULTS[weapons[weapon_select]["name"]]
		get_player().get_canvaslayer().get_node("cooldown").value = cooldown_timer

	lifetime_so_far_sec += delta
		
	if Input.is_action_just_released("cycle_weapon_player"+str(player_number)):
		cycle_weapon()
	
	if Input.is_action_just_released("fire_player"+str(player_number)) and weapons[weapon_select]["active"] == false and weapons[weapon_select]["cooldown_timer"] <= 0.0 and weapons[weapon_select]["enabled"] == true:
		# print("Player pressed fire")
		weapons[weapon_select]["cooldown_timer"] = COOLDOWN_TIMER_DEFAULTS[weapons[weapon_select].name]
		get_player().set_label(player_number, get_player().lives_left, total_damage, weapons[weapon_select].damage)
		if weapon_select == 0 or weapon_select == 3:  # mine or nuke
			fire_mine_or_nuke()
		elif weapon_select == 1:
			fire_missile_or_rocket()
		elif weapon_select == 2:
			fire_missile_or_rocket()

	if weapons[weapon_select]["active"] == false:
		if weapons[weapon_select]["cooldown_timer"] > 0.0:
			weapons[weapon_select]["cooldown_timer"] -= delta
			if weapons[weapon_select]["cooldown_timer"] < 0.0:
				weapons[weapon_select]["cooldown_timer"]  = 0.0
		cooldown_timer = weapons[weapon_select]["cooldown_timer"]
	
	if cooldown_timer < 0.0:
		cooldown_timer = 0.0


func cycle_weapon():
		weapon_select += 1
		if weapon_select > 3:
			weapon_select = 0
		if weapons[weapon_select].enabled == false:
			weapon_select += 1
		if weapon_select > 3:
			weapon_select = 0
		get_player().get_canvaslayer().get_node("icon_mine").hide()
		get_player().get_canvaslayer().get_node("icon_rocket").hide()
		get_player().get_canvaslayer().get_node("icon_missile").hide()
		get_player().get_canvaslayer().get_node("icon_nuke").hide()
		get_player().get_canvaslayer().get_node("icon_"+weapons[weapon_select].name).show()
		get_player().set_label(player_number, get_player().lives_left, total_damage, weapons[weapon_select].damage)


func _physics_process(delta):
	
	if total_damage < max_damage:
		
		var fwd_mps = transform.basis.xform_inv(linear_velocity).x

		steer_target = Input.get_action_strength("turn_left_player"+str(player_number)) - Input.get_action_strength("turn_right_player"+str(player_number))
		steer_target *= STEER_LIMIT

		if Input.is_action_pressed("accelerate_player"+str(player_number)):
			# Increase engine force at low speeds to make the initial acceleration faster.
			speed = linear_velocity.length()
			if speed < speed_low_limit and speed != 0:
				engine_force = clamp(engine_force_value * speed_low_limit / speed, 0, 100)
			else:
				engine_force = engine_force_value
		else:
			engine_force = 0
			
		if Input.is_action_pressed("reverse_player"+str(player_number)):
			# Increase engine force at low speeds to make the initial acceleration faster.
			if fwd_mps >= -1:
				speed = linear_velocity.length()
				if speed < speed_low_limit and speed != 0:
					engine_force = -clamp(engine_force_value * speed_low_limit / speed, 0, 100)
				else:
					engine_force = -engine_force_value
			else:
				brake = 1
		else:
			brake = 0.0

		steering = move_toward(steering, steer_target, STEER_SPEED * delta)
	
	if hit_by_missile["active"] == true:
		# print("Player "+str(player_number)+ " hit by missile!")
		#var direction = hit_by_missile_origin - $Body.transform.origin  
		var direction = hit_by_missile["direction_for_explosion"]  # $Body.transform.origin - hit_by_missile_origin 
		direction[1] += 5.0
		# remove downwards force - as vehicles can be blown through the terrain
		if direction[1] < 0:
			direction[1] = 0
		var explosion_force = 200  # 100.0/pow(distance+1.0, 1.5)  # inverse square of distance
		if hit_by_missile["direct_hit"] == true:
			apply_impulse( Vector3(0,0,0), explosion_force*direction.normalized() )   # offset, impulse(=direction*force)
			if hit_by_missile["homing"]:
				damage(weapons[2].damage)
			else:
				damage(weapons[1].damage)
		else:
			var indirect_explosion_force = explosion_force/hit_by_missile["distance"]
			
			apply_impulse( Vector3(0,0,0), indirect_explosion_force*direction.normalized() )   # offset, impulse(=direction*force)
			damage(1)
		angular_velocity =  Vector3(rng.randf_range(-10, 10), rng.randf_range(-10, 10), rng.randf_range(-10, 10)) 
			
		hit_by_missile["active"] = false


func reset_vals():
	engine_force_value = ENGINE_FORCE_VALUE
	$ParticlesSmoke.emitting = false
	$Flames3D.emitting = false
	$ParticlesSmoke.amount = 1
	$Flames3D.amount = 1
	total_damage = 0.0


func get_speed():
	return speed


func get_speed2():
	return transform.basis.xform_inv(linear_velocity).z


func get_global_offset_pos(offset_y, mult_y, offset_z, mult_z):
	var global_pos = global_transform.origin
	global_pos -= (offset_z*mult_z)*Vector3.FORWARD
	global_pos += (offset_y*mult_y)*Vector3.UP
	return global_pos


func damage(amount):
	total_damage += amount
	if $ParticlesSmoke.emitting == false:
		$ParticlesSmoke.emitting = true
		$Flames3D.emitting = true
	$ParticlesSmoke.amount *= 2  # increase engine smoke indicating damage
	$Flames3D.amount *= 5
	engine_force_value *= 0.75  # decrease engine power to indicate damage

	if total_damage >= max_damage:
		print("total_damage >= max_damage")
		total_damage = max_damage
		$Explosion/AnimationPlayer.play("explosion")
		reset_car = true
		$Body.visible = false
		$Wheel1.visible = false
		$Wheel2.visible = false
		$Wheel3.visible = false
		$Wheel4.visible = false
		$ParticlesSmoke.visible = false
		$Flames3D.visible = false
		lights_disabled = true
		lights_off()
	get_player().set_label(player_number, get_player().lives_left, total_damage, weapons[weapon_select].damage)
	get_player().get_canvaslayer().get_node("health").value = max_damage-total_damage
	if max_damage-total_damage >= 7.0:
		get_player().get_canvaslayer().get_node("health").tint_progress = "#7e00ff00"  # green
	elif max_damage-total_damage <= 3.0:
		get_player().get_canvaslayer().get_node("health").tint_progress = "#7eff0000"  # red
	else:
		get_player().get_canvaslayer().get_node("health").tint_progress = "#7eff6c00"  # orange


func get_player():
	return get_parent().get_player()
	

func get_wheel(num):
	return get_node("Wheel"+str(num))
	

func fire_mine_or_nuke():
	# print("Firing weapon="+str(weapon_select))
	var weapon_instance = load(weapons[weapon_select]["scene"]).instance()
	add_child(weapon_instance) 
	weapon_instance.rotation_degrees = rotation_degrees
	weapons[weapon_select]["active"] = true
	if weapon_select == 0:
		weapon_instance.set_as_mine()
		weapon_instance.activate($BombPosition.global_transform.origin, linear_velocity, angular_velocity, 1, player_number, get_player())
	elif weapon_select == 3:
		# print("activating nuke")
		weapon_instance.set_as_nuke()
		weapon_instance.activate(get_node("/root/TownScene/NukeSpawnPoint").global_transform.origin, 0.0, 0.0, 1, player_number, get_player())
		if weapons[3].test_mode == false:
			weapons[3]["enabled"] = false  # so powerup is needed again
			cycle_weapon()  # de-select nuke, as it's not available any more
	else:
		print("fire_mine_or_nuke(): Error! Shouldn't be here")
	# print("weapons[weapon_select]="+str(weapons[weapon_select]))
	weapon_instance.set_as_toplevel(true)


func fire_missile_or_rocket():
	
	var weapon_instance = load(weapons[weapon_select]["scene"]).instance()
	weapons[weapon_select]["instance"] = weapon_instance
	add_child(weapon_instance)
	
	weapon_instance.velocity = transform.basis.z * weapon_instance.muzzle_velocity
	weapon_instance.initial_speed = weapon_instance.velocity.length()
	weapon_instance.linear_velocity = linear_velocity
	weapon_instance.angular_velocity = angular_velocity
	if weapon_select == 2:
		weapon_instance.velocity[1] += 1.0   # angle it up a bit
		weapon_instance.global_transform.origin = $MissilePosition.global_transform.origin
	else:
		weapon_instance.global_transform.origin = $RocketPosition.global_transform.origin
		weapon_instance.velocity[1] -= 0.5  # angle the rocket down a bit
	if weapon_select == 1:
		weapon_instance.activate(player_number, false)  # homing = false
	else:
		weapon_instance.activate(player_number, true)  # homing = true
	weapon_instance.set_as_toplevel(true)
	weapons[weapon_select]["active"] = true
	

func lights_on():
	set_all_lights(true)


func lights_off():
	set_all_lights(false)


func set_all_lights(state):
	$Lights/LightFrontLeft.visible = state
	$Lights/LightFrontRight.visible = state
	$Lights/LightBackLeft.visible = state
	$Lights/LightBackRight.visible = state
	$Lights/LightUnder1.visible = state
	$Lights/LightUnder2.visible = state
	$Lights/LightUnder3.visible = state
	$Lights/LightUnder4.visible = state
	$Lights/LightUnder5.visible = state


func set_global_transform_origin(pos):
	global_transform.origin = pos

 
func _on_CarBody_body_entered(body):
	# print("vehicle: _on_CarBody_body_entered name="+str(body.name))
	if "Lava" in body.name:
		# print("Taking max_damage damage")
		damage(max_damage)
