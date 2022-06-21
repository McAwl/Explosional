extends Spatial
class_name MainScene

var town = null
var timer_1_sec: float = 1.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var is_game_paused: bool = false
var trees: Array = []
var num_trees: int = 0
var num_trees_total: int = 200  #100
var grasses: Array = []
var num_grasses: int = 0
var num_grasses_total: int = 500  #200
var ray: RayCastProceduralVegetation = load(Global.raycast_procedural_veg_folder).instance()
var tree_resource: Resource = load(Global.tree_folder)
var grass_resource: Resource = load(Global.grass_folder)
var veg_check_raycast: bool = false
var last_veg: Array = []
var in_slow_motion: bool = false

export var air_strike: Dictionary = {"on": false, "duration_so_far_sec": 0.0, "duration_sec": 30.0, "interval_so_far_sec": 0.0, "interval_sec": 120.0, "circle_radius_m": 10.0}
export var start_clock_hrs: float = 12.0
export var test_nuke: bool = false
export var fake_sun_omni_light: bool = false
export var test_turn_off_airstrike: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	# $TimerSlowMotion.start()  # for Procedurally place vegetation
	self.add_child(ray)
	$VC/CL/MainMenu.set_visible(false)
	$VC/CL/MainMenu.game_active = true
	$VC/CL/MainMenu/PlayerSelection.hide()
	$VC/CL/MainMenu/LoadingText.hide()
	
	# hide the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if fake_sun_omni_light == true:
		$Sun/OmniLight.visible = true
		$DirectionalLightSun.visible = false
		$Moons/OmniLight.visible = true
		$DirectionalLightMoon.visible = false
	else:
		$Sun/OmniLight.visible = false
		$DirectionalLightSun.visible = true
		$Moons/OmniLight.visible = false
		$DirectionalLightMoon.visible = true
	var spawn_points: Array = get_spawn_points()
	for player_number in range(1, StatePlayers.num_players()+1):
		var player_instance: Player = load(Global.player_folder).instance()
		add_child(player_instance)
		player_instance.name = "Player"+StatePlayers.players[player_number]["name"]
		var pos: Vector3 = spawn_points[player_number-1].global_transform.origin
		player_instance.init(player_number, pos)
		player_instance.get_vehicle_body().weapons_state[3].enabled = test_nuke
		player_instance.get_vehicle_body().weapons_state[3].test_mode = test_nuke
	var anim_time: float = start_clock_hrs + 12.0
	if anim_time > 24.0:
		anim_time -= 12.0
	$DirectionalLightSun/DayNightAnimation.play("daynightcycle")
	$DirectionalLightSun/DayNightAnimation.seek(anim_time)
	$DirectionalLightMoon/DayNightAnimation.play("daynightcycle")
	$DirectionalLightMoon/DayNightAnimation.seek(anim_time)

	# Add veg instances, but place later in physics as we need raycasts
	for _nt in range(0, num_trees_total):
		var tree: AnimatedTree = tree_resource.instance()
		$Vegetation/Trees.add_child(tree)
		trees.append(tree.get_instance_id())
		
	for _ng in range(0, num_grasses_total): 
		var grass: AnimatedGrass = grass_resource.instance()
		$Vegetation/Grass.add_child(grass)
		grasses.append(grass.get_instance_id())


func turn_airstrike_on() -> void:
	air_strike["on"] = true
	air_strike["interval_so_far_sec"] = 0.0
	air_strike["duration_so_far_sec"] = 0.0
	# var players = get_tree().get_nodes_in_group("player")  # 
	# print("len(players)="+str(len(players)))
	air_strike_label().visible = true
	air_strike_label().get_node("TextFlash").play("font_blink")
	$VC/CL/IconRadiation.visible = true
	$Effects/Siren.playing = true


