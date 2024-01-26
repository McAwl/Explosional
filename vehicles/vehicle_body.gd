extends VehicleBody
class_name VehicleBodyExplosional

const SCRIPT_VEHICLE_DETACH_RIGID_BODIES = preload("res://vehicles/vehicle_detach_rigid_bodies.gd")  # Global.vehicle_detach_rigid_bodies_folder)
const CHECK_ACCEL_DAMAGE_INTERVAL: float = 0.5
const MIN_SPEED_POWERUP_KM_HR = 90.0
const CONSECUTIVE_CLIPPING_ALERT: int = 10
var new_exploded_vehicle_part: Resource = load(Global.exploded_vehicle_part_folder)

export var engine_force_value: float = ConfigVehicles.ENGINE_FORCE_VALUE_DEFAULT  #40
export var speed: float = 0.0

var steer_target: float = 0
var print_timer: float = 0.0
var engine_force_ewma: float
var player_number: int
var camera: Camera
var speed_low_limit: float = 5.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var special_ability_state: Dictionary = {"shield": false, "climb_walls": false}
var cooldown_timer: float = ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.MINE]
var timer_0_1_sec: float = 0.1
var timer_1_sec: float = 1.0  # timer to eg: check if car needs to turn light on 
var timer_1_sec_physics: float = 1.0  # to check and correct clipping, etc
var lifetime_so_far_sec: float = 0.0  # to eg disable air strikes for a bit after re-spawn
var hit_by_missile: Dictionary = {
	"active": false, 
	"homing": null, 
	"origin": null, 
	"velocity": null,
	"direct_hit": null, 
	"distance": null,
	"weapon_type": null
	}
var max_damage: float = 10.0
var total_damage: float = 0.0
var take_damage: bool = true
var wheel_positions: Array = []
var wheels: Array = []

var vehicle_parts_exploded: Spatial   #= get_node("MeshInstances")

