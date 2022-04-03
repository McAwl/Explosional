extends Spatial


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func detach_rigid_bodies(force):

	# var explosion_force = 1.0  # Vector3.ZERO
	# var direction = Vector3.UP
	
	for ch in self.get_children():
		var new_rigid_body = load("res://scenes/car_rigid_body_part.tscn").instance()
		self.add_child(new_rigid_body)
		new_rigid_body.name = "RigidBody_"+ch.name
		self.remove_child(ch)
		new_rigid_body.add_child(ch)
		new_rigid_body.set_as_toplevel(true)
		new_rigid_body.linear_velocity = get_parent().linear_velocity
		# new_rigid_body.apply_impulse( Vector3(0,0,0), Vector3(0,0,0).normalized() )
		new_rigid_body.apply_impulse( Vector3(0,0,0), Vector3(force,force,force) )
