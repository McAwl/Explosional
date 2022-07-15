class_name Missile
extends Spatial


var velocity: Vector3 = Vector3.ZERO
var homing: bool = true
var homing_check_target_timer: float = 0.1
var homing_force: float = 1.0  # 1.0  # 
var parent_player_number: int
var closest_target: VehicleBody
var closest_target_distance: float
var closest_target_direction: Vector3
var closest_target_direction_normalised: Vector3
var print_timer: float = 0.1
var speed_up_down_rate: float = 0.5  # 1.0
var fwd_speed: float
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var exploded: bool = false
var weapon_type: int  
var flicker_thrust_timer: float = 0.1
var lifetime_seconds: float = 10.0
var homing_start_timer: float


# Built-in methods

func _ready():
	Global.debug_print(3, "Launched missile of type "+str(weapon_type))
	$ParticlesThrust.visible = true
	$Body/MeshInstance.visible = true
	if weapon_type == ConfigWeapons.Type.MISSILE or weapon_type == ConfigWeapons.Type.BALLISTIC_MISSILE:
		homing_start_timer = ConfigWeapons.HOMING_DELAY[weapon_type]
		lifetime_seconds = ConfigWeapons.LIFETIME_SECONDS[weapon_type]
		Global.debug_print(3, "  homing_start_timer="+str(homing_start_timer))
		Global.debug_print(3, "  TARGET_SPEED="+str(ConfigWeapons.TARGET_SPEED[weapon_type]))
		Global.debug_print(3, "  MUZZLE_SPEED="+str(ConfigWeapons.MUZZLE_SPEED[weapon_type]))
	$Body/OmniLight.light_color = Color(0, 1, 0)  # green = not active
	Global.debug_print(3, "  lifetime_seconds="+str(lifetime_seconds))


func _process(delta):
	
	lifetime_seconds -= delta
	flicker_thrust_timer -=delta
	print_timer -= delta
	
	if homing_start_timer >= 0.0:
		homing_start_timer -= delta

	if homing == true:
		homing_check_target_timer -= delta
	
	if flicker_thrust_timer < 0.0:
		flicker_thrust_timer = 0.1
		flicker_thrust_light()
	
	if print_timer < 0.0:
		#Global.debug_print(3, " hit_something="+str(hit_something))
		print_timer = 0.5
		if has_node("Body"):
			fwd_speed = abs($Body.transform.basis.xform_inv($Body.linear_velocity).z)
			#Global.debug_print(3, "fwd_speed="+str(fwd_speed))
			#Global.debug_print(3, "target_speed="+str(ConfigWeapons.TARGET_SPEED[weapon_type_name]))
	
	if exploded == true or lifetime_seconds < 0.0:
		
		if has_node("Explosion"):
			if $Explosion.effects_finished() == true:
				queue_free()
		else:
			queue_free()
	
	if lifetime_seconds < 0.0 and exploded == false:
		Global.debug_print(3, "Missile self-destructing: lifetime_seconds < 0.0 and exploded == false")
		explode(null)


