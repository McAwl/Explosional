extends Spatial


var apply_forces = false
var rng = RandomNumberGenerator.new()
var force = 0.1
var total_mass = 40.0
var timer = 60  # sec


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func _process(delta):
	timer -= delta
	if timer <= 0.0:
		queue_free()


func detach_rigid_bodies(force_, total_mass_):
	force = force_
	total_mass = total_mass_
	apply_forces = true
	#print("detach_rigid_bodies")


func _physics_process(_delta):
	#print("_physics_process")
	if apply_forces == true:
		# var num_meshes = 0
		var total_volume = 0
		for ch in self.get_children():
			if ch is MeshInstance:
				var mesh_volume = ch.get_aabb().get_area ()
				total_volume += mesh_volume
				#print("mesh_volume = "+str(ch.name)+"="+str(mesh_volume))
				# num_meshes += 1
		#print("total_volume="+str(total_volume))
		#print("num_meshes="+str(num_meshes))
		var parent_linear_velocity = get_parent().linear_velocity
		for ch in self.get_children():
			if ch is MeshInstance:
				ch.visible = true
				# print("type of mesh piece "+str(ch.type))
				# var new_rigid_body = load("res://scenes/car_rigid_body_part.tscn").instance()
				var new_rigid_body = RigidBody.new()
				self.add_child(new_rigid_body)
				new_rigid_body.name = "RigidBody_"+ch.name
				var mesh_volume = ch.get_aabb().get_area ()
				new_rigid_body.mass = total_mass * (mesh_volume/total_volume)  # mass_per_piece
				#print("new_rigid_body.mass="+str(new_rigid_body.mass))
				self.remove_child(ch)
				new_rigid_body.add_child(ch)
				new_rigid_body.set_as_toplevel(true)
				new_rigid_body.linear_velocity = parent_linear_velocity
			
				ch.create_convex_collision ( )  # "creates a StaticBody child node with a ConvexPolygonShape collision shape calculated from the mesh geometry" 
				# ch.create_trimesh_collision ( ) # TODO 
				var collision = null
				var staticbody = null 
				for mesh_child in ch.get_children():
					if mesh_child is StaticBody:
						staticbody = mesh_child
						#print("  mesh_child staticbody="+str(staticbody.name))
						for staticbody_child in mesh_child.get_children():
							if staticbody_child is CollisionShape:  # ConvexPolygonShape:
								collision = staticbody_child
								#print("    staticbody_child collision="+str(collision.name))
								
				if collision != null and staticbody != null:
					staticbody.remove_child(collision)
					print("staticbody ch = "+str(staticbody.get_children()))
					new_rigid_body.add_child(collision)
					#print("new_rigid_body ch = "+str(new_rigid_body.get_children()))
				else:
					print("Error: collision null or staticbody null")
					
				staticbody.queue_free()
				var direction = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1),rng.randf_range(-1, 1))
				new_rigid_body.apply_impulse( Vector3(0,0,0),  force*direction.normalized() )
		apply_forces = false
