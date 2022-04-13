extends VehicleBody


const STEER_SPEED = 1.5
const STEER_LIMIT = 0.6 #0.4
const EXPLOSION_STRENGTH = 50.0
const ENGINE_FORCE_VALUE_DEFAULT = 80
const script_vehicle_detach_rigid_bodies = preload("res://logic/vehicle_detach_rigid_bodies.gd")

var steer_target = 0

var print_timer = 0.0

export var engine_force_value = ENGINE_FORCE_VALUE_DEFAULT  #40
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
var weapons = {0: {"name": "mine", "damage": 2, "active": false, "cooldown_timer": COOLDOWN_TIMER_DEFAULTS["mine"], "scene": "res://scenes/explosive.tscn", "enabled": true}, \
			   1: {"name": "rocket", "damage": 5, "indirect_damage": 1, "active": false, "cooldown_timer": COOLDOWN_TIMER_DEFAULTS["rocket"], "scene": "res://scenes/missile.tscn", "enabled": true}, \
			   2: {"name": "missile", "damage": 5, "indirect_damage": 1, "active": false, "cooldown_timer": COOLDOWN_TIMER_DEFAULTS["missile"], "scene": "res://scenes/missile.tscn", "enabled": true}, \
			   3: {"name": "nuke", "damage": 10, "active": false, "cooldown_timer": COOLDOWN_TIMER_DEFAULTS["nuke"], "scene": "res://scenes/explosive.tscn", "enabled": false, "test_mode": false}}
var weapon_select = 0
var lights_disabled = false
var acceleration_calc_for_damage = 0.0
var vel_max = 0.0
var check_accel_damage_timer = 3.0
var accel_damage_threshold = 100.0
var explosion2_timer = 0.2
var vehicle_types = {	"tank":  {"scene": "res://scenes/vehicle_tank.tscn", 
									"engine_force_value": 40, 
									"mass_kg/100": 200.0, 
									"suspension_stiffness": 100.0, 
									"suspension_travel": 0.1,
									"radius_wheel_m": 0.35,
									"four_wheel_drive": true}, 
						"racer": {"scene": "res://scenes/vehicle_racer.tscn", 
									"engine_force_value": 130, 
									"mass_kg/100": 70.0, 
									"suspension_stiffness": 75.0, 
									"suspension_travel": 0.5,
									"radius_wheel_m": 0.25,
									"four_wheel_drive": false}, 
						"rally": {"scene": "res://scenes/vehicle_rally.tscn", 
									"engine_force_value": 35, 
									"mass_kg/100": 50.0, 
									"suspension_stiffness": 40.0, 
									"suspension_travel": 2.0,
									"radius_wheel_m": 0.4,
									"four_wheel_drive": true}, 
						"truck": {"scene": "res://scenes/vehicle_truck.tscn", 
									"engine_force_value": 60, 
									"mass_kg/100": 300.0, 
									"suspension_stiffness": 90.0, 
									"suspension_travel":0.2,
									"radius_wheel_m": 0.4,
									"four_wheel_drive": false}}
var vehicle_type = "racer"
var vehicle_state = 'alive'  # 'alive', 'dying', 'dead'

func _ready():
	pass


func init(_pos=null, _player_number=null, _name=null):
	
	print("vehicle_body:init()")
	
	lifetime_so_far_sec = 0.0
	vehicle_state = "alive"
	cooldown_timer = weapons[weapon_select]["cooldown_timer"]
	
	if _player_number != null:
		player_number = _player_number
		
	if _name != null:
		name = _name
	
	if _pos != null:
		set_global_transform_origin(_pos)
		
	add_vehicle_mesh()
	add_main_collision_shapes()
	disable_vehicle_mesh_collision_shapes()
	position_vehicle_lights()
	position_wheels()
	position_raycasts()
	configure_vehicle_properties()
	init_visual_effects()
	
	total_damage = 0.0
	check_accel_damage_timer = 4.0


