extends RigidBody

# A class to represent differnet kinds of explosives:
# 1. A Mine, which explodes when in proximity to a vehicle
# 2. A Bomb, which falls and detonates on contact with anything
# 3. A Nuke, a heavy Bomb

enum TYPES {NOT_SET, MINE, BOMB, NUKE}
var type = TYPES.NOT_SET

var take_damage = false
var timer = 1.0
var explosive_stage = 0  # 0=turned on, 1=inactive waiting for timer to count to 0, 2=active, 3=triggered (car proximity), 4=explode, 5=animation and sound
var timer_1s = 1.0
var launched_by_player_number  # record which player number launched this explosive 
var launched_by_player = null

# explosion force = explosion_strength / (explosion_decrease*distance)+1.0 ^ explosion_exponent)
var explosion_strength = {TYPES.NOT_SET: 0.0, TYPES.MINE: 5000.0, TYPES.BOMB: 5000.0, TYPES.NUKE: 10000.0}
var explosion_range = {TYPES.NOT_SET: 0.0, TYPES.MINE: 10.0, TYPES.BOMB: 10.0, TYPES.NUKE: 1000.0}
var explosion_exponent = {TYPES.NOT_SET: 1.5, TYPES.MINE: 1.5, TYPES.BOMB: 1.5, TYPES.NUKE: 1.05}
var explosion_decrease = {TYPES.NOT_SET: 1.0, TYPES.MINE: 1.0, TYPES.BOMB: 1.0, TYPES.NUKE: 0.05}

const EXPLOSIVE_START_WAIT = 3.0  # wait time when first turned on to activation
const EXPLOSIVE_ACTIVE_WAIT = 1.0
const EXPLOSIVE_PROXIMITY_DISTANCE = 5.0
const FLASH_TIMER_WAIT = 0.25

var rng = RandomNumberGenerator.new()

var explosive_proximity_check_timer = 1.0
var explosive_proximity_timer_limit = 20
var explosive_inactive_timer = 1.0

var material_green
var material_red
var material_orange
var material_black

var explosive_flash_state = 0
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
	$SpotLight.spot_range = 0.0
	$ExplosionNuke/top/OmniLight.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	timer_1s -= delta
	flash_timer -= delta
	explosive_proximity_check_timer -= delta
	explosive_proximity_timer_limit -= delta
	
	# Most of the states can be handled here (state 4: explosion handled in physics method)
	if explosive_stage == 1:
		explosive_inactive_timer -= delta
		if explosive_inactive_timer <= 0.0:
			explosive_inactive_timer = EXPLOSIVE_START_WAIT  # rest for next time
			explosive_stage = 2
			explosive_proximity_timer_limit = 20  # to ensure we don't wait forever, e.g. if the bomb is stuck somewhere it can't be activated
			material_override(material_orange)
		
	if explosive_stage == 2:  # active waiting for proximity to car 
		if explosive_proximity_check_timer <= 0:  # check proximity regularly, not too often
			for player in get_node("/root/TownScene").get_players():  # i in range(1, 5):
				# explosion toward all players
				var carbody = player.get_carbody()  # get_node("../InstancePos"+str(i)+"/VC/V/CarBase/Body")
				var distance = global_transform.origin.distance_to(carbody.global_transform.origin)
				if distance < EXPLOSIVE_PROXIMITY_DISTANCE or explosive_proximity_timer_limit <= 0:
					explosive_stage = 3  # trigged by proximity to car
					material_override(material_red)
					timer = EXPLOSIVE_ACTIVE_WAIT
			explosive_proximity_check_timer = EXPLOSIVE_ACTIVE_WAIT/4.0

	if explosive_stage == 3:  # triggered by car proximity
		timer -= delta
		if timer <= 0.0:
			timer = EXPLOSIVE_ACTIVE_WAIT
			visible = false
			#	print("  real bomb Body.visible = "+str($Body.visible))'''
			explosive_stage = 4
			if type == TYPES.MINE:
				material_override(material_green)
					
		if timer < EXPLOSIVE_ACTIVE_WAIT/2.0:
			if flash_timer <= 0.0:
				flash_timer = EXPLOSIVE_ACTIVE_WAIT/4.0
				if explosive_flash_state == 0:
					if type == TYPES.MINE:
						material_override(material_red)
					explosive_flash_state = 1
				else:
					if type == TYPES.MINE:
						material_override(material_black)
					explosive_flash_state = 0
	
	if explosive_stage == 5:
		if type != TYPES.MINE:
			axis_lock_angular_x = true
			axis_lock_angular_y = true
			axis_lock_angular_z = true
			axis_lock_linear_x = true
			axis_lock_linear_y = true
			axis_lock_linear_z = true
			
		$SpotLight.hide()
		if no_animations_or_sound_playing() or (type == TYPES.MINE and explosive_proximity_timer_limit < 0.0):
			# explosion particles have finished, explosion sound has finished, so disable the bomb
			# print("explosive_stage == 5 no_animations_or_sound_playing() or (type == TYPES.MINE and explosive_proximity_timer_limit < 0.0) or or (type == TYPES.BOMB and explosive_proximity_timer_limit < 0.0)")
			#explosive_stage = 0
			visible = false
			# if explosive_proximity_timer_limit < 0.0:
			#	print("explosive_proximity_timer_limit < 0.0")
			# print("queue_free: "+str(name))
			queue_free()

	if timer_1s < 0.0:
		timer_1s = 1.0
		if $MineMeshes/Main.visible == true:
			$MineMeshes/OmniLight.visible = !$MineMeshes/OmniLight.visible


