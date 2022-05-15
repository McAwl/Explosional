extends RigidBody


export var muzzle_velocity = 1.0  # metres per second added to vehicle movement
# export var g = Vector3.DOWN * 0  # 20

# var velocity = Vector3.ZERO
onready var lifetime_seconds = 10.0
var homing = true
var homing_check_target_timer = 0.1
var parent_player_number
var closest_target
var closest_target_distance
var closest_target_direction
var closest_target_direction_normalised
var closest_target_direction_normalised_local
var print_timer = 0.1
var initial_speed
var random_movement_timer = 0.2
var light_flicker_timer = 0.1
var fwd_speed
var random_movement_vector = Vector3(0,0,0)
var linear_velocity_ewma
var rng = RandomNumberGenerator.new()

var hit_something = false

var explosion_range = 10.0

var homing_force = 0.2  # 0.1 OK 1.0 too strong, keep < 0.1

# Called when the node enters the scene tree for the first time.
func _ready():
	$ParticlesThrust.visible = true
	$OmniLight.visible = true
	$ParticlesExplosion.emitting = false
	$ParticlesExplosion.visible = false
	# $ParticlesExplosion2.visible = false
	$MeshInstance.visible = true


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
		print_timer = 0.5
		print("missile/rocket linear_velocity = "+str(linear_velocity))
		print("missile/rocket fwd speed = "+str(fwd_speed))
		print("closest_target_direction_normalised="+str(closest_target_direction_normalised))
		print("closest_target_direction_normalised_local="+str(closest_target_direction_normalised_local))
		
	
	if hit_something == true:
		lifetime_seconds = 2.0  # otherwise it might cut off the explosion anim/sound
		if $ExplosionSound.playing == false and $ParticlesExplosion.emitting == false:
		# if $ExplosionSound.playing == false and $ParticlesExplosion2/AnimationPlayer.current_animation != "Explode":
			# explosion noise finished
			# print("missile:process(): queue_free()")
			queue_free()
		# else:
		# 	print("missile:process(): $ExplosionSound.playing OR $ParticlesExplosion.emitting")
	
	if lifetime_seconds < 0.0:
		queue_free()
	
	# flicker the light from the thrust animation
	light_flicker_timer -= delta
	if light_flicker_timer < 0.0:
		$OmniLight.light_energy=rng.randi_range(1,16)
		light_flicker_timer = 0.1


func _integrate_forces(state):
	
	if linear_velocity_ewma == null:
		linear_velocity_ewma = linear_velocity
	else:
		linear_velocity_ewma = (0.001*linear_velocity_ewma) + ((1.0-0.001)*linear_velocity_ewma)
	# Any direct changes to the physics properties needs to happen here, not in _process or _process_physics
	# look_at(transform.origin + linear_velocity_ewma.normalized(), Vector3.UP)  # turns to point in its direction of travel
	# keep the same forward speed at all times - e.g. when turning
	# linear_velocity = fwd_speed*linear_velocity.normalized()
	
	# steer the missile gently around the terrain up/down
	#$ThrustUp.visible = false
	#if $Raycasts/RayCastBitDown.is_colliding():
	#	if "terrain" in $Raycasts/RayCastBitDown.get_collider().name.to_lower():
	#		transform.basis...rotation_degrees(-1.0)  #apply_impulse(Vector3(0,0,0), 0.01*fwd_speed*delta*transform.basis.y)  # up
	#		print("apply_impulse up")
	#		$ThrustUp.visible = true
	#		$ThrustDown.visible = false
	#	else:
	#		print("raycastbitdown colliding with "+str($Raycasts/RayCastBitDown.get_collider().name))