# this is changingstate info, see config_weapons.gd for constants
var weapons_state: Dictionary = {
	ConfigWeapons.Type.MINE: {"active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.MINE], "enabled": true}, \
	ConfigWeapons.Type.ROCKET: {"active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.ROCKET], "enabled": true}, \
	ConfigWeapons.Type.MISSILE: {"active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.MISSILE], "enabled": true}, \
	ConfigWeapons.Type.NUKE: {"active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.NUKE], "enabled": false, "test_mode": false},
	ConfigWeapons.Type.BALLISTIC: {"active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.BALLISTIC], "enabled": true},
	ConfigWeapons.Type.BOMB: {"active": false, "enabled": false, "test_mode": false},
	ConfigWeapons.Type.BALLISTIC_MISSILE: {"active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.BALLISTIC_MISSILE], "enabled": true},
	ConfigWeapons.Type.AIR_BURST: {"active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.AIR_BURST], "enabled": true},
	ConfigWeapons.Type.TRUCK_MINE: {"active": false, "cooldown_timer": ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[ConfigWeapons.Type.TRUCK_MINE], "enabled": true},
	}

var weapon_select: int = ConfigWeapons.Type.MINE
var lights_disabled: bool = false
var acceleration_calc_for_damage: float = 0.0
var acceleration_calc_for_damage2: float = 0.0
var acceleration_fwd_0_1_ewma: float = 0.0
var acceleration_fwd_0_1: float = 0.0
var vel: Vector3
var accel_damage_enabled: bool = false
var consecutive_clipping: int = 0
var fwd_mps: float = 0.0
var old_fwd_mps_0_1: float = 0.0
var fwd_mps_0_1_ewma: float = 0.0
var fwd_mps_0_1: float = 0.0
var explosion2_timer: float = 0.2
var knock_back_firing_ballistic: bool = false  # knock the vehicle backwards when firing a ballistic weapons
var vehicle_state: int = ConfigVehicles.AliveState.ALIVE 
var set_pos: bool = false
var pos: Vector3
var powerup_state: Dictionary = {
	"shield": {"enabled": false, "hits_left": 0, "max_hits": 0},
	"fast_reverse": {"enabled": false},
	}


# Built-in  methods

func _ready():
	Global.debug_print(5, "vehicle_body: _ready() global_transform.origin= "+str(self.global_transform.origin), "camera")
	var _connect_change_weather = Global.connect("change_weather", self, "on_change_weather")
	var _connect_update_weather = Global.connect("update_weather", self, "on_update_weather")
	vehicle_state = ConfigVehicles.AliveState.ALIVE
	#Global.debug_print(3, "vehicle_body: _ready(): Camera target pos="+str($CameraBase/Camera.target.global_transform.origin), "camera")


func _process(delta):
	
	if vehicle_state == ConfigVehicles.AliveState.DEAD:
		return

	if set_pos == false:
		Global.debug_print(3, "Exiting _process: set_pos == false", "camera")
		set_global_transform_origin()

	print_timer += delta
		
	if global_transform.origin.y < -50.0:
		Global.debug_print(3, "global_transform.origin.y < -50.0 -> AliveState.DEAD")
		#vehicle_state = ConfigVehicles.AliveState.DEAD
		add_damage(max_damage, Global.DamageType.OFF_MAP)
	
	if vehicle_state == ConfigVehicles.AliveState.DYING:
		explosion2_timer -= delta
		if explosion2_timer <= 0.0:
			explosion2_timer = 0.2
		if dying_finished():
			Global.debug_print(3, "dying_finished() -> AliveState.DEAD")
			vehicle_state = ConfigVehicles.AliveState.DEAD
		else:
			if !vehicle_parts_exploded == null:
				# Move the target cameras to the centre of the collection of meshes
				Global.debug_print(3, "moving cam to centre_of_meshes")
				var centre_of_meshes = vehicle_parts_exploded.centre_of_meshes
				$CameraBase/CameraBasesTargets/CamTargetForward.translation = centre_of_meshes
				$CameraBase/CameraBasesTargets/CamTargetForward_UD.translation = centre_of_meshes
				$CameraBase/CameraBasesTargets/CamTargetReverse.translation = centre_of_meshes
				$CameraBase/CameraBasesTargets/CamTargetReverse_UD.translation = centre_of_meshes
				#get_camera().fix_distance(10.0)
				

	if total_damage >= max_damage:
		Global.debug_print(3, "Exiting _process: total_damage >= max_damage")
		return

	timer_1_sec -= delta
	if timer_1_sec <= 0.0:
		timer_1_sec = 1.0
		check_lights()
		var ongoing_damage: float = check_ongoing_damage()
		if ongoing_damage > 0:
			add_damage(ongoing_damage, Global.DamageType.LAVA)

	timer_0_1_sec -= delta
	if timer_0_1_sec <= 0.0:
		flicker_lights()
		timer_0_1_sec = 0.1
		if not ("instance" in weapons_state[weapon_select]):
			#Global.debug_print(3, str(weapons[weapon_select]["name"])+" not in dict")
			weapons_state[weapon_select]["active"] = false
			cooldown_timer = weapons_state[weapon_select]["cooldown_timer"]
		elif weapons_state[weapon_select]["instance"] == null:
			#Global.debug_print(3, str(weapons[weapon_select]["name"])+" is null")
			weapons_state[weapon_select]["active"] = false
			cooldown_timer = weapons_state[weapon_select]["cooldown_timer"]
		elif not is_instance_valid(weapons_state[weapon_select]["instance"]):
			#Global.debug_print(3, str(weapons[weapon_select]["name"])+" is invalid instance")
			weapons_state[weapon_select]["active"] = false
			cooldown_timer = weapons_state[weapon_select]["cooldown_timer"]
		#else:
		#Global.debug_print(3, str(weapons[weapon_select]["name"])+" in dict. Lifetime="+str(weapons[weapon_select]["instance"].lifetime_seconds))
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

	$CameraBase/Camera/ParticlesCinders.process_material.direction = Global.weather_state["wind_direction"]
	$CameraBase/Camera/ParticlesCinders.process_material.initial_velocity = Global.weather_state["wind_strength"]/100.0
	add_central_force(Global.weather_state["wind_direction"] * Global.weather_state["wind_strength"])


func _input(event):
	if InputMap.event_is_action (event, "cycle_weapon_player"+str(player_number)):
		if event.is_pressed():
			cycle_weapon()
			# Stop the event from spreading
			get_tree().set_input_as_handled()
	elif InputMap.event_is_action (event, "fire_player"+str(player_number)) and weapons_state[weapon_select]["active"] == false and weapons_state[weapon_select]["cooldown_timer"] <= 0.0 and weapons_state[weapon_select]["enabled"] == true:
		if event.is_pressed():
			#Global.debug_print(3, "Player pressed fire")
			weapons_state[weapon_select]["cooldown_timer"] = ConfigWeapons.COOLDOWN_TIMER_DEFAULTS[weapon_select]
			get_player().set_label_player_name()
			get_player().set_label_lives_left()
			if weapon_select == ConfigWeapons.Type.MINE or weapon_select == ConfigWeapons.Type.NUKE or weapon_select == ConfigWeapons.Type.TRUCK_MINE:  # mine or nuke
				fire_mine_or_nuke()
			elif weapon_select == ConfigWeapons.Type.ROCKET:
				fire_missile_or_rocket()
			elif weapon_select == ConfigWeapons.Type.MISSILE:
				fire_missile_or_rocket()
			elif weapon_select == ConfigWeapons.Type.BALLISTIC:
				fire_missile_or_rocket()
			elif weapon_select == ConfigWeapons.Type.BALLISTIC_MISSILE:
				fire_missile_or_rocket()
			elif weapon_select == ConfigWeapons.Type.AIR_BURST:
				fire_missile_or_rocket()
			else:
				Global.debug_print(1, "Warning: player "+str(player_number)+" fired unknown weapon "+str(weapon_select))
			# Stop the event from spreading
			get_tree().set_input_as_handled()
	elif InputMap.event_is_action (event, "damage_player1"):
		if event.is_pressed():
			if player_number == 1 and Global.build_type == Global.Build.Development:
				Global.debug_print(3, "_input(): adding Global.DamageType.TEST = "+str(Global.DamageType.TEST), "damage")
				add_damage(1, Global.DamageType.TEST)
				#add_damage(max_damage, Global.DamageType.OFF_MAP)
			# Stop the event from spreading
			get_tree().set_input_as_handled()
	elif InputMap.event_is_action (event, "kill_player1"):
		if event.is_pressed():
			if player_number == 1 and Global.build_type == Global.Build.Development:
				Global.debug_print(3, "_input(): adding Global.DamageType.TEST = "+str(Global.DamageType.TEST), "damage")
				add_damage(max_damage, Global.DamageType.TEST)
				#add_damage(max_damage, Global.DamageType.OFF_MAP)
			# Stop the event from spreading
			get_tree().set_input_as_handled()
	elif InputMap.event_is_action (event, "kill_player2"):
		if event.is_pressed():
			if player_number == 2 and Global.build_type == Global.Build.Development:
				add_damage(max_damage, Global.DamageType.TEST)
			# Stop the event from spreading
			get_tree().set_input_as_handled()
	elif InputMap.event_is_action (event, "kill_player3"):
		if event.is_pressed():
			if player_number == 3 and Global.build_type == Global.Build.Development:
				add_damage(max_damage, Global.DamageType.TEST)
			# Stop the event from spreading
			get_tree().set_input_as_handled()
	elif InputMap.event_is_action (event, "kill_player4"):
		if event.is_pressed():
			if player_number == 4 and Global.build_type == Global.Build.Development:
				add_damage(max_damage, Global.DamageType.TEST)
			# Stop the event from spreading
			get_tree().set_input_as_handled()
	elif InputMap.event_is_action (event, "toggle_cinders"):
		if event.is_pressed() and Global.build_options["allow_toggle_cinders"] == true:
			# fog will set to camera.far as long as the fog depth end = 0 in the main enviroment
			if not $CameraBase/Camera/TweenCameraFarCullingDistance.is_active():
				Global.toggle_weather()
			# Stop the event from spreading
			get_tree().set_input_as_handled()


func _physics_process(delta):
	
	if not player_number in StatePlayers.players.keys():
		return  # in process of being reset?
	
	timer_1_sec_physics -= delta
	
	# Add forces due to weather
	var weather_force_modifier_per_vehicle: float = pow(ConfigVehicles.config[get_type()]["mass_kg/100"]/70.0, 1.5)
	add_central_force(weather_force_modifier_per_vehicle*Global.weather_state["wind_direction"] * Global.weather_state["wind_strength"])
	#Global.debug_print(3, "Global.weather_state['wind_direction']="+str(Global.weather_state['wind_direction']))
	#Global.debug_print(3, "Global.weather_state['wind_strength']="+str(Global.weather_state['wind_strength']))
		
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
	#		Global.debug_print(3, "old_acceleration_calc_for_damage="+str(old_acceleration_calc_for_damage))
	#		Global.debug_print(3, "  new acceleration_calc_for_damage (smoothed)="+str(acceleration_calc_for_damage))
	#		Global.debug_print(3, "  new_acceleration="+str(new_acceleration))
	#		#Global.debug_print(3, "  CheckAccelDamage="+str($CheckAccelDamage.))
	#		Global.debug_print(3, "  lifetime_so_far_sec="+str(lifetime_so_far_sec))
	
	check_accel_damage()

	if total_damage < max_damage:

		#var old_engine_force: float = engine_force
	
		var engine_force_adjustment_4wd: float = 1.0
		if is_4wd():
			# Adjust power to each wheel for 4WD vehicles
			# e.g. if only 1 wheel of 4 is in contact, add the force from other wheels to that one wheel (x4)
			var num_wheels_in_contact: int = 0
			var total_num_wheels: int = 0
			for wh in get_children():
					if wh is VehicleWheel:
						total_num_wheels += 1
						if wh.is_in_contact():
							num_wheels_in_contact += 1
							#if timer_1_sec_physics < 0.0:
							#	Global.debug_print(8, "Wheel "+str(wh)+" in contact with "+str(wh.get_contact_body().name), "vehicle_traction")
			if num_wheels_in_contact > 0 and num_wheels_in_contact < total_num_wheels:
				engine_force_adjustment_4wd = 1.0 + ((float(total_num_wheels) / float(num_wheels_in_contact))/2.0)
			if timer_1_sec_physics < 0.0:
				Global.debug_print(8, str(num_wheels_in_contact)+" of "+str(total_num_wheels)+" in contact. engine_force_adjustment_4wd="+str(engine_force_adjustment_4wd), "vehicle_traction")

		if Input.is_action_pressed("accelerate_player"+str(player_number)):
			# Increase engine force at low speeds to make the initial acceleration faster.
			var max_speed_limit_mps = (1.0/3.6) * ConfigVehicles.config[get_type()]["max_speed_km_hr"]
			if fwd_mps < speed_low_limit and speed != 0 and fwd_mps != 0.0:
				engine_force = clamp(engine_force_value * speed_low_limit / abs(fwd_mps), 0, engine_force_value)
				#Global.debug_print(3, "clamped engine_force="+str(engine_force))
			elif fwd_mps > max_speed_limit_mps and speed != 0 and fwd_mps != 0.0:
				var speed_over_limit_mps = max_speed_limit_mps - abs(fwd_mps)  # how far over limit in metres/sec
				engine_force = clamp(engine_force_value * (abs(fwd_mps)/(10.0*speed_over_limit_mps)), 0, engine_force_value)  # once over speed limit, severely reduce engine force
				#Global.debug_print(3, "clamped engine_force="+str(engine_force))
			else:
				engine_force = engine_force_value
				#Global.debug_print(3, "engine_force="+str(engine_force))
		else:
			engine_force = 0
			
		if Input.is_action_pressed("reverse_player"+str(player_number)):
			var _max_speed_limit_mps = (1.0/3.6) * ConfigVehicles.config[get_type()]["max_speed_km_hr"]
			# brakes shouldn't be effected by whether the engine is damaged
			if powerup_state["fast_reverse"]["enabled"] == true:
				engine_force = -engine_force_value*10.0
			else:
				engine_force = -engine_force_value/2.0
			if fwd_mps > speed_low_limit:
				brake = ConfigVehicles.config[get_type()]["brake"] / 5.0
		else:
			brake = 0.0
		
		if delta < 1.0:
			engine_force_ewma = (engine_force*delta) + (engine_force_ewma*(1-delta))
		else:
			engine_force_ewma = (engine_force*0.5) + (engine_force_ewma*0.5)

		var left  = Input.get_action_strength("turn_left_player"+str(player_number))  # * ConfigVehicles.STEER_LIMIT
		var right = Input.get_action_strength("turn_right_player"+str(player_number))  # * ConfigVehicles.STEER_LIMIT
		if get_type() == ConfigVehicles.Type.TANK:
			# Use per wheel forces so we can turn the vehicle without steering a wheel
			for wh in get_children():
				if wh is VehicleWheel:
					if engine_force == 0.0 and (left > 0.0 or right > 0.0):  # turning at rest
						wh.engine_force = 6.0*ConfigVehicles.config[ConfigVehicles.Type.TANK]["engine_force_value"]
						#Global.debug_print(3, "turning at rest wh.engine_force="+str(wh.engine_force))
					elif engine_force > 0.0 and (left > 0.0 or right > 0.0):  # turning at speed
						wh.engine_force = 6.0*engine_force
						#Global.debug_print(3, "turning at speed wh.engine_force="+str(wh.engine_force))
					elif engine_force > 0.0: # moving straight forward, no turing
						wh.engine_force = engine_force
						#Global.debug_print(3, "straight wh.engine_force="+str(wh.engine_force))
					#else:  
					#	Global.debug_print(3, "??")
					#Global.debug_print(3, "wh.name="+str(wh.name))
					if wh.engine_force > 0.0:  # turn tank wheels in opposite directions
						if wh.name in ["Wheel1", "Wheel2", "Wheel6", "Wheel7"]:  # left row
							#Global.debug_print(3, "left row "+str(wh.name))
							wh.engine_force *= 1.0 if right-left == 0.0 else right-left
						elif wh.name in ["Wheel3", "Wheel4", "Wheel5", "Wheel8"]:  # right row
							#Global.debug_print(3, "right row "+str(wh.name))
							wh.engine_force *= 1.0 if left-right == 0.0 else left-right
						#else:
						#	Global.debug_print(3, "Warning: wheel name not found for tank")
					#Global.debug_print(3, "wh.engine_force="+str(wh.engine_force)+", left="+str(left)+", right="+str(right))
					#engine_force = 0.0  # turn off overall engine force, leaving per-wheel forces used above
					#if (left > 0.0 or right > 0.0):
					#	Global.debug_print(3, "turing wh.engine_force="+str(wh.engine_force))
					#	if wh.engine_force == 0.0:
					#		Global.debug_print(3, "Warning: wheel "+str(wh.name)+" force=0 and user is turning")
					wh.engine_force *= engine_force_adjustment_4wd
		else:  # steer wheels normally
			engine_force *= engine_force_adjustment_4wd
			steer_target = left - right
			steer_target *= ConfigVehicles.STEER_LIMIT
		steering = move_toward(steering, steer_target, ConfigVehicles.STEER_SPEED * delta)
		
		# Keep 4wd vehicles on inclines surfaces, given Godot's VehicleWheel traction doesn't work properly
		if fwd_mps < 2.0 and engine_force > 0 and is_4wd():
			if get_type() == ConfigVehicles.Type.RALLY:
				apply_impulse( Vector3(0,0,0), 0.5*engine_force*transform.basis.z )   # offset, impulse(=direction*force)
				#apply_impulse( Vector3(0,0,0), 0.5*engine_force*transform.basis.y )   # offset, impulse(=direction*force)
				special_ability_state["climb_walls"] = true
				power_up_effect(true)
			else:  # e.g. get_type == ConfigVehicles.Type.TANK:
				apply_impulse( Vector3(0,0,0), 0.1*engine_force*transform.basis.z )   # offset, impulse(=direction*force)
				special_ability_state["climb_walls"] = false
				# power up effects will switch off automatically with TimerDisablePowerup
		else:
			special_ability_state["climb_walls"] = false
		
	if hit_by_missile["active"] == true:
		var weapon_type = hit_by_missile["weapon_type"]
		var weapon_type_name = ConfigWeapons.Type.keys()[weapon_type]
		Global.debug_print(3, "Player "+str(player_number)+ " hit by "+str(weapon_type_name), "missile")
		#var direction = hit_by_missile_origin - $Body.transform.origin  
		var direction: Vector3 = hit_by_missile["direction_for_explosion"]  # $Body.transform.origin - hit_by_missile_origin 
		direction[1] += 5.0
		if direction[1] < 0:
			direction[1] = 0  # remove downwards force - as vehicles can be blown through the terrain
		#var explosion_force: float = 200.0  # 100.0/pow(distance+1.0, 1.5)  # inverse square of distance
		if hit_by_missile["direct_hit"] == true:
			var force: float = ConfigWeapons.EXPLOSION_STRENGTH[weapon_type]/1.0
			Global.debug_print(3, "(direct hit) explosion_force="+str(force), "missile")
			apply_impulse( Vector3(0,0,0), force*direction.normalized() )   # offset, impulse(=direction*force)
			# and add any direct hit-specific damage (may be 0)
			add_damage(ConfigWeapons.DAMAGE[weapon_type], Global.DamageType.DIRECT_HIT)
			Global.debug_print(3, "total_damage now = "+str(total_damage), "missile")
		else:
			var force = ConfigWeapons.EXPLOSION_STRENGTH[weapon_type]
			var indirect_explosion_force: float = ConfigWeapons.EXPLOSION_STRENGTH[weapon_type]/hit_by_missile["distance"]
			Global.debug_print(3, "force="+str(force)+" at distance="+str(hit_by_missile["distance"])+" -> indirect_explosion_force="+str(indirect_explosion_force), "missile")
			apply_impulse( Vector3(0,0,0), indirect_explosion_force*direction.normalized() )   # offset, impulse(=direction*force)
			if hit_by_missile["distance"] <= ConfigWeapons.EXPLOSION_RANGE[weapon_type]:
				Global.debug_print(3, "Also adding indirect damage "+str(ConfigWeapons.DAMAGE_INDIRECT[weapon_type]), "missile")
				add_damage(ConfigWeapons.DAMAGE_INDIRECT[weapon_type], Global.DamageType.INDIRECT_HIT)
				Global.debug_print(3, "total_damage now = "+str(total_damage), "missile")
		angular_velocity =  Vector3(rng.randf_range(-10, 10), rng.randf_range(-10, 10), rng.randf_range(-10, 10)) 
			
		hit_by_missile["active"] = false

	# If we've fired a ballistic weapon, know backwards here
	if knock_back_firing_ballistic == true:
		Global.debug_print(3, "knock_back_firing_ballistic: knocing vehicle back")
		knock_back_firing_ballistic = false
		apply_impulse( Vector3(0,0,0), -100.0*transform.basis.z )   # offset, impulse(=direction*force)
		apply_impulse( Vector3(0,0,0), 50.0*transform.basis.y )   # offset, impulse(=direction*force)

	if timer_1_sec_physics < 0.0:
		timer_1_sec_physics = 1.0
		if check_for_clipping():
			consecutive_clipping += 1
		else:
			consecutive_clipping = 0
		if consecutive_clipping > CONSECUTIVE_CLIPPING_ALERT:
			Global.debug_print(2, "Error: "+str(consecutive_clipping) + " consecutive vehicle clipping detected..")
			transform.origin += Vector3.UP


# Signal methods


func on_change_weather(weather_change: Dictionary, change_duration_sec) -> void:
	
	Global.debug_print(5, "VehicleBody: received change_weather signal="+str(weather_change), "weather")
	#Global.debug_print(3, "VehicleBody: weather_change.keys()="+str(weather_change.keys()), "weather")
	
	for weather_item_key in weather_change.keys():
		if "visibility" == weather_item_key:
			Global.debug_print(3, "VehicleBody: changing weather: visibility", "weather")
			Global.debug_print(3, "  old="+str(weather_change["visibility"][0])+", new="+str(weather_change["visibility"][1]), "weather")
			if $CameraBase/Camera/TweenCameraFarCullingDistance.is_active():
				Global.debug_print(3, "VehicleBody: warning: starting $CameraBase/Camera/TweenCameraFarCullingDistance but it's still active", "weather")
			$CameraBase/Camera/TweenCameraFarCullingDistance.interpolate_property($CameraBase/Camera, "far", weather_change["visibility"][0], weather_change["visibility"][1], change_duration_sec, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$CameraBase/Camera/TweenCameraFarCullingDistance.start()
		#if "cinders_visible" == weather_item_key:
		#	get_node("/root/MainScene/Effects/TweenFireStorm").interpolate_property(get_node("/root/MainScene/Viewport/WorldEnvironment"), "environment:dof_blur_far_distance", weather_change["dof_blur_far_distance"][0], weather_change["dof_blur_far_distance"][1], change_duration_sec, Tween.TRANS_LINEAR, Tween.EASE_IN)
		#	get_node("/root/MainScene/Effects/TweenFireStorm").start()
		#	$CameraBase/Camera/ParticlesCinders.visible = weather_change["cinders_visible"]
		if "cam_colour_filer_transparency" == weather_item_key:
			Global.debug_print(1, "MainScene: changing weather: weather_item = cam_colour_filer_transparency", "weather")
			Global.debug_print(1, "MainScene: weather_change = "+str(weather_change), "weather")
			Global.debug_print(1, "  old="+str(weather_change["cam_colour_filer_transparency"][0])+", new="+str(weather_change["cam_colour_filer_transparency"][1]), "weather")
			if $CameraBase/Camera/TweenCameraColourFilterTransparency.is_active():
				Global.debug_print(3, "VehicleBody: warning: starting $Effects/cam_colour_filer_transparency but it's still active", "weather")
			$CameraBase/Camera/TweenCameraColourFilterTransparency.interpolate_property($CameraBase/Camera/CSGPolygon.get_material(), "albedo_color:a", weather_change["cam_colour_filer_transparency"][0], weather_change["cam_colour_filer_transparency"][1], change_duration_sec, Tween.TRANS_LINEAR, Tween.EASE_IN)  #Color(1, 0.52549, 0, 0.305882)
			$CameraBase/Camera/TweenCameraColourFilterTransparency.start()


func on_update_weather(weather_state) -> void:
	
	Global.debug_print(5, "VehicleBody: received update_weather signal="+str(weather_state), "weather")
	
	# Check visibility matches weather model and correct if needed. This can happen when vehicle respawns and the weather has changed
	#if not $CameraBase/Camera/TweenCameraFarCullingDistance.is_active():  # only check if we're not already trying to change it via the Tween
	#	if not Global.weather_model[weather_state["type"]]["visibility"] == $CameraBase/Camera.far:
	#		Global.debug_print(1, "VehicleBody: update_weather(): error! visibility doesn't match weather model! Correcting...", "weather")
	#		$CameraBase/Camera.far = Global.weather_model[weather_state["type"]]["visibility"]
		
	# Check snow visibility matches weather model and correct if needed. This can happen when vehicle respawns and the weather has changed 
	if weather_state["type"] != Global.Weather.FIRE_STORM and $CameraBase/Camera/ParticlesCinders.visible:
		Global.debug_print(1, "VehicleBody: error! ParticlesCinders.visible but weather is not FIRE_STORM. Correcting...", "weather")
		$CameraBase/Camera/ParticlesCinders.hide()
	elif weather_state["type"] == Global.Weather.FIRE_STORM and not $CameraBase/Camera/ParticlesCinders.visible:
		Global.debug_print(1, "VehicleBody: error! ParticlesCinders not visible but weather is FIRE_STORM. Correcting...", "weather")
		$CameraBase/Camera/ParticlesCinders.show()


func _on_CarBody_body_entered(body):
	if "Lava" in body.name:
		#Global.debug_print(3, "Taking max_damage damage")
		add_damage(max_damage, Global.DamageType.LAVA)


func _on_DynamicGripTimer_timeout():
	# Dynamically adjust the grip depending on speed
	# This means vehicles can more easily climb walls, but not roll at higher speed
	if ConfigVehicles.config[get_type()]["all_wheel_drive"] == true:
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
			if wh.get_skidinfo() < 0.15:
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
	#$Effects/WheelSpeedDust.amount = num_particles  # changing this resets the particle system. Great!


func _on_TimerDisablePowerup_timeout():
	if not special_ability_state["climb_walls"]:
		power_up_effect(false)


func _on_TimerDisableShieldAbility_timeout():
	special_ability_state["shield"] = false
	if powerup_state["shield"]["enabled"] == false:
		$Effects/Shield.hide()


func _on_TimerFlickerShield_timeout():
	if $Effects/Shield.visible == true and powerup_state["shield"]["enabled"] == true and special_ability_state["shield"] == false:
		if powerup_state["shield"]["max_hits"] > 0.0:
			if not $Effects/Shield/GlowingSphere.visible:
				$Effects/Shield/GlowingSphere.show()
			elif rng.randf() > float(powerup_state["shield"]["hits_left"])/float(powerup_state["shield"]["max_hits"]):
				$Effects/Shield/GlowingSphere.hide()


func _on_CheckAccelDamage_timeout():
	accel_damage_enabled = true 
	Global.debug_print(3, "accel_damage_enabled="+str(accel_damage_enabled))


func _on_TimerShieldCheckSpecialAbility_timeout():
	if get_type() == ConfigVehicles.Type.RACER:
		if fwd_mps > (MIN_SPEED_POWERUP_KM_HR/200) * (1.0/3.6) * ConfigVehicles.config[get_type()]["max_speed_km_hr"]:
			$TimerDisableShieldAbility.start(5.0)
			if special_ability_state["shield"] == false:
				special_ability_state["shield"] = true
				$Effects/Shield.show()
				$Effects/Shield/GlowingSphere.show()
				$Effects/Audio/SpecialAbilityActivationSound.play()


func _on_TimerCheckSoundPitch_timeout():
	pass # Replace with function body.


func _on_TimerDisableShieldPowerup_timeout():
	powerup_state["shield"]["enabled"] = false
	$Effects/Shield.hide()
	$Effects/Shield/GlowingSphere.hide()


func _on_TimerCheckSpeedDemon5Achievement_timeout():
	get_player().add_achievement(Global.Achievements.SPEED_DEMON5)


func _on_TimerCheckMaxSpeed_timeout():
	var max_speed_limit_mps = (1.0/3.6) * ConfigVehicles.config[get_type()]["max_speed_km_hr"]
	if fwd_mps >= max_speed_limit_mps:
		if $TimerCheckSpeedDemon5Achievement.is_stopped():
			$TimerCheckSpeedDemon5Achievement.start()
	else:
		$TimerCheckSpeedDemon5Achievement.stop()


# Public methods

func init(_pos=null, _player_number=null, _name=null) -> bool:
	
	Global.debug_print(5, "vehicle_body: init() _pos="+str(_pos)+", global_transform.origin= "+str(self.global_transform.origin), "camera")
	
	lifetime_so_far_sec = 0.0
	cooldown_timer = weapons_state[weapon_select]["cooldown_timer"]
	
	if _player_number != null:
		player_number = _player_number
		
	if _name != null:
		name = _name
	
	pos = _pos
	Global.debug_print(5, "vehicle_body: init(): global_transform.origin= "+str(self.global_transform.origin), "camera")
	#Global.debug_print(5, "VehicleBody() init: StatePlayers.num_players()="+str(StatePlayers.num_players()))
	
	#Global.debug_print(5, "vehicle="+str(get_type()))
	# Depending on vehicle type, we look for its nodes
	var vehicle_type_node: Spatial = $VehicleTypes.get_node(ConfigVehicles.nice_name[get_type()]) as Spatial
	if vehicle_type_node == null:
		return false
	# move all the vehicle type nodes to the correct location
	for ch in vehicle_type_node.get_children():
		#var ctm = ch.get_node(ch.name)
		if ch.name in ["Raycasts", "Positions", "MeshInstances", "Lights", "CameraBasesTargets"]:  # move from 1 level down
			vehicle_type_node.remove_child(ch)
			Global.debug_print(6, "vehicle_body: init(): ch="+str(ch), "camera")
			if ch.name == "CameraBasesTargets":
				if has_node("CameraBase"):
					$CameraBase.add_child(ch)   #NODE NOT FOUND ERROR E 0:00:10.604   get_node: (Node not found: "../../../../../CameraBase/Camera" (relative to "//MainScene/Player1/VC/V/vehicle_body/CameraBase/CameraBasesTargets/CamTargetForward/MeshInstance").)
				else:
					Global.debug_print(6, "Error: no CameraBase, children are: "+str(get_children()))
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
	
	Global.debug_print(5, "StatePlayers.players[player_number]['vehicle']="+str(get_type()))
	if get_type() < 0:  # in ConfigVehicles.Type:
		Global.debug_print(6, "init: vehicle_type "+str(get_type())+" not found in ConfigVehicles.Type="+str(ConfigVehicles.Type))
		return false
		
	configure_vehicle_properties()
	configure_weapons()
	init_visual_effects(true)
	init_audio_effects()
	
	total_damage = 0.0
	#$CheckAccelDamage.wait_time = CHECK_ACCEL_DAMAGE_INTERVAL*8.0  # so the vehicle doesn't take damage with initial spawn fall
	$CheckAccelDamage.start(4.0)
	
	Global.debug_print(5, "Initialising camera using pos="+str(_pos), "camera")
	init_camera(StatePlayers.num_players(), _pos)
	Global.debug_print(5, "..done $CameraBase/Camera.global_transform="+str($CameraBase/Camera.global_transform), "camera")
	
	vehicle_parts_exploded = get_node("MeshInstances")
	Global.debug_print(5, "vehicle_body: init() end: global_transform.origin= "+str(self.global_transform.origin), "camera")
	
	max_damage = ConfigVehicles.MAX_DAMAGE[get_type()]
	Global.debug_print(5, "vehicle_body: init() setting max_damage= "+str(max_damage), "max_damage")
	
	return true


func get_type():
	if not player_number in StatePlayers.players.keys():
		Global.debug_print(3, "Error: player_number not in StatePlayers.players")
		Global.debug_print(3, "  StatePlayers.players="+str(StatePlayers.players))
		return null
	else:
		return StatePlayers.players[player_number]["vehicle"]


func configure_weapons() -> void:
	for k in ConfigWeapons.Type.values():  # .keys():
		#Global.debug_print(3, "checking weapon "+str(k))  # 0=mine, etc
		#Global.debug_print(3, "vt="+str(vt))
		if get_type() in ConfigWeapons.vehicle_weapons[k]:
			#Global.debug_print(3, "vt "+str(vt)+" has weapon "+str(k))
			weapons_state[k]["enabled"] = true
			weapon_select = k
			set_icon()
		else:
			#Global.debug_print(3, "vt "+str(vt)+" doesnt have weapon "+str(k))
			weapons_state[k]["enabled"] = false


func init_audio_effects() -> void:
	engine_sound_on()


func engine_sound_on() -> void:
	#Global.debug_print(3, "engine_sound_on(): "+str(get_type()))
	match get_type():
		ConfigVehicles.Type.RACER:
			$Effects/Audio/EngineSound.playing = true
		ConfigVehicles.Type.RALLY:
			$Effects/Audio/EngineSound.playing = true
		ConfigVehicles.Type.TANK:
			$Effects/Audio/EngineSound.playing = true
		ConfigVehicles.Type.TRUCK:
			$Effects/Audio/EngineSound.playing = true
		_:
			Global.debug_print(3, "Warning: using default engine sound")
			$Effects/Audio/EngineSound.playing = true


func engine_sound_off() -> void:
	$Effects/Audio/EngineSound.playing = false


func init_camera(_num_players, _pos) -> void:
	$CameraBase/Camera.init(_num_players, _pos, _pos)
	#$CameraBase/Camera.target.origin = _pos
	#$CameraBase/Camera.number_of_players = StatePlayers.num_players()


func init_visual_effects(start) -> void:
	
	lights_disabled = false
	
	align_effects_with_damage()

	lights_off()
	
	powerup_state["shield"]["enabled"] = false
	$Effects/Shield.hide()
	$Effects/Shield.visible = false
	$CameraBase/Camera/ParticlesCinders.hide()
	
	if start == false:
		engine_sound_off()


func dying_visual_effects() -> void:
	init_visual_effects(false)


func configure_vehicle_properties() -> void:
	#Global.debug_print(3, "vts="+str(vts))
	engine_force_value = ConfigVehicles.config[get_type()]["engine_force_value"]
	mass = ConfigVehicles.config[get_type()]["mass_kg/100"]
	set_wheel_parameters(get_type())


func set_wheel_parameters(_vts) -> void:
	
	for wh in get_children():
		Global.debug_print(5, "set_wheel_parameters: Setting "+str(ConfigVehicles.config[_vts]), "wheel")
		if wh is VehicleWheel:
			wh.visible = true
			wh.suspension_stiffness = ConfigVehicles.config[_vts]["suspension_stiffness"]
			wh.suspension_travel = ConfigVehicles.config[_vts]["suspension_travel"]
			wh.wheel_friction_slip = ConfigVehicles.config[_vts]["wheel_friction_slip"]
			wh.wheel_roll_influence = ConfigVehicles.config[_vts]["wheel_roll_influence"]
			#wh.suspension_max_force = 4.0 * mass   # as per https://github.com/godotengine/godot/issues/45339
			if wh.suspension_travel > wh.wheel_rest_length:
				Global.debug_print(5, "Warning wheel suspension_travel > wh.wheel_rest_length", "wheel")
			#for ch2 in wh.get_children():
			#	if get_type() != ConfigVehicles.Type.TANK:
			#		ch2.visible = true
	
	if get_type() == ConfigVehicles.Type.TANK:
		get_wheel(5).use_as_traction = true  # middle
		get_wheel(6).use_as_traction = true  # middle
		get_wheel(7).use_as_traction = true  # middle
		get_wheel(8).use_as_traction = true  # middle
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


func is_4wd() -> bool:
	return ConfigVehicles.config[get_type()]["all_wheel_drive"]


func re_parent_to_main_scene(child) -> void:
	remove_child(child)
	get_main_scene().call_deferred("add_child", child)
	Global.debug_print(3, "reparented "+str(child.name))


func get_main_scene():
	return get_player().get_parent()


func check_lights() -> void:
	if get_main_scene().get_node("DirectionalLightSun").light_energy < 0.3: 
		#Global.debug_print(3, "turning lights on")
		lights_on()
	else:
		#Global.debug_print(3, "turning lights off")
		lights_off()


func flicker_lights() -> void:
	# damaged lights, and also the lights due to damage
	# small chance of turning off when damaged. slightly bigger chance of turing back on (should flicker)
	
	for l in [1, 2, 3, 4, 5]:
		if rng.randf() < 0.1:
			$Effects/Damage/LightsOnFire.get_node("OnFireLight"+str(l)).light_energy = 0.0
		else:
			$Effects/Damage/LightsOnFire.get_node("OnFireLight"+str(l)).light_energy = total_damage/max_damage

	if rng.randf() < 0.1*total_damage/max_damage:
		#Global.debug_print(3, "damaged LightFrontLeft flickering off")
		$Lights/LightFrontLeft.spot_range = 10  #100.0*(max_damage-total_damage)
	elif rng.randf() < 0.5*total_damage/max_damage:
		#Global.debug_print(3, "damaged LightFrontLeft flickering on")
		$Lights/LightFrontLeft.spot_range = 100.0

	if rng.randf() < 0.1*total_damage/max_damage:
		#Global.debug_print(3, "damaged LightFrontRight flickering off")
		$Lights/LightFrontRight.spot_range = 10  # 100.0*(max_damage-total_damage)
	elif rng.randf() < 0.5*total_damage/max_damage:
		#Global.debug_print(3, "damaged LightFrontRight flickering on")
		$Lights/LightFrontRight.spot_range = 100.0


func get_raycast(left_or_right, wheel_num) -> RayCast:  # 1=front, 2=back
	var gw: VehicleWheel = get_wheel(wheel_num)
	if gw != null:
		return $Raycasts.get_node("RayCastWheel"+str(left_or_right)+str(wheel_num)) as RayCast
	else:
		return null


func check_ongoing_damage() -> int:
	if total_damage < max_damage:
		for raycast in [get_raycast("Left", 1), get_raycast("Right", 1), get_raycast("Left", 2), get_raycast("Right", 2), $Raycasts/RayCastCentreDown, $Raycasts/RayCastBonnetUp, $Raycasts/RayCastForward, $Raycasts/RayCastBackward, $Raycasts/RayCastLeft, $Raycasts/RayCastRight]:
			if check_raycast("lava", raycast) == true:
				#Global.debug_print(3, "Player taking damage 1")
				return 1
		$Effects/Damage/LavaLight1.visible = false
		return 0
	return 0


func check_raycast(substring_in_hit_name, raycast) -> bool:
	if raycast != null:
		if raycast.is_colliding():
			if substring_in_hit_name.to_lower() in raycast.get_collider().name.to_lower():
				#Global.debug_print(3, "Vehicle raycast "+str(raycast.name)+": collision matches substring: "+str(substring_in_hit_name))
				$Effects/Damage/LavaLight1.visible = true
				return true
	return false


func check_accel_damage() -> void:
		
	if not accel_damage_enabled:
		return  # makes sure we don't check again soon after we add damage below
		
	#Global.debug_print(3, "acceleration_calc_for_damage="+str(acceleration_calc_for_damage))
	#Global.debug_print(3, "accel_damage_threshold="+str(accel_damage_threshold))
	if acceleration_calc_for_damage > ConfigVehicles.ACCEL_DAMAGE_THRESHOLD:
		#Global.debug_print(3, "acceleration_calc_for_damage > ACCEL_DAMAGE_THRESHOLD()")
		var rammed_another_car: bool = false
		$Effects/Audio/CrashSound.playing = true
		$Effects/Audio/CrashSound.volume_db = 0.0
		if $Raycasts/RayCastFrontRamDamage1.is_colliding():
			var collider = $Raycasts/RayCastFrontRamDamage1.get_collider()
			if collider is VehicleBody:
				Global.debug_print(3, "player "+str(player_number)+" rammed "+str(collider.name), "ramming")
				rammed_another_car = true
		if $Raycasts/RayCastFrontRamDamage2.is_colliding():
			var collider = $Raycasts/RayCastFrontRamDamage2.get_collider()
			if collider is VehicleBody:
				Global.debug_print(3, "player "+str(player_number)+" rammed "+str(collider.name), "ramming")
				rammed_another_car = true
		if $Raycasts/RayCastFrontRamDamage3.is_colliding():
			var collider = $Raycasts/RayCastFrontRamDamage3.get_collider()
			if collider is VehicleBody:
				Global.debug_print(3, "player "+str(player_number)+" rammed "+str(collider.name), "ramming")
				rammed_another_car = true
		if rammed_another_car == false:
			var damage: float = round(acceleration_calc_for_damage / ConfigVehicles.ACCEL_DAMAGE_THRESHOLD)
			Global.debug_print(3,  "player "+str(player_number)+" didn't ram anything: adding acceleration damage="+str(damage), "ramming")
			add_damage(damage, Global.DamageType.FORCE)
		else:
			Global.debug_print(3,  "ignoring acceleration damage", "ramming")
	
	elif acceleration_calc_for_damage > ConfigVehicles.ACCEL_DAMAGE_THRESHOLD/2.0:
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
	#Global.debug_print(3, "set_icon()")
	#Global.debug_print(3, "ConfigWeapons.ICON.keys()="+str(ConfigWeapons.ICON.keys()))
	for wk in ConfigWeapons.Type.keys():
		#Global.debug_print(3, "wk="+str(wk))
		if ConfigWeapons.Type[wk] in ConfigWeapons.ICON.keys():
			var icon_str: String = ConfigWeapons.ICON[ConfigWeapons.Type[wk]]
			#Global.debug_print(3, "icon_str="+str(icon_str))
			get_player().get_hud().get_node(icon_str).hide()
		#else:
		#	Global.debug_print(3, "ConfigWeapons.Type[wk] not in ConfigWeapons.ICON.keys() for ConfigWeapons.Type[wk]="+str(ConfigWeapons.Type[wk]))
	get_player().get_hud().get_node("icon_"+ConfigWeapons.Type.keys()[weapon_select].to_lower()).show()


func check_for_clipping() -> bool:
	var left_wheels_clipped: bool = false
	var right_wheels_clipped: bool = false
	if abs(fwd_mps_0_1) < 0.1:  # stationary
		#Global.debug_print(3, "Checking for clipping")
		var num_wheels_clipped: int = 0
		for raycast in $Raycasts.get_children():
			if "Wheel" in raycast.name:
				if not raycast.is_colliding():
					num_wheels_clipped += 1
					#Global.debug_print(3, "raycast "+raycast.name+" not colliding")
				#else:
				#	Global.debug_print(3, "raycast "+raycast.name+" is colliding with "+str(raycast.get_collider().name))
				if "left" in raycast.name.to_lower():
					left_wheels_clipped = true
				if "right" in raycast.name.to_lower():
					right_wheels_clipped = true
		if num_wheels_clipped > 0:
			Global.debug_print(3, "vehicle_body: check-for_clipping(): applying upwards translation - wheel(s) are clipped")
			transform.origin += Vector3.UP*0.5
			if left_wheels_clipped == true and right_wheels_clipped == false:
				transform.origin += Vector3.RIGHT*0.5
			if left_wheels_clipped == false and right_wheels_clipped == true:
				transform.origin += Vector3.LEFT*0.5
			# Apply some random sideways movements as well
			if rng.randf() < 0.5:
				transform.origin += Vector3.LEFT*0.5
			else:
				transform.origin += Vector3.RIGHT*0.5
			if rng.randf() < 0.5:
				transform.origin += Vector3.FORWARD*0.5
			else:
				transform.origin += Vector3.BACK*0.5
			#Global.debug_print(3, "vehicle_body: check-for_clipping(): applying impulse - wheel(s) are clipped")
			#apply_impulse( Vector3(0, -10.0, 0), Vector3(rng.randf()*0.05, rng.randf()*2.0*ConfigVehicles.config[get_type()]["mass_kg/100"], rng.randf()*0.05) )   # from underneath, upwards force
			$CheckAccelDamage.start(2.0)  # disable damage for temporarily
			return true
	return false




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


func add_damage(amount: float, damage_type: int) -> void:
	
	Global.debug_print(3, "add_damage() type "+str(damage_type)+"="+str(Global.DamageType.keys()[damage_type]), "damage")
	
	if not $CheckAccelDamage.is_inside_tree():
		Global.debug_print(1, "add_damage(): Error: not $CheckAccelDamage.is_inside_tree()", "damage")

	$CheckAccelDamage.start(CHECK_ACCEL_DAMAGE_INTERVAL)  # make sure we don't check again for a small duration
	accel_damage_enabled = false
	
	if powerup_state["shield"]["enabled"] == true and not damage_type == Global.DamageType.LAVA and not damage_type == Global.DamageType.OFF_MAP:
		powerup_state["shield"]["hits_left"] -= 1
		Global.debug_print(3, "add_damage(): ignoring damage of "+str(damage_type)+"= "+str(Global.DamageType.keys()[damage_type])+" - shield powerup is on")
		if powerup_state["shield"]["hits_left"] <= 0:
			powerup_state["shield"]["enabled"] = false
			if special_ability_state["shield"] == false:
				$Effects/Shield.hide()
			Global.debug_print(3, "add_damage(): shield off - max hits reached")
		return
	
	if special_ability_state["shield"] == true and not damage_type == Global.DamageType.LAVA and not damage_type == Global.DamageType.OFF_MAP:
		Global.debug_print(3, "add_damage(): ignoring damage of "+str(damage_type)+"= "+str(Global.DamageType.keys()[damage_type])+" - shield special ability is on")
		return
		
	match Global.game_mode:
		Global.GameMode.COMPETITIVE:
			total_damage += amount
		Global.GameMode.PEACEFUL:
			if damage_type == Global.DamageType.LAVA or damage_type == Global.DamageType.OFF_MAP:
				total_damage += amount
			else:
				Global.debug_print(3, "add_damage(): Ignoring damage: GameMode.PEACEFUL")  
		Global.GameMode.TOUGH:
			if damage_type == Global.DamageType.DIRECT_HIT or damage_type == Global.DamageType.LAVA or damage_type == Global.DamageType.OFF_MAP:
				total_damage += max_damage  # any direct hit is instant death
			else:
				Global.debug_print(3, "add_damage(): Ignoring damage: GameMode.TOUGH and damage_type="+str(damage_type)) 
		_:
			Global.debug_print(3, "add_damage(): Error: unknown damage type")

	Global.debug_print(3, "add_damage(): accel_damage_enabled="+str(accel_damage_enabled), "damage")
	align_effects_with_damage()
	check_engine_force_value()
	
	if total_damage >= max_damage and vehicle_state != ConfigVehicles.AliveState.DYING:
		Global.debug_print(3, "damage: total_damage >= max_damage and vehicle_state != ConfigVehicles.AliveState.DYING", "damage")
		if damage_type == Global.DamageType.LAVA:
			get_player().add_achievement(Global.Achievements.HOT_STUFF)
		Global.debug_print(3, "add_damage(): : total_damage >= max_damage", "damage")
		start_vehicle_dying()
	
	# explode one mesh from the vehicle body
	if Global.build_options["vehicle_falling_parts"] == true:
		if has_node("MeshInstances"):
			var base_scale = $MeshInstances.scale
			for vehicle_part in $MeshInstances.get_children():
				var new_exploded_vehicle_part_instance: ExplodedVehiclePart = new_exploded_vehicle_part.instance()
				$MeshInstances.remove_child(vehicle_part)  # move the part from the vehicle to an exploded part
				vehicle_part.visible = true  # some meshes start off invisible
				vehicle_part.translation = Vector3(0.0, 0.0, 0.0)  # start them all at 0,0,0?
				new_exploded_vehicle_part_instance.get_node("SmokeTrail").emitting = true
				new_exploded_vehicle_part_instance.add_child(vehicle_part)
				new_exploded_vehicle_part_instance.set_as_toplevel(true)
				new_exploded_vehicle_part_instance.global_transform.origin = global_transform.origin
				new_exploded_vehicle_part_instance.global_transform.origin.y += 1
				new_exploded_vehicle_part_instance.linear_velocity = linear_velocity/2.0
				vehicle_part.scale *= base_scale
				add_child(new_exploded_vehicle_part_instance)
				new_exploded_vehicle_part_instance.name = "ExplodedVehiclePart_"+str(vehicle_part.name)
				break # only consider one mesh for now
				#explode_vehicle_meshes(true)  # test to expldoe one mesh from the vehicle only


func check_engine_force_value() -> void:
	if get_type() == null:
		return
	var efv = ConfigVehicles.config[get_type()]["engine_force_value"]
	engine_force_value = efv*(1.0 - (0.5*total_damage/max_damage))  # decrease engine power to indicate damage - min is half power
	#engine_force_value = ConfigVehicles.config[get_type()]["engine_force_value"]*pow(0.75, total_damage)  # decrease engine power to indicate damage


func restore_half_health(): # ie remove half the current damage
	total_damage = total_damage/2
	
	
func restore_health(amount):
	if amount == 0:
		return

	var new_total_damage = total_damage - amount
	if new_total_damage < 0:
		new_total_damage = 0
	
	if new_total_damage >= 0:
		Global.debug_print(3, "Restored to "+str(new_total_damage)+" damage")
		total_damage = new_total_damage
		align_effects_with_damage()
	else:
		Global.debug_print(3, "Warning: restore_health() had no effect")
		
	check_engine_force_value()


func align_effects_with_damage():
	if total_damage > 0:
		if $Effects/Damage/ParticlesSmoke.emitting == false:
			$Effects/Damage/ParticlesSmoke.emitting = true
			$Effects/Damage/Flames3D.emitting = true
		$Effects/Damage/ParticlesSmoke.amount *= 2  # increase engine smoke indicating damage
		$Effects/Damage/Flames3D.visible = true
		$Effects/Damage/Flames3D.amount = 1 + int(50*total_damage/max_damage)
		$Effects/Damage/LightsOnFire/OnFireLight1.light_energy = (total_damage/max_damage)/2.0
		$Effects/Damage/LightsOnFire/OnFireLight2.light_energy = (total_damage/max_damage)/2.0
		$Effects/Damage/LightsOnFire/OnFireLight4.light_energy = (total_damage/max_damage)/2.0
		$Effects/Damage/LightsOnFire/OnFireLight5.light_energy = (total_damage/max_damage)/2.0
	else:
		$Effects/Damage/ParticlesSmoke.emitting = false
		$Effects/Damage/ParticlesSmoke.amount = 1
		$Effects/Damage/ParticlesSmoke.visible = false
		$Effects/Damage/LightsOnFire/OnFireLight1.visible = true
		$Effects/Damage/Flames3D.emitting = false
		$Effects/Damage/Flames3D.amount = 1
		$Effects/Damage/Flames3D.visible = false


func get_player() -> Player:
	return get_parent().get_parent().get_parent() as Player
	

func get_wheel(num) -> VehicleWheel:
	if has_node("Wheel"+str(num)):
		if get_node("Wheel"+str(num)) is VehicleWheel:
			return get_node("Wheel"+str(num)) as VehicleWheel
	return null


func fire_mine_or_nuke() -> void:
	Global.debug_print(3, "Firing weapon="+str(weapon_select), "weapon")
	var weapon_instance = load(ConfigWeapons.SCENE[weapon_select]).instance()
	add_child(weapon_instance) 
	weapon_instance.rotation_degrees = rotation_degrees
	#weapons_state[weapon_select]["active"] = true
	if weapon_select == ConfigWeapons.Type.MINE or weapon_select == ConfigWeapons.Type.TRUCK_MINE:
		if weapon_select == ConfigWeapons.Type.MINE:
			weapon_instance.set_as_mine()
		elif weapon_select == ConfigWeapons.Type.TRUCK_MINE:
			weapon_instance.set_as_truck_mine()
			weapon_instance.scale = Vector3(2.0, 2.0, 2.0)
		else:
			Global.debug_print(0, "Error: unknown weapon type", "weapon")
		var ray : RayCast = $Raycasts/RayCastMinePlacement
		if ray.is_colliding():
			Global.debug_print(5, "fire_mine_or_nuke(): ray.is_colliding()", "mine")
			var mine_pos = ray.get_collision_point()
			mine_pos[1] += 0.5  # place above ground
			weapon_instance.activate(mine_pos, linear_velocity, angular_velocity, 1, player_number, get_player())
		else:  # place at the origin of each vehicle's raycast, e.g. we may be near a cliff etc
			Global.debug_print(5, "fire_mine_or_nuke(): ray.is_colliding()", "mine")
			weapon_instance.activate(ray.global_transform.origin, linear_velocity, angular_velocity, 1, player_number, get_player())
	elif weapon_select == ConfigWeapons.Type.NUKE:
		#Global.debug_print(3, "activating nuke")
		weapon_instance.set_as_nuke()
		#weapon_instance.activate(get_node("/root/MainScene/Platforms/NukeSpawnPoint").global_transform.origin, 0.0, 0.0, 1, player_number, get_player())
		var nuke_spawn_point = global_transform.origin
		nuke_spawn_point.y += 100.0
		weapon_instance.activate(nuke_spawn_point, 0.0, 0.0, 1, player_number, get_player())
		if weapons_state[3].test_mode == false:
			weapons_state[3]["enabled"] = false  # so powerup is needed again
			cycle_weapon()  # de-select nuke, as it's not available any more
	else:
		Global.debug_print(3, "fire_mine_or_nuke(): fire_mine_or_nuke(): Error! Shouldn't be here")
	#Global.debug_print(3, "weapons_state[weapon_select]="+str(weapons_state[weapon_select]))
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
	elif weapon_select == ConfigWeapons.Type.AIR_BURST:
		weapon_instance.velocity[1] += 10.0   # angle it up a lot
		weapon_instance.global_transform.origin = $Positions/Weapons/TruckBombPosition.global_transform.origin
	else:
		weapon_instance.global_transform.origin = $Positions/Weapons/RocketPosition.global_transform.origin
		#weapon_instance.velocity[1] -= 0.5  # angle the rocket down a bit
		#weapon_instance.velocity[1] += 1.0   # angle it up a bit
	#Global.debug_print(3, "weapon velocity="+str(weapon_instance.velocity))
	if weapon_select == ConfigWeapons.Type.ROCKET or weapon_select == ConfigWeapons.Type.AIR_BURST:
		weapon_instance.activate(player_number, false)  # homing = false
	elif weapon_select == ConfigWeapons.Type.BALLISTIC:
		knock_back_firing_ballistic = true
		weapon_instance.activate(player_number, false)  # homing = false
		weapon_instance.get_node("ParticlesThrust").visible = false
		weapon_instance.velocity += Vector3.UP   # * 5.0  # fire upwards a bit
		$Effects/Audio/GunshotSound.playing = true
	else:
		weapon_instance.activate(player_number, true)  # homing = true
	weapon_instance.set_as_toplevel(true)
	#weapons_state[weapon_select]["active"] = true
	

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
		Global.debug_print(1, "_process(): warning: vehicle not is_inside_tree()", "camera")


func power_up(type: int) -> void:
	Global.debug_print(3, "power_up: power_up = "+str(type))
	if type == ConfigWeapons.PowerupType.NUKE:
		weapons_state[ConfigWeapons.Type.NUKE].enabled = true
		weapon_select = ConfigWeapons.Type.NUKE
		cycle_weapon(true)
	elif type == ConfigWeapons.PowerupType.SHIELD:
		$Effects/Shield.show()
		$Effects/Shield/GlowingSphere.show()
		#$Effects/Audio/ActivationSound.play()
		powerup_state["shield"]["enabled"] = true
		powerup_state["shield"]["hits_left"] = 3
		powerup_state["shield"]["max_hits"] = 3
		$TimerDisableShieldPowerup.start(30.0)
	elif type == ConfigWeapons.PowerupType.HEALTH:
		if total_damage > 0:
			restore_half_health()
			# reset_total_damage()


func reset_total_damage():
	total_damage = 0
	align_effects_with_damage()
	configure_vehicle_properties()  # reset engine power


func is_shield_on():
	return powerup_state["shield"]["enabled"] or special_ability_state["shield"]  #$Effects/Shield.visible


func is_shield_off():
	return not powerup_state["shield"]["enabled"] and not special_ability_state["shield"]  #$Effects/Shield.visible


func get_camera() -> Camera:
	#return get_player().get_camera() as Camera
	return $CameraBase/Camera as Camera


func set_label(new_label) -> void:
	get_node( "../../CanvasLayer/Label").text = new_label


func start_vehicle_dying() -> void:
	
	Global.debug_print(3, "start_vehicle_dying(): vehicle_state = "+str(ConfigVehicles.AliveState.keys()[vehicle_state]), "damage")
	if vehicle_state == ConfigVehicles.AliveState.ALIVE:
		Global.debug_print(3, "start_vehicle_dying(): vehicle_state == ALIVE", "damage")
		vehicle_state = ConfigVehicles.AliveState.DYING
		#Global.debug_print(3, "reset_car()")
		Global.debug_print(3, "start_vehicle_dying(): total_damage >= max_damage", "damage")
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
		
		Global.debug_print(3, "start_vehicle_dying(): Starting slow_motion_timer", "damage")
		get_main_scene().start_timer_slow_motion()
		remove_main_collision_shapes()
		explode_vehicle_meshes()
		get_player().decrement_lives_left()
		Global.debug_print(3, "start_vehicle_dying(): ..done", "damage")
	else:
		Global.debug_print(3, "start_vehicle_dying(): error, shouldn't be here. vehicle_state ="+str(vehicle_state), "damage")


func remove_nodes_for_dying() -> void:
	remove_wheels()
	remove_raycasts()
	#remove_weapon_positions()


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
	# if we're moving downwards, replace with upwards movement
	if self.linear_velocity.y < 1.0:
		if self.linear_velocity.y < 0.0:
			self.linear_velocity.y = -self.linear_velocity.y
		else:
			self.linear_velocity.y = 1.0


func explode_vehicle_meshes(one_only: bool = false) -> void:
	Global.debug_print(3, "explode_vehicle_meshes(): one_only="+str(one_only), "exploding parts")
	if self.has_node("MeshInstances"):
		Global.debug_print(3, "explode_vehicle_meshes(): Found node MeshInstances", "damage")
		Global.debug_print(3, "explode_vehicle_meshes(): explode_vehicle_meshes(): self.has_node('MeshInstances')", "damage")
		Global.debug_print(3, "explode_vehicle_meshes(): self.translation="+str(self.translation), "damage")
		vehicle_parts_exploded.set_script(SCRIPT_VEHICLE_DETACH_RIGID_BODIES)
		vehicle_parts_exploded.set_process(true)
		vehicle_parts_exploded.set_physics_process(true)
		if one_only:
			vehicle_parts_exploded.num_meshes_exploded = 0  
		vehicle_parts_exploded.detach_rigid_bodies(0.00, self.mass, self.linear_velocity, self.global_transform.origin)
		#self.remove_child(ch)
		#ch.set_as_toplevel(true)
		# move the exploded mesh to the player, in case the VehicleBody is be deleted due to death (or we might be exploding only one mesh due to damage)
		if not one_only:
			remove_child(vehicle_parts_exploded)
			get_player().add_child(vehicle_parts_exploded)
			vehicle_parts_exploded.name = "vehicle_parts_exploded"
			# Move the target cameras to the centre of the body
			$CameraBase/CameraBasesTargets/CamTargetForward.translation = Vector3(0.0, 0.0, 0.0)
			$CameraBase/CameraBasesTargets/CamTargetForward_UD.translation = Vector3(0.0, 0.0, 0.0)
			$CameraBase/CameraBasesTargets/CamTargetReverse.translation = Vector3(0.0, 0.0, 0.0)
			$CameraBase/CameraBasesTargets/CamTargetReverse_UD.translation = Vector3(0.0, 0.0, 0.0)
		Global.debug_print(3, "explode_vehicle_meshes(): vehicle_parts_exploded position="+str(vehicle_parts_exploded.global_transform.origin), "damage")
		Global.debug_print(3, "explode_vehicle_meshes(): our position="+str(self.global_transform.origin), "damage")


func dying_finished() -> bool:
	if vehicle_state == ConfigVehicles.AliveState.DYING:
		if $Effects/Damage.has_node("Explosion"):
			if $Effects/Damage/Explosion.effects_finished():
				Global.debug_print(3, "dying_finished(): vehicle_state == DYING' and $Explosion/AnimationPlayer.current_animation != 'explosion' = "+str($Effects/Damage/Explosion/AnimationPlayer.current_animation), "damage")
				return true
			return false
		else:
			Global.debug_print(3, "dying_finished(): no $Effects/Damage.has_node('Explosion')", "damage")
			return true
	Global.debug_print(3, "vehicle_state not == ConfigVehicles.AliveState.DYING", "damage")
	return false


func randomly_emit(node, prob):
	if rng.randf() < prob:
		node.emitting = true
	else:
		node.emitting = false


func get_max_speed_km_hr():
	return ConfigVehicles.config[get_type()]["max_speed_km_hr"]


func get_av_wheel_friction_slip():
	var num_wheels = 0
	var av_wheel_friction_slip = 0
	for wh in get_children():
		if wh is VehicleWheel:
			num_wheels += 1
			av_wheel_friction_slip += wh.wheel_friction_slip
	if num_wheels > 0:
		av_wheel_friction_slip /= num_wheels
	else:
		av_wheel_friction_slip = 1.0  # 1.0 = normal setting
	return av_wheel_friction_slip


func power_up_effect(enable):
	$Effects/Powerup.visible = enable