func init_visual_effects():
	
	lights_disabled = false
	
	$ParticlesSmoke.emitting = false
	$ParticlesSmoke.amount = 1
	$ParticlesSmoke.visible = false
	
	$Lights_onfire/OnFireLight1.light_energy = 0.0
	$Lights_onfire/OnFireLight2.light_energy = 0.0
	$Lights_onfire/OnFireLight4.light_energy = 0.0
	$Lights_onfire/OnFireLight5.light_energy = 0.0
	
	$Explosion2Light.visible = false
	$Explosion2Light.visible = false
	
	$Explosion.visible = false
	
	$Flames3D.emitting = false
	$Flames3D.amount = 1
	$Flames3D.visible = false

	lights_off()
	
	$Shield.visible = false


func dying_visual_effects():
	init_visual_effects()
	$Explosion2Light.visible = true # exept this one
	

func add_main_collision_shapes():
	
	# move the collisionshapes from the mesh import meta-data to the carbody
	var cs = $vehicle_mesh/positions/collision_shapes
	for ch in cs.get_children():
		if ch is CollisionShape:
			# ch.scale = $vehicle_mesh.scale
			cs.remove_child(ch)
			self.add_child(ch)


func add_vehicle_mesh():
	
	# delete any old vehicle mesh from previous life it at all
	for ch in get_children():
		if "vehicle_mesh" in ch.name:
			ch.queue_free()

	if player_number == 1:
		vehicle_type = "racer"
	elif player_number == 2:
		vehicle_type = "rally"
	elif player_number == 3:
		vehicle_type = "tank"
	elif player_number == 4:
		vehicle_type = "truck"
		
	var vt = vehicle_types[vehicle_type]
	var vehicle_mesh = load(vt["scene"]).instance()
	vehicle_mesh.name = "vehicle_mesh"
	add_child(vehicle_mesh)


func disable_vehicle_mesh_collision_shapes(disable=true):
	
	# disable the individual meshinstance collisionshape - used for exploding the vehicle into pieces
	for mi in $vehicle_mesh.get_node("mesh_instances").get_children():
		if mi.has_node("CollisionShape"):
			mi.get_node("CollisionShape").disabled = disable


func enable_vehicle_mesh_collision_shapes():
	disable_vehicle_mesh_collision_shapes(false)


func position_vehicle_lights():
	
	var pvl = $vehicle_mesh.get_node("positions").get_node("lights")
	$Lights/LightFrontRight.transform.origin = pvl.get_node("headlight_right").transform.origin
	$Lights/LightFrontLeft.transform.origin = pvl.get_node("headlight_left").transform.origin
	$Lights/LightBackRight.transform.origin = pvl.get_node("taillight_right").transform.origin
	$Lights/LightBackLeft.transform.origin = pvl.get_node("taillight_left").transform.origin


func position_wheels():
	
	var wh = $vehicle_mesh/positions/wheels
	
	# reposition the wheels 
	$Wheel1.transform.origin = wh.get_node("front_left").transform.origin
	$Wheel2.transform.origin = wh.get_node("rear_left").transform.origin
	$Wheel3.transform.origin = wh.get_node("front_right").transform.origin
	$Wheel4.transform.origin = wh.get_node("rear_right").transform.origin


func position_raycasts():
	# move the raycasts
	var rs = $vehicle_mesh/positions/raycasts
	for rc in rs.get_children():
		if rc is RayCast:
			rs.remove_child(rc)
			self.add_child(rc)


func configure_vehicle_properties():
	
	engine_force_value = vehicle_types[vehicle_type]["engine_force_value"]
	mass = vehicle_types[vehicle_type]["mass_kg/100"]
	var vt = vehicle_types[vehicle_type]
	set_wheel_parameters(vt["suspension_stiffness"], vt["suspension_travel"], vt["radius_wheel_m"])
	if vehicle_types[vehicle_type]["four_wheel_drive"] == true:
		get_wheel(1).use_as_traction = true  # front
		get_wheel(3).use_as_traction = true  # front
		get_wheel(2).use_as_traction = true
		get_wheel(4).use_as_traction = true
	else:
		get_wheel(1).use_as_traction = true  # front
		get_wheel(3).use_as_traction = true  # front
		get_wheel(2).use_as_traction = false
		get_wheel(4).use_as_traction = false


