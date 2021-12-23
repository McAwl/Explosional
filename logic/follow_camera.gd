extends Camera

export var min_distance = 2.0
export var max_distance = 4.0
export var angle_v_adjust = 0.0

var collision_exception = []
export var height = 1.5

var follow_speed = 0.01  # set 0-1: 0.1=slow follow 0.9=fast follow
var lerp_val = 0.5

func _ready():
	# environment = get_node("/root/TownScene/Viewport/WorldEnvironment")
	# Find collision exceptions for ray.
	var node = self
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


func _physics_process(delta):
	#var target = get_parent().get_global_transform().origin  # parent is CameraBase pos behind and above the vehicle
	var target_forward = get_parent().get_node("CamTargetForward").get_global_transform().origin
	var target_reverse = get_parent().get_node("CamTargetReverse").get_global_transform().origin
	var cam_base_forward = get_parent().get_node("CamBaseForward").get_global_transform().origin
	var cam_base_reverse = get_parent().get_node("CamBaseReverse").get_global_transform().origin
	
	var linear_velocity = get_parent().get_parent().linear_velocity
	var speed = linear_velocity.length()
	var fwd_mps = 2.0 + get_parent().get_parent().transform.basis.xform_inv(linear_velocity).z
	
	var old_lerp_val = lerp_val
	var new_lerp_val = 0.5 + (fwd_mps/10)
	lerp_val = (follow_speed*new_lerp_val) + ((1.0-follow_speed)*old_lerp_val)
	
	if lerp_val < 0.0:
		lerp_val = 0.0
	elif lerp_val > 1.0:
		lerp_val = 1.0
	#print("fwd_mps) = "+str(fwd_mps))
	#print("lerp_val="+str(lerp_val))
	
	# get_global_transform().position = get_global_transform().position.linear_interpolate(mouse_pos, delta * FOLLOW_SPEED)
	# look_at(target_forward, Vector3.UP)  # move the camera to pos
	
	var target = lerp(target_reverse, target_forward, lerp_val)
	var pos =  lerp(cam_base_reverse, cam_base_forward, lerp_val)
	
	var from_target = pos - target

	# Check ranges.
	if from_target.length() < min_distance:
		from_target = from_target.normalized() * min_distance
	elif from_target.length() > max_distance:
		from_target = from_target.normalized() * max_distance

	from_target.y = height

	pos = target + from_target

	look_at_from_position(pos, target, Vector3.UP)  # move the camera to pos

	# Turn a little up or down
	var t = get_transform()
	t.basis = Basis(t.basis[0], deg2rad(angle_v_adjust)) * t.basis
	set_transform(t)