func turn_airstrike_off() -> void:
	air_strike["on"] = false
	air_strike["interval_so_far_sec"] = 0.0
	air_strike["duration_so_far_sec"] = 0.0
	air_strike_label().visible = false
	air_strike_label().get_node("TextFlash").stop()
	$VC/CL/IconRadiation.visible = false
	$Effects/Siren.playing = false
	

func _process(delta):
	
	if Input.is_action_pressed("pause") or Input.is_action_pressed("back"):
		is_game_paused = true
		$VC/CL/MainMenu.game_active = true
		$VC/CL/MainMenu.configure()
		$VC/CL/MainMenu.pause()
		print("pausing...")
		get_tree().paused = true  # pause everything, the MainMenu will continue processing
		
	
	if Input.is_action_pressed("toggle_hud"):
		for player in get_players():
			player.toggle_hud()
		
	air_strike["interval_so_far_sec"] +=delta
	air_strike["duration_so_far_sec"] += delta
		
	if air_strike["on"] == false and air_strike["interval_so_far_sec"] > air_strike["interval_sec"] and test_turn_off_airstrike == false:
		turn_airstrike_on()
	elif air_strike["on"] == true and air_strike["duration_so_far_sec"] > air_strike["duration_sec"]:
		turn_airstrike_off()
		# print("Turing airstrike off")
		#for node in get_tree().root.get_node("TownScene").get_children():  #find_node("*Bomb*":
			# print("After airstrike finished, found root.get_children() objects: "+str(node.name))
			#if "omb" in node.name:
			#	print("  Found bomb: stage = "+str(node.bomb_stage))
			#	print("  type = "+str(node.type))
			
		
	if air_strike["on"] == true:
		for player in get_players():  # range(1, num_players+1):
			if player.has_node("vehicle_body"):
				if player.get_vehicle_body().lifetime_so_far_sec > 5.0:
					if randf()<0.005:
						var weapon_instance = load(Global.explosive_folder).instance()
						add_child(weapon_instance) 
						var speed = player.get_vehicle_body().get_speed2()
						var cbo = player.get_vehicle_body().get_global_offset_pos(20.0, 1.0, 3.5*speed, 1.0)
						weapon_instance.activate(cbo, Vector3(0,0,0), Vector3(0,0,0), 1, 0)  # player 0 = no player
						weapon_instance.set_as_bomb()
						weapon_instance.set_as_toplevel(true)
						print("Launched bomb during airstrike at Player "+str(player.player_number))
						print("Bomb name "+str(weapon_instance.name))
						#$nuke_mushroom_cloud.emitting = true
						#$nuke_mushroom_cloud2.emitting = true

	timer_1_sec -= delta
	
	if timer_1_sec < 0.0:
		check_game_over()
		check_and_enforce_slow_motion()
		timer_1_sec = 1.0