func _physics_process(delta):

	if hit_something == false:
		#if closest_target != null and homing == true: 
			
			# The first method we tried and it worked OK - apply changes directly to the velocity
			#velocity = initial_speed * ( ((1.0-homing_force)*velocity.normalized()) + (homing_force*closest_target_direction.normalized()) )  # update this periodically below
			#if direction_local.z > 0:
				#print("is in front")
				# apply_impulse(Vector3(0,0,0), 0.25*transform.basis.x)  # push a little left
			#else:
			#     print("is behind")
			#if closest_target_direction_normalised_local.x > 0:
			#	# print("is right")
			#	apply_impulse(Vector3(0,0,0), 10.0*Vector3.LEFT*global_transform.basis.xform_inv(linear_velocity).normalized().z)  # push right  # push a little right
			#else:
			#	# print("is left")
			#	apply_impulse(Vector3(0,0,0), 10.0*Vector3.RIGHT*global_transform.basis.xform_inv(linear_velocity).normalized().z)  # push right  # push a little left
			#if dir.y > 0:
			#     print("is over the horizon")
			#else:
			#     print("is under the horizon")
			# The second method: steer the missile using forces perpendicular to its flight direction
			# target is left
			#apply_impulse(Vector3(0,0,0), 0.25*transform.basis.x)  # push a little left/right in the direction of the target
			# target is right
			#apply_impulse(Vector3(0,0,0), -0.25*transform.basis.x)  # push a little left/right in the direction of the target
			# target is up
			#apply_impulse(Vector3(0,0,0), -0.25*transform.basis.y)  # push a little left/right in the direction of the target
			# target is down
			#apply_impulse(Vector3(0,0,0), 0.25*transform.basis.y)  # push a little left/right in the direction of the target

		if homing:
			
			# steer the missile aroudn the terrain left/right
			#if $Raycasts/RayCastForward.is_colliding():
			#	if "terrain" in $Raycasts/RayCastForward.get_collider().name.to_lower():
			#		if $Raycasts/RayCastBitLeft.is_colliding():
			#			if "terrain" in $Raycasts/RayCastBitLeft.get_collider().name.to_lower():
			#				apply_impulse(Vector3(0,0,0), 2.0*Vector3.RIGHT*global_transform.basis.xform_inv(linear_velocity).normalized().z)  # push right
			#		if $Raycasts/RayCastBitRight.is_colliding():
			#			if "terrain" in $Raycasts/RayCastBitRight.get_collider().name.to_lower():
			#				apply_impulse(Vector3(0,0,0), 2.0*Vector3.LEFT*global_transform.basis.xform_inv(linear_velocity).normalized().z)  # push left
			#		if $Raycasts/RayCastDown.is_colliding():
			#			if "terrain" in $Raycasts/RayCastDown.get_collider().name.to_lower():
			#				apply_impulse(Vector3(0,0,0), 2.0*Vector3.UP*global_transform.basis.xform_inv(linear_velocity).normalized().z)  # push higher
			#		if $Raycasts/RayCastUp.is_colliding():
			#			if "terrain" in $Raycasts/RayCastUp.get_collider().name.to_lower():
			#				apply_impulse(Vector3(0,0,0), 2.0*Vector3.DOWN*global_transform.basis.xform_inv(linear_velocity).normalized().z)  # push lower
			
			# steer the missile gently around the terrain up/down
			$ThrustUp.visible = false
			if $Raycasts/RayCastBitDown.is_colliding():
				if "terrain" in $Raycasts/RayCastBitDown.get_collider().name.to_lower():
					apply_impulse(Vector3(0,0,0), -0.1*fwd_speed*delta*transform.basis.y)  # up slowly
					print("apply_impulse up")
					$ThrustUp.visible = true
					$ThrustDown.visible = false
				else:
					print("raycastbitdown colliding with "+str($Raycasts/RayCastBitDown.get_collider().name))
			if $Raycasts/RayCastDown.is_colliding():
				if "terrain" in $Raycasts/RayCastDown.get_collider().name.to_lower():
					apply_impulse(Vector3(0,0,0), -0.2*fwd_speed*delta*transform.basis.y)  # up a bit faster
					print("apply_impulse up")
					$ThrustUp.visible = true
					$ThrustDown.visible = false
				else:
					print("raycastbitdown colliding with "+str($Raycasts/RayCastBitDown.get_collider().name))
			$Raycasts/RayCastBitDown.force_raycast_update()
			$Raycasts/RayCastDown.force_raycast_update()
			if $Raycasts/RayCastBitDown.is_colliding()==false and $Raycasts/RayCastDown.is_colliding()==false:
				apply_impulse(Vector3(0,0,0), 0.1*fwd_speed*delta*transform.basis.y)  # down slowly
				print("apply_impulse down")
				#apply_impulse(Vector3(0,0,0), Vector3.DOWN*global_transform.basis.xform_inv(linear_velocity).normalized().z)  # push a little lower
				$ThrustDown.visible = true
			else:
				$ThrustDown.visible = false

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
							closest_target_direction_normalised_local = to_local(closest_target_direction_normalised)

	# Occasionally apply a small random force so the missile doesn't fly exactly straight
	# apply at direction perpendicular to direction
	random_movement_timer -= delta
	if random_movement_timer < 0.0:
		random_movement_timer = 0.05
		var impulse_magnitude = 0.001  # 0.1
		#random_movement_vector.x += impulse_magnitude*rng.randfn() # "random walk"
		#random_movement_vector.y += impulse_magnitude*rng.randfn()
		random_movement_vector.x = impulse_magnitude*rng.randfn() 
		random_movement_vector.y = impulse_magnitude*rng.randfn()
		apply_impulse(Vector3(0,0,0), random_movement_vector.x*transform.basis.x)  # left/right
		apply_impulse(Vector3(0,0,0), random_movement_vector.y*transform.basis.y)  # up/down


func activate(_parent_player_number, _homing):
	homing = _homing
	parent_player_number = _parent_player_number


func _on_Missile_body_entered(body):
	if hit_something == false:
		print("Missile hit something...")
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
			print("Missile hit "+str(body.name))
			body.hit_by_missile["active"] = true
			body.hit_by_missile["origin"] = transform.origin
			body.hit_by_missile["direction_for_explosion"] = linear_velocity  #velocity
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

