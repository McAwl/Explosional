extends Spatial


# Declare member variables here. 
var timer = 5.0
var bomb_stage = 0  # 0=inactive, 1=active, 2=explode, 3=animation and sound
var print_timer = 0.0
var player_number
const EXPLOSION_STRENGTH = 200.0  #200.0
const EXPLOSION_RANGE = 10.0  #200.0
var rng = RandomNumberGenerator.new()
var explode = false
var flash_timer = 0.25
var material_default
var material_about_to_explode


# Called when the node enters the scene tree for the first time.
func _ready():
	material_default = SpatialMaterial.new() #Make a new Spatial Material
	material_default.albedo_color = Color(1.0, 1.0, 1.0, 1.0) #Set color of new material
	material_about_to_explode = SpatialMaterial.new() #Make a new Spatial Material
	material_about_to_explode.albedo_color = Color(1.0, 0.0, 0.0, 1.0) #Set color of new material


func _physics_process(_delta):
	if bomb_stage == 2:
		$explosion.playing = true
		# $explosion.seek(1.0)
		$Particles.global_transform.origin = $Body.global_transform.origin
		$Particles.emitting = true
		for i in range(1,5):
			# explosion toward all players
			var node = get_node("../InstancePos"+str(i)+"/VC/V/CarBase/Body")
			print("node = "+str(node.get_path()))
			#var direction = Vector3(0.0, 1.0, 0.0, 0.0)  #up?
			print("  real_bomb.global_transform.origin = "+ str( global_transform.origin ) )
			print("  node.global_transform.origin = "+ str( node.global_transform.origin ) )
			var direction = node.transform.origin - transform.origin
			print("  direction = "+ str( direction ) )
			#direction = Vector3(direction[0], direction[1], direction[2])
			#print("  direction = "+ str( direction ) )
			var distance = $Body.global_transform.origin.distance_to(node.global_transform.origin)
			print("  distance = "+ str( distance ) )
			
			var explosion_force = EXPLOSION_STRENGTH/pow(distance+1.0,2.0)
			if explosion_force>5:
				explosion_force=5.0
			print("  explosion_force = "+ str( explosion_force ) )
			node.apply_impulse( direction, Vector3(0.0, explosion_force, 0.0))
		bomb_stage = 3


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	print_timer += delta
	flash_timer -= delta
	
	if material_default == null:
		material_default = $Body.get_node("MeshInstance").material[0]
	
	if print_timer > 1.0:
		if player_number != null:
			if player_number == 1:
				print("player_number = "+str(player_number))
				print("  real bomb timer = "+str(timer))
				print("  real bomb_stage = "+str(bomb_stage))
				print("  real bomb visible = "+str(visible))
		print_timer = 0.0
		
	if bomb_stage == 1:
		timer -= delta
		if timer <= 0.0:
			timer = 5.0
			$Body.visible = false
			if player_number == 1:
				print("player_number = "+str(player_number))
				print("  explode")
				print("  real_bomb.global_transform.origin = "+ str( global_transform.origin ) )
				print("  real bomb Body.visible = "+str($Body.visible))
			bomb_stage = 2
			$Body.get_node("MeshInstance").material_override = material_default
					
		if timer < 2.5 and flash_timer >= 0.0:
			#$Body.visible = !$Body.visible
			if $Body.visible:
				if $Body.get_node("MeshInstance").material[0] == material_about_to_explode:
					$Body.get_node("MeshInstance").material_override = material_default 
				else:
					$Body.get_node("MeshInstance").material_override = material_about_to_explode 
			flash_timer = 0.25
	
	if bomb_stage == 3:
		if $Particles.emitting == false and $explosion.playing == false:
			# explosion particles have finished, explosion sound has finished, so disable the bomb
			#visible = false #true
			#explode = false
			bomb_stage = 0
			$Body.visible = false
		#else:
		#	print("explosion sound + particles")
