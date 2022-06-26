extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$SignRestoreDamage.rotation_degrees.y += delta*30.0


func vehicle_in_area() -> bool:
	if len(get_overlapping_bodies())>0.0:
		#print("get_overlapping_bodies()>0.0")
		for ob in get_overlapping_bodies():
			#print("ob.name="+str(ob.name))
			if ob is VehicleBody:
				return true
	return false


func _on_TimerCheckInsideWorkshop_timeout():
	if len(get_overlapping_bodies())>0.0:
		#print("get_overlapping_bodies()>0.0")
		for ob in get_overlapping_bodies():
			#print("ob.name="+str(ob.name))
			if ob is VehicleBody:
				#print("Found VehicleBody. Current total_damage="+str(ob.total_damage))
				#print("total_damage="+str(ob.total_damage)+". Restoring health...")
				if ob.total_damage > 0:
					ob.restore_health(1) 
					$ActivationSound.play()
					#print("  Done. Now total_damage="+str(ob.total_damage))



func _on_TimerFlashAreaIfVehicleInArea_timeout():
	if vehicle_in_area():
		$AreaVolume.visible = !$AreaVolume.visible
	else:
		$AreaVolume.show()

