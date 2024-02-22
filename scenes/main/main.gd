class_name MainScene
extends Spatial


export var air_strike_state: Dictionary = {
	"on": false, 
	"duration_so_far_sec": 0.0, 
	"interval_so_far_sec": 0.0}
	
export var start_clock_hrs: float = 12.0
export var test_nuke: bool = false
export var fake_sun_omni_light: bool = false

var town = null
var timer_1_sec: float = 1.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var is_game_paused: bool = false
var trees: Array = []
var num_trees: int = 0
var num_trees_total: int = 100  #100
var grasses: Array = []
var num_grasses: int = 0
var num_grasses_total: int = 200  #200
var ray: RayCastProceduralVegetation = load(Global.raycast_procedural_veg_folder).instance()
var tree_resource: Resource = load(Global.tree_folder)
var grass_resource: Resource = load(Global.grass_folder)
var veg_check_raycast: bool = false
var last_veg: Array = []
var in_slow_motion: bool = false
var game_over_checked = false
var time_since_last_toggle = 0.0


# built-in virtual methods

func _ready():
	Global.debug_print(5, "main:ready()", "scenes")
	var _connect_change_weather = Global.connect("change_weather", self, "on_change_weather")
	randomize()
	#$TimerSlowMotion.start()  # for Procedurally place vegetation
	self.add_child(ray)
	#$VC/CL/MainMenu.set_visible(false)
	$VC/CL/MainMenu.game_active = true
	$VC/CL/MainMenu/PlayerSelection.hide()
	$VC/CL/MainMenu/GameModeSelection.hide()
	$VC/CL/MainMenu/VersionText.hide()
	$VC/CL/MainMenu/LoadingText.show()
	$VC/CL/MainMenu.show()
	$VC/CL/MainMenu/MainSelection.show()
	$VC/CL/MainMenu/MainSelection/MainContainer/ButtonsContainer.hide()
	$VC/CL/MainMenu/MainSelection/MainContainer/TitleContainer.hide()
	
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
	var spawn_points: Array = _get_spawn_points()
	Global.debug_print(3, "main:ready(): instancing players")
	for player_number in range(1, StatePlayers.num_players()+1):
		var player_instance: Player = load(Global.player_folder).instance()
		add_child(player_instance)
		player_instance.name = "Player"+StatePlayers.players[player_number]["name"]
		var vehicle_body_pos: Vector3 = spawn_points[player_number-1].global_transform.origin
		player_instance.init(player_number, vehicle_body_pos)
		player_instance.get_vehicle_body().weapons_state[3].enabled = test_nuke
		player_instance.get_vehicle_body().weapons_state[3].test_mode = test_nuke
		Global.debug_print(3, "main:ready(): player_instance.get_vehicle_body().global_transform.origin after vb init="+str(player_instance.get_vehicle_body().global_transform.origin), "camera")
	Global.debug_print(3, "main:ready(): instancing players completed")
	var anim_time: float = start_clock_hrs + 12.0
	if anim_time > 24.0:
		anim_time -= 12.0
	$DirectionalLightSun/DayNightAnimation.play("daynightcycle")
	$DirectionalLightSun/DayNightAnimation.seek(anim_time)
	$DirectionalLightMoon/DayNightAnimation.play("daynightcycle")
	$DirectionalLightMoon/DayNightAnimation.seek(anim_time)

	if Global.build_options["foliage"]:
		# Add veg instances, but place later in physics as we need raycasts
		for _nt in range(0, num_trees_total):
			var tree: AnimatedTree = tree_resource.instance()
			$Vegetation/Trees.add_child(tree)
			trees.append(tree.get_instance_id())
			
		for _ng in range(0, num_grasses_total): 
			var grass: AnimatedGrass = grass_resource.instance()
			$Vegetation/Grass.add_child(grass)
			grasses.append(grass.get_instance_id())
	
	if Global.build_options["platforms"] == false:
		$Structures/Platforms.queue_free()
		
	Global.debug_print(5, "main:ready() exit", "scenes")
	
	# Set some graphics options
	if Global.graphics == Global.Graphics.Low:
		$DirectionalLightSun.shadow_enabled = false
		$DirectionalLightMoon.shadow_enabled = false
		Engine.iterations_per_second = 60  # any lower and vehicle falls through the terrain
		#rendering/quality/shadow_atlas/size = 2048
	else:
		$DirectionalLightSun.shadow_enabled = true
		$DirectionalLightMoon.shadow_enabled = true
		Engine.iterations_per_second = 288
		#rendering/quality/shadow_atlas/size = 4096


