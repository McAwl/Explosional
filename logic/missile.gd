extends RigidBody

var velocity = Vector3.ZERO
onready var lifetime_seconds = 10.0
var homing = true
var homing_check_target_timer = 0.1
var homing_force = 1.0  # 
var parent_player_number
var closest_target
var closest_target_distance
var closest_target_direction
var closest_target_direction_normalised
var print_timer = 0.1
var speed_up_down_rate = 1.0
var explosion_range = 10.0
var fwd_speed
var rng = RandomNumberGenerator.new()
var hit_something = false
var weapon_type  
var weapon_type_name  

# Called when the node enters the scene tree for the first time.
func _ready():
	$ParticlesThrust.visible = true
	$OmniLight.visible = true
	$ParticlesExplosion.emitting = false
	$ParticlesExplosion.visible = false
	# $ParticlesExplosion2.visible = false
	$MeshInstance.visible = true


func muzzle_speed():
	return ConfigWeapons.MUZZLE_SPEED[weapon_type_name]


func _process(delta):
	lifetime_seconds -= delta
	if homing == true:
		homing_check_target_timer -= delta
	print_timer -= delta
	
	if print_timer < 0.0:
		# print(" hit_something="+str(hit_something))
		# print("$ParticlesExplosion2.visible="+str($ParticlesExplosion2.visible))
		# print("$ParticlesExplosion2.emitting="+str($ParticlesExplosion2.emitting))
		# print("$ExplosionSound.playing="+str($ExplosionSound.playing))
		print_timer = 0.1
	
	if hit_something == true:
		lifetime_seconds = 2.0  # otherwise it might cut off the explosion anim/sound
		if $ExplosionSound.playing == false and $ParticlesExplosion.emitting == false:
		# if $ExplosionSound.playing == false and $ParticlesExplosion2/AnimationPlayer.current_animation != "Explode":
			# explosion noise finished
			#print("missile:process(): queue_free()")
			queue_free()
		#else:
		#	print("missile:process(): $ExplosionSound.playing OR $ParticlesExplosion.emitting")
	
	if lifetime_seconds < 0.0:
		queue_free()


func _physics_process(delta):
	if fwd_speed == null:
		fwd_speed = abs(transform.basis.xform_inv(linear_velocity).z)
		print("fwd_speed="+str(fwd_speed))
		print("target_speed="+str(ConfigWeapons.TARGET_SPEED[weapon_type_name]))
		
	if hit_something == false:
		if closest_target != null and homing == true: 
			
			# redirect the missile towards the target
			velocity = velocity.linear_interpolate(closest_target_direction, delta*homing_force)
		
		# interpolate to the target speed
		velocity = velocity.linear_interpolate((velocity.normalized())*ConfigWeapons.TARGET_SPEED[weapon_type_name], delta*speed_up_down_rate) 
		
		transform.origin += velocity * delta  # move the missile
		look_at(transform.origin + velocity.normalized(), Vector3.UP)  # point the missile in the direction it's moving
		
		if homing:
			if homing_check_target_timer < 0.0:
				homing_check_target_timer = 0.1
				for player in get_node("/root/TownScene").get_players():  # in range(1, 5): # explosion toward all players
					#if i != parent_player_number:
					if player.player_number != parent_player_number:
						var target = player.get_vehicle_body()  # get_node("/root/TownScene/InstancePos"+str(i)+"/VC/V/CarBase/Body")
						#var target = get_node("/root/TownScene/InstancePos"+str(i)+"/VC/V/CarBase/Body")
						var distance = global_transform.origin.distance_to(target.global_transform.origin)
						if closest_target_distance == null or distance < closest_target_distance or closest_target == null or closest_target_direction == null:
							closest_target = target
							closest_target_distance = distance
							closest_target_direction =  closest_target.global_transform.origin - global_transform.origin
							closest_target_direction_normalised = closest_target_direction.normalized()


func activate(_parent_player_number, _homing):
	homing = _homing
	parent_player_number = _parent_player_number


func _on_Missile_body_entered(body):
	if hit_something == false:
		# print("Missile hit something...")
		$ExplosionSound.playing = true
		$ParticlesExplosion.emitting = true
		$ParticlesExplosion.visible = true
		# $ParticlesExplosion2/AnimationPlayer.play("Explode")
		# $ParticlesExplosion2.visible = true
		hit_something = true
		$MeshInstance.visible = false
		$OmniLight.visible = false
		$ParticlesThrust.visible = false
		#  velocity = Vector3(0,0,0)  # ??????
			
		if "vehicle_body" in body.name:
			# print("Missile hit "+str(body.name))
			body.hit_by_missile["active"] = true
			body.hit_by_missile["origin"] = transform.origin
			body.hit_by_missile["direction_for_explosion"] = velocity
			body.hit_by_missile["homing"] = homing
			body.hit_by_missile["direct_hit"] = true
		else: 
			for player in get_node("/root/TownScene").get_players():  # in range(1, 5): # explosion toward all players
				var target = player.get_vehicle_body()  # get_node("/root/TownScene/InstancePos"+str(i)+"/VC/V/CarBase/Body")
				#var target = get_node("/root/TownScene/InstancePos"+str(i)+"/VC/V/CarBase/Body")
				var direction = global_transform.origin - target.global_transform.origin
				var distance = global_transform.origin.distance_to(target.global_transform.origin)
				if distance < explosion_range:
					# print("Missile hit "+str(body.name))
					target.hit_by_missile["active"] = true
					target.hit_by_missile["origin"] = transform.origin
					target.hit_by_missile["direction_for_explosion"] = direction
					target.hit_by_missile["homing"] = homing
					target.hit_by_missile["direct_hit"] = false
					target.hit_by_missile["distance"] = distance

