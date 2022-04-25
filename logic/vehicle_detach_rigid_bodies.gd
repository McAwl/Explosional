extends Spatial

# This script gets attached to an instance of a vehicle mesh instance scene

var apply_forces = false
var force = 0.1
var total_mass = 40.0
var linear_velocity
var max_lifetime_sec = 60  # sec
var rng = RandomNumberGenerator.new()
var global_transform_origin_parent

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func _process(delta):
	
	max_lifetime_sec -= delta
	if max_lifetime_sec <= 0.0:
		print("max_lifetime_sec <= 0.0: vehicle mesh queue_free")
		queue_free()


func av_lifetime(_av_lifetime_sec):
	pass  # av_lifetime_sec


func detach_rigid_bodies(force_, total_mass_, _linear_velocity, _global_transform_origin_parent):
	force = force_
	total_mass = total_mass_
	linear_velocity = _linear_velocity
	global_transform_origin_parent = _global_transform_origin_parent
	apply_forces = true  # one time only impulse
	print("detach_rigid_bodies")


func _physics_process(_delta):

	if apply_forces == true:
		print("_physics_process: apply_forces = true")
		print("force = "+str(force))
		# var num_meshes = 0
		var total_volume = 0
		for ch in get_children():
			if ch is MeshInstance:
				var mesh_volume = ch.get_aabb().get_area ()
				total_volume += mesh_volume
				# print("ch.get_aabb()= "+str(ch.get_aabb())+" mesh_volume = "+str(ch.name)+"="+str(mesh_volume))
		#print("total_volume="+str(total_volume))
		#print("num_meshes="+str(num_meshes))
		for ch in get_children():
			if ch is MeshInstance:
				ch.visible = true  # some meshes start off invisible
				ch.translation = Vector3(0.0, 0.0, 0.0)  # start them all at 0,0,0?
				# ch.scale = scale*ch.scale  # mesh_instances is scaled, as are some meshes within - so need to apply both
				var mesh_volume = ch.get_aabb().get_area ()
				var aabb_size = ch.get_aabb().size
				var aabb_position = ch.get_aabb().position
				var aabb_end = ch.get_aabb().end
				# print("type of mesh piece "+str(ch.type))
				# var new_exploded_vehicle_part = load("res://scenes/car_rigid_body_part.tscn").instance()
				# var new_exploded_vehicle_part = RigidBody.new()
				var new_exploded_vehicle_part = load("res://scenes/exploded_vehicle_part.tscn").instance()
				new_exploded_vehicle_part.set_lifetime(max_lifetime_sec)
				new_exploded_vehicle_part.get_node("smoke_trail").emitting = true
				#new_exploded_vehicle_part.get_node("CollisionShape").translation = self.get_node("mesh_instances").translation
				#new_exploded_vehicle_part.translation = self.get_node("mesh_instances").translation
				# new_exploded_vehicle_part.translation = ch.translation
				# new_exploded_vehicle_part.get_node("CollisionShape").scale = self.get_node("mesh_instances").scale
				self.add_child(new_exploded_vehicle_part)
				new_exploded_vehicle_part.name = "RigidBody_"+ch.name
				# var mesh_centre = (aabb_position + aabb_size) / 2.0
				var mesh_centre = (aabb_position + aabb_end) / 2.0
				
				# new_exploded_vehicle_part.get_node("CollisionShape").translation = aabb_end
				new_exploded_vehicle_part.get_node("CollisionShape").scale = ch.scale * aabb_size  # 
				# do in this order? some meshinstance are -1,-1,-1 scale for some reason. Think it's a Blender invert normals thing
				new_exploded_vehicle_part.get_node("CollisionShape").translation = mesh_centre  # add a rigid body at the centre of the mesh
				  
				if mesh_volume <= 0.0 or total_mass <= 0.0:
					new_exploded_vehicle_part.mass = 1.0
				else:
					new_exploded_vehicle_part.mass = total_mass * (mesh_volume/total_volume)  # mass_per_piece
				#print("new_exploded_vehicle_part.mass="+str(new_exploded_vehicle_part.mass))
				remove_child(ch)
				new_exploded_vehicle_part.add_child(ch)
				new_exploded_vehicle_part.set_as_toplevel(true)
				new_exploded_vehicle_part.global_transform.origin = global_transform_origin_parent  # ch.global_transform.origin
				# new_exploded_vehicle_part.global_transform.origin.y += 1.0
				new_exploded_vehicle_part.linear_velocity = linear_velocity
				if ch.name == "chrome003":
					print("before new_exploded_vehicle_part.linear_velocity="+str(new_exploded_vehicle_part.linear_velocity))
				# any rigid body moving downwards, replace with upwards movement
				if new_exploded_vehicle_part.linear_velocity.y < 1.0:
					if new_exploded_vehicle_part.linear_velocity.y < 0.0:
						new_exploded_vehicle_part.linear_velocity.y = -new_exploded_vehicle_part.linear_velocity.y
					else:
						new_exploded_vehicle_part.linear_velocity.y = 1.0
				if ch.name == "chrome003":
					print("after new_exploded_vehicle_part.linear_velocity="+str(new_exploded_vehicle_part.linear_velocity))
				# var collision = ch.get_node("CollisionShape")
				#$var shape = BoxShape.new()
				#var ch_aabb_size = ch.get_aabb().size
				# shape.set_extents(ch_aabb_size)
				#var collision_shape = CollisionShape.new()
				#collision_shape.set_shape(shape)
				# collision.disabled = false
				# ch.remove_child(collision)
				# new_exploded_vehicle_part.add_child(collision_shape)
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
				#	new_exploded_vehicle_part.add_child(collision)
				#else:
				#	print("Error: collision null or staticbody null")
					
				#staticbody.queue_free() # use this if using .create_convex_collision ( )
				#var direction = Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(-1, -2), rng.randf_range(-0.1, 0.1))
				var direction = Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(0.0, 0.2), rng.randf_range(-0.1, 0.1))  # Vector3(0.0, 1.0, 0.0)=up
				var force_origin = Vector3(0, -20.0, 0)
				# new_exploded_vehicle_part.apply_impulse( force_origin, force*(direction.normalized()) )
			else:
				ch.queue_free()  # if not a MeshInstance, delete everything but meshes
		apply_forces = false