func _physics_process(delta):
	
	if not has_node("Body"):
		return

	if fwd_speed == null:
		fwd_speed = abs($Body.transform.basis.xform_inv($Body.linear_velocity).z)
		#Global.debug_print(3, "fwd_speed="+str(fwd_speed))
		#Global.debug_print(3, "transform.basis.z="+str(transform.basis.z))
		#Global.debug_print(3, "target_speed="+str(ConfigWeapons.TARGET_SPEED[weapon_type_name]))
	
	
	if exploded == false:
		if homing == true and homing_start_timer <= 0.0:
			
			if closest_target != null: 
				
				# redirect the missile towards the target
				# velocity = velocity.linear_interpolate(closest_target_direction, delta*homing_force)
				# Vary the homing strength by distance
				var homing_force_adjusted: float = homing_force
				if closest_target_distance > 200.0:
					 homing_force_adjusted = homing_force/10.0
					 speed_up_down_rate = 0.5
				elif closest_target_distance > 50.0:
					 homing_force_adjusted = homing_force/5.0
					 speed_up_down_rate = 0.5
				elif closest_target_distance > 20.0:
					 homing_force_adjusted = homing_force*1.0
					 speed_up_down_rate = 10.0
				elif closest_target_distance > 10.0:
					 homing_force_adjusted = homing_force*1.0
					 speed_up_down_rate = 20.0
				else:
					 homing_force_adjusted = homing_force*2.0
					 speed_up_down_rate = 30.0
				velocity = velocity.linear_interpolate(closest_target_direction, delta*homing_force_adjusted)  # scale homing force by range
			
			if closest_target == null or (closest_target != null and closest_target_distance > 10.0): 
				# If not too close to a target (or there's no target), try to avoid the terrain
				
				# steer up if getting close to the terrain underneath
				if $RayCastDown.is_colliding():
					if "terrain" in $RayCastDown.get_collider().name.to_lower():
						velocity += transform.basis.y * 0.1
				else:  # steer down a bit
					velocity += -transform.basis.y * 0.05
					
				# steer up if aiming at the terrain
				if $RayCastForward.is_colliding():
					if "terrain" in $RayCastForward.get_collider().name.to_lower():
						velocity += transform.basis.y * 0.1
				
				# steer right a bit
				if $RayCastForwardLeft.is_colliding():
					if "terrain" in $RayCastForwardLeft.get_collider().name.to_lower():
						velocity += transform.basis.x * 0.025
						
				# steer left a bit
				if $RayCastForwardRight.is_colliding():
					if "terrain" in $RayCastForwardRight.get_collider().name.to_lower():
						velocity += -transform.basis.x * 0.025
				
				# steer up a bit
				if $RayCastForwardDown.is_colliding():
					if "terrain" in $RayCastForwardDown.get_collider().name.to_lower():
						velocity += transform.basis.y * 0.025
						
				# steer down a bit
				if $RayCastForwardUp.is_colliding():
					if "terrain" in $RayCastForwardUp.get_collider().name.to_lower():
						velocity += -transform.basis.y * 0.025
		
		if weapon_type == ConfigWeapons.Type.BALLISTIC:  #4:  # for ballistic weapons, add gravity
			velocity += Vector3.DOWN * 0.04
		elif weapon_type == ConfigWeapons.Type.ROCKET:  #4:  # for rocket add a little bit of gravity
			velocity += Vector3.DOWN * 0.01
		
		if weapon_type == ConfigWeapons.Type.ROCKET:  # 1:  # rocket
			add_random_movement(0.05)
		elif weapon_type == ConfigWeapons.Type.MISSILE or weapon_type == ConfigWeapons.Type.BALLISTIC_MISSILE:  # 2:  # missile
			add_random_movement(0.1)
		
		# interpolate to the target speed
		velocity = velocity.linear_interpolate((velocity.normalized())*ConfigWeapons.TARGET_SPEED[weapon_type], delta*speed_up_down_rate) 
		
		transform.origin += velocity * delta  # move the missile
		look_at(transform.origin + velocity.normalized(), Vector3.UP)  # point the missile in the direction it's moving
		
		if homing:
			if homing_check_target_timer < 0.0:
				homing_check_target_timer = 0.1
				for player in get_node("/root/MainScene").get_players():  # in range(1, 5): # explosion toward all players
					#if i != parent_player_number:
					if player.player_number != parent_player_number:
						var target: VehicleBody = player.get_vehicle_body()  # get_node("/root/Main/InstancePos"+str(i)+"/VC/V/CarBase/Body")
						#var target = get_node("/root/Main/InstancePos"+str(i)+"/VC/V/CarBase/Body")
						if target != null:  # it might have exploded already, leaving no body
							var distance = global_transform.origin.distance_to(target.global_transform.origin)
							if closest_target_distance == null or distance < closest_target_distance or closest_target == null or closest_target_direction == null:
								closest_target = target
								closest_target_distance = distance
								closest_target_direction =  closest_target.global_transform.origin - global_transform.origin
								closest_target_direction_normalised = closest_target_direction.normalized()


# Signal methods


func _on_Body_body_entered(body):
	Global.debug_print(3, "Missile hit body of type "+str(typeof(body))+", name="+str(body))
	if exploded == false:
		explode(body)