func _process(delta):
	
	time_since_last_toggle += delta
	
	if Input.is_action_pressed("pause") or Input.is_action_pressed("back"):
		is_game_paused = true
		$VC/CL/MainMenu.game_active = true
		$VC/CL/MainMenu.configure()
		$VC/CL/MainMenu.pause()
		Global.debug_print(3, "pausing...")
		get_tree().paused = true  # pause everything, the MainMenu will continue processing
		
	
	if Input.is_action_pressed("toggle_hud") and time_since_last_toggle > 1.0:
		time_since_last_toggle = 0.0
		for player in get_players():
			player.toggle_hud()
	
	if Input.is_action_pressed("toggle_fps")  and time_since_last_toggle > 1.0:
		time_since_last_toggle = 0.0
		if $VC/CL/FPSCounter.visible == true:
			$VC/CL/FPSCounter.hide()
		else:
			var fps_text = "FPS:"+str(Engine.get_frames_per_second())
			if Global.graphics == Global.Graphics.Low:
				$VC/CL/FPSCounter.text = "LG:"+fps_text
			else:
				$VC/CL/FPSCounter.text = "HG:"+fps_text
			$VC/CL/FPSCounter.show()

	if Global.build_options["air_strike"]:
		
		air_strike_state["interval_so_far_sec"] += delta
		air_strike_state["duration_so_far_sec"] += delta
		
		if air_strike_state["on"] == false and air_strike_state["interval_so_far_sec"] > Global.air_strike_config["interval_sec"] and Global.game_mode != Global.GameMode.PEACEFUL:
			_turn_airstrike_on()
		elif air_strike_state["on"] == true and air_strike_state["duration_so_far_sec"] > Global.air_strike_config["duration_sec"]:
			_turn_airstrike_off()
			#Global.debug_print(3, "Turing airstrike off")
			#for node in get_tree().root.get_node("TownScene").get_children():  #find_node("*Bomb*":
				#Global.debug_print(3, "After airstrike finished, found root.get_children() objects: "+str(node.name))
				#if "omb" in node.name:
				#	Global.debug_print(3, "  Found bomb: stage = "+str(node.bomb_stage))
				#	Global.debug_print(3, "  type = "+str(node.type))
				
			
		if air_strike_state["on"] == true:
			for player in get_players():  # range(1, num_players+1):
				if player.has_vehicle_body():
					if player.get_vehicle_body().lifetime_so_far_sec > 5.0:
						if randf() < delta/5.0:  # target a rate of one bomb per player per five seconds
							var weapon_instance = load(Global.explosive_folder).instance()
							add_child(weapon_instance) 
							var speed = player.get_vehicle_body().get_speed2()
							var cbo = player.get_vehicle_body().get_global_offset_pos(20.0, 1.0, 3.5*speed, 1.0)
							weapon_instance.activate(cbo, Vector3(0,0,0), Vector3(0,0,0), 1, 0)  # player 0 = no player
							weapon_instance.set_as_bomb()
							weapon_instance.set_as_toplevel(true)
							Global.debug_print(3, "Launched bomb during airstrike at Player "+str(player.player_number))
							Global.debug_print(3, "Bomb name "+str(weapon_instance.name))
							#$nuke_mushroom_cloud.emitting = true
							#$nuke_mushroom_cloud2.emitting = true

	timer_1_sec -= delta
	
	if timer_1_sec < 0.0:
		_check_game_over()
		_check_and_enforce_slow_motion()
		timer_1_sec = 1.0
		
	if $Effects/Wind.volume_db != Global.weather_state["wind_volume_db"]:
		$Effects/TweenWindVolume.interpolate_property($Effects/Wind, "volume_db", $Effects/Wind.volume_db, Global.weather_state["wind_volume_db"], 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Effects/TweenWindVolume.start()
		$Effects/TweenCindersVolume.interpolate_property($Effects/Cinders, "volume_db", $Effects/Cinders.volume_db, Global.weather_state["wind_volume_db"], 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Effects/TweenCindersVolume.start()


func _physics_process(_delta):
	
	if Global.build_options["foliage"]:
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
				#Global.debug_print(3, "ray translation="+str(ray.translation))
				#ray.cast_to = Vector3(0, -1000, 0)
				if ray.is_colliding():
					Global.debug_print(4, "main: colliding with "+str(ray.get_collider().name), "procedural veg")
					if "terrain" in ray.get_collider().name.to_lower() and not "lava" in ray.get_collider().name.to_lower():
						Global.debug_print(5, "colliding with terrain..", "procedural veg")
						#Global.debug_print(3, "collision point = "+str(ray.get_collision_point()))
						if num_trees < num_trees_total:  # place trees first
							if ray.get_collision_normal().normalized().y > 0.98 and ray.get_collision_normal().normalized().y < 0.99:  # slightly sloping ground for trees
								#Global.debug_print(3, "tree collision normal.normalized() = "+str(ray.get_collision_normal().normalized()))
								#var tree = load("res://scenes/tree.tscn").instance()  #
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
								#Global.debug_print(3, "grass collision normal.normalized() = "+str(ray.get_collision_normal().normalized()))
								#tree.global_transform.origin = ray.get_collision_point()
								#var grass = load("res://scenes/grass.tscn").instance()  # 
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


# Signal methods


func on_change_weather(weather_change: Dictionary, change_duration_sec) -> void:
	Global.debug_print(3, "MainScene weather_change="+str(weather_change))
	for weather_item_key in weather_change.keys():
		if "fog_depth_begin" == weather_item_key:
			Global.debug_print(3, "MainScene: changing weather: weather_item = fog_depth_begin", "weather")
			Global.debug_print(3, "  old="+str(weather_change["fog_depth_begin"][0])+", new="+str(weather_change["fog_depth_begin"][1]), "weather")
			if $Effects/TweenFogDepthBegin.is_active():
				Global.debug_print(3, "VehicleBody: warning: starting $Effects/TweenFogDepthBegin but it's still active", "weather")
			$Effects/TweenFogDepthBegin.interpolate_property($Viewport/WorldEnvironment, "environment:fog_depth_begin", weather_change["fog_depth_begin"][0], weather_change["fog_depth_begin"][1], change_duration_sec, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Effects/TweenFogDepthBegin.start()
			
		if "dof_blur_far_amount" == weather_item_key:
			Global.debug_print(1, "MainScene: changing weather: weather_item = dof_blur_far_amount", "weather")
			Global.debug_print(1, "MainScene: weather_change = "+str(weather_change), "weather")
			Global.debug_print(1, "  old="+str(weather_change["dof_blur_far_amount"][0])+", new="+str(weather_change["dof_blur_far_amount"][1]), "weather")
			if $Effects/TweenBlurFarAmount.is_active():
				Global.debug_print(3, "VehicleBody: warning: starting $Effects/dof_blur_far_amount but it's still active", "weather")
			$Effects/TweenBlurFarAmount.interpolate_property($Viewport/WorldEnvironment, "environment:dof_blur_far_amount", weather_change["dof_blur_far_amount"][0], weather_change["dof_blur_far_amount"][1], change_duration_sec, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$Effects/TweenBlurFarAmount.start()
			
		if $Effects/TweenBlurFarAmount.is_active():
			Global.debug_print(3, "VehicleBody: warning: starting $Effects/TweenFogColor but it's still active", "weather")
		#$Effects/TweenFireStorm.interpolate_property($Effects/FireStormDirectionalLight, "light_energy", weather_change["fire_storm_dir_light"][0], weather_change["fire_storm_dir_light"][1], change_duration_sec, Tween.TRANS_LINEAR, Tween.EASE_IN)
		#$Effects/TweenFireStorm.start()


func _on_TimerCheckAudioPitch_timeout():
	$Effects.set_pitch_scale(Engine.time_scale)


func _all_audio_pitch(_pitch=null):
	var set_pitch = _pitch
	if _pitch == null:
		set_pitch = Engine.time_scale
	$Effects.set_pitch_scale(set_pitch)


# Private methods

func _turn_airstrike_on() -> void:
	air_strike_state["on"] = true
	air_strike_state["interval_so_far_sec"] = 0.0
	air_strike_state["duration_so_far_sec"] = 0.0
	#var players = get_tree().get_nodes_in_group("player")  # 
	#Global.debug_print(3, "len(players)="+str(len(players)))
	_air_strike_label().visible = true
	_air_strike_label().get_node("TextFlash").play("font_blink")
	$VC/CL/IconRadiation.visible = true
	$Effects/Siren.playing = true


func _turn_airstrike_off() -> void:
	air_strike_state["on"] = false
	air_strike_state["interval_so_far_sec"] = 0.0
	air_strike_state["duration_so_far_sec"] = 0.0
	_air_strike_label().visible = false
	_air_strike_label().get_node("TextFlash").stop()
	$VC/CL/IconRadiation.visible = false
	$Effects/Siren.playing = false


func _check_and_enforce_slow_motion() -> void:
	Global.debug_print(5, "_check_and_enforce_slow_motion():", "slow motion")
	Global.debug_print(5, "Engine.time_scale="+str(Engine.time_scale), "slow motion")
	Global.debug_print(5, "$Effects/Wind.pitch_scale="+str($Effects/Wind.pitch_scale), "slow motion")
	if $TimerSlowMotion.is_stopped():
		Global.debug_print(5, "$TimerSlowMotion.is_stopped()", "slow motion")
		if not Engine.time_scale == 1.0 and not $TweenNormalMotion.is_active():
			Global.debug_print(5, "not Engine.time_scale == 1.0 and not $TweenNormalMotion.is_active()", "slow motion")
			#Engine.time_scale = 1.0
			$TweenNormalMotion.interpolate_property(Engine, "time_scale", 0.1, 1.0, Global.SLOW_MOTION_DURATION_SEC/2.0, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
			$TweenNormalMotion.start()
			in_slow_motion = false
	else:
		Global.debug_print(5, "not $TimerSlowMotion.is_stopped()", "slow motion")
		#Engine.time_scale = 0.1
		if not $TweenSlowMotion.is_active():
			Global.debug_print(5, "not $TweenSlowMotion.is_active()", "slow motion")
			$TweenSlowMotion.interpolate_property(Engine, "time_scale", 1.0, 0.1, Global.SLOW_MOTION_DURATION_SEC/2.0, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
			$TweenSlowMotion.start()
			in_slow_motion = true


func _check_game_over() -> void:
	if not game_over_checked:
		var dead_cars: int = 0
		var num_cars: int = 0
		for player_number in range(1, StatePlayers.num_players()+1):
			num_cars += 1
			if StatePlayers.players[player_number]["lives_left"] <= 0:
				dead_cars += 1
		if dead_cars >= (num_cars-1) and num_cars>1:
			game_over_checked = true
			Engine.time_scale = 1.0
			_all_audio_pitch(1.0)
			in_slow_motion = false
			get_tree().paused = false
			var final_score_resource: Resource = load(Global.final_score_scene)
			var final_score_scene: FinalScore = final_score_resource.instance()
			var winner_name: String = ""
			for player_number in range(1, StatePlayers.num_players()+1):
				if StatePlayers.players[player_number]["lives_left"] > 0:
					winner_name = StatePlayers.players[player_number]["name"]  #get_player(player_number).player_name
			final_score_scene.player_winner_name = winner_name
			StatePlayers.players = {}
			get_tree().root.call_deferred("add_child", final_score_scene)
			queue_free()


func _get_spawn_points() -> Array:
	# Returns a random-order array of SpawnPoints
	var shuffled = get_node("SpawnPoints").get_children()
	shuffled.shuffle()
	return get_node("SpawnPoints").get_children()


func _get_random_spawn_point() -> Spatial:
	var spawn_points = _get_spawn_points()
	return spawn_points[randi() % spawn_points.size()].global_transform.origin


func _get_bombs():
	return get_tree().get_nodes_in_group("bomb")


func _air_strike_label() -> Label:
	return $VC.get_node("CL/LabelAirStrike") as Label


# Public methods

func wind(active: bool):
	$Effects/Wind.playing = active
	$Effects/Cinders.playing = active


func start_timer_slow_motion() -> void:
	$TimerSlowMotion.start()
	_check_and_enforce_slow_motion()
	# TODO Send a signal to everyone! 


func is_in_slow_motion():
	#Global.debug_print(3, "Engine.time_scale="+str(Engine.time_scale))
	if Engine.time_scale < 1.0:
		return true
	else:
		return false


func get_players(ignore_player_number=false) -> Array:
	var players_all = get_tree().get_nodes_in_group("player")  # 
	#Global.debug_print(3, "players_all="+str(players_all))
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


func reset_game() -> void:
	Engine.time_scale = 1.0
	_all_audio_pitch(1.0)
	in_slow_motion = false
	StatePlayers.players = {}
	var next_level_resource = load(Global.logo_scene_folder)
	var next_level = next_level_resource.instance() as LogoScene
	get_tree().root.call_deferred("add_child", next_level)
	get_tree().paused = false
	queue_free()


func _on_PlayArea_body_exited(body):
	if body is VehicleBody:
		Global.debug_print(3, "main(): detected VehicleBody leaving the playing area", "damage")
		if is_game_paused == true:
			Global.debug_print(3, "main(): is_game_paused == true, ignoring", "damage")
			return
		Global.debug_print(3, "main(): body location = "+str(body.global_transform.origin), "damage")
		Global.debug_print(3, "main(): body name = "+str(body.name), "damage")
		Global.debug_print(3, "main(): lifetime_so_far_sec="+str(body.lifetime_so_far_sec), "damage")
		if body.vehicle_state == ConfigVehicles.AliveState.ALIVE:
			body.add_damage(body.max_damage, Global.DamageType.OFF_MAP)
			# body.get_player().add_achievement(Global.Achievements.OUT_OF_THIS_WORLD)
		else:
			Global.debug_print(3, "main(): ignoring: VehicleBody not ALIVE; must be DEAD or DYING...", "damage")



func _on_TimerFlashingFirestormIcon_timeout():
	# periodically flash the icon
	if Global.weather_state["type"] == Global.Weather.FIRE_STORM:
		$VC/CL/IconFireStorm.visible = !$VC/CL/IconFireStorm.visible
	else:
		$VC/CL/IconFireStorm.hide()



func _on_Timer_timeout():
	var fps_text = "FPS:"+str(Engine.get_frames_per_second())
	if Global.graphics == Global.Graphics.Low:
		$VC/CL/FPSCounter.text = "LG:"+fps_text
	else:
		$VC/CL/FPSCounter.text = "HG:"+fps_text
