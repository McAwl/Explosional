extends RigidBody


export var muzzle_velocity = 2.0  # metres per second added to vehicle movement
# export var g = Vector3.DOWN * 0  # 20

var velocity = Vector3.ZERO
onready var lifetime_seconds = 5.0
var homing = true
var homing_check_target_timer = 0.1
var parent_player_number
var closest_target
var closest_target_distance
var closest_target_direction
var closest_target_direction_normalised
var print_timer = 0.1
var initial_speed
var random_movement_timer = 0.2

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
		print_timer = 0.1
		print("missile/rocket linear_velocity = "+str(linear_velocity))
	
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


func _physics_process(delta):
	
	if hit_something == false:
		#if closest_target != null and homing == true: 
			
			# The first method we tried and it worked OK - apply changes directly to the velocity
			#velocity = initial_speed * ( ((1.0-homing_force)*velocity.normalized()) + (homing_force*closest_target_direction.normalized()) )  # update this periodically below
			
			# The second method: steer the missile using forces perpendicular to its flight direction
			# Occasionally apply a small random force so the missile doesn't fly exactly straight
		
			#	if rng.randf() < 0.5:
			#		var impulse_force = 1.0*(Vector3(rng.randf(), rng.randf(), rng.randf()).normalized())
			#		print("applying impulse force to missile: "+str(impulse_force))
			#		apply_impulse( Vector3(0,0,0), -closest_target_direction_normalised*impulse_force)   # offset, impulse(=direction*force)
	
		#else:
			# velocity += g
		if print_timer < 0.0:
			print_timer = 0.1
		
		# transform.origin += velocity * delta  # this is for method 1 only 
		
		# ??? this stops the projectile. Why? 
		#look_at(transform.origin + linear_velocity.normalized(), Vector3.UP)  # turns to point in its direction of travel
		
		if homing:
			# steer the missile aroudn the terrain
			if $Raycasts/RayCastForward.is_colliding():
				if "terrain" in $Raycasts/RayCastForward.get_collider().name.to_lower():
					if $Raycasts/RayCastBitLeft.is_colliding() and not $Raycasts/RayCastBitRight.is_colliding():
						if "terrain" in $Raycasts/RayCastBitLeft.get_collider().name.to_lower():
							apply_impulse(Vector3(0,0,0), -10.0*transform.basis.x)  # push right
					elif $Raycasts/RayCastBitRight.is_colliding() and not $Raycasts/RayCastBitLeft.is_colliding():
						if "terrain" in $Raycasts/RayCastBitRight.get_collider().name.to_lower():
							apply_impulse(Vector3(0,0,0), 10.0*transform.basis.x)  # push left
					elif $Raycasts/RayCastBitLeft.is_colliding() and $Raycasts/RayCastBitRight.is_colliding():
						if "terrain" in $Raycasts/RayCastBitLeft.get_collider().name.to_lower() and "terrain" in $Raycasts/RayCastBitRight.get_collider().name.to_lower():
							apply_impulse(Vector3(0,0,0), -10.0*transform.basis.y)  # push higher
			
			if $Raycasts/RayCastDown.is_colliding():
				if "terrain" in $Raycasts/RayCastDown.get_collider().name.to_lower():
					apply_impulse(Vector3(0,0,0), -2.0*transform.basis.y)  # push higher
			else:
				apply_impulse(Vector3(0,0,0), 0.25*transform.basis.y)  # push a little lower
							
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

	# Occasionally apply a small random force so the missile doesn't fly exactly straight
	# apply at direction perpendicular to direction
	random_movement_timer -= delta
	if random_movement_timer < 0.0:
		random_movement_timer = 0.1
		var impulse_magnitude = 10.0
		if rng.randf() < 0.5:
			apply_impulse(Vector3(0,0,0), impulse_magnitude*rng.randfn(0.0, 1.0)*transform.basis.x)  # mean, stdev
		if rng.randf() < 0.5:
			apply_impulse(Vector3(0,0,0), impulse_magnitude*rng.randfn(0.0, 1.0)*transform.basis.y)  # mean, stdev
		


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

