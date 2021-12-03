extends RigidBody


export var muzzle_velocity = 5  #25
export var g = Vector3.DOWN * 0  # 20

var velocity = Vector3.ZERO
onready var lifetime_seconds = 2.0
var homing = true
var homing_check_target_timer = 0.1
var homing_force = 0.05  # 0.1 OK 1.0 too strong, keep 0.01 to 0.01
var parent_player_number
var closest_target
var closest_target_distance
var closest_target_direction
var closest_target_direction_normalised
var print_timer = 0.1
var initial_speed

var hit_something = false

		
func _process(delta):
	lifetime_seconds -= delta
	homing_check_target_timer -= delta
	print_timer -= delta
	
	if hit_something == true and $explosion.playing == false and $Particles2.emitting == true:
		# explosiion noise finished
		queue_free()
	
	if lifetime_seconds < 0.0:
		queue_free()

func _physics_process(delta):
	if closest_target != null: 
		
		velocity = initial_speed * ( ((1.0-homing_force)*velocity.normalized()) + (homing_force*closest_target_direction.normalized()) )  # update this periodically below
		
		if print_timer<0.0:
			print_timer = 0.1
			
	else:
		velocity += g
		if print_timer<0.0:
			print_timer = 0.1
			print("velocity g*delta)="+str(velocity))
	

	#look_at(transform.origin + velocity.normalized(), Vector3.UP)
	transform.origin += velocity * delta
	
	
	if homing_check_target_timer < 0.0:
		homing_check_target_timer = 0.1
		# print("closest_target="+str(closest_target))
		for i in range(1,5): # explosion toward all players
			if i != parent_player_number:
				var target = get_node("/root/TownScene/InstancePos"+str(i)+"/VC/V/CarBase/Body")
				var distance = global_transform.origin.distance_to(target.global_transform.origin)
				if closest_target_distance == null or distance < closest_target_distance or closest_target == null or closest_target_direction == null:
					closest_target = target
					closest_target_distance = distance
					closest_target_direction =  closest_target.global_transform.origin - global_transform.origin
					closest_target_direction_normalised = closest_target_direction.normalized()



