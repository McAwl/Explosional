extends VehicleBody


const STEER_SPEED = 1.5
const STEER_LIMIT = 0.6 #0.4
const EXPLOSION_STRENGTH = 50.0
const ENGINE_FORCE_VALUE_DEFAULT = 80
const script_vehicle_detach_rigid_bodies = preload("res://logic/vehicle_detach_rigid_bodies.gd")

var steer_target = 0

var print_timer = 0.0

export var engine_force_value = ENGINE_FORCE_VALUE_DEFAULT  #40
var engine_force_ewma
var player_number
var num_players
var camera
export var speed = 0.0
var speed_low_limit = 5
var rng = RandomNumberGenerator.new()

var cooldown_timer = ConfigWeapons.COOLDOWN_TIMER_DEFAULTS["mine"]
var timer_0_1_sec = 0.1
var timer_1_sec = 1.0  # timer to eg: check if car needs to turn light on 
var timer_1_sec_physics = 1.0  # to check and correct clipping, etc
var lifetime_so_far_sec = 0.0  # to eg disable air strikes for a bit after re-spawn
var hit_by_missile = {"active": false, "homing": null, "origin": null, "velocity": null, "direct_hit": null, "distance": null}
var max_damage = 10.0
var total_damage = 0.0
var take_damage = true
var wheel_positions = []
var wheels = []
# this is changingstate info, see config_weapons.gd for constants
var weapons = {0: {"name": "mine", "active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS["mine"], "enabled": true}, \
			   1: {"name": "rocket", "active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS["rocket"], "enabled": true}, \
			   2: {"name": "missile", "active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS["missile"], "enabled": true}, \
			   3: {"name": "nuke", "active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS["nuke"], "enabled": false, "test_mode": false},
			   4: {"name": "ballistic", "active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS["ballistic"], "enabled": true}}
var weapon_select = 0
var lights_disabled = false
var acceleration_calc_for_damage = 0.0
var acceleration_fwd_0_1_ewma = 0.0
var acceleration_fwd_0_1 = 0.0
var vel_max = 0.0
var check_accel_damage_timer = 3.0
var accel_damage_threshold = 50.0
var fwd_mps = 0.0
var old_fwd_mps_0_1 = 0.0
var fwd_mps_0_1_ewma = 0.0
var fwd_mps_0_1 = 0.0
var explosion2_timer = 0.2
var knock_back_firing_ballistic = false  # knock the vehicle backwards when firing a ballistic weapons

var vehicle_types = {	"Tank":  {"scene": "res://scenes/vehicle_tank.tscn", 
									"engine_force_value": 150,  # keep this at 1x mass
									"mass_kg/100": 200.0, 
									"suspension_stiffness": 100.0, 
									"suspension_travel": 0.1,
									"all_wheel_drive": true,
									"wheel_friction_slip": 15.0,
									"wheel_roll_influence": 0.9,
									"brake": 40.0}, 
						"Racer": {"scene": "res://scenes/vehicle_racer.tscn", 
									"engine_force_value": 220,  # keep this at 3x mass
									"mass_kg/100": 70.0, 
									"suspension_stiffness": 75.0, 
									"suspension_travel": 0.25,
									"all_wheel_drive": false,
									"wheel_friction_slip": 1.1,
									"wheel_roll_influence": 0.9,
									"brake": 10.0}, 
						"Rally": {"scene": "res://scenes/vehicle_rally.tscn", 
									"engine_force_value": 70,  # keep this at 3x mass
									"mass_kg/100": 50.0, 
									"suspension_stiffness": 40.0, 
									"suspension_travel": 2.0,
									"all_wheel_drive": true,
									"wheel_friction_slip": 1.3,
									"wheel_roll_influence": 0.9,
									"brake": 5.0}, 
						"Truck": {"scene": "res://scenes/vehicle_truck.tscn", 
									"engine_force_value": 200,  # keep this at 1x mass
									"mass_kg/100": 200.0, 
									"suspension_stiffness": 90.0, 
									"suspension_travel":0.2,
									"all_wheel_drive": false,
									"wheel_friction_slip":1.0,
									"wheel_roll_influence": 0.9,
									"brake": 40.0}}
var vehicle_type = "racer"
var vehicle_state = 'alive'  # 'alive', 'dying', 'dead'
var set_pos = false
var pos


func _ready():
	pass


func init(_pos=null, _player_number=null, _name=null, _num_players=null):
	
	print("VehicleBody:init()")
	
	lifetime_so_far_sec = 0.0
	vehicle_state = "alive"
	cooldown_timer = weapons[weapon_select]["cooldown_timer"]
	
	if _player_number != null:
		player_number = _player_number
		
	if _name != null:
		name = _name
	
	pos = _pos
	num_players = _num_players
	print("VehicleBody() init: num_players="+str(num_players))
	
	if player_number == 1:
		vehicle_type = "Racer"
	elif player_number == 2:
		vehicle_type = "Rally"
	elif player_number == 3:
		vehicle_type = "Tank"
	elif player_number == 4:
		vehicle_type = "Truck" 
	else:
		vehicle_type = "Racer"
	
	print("vehicle_type="+str(vehicle_type))
	# Depending on vehicle type, we look for its nodes
	var vehicle_type_node = $VehicleTypes.get_node(str(vehicle_type))
	if vehicle_type_node == null:
		return false
	# move all the vehicle type nodes to the correct location
	for ch in vehicle_type_node.get_children():
		# var ctm = ch.get_node(ch.name)
		if ch.name in ["Raycasts", "Positions", "MeshInstances", "Lights", "CameraBasesTargets"]:  # move from 1 level down
			vehicle_type_node.remove_child(ch)
			if ch.name == "CameraBasesTargets":
				# print("ctm="+str(ctm))
				print("ch="+str(ch))
				$CameraBase.add_child(ch)
			else:
				add_child(ch)
		elif ch.name in ["Wheels", "CollisionShapes", "Effects"]:  # move from 2 levels down
			for ctmch in ch.get_children():
				if ch.name in ["Wheels", "CollisionShapes"]:
					ch.remove_child(ctmch)
					add_child(ctmch)
				elif ch.name in ["Effects"]:
					for ctmchch in ctmch.get_children():  # Damage
						ctmch.remove_child(ctmchch)
						$Effects.get_node(ctmch.name).add_child(ctmchch)

	# Delete all the vehicle type nodes
	if has_node("VehicleTypes"):
		get_node("VehicleTypes").queue_free()
	
	if not vehicle_type in vehicle_types:
		print("vehicle_type "+str(vehicle_type)+" no found")
		return false
		
	configure_vehicle_properties()
	init_visual_effects()
	init_audio_effects()
	
	total_damage = 0.0
	check_accel_damage_timer = 4.0
	init_camera(num_players)
	return true


func init_audio_effects():
	engine_sound_on()


func engine_sound_on():
	if vehicle_type == "racer":
		$Effects/Audio/EngineSound.playing = false
		$Effects/Audio/EngineSoundRally.playing = true
	elif vehicle_type == "rally":
		$Effects/Audio/EngineSound.playing = false
		$Effects/Audio/EngineSoundRally.playing = true
	elif vehicle_type == "tank":
		$Effects/Audio/EngineSound.playing = true
		$Effects/Audio/EngineSoundRally.playing = false
	elif vehicle_type == "truck":
		$Effects/Audio/EngineSound.playing = true
		$Effects/Audio/EngineSound.playing = false
	else:
		$Effects/Audio/EngineSound.playing = false
		$Effects/Audio/EngineSoundRally.playing = true


func engine_sound_off():
	$Effects/Audio/EngineSound.playing = false
	$Effects/Audio/EngineSoundRally.playing = false


func init_camera(_num_players):
	$CameraBase/Camera.number_of_players = num_players


func init_visual_effects():
	
	lights_disabled = false
	
	$Effects/Damage/ParticlesSmoke.emitting = false
	$Effects/Damage/ParticlesSmoke.amount = 1
	$Effects/Damage/ParticlesSmoke.visible = false
	
	$Effects/Damage/LightsOnFire/OnFireLight1.visible = true
	$Effects/Damage/LightsOnFire/OnFireLight1.light_energy = 0.0
	$Effects/Damage/LightsOnFire/OnFireLight2.light_energy = 0.0
	$Effects/Damage/LightsOnFire/OnFireLight4.light_energy = 0.0
	$Effects/Damage/LightsOnFire/OnFireLight5.light_energy = 0.0
	
	$Effects/Damage/Explosion2Light.visible = false
	
	$Effects/Damage/Explosion.visible = false
	
	$Effects/Damage/Flames3D.emitting = false
	$Effects/Damage/Flames3D.amount = 1
	$Effects/Damage/Flames3D.visible = false

	lights_off()
	
	$Effects/Shield.visible = false


func dying_visual_effects():
	init_visual_effects()
	$Effects/Damage/Explosion2Light.visible = true # exept this one


func configure_vehicle_properties():
	
	engine_force_value = vehicle_types[vehicle_type]["engine_force_value"]
	mass = vehicle_types[vehicle_type]["mass_kg/100"]
	var vts = vehicle_types[vehicle_type]
	set_wheel_parameters(vts, vehicle_type)


func set_wheel_parameters(_vts, _vehicle_type):
	
	for wh in get_children():
		if wh is VehicleWheel:
			wh.visible = true
			wh.suspension_stiffness = _vts["suspension_stiffness"]
			wh.suspension_travel = _vts["suspension_travel"]
			wh.wheel_friction_slip = _vts["wheel_friction_slip"]
			wh.wheel_roll_influence = _vts["wheel_roll_influence"]
			for ch2 in wh.get_children():
				if ch2 is MeshInstance:
					ch2.visible = false
				if ch2 is CSGTorus and _vehicle_type != "tank":
					ch2.visible = true
	
	if vehicle_type == "tank":
		get_wheel(5).use_as_traction = true  # middle
		get_wheel(6).use_as_traction = true  # middle
	else:
		if _vts["all_wheel_drive"] == true:
			get_wheel(1).use_as_traction = true  # front
			get_wheel(3).use_as_traction = true  # front
			get_wheel(2).use_as_traction = true  # rear
			get_wheel(4).use_as_traction = true  # rear
		else:
			get_wheel(1).use_as_traction = true  # front
			get_wheel(3).use_as_traction = true  # front
			get_wheel(2).use_as_traction = false  # rear
			get_wheel(4).use_as_traction = false  # rear
	 

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
	
	for l in [1, 2, 3, 4, 5]:
		if rng.randf() < 0.1:
			$Effects/Damage/LightsOnFire.get_node("OnFireLight"+str(l)).light_energy = 0.0
		else:
			$Effects/Damage/LightsOnFire.get_node("OnFireLight"+str(l)).light_energy = total_damage/10.0

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
		return $Raycasts.get_node("RayCastWheel"+str(wheel_num))
	else:
		return null


func check_ongoing_damage():
	if total_damage < max_damage:
		for raycast in [get_raycast(1), get_raycast(2), get_raycast(3), get_raycast(4), $Raycasts/RayCastCentreDown, $Raycasts/RayCastBonnetUp, $Raycasts/RayCastForward, $Raycasts/RayCastBackward, $Raycasts/RayCastLeft, $Raycasts/RayCastRight]:
			if check_raycast("lava", raycast) == true:
				# print("Player taking damage 1")
				return 1
		$Effects/Damage/LavaLight1.visible = false
		return 0
	return 0


func check_raycast(substring_in_hit_name, raycast):
	if raycast != null:
		if raycast.is_colliding():
			if substring_in_hit_name.to_lower() in raycast.get_collider().name.to_lower():
				# print("Vehicle raycast "+str(raycast.name)+": collision matches substring: "+str(substring_in_hit_name))
				$Effects/Damage/LavaLight1.visible = true
				return true
	return false


func _process(delta):
	
	if set_pos == false:
		set_global_transform_origin()

	print_timer += delta
		
	if global_transform.origin.y < -50.0:
		vehicle_state = "dead"
	
	if vehicle_state == "dying":
		explosion2_timer -= delta
		if explosion2_timer <= 0.0:
			$Effects/Damage/Explosion2Light.visible = false
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
			add_damage(ongoing_damage)

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
		get_player().get_canvaslayer().get_node("cooldown").max_value = ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[weapons[weapon_select]["name"]]
		get_player().get_canvaslayer().get_node("cooldown").value = cooldown_timer
		
		# Update all the 0.1 sec physical calculations
		# speed
		old_fwd_mps_0_1 = fwd_mps_0_1
		fwd_mps_0_1 = transform.basis.xform_inv(linear_velocity).z  # global linear velocity rotated to our forward direction (z)
		fwd_mps_0_1_ewma = (0.5*fwd_mps_0_1) + (0.5*fwd_mps_0_1)  # smooth it out over 1 sec
		# accel
		acceleration_fwd_0_1 = 0.1 * (fwd_mps_0_1-old_fwd_mps_0_1)  # calc fwd accel every 0.1s
		acceleration_fwd_0_1_ewma = (0.9*acceleration_fwd_0_1_ewma) + (0.1*acceleration_fwd_0_1)  # smooth it out over 1 sec


	lifetime_so_far_sec += delta
		
	if Input.is_action_just_released("cycle_weapon_player"+str(player_number)):
		cycle_weapon()
	
	if Input.is_action_just_released("fire_player"+str(player_number)) and weapons[weapon_select]["active"] == false and weapons[weapon_select]["cooldown_timer"] <= 0.0 and weapons[weapon_select]["enabled"] == true:
		# print("Player pressed fire")
		weapons[weapon_select]["cooldown_timer"] = ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[weapons[weapon_select].name]
		get_player().set_label_player_name()
		get_player().set_label_lives_left()
		if weapon_select == 0 or weapon_select == 3:  # mine or nuke
			fire_mine_or_nuke()
		elif weapon_select == 1:
			fire_missile_or_rocket()
		elif weapon_select == 2:
			fire_missile_or_rocket()
		elif weapon_select == 4:
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
			$Effects/Audio/CrashSound.playing = true
			$Effects/Audio/CrashSound.volume_db = 0.0
			if $Raycasts/RayCastFrontRamDamage1.is_colliding():
				var collider_name = $Raycasts/RayCastFrontRamDamage1.get_collider().name
				if "car" in collider_name.to_lower():
					print("player "+str(player_number)+" rammed "+str(collider_name))
					rammed_another_car = true
			if $Raycasts/RayCastFrontRamDamage2.is_colliding():
				var collider_name = $Raycasts/RayCastFrontRamDamage2.get_collider().name
				if "car" in collider_name.to_lower():
					print("player "+str(player_number)+" rammed "+str(collider_name))
					rammed_another_car = true
			if $Raycasts/RayCastFrontRamDamage3.is_colliding():
				var collider_name = $Raycasts/RayCastFrontRamDamage3.get_collider().name
				if "car" in collider_name.to_lower():
					print("player "+str(player_number)+" rammed "+str(collider_name))
					rammed_another_car = true
			if rammed_another_car == false:
				var damage = round(acceleration_calc_for_damage / accel_damage_threshold)
				print("damage="+str(damage))
				add_damage(damage)
			# else don't take any damage
				
			check_accel_damage_timer = 0.5
		elif acceleration_calc_for_damage > accel_damage_threshold/2.0:
			$Effects/Audio/CrashSound.playing = true
			$Effects/Audio/CrashSound.volume_db = -18.0
			
	else:
		check_accel_damage_timer -=delta


func cycle_weapon():
		weapon_select += 1
		if weapon_select > 4:
			weapon_select = 0
		if weapons[weapon_select].enabled == false:
			weapon_select += 1
		if weapon_select > 4:
			weapon_select = 0
		get_player().get_canvaslayer().get_node("icon_mine").hide()
		get_player().get_canvaslayer().get_node("icon_rocket").hide()
		get_player().get_canvaslayer().get_node("icon_missile").hide()
		get_player().get_canvaslayer().get_node("icon_ballistic").hide()
		get_player().get_canvaslayer().get_node("icon_nuke").hide()
		get_player().get_canvaslayer().get_node("icon_"+weapons[weapon_select].name).show()
		get_player().set_label_player_name()
		get_player().set_label_lives_left()


func _physics_process(delta):
	
	var new_vel = get_linear_velocity()
	var new_vel_max = max(abs(new_vel.x), max(abs(new_vel.y), abs(new_vel.z)))
	fwd_mps = transform.basis.xform_inv(linear_velocity).z  # global velocity rotated to our forward (z) direction
	# Smooth out the accel calc by using a 50/50 exponentially-weighted moving average
	acceleration_calc_for_damage = (0.5*acceleration_calc_for_damage) + (0.5*abs(new_vel_max - vel_max)/delta)
	vel_max = new_vel_max

	if total_damage < max_damage:
		
		steer_target = Input.get_action_strength("turn_left_player"+str(player_number)) - Input.get_action_strength("turn_right_player"+str(player_number))
		steer_target *= STEER_LIMIT

		var old_engine_force = engine_force
	
		if Input.is_action_pressed("accelerate_player"+str(player_number)):
			# Increase engine force at low speeds to make the initial acceleration faster.
			if fwd_mps < speed_low_limit and speed != 0:
				engine_force = clamp(engine_force_value * speed_low_limit / fwd_mps, 0, 100)
			else:
				engine_force = engine_force_value
		else:
			engine_force = 0
			
		if Input.is_action_pressed("reverse_player"+str(player_number)):
			engine_force = -engine_force_value/2.0
			if fwd_mps > speed_low_limit:
				brake = vehicle_types[vehicle_type]["brake"] / 5.0
		else:
			brake = 0.0
			
		if delta < 1.0:
			engine_force_ewma = (delta*engine_force) + ((1.0-delta)*old_engine_force)
	

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

	# If we've fired a ballistic weapon, know backwards here
	if knock_back_firing_ballistic == true:
		print("knock_back_firing_ballistic: knocing vehicle back")
		knock_back_firing_ballistic = false
		apply_impulse( Vector3(0,0,0), -100.0*transform.basis.z )   # offset, impulse(=direction*force)
		apply_impulse( Vector3(0,0,0), 50.0*transform.basis.y )   # offset, impulse(=direction*force)

	timer_1_sec_physics -= delta
	if timer_1_sec_physics < 0.0:
		timer_1_sec_physics = 1.0
		check_for_clipping()


func check_for_clipping():
	if abs(fwd_mps_0_1) < 0.1:  # stationary
		print("Checking for clipping")
		var num_wheels_clipped = 0
		for raycast in $Raycasts.get_children():
			if "Wheel" in raycast.name:
				if not raycast.is_colliding():
					num_wheels_clipped += 1
					print("raycast "+raycast.name+" not colliding")
				else:
					print("raycast "+raycast.name+" is colliding with "+str(raycast.get_collider().name))
		if num_wheels_clipped > 0:
			print("applying impulse - wheel(s) are clipped")
			apply_impulse( Vector3(0, -10.0, 0), Vector3(0.0, 5*vehicle_types[vehicle_type]["mass_kg/100"], 0.0) )   # from underneath, upwards force
			check_accel_damage_timer = 2.0  # disable damage for temporarily
	

func update_speed():
	speed = linear_velocity.length()


func get_speed():
	update_speed()
	return speed


func get_speed2():
	return transform.basis.xform_inv(linear_velocity).z


func get_global_offset_pos(offset_y, mult_y, offset_z, mult_z):
	var global_pos = global_transform.origin
	global_pos -= (offset_z*mult_z)*Vector3.FORWARD
	global_pos += (offset_y*mult_y)*Vector3.UP
	return global_pos


func add_damage(amount):
	total_damage += amount
	if $Effects/Damage/ParticlesSmoke.emitting == false:
		$Effects/Damage/ParticlesSmoke.emitting = true
		$Effects/Damage/Flames3D.emitting = true
	$Effects/Damage/ParticlesSmoke.amount *= 2  # increase engine smoke indicating damage
	$Effects/Damage/Flames3D.visible = true
	$Effects/Damage/Flames3D.amount *= 4
	if $Effects/Damage/Flames3D.amount > 100:
		$Effects/Damage/Flames3D.amount = 100
	$Effects/Damage/LightsOnFire/OnFireLight1.light_energy = total_damage/20.0
	$Effects/Damage/LightsOnFire/OnFireLight2.light_energy = total_damage/20.0
	$Effects/Damage/LightsOnFire/OnFireLight4.light_energy = total_damage/20.0
	$Effects/Damage/LightsOnFire/OnFireLight5.light_energy = total_damage/20.0
	engine_force_value *= 0.75  # decrease engine power to indicate damage

	if total_damage >= max_damage and vehicle_state != "dying":
		print("damage: total_damage >= max_damage")
		start_vehicle_dying()


func get_player():
	return get_parent().get_parent().get_parent()
	

func get_wheel(num):
	if has_node("Wheel"+str(num)):
		return get_node("Wheel"+str(num))
	else:
		return null


func fire_mine_or_nuke():
	# print("Firing weapon="+str(weapon_select))
	var weapon_instance = load(ConfigWeapons.SCENE[weapons[weapon_select]["name"]]).instance()
	add_child(weapon_instance) 
	weapon_instance.rotation_degrees = rotation_degrees
	weapons[weapon_select]["active"] = true
	if weapon_select == 0:
		weapon_instance.set_as_mine()
		weapon_instance.activate($Positions/Weapons/BombPosition.global_transform.origin, linear_velocity, angular_velocity, 1, player_number, get_player())
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
	
	var weapon_instance = load(ConfigWeapons.SCENE[weapons[weapon_select]["name"]]).instance()
	weapons[weapon_select]["instance"] = weapon_instance
	add_child(weapon_instance)
	# Shoot out fast (current speed + muzzle speed), it will then slow/speed to approach weapon_instance.target_speed	
	weapon_instance.weapon_type = weapon_select
	weapon_instance.weapon_type_name = ConfigWeapons.weapon_types[weapon_select]["name"]
	weapon_instance.velocity = (transform.basis.z.normalized()) * (weapon_instance.muzzle_speed() + abs(transform.basis.xform_inv(linear_velocity).z))  
	weapon_instance.linear_velocity = linear_velocity  # initial only, this is not used, "velocity" is used to change it's position
	weapon_instance.angular_velocity = angular_velocity
	if weapon_select == 2:
		weapon_instance.velocity[1] += 1.0   # angle it up a bit
		weapon_instance.global_transform.origin = $Positions/Weapons/MissilePosition.global_transform.origin
	else:
		weapon_instance.global_transform.origin = $Positions/Weapons/RocketPosition.global_transform.origin
		weapon_instance.velocity[1] -= 0.5  # angle the rocket down a bit
	if weapon_select == 1:
		weapon_instance.activate(player_number, false)  # homing = false
	elif weapon_select == 4:
		knock_back_firing_ballistic = true
		weapon_instance.activate(player_number, false)  # homing = false
		weapon_instance.get_node("ParticlesThrust").visible = false
		weapon_instance.velocity += Vector3.UP * 5.0  # fire upwards a bit
		$Effects/Audio/GunshotSound.playing = true
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


func set_global_transform_origin():
	if is_inside_tree() and set_pos == false:
		global_transform.origin = pos
		set_pos = true
	else:
		print("_process(): warning: vehicle not is_inside_tree()")


func _on_CarBody_body_entered(body):
	# print("vehicle: _on_CarBody_body_entered name="+str(body.name))
	if "Lava" in body.name:
		# print("Taking max_damage damage")
		add_damage(max_damage)
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
		
		for ch in $Effects/Audio.get_children():  # turn off engine sounds
			ch.playing = false
		
		$Effects/Audio/CrashSound.playing = true
		$Effects/Damage/Explosion/AnimationPlayer.play("explosion")
		
		remove_nodes_for_dying()
		
		dying_visual_effects()
		
		explosion2_timer = 0.25
		
		get_main_scene().start_timer_slow_motion()
		remove_main_collision_shapes()
		explode_vehicle_meshes()
		get_player().lives_left -= 1
	else:
		print("start_vehicle_dying(): error, shouldn't be here. vehicle_state="+str(vehicle_state))


func remove_nodes_for_dying():
	remove_wheels()
	remove_raycasts()
	# remove_weapon_positions()


func remove_wheels():
	#remove the wheels: we'll then make the wheel meshes from the mesh import visible
	for vw in get_children():
		if vw is VehicleWheel:
			vw.queue_free()


func remove_raycasts():
	#remove the raycasts
	for rc in get_children():
		if rc is RayCast:
			rc.queue_free()


func remove_main_collision_shapes():
	# remove the existing CollisionShape(s) based on the car structure
	for cs in get_children():
		if cs is CollisionShape: 
			cs.queue_free()  
	# Add a small CollisionShape so we don't fall through the ground
	var new_rigid_body = load("res://scenes/exploded_vehicle_part.tscn").instance()
	var cs = new_rigid_body.get_node("CollisionShape")
	new_rigid_body.remove_child(cs)
	add_child(cs)
	new_rigid_body.queue_free()


func explode_vehicle_meshes():
	# 
	if self.has_node("MeshInstances"):
		var vm = get_node("MeshInstances")
		print("Found node MeshInstances: destroying...")
		print("explode_vehicle_meshes(): self.has_node('MeshInstances')")
		print("self.translation="+str(self.translation))
		vm.set_script(script_vehicle_detach_rigid_bodies)
		vm.set_process(true)
		vm.set_physics_process(true)
		vm.detach_rigid_bodies(0.001, self.mass, self.linear_velocity, self.global_transform.origin)
		# self.remove_child(ch)
		# ch.set_as_toplevel(true)
		$Effects/Damage/Explosion2.emitting = true
		# move the exploded mesh to the player, as the VehicleBody will be deleted after the explosion
		remove_child(vm)
		get_player().add_child(vm)
		vm.name = "vehicle_parts_exploded"
		# Move the target cameras to the centre of the body
		$CameraBase/CameraBasesTargets/CamTargetForward.translation = Vector3(0.0, 0.0, 0.0)
		$CameraBase/CameraBasesTargets/CamTargetForward_UD.translation = Vector3(0.0, 0.0, 0.0)
		$CameraBase/CameraBasesTargets/CamTargetReverse.translation = Vector3(0.0, 0.0, 0.0)
		$CameraBase/CameraBasesTargets/CamTargetReverse_UD.translation = Vector3(0.0, 0.0, 0.0)


func dying_finished():
	if vehicle_state == "dying":
		if $Effects/Damage/Explosion/AnimationPlayer.current_animation != "explosion":
			print("vehicle_state == 'dying' and $Explosion/AnimationPlayer.current_animation != 'explosion' = "+str($Effects/Damage/Explosion/AnimationPlayer.current_animation))
			return true
	return false
