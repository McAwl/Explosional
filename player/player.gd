class_name Player
extends Spatial


var player_number: int
var last_spawn_point: Vector3
var achievements: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	$VC/V/CanvasLayer/HeadUpDisplay/icon_mine.visible = true
	$VC/V/CanvasLayer/HeadUpDisplay/icon_rocket.visible = false
	$VC/V/CanvasLayer/HeadUpDisplay/icon_missile.visible = false
	$VC/V/CanvasLayer/HeadUpDisplay/icon_nuke.visible = false
	$VC/V/CanvasLayer/HeadUpDisplay/health.tint_progress = "#7e00ff00"  # green
	get_canvaslayer().get_node("LabelAchievement").hide()


func _process(_delta):
	 update_other_player_label()  # need to do this on every screen refresh


# Signal methods

func _on_TimerUpdateSpeedometer_timeout():
	if get_vehicle_body() == null:
		return
	#Global.debug_print(3, "_on_TimerUpdateSpeedometer_timeout()")
	# 3.6 kilometers per hour equal one meter per second\
	var speed_km_hr = get_vehicle_body().fwd_mps*3.6
	var text = "%03d km/hr" % int(round(abs(speed_km_hr))) + \
	"  max: "+str(get_vehicle_body().get_max_speed_km_hr()) + \
	" km/hr  \npower: %04d" % int(round(get_vehicle_body().engine_force_ewma)) + \
	"  max: %04d" % + int(round(get_vehicle_body().engine_force_value)) + \
	"  grip: "+str(get_vehicle_body().get_av_wheel_friction_slip())
	get_canvaslayer().get_node('GridContainer').get_node('Label1').text = text
	get_canvaslayer().get_node('Speedometer').update_dial(speed_km_hr, get_vehicle_body().get_max_speed_km_hr())


func _on_TimerUpdateHUD_timeout():
	# periodically update player display
	set_label_player_name()
	set_label_lives_left()
	var health_display: TextureProgress = get_hud().get_node("health")
	if get_vehicle_body() != null:
		health_display.max_value = get_vehicle_body().max_damage
		health_display.value = get_vehicle_body().max_damage-get_vehicle_body().total_damage
		if get_vehicle_body().max_damage-get_vehicle_body().total_damage >= 7.0:
			health_display.tint_progress = "#7e00ff00"  # green
		elif get_vehicle_body().max_damage-get_vehicle_body().total_damage <= 3.0:
			health_display.tint_progress = "#7eff0000"  # red
		else:
			health_display.tint_progress = "#7eff6c00"  # orange