func set_wheel_parameters(ss, st, rw):
	for wheel_num in [1,2,3,4]:
		get_wheel(wheel_num).suspension_stiffness = ss
		get_wheel(wheel_num).suspension_travel = st
		get_wheel(wheel_num).wheel_radius = rw
		get_wheel(wheel_num).get_node("Wheel"+str(wheel_num)).scale = Vector3(rw, rw/4.0, rw)
	 

func re_parent_to_main_scene(child):
	remove_child(child)
	get_main_scene().call_deferred("add_child", child)
	print("reparented "+str(child.name))


func get_main_scene():
	return get_player().get_parent()


func check_lights():
	if get_main_scene().get_node("DirectionalLightSun").light_energy < 0.3: 
		# print("turning lights on")
		lights_on()
	else:
		# print("turning lights off")
		lights_off()


func flicker_lights():
	# damaged lights, and also the lights due to damage
	# small chance of turning off when damaged. slightly bigger chance of turing back on (should flicker)
	
	if rng.randf() < 0.1:
		$Lights_onfire/OnFireLight1.light_energy = 0.0
	else:
		$Lights_onfire/OnFireLight1.light_energy = total_damage/10.0
		
	if rng.randf() < 0.1:
		$Lights_onfire/OnFireLight2.light_energy = 0.0
	else:
		$Lights_onfire/OnFireLight2.light_energy = total_damage/10.0
		
	if rng.randf() < 0.1:
		$Lights_onfire/OnFireLight3.light_energy = 0.0
	else:
		$Lights_onfire/OnFireLight3.light_energy = total_damage/10.0
		
	if rng.randf() < 0.1:
		$Lights_onfire/OnFireLight4.light_energy = 0.0
	else:
		$Lights_onfire/OnFireLight4.light_energy = total_damage/10.0
		
	if rng.randf() < 0.1:
		$Lights_onfire/OnFireLight5.light_energy = 0.0
	else:
		$Lights_onfire/OnFireLight5.light_energy = total_damage/10.0
	
	
	
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
	var gw = get_wheel(wheel_num)
	if gw != null:
		return get_wheel(wheel_num).get_node("RayCastWheel"+str(wheel_num))
	else:
		return null


func check_ongoing_damage():
	if total_damage < max_damage:
		for raycast in [get_raycast(1), get_raycast(2), get_raycast(3), get_raycast(4), $RayCastCentreDown, $RayCastBonnetUp, $RayCastForward, $RayCastBackward, $RayCastLeft, $RayCastRight]:
			if check_raycast("lava", raycast) == true:
				# print("Player taking damage 1")
				return 1
		$LavaLight1.visible = false
		return 0
	return 0


func check_raycast(substring_in_hit_name, raycast):
	if raycast != null:
		if raycast.is_colliding():
			if substring_in_hit_name.to_lower() in raycast.get_collider().name.to_lower():
				# print("Vehicle raycast "+str(raycast.name)+": collision matches substring: "+str(substring_in_hit_name))
				$LavaLight1.visible = true
				return true
	return false


