extends RigidBody


export var muzzle_velocity = 5  #25
export var g = Vector3.DOWN * 0  # 20

var velocity = Vector3.ZERO
onready var lifetime_seconds = 2.0
var homing = true
var homing_check_target_timer = 0.1
var homing_force = 0.2  # 0.1 OK 1.0 too strong, keep < 0.1
var parent_player_number
var closest_target
var closest_target_distance
var closest_target_direction
var closest_target_direction_normalised
var print_timer = 0.1
var initial_speed
var explosion_range = 10.0

var rng = RandomNumberGenerator.new()

var hit_something = false


# Called when the node enters the scene tree for the first time.
func _ready():
	$ParticlesThrust.visible = true
	$ParticlesExplosion.visible = false	


func _process(delta):
	lifetime_seconds -= delta
	if homing == true:
		homing_check_target_timer -= delta
	print_timer -= delta
	
	if hit_something == true and $ExplosionSound.playing == false and $ParticlesExplosion.emitting == true:
		# explosion noise finished
		queue_free()
	
	if lifetime_seconds < 0.0:
		queue_free()


func _physics_process(delta):
	if hit_something == false:
		if closest_target != null and homing == true: 
			
			velocity = initial_speed * ( ((1.0-homing_force)*velocity.normalized()) + (homing_force*closest_target_direction.normalized()) )  # update this periodically below
			
			if print_timer<0.0:
				print_timer = 0.1
				
		else:
			velocity += g
			if print_timer<0.0:
				print_timer = 0.1
		
		transform.origin += velocity * delta
		look_at(transform.origin + velocity.normalized(), Vector3.UP)
		
		if homing:
			if homing_check_target_timer < 0.0:
				homing_check_target_timer = 0.1
				for player in get_node("/root/TownScene").get_players():  # in range(1, 5): # explosion toward all players
					#if i != parent_player_number:
					if player.player_number != parent_player_number:
						var target = player.get_carbody()  # get_node("/root/TownScene/InstancePos"+str(i)+"/VC/V/CarBase/Body")
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
		hit_something = true
		#  velocity = Vector3(0,0,0)  # ??????
			
		if "CarBody" in body.name:
			# print("Missile hit "+str(body.name))
			body.hit_by_missile["active"] = true
			body.hit_by_missile["origin"] = transform.origin
			body.hit_by_missile["direction_for_explosion"] = velocity
			body.hit_by_missile["homing"] = homing
			body.hit_by_missile["direct_hit"] = true
		else: 
			for player in get_node("/root/TownScene").get_players():  # in range(1, 5): # explosion toward all players
				var target = player.get_carbody()  # get_node("/root/TownScene/InstancePos"+str(i)+"/VC/V/CarBase/Body")
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

