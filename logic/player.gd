extends Spatial
class_name Player

var player_number: int
var timer_0_1_s: float = 0.1
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


func _process(delta):
	
	timer_0_1_s -= delta
	if timer_0_1_s <= 0.0:
		timer_0_1_s = 0.1
		
		# periodically check for a destroyed vehicle
		if get_viewport().has_node("vehicle_body"):
			var vb: VehicleBody = get_viewport().get_node("vehicle_body")
			if vb.vehicle_state == ConfigVehicles.AliveState.DEAD:
				vb.queue_free()
		else:
			if StatePlayers.players[player_number]["lives_left"] > 0:
				# print("player:_process() "+str(StatePlayers.players[player_number]["lives_left"])+" lives left, spawning...")
				init_vehicle_body(last_spawn_point)
		
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
	var vehicle_body: VehicleBody = load("res://scenes/vehicle_body.tscn").instance()
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
	if get_viewport().has_node("vehicle_body"):
		var vehicle_body: VehicleBody = get_viewport().get_node("vehicle_body")
		# if vehicle_body == null:
		#	print("Warning: vehicle_body="+str(vehicle_body)+", print_tree: ")
		#	print_tree()
		return vehicle_body
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