func _process(delta):
	
	print_timer += delta
		
	if global_transform.origin.y < -50.0:
		vehicle_state = "dead"
	
	if vehicle_state == "dying":
		explosion2_timer -= delta
		if explosion2_timer <= 0.0:
			$Explosion2Light.visible = false
			explosion2_timer = 0.2
		if dying_finished():
			vehicle_state = "dead"

	if total_damage >= max_damage:
		return

	check_accel_damage(delta)

	timer_1_sec -= delta
	if timer_1_sec <= 0.0:
		timer_1_sec = 1.0
		check_lights()
		var ongoing_damage = check_ongoing_damage()
		if ongoing_damage > 0:
			damage(ongoing_damage)

	timer_0_1_sec -= delta
	if timer_0_1_sec <= 0.0:
		# print("acceleration_calc_for_damage="+str(acceleration_calc_for_damage))
		flicker_lights()
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
		get_player().set_label_player_name()  # , total_damage, weapons[weapon_select].damage)
		get_player().set_label_lives_left()
		get_player().get_canvaslayer().get_node("cooldown").max_value = COOLDOWN_TIMER_DEFAULTS[weapons[weapon_select]["name"]]
		get_player().get_canvaslayer().get_node("cooldown").value = cooldown_timer

	lifetime_so_far_sec += delta
		
	if Input.is_action_just_released("cycle_weapon_player"+str(player_number)):
		cycle_weapon()
	
	if Input.is_action_just_released("fire_player"+str(player_number)) and weapons[weapon_select]["active"] == false and weapons[weapon_select]["cooldown_timer"] <= 0.0 and weapons[weapon_select]["enabled"] == true:
		# print("Player pressed fire")
		weapons[weapon_select]["cooldown_timer"] = COOLDOWN_TIMER_DEFAULTS[weapons[weapon_select].name]
		get_player().set_label_player_name()
		get_player().set_label_lives_left()
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


func check_accel_damage(delta):
	if check_accel_damage_timer <= 0.0:
		# print("acceleration_calc_for_damage="+str(acceleration_calc_for_damage))
		# print("accel_damage_threshold="+str(accel_damage_threshold))
		if acceleration_calc_for_damage > accel_damage_threshold:
			var rammed_another_car = false
			$crash_sound.playing = true
			if $RayCastFrontRamDamage1.is_colliding():
				var collider_name = $RayCastFrontRamDamage1.get_collider().name
				if "car" in collider_name.to_lower():
					print("player "+str(player_number)+" rammed "+str(collider_name))
					rammed_another_car = true
			if $RayCastFrontRamDamage2.is_colliding():
				var collider_name = $RayCastFrontRamDamage2.get_collider().name
				if "car" in collider_name.to_lower():
					print("player "+str(player_number)+" rammed "+str(collider_name))
					rammed_another_car = true
			if $RayCastFrontRamDamage3.is_colliding():
				var collider_name = $RayCastFrontRamDamage3.get_collider().name
				if "car" in collider_name.to_lower():
					print("player "+str(player_number)+" rammed "+str(collider_name))
					rammed_another_car = true
			if rammed_another_car == false:
				var damage = round(acceleration_calc_for_damage / accel_damage_threshold)
				print("damage="+str(damage))
				damage(damage)
			# else don't take any damage
				
			check_accel_damage_timer = 0.5
	else:
		check_accel_damage_timer -=delta


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
		get_player().set_label_player_name()
		get_player().set_label_lives_left()


