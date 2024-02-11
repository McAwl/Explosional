class_name FollowCamera
extends Camera


enum View {THIRD_PERSON=0, FIRST_PERSON=1}

#const FOLLOW_SPEED: float = 2.0  #2.0  # 2.0 is good, 0.9 is too slow, 5.0 shakes too much and will make you feel sick

# do these do anynthing?
#export var min_distance: float = 1.0 # 2.0 
#export var max_distance: float = 1.5  #4.0
#var follow_speed_mult_min = 1.0  # 2.0 is too slow - the car moves outside cam, 1.0 is good

export var angle_v_adjust: float = 0.0
export var height: float = 1.5

var collision_exception: Array = []
var lerp_val: float = 0.5
var target = null
var timer_0_5s: float = 0.5
var number_of_players: int
var view: int = View.THIRD_PERSON
var raycast_cam_to_vehicle: RayCast
var raycast_vehicle_to_cam: RayCast


# Built-in methods

func _ready():
	Global.debug_print(5, "follow_camera: _ready() global_transform.origin= "+str(self.global_transform.origin), "camera")


func init(_number_of_players, _base_origin, _target_origin):
	Global.debug_print(5, "follow_camera: init() global_transform.origin= "+str(self.global_transform.origin), "camera")
	var node = self
	global_transform.origin = _base_origin
	Global.debug_print(5, "follow_camera: init() recalc: global_transform.origin= "+str(self.global_transform.origin), "camera")
	target = global_transform
	target.origin = _target_origin
	Global.debug_print(5, "follow_camera: init() recalc: target.origin= "+str(self.target.origin), "camera")
	
	while(node):
		if (node is RigidBody):
			collision_exception.append(node.get_rid())
			break
		else:
			#if node is not null:#
			#	Global.debug_print(3, "node = "+node.name)
			if node.name != "Body":
				node = get_node("../../")
			#if node:
			#	Global.debug_print(3, "reparented node = "+node.name)

	# This detaches the camera transform from the parent spatial node.
	set_as_toplevel(true)
	#Global.debug_print(5, "follow_camera: _ready() target.origin starting at position "+str(self.target.origin), "camera")
	#Global.debug_print(5, "follow_camera: init() global_transform.origin starting at global_transform.origin= "+str(self.global_transform.origin), "camera")
	#Global.debug_print(5, "follow_camera: init() parent has global_transform.origin= "+str(get_parent().global_transform.origin), "camera")
	
	number_of_players= _number_of_players
	Global.debug_print(5, "follow_camera:init() completed", "camera")
	

func get_carbody():
	return get_parent().get_parent()



func get_carbody_raycasts():
	return get_parent().get_parent().get_node("Raycasts")


func get_carbody_positions():
	return get_parent().get_parent().get_node("Positions")


