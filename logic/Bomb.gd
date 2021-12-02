extends Spatial


# Declare member variables here. 
var timer = 1.0
var bomb_stage = 0  # 0=turned on, 1=inactive waiting for timer to count to 0, 2=active, 3=triggered (car proximity), 4=explode, 5=animation and sound
var print_timer = 0.0
var player_number
const EXPLOSION_STRENGTH = 10000.0  #200.0
const EXPLOSION_RANGE = 10.0  #200.0
const BOMB_START_WAIT = 3.0  # wait time when first turned on to activation
const BOMB_ACTIVE_WAIT = 1.0
const BOMB_PROXIMITY_DISTANCE = 5.0
var rng = RandomNumberGenerator.new()
var explode = false
const FLASH_TIMER_WAIT = 0.25
var bomb_proximity_check_timer = 1.0
var bomb_proximity_timer_limit = 20
var bomb_inactive_timer = 1.0
var material_green
var material_red
var material_orange
var material_black
var bomb_flash_state = 0
var flash_timer = 0.25
var take_damage = false

# Called when the node enters the scene tree for the first time.
func _ready():
	material_green = SpatialMaterial.new() #Make a new Spatial Material
	material_green.albedo_color = Color(0.0, 1.0, 0.0, 1.0) #Set color of new material
	material_red = SpatialMaterial.new() #Make a new Spatial Material
	material_red.albedo_color = Color(1.0, 0.0, 0.0, 1.0) #Set color of new material
	material_orange = SpatialMaterial.new()
	material_orange.albedo_color = Color(1.0, 0.5, 0.0, 1.0) #Set color of new material
	material_black = SpatialMaterial.new() #Make a new Spatial Material
	material_black.albedo_color = Color(0.0, 0.0, 0.0, 0.0) #Set color of new material
	# $Body.visible = false

func _physics_process(_delta):
	if bomb_stage == 4:
		$explosion.playing = true
		# $explosion.seek(1.0)
		$Particles.global_transform.origin = $Body.global_transform.origin
		$Particles.emitting = true
		var targets = []
		for i in range(1,5): # explosion toward all players
			var target = get_node("../InstancePos"+str(i)+"/VC/V/CarBase/Body")
			targets.append(target)
		for i in range(1,5):  # explosion toward all bombs
			if i != player_number:
				var target = get_node("../Bomb"+str(i)+"/Body")
				targets.append(target)
		for target in targets:
			var distance = $Body.global_transform.origin.distance_to(target.global_transform.origin)
			if distance < EXPLOSION_RANGE:
				var direction = target.transform.origin - $Body.transform.origin  
				# direction[2]+=5.0  # slight upward force as well
				var explosion_force = EXPLOSION_STRENGTH/pow(distance+1.0, 1.5)  # inverse square of distance
				target.apply_impulse( Vector3(0,0,0), explosion_force*direction.normalized() )   # offset, impulse(=direction*force)
				if target.take_damage == true:
					target.total_damage += explosion_force/10000
					if target.get_node("Particles").process_material.get_param(ParticlesMaterial.PARAM_SCALE) < 0.25:
						target.get_node("Particles").process_material.set_param(ParticlesMaterial.PARAM_SCALE, target.total_damage)
					print("target.total_damage="+str(target.total_damage))
					print("target.get_node('Particles').process_material.get_param(ParticlesMaterial.PARAM_SCALE)="+str(target.get_node("Particles").process_material.get_param(ParticlesMaterial.PARAM_SCALE)))
				print("bomb explosion_force="+str(explosion_force))
					
		bomb_stage = 5
		bomb_proximity_check_timer = BOMB_ACTIVE_WAIT *4  # to ensure we don't wait forever



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	print_timer += delta
	flash_timer -= delta
	bomb_proximity_check_timer -= delta
	bomb_proximity_timer_limit -= delta
	
	#if material_green == null:
	#	material_green = $Body.get_node("MeshInstance").material[0]
	#	#material_green = $Body.get_node("MeshInstance2").material[0]
	
	#if print_timer > 1.0:
	#		if player_number != null:
	#		if player_number == 1:
	#			print("player_number = "+str(player_number))
	#			print("  real bomb timer = "+str(timer))
	#			print("  real bomb bomb_proximity_timer_limit = "+str(bomb_proximity_timer_limit))
	#			print("  real bomb_stage = "+str(bomb_stage))
	#			print("  real bomb visible = "+str(visible))
	#			print("  $Particles.emitting = "+str($Particles.emitting))  
	#			print("  $explosion.playing = "+str($explosion.playing))
	#	print_timer = 0.0
	
	if bomb_stage == 1:
		bomb_inactive_timer -= delta
		if bomb_inactive_timer <= 0.0:
			bomb_inactive_timer = BOMB_START_WAIT  # rest for next time
			bomb_stage = 2
			bomb_proximity_timer_limit = 20  # to ensure we don't wait forever, e.g. if the bomb is stuck somewhere it can't be activated
			material_override(material_orange)
		
	if bomb_stage == 2:  # active waiting for proximity to car 
		if bomb_proximity_check_timer <= 0:  # check proximity regularly, not too often
			for i in range(1,5):
				# explosion toward all players
				var carbase_body = get_node("../InstancePos"+str(i)+"/VC/V/CarBase/Body")
				var distance = $Body.global_transform.origin.distance_to(carbase_body.global_transform.origin)
				if distance < BOMB_PROXIMITY_DISTANCE or bomb_proximity_timer_limit <= 0:
					bomb_stage = 3  # trigged by proximity to car
					material_override(material_red)
					timer = BOMB_ACTIVE_WAIT
			bomb_proximity_check_timer = BOMB_ACTIVE_WAIT/4.0

	if bomb_stage == 3:  # triggered by car proximity
		timer -= delta
		if timer <= 0.0:
			timer = BOMB_ACTIVE_WAIT
			$Body.visible = false
			#	print("  real bomb Body.visible = "+str($Body.visible))'''
			bomb_stage = 4
			material_override(material_green)
					
		if timer < BOMB_ACTIVE_WAIT/2.0:
			if flash_timer <= 0.0:
				flash_timer = BOMB_ACTIVE_WAIT/4.0
				if bomb_flash_state == 0:
					material_override(material_red)
					bomb_flash_state = 1
				else:
					material_override(material_black)
					bomb_flash_state = 0
	
	if bomb_stage == 5:
		if  bomb_proximity_timer_limit < 0.0 or ($Particles.emitting == false and $explosion.playing == false):
			# explosion particles have finished, explosion sound has finished, so disable the bomb
			bomb_stage = 0
			$Body.visible = false


func material_override(material):
	$Body.get_node("MeshInstance").material_override = material
	$Body.get_node("MeshInstance2").material_override = material


func activate(pos, linear_velocity, angular_velocity):
	$Body.visible = true
	$Body.global_transform.origin = pos  # $Body/MinePosition.global_transform.origin
	bomb_stage = 1
	timer = BOMB_START_WAIT
	material_override(material_green)
	$Body.linear_velocity = linear_velocity
	$Body.angular_velocity = angular_velocity
	$Body.rotation_degrees = Vector3(0.0, 0.0, 0.0)