func _physics_process(delta):
	
	var new_vel = get_linear_velocity()
	var new_vel_max = max(abs(new_vel.x), max(abs(new_vel.y), abs(new_vel.z)))
	
	# Smooth out the accel calc by using a 50/50 exponentially-weighted moving average
	acceleration_calc_for_damage = (0.5*acceleration_calc_for_damage) + (0.5*abs(new_vel_max - vel_max)/delta)
	
	vel_max = new_vel_max

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
			# if hit_by_missile["homing"]:
			# 	damage(weapons[2].damage)
			# else:
			#	damage(weapons[1].damage)
		else:
			var indirect_explosion_force = explosion_force/hit_by_missile["distance"]
			
			apply_impulse( Vector3(0,0,0), indirect_explosion_force*direction.normalized() )   # offset, impulse(=direction*force)
			# damage(1)
		angular_velocity =  Vector3(rng.randf_range(-10, 10), rng.randf_range(-10, 10), rng.randf_range(-10, 10)) 
			
		hit_by_missile["active"] = false


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
	$Flames3D.amount *= 4
	if $Flames3D.amount > 100:
		$Flames3D.amount = 100
	$Lights_onfire/OnFireLight1.light_energy = total_damage/20.0
	$Lights_onfire/OnFireLight2.light_energy = total_damage/20.0
	$Lights_onfire/OnFireLight4.light_energy = total_damage/20.0
	$Lights_onfire/OnFireLight5.light_energy = total_damage/20.0
	engine_force_value *= 0.75  # decrease engine power to indicate damage

	if total_damage >= max_damage and vehicle_state != "dying":
		print("damage: total_damage >= max_damage")
		start_vehicle_dying()

	get_player().set_label_player_name()
	get_player().set_label_lives_left()
	get_player().get_canvaslayer().get_node("health").value = max_damage-total_damage
	if max_damage-total_damage >= 7.0:
		get_player().get_canvaslayer().get_node("health").tint_progress = "#7e00ff00"  # green
	elif max_damage-total_damage <= 3.0:
		get_player().get_canvaslayer().get_node("health").tint_progress = "#7eff0000"  # red
	else:
		get_player().get_canvaslayer().get_node("health").tint_progress = "#7eff6c00"  # orange


func get_player():
	return get_parent().get_parent().get_parent()
	

func get_wheel(num):
	if has_node("Wheel"+str(num)):
		return get_node("Wheel"+str(num))
	else:
		return null


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
		weapon_instance.activate(get_node("/root/TownScene/Platforms/NukeSpawnPoint").global_transform.origin, 0.0, 0.0, 1, player_number, get_player())
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
	if "Nuke" in body.name:
		weapons[3].enabled = true
		body.get_parent().disable()  # disable the nuke powerup on a timer


func get_camera():
	return $CameraBase/Camera


func set_label(new_label):
	get_node( "../../CanvasLayer/Label").text = new_label


func start_vehicle_dying():
	
	if vehicle_state == "alive":
		print("start_vehicle_dying(): vehicle_state = "+str(vehicle_state))
		vehicle_state = "dying"
		# print("reset_car()")
		print("start_vehicle_dying(): total_damage >= max_damage")
		total_damage = max_damage
		
		$crash_sound.playing = true
		$Explosion/AnimationPlayer.play("explosion")
		
		$Wheel1.visible = false
		$Wheel2.visible = false
		$Wheel3.visible = false
		$Wheel4.visible = false
		
		dying_visual_effects()
		
		explosion2_timer = 0.25
		
		get_main_scene().start_timer_slow_motion()
		remove_main_collision_shapes()
		explode_vehicle_meshes()
		get_player().lives_left -= 1


func remove_main_collision_shapes():
	# remove the existing CollisionShapes based on the car structure (usually 3 or 4)
	for cs in get_children():
		if cs is CollisionShape: 
			cs.queue_free()  
	# Add a small rigid body so we don't fall through the ground
	var new_rigid_body = load("res://scenes/rigid_body.tscn").instance()
	add_child(new_rigid_body)


func explode_vehicle_meshes():
	for ch in get_children():
		if ch.name == "vehicle_mesh":
			ch.set_script(script_vehicle_detach_rigid_bodies)
			ch.set_process(true)
			ch.set_physics_process(true)
			ch.detach_rigid_bodies(0.1, self.mass)
			ch.name = "vehicle_parts_exploded"
			# self.remove_child(ch)
			# ch.set_as_toplevel(true)
			$Explosion2.emitting = true


func dying_finished():
	if vehicle_state == "dying":
		if $Explosion/AnimationPlayer.current_animation != "explosion":
			print("vehicle_state == 'dying' and $Explosion/AnimationPlayer.current_animation != 'explosion' = "+str($Explosion/AnimationPlayer.current_animation))
			return true
	return false