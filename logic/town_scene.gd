extends Spatial

var town = null
var timer_1_sec = 1.0
var num_players
var players
var rng = RandomNumberGenerator.new()

export var air_strike = {"on": false, "duration_so_far_sec": 0.0, "duration_sec": 30.0, "interval_so_far_sec": 0.0, "interval_sec": 120.0, "circle_radius_m": 10.0}
export var start_clock_hrs = 12.0
export var test_nuke = false
export var fake_sun_omni_light = false
export var test_turn_off_airstrike = false

# Called when the node enters the scene tree for the first time.
func _ready():
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
	num_players = len(players)
	var spawn_points = get_spawn_points()
	for player_number in range(1, num_players+1):
		var player_instance = load("res://scenes/player.tscn").instance()
		var pos = spawn_points[player_number-1].global_transform.origin
		player_instance.init(player_number, num_players, players[player_number]["name"], pos)
		player_instance.get_carbody().weapons[3].enabled = test_nuke
		player_instance.get_carbody().weapons[3].test_mode = test_nuke
		add_child(player_instance)
	var anim_time = start_clock_hrs + 12.0
	if anim_time > 24.0:
		anim_time -= 12.0
	$DirectionalLightSun/DayNightAnimation.play("daynightcycle")
	$DirectionalLightSun/DayNightAnimation.seek(anim_time)
	$DirectionalLightMoon/DayNightAnimation.play("daynightcycle")
	$DirectionalLightMoon/DayNightAnimation.seek(anim_time)


func turn_airstrike_on():
	air_strike["on"] = true
	air_strike["interval_so_far_sec"] = 0.0
	air_strike["duration_so_far_sec"] = 0.0
	# var players = get_tree().get_nodes_in_group("player")  # 
	# print("len(players)="+str(len(players)))
	air_strike_label().visible = true
	air_strike_label().get_node("TextFlash").play("font_blink")
	$VC/CL/IconRadiation.visible = true
	$siren.playing = true


func turn_airstrike_off():
	air_strike["on"] = false
	air_strike["interval_so_far_sec"] = 0.0
	air_strike["duration_so_far_sec"] = 0.0
	air_strike_label().visible = false
	air_strike_label().get_node("TextFlash").stop()
	$VC/CL/IconRadiation.visible = false
	$siren.playing = false
	

func _process(delta):
	
	if $TimerSlowMotion.is_stopped():
		Engine.time_scale = 1.0
		all_audio_pitch(1.0)
	else:
		Engine.time_scale = 0.2
		all_audio_pitch(0.2)

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
			if player.get_carbody().lifetime_so_far_sec > 5.0:
				if randf()<0.005:
					var weapon_instance = load("res://scenes/explosive.tscn").instance()
					add_child(weapon_instance) 
					var speed = player.get_carbody().get_speed2()
					var cbo = player.get_carbody().get_global_offset_pos(20.0, 1.0, 3.5*speed, 1.0)
					weapon_instance.activate(cbo, Vector3(0,0,0), Vector3(0,0,0), 1, 0)  # player 0 = no player
					weapon_instance.set_as_bomb()
					weapon_instance.set_as_toplevel(true)
					print("Launched bomb during airstrike at Player "+str(player.player_number))
					print("Bomb name "+str(weapon_instance.name))
					#$nuke_mushroom_cloud.emitting = true
					#$nuke_mushroom_cloud2.emitting = true

	timer_1_sec -= delta
	if Input.is_action_pressed("back"):
		reset_game()
	
	if timer_1_sec < 0.0:
		check_game_over()
	
	update_player_hud()


func update_player_hud():
	for player_src in range(1, num_players+1):
		for player_dst in range(1, num_players+1):
			if player_src != player_dst:
				var player_src_carbase = get_player(player_src).get_carbase()
				var player_src_carbody = player_src_carbase.get_carbody()
				var player_src_camera = player_src_carbase.get_camera()
				var player_dst_carbody = get_player(player_dst).get_carbase().get_carbody()
				var distance = player_src_carbody.get_global_transform().origin.distance_to(player_dst_carbody.global_transform.origin)
				var player_dst_viewport_pos = player_src_camera.unproject_position ( player_dst_carbody.get_global_transform().origin ) 
				var label = get_player(player_src).get_canvaslayer().get_node("label_player_"+str(player_dst)+"_pos")
				if distance < 50.0:
					label.get("custom_fonts/font").set_size(50)
				elif distance < 100.0:
					label.get("custom_fonts/font").set_size(30)
				elif distance < 200.0:
					label.get("custom_fonts/font").set_size(20)
				else:
					label.get("custom_fonts/font").set_size(10)
				
				if player_src_camera.is_position_behind (player_dst_carbody.get_global_transform().origin ):
					label.visible = false
				else:
					label.visible = true
					label.rect_position = player_dst_viewport_pos
				
				
		
func check_game_over():
	var dead_cars = 0
	var num_cars = 0
	timer_1_sec = 1.0
	for player_number in range(1, num_players+1):
		num_cars += 1
		if get_player(player_number).lives_left < 0:
			dead_cars += 1
	if dead_cars >= (num_cars-1) and num_cars>1:
		var next_level_resource = load("res://scenes/final_score.tscn")
		var next_level = next_level_resource.instance()
		var winner_name = ""
		for player_number in range(1, num_players+1):
			if get_player(player_number).lives_left >= 0:
				winner_name = get_player(player_number).player_name
		next_level.player_winner_name = winner_name
		get_tree().root.call_deferred("add_child", next_level)
		queue_free()


func all_audio_pitch(pitch):
	$BackgroundMusic/track_1.pitch_scale = pitch
	$BackgroundMusic/track_2.pitch_scale = pitch
	$BackgroundMusic/track_3.pitch_scale = pitch


func get_spawn_points():
	return get_node("SpawnPoints").get_children()


func get_random_spawn_point():
	var spawn_points = get_spawn_points()
	return spawn_points[randi() % spawn_points.size()].global_transform.origin
	
	
func get_players(ignore_player_number=false):
	var players_all = get_tree().get_nodes_in_group("player")  # 
	var players2 = []
	for player in players_all:  # range(1, num_players+1):
		if ignore_player_number == false:
			players2.append(get_player(player.player_number))
		else:
			if ignore_player_number != player.player_number:
				players2.append(get_player(player.player_number))
	return players2


func get_player(player_number):
	return get_node("Player"+str(player_number))
	

func get_bombs():
	return get_tree().get_nodes_in_group("bomb")
	

func reset_game():
	queue_free()
	var _ret_val = get_tree().change_scene("res://scenes/start.tscn")  #get_tree().reload_current_scene()


func air_strike_label():
	return $VC.get_node("CL/LabelAirStrike")


func start_timer_slow_motion():
	$TimerSlowMotion.start()
