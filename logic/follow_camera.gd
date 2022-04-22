extends Camera

export var min_distance = 2.0
export var max_distance = 4.0
export var angle_v_adjust = 0.0

var collision_exception = []
export var height = 1.5

var FOLLOW_SPEED = 2.0  # set 0-1: 0.1=slow follow 0.9=fast follow
var lerp_val = 0.5
var target
var timer_0_5s = 0.5
var number_of_players

func _ready():
	# environment = get_node("/root/TownScene/Viewport/WorldEnvironment")
	# Find collision exceptions for ray.
	var node = self
	target = global_transform
	while(node):
		if (node is RigidBody):
			collision_exception.append(node.get_rid())
			break
		else:
			#if node is not null:#
			#	print("node = "+node.name)
			if node.name != "Body":
				node = get_node("../../")
			#if node:
			#	print("reparented node = "+node.name)

	# This detaches the camera transform from the parent spatial node.
	set_as_toplevel(true)

func init(_number_of_players):
	number_of_players= _number_of_players
	
	
func get_carbody():
	return get_parent().get_parent()


func _physics_process(delta):
	
	timer_0_5s -= delta
	
	var cbts = get_parent().get_node("CameraBasesTargets")
	var target_forward = cbts.get_node("CamTargetForward").get_global_transform()
	var target_reverse = cbts.get_node("CamTargetReverse").get_global_transform()
	var cam_base_forward = cbts.get_node("CamBaseForward").get_global_transform()
	# var cam_base_forward2 = get_parent().get_node("CamBaseForward2").get_global_transform()
	var cam_base_reverse = cbts.get_node("CamBaseReverse").get_global_transform()
	
	var linear_velocity = get_parent().get_parent().linear_velocity
	var fwd_mps = get_parent().get_parent().transform.basis.xform_inv(linear_velocity).z
	var angular_velocity = get_parent().get_parent().angular_velocity
	
	if abs(fwd_mps) < 0.5:
		if abs(get_carbody().rotation_degrees[0]) > 90 or abs(get_carbody().rotation_degrees[2]) > 90:
			target_forward = cbts.get_global_transform()
			target_reverse = cbts.get_global_transform()
			cam_base_forward = cbts.get_global_transform()
			cam_base_reverse = cbts.get_global_transform()

	# when launched by explosion, angular velocity is high and fwd_mps swaps from + to (and is also high)
	# this stops the fast switching in this case - zooms out and stops rotating the camera so fast
	# fix is to follow the target faster, but follow the base more slowly
	var follow_speed_multiplier = 1.0 + 0.01*angular_velocity.length()*abs(fwd_mps)
	var modify_by_num_players = 1.0 + ((float(number_of_players)-1.0)/2.0)  # keep closer to the vehicle the smaller the viewport is (number of players)
	
	if fwd_mps >= -2.0:
		global_transform = global_transform.interpolate_with(cam_base_forward, modify_by_num_players * delta * FOLLOW_SPEED / follow_speed_multiplier)
		target = target.interpolate_with(target_forward, modify_by_num_players * delta * FOLLOW_SPEED * follow_speed_multiplier)
	else:
		global_transform = global_transform.interpolate_with(cam_base_reverse, modify_by_num_players * delta * FOLLOW_SPEED / follow_speed_multiplier)
		target = target.interpolate_with(target_reverse, modify_by_num_players * delta * FOLLOW_SPEED * follow_speed_multiplier)
	
	if timer_0_5s < 0:
		timer_0_5s = 0.5
		
	look_at(target.origin, Vector3.UP)
	
	
	# Turn a little up or down
	var t = get_transform()
	t.basis = Basis(t.basis[0], deg2rad(angle_v_adjust)) * t.basis
	set_transform(t)
