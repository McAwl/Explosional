extends Spatial
class_name Player

var player_number: int
var last_spawn_point: Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	$VC/V/CanvasLayer/HeadUpDisplay/icon_mine.visible = true
	$VC/V/CanvasLayer/HeadUpDisplay/icon_rocket.visible = false
	$VC/V/CanvasLayer/HeadUpDisplay/icon_missile.visible = false
	$VC/V/CanvasLayer/HeadUpDisplay/icon_nuke.visible = false
	$VC/V/CanvasLayer/HeadUpDisplay/health.tint_progress = "#7e00ff00"  # green


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


func _process(_delta):
	 update_other_player_label()  # need to do this on every screen refresh


func init(_player_number, pos=null) -> void:
	last_spawn_point = pos
	# print("player:init()")
	
	player_number = _player_number
	# print("player init(): StatePlayers.num_players()="+str(StatePlayers.num_players()))
	
	
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
	var retval: bool = vehicle_body.init(pos, player_number, "vehicle_body")
	if retval == false:
		print("Error: couldn't initialise vehicle body")
		get_tree().quit()
	

func set_viewport_container_one(_player_number) -> void:
	# print("set_viewport_container_one():")
	# print("player_number="+str(_player_number))
	if _player_number == 1:
		set_viewport_container(0, 0, 0, 0, 1920, 1080)


func set_viewport_container_two(_player_number) -> void:
	# print("set_viewport_container_two():")
	# print("player_number="+str(_player_number))
	if _player_number == 1:
		set_viewport_container(0, 0, 540, 0, 1920, 540)
	elif _player_number == 2:
		set_viewport_container(0, 0, 0, 540, 1920, 540)


func set_viewport_container_three(_player_number) -> void:
	# print("set_viewport_container_three():")
	# print("_player_number="+str(_player_number))
	if _player_number == 1:
		set_viewport_container(0, 960, 540, 0, 960, 540)
	elif _player_number == 2:
		set_viewport_container(960, 0, 540, 0, 960, 540)
	elif _player_number == 3:
		set_viewport_container(0, 0, 0, 540, 1920, 540)


func set_viewport_container_four(_player_number) -> void:
	# print("set_viewport_container_four():")
	# print("_player_number="+str(_player_number))
	if _player_number == 1:
		set_viewport_container(0, 960, 540, 0, 960, 540)
	elif _player_number == 2:
		set_viewport_container(960, 0, 540, 0, 960, 540)
	elif _player_number == 3:
		set_viewport_container(0, 960, 0, 540, 960, 540)
	elif _player_number == 4:
		set_viewport_container(960, 0, 0, 540, 960, 540)


func set_viewport_container(_left, _right, _bottom, _top, size_x, size_y) -> void:
	"""
	# get_label_lives_left().margin_right = 0
	# get_label().margin_bottom = 0
	# get_label().margin_top = _top
	# get_label().rect_size.x = size_x
	# get_label().rect_size.y = size_y
	#print("LRTB="+str([_left, _right, _bottom, _top]))
	# print("$VC margins LRBT="+str([$VC.margin_left, $VC.margin_right, $VC.margin_bottom, $VC.margin_top]))
	# print("$VC.rect_size="+str($VC.rect_size))
	# print("$V size="+str([$VC/V.size]))
	# print("label rect_size="+str(get_label().rect_size))
	# print("label align="+str(get_label().align))
	# print("label LRBT="+str([get_label().margin_left, get_label().margin_right, get_label().margin_bottom, get_label().margin_top]))"""
	$VC.margin_left = _left
	$VC.margin_right = _right
	$VC.margin_bottom = _bottom
	$VC.margin_top = _top
	$VC.rect_size.x = size_x
	$VC.rect_size.y = size_y
	get_viewport().size.x = size_x
	get_viewport().size.y = size_y
	# label stuff is relative to the container, not window...
	# get_label().margin_left = _left
	get_label_player_name().margin_right = 0


func get_viewport_container() -> ViewportContainer:
	if has_node("VC"):
		return $VC as ViewportContainer
	else:
		print("Warning: no VC, print_tree: ")
		print_tree()
		return null


func get_player_name() -> String:
	return StatePlayers.players[player_number]["name"]


func get_lives_left() -> int:
	return StatePlayers.players[player_number]["lives_left"]


func decrement_lives_left() -> void:
	StatePlayers.players[player_number]["lives_left"] -= 1


func get_viewport() -> Viewport:
	if get_viewport_container() != null:
		if get_viewport_container().has_node("V"):
			return get_viewport_container().get_node("V") as Viewport
		else:
			print("Warning: no V, print_tree: ")
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
	get_label_player_name().text = StatePlayers.players[player_number]["name"]


