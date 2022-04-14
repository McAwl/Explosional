extends Spatial

var player_number
var number_players
var player_name
var lives_left = 3
var timer_0_1_s = 0.1
var last_spawn_point

# Called when the node enters the scene tree for the first time.
func _ready():
	$VC/V/CanvasLayer/icon_mine.visible = true
	$VC/V/CanvasLayer/icon_rocket.visible = false
	$VC/V/CanvasLayer/icon_missile.visible = false
	$VC/V/CanvasLayer/icon_nuke.visible = false
	$VC/V/CanvasLayer/health.tint_progress = "#7e00ff00"  # green


func reset_health():
	$VC/V/CanvasLayer/health.value = get_vehicle_body().max_damage
	$VC/V/CanvasLayer/health.tint_progress = "#7e00ff00"  # green


func _process(delta):
	
	timer_0_1_s -= delta
	if timer_0_1_s <= 0.0:
		timer_0_1_s = 0.1
		
		# periodically check for a destroyed vehicle
		if get_viewport().has_node("vehicle_body"):
			var vb = get_viewport().get_node("vehicle_body")
			if vb.vehicle_state == "dead":
				vb.queue_free()
		else:
			if lives_left > 0:
				print("player:_process() "+str(lives_left)+" lives left, spawning...")
				init_vehicle_body(last_spawn_point)
		
		# periodically update player display
		set_label_player_name()
		set_label_lives_left()
		var health_display = get_canvaslayer().get_node("health")
		health_display.value = get_vehicle_body().max_damage-get_vehicle_body().total_damage
		if get_vehicle_body().max_damage-get_vehicle_body().total_damage >= 7.0:
			health_display.tint_progress = "#7e00ff00"  # green
		elif get_vehicle_body().max_damage-get_vehicle_body().total_damage <= 3.0:
			health_display.tint_progress = "#7eff0000"  # red
		else:
			health_display.tint_progress = "#7eff6c00"  # orange


func init(_player_number, _number_players, _player_name, pos=null):
	last_spawn_point = pos
	number_players = _number_players
	print("player:init()")
	
	player_number = _player_number
	player_name = _player_name
	
	# Add a vehicle to the player
	init_vehicle_body(pos)
	
	set_label_player_name()
	set_label_lives_left()

	name = "Player"+str(_player_number)
	# print("_number_players="+str(_number_players))
	if number_players == 1:
		set_viewport_container_one(_player_number)
	elif number_players == 2:
		set_viewport_container_two(_player_number)
	elif number_players == 3:
		set_viewport_container_three(_player_number)
	elif number_players == 4:
		set_viewport_container_four(_player_number)
	else: 
		set_viewport_container_two(_player_number)


func init_vehicle_body(pos):
	var vehicle_body = load("res://scenes/vehicle_body.tscn").instance()
	# vehicle_body = load("res://scenes/trailer_truck.tscn").instance()
	vehicle_body.init(pos, player_number, "vehicle_body")
	get_viewport().add_child(vehicle_body)
	

func set_viewport_container_one(_player_number):
	# print("set_viewport_container_one():")
	# print("player_number="+str(_player_number))
	if _player_number == 1:
		set_viewport_container(0, 0, 0, 0, 1920, 1080)


func set_viewport_container_two(_player_number):
	# print("set_viewport_container_two():")
	# print("player_number="+str(_player_number))
	if _player_number == 1:
		set_viewport_container(0, 0, 540, 0, 1920, 540)
	elif _player_number == 2:
		set_viewport_container(0, 0, 0, 540, 1920, 540)


func set_viewport_container_three(_player_number):
	# print("set_viewport_container_three():")
	# print("_player_number="+str(_player_number))
	if _player_number == 1:
		set_viewport_container(0, 960, 540, 0, 960, 540)
	elif _player_number == 2:
		set_viewport_container(960, 0, 540, 0, 960, 540)
	elif _player_number == 3:
		set_viewport_container(0, 0, 0, 540, 1920, 540)


func set_viewport_container_four(_player_number):
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


func set_viewport_container(_left, _right, _bottom, _top, size_x, size_y):
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


func get_viewport_container():
	if has_node("VC"):
		return $VC
	else:
		print("Warning: no VC, print_tree: ")
		print_tree()
		return null

	
func get_viewport():
	if get_viewport_container() != null:
		if get_viewport_container().has_node("V"):
			return get_viewport_container().get_node("V")
		else:
			print("Warning: no V, print_tree: ")
			print_tree()
			return null
	else:
		return null

	
func get_vehicle_body():
	if get_viewport().has_node("vehicle_body"):
		var vehicle_body = get_viewport().get_node("vehicle_body")
		# if vehicle_body == null:
		#	print("Warning: vehicle_body="+str(vehicle_body)+", print_tree: ")
		#	print_tree()
		return vehicle_body
	return null


func get_label_player_name():
	return $VC/V/CanvasLayer/label_player_name


func get_label_lives_left():
	return $VC/V/CanvasLayer/label_lives_left


func get_canvaslayer():
	return $VC/V/CanvasLayer


func set_label_player_name():
	get_label_player_name().text = "Player"+str(player_number)+": "+str(player_name)


func set_label_lives_left():
	get_label_lives_left().text = str(lives_left)
	

func set_global_transform_origin(o):
	get_vehicle_body().global_transform.origin = o

