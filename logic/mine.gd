extends RigidBody


var take_damage = false
# Declare member variables here. 
var timer = 1.0
var bomb_stage = 0  # 0=turned on, 1=inactive waiting for timer to count to 0, 2=active, 3=triggered (car proximity), 4=explode, 5=animation and sound
var print_timer = 0.0
var player_number

# This object acts as different kikds of weapons
enum TYPES {NOT_SET, MINE, BOMB, NUKE}
var type = TYPES.NOT_SET

# explosion force = explosion_strength / (explosion_decrease*distance)+1.0 ^ explosion_exponent)
var explosion_strength = {TYPES.NOT_SET: 0.0, TYPES.MINE: 10000.0, TYPES.BOMB: 10000.0, TYPES.NUKE: 10000.0}
var explosion_range = {TYPES.NOT_SET: 0.0, TYPES.MINE: 10.0, TYPES.BOMB: 10.0, TYPES.NUKE: 1000.0}
var explosion_exponent = {TYPES.NOT_SET: 1.5, TYPES.MINE: 1.5, TYPES.BOMB: 1.5, TYPES.NUKE: 1.05}
var explosion_decrease = {TYPES.NOT_SET: 1.0, TYPES.MINE: 1.0, TYPES.BOMB: 1.0, TYPES.NUKE: 0.05}

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
var hit_on_contact = false


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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	print_timer += delta
	flash_timer -= delta
	bomb_proximity_check_timer -= delta
	bomb_proximity_timer_limit -= delta
	
	if bomb_stage == 1:
		bomb_inactive_timer -= delta
		if bomb_inactive_timer <= 0.0:
			bomb_inactive_timer = BOMB_START_WAIT  # rest for next time
			bomb_stage = 2
			bomb_proximity_timer_limit = 20  # to ensure we don't wait forever, e.g. if the bomb is stuck somewhere it can't be activated
			material_override(material_orange)
		
	if bomb_stage == 2:  # active waiting for proximity to car 
		if bomb_proximity_check_timer <= 0:  # check proximity regularly, not too often
			for player in get_node("/root/TownScene").get_players():  # i in range(1, 5):
				# explosion toward all players
				var carbody = player.get_carbody()  # get_node("../InstancePos"+str(i)+"/VC/V/CarBase/Body")
				var distance = global_transform.origin.distance_to(carbody.global_transform.origin)
				if distance < BOMB_PROXIMITY_DISTANCE or bomb_proximity_timer_limit <= 0:
					bomb_stage = 3  # trigged by proximity to car
					material_override(material_red)
					timer = BOMB_ACTIVE_WAIT
			bomb_proximity_check_timer = BOMB_ACTIVE_WAIT/4.0

	if bomb_stage == 3:  # triggered by car proximity
		timer -= delta
		if timer <= 0.0:
			timer = BOMB_ACTIVE_WAIT
			visible = false
			#	print("  real bomb Body.visible = "+str($Body.visible))'''
			bomb_stage = 4
			if type == TYPES.MINE:
				material_override(material_green)
					
		if timer < BOMB_ACTIVE_WAIT/2.0:
			if flash_timer <= 0.0:
				flash_timer = BOMB_ACTIVE_WAIT/4.0
				if bomb_flash_state == 0:
					if type == TYPES.MINE:
						material_override(material_red)
					bomb_flash_state = 1
				else:
					if type == TYPES.MINE:
						material_override(material_black)
					bomb_flash_state = 0
	
	if bomb_stage == 5:
		if (type == TYPES.MINE and bomb_proximity_timer_limit < 0.0 and no_animations_or_sound_playing()) or (type != TYPES.MINE and no_animations_or_sound_playing()):
			# explosion particles have finished, explosion sound has finished, so disable the bomb
			print("setting bomb_stage = 0")
			bomb_stage = 0
			visible = false
			if bomb_proximity_timer_limit < 0.0:
				print("bomb_proximity_timer_limit < 0.0")


func no_animations_or_sound_playing():
	if $Particles.emitting == true: 
		return false
	if $explosion.playing == true: 
		return false
	if $explosion_nuke.playing == true: 
		return false
	if $nuke_mushroom_cloud.emitting == true: 
		return false
	if $nuke_mushroom_cloud2.emitting == true: 
		return false
	else:
		return true


func get_players():
	return get_node("/root/TownScene").get_players()


func get_bombs():
	return get_node("/root/TownScene").get_players()


