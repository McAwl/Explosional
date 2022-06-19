extends VehicleBody

const SCRIPT_VEHICLE_DETACH_RIGID_BODIES = preload("res://vehicles/vehicle_detach_rigid_bodies.gd")  # Global.vehicle_detach_rigid_bodies_folder)

var steer_target: float = 0

var print_timer: float = 0.0

export var engine_force_value: float = ConfigVehicles.ENGINE_FORCE_VALUE_DEFAULT  #40
var engine_force_ewma: float
var player_number: int
var camera: Camera
export var speed: float = 0.0
var speed_low_limit: float = 5.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var cooldown_timer: float = ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.MINE]
var timer_0_1_sec: float = 0.1
var timer_1_sec: float = 1.0  # timer to eg: check if car needs to turn light on 
var timer_1_sec_physics: float = 1.0  # to check and correct clipping, etc
var lifetime_so_far_sec: float = 0.0  # to eg disable air strikes for a bit after re-spawn
var hit_by_missile: Dictionary = {"active": false, "homing": null, "origin": null, "velocity": null, "direct_hit": null, "distance": null}
var max_damage: float = 10.0
var total_damage: float = 0.0
var take_damage: bool = true
var wheel_positions: Array = []
var wheels: Array = []

# this is changingstate info, see config_weapons.gd for constants
var weapons_state: Dictionary = {
	ConfigWeapons.Type.MINE: {"active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.MINE], "enabled": true}, \
	ConfigWeapons.Type.ROCKET: {"active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.ROCKET], "enabled": true}, \
	ConfigWeapons.Type.MISSILE: {"active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.MISSILE], "enabled": true}, \
	ConfigWeapons.Type.NUKE: {"active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.NUKE], "enabled": false, "test_mode": false},
	ConfigWeapons.Type.BALLISTIC: {"active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.BALLISTIC], "enabled": true},
	ConfigWeapons.Type.BOMB: {"active": false, "enabled": false, "test_mode": false},
	ConfigWeapons.Type.BALLISTIC_MISSILE: {"active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.BALLISTIC_MISSILE], "enabled": true},
	}

var weapon_select: int = ConfigWeapons.Type.MINE
var lights_disabled: bool = false
var acceleration_calc_for_damage: float = 0.0
var acceleration_calc_for_damage2: float = 0.0
var acceleration_fwd_0_1_ewma: float = 0.0
var acceleration_fwd_0_1: float = 0.0
var vel: Vector3
const ACCEL_DAMAGE_THRESHOLD: float = 50.0
const CHECK_ACCEL_DAMAGE_INTERVAL: float = 0.5
var accel_damage_enabled: bool = false
var fwd_mps: float = 0.0
var old_fwd_mps_0_1: float = 0.0
var fwd_mps_0_1_ewma: float = 0.0
var fwd_mps_0_1: float = 0.0
var explosion2_timer: float = 0.2
var knock_back_firing_ballistic: bool = false  # knock the vehicle backwards when firing a ballistic weapons
var vehicle_state: int = ConfigVehicles.AliveState.ALIVE 
var set_pos: bool = false
var pos: Vector3


func _ready():
	vehicle_state = ConfigVehicles.AliveState.ALIVE


func init(_pos=null, _player_number=null, _name=null) -> bool:
	
	#print("VehicleBody:init()")
	
	lifetime_so_far_sec = 0.0
	cooldown_timer = weapons_state[weapon_select]["cooldown_timer"]
	
	if _player_number != null:
		player_number = _player_number
		
	if _name != null:
		name = _name
	
	pos = _pos
	#print("VehicleBody() init: StatePlayers.num_players()="+str(StatePlayers.num_players()))
	
	#print("vehicle="+str(StatePlayers.players[player_number]["vehicle"]))
	# Depending on vehicle type, we look for its nodes
	var vehicle_type_node: Spatial = $VehicleTypes.get_node(ConfigVehicles.nice_name[StatePlayers.players[player_number]["vehicle"]]) as Spatial
	if vehicle_type_node == null:
		return false
	# move all the vehicle type nodes to the correct location
	for ch in vehicle_type_node.get_children():
		# var ctm = ch.get_node(ch.name)
		if ch.name in ["Raycasts", "Positions", "MeshInstances", "Lights", "CameraBasesTargets"]:  # move from 1 level down
			vehicle_type_node.remove_child(ch)
			if ch.name == "CameraBasesTargets":
				# print("ctm="+str(ctm))
				#print("ch="+str(ch))
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
	
	print("StatePlayers.players[player_number]['vehicle']="+str(StatePlayers.players[player_number]["vehicle"]))
	if StatePlayers.players[player_number]["vehicle"] < 0:  # in ConfigVehicles.Type:
		print("vehicle_type "+str(StatePlayers.players[player_number]["vehicle"])+" not found in ConfigVehicles.Type="+str(ConfigVehicles.Type))
		return false
		
	configure_vehicle_properties()
	configure_weapons()
	init_visual_effects(true)
	init_audio_effects()
	
	total_damage = 0.0
	#$CheckAccelDamage.wait_time = CHECK_ACCEL_DAMAGE_INTERVAL*8.0  # so the vehicle doesn't take damage with initial spawn fall
	$CheckAccelDamage.start(4.0)
	
	init_camera(StatePlayers.num_players())
	return true


func configure_weapons() -> void:
	for k in ConfigWeapons.Type.values():  # .keys():
		#print("checking weapon "+str(k))  # 0=mine, etc
		var vt = StatePlayers.players[player_number]["vehicle"]
		#print("vt="+str(vt))
		if vt in ConfigWeapons.vehicle_weapons[k]:
			#print("vt "+str(vt)+" has weapon "+str(k))
			weapons_state[k]["enabled"] = true
			weapon_select = k
			set_icon()
		else:
			#print("vt "+str(vt)+" doesnt have weapon "+str(k))
			weapons_state[k]["enabled"] = false


func init_audio_effects() -> void:
	engine_sound_on()


func engine_sound_on() -> void:
	#print("engine_sound_on(): "+str(StatePlayers.players[player_number]["vehicle"]))
	match StatePlayers.players[player_number]["vehicle"]:
		ConfigVehicles.Type.RACER:
			$Effects/Audio/EngineSound.playing = false
			$Effects/Audio/EngineSoundRally.playing = true
		ConfigVehicles.Type.RALLY:
			$Effects/Audio/EngineSound.playing = false
			$Effects/Audio/EngineSoundRally.playing = true
		ConfigVehicles.Type.TANK:
			$Effects/Audio/EngineSound.playing = true
			$Effects/Audio/EngineSound.playing = false
		ConfigVehicles.Type.TRUCK:
			$Effects/Audio/EngineSound.playing = true
			$Effects/Audio/EngineSound.playing = false
		_:
			print("Warning: using defain engine sound")
			$Effects/Audio/EngineSound.playing = false
			$Effects/Audio/EngineSoundRally.playing = true


func engine_sound_off() -> void:
	$Effects/Audio/EngineSound.playing = false
	$Effects/Audio/EngineSoundRally.playing = false


func init_camera(_num_players) -> void:
	$CameraBase/Camera.number_of_players = StatePlayers.num_players()


func init_visual_effects(start) -> void:
	
	lights_disabled = false
	
	$Effects/Damage/ParticlesSmoke.emitting = false
	$Effects/Damage/ParticlesSmoke.amount = 1
	$Effects/Damage/ParticlesSmoke.visible = false
	
	$Effects/Damage/LightsOnFire/OnFireLight1.visible = true
	$Effects/Damage/LightsOnFire/OnFireLight1.light_energy = 0.0
	$Effects/Damage/LightsOnFire/OnFireLight2.light_energy = 0.0
	$Effects/Damage/LightsOnFire/OnFireLight4.light_energy = 0.0
	$Effects/Damage/LightsOnFire/OnFireLight5.light_energy = 0.0
	
	$Effects/Damage/Flames3D.emitting = false
	$Effects/Damage/Flames3D.amount = 1
	$Effects/Damage/Flames3D.visible = false

	lights_off()
	
	$Effects/Shield.visible = false
	
	if start == false:
		engine_sound_off()


func dying_visual_effects() -> void:
	init_visual_effects(false)


func configure_vehicle_properties() -> void:
	var vts: int = StatePlayers.players[player_number]["vehicle"]
	#print("vts="+str(vts))
	engine_force_value = ConfigVehicles.config[vts]["engine_force_value"]
	mass = ConfigVehicles.config[vts]["mass_kg/100"]
	set_wheel_parameters(vts)


func set_wheel_parameters(_vts) -> void:
	
	for wh in get_children():
		if wh is VehicleWheel:
			wh.visible = true
			wh.suspension_stiffness = ConfigVehicles.config[_vts]["suspension_stiffness"]
			wh.suspension_travel = ConfigVehicles.config[_vts]["suspension_travel"]
			wh.wheel_friction_slip = ConfigVehicles.config[_vts]["wheel_friction_slip"]
			wh.wheel_roll_influence = ConfigVehicles.config[_vts]["wheel_roll_influence"]
			for ch2 in wh.get_children():
				if ch2 is MeshInstance:
					ch2.visible = false
				if ch2 is CSGTorus and StatePlayers.players[player_number]["vehicle"] != ConfigVehicles.Type.TANK:
					ch2.visible = true
	
	if StatePlayers.players[player_number]["vehicle"] == ConfigVehicles.Type.TANK:
		get_wheel(5).use_as_traction = true  # middle
		get_wheel(6).use_as_traction = true  # middle
	else:
		if ConfigVehicles.config[_vts]["all_wheel_drive"] == true:
			get_wheel(1).use_as_traction = true  # front
			get_wheel(3).use_as_traction = true  # front
			get_wheel(2).use_as_traction = true  # rear
			get_wheel(4).use_as_traction = true  # rear
		else:
			get_wheel(1).use_as_traction = true  # front
			get_wheel(3).use_as_traction = true  # front
			get_wheel(2).use_as_traction = false  # rear
			get_wheel(4).use_as_traction = false  # rear
	 

func re_parent_to_main_scene(child) -> void:
	remove_child(child)
	get_main_scene().call_deferred("add_child", child)
	print("reparented "+str(child.name))


func get_main_scene():
	return get_player().get_parent()


func check_lights() -> void:
	if get_main_scene().get_node("DirectionalLightSun").light_energy < 0.3: 
		# print("turning lights on")
		lights_on()
	else:
		# print("turning lights off")
		lights_off()


func flicker_lights() -> void:
	# damaged lights, and also the lights due to damage
	# small chance of turning off when damaged. slightly bigger chance of turing back on (should flicker)
	
	for l in [1, 2, 3, 4, 5]:
		if rng.randf() < 0.1:
			$Effects/Damage/LightsOnFire.get_node("OnFireLight"+str(l)).light_energy = 0.0
		else:
			$Effects/Damage/LightsOnFire.get_node("OnFireLight"+str(l)).light_energy = total_damage/10.0

	if rng.randf() < 0.1*total_damage/max_damage:
		#print("damaged LightFrontLeft flickering off")
		$Lights/LightFrontLeft.spot_range = 10  #100.0*(max_damage-total_damage)
	elif rng.randf() < 0.5*total_damage/max_damage:
		#print("damaged LightFrontLeft flickering on")
		$Lights/LightFrontLeft.spot_range = 100.0

	if rng.randf() < 0.1*total_damage/max_damage:
		#print("damaged LightFrontRight flickering off")
		$Lights/LightFrontRight.spot_range = 10  # 100.0*(max_damage-total_damage)
	elif rng.randf() < 0.5*total_damage/max_damage:
		#print("damaged LightFrontRight flickering on")
		$Lights/LightFrontRight.spot_range = 100.0


func get_raycast(wheel_num) -> RayCast:
	var gw: VehicleWheel = get_wheel(wheel_num)
	if gw != null:
		return $Raycasts.get_node("RayCastWheel"+str(wheel_num)) as RayCast
	else:
		return null


func check_ongoing_damage() -> int:
	if total_damage < max_damage:
		for raycast in [get_raycast(1), get_raycast(2), get_raycast(3), get_raycast(4), $Raycasts/RayCastCentreDown, $Raycasts/RayCastBonnetUp, $Raycasts/RayCastForward, $Raycasts/RayCastBackward, $Raycasts/RayCastLeft, $Raycasts/RayCastRight]:
			if check_raycast("lava", raycast) == true:
				#print("Player taking damage 1")
				return 1
		$Effects/Damage/LavaLight1.visible = false
		return 0
	return 0


func check_raycast(substring_in_hit_name, raycast) -> bool:
	if raycast != null:
		if raycast.is_colliding():
			if substring_in_hit_name.to_lower() in raycast.get_collider().name.to_lower():
				#print("Vehicle raycast "+str(raycast.name)+": collision matches substring: "+str(substring_in_hit_name))
				$Effects/Damage/LavaLight1.visible = true
				return true
	return false


func _process(delta):
	
	if vehicle_state == ConfigVehicles.AliveState.DEAD:
		return

	if set_pos == false:
		print("Exiting _process: set_pos == false")
		set_global_transform_origin()

	print_timer += delta
		
	if global_transform.origin.y < -50.0:
		print("global_transform.origin.y < -50.0 -> AliveState.DEAD")
		vehicle_state = ConfigVehicles.AliveState.DEAD
	
	if vehicle_state == ConfigVehicles.AliveState.DYING:
		explosion2_timer -= delta
		if explosion2_timer <= 0.0:
			explosion2_timer = 0.2
		if dying_finished():
			print("dying_finished() -> AliveState.DEAD")
			vehicle_state = ConfigVehicles.AliveState.DEAD

	if total_damage >= max_damage:
		print("Exiting _process: total_damage >= max_damage")
		return

	timer_1_sec -= delta
	if timer_1_sec <= 0.0:
		timer_1_sec = 1.0
		check_lights()
		var ongoing_damage: float = check_ongoing_damage()
		if ongoing_damage > 0:
			add_damage(ongoing_damage)

	timer_0_1_sec -= delta
	if timer_0_1_sec <= 0.0:
		flicker_lights()
		timer_0_1_sec = 0.1
		if not ("instance" in weapons_state[weapon_select]):
			#print(str(weapons[weapon_select]["name"])+" not in dict")
			weapons_state[weapon_select]["active"] = false
			cooldown_timer = weapons_state[weapon_select]["cooldown_timer"]
		elif weapons_state[weapon_select]["instance"] == null:
			#print(str(weapons[weapon_select]["name"])+" is null")
			weapons_state[weapon_select]["active"] = false
			cooldown_timer = weapons_state[weapon_select]["cooldown_timer"]
		elif not is_instance_valid(weapons_state[weapon_select]["instance"]):
			#print(str(weapons[weapon_select]["name"])+" is invalid instance")
			weapons_state[weapon_select]["active"] = false
			cooldown_timer = weapons_state[weapon_select]["cooldown_timer"]
		#else:
		#	print(str(weapons[weapon_select]["name"])+" in dict. Lifetime="+str(weapons[weapon_select]["instance"].lifetime_seconds))
		get_player().set_label_player_name()  # , total_damage, weapons_state[weapon_select].damage)
		get_player().set_label_lives_left()
		get_player().get_hud().get_node("cooldown").max_value = ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[weapon_select]
		get_player().get_hud().get_node("cooldown").value = cooldown_timer
		
		# Update all the 0.1 sec physical calculations
		# speed
		old_fwd_mps_0_1 = fwd_mps_0_1
		fwd_mps_0_1 = transform.basis.xform_inv(linear_velocity).z  # global linear velocity rotated to our forward direction (z)
		fwd_mps_0_1_ewma = (0.5*fwd_mps_0_1) + (0.5*fwd_mps_0_1)  # smooth it out over 1 sec
		# accel
		acceleration_fwd_0_1 = 0.1 * (fwd_mps_0_1-old_fwd_mps_0_1)  # calc fwd accel every 0.1s
		acceleration_fwd_0_1_ewma = (0.9*acceleration_fwd_0_1_ewma) + (0.1*acceleration_fwd_0_1)  # smooth it out over 1 sec

	lifetime_so_far_sec += delta

	if weapons_state[weapon_select]["active"] == false:
		if weapons_state[weapon_select]["cooldown_timer"] > 0.0:
			weapons_state[weapon_select]["cooldown_timer"] -= delta
			if weapons_state[weapon_select]["cooldown_timer"] < 0.0:
				weapons_state[weapon_select]["cooldown_timer"]  = 0.0
		cooldown_timer = weapons_state[weapon_select]["cooldown_timer"]
	
	if cooldown_timer < 0.0:
		cooldown_timer = 0.0


func _input(_event):
	if Input.is_action_just_released("cycle_weapon_player"+str(player_number)):
		cycle_weapon()
	elif Input.is_action_just_released("fire_player"+str(player_number)) and weapons_state[weapon_select]["active"] == false and weapons_state[weapon_select]["cooldown_timer"] <= 0.0 and weapons_state[weapon_select]["enabled"] == true:
		#print("Player pressed fire")
		weapons_state[weapon_select]["cooldown_timer"] = ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[weapon_select]
		get_player().set_label_player_name()
		get_player().set_label_lives_left()
		if weapon_select == ConfigWeapons.Type.MINE or weapon_select == ConfigWeapons.Type.NUKE:  # mine or nuke
			fire_mine_or_nuke()
		elif weapon_select == ConfigWeapons.Type.ROCKET:
			fire_missile_or_rocket()
		elif weapon_select == ConfigWeapons.Type.MISSILE:
			fire_missile_or_rocket()
		elif weapon_select == ConfigWeapons.Type.BALLISTIC:
			fire_missile_or_rocket()
		elif weapon_select == ConfigWeapons.Type.BALLISTIC_MISSILE:
			fire_missile_or_rocket()
	elif Input.is_action_just_released("kill_player1"):
		if player_number == 1:
			add_damage(10.0)


func check_accel_damage() -> void:
		
	if not accel_damage_enabled:
		return  # makes sure we don't check again soon after we add damage below
		
	#print("acceleration_calc_for_damage="+str(acceleration_calc_for_damage))
	#print("accel_damage_threshold="+str(accel_damage_threshold))
	if acceleration_calc_for_damage > ACCEL_DAMAGE_THRESHOLD:
		#print("acceleration_calc_for_damage > ACCEL_DAMAGE_THRESHOLD()")
		var rammed_another_car: bool = false
		$Effects/Audio/CrashSound.playing = true
		$Effects/Audio/CrashSound.volume_db = 0.0
		if $Raycasts/RayCastFrontRamDamage1.is_colliding():
			var collider_name: String = $Raycasts/RayCastFrontRamDamage1.get_collider().name
			if "car" in collider_name.to_lower():
				print("player "+str(player_number)+" rammed "+str(collider_name))
				rammed_another_car = true
		if $Raycasts/RayCastFrontRamDamage2.is_colliding():
			var collider_name: String = $Raycasts/RayCastFrontRamDamage2.get_collider().name
			if "car" in collider_name.to_lower():
				print("player "+str(player_number)+" rammed "+str(collider_name))
				rammed_another_car = true
		if $Raycasts/RayCastFrontRamDamage3.is_colliding():
			var collider_name: String = $Raycasts/RayCastFrontRamDamage3.get_collider().name
			if "car" in collider_name.to_lower():
				print("player "+str(player_number)+" rammed "+str(collider_name))
				rammed_another_car = true
		if rammed_another_car == false:
			var damage: float = round(acceleration_calc_for_damage / ACCEL_DAMAGE_THRESHOLD)
			print("damage="+str(damage))
			add_damage(damage)
		# else don't take any damage
	elif acceleration_calc_for_damage > ACCEL_DAMAGE_THRESHOLD/2.0:
		$Effects/Audio/CrashSound.playing = true
		$Effects/Audio/CrashSound.volume_db = -18.0


func cycle_weapon(keep=false) -> void:
	if keep == false:
		weapon_select += 1
		if weapon_select > len(weapons_state)-1:
			weapon_select = 0  # leave this as in int, in case the weapon design is changed
		while weapons_state[weapon_select].enabled == false:
			weapon_select += 1
			if weapon_select > len(weapons_state)-1:
				weapon_select = 0  # leave this as in int, in case the weapon design is changed
	set_icon()
	get_player().set_label_player_name()
	get_player().set_label_lives_left()


func set_icon() -> void:
	#print("set_icon()")
	#print("ConfigWeapons.ICON.keys()="+str(ConfigWeapons.ICON.keys()))
	for wk in ConfigWeapons.Type.keys():
		#print("wk="+str(wk))
		if ConfigWeapons.Type[wk] in ConfigWeapons.ICON.keys():
			var icon_str: String = ConfigWeapons.ICON[ConfigWeapons.Type[wk]]
			#print("icon_str="+str(icon_str))
			get_player().get_hud().get_node(icon_str).hide()
		#else:
		#	print("ConfigWeapons.Type[wk] not in ConfigWeapons.ICON.keys() for ConfigWeapons.Type[wk]="+str(ConfigWeapons.Type[wk]))
	get_player().get_hud().get_node("icon_"+ConfigWeapons.Type.keys()[weapon_select].to_lower()).show()


func _physics_process(delta):
	# Keep polling continuous Input related to movement here: e.g. accelerate and move. All others move to e.g. _input()
	
	# test adding constant downwards force so a vehicle can climb walls
	#change this vector according to your needs. "* delta" scales it to the time-interval of fixed_process
	#var gravity=Vector3(0,get_mass() * 9.8/2.0,0)*delta
	#    
	#local coordinates of objects center of gravity
	#var local_cog = Vector3(0,0,0)
	#
	#apply one gravity "impulse" per process interval
	#apply_impulse(local_cog,  gravity)
	
	var new_vel: Vector3 = get_linear_velocity()
	#var new_vel_max: float = max(abs(new_vel.x), max(abs(new_vel.y), abs(new_vel.z)))
	fwd_mps = transform.basis.xform_inv(linear_velocity).z  # global velocity rotated to our forward (z) direction
	# Smooth out the accel calc by using a 50/50 exponentially-weighted moving average
	#var old_acceleration_calc_for_damage = acceleration_calc_for_damage
	# accel is sqrt(dx^2 + dy^2 + dz^2)
	var new_acceleration = sqrt(pow(new_vel.x - vel.x, 2)+pow(new_vel.y - vel.y, 2)+pow(new_vel.z - vel.z, 2))/delta  # now this should be in m/s/s, so 1g=9.6
	acceleration_calc_for_damage = (0.8*acceleration_calc_for_damage) + (0.2*new_acceleration)
	vel = new_vel
	
	#if abs(old_acceleration_calc_for_damage) > 0.0 and abs(acceleration_calc_for_damage) > 0.0:
	#	if abs(old_acceleration_calc_for_damage)/abs(acceleration_calc_for_damage) > 2.0 or abs(old_acceleration_calc_for_damage)/abs(acceleration_calc_for_damage) < 0.5:
	#		print("old_acceleration_calc_for_damage="+str(old_acceleration_calc_for_damage))
	#		print("  new acceleration_calc_for_damage (smoothed)="+str(acceleration_calc_for_damage))
	#		print("  new_acceleration="+str(new_acceleration))
	#		#print("  CheckAccelDamage="+str($CheckAccelDamage.))
	#		print("  lifetime_so_far_sec="+str(lifetime_so_far_sec))
	
	check_accel_damage()

	if total_damage < max_damage:
		
		steer_target = Input.get_action_strength("turn_left_player"+str(player_number)) - Input.get_action_strength("turn_right_player"+str(player_number))
		steer_target *= ConfigVehicles.STEER_LIMIT

		var old_engine_force: float = engine_force
	
		if Input.is_action_pressed("accelerate_player"+str(player_number)):
			# Increase engine force at low speeds to make the initial acceleration faster.
			var max_speed_limit_mps = (1.0/3.6) * ConfigVehicles.config[StatePlayers.players[player_number]["vehicle"]]["max_speed_km_hr"]
			if fwd_mps < speed_low_limit and speed != 0 and fwd_mps != 0.0:
				engine_force = clamp(engine_force_value * speed_low_limit / abs(fwd_mps), 0, engine_force_value)
				#print("clamped engine_force="+str(engine_force))
			elif fwd_mps > max_speed_limit_mps and speed != 0 and fwd_mps != 0.0:
				var speed_over_limit_mps = max_speed_limit_mps - abs(fwd_mps)  # how far over limit in metres/sec
				engine_force = clamp(engine_force_value * (abs(fwd_mps)/(10.0*speed_over_limit_mps)), 0, engine_force_value)  # once over speed limit, severely reduce engine force
				#print("clamped engine_force="+str(engine_force))
			else:
				engine_force = engine_force_value
				#print("engine_force="+str(engine_force))
		else:
			engine_force = 0
			
		if Input.is_action_pressed("reverse_player"+str(player_number)):
			engine_force = -engine_force_value/2.0
			if fwd_mps > speed_low_limit:
				brake = ConfigVehicles.config[StatePlayers.players[player_number]["vehicle"]]["brake"] / 5.0
		else:
			brake = 0.0
			
		if delta < 1.0:
			engine_force_ewma = (delta*engine_force) + ((1.0-delta)*old_engine_force)

		steering = move_toward(steering, steer_target, ConfigVehicles.STEER_SPEED * delta)
	
	if hit_by_missile["active"] == true:
		print("Player "+str(player_number)+ " hit by missile!")
		#var direction = hit_by_missile_origin - $Body.transform.origin  
		var direction: Vector3 = hit_by_missile["direction_for_explosion"]  # $Body.transform.origin - hit_by_missile_origin 
		direction[1] += 5.0
		if direction[1] < 0:
			direction[1] = 0  # remove downwards force - as vehicles can be blown through the terrain
		#var explosion_force: float = 200.0  # 100.0/pow(distance+1.0, 1.5)  # inverse square of distance
		if hit_by_missile["direct_hit"] == true:
			print("(direct hit) explosion_force="+str(hit_by_missile["force"]))
			apply_impulse( Vector3(0,0,0), hit_by_missile["force"]*direction.normalized() )   # offset, impulse(=direction*force)
			# if hit_by_missile["homing"]:
			# 	damage(weapons[2].damage)
			# else:
			#	damage(weapons[1].damage)
		else:
			var indirect_explosion_force: float = hit_by_missile["force"]/hit_by_missile["distance"]
			print("force="+str(hit_by_missile["force"])+" at distance="+str(hit_by_missile["distance"])+" -> indirect_explosion_force="+str(indirect_explosion_force))
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


func check_for_clipping() -> void:
	if abs(fwd_mps_0_1) < 0.1:  # stationary
		#print("Checking for clipping")
		var num_wheels_clipped: int = 0
		for raycast in $Raycasts.get_children():
			if "Wheel" in raycast.name:
				if not raycast.is_colliding():
					num_wheels_clipped += 1
					#print("raycast "+raycast.name+" not colliding")
				#else:
				#	print("raycast "+raycast.name+" is colliding with "+str(raycast.get_collider().name))
		if num_wheels_clipped > 0:
			#print("applying impulse - wheel(s) are clipped")
			apply_impulse( Vector3(0, -10.0, 0), Vector3(rng.randf()*0.1, rng.randf()*5.0*ConfigVehicles.config[StatePlayers.players[player_number]["vehicle"]]["mass_kg/100"], rng.randf()*0.1) )   # from underneath, upwards force
			$CheckAccelDamage.start(2.0)  # disable damage for temporarily
	

func update_speed() -> void:
	speed = linear_velocity.length()


func get_speed() -> float:
	update_speed()
	return speed


func get_speed2() -> float:
	return transform.basis.xform_inv(linear_velocity).z


func get_global_offset_pos(offset_y, mult_y, offset_z, mult_z) -> Vector3:
	var global_pos: Vector3 = global_transform.origin
	global_pos -= (offset_z*mult_z)*Vector3.FORWARD
	global_pos += (offset_y*mult_y)*Vector3.UP
	return global_pos


func add_damage(amount) -> void:
	total_damage += amount
	$CheckAccelDamage.start(CHECK_ACCEL_DAMAGE_INTERVAL)  # make sure we don't check again for a small duration
	accel_damage_enabled = false
	if $Effects/Damage/ParticlesSmoke.emitting == false:
		$Effects/Damage/ParticlesSmoke.emitting = true
		$Effects/Damage/Flames3D.emitting = true
	$Effects/Damage/ParticlesSmoke.amount *= 2  # increase engine smoke indicating damage
	$Effects/Damage/Flames3D.visible = true
	$Effects/Damage/Flames3D.amount = 1 + int(50*total_damage/max_damage)
	$Effects/Damage/LightsOnFire/OnFireLight1.light_energy = total_damage/20.0
	$Effects/Damage/LightsOnFire/OnFireLight2.light_energy = total_damage/20.0
	$Effects/Damage/LightsOnFire/OnFireLight4.light_energy = total_damage/20.0
	$Effects/Damage/LightsOnFire/OnFireLight5.light_energy = total_damage/20.0
	engine_force_value *= 0.75  # decrease engine power to indicate damage

	if total_damage >= max_damage and vehicle_state != ConfigVehicles.AliveState.DYING:
		print("damage: total_damage >= max_damage")
		start_vehicle_dying()


func get_player() -> Player:
	return get_parent().get_parent().get_parent() as Player
	

func get_wheel(num) -> VehicleWheel:
	if has_node("Wheel"+str(num)):
		if get_node("Wheel"+str(num)) is VehicleWheel:
			return get_node("Wheel"+str(num)) as VehicleWheel
	return null


func fire_mine_or_nuke() -> void:
	#print("Firing weapon="+str(weapon_select))
	var weapon_instance = load(ConfigWeapons.SCENE[weapon_select]).instance()
	add_child(weapon_instance) 
	weapon_instance.rotation_degrees = rotation_degrees
	# weapons_state[weapon_select]["active"] = true
	if weapon_select == ConfigWeapons.Type.MINE:
		weapon_instance.set_as_mine()
		weapon_instance.activate($Positions/Weapons/BombPosition.global_transform.origin, linear_velocity, angular_velocity, 1, player_number, get_player())
	elif weapon_select == ConfigWeapons.Type.NUKE:
		#print("activating nuke")
		weapon_instance.set_as_nuke()
		#weapon_instance.activate(get_node("/root/MainScene/Platforms/NukeSpawnPoint").global_transform.origin, 0.0, 0.0, 1, player_number, get_player())
		var nuke_spawn_point = global_transform.origin
		nuke_spawn_point.y += 100.0
		weapon_instance.activate(nuke_spawn_point, 0.0, 0.0, 1, player_number, get_player())
		if weapons_state[3].test_mode == false:
			weapons_state[3]["enabled"] = false  # so powerup is needed again
			cycle_weapon()  # de-select nuke, as it's not available any more
	else:
		print("fire_mine_or_nuke(): Error! Shouldn't be here")
	#print("weapons_state[weapon_select]="+str(weapons_state[weapon_select]))
	weapon_instance.set_as_toplevel(true)


func fire_missile_or_rocket() -> void:
	
	var weapon_instance = load(ConfigWeapons.SCENE[weapon_select]).instance()
	weapons_state[weapon_select]["instance"] = weapon_instance
	# Shoot out fast (current speed + muzzle speed), it will then slow/speed to approach weapon_instance.target_speed	
	weapon_instance.weapon_type = weapon_select
	add_child(weapon_instance)
	weapon_instance.name = ConfigWeapons.Type.keys()[weapon_select]
	weapon_instance.velocity = (transform.basis.z.normalized()) * (weapon_instance.muzzle_speed() + abs(transform.basis.xform_inv(linear_velocity).z))  
	weapon_instance.set_linear_velocity(linear_velocity)  # initial only, this is not used, "velocity" is used to change it's position
	weapon_instance.set_angular_velocity(angular_velocity)
	if weapon_select == ConfigWeapons.Type.MISSILE:
		weapon_instance.velocity[1] += 1.0   # angle it up a bit
		weapon_instance.global_transform.origin = $Positions/Weapons/MissilePosition.global_transform.origin
	elif weapon_select == ConfigWeapons.Type.BALLISTIC_MISSILE:
		weapon_instance.velocity[1] += 10.0   # angle it up a lot
		weapon_instance.global_transform.origin = $Positions/Weapons/BallisticMissilePosition.global_transform.origin
	else:
		weapon_instance.global_transform.origin = $Positions/Weapons/RocketPosition.global_transform.origin
		weapon_instance.velocity[1] -= 0.5  # angle the rocket down a bit
	#print("weapon velocity="+str(weapon_instance.velocity))
	if weapon_select == ConfigWeapons.Type.ROCKET:
		weapon_instance.activate(player_number, false)  # homing = false
	elif weapon_select == ConfigWeapons.Type.BALLISTIC:
		knock_back_firing_ballistic = true
		weapon_instance.activate(player_number, false)  # homing = false
		weapon_instance.get_node("ParticlesThrust").visible = false
		weapon_instance.velocity += Vector3.UP * 5.0  # fire upwards a bit
		$Effects/Audio/GunshotSound.playing = true
	else:
		weapon_instance.activate(player_number, true)  # homing = true
	weapon_instance.set_as_toplevel(true)
	# weapons_state[weapon_select]["active"] = true
	

func lights_on() -> void:
	set_all_lights(true)


func lights_off() -> void:
	set_all_lights(false)


func set_all_lights(state) -> void:
	$Lights/LightFrontLeft.visible = state
	$Lights/LightFrontRight.visible = state
	$Lights/LightBackLeft.visible = state
	$Lights/LightBackRight.visible = state
	$Lights/LightUnder1.visible = state
	$Lights/LightUnder2.visible = state
	$Lights/LightUnder3.visible = state
	$Lights/LightUnder4.visible = state
	$Lights/LightUnder5.visible = state


func set_global_transform_origin() -> void:
	if is_inside_tree() and set_pos == false:
		global_transform.origin = pos
		set_pos = true
	else:
		print("_process(): warning: vehicle not is_inside_tree()")


func _on_CarBody_body_entered(body):

	if "Lava" in body.name:
		#print("Taking max_damage damage")
		add_damage(max_damage)


func power_up(power_up_name) -> void:
	print("power_up: power_up_name = "+str(power_up_name))
	weapons_state[ConfigWeapons.Type.NUKE].enabled = true
	weapon_select = ConfigWeapons.Type.NUKE
	cycle_weapon(true)


func get_camera() -> Camera:
	return get_player().get_camera() as Camera
	#return $CameraBase/Camera as Camera


func set_label(new_label) -> void:
	get_node( "../../CanvasLayer/Label").text = new_label


func start_vehicle_dying() -> void:
	
	if vehicle_state == ConfigVehicles.AliveState.ALIVE:
		print("start_vehicle_dying(): vehicle_state = "+str(vehicle_state))
		vehicle_state = ConfigVehicles.AliveState.DYING
		#print("reset_car()")
		print("start_vehicle_dying(): total_damage >= max_damage")
		total_damage = max_damage
		
		for ch in $Effects/Audio.get_children():  # turn off engine sounds
			if ch is AudioStreamPlayer:
				ch.playing = false
		
		$Effects/Audio/CrashSound.playing = true
		
		var explosion: Explosion = load(Global.explosion_folder).instance()
		explosion.name = "Explosion"
		$Effects/Damage.add_child(explosion)
		explosion.global_transform.origin = global_transform.origin
		# the billboard explosion looks awful in slow motion, as it uses animation frames.
		# so use the explosion smoke/sound/light/etc but turn off the main billboard animation
		explosion.start_effects($Effects/Damage, true)
		
		remove_nodes_for_dying()
		
		dying_visual_effects()
		
		explosion2_timer = 0.25
		
		print("vehicle_body: Starting slow_motion_timer")
		get_main_scene().start_timer_slow_motion()
		remove_main_collision_shapes()
		explode_vehicle_meshes()
		get_player().decrement_lives_left()
	else:
		print("start_vehicle_dying(): error, shouldn't be here. vehicle_state="+str(vehicle_state))


func remove_nodes_for_dying() -> void:
	remove_wheels()
	remove_raycasts()
	# remove_weapon_positions()


func remove_wheels() -> void:
	#remove the wheels: we'll then make the wheel meshes from the mesh import visible
	for vw in get_children():
		if vw is VehicleWheel:
			vw.queue_free()


func remove_raycasts() -> void:
	#remove the raycasts
	for rc in get_children():
		if rc is RayCast:
			rc.queue_free()


func remove_main_collision_shapes() -> void:
	# remove the existing CollisionShape(s) based on the car structure
	for cs in get_children():
		if cs is CollisionShape: 
			cs.queue_free()  
	# Add a small CollisionShape so we don't fall through the ground
	var new_rigid_body: ExplodedVehiclePart = load("res://vehicles/exploded_vehicle_part.tscn").instance()
	var cs: CollisionShape = new_rigid_body.get_node("CollisionShape")
	new_rigid_body.remove_child(cs)
	add_child(cs)
	new_rigid_body.queue_free()


func explode_vehicle_meshes() -> void:
	# 
	if self.has_node("MeshInstances"):
		var vm: Spatial = get_node("MeshInstances")
		print("Found node MeshInstances: destroying...")
		print("explode_vehicle_meshes(): self.has_node('MeshInstances')")
		print("self.translation="+str(self.translation))
		vm.set_script(SCRIPT_VEHICLE_DETACH_RIGID_BODIES)
		vm.set_process(true)
		vm.set_physics_process(true)
		vm.detach_rigid_bodies(0.00, self.mass, self.linear_velocity, self.global_transform.origin)
		# self.remove_child(ch)
		# ch.set_as_toplevel(true)
		# move the exploded mesh to the player, as the VehicleBody will be deleted after the explosion
		remove_child(vm)
		get_player().add_child(vm)
		vm.name = "vehicle_parts_exploded"
		# Move the target cameras to the centre of the body
		$CameraBase/CameraBasesTargets/CamTargetForward.translation = Vector3(0.0, 0.0, 0.0)
		$CameraBase/CameraBasesTargets/CamTargetForward_UD.translation = Vector3(0.0, 0.0, 0.0)
		$CameraBase/CameraBasesTargets/CamTargetReverse.translation = Vector3(0.0, 0.0, 0.0)
		$CameraBase/CameraBasesTargets/CamTargetReverse_UD.translation = Vector3(0.0, 0.0, 0.0)


func dying_finished() -> bool:
	if vehicle_state == ConfigVehicles.AliveState.DYING:
		if $Effects/Damage.has_node("Explosion"):
			if $Effects/Damage/Explosion.effects_finished():
				print("dying_finished(): vehicle_state == DYING' and $Explosion/AnimationPlayer.current_animation != 'explosion' = "+str($Effects/Damage/Explosion/AnimationPlayer.current_animation))
				return true
			return false
		else:
			print("dying_finished(): no $Effects/Damage.has_node('Explosion')")
			return true
	return false


# Dynamically adjust the grip depending on speed
# This means vehicles can more easily climb walls, but not roll at higher speed
func _on_DynamicGripTimer_timeout():
	if ConfigVehicles.config[StatePlayers.players[player_number]["vehicle"]]["all_wheel_drive"] == true:
		for wh in get_children():
			if wh is VehicleWheel:
				if abs(fwd_mps) < 1.0:
					wh.wheel_friction_slip = 1000.0  # 0 is no grip, 1 is normal, any higher caused rolling at higher speeds
				elif abs(fwd_mps) < 2.0:
					wh.wheel_friction_slip = 100.0
				elif abs(fwd_mps) < 5.0:
					wh.wheel_friction_slip = 10.0
				elif abs(fwd_mps) < 10.0:
					wh.wheel_friction_slip = 5.0
				else:
					wh.wheel_friction_slip = 1.0


func _on_CheckSkidTimer_timeout():
	
	if abs(fwd_mps) < 10.0:
		#$Effects/WheelSkidDust.emitting = false
		return
		
	var skidding: bool = false
	randomly_emit($Effects/WheelSkidDust, 0.0)
	
	for wh in get_children():
		if wh is VehicleWheel: 
			if wh.get_skidinfo() < 0.5:
				skidding = true

	if skidding == true:
		randomly_emit($Effects/WheelSkidDust, 0.25)
		if $Effects/Audio/SkidSound.playing == false:
			$Effects/Audio/SkidSound.playing = true
			$Effects/Audio/SkidSound.pitch_scale = 0.5+(abs(fwd_mps)/100.0)
			$Effects/Audio/SkidSound.play(8.21)
		elif $Effects/Audio/SkidSound.playing == true:
			if $Effects/Audio/SkidSound.get_playback_position() > 9.75:
				$Effects/Audio/SkidSound.play(8.21)


func _on_CheckWheelSpeedDustTimer_timeout():
	randomly_emit($Effects/WheelSpeedDust, 1.0 - (20.0/(20.0+abs(fwd_mps))))
	# $Effects/WheelSpeedDust.amount = num_particles  # changing this resets the particle system. Great!


func randomly_emit(node, prob):
	if rng.randf() < prob:
		node.emitting = true
	else:
		node.emitting = false


func _on_CheckAccelDamage_timeout():
	accel_damage_enabled = true 