func no_animations_or_sound_playing():
	# print("explosive_stage ==  "+str(explosive_stage))
	if $ParticlesExplosion.emitting == true: 
		# print("$ParticlesExplosion.emitting == true")
		return false
	if $explosion_sound_mine_bomb.playing == true: 
		# print("$explosion_sound_mine_bomb.playing == true")
		return false
	if $ExplosionNuke/AnimationPlayer.current_animation == "nuke":
		# print("$ExplosionNuke/AnimationPlayer.current_animation == nuke")
		# print(str($ExplosionNuke/AnimationPlayer.current_animation_position))
		return false
	else:
		# print("no_animations_or_sound_playing(): returned true")
		# print("$ExplosionNuke/AnimationPlayer.current_animation="+str($ExplosionNuke/AnimationPlayer.current_animation))
		return true


func get_players():
	return get_node("/root/TownScene").get_players()


func get_bombs():
	return get_node("/root/TownScene").get_players()


func _physics_process(_delta):
	
	if explosive_stage == 4:
		# print("explosive_stage == 4")
		hide_meshinstances()
		if type == TYPES.NUKE:
			# print("_physics_process(): explosive_stage == 4 type == TYPES.NUKE")
			linear_velocity = Vector3(0.0, 0.0, 0.0)
			angular_velocity = Vector3(0.0, 0.0, 0.0)
			rotation_degrees = Vector3(0.0, 0.0, 0.0)
			# print("type == "+str(type))
			$ExplosionNuke/AnimationPlayer.seek(0.0)
			$ExplosionNuke/AnimationPlayer.play("nuke")
			$ExplosionNuke/AnimationPlayer.seek(0.0)
			$ExplosionNuke/explosion_nuke_sound.playing = true
		elif type == TYPES.MINE:
			$ParticlesExplosion.global_transform.origin = global_transform.origin
			# print("type == TYPES.MINE setting $ParticlesExplosion.emitting = true")
			$ParticlesExplosion.emitting = true
			$explosion_sound_mine_bomb.playing = true
		elif type == TYPES.BOMB:
			$explosion_sound_mine_bomb.playing = true
			# print(" type == TYPES.BOMB setting $ParticlesExplosion.emitting = true")
			$ParticlesExplosion.emitting = true
		var targets = []
		for target in get_players():  # i in range(1,5): # explosion toward all players
			var target_body = target.get_carbody()  # get_node("../InstancePos"+str(i)+"/VC/V/CarBase/Body")
			targets.append(target_body)
		for bomb in get_bombs():  # i in range(1,5):  # explosion toward all bombs
			# if i != player_number:
			var target = bomb  # get_node("../Bomb"+str(i)+"/Body")
			targets.append(target)
		for target in targets:
			var distance = global_transform.origin.distance_to(target.global_transform.origin)
			#print("target.name="+str(target.name))
			if distance < explosion_range[type] and "CarBody" in target.name:
				var direction = target.transform.origin - transform.origin  
				# direction[2]+=5.0  # slight upward force as well - isn't [1] up/down?
				# remove downwards force - as vehicles can be blown through the terrain
				if direction[1] < 0:
					direction[1] = 0
				var explosion_force = explosion_strength[type]/pow((explosion_decrease[type]*distance)+1.0, explosion_exponent[type])  # inverse square of distance
				if type == TYPES.NUKE:
					if target.player_number == launched_by_player_number:
						explosion_force = 0.0  # no damage from player which launched the nuke
					else:
						distance = 50.0  # ensure a specific force is experiences by all other players
				target.apply_impulse( Vector3(0,0,0), explosion_force*direction.normalized() )   # offset, impulse(=direction*force)
				target.angular_velocity  = Vector3(5.0*randf(),5.0*randf(),5.0*randf())
				#if target.take_damage == true:
				#	if type == TYPES.NUKE:
				#		if target.player_number != launched_by_player_number:
				#			target.damage(10)
				#			# print("target took nuke damage launched_by_player_number "+str(launched_by_player_number))
				#		# else don't take damage from player that launched it
				#	else:
				#		target.damage(2)
				#		# print("target took damage launched_by_player_number "+str(launched_by_player_number))
				#		# print("direction="+str(direction))
				

		# print("setting explosive_stage = 5")
		explosive_stage = 5
		explosive_proximity_check_timer = EXPLOSIVE_ACTIVE_WAIT *4  # to ensure we don't wait forever

	if explosive_stage == 5:  # stop rotation of bombs/nukes after they hit, otherwise animations rotation/move/etc weirddly
		# linear_velocity = Vector3(0.0, 0.0, 0.0)
		# angular_velocity = Vector3(0.0, 0.0, 0.0)
		rotation_degrees = Vector3(0.0, 0.0, 0.0)


