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


func _ready():
	pass  #bomb = $Bomb #.player_number = player_number


func _physics_process(delta):
	
	rng.randomize()
	var my_random_number = rng.randf_range(0.0, 1000.0)
	if my_random_number < 1.0:
		# add impulse force (explosion)
		apply_impulse( Vector3(rng.randf_range(0.0, 0.01), 1.0, rng.randf_range(0.0, 0.01)), Vector3(rng.randf_range(0.0, 1.0), EXPLOSION_STRENGTH+rng.randf_range(0.0, EXPLOSION_STRENGTH), rng.randf_range(0.0, 1.0)))
		#print("explosion!")
	
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

func get_speed():
	return speed