func _on_TimerCheckDestroyedVehicle_timeout():
	# periodically check for a destroyed vehicle
	#if get_viewport().has_node("vehicle_body"):
	#	var vb: VehicleBody = get_viewport().get_node("vehicle_body")
	#	if vb.vehicle_state == ConfigVehicles.AliveState.DEAD:
	#		Global.debug_print(3, "vb.vehicle_state == ConfigVehicles.AliveState.DEAD: destroying vehicle body")
	#		#vb.queue_free()  # doing this removes the camera and really screws thigns up
	#else:
	# TODO move the camera to the player so we can destroy the VehicleBody and keep seeing the exploded parts

	var re_spawn: bool = false
	var have_vb =  has_vehicle_body()
	var vb: VehicleBody
	
	if have_vb == false:
		Global.debug_print(3, "_on_TimerCheckDestroyedVehicle_timeout(): have_vb == false, setting re_spawn = true", "vehicle_respawn")
		re_spawn = true
	else:
		Global.debug_print(5, "_on_TimerCheckDestroyedVehicle_timeout(): have_vb == true", "vehicle_respawn")
		vb = get_vehicle_body()  # get_viewport().get_node("vehicle_body")
		if vb.vehicle_state == ConfigVehicles.AliveState.DEAD:
			Global.debug_print(3, "vb.vehicle_state == ConfigVehicles.AliveState.DEAD, setting re_spawn = true", "vehicle_respawn")
			re_spawn = true
	
	if re_spawn:
		re_spawn = false
		if not get_parent().is_in_slow_motion():  # wait until the main scene finished any slow motion dying stuff
			Global.debug_print(3, "player "+str(player_number)+":_on_TimerCheckDestroyedVehicle_timeout(): not get_parent().is_in_slow_motion()", "vehicle_respawn")
			Global.debug_print(3, "player "+str(player_number)+":_on_TimerCheckDestroyedVehicle_timeout(): vehicle_state ="+str(vb.vehicle_state)+"="+str(ConfigVehicles.AliveState.keys()[vb.vehicle_state]), "vehicle_respawn")
			#if vehicle_state == ConfigVehicles.AliveState.DYING:
			#Global.debug_print(3, "Engine.time_scale="+str(Engine.time_scale))
			if StatePlayers.players[player_number]["lives_left"] > 0:
				Global.debug_print(3, "player "+str(player_number)+": "+str(StatePlayers.players[player_number]["lives_left"])+" lives left, spawning...", "vehicle_respawn")
				re_spawn = true
				
	if re_spawn:
		Global.debug_print(3, "player "+str(player_number)+":_on_TimerCheckDestroyedVehicle_timeout(): if re_spawn", "vehicle_respawn")
		if vb != null:
			Global.debug_print(3, "player "+str(player_number)+":_on_TimerCheckDestroyedVehicle_timeout(): vb != null -> vb.queue_free()", "vehicle_respawn")
			Global.debug_print(3, "player "+str(player_number)+":_on_TimerCheckDestroyedVehicle_timeout(): vb.vehicle_state == "+str(vb.vehicle_state), "vehicle_respawn")
			vb.queue_free()
		init_vehicle_body(last_spawn_point)


func _on_TimerDisableAchievementLabel_timeout():
		get_canvaslayer().get_node("LabelAchievement").hide()


# Public methods

func reset_health() -> void:
	$VC/V/CanvasLayer/health.value = get_vehicle_body().max_damage
	$VC/V/CanvasLayer/health.tint_progress = "#7e00ff00"  # green


func get_hud() -> Node2D:
	return $VC/V/CanvasLayer/HeadUpDisplay as Node2D


func toggle_hud() -> void:
	if get_hud().visible == true:
		get_hud().visible = false
	else:
		get_hud().visible = true


func init(_player_number, pos=null) -> void:
	last_spawn_point = pos
	#Global.debug_print(3, "player:init()")
	
	player_number = _player_number
	#Global.debug_print(3, "player init(): StatePlayers.num_players()="+str(StatePlayers.num_players()))
	
	
	# Add a vehicle to the player
	init_vehicle_body(pos)
	
	set_label_player_name()
	set_label_lives_left()

	
	match StatePlayers.num_players():
		1: 
			set_viewport_container_one(_player_number)
		2:
			set_viewport_container_two(_player_number)
		3:
			set_viewport_container_three(_player_number)
		4:
			set_viewport_container_four(_player_number)
		_: 
			set_viewport_container_two(_player_number)


func init_vehicle_body(pos) -> void:
	var vehicle_body: VehicleBody = load(Global.vehicle_body_folder).instance()
	get_viewport().add_child(vehicle_body)
	Global.debug_print(2, "Player "+str(player_number)+" spawned a new vehicle body", "vehicle_respawn")
	var retval: bool = vehicle_body.init(pos, player_number, "vehicle_body")
	if retval == false:
		Global.debug_print(1, "Error: couldn't initialise vehicle body", "vehicle_respawn")
		get_tree().quit()
	

func set_viewport_container_one(_player_number) -> void:
	#Global.debug_print(3, "set_viewport_container_one():")
	#Global.debug_print(3, "player_number="+str(_player_number))
	if _player_number == 1:
		set_viewport_container(0, 0, 0, 0, 1920, 1080)


