extends Spatial


var apply_forces = false
var rng = RandomNumberGenerator.new()
var force = 0.1
var total_mass = 40.0
var linear_velocity
var lifetime_sec = 120  # sec
var origin


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func _process(delta):
	lifetime_sec -= delta
	if lifetime_sec <= 0.0:
		print("vehicle mesh queue_free")
		queue_free()


func detach_rigid_bodies(force_, total_mass_, _linear_velocity, _origin):
	force = force_
	total_mass = total_mass_
	linear_velocity = _linear_velocity
	origin = _origin
	apply_forces = true  # one time only impulse
	print("detach_rigid_bodies")


func _physics_process(_delta):
	if apply_forces == true:
		print("_physics_process: apply_forces = true")
		# var num_meshes = 0
		var total_volume = 0
		for ch in self.get_node("mesh_instances").get_children():
			if ch is MeshInstance:
				var mesh_volume = ch.get_aabb().get_area ()
				total_volume += mesh_volume
				ch.scale = self.get_node("mesh_instances").scale
				# print("ch.get_aabb()= "+str(ch.get_aabb())+" mesh_volume = "+str(ch.name)+"="+str(mesh_volume))
		#print("total_volume="+str(total_volume))
		#print("num_meshes="+str(num_meshes))
		for ch in self.get_node("mesh_instances").get_children():
			if ch is MeshInstance:
				ch.visible = true
				# print("type of mesh piece "+str(ch.type))
				# var new_rigid_body = load("res://scenes/car_rigid_body_part.tscn").instance()
				# var new_rigid_body = RigidBody.new()
				var new_rigid_body = load("res://scenes/rigid_body.tscn").instance()
				#new_rigid_body.get_node("CollisionShape").translation = self.get_node("mesh_instances").translation
				#new_rigid_body.translation = self.get_node("mesh_instances").translation
				# new_rigid_body.translation = ch.translation
				# new_rigid_body.get_node("CollisionShape").scale = self.get_node("mesh_instances").scale
				self.add_child(new_rigid_body)
				new_rigid_body.name = "RigidBody_"+ch.name
				new_rigid_body.get_node("CollisionShape").translation = Vector3(0.0, 0.0, 0.0)
				ch.translation = Vector3(0.0, 0.0, 0.0)
				var mesh_volume = ch.get_aabb().get_area ()
				if mesh_volume <= 0.0 or total_mass <= 0.0:
					new_rigid_body.mass = 1.0
				else:
					new_rigid_body.mass = total_mass * (mesh_volume/total_volume)  # mass_per_piece
				#print("new_rigid_body.mass="+str(new_rigid_body.mass))
				self.get_node("mesh_instances").remove_child(ch)
				new_rigid_body.add_child(ch)
				new_rigid_body.set_as_toplevel(true)
				new_rigid_body.global_transform.origin = origin
				# new_rigid_body.global_transform.origin.y += 1.0
				new_rigid_body.linear_velocity = linear_velocity
				# var collision = ch.get_node("CollisionShape")
				#$var shape = BoxShape.new()
				#var ch_aabb_size = ch.get_aabb().size
				# shape.set_extents(ch_aabb_size)
				#var collision_shape = CollisionShape.new()
				#collision_shape.set_shape(shape)
				# collision.disabled = false
				# ch.remove_child(collision)
				# new_rigid_body.add_child(collision_shape)
				#ch.create_convex_collision ( )  # "creates a StaticBody child node with a ConvexPolygonShape collision shape calculated from the mesh geometry" 
				# ch.create_trimesh_collision ( ) # TODO 
				#var collision = null
				#var staticbody = null 
				# here we remove the staticbody and move the collisionshape up to the rigidbody we've already created
				# for mesh_child in ch.get_children():
				# 	if mesh_child is StaticBody:
				#		staticbody = mesh_child
				#		#print("  mesh_child staticbody="+str(staticbody.name))
				#		for staticbody_child in mesh_child.get_children():
				##				collision = staticbody_child
				#	#			#print("    staticbody_child collision="+str(collision.name))
				#	#			
				#if collision != null and staticbody != null:
				#	staticbody.remove_child(collision)
				#	new_rigid_body.add_child(collision)
				#else:
				#	print("Error: collision null or staticbody null")
					
				#staticbody.queue_free() # use this if using .create_convex_collision ( )
				var direction = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1),rng.randf_range(-1, 1))
				new_rigid_body.apply_impulse( Vector3(0,0,0),  force*direction.normalized() )
				var new_smoke_particles = load("res://scenes/smoke_trail.tscn").instance()
				# get_parent().add_child(new_smoke_particles)
				#new_smoke_particles.global_transform.origin = origin
				new_rigid_body.add_child(new_smoke_particles)
			else:
				ch.queue_free()  # delete everything but meshes
		apply_forces = false
		get_node("positions").queue_free()
		get_node("mesh_instances").queue_free()
