extends Camera

export var min_distance = 2.0
export var max_distance = 4.0
export var angle_v_adjust = 0.0

var collision_exception = []
export var height = 1.5

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


func _physics_process(_delta):
	var target = get_parent().get_global_transform().origin  # parent is CameraBase pos behind and above the vehicle
	var linear_velocity = get_parent().get_parent().linear_velocity
	var speed = linear_velocity.length()
	var _fwd_mps  = get_parent().get_parent().transform.basis.xform_inv(linear_velocity).z
	# print("fwd_mps) = "+str(fwd_mps))
	# target.z += fwd_mps
	var pos = get_global_transform().origin
	# pos.z -= fwd_mps
	
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