func set_viewport_container_two(_player_number) -> void:
	#Global.debug_print(3, "set_viewport_container_two():")
	#Global.debug_print(3, "player_number="+str(_player_number))
	if _player_number == 1:
		set_viewport_container(0, 0, 540, 0, 1920, 540)
	elif _player_number == 2:
		set_viewport_container(0, 0, 0, 540, 1920, 540)


func set_viewport_container_three(_player_number) -> void:
	#Global.debug_print(3, "set_viewport_container_three():")
	#Global.debug_print(3, "_player_number="+str(_player_number))
	if _player_number == 1:
		set_viewport_container(0, 960, 540, 0, 960, 540)
	elif _player_number == 2:
		set_viewport_container(960, 0, 540, 0, 960, 540)
	elif _player_number == 3:
		set_viewport_container(0, 0, 0, 540, 1920, 540)


func set_viewport_container_four(_player_number) -> void:
	#Global.debug_print(3, "set_viewport_container_four():")
	#Global.debug_print(3, "_player_number="+str(_player_number))
	if _player_number == 1:
		set_viewport_container(0, 960, 540, 0, 960, 540)
	elif _player_number == 2:
		set_viewport_container(960, 0, 540, 0, 960, 540)
	elif _player_number == 3:
		set_viewport_container(0, 960, 0, 540, 960, 540)
	elif _player_number == 4:
		set_viewport_container(960, 0, 0, 540, 960, 540)


func set_viewport_container(_left, _right, _bottom, _top, size_x, size_y) -> void:
	$VC.margin_left = _left
	$VC.margin_right = _right
	$VC.margin_bottom = _bottom
	$VC.margin_top = _top
	$VC.rect_size.x = size_x
	$VC.rect_size.y = size_y
	get_viewport().size.x = size_x
	get_viewport().size.y = size_y
	# label stuff is relative to the container, not window...
	#get_label().margin_left = _left
	get_label_player_name().margin_right = 0


func get_viewport_container() -> ViewportContainer:
	if has_node("VC"):
		return $VC as ViewportContainer
	else:
		Global.debug_print(3, "Warning: no VC, print_tree: ")
		print_tree()
		return null


func get_player_name() -> String:
	return StatePlayers.players[player_number]["name"]


func get_lives_left() -> int:
	return StatePlayers.players[player_number]["lives_left"]


func decrement_lives_left() -> void:
	if not player_number in StatePlayers.players:
		Global.debug_print(1, "Error: player.gd: not player_number in StatePlayers.players")
		return
	StatePlayers.players[player_number]["lives_left"] -= 1


func get_viewport() -> Viewport:
	if get_viewport_container() != null:
		if get_viewport_container().has_node("V"):
			return get_viewport_container().get_node("V") as Viewport
		else:
			Global.debug_print(3, "Warning: no V, print_tree: ")
			print_tree()
			return null
	else:
		return null

	
func get_vehicle_body() -> VehicleBody:
	for ch in get_viewport().get_children():
		if ch is VehicleBody:
			return ch
	return null


func get_label_player_name() -> Label:
	return $VC/V/CanvasLayer/HeadUpDisplay/label_player_name as Label


func get_label_lives_left() -> Label:
	return $VC/V/CanvasLayer/HeadUpDisplay/label_lives_left as Label


func get_canvaslayer() -> CanvasLayer:
	return $VC/V/CanvasLayer as CanvasLayer


func set_label_player_name() -> void:
	if player_number in StatePlayers.players.keys():
		get_label_player_name().text = StatePlayers.players[player_number]["name"]
	else:
		Global.debug_print(3, "Warning: player_number "+str(player_number)+" not in StatePlayers.players.keys()")


func set_label_lives_left() -> void:
	if player_number in StatePlayers.players.keys():
		get_label_lives_left().text = str(StatePlayers.players[player_number]["lives_left"])
	else:
		Global.debug_print(3, "Warning: player_number "+str(player_number)+" not in StatePlayers.players.keys()")


