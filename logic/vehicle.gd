extends VehicleBody


const STEER_SPEED = 1.5
const STEER_LIMIT = 0.6 #0.4
const EXPLOSION_STRENGTH = 50.0

var steer_target = 0

export var engine_force_value = 40
var player_number
var camera
export var speed = 0.0
var rng = RandomNumberGenerator.new()

export var muzzle_velocity = 25
export var g = Vector3.DOWN * 20
var velocity = Vector3.ZERO
var missile_active = false
const MISSILE_COOLDOWN_TIMER = 0.25
var missile_cooldown_timer

var hit_by_missile = false
var hit_by_missile_origin

var missile_scene = load("res://scenes/missile.tscn")  # export (PackedScene) var Missile

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
		if speed < 5 and speed != 0:
			engine_force = clamp(engine_force_value * 5 / speed, 0, 100)
		else:
			engine_force = engine_force_value
	else:
		engine_force = 0
		
	if Input.is_action_pressed("reverse_player"+str(player_number)):
		# Increase engine force at low speeds to make the initial acceleration faster.
		if fwd_mps >= -1:
			speed = linear_velocity.length()
			if speed < 5 and speed != 0:
				engine_force = -clamp(engine_force_value * 5 / speed, 0, 100)
			else:
				engine_force = -engine_force_value
		else:
			brake = 1
	else:
		brake = 0.0

	steering = move_toward(steering, steer_target, STEER_SPEED * delta)
	
	if hit_by_missile == true:
		print("Player "+str(player_number)+ " hit by missile!")
		var direction = hit_by_missile_origin - $Body.transform.origin  
		direction[1] += 20.0
		var explosion_force = 400  # 100.0/pow(distance+1.0, 1.5)  # inverse square of distance
		apply_impulse( Vector3(0,0,0), explosion_force*direction.normalized() )   # offset, impulse(=direction*force)
		angular_velocity =  Vector3(rng.randf_range(-10, 10), rng.randf_range(-10, 10), rng.randf_range(-10, 10)) 
		hit_by_missile = false
		
	# detect the wheels touching grass 
	#var w1r = $Wheel1.get_node("RayCast")
	#var w2r = $Wheel2.get_node("RayCast")
	#var w3r = $Wheel3.get_node("RayCast")
	#var w4r = $Wheel4.get_node("RayCast")
	#if w1r.is_colliding() and w2r.is_colliding() and w3r.is_colliding() and w4r.is_colliding():
	#	var w1cpn = w1r.get_collider().get_parent().name
#		var w2cpn = w2r.get_collider().get_parent().name#
	#	var w3cpn = w3r.get_collider().get_parent().name
	#	var w4cpn = w4r.get_collider().get_parent().name
	#	#print( str(player_number)+": "+w1cpn+" "+w1cpn+" "+w1cpn+" "+w1cpn)
	#	if w1cpn == "grass" and w2cpn == "grass" and w3cpn == "grass" and w4cpn == "grass":
	#		apply_impulse( Vector3(rng.randf_range(0.0, 0.01), 1.0, rng.randf_range(0.0, 0.01)), Vector3(rng.randf_range(0.0, 1.0), 5*EXPLOSION_STRENGTH+rng.randf_range(0.0, 5*EXPLOSION_STRENGTH), rng.randf_range(0.0, 1.0)))


func _process(delta):
	
	if Input.is_action_pressed("missile_player"+str(player_number)) and missile_active == false:
		var b = missile_scene.instance()
		add_child(b)  # #owner.add_child(b)
		#b.transform = global_transform 
		#b.global_transform.origin = $MissilePosition.global_transform.origin
		b.global_transform.origin = $MissilePosition.global_transform.origin
		#b.global_transform.origin[1] -= 0.1  # down a bit (centre of car)
		#b.global_transform.origin[2] += 3.0  # forward a bit (in front of car)
		#b.velocity = b.transform.basis.z * b.muzzle_velocity
		b.velocity = transform.basis.z * b.muzzle_velocity
		b.linear_velocity = linear_velocity
		b.angular_velocity = angular_velocity
		b.rotation_degrees = rotation_degrees
		missile_active = true
		missile_cooldown_timer = MISSILE_COOLDOWN_TIMER
		b.set_as_toplevel(true)

	if missile_active == true:
		missile_cooldown_timer -= delta
		if missile_cooldown_timer < 0.0:
			missile_active = false




func _on_Body_body_entered(body):
	if "Missile" in body.name:
		hit_by_missile = true
		hit_by_missile_origin = body.transform.origin
		body.queue_free()
		