func _physics_process(delta):
	
	timer_0_5s -= delta
	
	var cbts: Spatial = get_parent().get_node("CameraBasesTargets")
	
	if cbts == null:
		Global.debug_print(1, "follow_camera: _physics_process(): Warning cbts == null", "camera")
		return
		
	var target_forward_third_person: Transform = cbts.get_node("CamTargetForward").get_global_transform()
	#var target_reverse_third_person: Transform = cbts.get_node("CamTargetReverse").get_global_transform()
	var cam_base_forward_third_person: Transform = cbts.get_node("CamBaseForward").get_global_transform()
	#var cam_base_reverse_third_person: Transform = cbts.get_node("CamBaseReverse").get_global_transform()
	
	if target == null:
		Global.debug_print(1, "follow_camera: _physics_process(): Warning target == null", "camera")
		target = target_forward_third_person
		Global.debug_print(1, "follow_camera: _physics_process(): Reset to CamTargetForward", "camera")
		return
	
	var linear_velocity: Vector3 = get_carbody().linear_velocity
	var fwd_mps: float = get_carbody().transform.basis.xform_inv(linear_velocity).z
	var angular_velocity: Vector3 = get_carbody().angular_velocity
	
	# ?
	#if abs(fwd_mps) < -2.0:
	#	if abs(get_carbody().rotation_degrees[0]) > 90 or abs(get_carbody().rotation_degrees[2]) > 90:
	#		target_forward_third_person = cbts.get_global_transform()
	#		target_reverse_third_person = cbts.get_global_transform()
	#		cam_base_forward_third_person = cbts.get_global_transform()
	#		cam_base_reverse_third_person = cbts.get_global_transform()

	# when launched by explosion, angular velocity is high and fwd_mps swaps from + to (and is also high)
	# this stops the fast switching in this case - zooms out and stops rotating the camera so fast
	# fix is to follow the target faster, but follow the base more slowly
	
	#var follow_speed_multiplier: float = follow_speed_mult_min + follow_speed_mult_min + 0.01*angular_velocity.length()*abs(fwd_mps)
	var angular_velocity_modifier: float = 1.0 + 0.01*angular_velocity.length()*abs(fwd_mps)
	#var modify_by_num_players: float = (float(number_of_players)-1.0)/2.0  # keep closer to the vehicle the smaller the viewport is (number of players)
	
	var interpolate_weight_min = 0.0001  # hold the orig cam position
	var interpolate_weight_max = 0.9999  # track the new cam position
	#var modify_by_speed = pow(abs(fwd_mps/20.0), 1.1)
	
	var interpolate_weight : float
	if fwd_mps >= 50.0:
		interpolate_weight = 10.0*delta
	else:
		interpolate_weight = (5.0 + abs(fwd_mps/10.0)) * delta
	
	"""if fwd_mps >= 50.0:
		interpolate_weight = 10.0*delta
	elif fwd_mps >= 25.0:
		interpolate_weight = 7.5*delta
	elif fwd_mps >= 10.0:
		interpolate_weight = 5.0*delta
	elif fwd_mps >= 0.0:
		interpolate_weight = 5.0*delta 
	elif fwd_mps >= -10.0:
		interpolate_weight = 5.0*delta
	elif fwd_mps >= -25.0:
		interpolate_weight = 7.5*delta
	else:
		interpolate_weight = 10.0*delta"""
	
	interpolate_weight = clamp(interpolate_weight, interpolate_weight_min, interpolate_weight_max)
	
	#if $TimerVehicleCamDelayEnable.is_stopped():
	#if fwd_mps >= -2.0:  # look-forward config for camera
	global_transform = global_transform.interpolate_with(cam_base_forward_third_person, interpolate_weight / angular_velocity_modifier)  # weight 0 (slow) to 1 (fast)
	target = target.interpolate_with(target_forward_third_person, interpolate_weight)  # weight 0 (slow) to 1 (fast)
	#else:  # look-backwards config for camera
	#	global_transform = global_transform.interpolate_with( cam_base_reverse_third_person, 0.01 + modify_by_speed * modify_by_num_players * delta * FOLLOW_SPEED / follow_speed_multiplier)
	#	target = target.interpolate_with(target_reverse_third_person, modify_by_num_players * delta * FOLLOW_SPEED * follow_speed_multiplier)
	#else:
	#	#global_transform = global_transform.interpolate_with( cam_base_forward_third_person, 0.01 + modify_by_speed * modify_by_num_players * delta * FOLLOW_SPEED / follow_speed_multiplier)
	#	#global_transform = cam_base_forward_third_person
	#	global_transform = global_transform.interpolate_with( cam_base_forward_third_person, delta * FOLLOW_SPEED / follow_speed_multiplier)
		
	if timer_0_5s < 0:
		#Global.debug_print(5, "follow_camera: _physics_process(): global_transform="+str(global_transform.origin)+", target="+str(target.origin), "camera")
		if get_carbody().vehicle_state == ConfigVehicles.AliveState.ALIVE:  # else if the car has started exploding leave it at 3rd person for now TODO fix later? 
			var iray
			# check the camera can see the vehicle
			#if fwd_mps >= -2.0:
			iray = get_world().direct_space_state.intersect_ray(global_transform.origin, get_carbody_positions().get_node("CamRaycastTargetRear").global_transform.origin)
			#else:
			#	iray = get_world().direct_space_state.intersect_ray(global_transform.origin, get_carbody_positions().get_node("CamRaycastTargetFront").global_transform.origin)
			#Global.debug_print(3, "iray="+str(iray))
			#Global.debug_print(3, "get_parent().get_instance_id()="+str(get_parent().get_parent().get_instance_id()))
			#Global.debug_print(3, "len iray="+str(len(iray)))
			var colliding: bool = false
			if "collider_id" in iray:
				if iray["collider_id"] != get_carbody().get_instance_id():
					# no we can't see the vehicle from the cam, so swap to first-person view
					# TODO also move the third-person camera closer
					colliding = true
					#Global.debug_print(3, "colliding")
					self.visible = false
					self.current = false
					
					#if fwd_mps >= -2.0:
					get_parent().get_node("CameraFPBack").visible = false
					get_parent().get_node("CameraFPBack").current = false
					get_parent().get_node("CameraFPFront").visible = true
					get_parent().get_node("CameraFPFront").global_transform.origin = get_carbody_positions().get_node("FirstPersonViewFront").global_transform.origin
					get_parent().get_node("CameraFPFront").current = true
					#else:
					#	get_parent().get_node("CameraFPBack").visible = true
					#	get_parent().get_node("CameraFPBack").global_transform.origin = get_carbody_positions().get_node("FirstPersonViewRear").global_transform.origin
					#	get_parent().get_node("CameraFPBack").current = true
					##	get_parent().get_node("CameraFPFront").current = false
				#else:
				#Global.debug_print(3, "colliding with own vehicle body")
			
			if colliding == false:
				#Global.debug_print(3, "no collisions - setting third person cam")
				#if $TimerVehicleCamDelayEnable.is_stopped():
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


func _on_TimerVehicleCamDelayEnable_timeout():
	#get_node("/root/MainScene/VC/CL/MainMenu/MainSelection").hide()
	#get_node("/root/MainScene/VC/CL/MainMenu/LoadingText").hide()
	pass # Replace with function body.