func set_global_transform_origin(o) -> void:
	get_vehicle_body().global_transform.origin = o


func update_other_player_label():
	
	var keys = StatePlayers.players.keys()
	if not 1 in keys:
		get_hud().get_node("label_player_1_pos").hide()
	if not 2 in keys:
		get_hud().get_node("label_player_2_pos").hide()
	if not 3 in keys:
		get_hud().get_node("label_player_3_pos").hide()
	if not 4 in keys:
		get_hud().get_node("label_player_4_pos").hide()
		
	for player_num in keys:  #get_parent().get_players():
		var label = get_hud().get_node("label_player_"+str(player_num)+"_pos")
		#Global.debug_print(3, "player_num="+str(player_num))
		var player_dst = get_parent().get_player(player_num)
		if self != player_dst:  # ignore self
			var player_dst_vehicle_body = player_dst.get_vehicle_body()
			if player_dst_vehicle_body != null:  # eg if player has no lives left, not in the game any more
				var player_dst_hud_pos_loc = player_dst_vehicle_body.get_node("Positions").get_node("HUDPositionLocation")
				var distance = get_vehicle_body().get_global_transform().origin.distance_to(player_dst_hud_pos_loc.global_transform.origin)
				var player_dst_viewport_pos = get_vehicle_body().get_camera().unproject_position ( player_dst_hud_pos_loc.get_global_transform().origin ) 

				var font_size = 10
				if distance < 25.0:
					font_size = 60
				elif distance < 50.0:
					font_size = 40
				elif distance < 100.0:
					font_size = 30
				elif distance < 200.0:
					font_size = 20
				label.get("custom_fonts/font").set_size(font_size)
				
				if get_vehicle_body().get_camera().is_position_behind (player_dst_hud_pos_loc.get_global_transform().origin ):
					label.visible = false
				else:
					label.visible = true
					label.rect_position = player_dst_viewport_pos
					label.rect_position.x -= font_size/2
					label.rect_position.y -= 20 + (font_size/2)
					label.rect_size.x = font_size
					label.rect_size.y = font_size*1.25
			else:
				label.visible = false  # TODO: don't show label for player with destroyed vehicle. A best idea?
		else:
			label.visible = false  # don't show our own label


func has_vehicle_body() -> bool:
	for ch in get_viewport().get_children():
		if ch is VehicleBody:
			return true
	return false


func get_camera() -> Camera:
	return $VC/V/Camera as Camera


func add_achievement(achievement: int) -> void:
	if not achievement in achievements.keys():
		var label = get_canvaslayer().get_node("LabelAchievement")
		achievements[achievement] = {}
		#Global.debug_print(3, "player achievements = "+str(achievements))
		label.anchor_top = 1.0
		label.anchor_bottom = 1.0
		label.show()
		#Global.debug_print(3, "Global.achievement_config="+str(Global.achievement_config))
		#Global.debug_print(3, "added achievement="+str(achievement))
		label.text = "Achievement unlocked: "+str(Global.achievement_config[achievement]["nice_name"])+"\n"+str(Global.achievement_config[achievement]["explanation"])
		$TimerDisableAchievementLabel.start()
		$SoundAchievement.playing = true
		$VC/V/CanvasLayer/TweenHorizAnchorTop.interpolate_property(label, "anchor_top", 1.0, 0.5, 0.5, Tween.TRANS_BACK, Tween.EASE_OUT)
		$VC/V/CanvasLayer/TweenHorizAnchorTop.start()
		$VC/V/CanvasLayer/TweenHorizAnchorBottom.interpolate_property(label, "anchor_bottom", 1.0, 0.5, 0.5, Tween.TRANS_BACK, Tween.EASE_OUT)
		$VC/V/CanvasLayer/TweenHorizAnchorBottom.start()