func _physics_process(_delta):
	
	#if num_trees < num_trees_total or num_grasses < num_grasses_total:  # or len(trees)>0 or len(grasses)>0:  # and rng.randf()<0.25:
	if len(trees)>0 or len(grasses)>0:  # and rng.randf()<0.25:
		if veg_check_raycast == false:
			veg_check_raycast = true  # check the raycast collision on the next physics process
			if rng.randf() < 0.9 and len(last_veg)>0:
				# reuse the last placement, randomise x/z nearby so veg is clustered together a bit
				ray.translation = Vector3(-0.5+rng.randf()+last_veg[1].x, last_veg[1].y, -0.5+rng.randf()+last_veg[1].z)
			else:
				ray.translation = Vector3(rng.randf()*1000.0, 100.0, rng.randf()*1000.0)
		else:
			veg_check_raycast = false  # move the raycast on the next physics process
			#ray.force_raycast_update()
			#print("ray translation="+str(ray.translation))
			# ray.cast_to = Vector3(0, -1000, 0)
			if ray.is_colliding():
				# print(" colliding with "+str(ray.get_collider().name))
				if "terrain" in ray.get_collider().name.to_lower() and not "lava" in ray.get_collider().name.to_lower():
					#print("colliding with terrain..")
					#print("collision point = "+str(ray.get_collision_point()))
					if rng.randf() < 0.5 and num_trees < num_trees_total:  # len(trees)>0: # tree
						if ray.get_collision_normal().normalized().y > 0.98 and ray.get_collision_normal().normalized().y < 0.99:  # slightly sloping ground for trees
							print("tree collision normal.normalized() = "+str(ray.get_collision_normal().normalized()))
							# var tree = load("res://scenes/tree.tscn").instance()  #
							var tree = instance_from_id(trees[0])
							#$Vegetation/Trees.add_child(tree)
							#tree.global_transform.origin = ray.get_collision_point()
							tree.translation = Vector3(ray.get_collision_point().x-28.3, ray.get_collision_point().y, ray.get_collision_point().z-82.4)
							tree.translation = Vector3(ray.get_collision_point().x, ray.get_collision_point().y, ray.get_collision_point().z)
							var scale_tree = 0.5 + (0.5*rng.randf())
							tree.scale = Vector3(scale_tree, scale_tree, scale_tree)
							num_trees += 1
							trees.remove(0)
							last_veg = ["tree", tree.translation]
					elif num_grasses < num_grasses_total:  # len(grasses)>0:  # grass
						if ray.get_collision_normal().normalized().y > 0.9999:  # very flat ground for grass
							print("grass collision normal.normalized() = "+str(ray.get_collision_normal().normalized()))
							#tree.global_transform.origin = ray.get_collision_point()
							# var grass = load("res://scenes/grass.tscn").instance()  # 
							var grass = instance_from_id(grasses[0])
							#$Vegetation/Grass.add_child(grass)
							grass.translation = Vector3(ray.get_collision_point().x-28.3, ray.get_collision_point().y, ray.get_collision_point().z-82.4)
							grass.translation = Vector3(ray.get_collision_point().x, ray.get_collision_point().y, ray.get_collision_point().z)
							num_grasses += 1
							grasses.remove(0)
							last_veg = ["grass", grass.translation]
					else:
						last_veg = []
					$VC/CL/Label.text = "Veg: "+str(num_trees)+" trees "+str(num_grasses)+" grass"
			else:
				last_veg = []


func check_and_enforce_slow_motion() -> void:
	if $TimerSlowMotion.is_stopped():
		Engine.time_scale = 1.0
		all_audio_pitch(1.0)
		in_slow_motion = false
	else:
		Engine.time_scale = 0.1
		all_audio_pitch(0.1)
		in_slow_motion = true


func is_in_slow_motion():
	#print("Engine.time_scale="+str(Engine.time_scale))
	if Engine.time_scale < 1.0:
		return true
	else:
		return false


func check_game_over() -> void:
	var dead_cars: int = 0
	var num_cars: int = 0
	for player_number in range(1, StatePlayers.num_players()+1):
		num_cars += 1
		if StatePlayers.players[player_number]["lives_left"] < 0:
			dead_cars += 1
	if dead_cars >= (num_cars-1) and num_cars>1:
		var next_level_resource: Resource = load(Global.final_score_scene)
		var next_level: FinalScore = next_level_resource.instance()
		var winner_name: String = ""
		for player_number in range(1, StatePlayers.num_players()+1):
			if StatePlayers.players[player_number]["lives_left"] >= 0:
				winner_name = StatePlayers.players[player_number]["name"]  #get_player(player_number).player_name
		next_level.player_winner_name = winner_name
		get_tree().root.call_deferred("add_child", next_level)


func all_audio_pitch(pitch) -> void:
	$Effects/BackgroundMusic.pitch_scale = pitch
	$Effects/Siren.pitch_scale = pitch


func get_spawn_points() -> Array:
	return get_node("SpawnPoints").get_children()


