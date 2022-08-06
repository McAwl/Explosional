class_name ExplodedVehiclePart
extends RigidBody


var max_lifetime: float = 60.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var igf: bool = false
var fp: bool = false


# Built-in methods

func _ready():
	# make the flames come from a small volume
	$Flames3D.emission_box_extents(Vector3(0.2, 0.2, 0.2))
	$TimerMaxLifetime.wait_time = rng.randf()*max_lifetime


#func _integrate_forces(_state):
#	#debug
#	if igf == true:
#		if global_transform.origin.y < -10.0:
#			Global.debug_print(3, "ExplodedVehiclePart: "+str(name)+"resetting y pos and velocity", "exploding parts")
#			Global.debug_print(3, "ExplodedVehiclePart: "+str(name)+"was global_transform.origin="+str(global_transform.origin), "exploding parts")
#			global_transform.origin.y = 10.0
#			linear_velocity.y = 0.0
#		igf = false


# Signalmethods

func _on_TimerMaxLifetime_timeout():
	Global.debug_print(3, "ExplodedVehiclePart: "+str(name)+" reached max lifetime. part name="+str(name)+": queue_free", "exploding parts")
	queue_free()


func _on_TimerCheckDestroy_timeout():
	#Global.debug_print(3, "ExplodedVehiclePart: "+str(name)+" global_transform.origin="+str(global_transform.origin), "exploding parts")
	# periodically adjust the smoke - reduce
	if has_node("SmokeTrail") and rng.randf_range(0, 1.0) > ($TimerCheckDestroy.wait_time/$TimerMaxLifetime.wait_time):
		if get_node("SmokeTrail").amount > 1:
			get_node("SmokeTrail").amount -= 1
			get_node("SmokeTrail").emitting = true
		else:
			get_node("SmokeTrail").emitting = false

	if has_node("Flames3D") and rng.randf_range(0, 1.0) > ($TimerCheckDestroy.wait_time/$TimerMaxLifetime.wait_time):
		if get_node("Flames3D").amount > 1:
			get_node("Flames3D").amount -= 1
			get_node("Flames3D").emitting = true
		else:
			get_node("Flames3D").emitting = false

	# periodically check and randomly destroy the part
	#if rng.randf_range(0, 1.0) > ($TimerCheckDestroy.wait_time/$TimerMaxLifetime.wait_time):
	#	Global.debug_print(3, "av_lifetime_sec: part name="+str(name)+": queue_free", "exploding parts")
	#	queue_free()
	
	igf = true
	fp = true

