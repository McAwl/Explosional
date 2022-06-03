extends Spatial

var velocity = Vector3.ZERO
onready var lifetime_seconds = 10.0
var homing = true
var homing_check_target_timer = 0.1
var homing_force = 1.0  # 1.0  # 
var homing_start_timer = 0.5
var parent_player_number
var closest_target
var closest_target_distance
var closest_target_direction
var closest_target_direction_normalised
var print_timer = 0.1
var speed_up_down_rate = 0.5  # 1.0
var explosion_range = 10.0
var fwd_speed
var rng = RandomNumberGenerator.new()
var exploded = false
var weapon_type  
var weapon_type_name  
var flicker_thrust_timer = 0.1

# Called when the node enters the scene tree for the first time.
func _ready():
	$ParticlesThrust.visible = true
	$Body/MeshInstance.visible = true


func muzzle_speed():
	return ConfigWeapons.MUZZLE_SPEED[weapon_type_name]


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
		# print(" hit_something="+str(hit_something))
		print_timer = 0.5
		if has_node("Body"):
			fwd_speed = abs($Body.transform.basis.xform_inv($Body.linear_velocity).z)
			#print("fwd_speed="+str(fwd_speed))
			#print("target_speed="+str(ConfigWeapons.TARGET_SPEED[weapon_type_name]))
	
	if exploded == true or lifetime_seconds < 0.0:
		
		if $Explosion.effects_finished() == true:
			queue_free()
	
	if lifetime_seconds < 0.0 and exploded == false:
		explode(null)


func _physics_process(delta):
	
	if not has_node("Body"):
		return

	if fwd_speed == null:
		fwd_speed = abs($Body.transform.basis.xform_inv($Body.linear_velocity).z)
		#print("fwd_speed="+str(fwd_speed))
		#print("transform.basis.z="+str(transform.basis.z))
		#print("target_speed="+str(ConfigWeapons.TARGET_SPEED[weapon_type_name]))
		
	if exploded == false:
		if homing == true: ## and homing_start_timer <= 0.0:
			
			if closest_target != null: 
				
				# redirect the missile towards the target
				# velocity = velocity.linear_interpolate(closest_target_direction, delta*homing_force)
				# Vary the homing strength by distance
				var homing_force_adjusted
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
		
		if weapon_type == 4:  # for ballistic weapons, add gravity
			velocity += Vector3.DOWN * 0.04
		
		if weapon_type == 1:  # rocket
			add_random_movement(0.05)
		elif weapon_type == 2:  # missile
			add_random_movement(0.1)
		
		# interpolate to the target speed
		velocity = velocity.linear_interpolate((velocity.normalized())*ConfigWeapons.TARGET_SPEED[weapon_type_name], delta*speed_up_down_rate) 
		
		transform.origin += velocity * delta  # move the missile
		look_at(transform.origin + velocity.normalized(), Vector3.UP)  # point the missile in the direction it's moving
		
		if homing:
			if homing_check_target_timer < 0.0:
				homing_check_target_timer = 0.1
				for player in get_node("/root/Main").get_players():  # in range(1, 5): # explosion toward all players
					#if i != parent_player_number:
					if player.player_number != parent_player_number:
						var target = player.get_vehicle_body()  # get_node("/root/Main/InstancePos"+str(i)+"/VC/V/CarBase/Body")
						#var target = get_node("/root/Main/InstancePos"+str(i)+"/VC/V/CarBase/Body")
						if target != null:  # it might have exploded already, leaving no body
							var distance = global_transform.origin.distance_to(target.global_transform.origin)
							if closest_target_distance == null or distance < closest_target_distance or closest_target == null or closest_target_direction == null:
								closest_target = target
								closest_target_distance = distance
								closest_target_direction =  closest_target.global_transform.origin - global_transform.origin
								closest_target_direction_normalised = closest_target_direction.normalized()


func add_random_movement(strength):
	# steer left/right a bit
	velocity += transform.basis.x * rng.randfn(0.0, strength)
	
	# steer up/down a bit
	if $RayCastForwardDown.is_colliding():
		velocity += transform.basis.y * rng.randfn(0.0, strength)


func activate(_parent_player_number, _homing):
	homing = _homing
	parent_player_number = _parent_player_number
	if weapon_type == 1 or weapon_type == 2:  # rocket or missile
		$LaunchSound.playing = true
		$FlyingSound.playing = true
		$ThrustLight.show()
	else:
		$ThrustLight.hide()


func _on_Body_body_entered(body):
	if exploded == false:
		explode(body)


func explode(body=null):  # null if lifetime has expired
	print("Missile hit something...")
	exploded = true
	$Body.queue_free()  # remove the body - it's destroyed
	$ParticlesThrust.visible = false
	$LaunchSound.playing = false
	$FlyingSound.playing = false
	$Explosion.start_effects()  # start the explosion visual and audio effects
	$ThrustLight.hide()
	
	# TODO this shouldbe replaced by signals
	if not body == null:
		if body is VehicleBody:
			# print("Missile hit "+str(body.name))
			body.hit_by_missile["active"] = true
			body.hit_by_missile["origin"] = transform.origin
			body.hit_by_missile["direction_for_explosion"] = velocity
			body.hit_by_missile["homing"] = homing
			body.hit_by_missile["direct_hit"] = true

	# regardless of what it hit, calc indirect damage to vehicle nearby, except for the one hit directly
	for player in get_node("/root/Main").get_players():  # in range(1, 5): # explosion toward all players
		var target = player.get_vehicle_body()  # get_node("/root/Main/InstancePos"+str(i)+"/VC/V/CarBase/Body")
		#var target = get_node("/root/Main/InstancePos"+str(i)+"/VC/V/CarBase/Body")
		var direction = global_transform.origin - target.global_transform.origin
		var distance = global_transform.origin.distance_to(target.global_transform.origin)
		if distance < explosion_range and target != body:
			# print("Missile hit "+str(body.name))
			target.hit_by_missile["active"] = true
			target.hit_by_missile["origin"] = transform.origin
			target.hit_by_missile["direction_for_explosion"] = direction
			target.hit_by_missile["homing"] = homing
			target.hit_by_missile["direct_hit"] = false
			target.hit_by_missile["distance"] = distance


func set_linear_velocity(_linear_velocity):
	$Body.linear_velocity = _linear_velocity


func set_angular_velocity(_angular_velocity):
	$Body.angular_velocity = _angular_velocity


func flicker_thrust_light():
	var rn = rng.randf()
	if exploded == false:
		# change tint to various kinds of orange
		if rn < 0.33:
			$ThrustLight.light_color = Color(1, 0.4, 0)  
		elif rn < 0.66: 
			$ThrustLight.light_color = Color(1, 0.6, 0) 
		else: 
			$ThrustLight.light_color = Color(1, 0.2, 0)