func get_random_spawn_point() -> Spatial:
	var spawn_points = get_spawn_points()
	return spawn_points[randi() % spawn_points.size()].global_transform.origin
	
	
func get_players(ignore_player_number=false) -> Array:
	var players_all = get_tree().get_nodes_in_group("player")  # 
	print("players_all="+str(players_all))
	var players2 = []
	for player in players_all:  # range(1, num_players+1):
		if ignore_player_number == false:
			players2.append(get_player(player.player_number))
		else:
			if ignore_player_number != player.player_number:
				players2.append(get_player(player.player_number))
	return players2


func get_player(player_number) -> Player:
	return get_node("Player"+str(player_number)) as Player
	

func get_bombs():
	return get_tree().get_nodes_in_group("bomb")
	

func reset_game() -> void:
	StatePlayers.players = {}
	var next_level_resource = load(Global.logo_scene_folder)
	var next_level = next_level_resource.instance() as LogoScene
	get_tree().root.call_deferred("add_child", next_level)
	get_tree().paused = false
	queue_free()


func air_strike_label() -> Label:
	return $VC.get_node("CL/LabelAirStrike") as Label


func start_timer_slow_motion() -> void:
	$TimerSlowMotion.start()
	check_and_enforce_slow_motion()


func _on_TimerCheckPowerups_timeout():
	
	if not $Powerups/NukeSpawnPoint.has_node("PowerUpNuke") and $Powerups/TimerNukePowerUp.is_stopped():
		$Powerups/TimerNukePowerUp.set_paused(false)
		$Powerups/TimerNukePowerUp.start(10.0)
		
	if not $Powerups/ShieldPowerupSpawnPoint.has_node("PowerUpShield1") and $Powerups/TimerShieldPowerup.is_stopped():
		$Powerups/TimerShieldPowerup.set_paused(false)
		$Powerups/TimerShieldPowerup.start(10.0)
	
	if not $Powerups/HealthPowerupSpawnPoint.has_node("PowerUpHealth1") and $Powerups/TimerHealthPowerup.is_stopped():
		$Powerups/TimerHealthPowerup.set_paused(false)
		$Powerups/TimerHealthPowerup.start(10.0)


func _on_TimerNukePowerUp_timeout():
	print("_on_TimerNukePowerUp_timeout")
	if $Powerups/TimerNukePowerUp.is_stopped():
		print("Respawning new_nuke_powerup")
		var new_nuke_powerup = load(Global.power_up_folder).instance()
		new_nuke_powerup.name = "PowerUpNuke"
		new_nuke_powerup.type = ConfigWeapons.PowerupType.NUKE
		$Powerups/NukeSpawnPoint.add_child(new_nuke_powerup)
		new_nuke_powerup.get_node("ActivationSound").play()


func _on_TimerShieldPowerup_timeout():
	print("_on_TimerShieldPowerup_timeout")
	if $Powerups/TimerShieldPowerup.is_stopped():
		print("Respawning shield_powerup")
		var new_shield_powerup = load(Global.power_up_folder).instance()
		new_shield_powerup.name = "PowerUpShield1"
		new_shield_powerup.type = ConfigWeapons.PowerupType.SHIELD
		$Powerups/ShieldPowerupSpawnPoint.add_child(new_shield_powerup)
		new_shield_powerup.get_node("ActivationSound").play()


func _on_TimerHealthPowerup_timeout():
	print("_on_TimerHealthPowerup_timeout")
	if $Powerups/TimerHealthPowerup.is_stopped():
		print("Respawning health_powerup")
		var new_health_powerup = load(Global.power_up_folder).instance()
		new_health_powerup.name = "PowerUpHealth1"
		new_health_powerup.type = ConfigWeapons.PowerupType.HEALTH
		$Powerups/HealthPowerupSpawnPoint.add_child(new_health_powerup)
		new_health_powerup.get_node("ActivationSound").play()
