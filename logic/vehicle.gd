extends VehicleBody


const STEER_SPEED = 1.5
const STEER_LIMIT = 0.6 #0.4
const EXPLOSION_STRENGTH = 50.0

var steer_target = 0

export var engine_force_value = 60  #40
var player_number
var camera
export var speed = 0.0
var speed_low_limit = 5
var rng = RandomNumberGenerator.new()

var bomb_active = false

# missile
var missile_active = false
const MISSILE_COOLDOWN_TIMER = 0.5
const BOMB_COOLDOWN_TIMER = 0.5
var missile_cooldown_timer
var bomb_cooldown_timer
var missile_homing = false

var hit_by_missile = false
var hit_by_missile_origin
var hit_by_missile_velocity

var missile_scene = load("res://scenes/missile.tscn")  
var bomb_scene = load("res://scenes/bomb.tscn")  
var total_damage = 0.0
var take_damage = true

func _ready():
	pass #missile_active = false 


func get_speed():
	return speed


func _physics_process(delta):

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
	
	if hit_by_missile == true:
		print("Player "+str(player_number)+ " hit by missile!")
		#var direction = hit_by_missile_origin - $Body.transform.origin  
		var direction = hit_by_missile_velocity  # $Body.transform.origin - hit_by_missile_origin 
		direction[1] += 5.0
		var explosion_force = 400  # 100.0/pow(distance+1.0, 1.5)  # inverse square of distance
		apply_impulse( Vector3(0,0,0), explosion_force*direction.normalized() )   # offset, impulse(=direction*force)
		angular_velocity =  Vector3(rng.randf_range(-10, 10), rng.randf_range(-10, 10), rng.randf_range(-10, 10)) 
		hit_by_missile = false
		total_damage += 1
		if $Particles.emitting == true:
			$Particles.amount += 1
			engine_force_value *= 0.75
		else:
			$Particles.emitting = true


func _process(delta):
	
	if Input.is_action_pressed("missile_player"+str(player_number)) and missile_active == false:
		var b = missile_scene.instance()
		add_child(b)  
		b.global_transform.origin = $MissilePosition.global_transform.origin
		b.velocity = transform.basis.z * b.muzzle_velocity
		b.velocity[1] += 1.0 
		b.initial_speed = b.velocity.length()
		b.linear_velocity = linear_velocity
		b.angular_velocity = angular_velocity
		b.rotation_degrees = $MissilePosition.rotation_degrees
		missile_active = true
		missile_cooldown_timer = MISSILE_COOLDOWN_TIMER
		b.parent_player_number = player_number
		b.homing = missile_homing
		b.set_as_toplevel(true)

	if missile_active == true:
		missile_cooldown_timer -= delta
		if missile_cooldown_timer < 0.0:
			missile_active = false

	if Input.is_action_pressed("bomb_player"+str(player_number)) and bomb_active == false:
		var b = bomb_scene.instance()
		add_child(b) 
		b.rotation_degrees = rotation_degrees
		bomb_active = true
		bomb_cooldown_timer = BOMB_COOLDOWN_TIMER
		b.activate($BombPosition.global_transform.origin, linear_velocity, angular_velocity)
		b.set_as_toplevel(true)

	if bomb_active == true:
		bomb_cooldown_timer -= delta
		if bomb_cooldown_timer < 0.0:
			bomb_active = false
			

func _on_Body_body_entered(body):
	
	if "Missile" in body.name:
		hit_by_missile = true
		hit_by_missile_origin = body.transform.origin
		hit_by_missile_velocity = body.velocity
		body.get_node("explosion").playing = true
		body.get_node("Particles2").emitting = true
		body.hit_something = true
		


