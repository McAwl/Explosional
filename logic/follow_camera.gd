extends Camera

export var min_distance = 2.0
export var max_distance = 4.0
export var angle_v_adjust = 0.0

var collision_exception = []
export var height = 1.5

var FOLLOW_SPEED = 2.0  # set 0-1: 0.1=slow follow 0.9=fast follow
var lerp_val = 0.5
var target

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


func _physics_process(delta):
	#var target = get_parent().get_global_transform().origin  # parent is CameraBase pos behind and above the vehicle
	var target_forward = get_parent().get_node("CamTargetForward").get_global_transform()
	var target_reverse = get_parent().get_node("CamTargetReverse").get_global_transform()
	var cam_base_forward = get_parent().get_node("CamBaseForward").get_global_transform()
	var cam_base_reverse = get_parent().get_node("CamBaseReverse").get_global_transform()
	
	var linear_velocity = get_parent().get_parent().linear_velocity
	var speed = linear_velocity.length()
	var fwd_mps = get_parent().get_parent().transform.basis.xform_inv(linear_velocity).z
	
	if fwd_mps >= -2.0:
		global_transform = global_transform.interpolate_with(cam_base_forward, delta * FOLLOW_SPEED)
		target = target.interpolate_with(target_forward, delta * FOLLOW_SPEED)
	else:
		global_transform = global_transform.interpolate_with(cam_base_reverse, delta * FOLLOW_SPEED)
		target = target.interpolate_with(target_reverse, delta * FOLLOW_SPEED)
	
	look_at(target.origin, Vector3.UP)
	
	# Turn a little up or down
	var t = get_transform()
	t.basis = Basis(t.basis[0], deg2rad(angle_v_adjust)) * t.basis
	set_transform(t)
