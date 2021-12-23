extends Spatial

var player_number
var player_name
var lives_left = 3


# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass


func init(_player_number, _number_players, _missile_homing, _player_name, pos=false):
	print("init")
	# Add a car to the player
	var carbase = load("res://scenes/car_base.tscn").instance()
	# carbase = load("res://scenes/trailer_truck.tscn").instance()
	carbase.name = "CarBase"
	player_number = _player_number
	player_name = _player_name
	get_viewport().add_child(carbase)
	get_carbody().player_number = player_number
	#get_carbody().missile_homing = _missile_homing
	if pos:
		get_carbody().global_transform.origin = pos
	set_label(player_number, lives_left, get_carbody().total_damage, get_carbody().weapons[get_carbody().weapon_select]["name"], get_carbody().cooldown_timer, get_carbody().weapons[get_carbody().weapon_select]["damage"])

	
	name = "InstancePos"+str(_player_number)
	print("_number_players="+str(_number_players))
	if _number_players == 1:
		set_viewport_container_one(_player_number)
	elif _number_players == 2:
		set_viewport_container_two(_player_number)
	elif _number_players == 3:
		set_viewport_container_three(_player_number)
	elif _number_players == 4:
		set_viewport_container_four(_player_number)
	else: 
		set_viewport_container_two(_player_number)


func set_viewport_container_one(_player_number):
	print("set_viewport_container_one():")
	print("player_number="+str(_player_number))
	if _player_number == 1:
		set_viewport_container(0, 0, 0, 0, 1920, 1080)


func set_viewport_container_two(_player_number):
	print("set_viewport_container_two():")
	print("player_number="+str(_player_number))
	if _player_number == 1:
		set_viewport_container(0, 0, 540, 0, 1920, 540)
	elif _player_number == 2:
		set_viewport_container(0, 0, 0, 540, 1920, 540)


func set_viewport_container_three(_player_number):
	print("set_viewport_container_three():")
	print("_player_number="+str(_player_number))
	if _player_number == 1:
		set_viewport_container(0, 960, 540, 0, 960, 540)
	elif _player_number == 2:
		set_viewport_container(960, 0, 540, 0, 960, 540)
	elif _player_number == 3:
		set_viewport_container(0, 0, 0, 540, 1920, 540)


func set_viewport_container_four(_player_number):
	print("set_viewport_container_four():")
	print("_player_number="+str(_player_number))
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
	get_label().margin_left = _left
	get_label().margin_right = 0
	# get_label().margin_bottom = 0
	get_label().margin_top = _top
	# get_label().rect_size.x = size_x
	# get_label().rect_size.y = size_y
	#print("LRTB="+str([_left, _right, _bottom, _top]))
	print("$VC margins LRBT="+str([$VC.margin_left, $VC.margin_right, $VC.margin_bottom, $VC.margin_top]))
	print("$VC.rect_size="+str($VC.rect_size))
	print("label rect_size="+str(get_label().rect_size))
	print("label align="+str(get_label().align))
	print("label LRBT="+str([get_label().margin_left, get_label().margin_right, get_label().margin_bottom, get_label().margin_top]))


func get_viewport_container():
	var vc = $VC
	if vc == null:
		print("Warning: vc="+str(vc)+", print_tree: ")
		print_tree()
	return vc

	
func get_viewport():
	var vp = get_viewport_container().get_node("V")
	if vp == null:
		print("Warning: vp="+str(vp)+", print_tree: ")
		print_tree()
	return vp


func get_carbase():
	var carbase = get_viewport().get_node("CarBase")
	if carbase == null:
		print("Warning: carbase="+str(carbase)+", print_tree: ")
		print_tree()
	return carbase

	
func get_carbody():
	var carbody = get_carbase().get_node("CarBody")
	if carbody == null:
		print("Warning: CarBody="+str(carbody)+", print_tree: ")
		print_tree()
	return carbody


func get_label():
	return $VC.get_node( "CanvasLayer/Label")

func air_strike_label():
	return $VC.get_node( "CanvasLayer/Label2")


func set_label2(s):
	get_label().text = s


func set_label(_player_number, _lives_left, player_damage, weapon, cooldown_timer, weapon_damage):
	#get_label().text = "Player:"+str(_player_number)+" Lives:"+str(_lives_left)+" Damage:"+str(player_damage)+" Weapon:"+str(weapon)+" Cooldown:"+str(cooldown_timer)+" Weapon Damage:"+str(weapon_damage)
	get_label().text = "Player"+str(_player_number)+":"+str(player_name)+" Lives:"+str(_lives_left)+" Damage:"+str(player_damage)+" Weapon:"+str(weapon)+" Cooldown:"+str(cooldown_timer)+" Weapon Damage:"+str(weapon_damage)

	

func set_global_transform_origin(o):
	get_carbody().global_transform.origin = o


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