func _on_TimerCheckActiveLight_timeout():
	if $Body.has_node("OmniLight"):
		if homing == false:
			$Body/OmniLight.hide()
		else:
			if homing_check_target_timer > 0.0:
				$Body/OmniLight.light_color = Color(0, 1, 0)  # green = not active
				$Body/OmniLight.show()
			else:
				$Body/OmniLight.light_color = Color(1, 0, 0)  # red = active
				if closest_target_distance == null:
					$Body/OmniLight.show()
				else:
					$Body/OmniLight.visible = !$Body/OmniLight.visible  # flash red = homing on a target


# Public methods

func muzzle_speed() -> float:
	return ConfigWeapons.MUZZLE_SPEED[weapon_type]


func add_random_movement(strength) -> void:
	# steer left/right a bit
	velocity += transform.basis.x * rng.randfn(0.0, strength)
	
	# steer up/down a bit
	if $RayCastForwardDown.is_colliding():
		velocity += transform.basis.y * rng.randfn(0.0, strength)


func activate(_parent_player_number, _homing) -> void:
	homing = _homing
	parent_player_number = _parent_player_number
	if weapon_type == ConfigWeapons.Type.ROCKET or weapon_type == ConfigWeapons.Type.MISSILE or weapon_type == ConfigWeapons.Type.BALLISTIC_MISSILE: 
		$LaunchSound.playing = true
		$FlyingSound.playing = true
		$ThrustLight.show()
	else:
		$ThrustLight.hide()


func explode(body=null) -> void:  # null if lifetime has expired
	exploded = true
	$Body.queue_free()  # remove the body - it's destroyed
	$ParticlesThrust.visible = false
	$LaunchSound.playing = false
	$FlyingSound.playing = false
	var explosion: Explosion = load(Global.explosion_folder).instance()
	explosion.name = "Explosion"
	self.add_child(explosion)
	$Explosion.start_effects(self)  # start the explosion visual and audio effects
	$ThrustLight.hide()
	
	# TODO this shouldbe replaced by signals
	if not body == null:
		if body is VehicleBody:
			Global.debug_print(3, "Missile direct hit to "+str(body.name))
			body.hit_by_missile["active"] = true
			body.hit_by_missile["origin"] = transform.origin
			body.hit_by_missile["direction_for_explosion"] = velocity
			body.hit_by_missile["homing"] = homing
			body.hit_by_missile["direct_hit"] = true
			body.hit_by_missile["force"] = ConfigWeapons.EXPLOSION_STRENGTH[weapon_type]

	# regardless of what it hit, calc indirect damage to vehicle nearby, except for the one hit directly
	for player in get_node("/root/MainScene").get_players():  # in range(1, 5): # explosion toward all players
		Global.debug_print(3, "Found a target for missile indirect damage = "+str(player.name))
		var target: VehicleBody = player.get_vehicle_body()  # get_node("/root/Main/InstancePos"+str(i)+"/VC/V/CarBase/Body")
		#var target = get_node("/root/Main/InstancePos"+str(i)+"/VC/V/CarBase/Body")
		var direction: Vector3 = global_transform.origin - target.global_transform.origin
		var distance: float = global_transform.origin.distance_to(target.global_transform.origin)
		Global.debug_print(3, "distance = "+str(distance))
		if distance < ConfigWeapons.DAMAGE_INDIRECT[weapon_type]["range"] and target != body:
			Global.debug_print(3, "Missile indirect damage to "+str(target.name))
			target.hit_by_missile["active"] = true
			target.hit_by_missile["origin"] = transform.origin
			target.hit_by_missile["direction_for_explosion"] = direction
			target.hit_by_missile["homing"] = homing
			target.hit_by_missile["direct_hit"] = false
			target.hit_by_missile["distance"] = distance
			target.hit_by_missile["force"] = ConfigWeapons.EXPLOSION_STRENGTH[weapon_type]


func set_linear_velocity(_linear_velocity) -> void:
	$Body.linear_velocity = _linear_velocity


func set_angular_velocity(_angular_velocity) -> void:
	$Body.angular_velocity = _angular_velocity


func flicker_thrust_light() -> void:
	var rn: float = rng.randf()
	if exploded == false:
		# change tint to various kinds of orange
		if rn < 0.33:
			$ThrustLight.light_color = Color(1, 0.4, 0)  
		elif rn < 0.66: 
			$ThrustLight.light_color = Color(1, 0.6, 0) 
		else: 
			$ThrustLight.light_color = Color(1, 0.2, 0)

