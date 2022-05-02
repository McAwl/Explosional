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
var view = 0  # 0=third person, 1=first-person
var raycast_cam_to_vehicle
var raycast_vehicle_to_cam
	
func _ready():
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


func get_carbody_raycasts():
	return get_parent().get_parent().get_node("Raycasts")


func get_carbody_positions():
	return get_parent().get_parent().get_node("Positions")


func _physics_process(delta):
	
	timer_0_5s -= delta
	
	var cbts = get_parent().get_node("CameraBasesTargets")
	var target_forward_third_person = cbts.get_node("CamTargetForward").get_global_transform()
	var target_reverse_third_person = cbts.get_node("CamTargetReverse").get_global_transform()
	var cam_base_forward_third_person = cbts.get_node("CamBaseForward").get_global_transform()
	# var cam_base_forward2 = get_parent().get_node("CamBaseForward2").get_global_transform()
	var cam_base_reverse_third_person = cbts.get_node("CamBaseReverse").get_global_transform()
	
	var linear_velocity = get_parent().get_parent().linear_velocity
	var fwd_mps = get_parent().get_parent().transform.basis.xform_inv(linear_velocity).z
	var angular_velocity = get_parent().get_parent().angular_velocity
	
	if abs(fwd_mps) < 0.5:
		if abs(get_carbody().rotation_degrees[0]) > 90 or abs(get_carbody().rotation_degrees[2]) > 90:
			target_forward_third_person = cbts.get_global_transform()
			target_reverse_third_person = cbts.get_global_transform()
			cam_base_forward_third_person = cbts.get_global_transform()
			cam_base_reverse_third_person = cbts.get_global_transform()

	# when launched by explosion, angular velocity is high and fwd_mps swaps from + to (and is also high)
	# this stops the fast switching in this case - zooms out and stops rotating the camera so fast
	# fix is to follow the target faster, but follow the base more slowly
	var follow_speed_multiplier = 1.0 + 0.01*angular_velocity.length()*abs(fwd_mps)
	var modify_by_num_players = 1.0 + ((float(number_of_players)-1.0)/2.0)  # keep closer to the vehicle the smaller the viewport is (number of players)
	
		
	if fwd_mps >= -2.0:  # look-forward config for camera
		# move the camera raycast to the origin to the camera
		var rcs = get_carbody_raycasts()
		var cbps = get_carbody_positions()
		raycast_cam_to_vehicle = rcs.get_node("RayCastCamToVehicle")
		raycast_vehicle_to_cam = rcs.get_node("RayCastVehicleToCam")
		raycast_cam_to_vehicle.global_transform.origin = self.global_transform.origin  # origin at the camera
		raycast_vehicle_to_cam.global_transform.origin = (cbps.get_node("CamRaycastTargetRear")).global_transform.origin  # origin at the vehicle
		# raycast_cam_to_vehicle.cast_to = raycast_vehicle_to_cam.global_transform.origin - raycast_cam_to_vehicle.global_transform.origin
		# raycast_vehicle_to_cam.cast_to = raycast_cam_to_vehicle.global_transform.origin - raycast_vehicle_to_cam.global_transform.origin
		# raycast_cam_to_vehicle.look_at(raycast_vehicle_to_cam)
		# raycast_cam_to_vehicle.force_raycast_update()
		# raycast_vehicle_to_cam.rotation_degrees = Vector3(0,0,0)
		# raycast_vehicle_to_cam.force_raycast_update()
		# raycast_vehicle_to_cam.look_at(raycast_cam_to_vehicle)
		# var r: Raycast = someRaycast
		# var rGlobalOrigin = r.to_global(Vector3.ZERO) # or r.global_transform.origin
		# var rGlobalCastToEndpoint = r.to_global(r.cast_to) # or r.global_transform * r.cast_to # or r.global_transform.xform(r.cast_to)
		# var rGlobalCastToVector = rGlobalCastToEndPoint - rGlobalOrigin
		# raycast_cam_to_vehicle.ro.look_at(get_carbody_positions().get_node("CamRaycastTargetRear"))  # local to local cast to the appropriate position on the mesh
		# raycast_cam_to_vehicle.global_transform.xform(cbps.get_node("CamRaycastTargetRear").transform)
		# raycast_vehicle_to_cam.global_transform.xform(self.transform)
		global_transform = global_transform.interpolate_with(cam_base_forward_third_person, modify_by_num_players * delta * FOLLOW_SPEED / follow_speed_multiplier)
		target = target.interpolate_with(target_forward_third_person, modify_by_num_players * delta * FOLLOW_SPEED * follow_speed_multiplier)
	else:  # look-backwards config for camera
		global_transform = global_transform.interpolate_with(cam_base_reverse_third_person, modify_by_num_players * delta * FOLLOW_SPEED / follow_speed_multiplier)
		target = target.interpolate_with(target_reverse_third_person, modify_by_num_players * delta * FOLLOW_SPEED * follow_speed_multiplier)
		
	if timer_0_5s < 0:
		if raycast_cam_to_vehicle.is_colliding() or raycast_vehicle_to_cam.is_colliding():
			print("colliding")
			self.visible = false
			self.current = false
			if fwd_mps >= -2.0:
				get_parent().get_node("CameraFPBack").visible = false
				get_parent().get_node("CameraFPBack").current = false
				get_parent().get_node("CameraFPFront").visible = true
				get_parent().get_node("CameraFPFront").global_transform.origin = get_carbody_positions().get_node("CamRaycastTargetFront").global_transform.origin
				get_parent().get_node("CameraFPFront").current = true
			else:
				get_parent().get_node("CameraFPBack").visible = true
				get_parent().get_node("CameraFPBack").global_transform.origin = get_carbody_positions().get_node("CamRaycastTargetRear").global_transform.origin
				get_parent().get_node("CameraFPBack").current = true
				get_parent().get_node("CameraFPFront").visible = false
				get_parent().get_node("CameraFPFront").current = false
		else:
			print("no collisions - setting third person cam")
			self.visible = true
			self.current = true
			get_parent().get_node("CameraFPBack").visible = false
			get_parent().get_node("CameraFPBack").current = false
			get_parent().get_node("CameraFPFront").visible = false
			get_parent().get_node("CameraFPFront").current = false
		timer_0_5s = 0.5
		
	look_at(target.origin, Vector3.UP)
	
	
	# Turn a little up or down
	var t = get_transform()
	t.basis = Basis(t.basis[0], deg2rad(angle_v_adjust)) * t.basis
	set_transform(t)
