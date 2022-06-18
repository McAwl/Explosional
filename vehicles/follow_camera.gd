extends Camera
class_name FollowCamera

export var min_distance: float = 2.0
export var max_distance: float = 4.0
export var angle_v_adjust: float = 0.0

var collision_exception: Array = []
export var height: float = 1.5

const FOLLOW_SPEED: float = 2.0  # set 0-1: 0.1=slow follow 0.9=fast follow
var lerp_val: float = 0.5
var target
var timer_0_5s: float = 0.5
var number_of_players: int
enum View {THIRD_PERSON=0, FIRST_PERSON=1}
var view: int = View.THIRD_PERSON
var raycast_cam_to_vehicle: RayCast
var raycast_vehicle_to_cam: RayCast
	
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
	
	var cbts: Spatial = get_parent().get_node("CameraBasesTargets")
	var target_forward_third_person: Transform = cbts.get_node("CamTargetForward").get_global_transform()
	var target_reverse_third_person: Transform = cbts.get_node("CamTargetReverse").get_global_transform()
	var cam_base_forward_third_person: Transform = cbts.get_node("CamBaseForward").get_global_transform()
	var cam_base_reverse_third_person: Transform = cbts.get_node("CamBaseReverse").get_global_transform()
	
	var linear_velocity: Vector3 = get_carbody().linear_velocity
	var fwd_mps: float = get_carbody().transform.basis.xform_inv(linear_velocity).z
	var angular_velocity: Vector3 = get_carbody().angular_velocity
	
	if abs(fwd_mps) < 0.5:
		if abs(get_carbody().rotation_degrees[0]) > 90 or abs(get_carbody().rotation_degrees[2]) > 90:
			target_forward_third_person = cbts.get_global_transform()
			target_reverse_third_person = cbts.get_global_transform()
			cam_base_forward_third_person = cbts.get_global_transform()
			cam_base_reverse_third_person = cbts.get_global_transform()

	# when launched by explosion, angular velocity is high and fwd_mps swaps from + to (and is also high)
	# this stops the fast switching in this case - zooms out and stops rotating the camera so fast
	# fix is to follow the target faster, but follow the base more slowly
	var follow_speed_multiplier: float = 1.0 + 0.01*angular_velocity.length()*abs(fwd_mps)
	var modify_by_num_players: float = 1.0 + ((float(number_of_players)-1.0)/2.0)  # keep closer to the vehicle the smaller the viewport is (number of players)
	
	if fwd_mps >= -2.0:  # look-forward config for camera
		global_transform = global_transform.interpolate_with(cam_base_forward_third_person, modify_by_num_players * delta * FOLLOW_SPEED / follow_speed_multiplier)
		target = target.interpolate_with(target_forward_third_person, modify_by_num_players * delta * FOLLOW_SPEED * follow_speed_multiplier)
	else:  # look-backwards config for camera
		global_transform = global_transform.interpolate_with(cam_base_reverse_third_person, modify_by_num_players * delta * FOLLOW_SPEED / follow_speed_multiplier)
		target = target.interpolate_with(target_reverse_third_person, modify_by_num_players * delta * FOLLOW_SPEED * follow_speed_multiplier)
		
	if timer_0_5s < 0:
		if get_carbody().vehicle_state == ConfigVehicles.AliveState.ALIVE:  # else if the car has started exploding leave it at 3rd person for now TODO fix later? 
			var iray
			# check the camera can see the vehicle
			if fwd_mps >= -2.0:
				iray = get_world().direct_space_state.intersect_ray(global_transform.origin, get_carbody_positions().get_node("CamRaycastTargetRear").global_transform.origin)
			else:
				iray = get_world().direct_space_state.intersect_ray(global_transform.origin, get_carbody_positions().get_node("CamRaycastTargetFront").global_transform.origin)
			# print("iray="+str(iray))
			# print("get_parent().get_instance_id()="+str(get_parent().get_parent().get_instance_id()))
			# print("len iray="+str(len(iray)))
			var colliding: bool = false
			if "collider_id" in iray:
				if iray["collider_id"] != get_carbody().get_instance_id():
					# no we can't see the vehicle from the cam, so swap to first-person view
					# TODO also move the third-person camera closer
					colliding = true
					# print("colliding")
					self.visible = false
					self.current = false
					if fwd_mps >= -2.0:
						get_parent().get_node("CameraFPBack").visible = false
						get_parent().get_node("CameraFPBack").current = false
						get_parent().get_node("CameraFPFront").visible = true
						get_parent().get_node("CameraFPFront").global_transform.origin = get_carbody_positions().get_node("FirstPersonViewFront").global_transform.origin
						get_parent().get_node("CameraFPFront").current = true
					else:
						get_parent().get_node("CameraFPBack").visible = true
						get_parent().get_node("CameraFPBack").global_transform.origin = get_carbody_positions().get_node("FirstPersonViewRear").global_transform.origin
						get_parent().get_node("CameraFPBack").current = true
						get_parent().get_node("CameraFPFront").visible = false
						get_parent().get_node("CameraFPFront").current = false
				# else:
				# 	print("colliding with own vehicle body")
			
			if colliding == false:
				# print("no collisions - setting third person cam")
				self.visible = true
				self.current = true
				get_parent().get_node("CameraFPBack").visible = false
				get_parent().get_node("CameraFPBack").current = false
				get_parent().get_node("CameraFPFront").visible = false
				get_parent().get_node("CameraFPFront").current = false
				
		timer_0_5s = 0.5
		
	look_at(target.origin, Vector3.UP)
	
	
	# Turn a little up or down
	var t: Transform = get_transform()
	t.basis = Basis(t.basis[0], deg2rad(angle_v_adjust)) * t.basis
	set_transform(t)