func _physics_process(_delta):
	
	if bomb_stage == 4:
		print("bomb_stage == 4")
		hide_meshinstances()
		# $explosion.seek(1.0)
		if type == TYPES.NUKE:
			print("type == TYPES.NUKE")
			$explosion_nuke.playing = true
			$nuke_mushroom_cloud.emitting = true
			$nuke_mushroom_cloud.rotation_degrees = Vector3(0.0, 0.0, 0.0)
			# $nuke_mushroom_cloud.angular_velocity = Vector3(0.0, 0.0, 0.0)
			$nuke_mushroom_cloud2.emitting = true
			$nuke_mushroom_cloud2.rotation_degrees = Vector3(0.0, 0.0, 0.0)
			# $nuke_mushroom_cloud2.angular_velocity = Vector3(0.0, 0.0, 0.0)
		else:
			print("type == "+str(type))
			$explosion.playing = true
			$Particles.global_transform.origin = global_transform.origin
			$Particles.emitting = true
		var targets = []
		for player in get_players():  # i in range(1,5): # explosion toward all players
			var target = player.get_carbody()  # get_node("../InstancePos"+str(i)+"/VC/V/CarBase/Body")
			targets.append(target)
		for bomb in get_bombs():  # i in range(1,5):  # explosion toward all bombs
			# if i != player_number:
			var target = bomb  # get_node("../Bomb"+str(i)+"/Body")
			targets.append(target)
		for target in targets:
			var distance = global_transform.origin.distance_to(target.global_transform.origin)
			#print("target.name="+str(target.name))
			if distance < explosion_range[type] and "CarBody" in target.name:
				var direction = target.transform.origin - transform.origin  
				# direction[2]+=5.0  # slight upward force as well
				var explosion_force = explosion_strength[type]/pow((explosion_decrease[type]*distance)+1.0, explosion_exponent[type])  # inverse square of distance
				if type == TYPES.NUKE and target.player_number == player_number:
					explosion_force = 0.0
				target.apply_impulse( Vector3(0,0,0), explosion_force*direction.normalized() )   # offset, impulse(=direction*force)
				target.angular_velocity  = Vector3(5.0*randf(),5.0*randf(),5.0*randf())
				if target.take_damage == true:
					if type == TYPES.NUKE:
						if target.player_number != player_number:
							target.damage(10)
						# else don't take damage from player that launched it
					else:
						target.damage(2)

		print("setting bomb_stage = 5")
		bomb_stage = 5
		bomb_proximity_check_timer = BOMB_ACTIVE_WAIT *4  # to ensure we don't wait forever


func material_override(material):
	$MineMeshes/Main.material_override = material
	$MineMeshes/Top.material_override = material


func activate(pos, linear_velocity, angular_velocity, stage, _player_number):
	visible = true
	global_transform.origin = pos
	bomb_stage = stage
	timer = BOMB_START_WAIT
	if type == TYPES.MINE:
		material_override(material_green)
	else:
		print("type ="+str(type))
	linear_velocity = linear_velocity
	angular_velocity = angular_velocity
	rotation_degrees = Vector3(0.0, 0.0, 0.0)
	player_number = _player_number


func _on_Bomb_body_entered(_body):
	if hit_on_contact == true and bomb_stage < 4:
		timer = BOMB_ACTIVE_WAIT
		print("mine: _on_Bomb_body_entered(_body):")
		print("body.name="+str(_body.name))
		bomb_stage = 4


func set_as_mine():
	print("set_as_mine()")
	hit_on_contact = false
	mine_meshes(true)
	bomb_meshes(false)
	nuke_meshes(false)
	type = TYPES.MINE


func set_as_bomb():
	print("set_as_bomb()")
	hit_on_contact = true
	mine_meshes(false)
	bomb_meshes(true)
	nuke_meshes(false)
	type = TYPES.BOMB


func set_as_nuke():
	print("set_as_nuke()")
	hit_on_contact = true
	mine_meshes(false)
	bomb_meshes(false)
	nuke_meshes(true)
	type = TYPES.NUKE


func hide_meshinstances():
	print("Hiding all meshinstances in object mine[/bomb/nuke/etc?]")
	mine_meshes(false)
	bomb_meshes(false)
	nuke_meshes(false)


func mine_meshes(_show):
	print("Setting mine meshinstances to "+str(_show))
	$MineMeshes/Main.visible = _show
	$MineMeshes/Top.visible = _show


func bomb_meshes(_show):
	print("Setting bomb meshinstances to "+str(_show))
	$BombMeshes/Body.visible = _show
	$BombMeshes/Fin1.visible = _show
	$BombMeshes/Fin2.visible = _show


func nuke_meshes(_show):
	print("Setting nuke meshinstances to "+str(_show))
	$NukeMeshes/Body.visible = _show
	$NukeMeshes/Fin1.visible = _show
	$NukeMeshes/Fin2.visible = _show