func set_label_lives_left() -> void:
	get_label_lives_left().text = str(StatePlayers.players[player_number]["lives_left"])
	

func set_global_transform_origin(o) -> void:
	get_vehicle_body().global_transform.origin = o


func _on_TimerUpdateSpeedometer_timeout():
	if get_vehicle_body() == null:
		return
	# print("_on_TimerUpdateSpeedometer_timeout()")
	# 3.6 kilometers per hour equal one meter per second
	get_canvaslayer().get_node('GridContainer').get_node('Label1').text = "%03d km/hr" % int(round(abs(get_vehicle_body().fwd_mps*3.6)))  #+" km/hr"


func _on_TimerUpdateHUD_timeout():
	# periodically update player display
	set_label_player_name()
	set_label_lives_left()
	var health_display: TextureProgress = get_hud().get_node("health")
	if get_vehicle_body() != null:
		health_display.value = get_vehicle_body().max_damage-get_vehicle_body().total_damage
		if get_vehicle_body().max_damage-get_vehicle_body().total_damage >= 7.0:
			health_display.tint_progress = "#7e00ff00"  # green
		elif get_vehicle_body().max_damage-get_vehicle_body().total_damage <= 3.0:
			health_display.tint_progress = "#7eff0000"  # red
		else:
			health_display.tint_progress = "#7eff6c00"  # orange


func update_other_player_label():
	for player_num in StatePlayers.players.keys():  #get_parent().get_players():
		#print("player_num="+str(player_num))
		var player_dst = get_parent().get_player(player_num)
		if self != player_dst:
			if get_vehicle_body() != null:  # eg if player has no lives left, not in the game any more
				var player_dst_vehicle_body = player_dst.get_vehicle_body()
				if player_dst_vehicle_body != null:
					var player_dst_hud_pos_loc = player_dst_vehicle_body.get_node("Positions").get_node("HUDPositionLocation")
					var distance = get_vehicle_body().get_global_transform().origin.distance_to(player_dst_hud_pos_loc.global_transform.origin)
					var player_dst_viewport_pos = get_vehicle_body().get_camera().unproject_position ( player_dst_hud_pos_loc.get_global_transform().origin ) 
					var label = get_hud().get_node("label_player_"+str(player_num)+"_pos")
					
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
			else:
				var label = get_hud().get_node("label_player_"+str(player_number)+"_pos")
				label.visible = false  # don't show own label


func _on_TimerCheckDestroyedVehicle_timeout():
	# periodically check for a destroyed vehicle
	#if get_viewport().has_node("vehicle_body"):
	#	var vb: VehicleBody = get_viewport().get_node("vehicle_body")
	#	if vb.vehicle_state == ConfigVehicles.AliveState.DEAD:
	#		print("vb.vehicle_state == ConfigVehicles.AliveState.DEAD: destroying vehicle body")
	#		#vb.queue_free()  # doing this removes the camera and really screws thigns up
	#else:
	# TODO move the camera to the player so we can destroy the VehicleBody and keep seeing the exploded parts

	var re_spawn: bool = false
	var have_vb =  has_vehicle_body()
	var vb: VehicleBody
	
	if have_vb == false:
		#print("have_vb == false")
		re_spawn = true
	else:
		vb = get_vehicle_body()  # get_viewport().get_node("vehicle_body")
		if vb.vehicle_state == ConfigVehicles.AliveState.DEAD:
			#print("vb.vehicle_state == ConfigVehicles.AliveState.DEAD")
			re_spawn = true
	
	if re_spawn:
		re_spawn = false
		if not get_parent().is_in_slow_motion():  # wait until the main scene finished any slow motion dying stuff
			#print("not get_parent().is_in_slow_motion()")
			#print("vehicle_state ="+str(vb.vehicle_state))
			#if vehicle_state == ConfigVehicles.AliveState.DYING:
			#print("Engine.time_scale="+str(Engine.time_scale))
			if StatePlayers.players[player_number]["lives_left"] > 0:
				#print("player: "+str(StatePlayers.players[player_number]["lives_left"])+" lives left, spawning...")
				re_spawn = true
				
	if re_spawn:
		#print("if re_spawn")
		if vb != null:
			#print("vb != null -> vb.queue_free()")
			#print("vb.vehicle_state == "+str(vb.vehicle_state))
			vb.queue_free()
		init_vehicle_body(last_spawn_point)


func has_vehicle_body() -> bool:
	for ch in get_viewport().get_children():
		if ch is VehicleBody:
			return true
	return false


func get_camera() -> Camera:
	return $VC/V/Camera as Camera
	