func material_override(material):
	$MineMeshes/Main.material_override = material
	$MineMeshes/Top.material_override = material


func activate(pos, linear_velocity, angular_velocity, stage, _launched_by_player_number, _launched_by_player=null):
	visible = true
	global_transform.origin = pos
	explosive_stage = stage
	timer = EXPLOSIVE_START_WAIT
	if type == TYPES.MINE:
		material_override(material_green)
		linear_velocity = linear_velocity
		angular_velocity = angular_velocity
	else:
		linear_velocity = Vector3(0.0, 0.0, 0.0)
		angular_velocity = Vector3(0.0, 0.0, 0.0)
		rotation_degrees = Vector3(0.0, 0.0, 0.0)
	launched_by_player_number = _launched_by_player_number
	var player_str = ""
	if _launched_by_player != null:
		launched_by_player = _launched_by_player
		player_str = " (player "+str(launched_by_player.player_name)+")"
	print("weapon of type "+str(TYPES.keys()[type]) + " launched by player_number "+str(launched_by_player_number)+player_str)


func _on_Bomb_body_entered(_body):
	if hit_on_contact == true and explosive_stage < 4:
		timer = EXPLOSIVE_ACTIVE_WAIT
		# print("mine: _on_Bomb_body_entered(_body):")
		# print("body.name="+str(_body.name))
		explosive_stage = 4


func set_as_mine():
	# print("set_as_mine()")
	hit_on_contact = false
	mine_meshes(true)
	bomb_meshes(false)
	nuke_meshes(false)
	type = TYPES.MINE
	$SpotLight.hide()


func set_as_bomb():
	# print("set_as_bomb()")
	hit_on_contact = true
	mine_meshes(false)
	bomb_meshes(true)
	nuke_meshes(false)
	type = TYPES.BOMB
	$SpotLight.show()
	$SpotLight.spot_range = 150


func set_as_nuke():
	# print("set_as_nuke()")
	hit_on_contact = true
	mine_meshes(false)
	bomb_meshes(false)
	nuke_meshes(true)
	type = TYPES.NUKE
	$SpotLight.show()
	$SpotLight.spot_range = 150.0
	$ExplosionNuke/AnimationPlayer.stop(true)



func hide_meshinstances():
	# print("Hiding all meshinstances in object mine[/bomb/nuke/etc?]")
	mine_meshes(false)
	bomb_meshes(false)
	nuke_meshes(false)


func mine_meshes(_show):
	# print("Setting mine meshinstances to "+str(_show))
	$MineMeshes/Main.visible = _show
	$MineMeshes/Top.visible = _show
	$MineMeshes/OmniLight.visible = _show


func bomb_meshes(_show):
	# print("Setting bomb meshinstances to "+str(_show))
	$BombMeshes/Body.visible = _show
	$BombMeshes/Fin1.visible = _show
	$BombMeshes/Fin2.visible = _show


func nuke_meshes(_show):
	# print("Setting nuke meshinstances to "+str(_show))
	$NukeMeshes/Body.visible = _show
	$NukeMeshes/Fin1.visible = _show
	$NukeMeshes/Fin2.visible = _show
