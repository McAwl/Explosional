extends Spatial

var player_number
var number_players
var player_name
var lives_left = 3

var vehicle_types = {	"tank":  {"scene": "res://scenes/vehicle_tank.tscn", 
									"engine_force_value": 40, 
									"mass_kg/100": 200.0, 
									"suspension_stiffness": 100.0, 
									"suspension_travel": 0.1,
									"radius_wheel_m": 0.35,
									"four_wheel_drive": true}, 
						"racer": {"scene": "res://scenes/vehicle_racer.tscn", 
									"engine_force_value": 130, 
									"mass_kg/100": 70.0, 
									"suspension_stiffness": 75.0, 
									"suspension_travel": 0.5,
									"radius_wheel_m": 0.25,
									"four_wheel_drive": false}, 
						"rally": {"scene": "res://scenes/vehicle_rally.tscn", 
									"engine_force_value": 35, 
									"mass_kg/100": 50.0, 
									"suspension_stiffness": 40.0, 
									"suspension_travel": 2.0,
									"radius_wheel_m": 0.4,
									"four_wheel_drive": true}, 
						"truck": {"scene": "res://scenes/vehicle_truck.tscn", 
									"engine_force_value": 60, 
									"mass_kg/100": 300.0, 
									"suspension_stiffness": 90.0, 
									"suspension_travel":0.2,
									"radius_wheel_m": 0.4,
									"four_wheel_drive": false}}
var vehicle_type = "racer"

# Called when the node enters the scene tree for the first time.
func _ready():
	$VC/V/CanvasLayer/icon_mine.visible = true
	$VC/V/CanvasLayer/icon_rocket.visible = false
	$VC/V/CanvasLayer/icon_missile.visible = false
	$VC/V/CanvasLayer/icon_nuke.visible = false
	$VC/V/CanvasLayer/health.tint_progress = "#7e00ff00"  # green


#func _process(delta):
	


func reset_health():
	$VC/V/CanvasLayer/health.value = get_carbody().max_damage
	$VC/V/CanvasLayer/health.tint_progress = "#7e00ff00"  # green
	
	
func init(_player_number, _number_players, _player_name, pos=null):
	number_players = _number_players
	# print("init")
	# Add a car to the player
	var carbase = load("res://scenes/car_base.tscn").instance()
	# carbase = load("res://scenes/trailer_truck.tscn").instance()
	carbase.name = "CarBase"
	player_number = _player_number
	player_name = _player_name
	get_viewport().add_child(carbase)
	get_carbody().player_number = player_number
	
	if player_number == 1:
		vehicle_type = "racer"
	elif player_number == 2:
		vehicle_type = "rally"
	elif player_number == 3:
		vehicle_type = "tank"
	elif player_number == 4:
		vehicle_type = "truck"
	
	var vehicle = load(vehicle_types[vehicle_type]["scene"]).instance()
	var pvl = vehicle.get_node("positions").get_node("lights")
	var vehicle_light_positions = [pvl.get_node("headlight_right").transform.origin, 
									pvl.get_node("headlight_left").transform.origin, 
									pvl.get_node("taillight_right").transform.origin, 
									pvl.get_node("taillight_left").transform.origin]
	vehicle.name = "vehicle_mesh"
	get_carbody().engine_force_value = vehicle_types[vehicle_type]["engine_force_value"]
	get_carbody().mass = vehicle_types[vehicle_type]["mass_kg/100"]
	
	get_carbody().get_wheel(1).suspension_stiffness = vehicle_types[vehicle_type]["suspension_stiffness"]
	get_carbody().get_wheel(1).suspension_travel = vehicle_types[vehicle_type]["suspension_travel"]
	get_carbody().get_wheel(1).wheel_radius = vehicle_types[vehicle_type]["radius_wheel_m"]
	get_carbody().get_wheel(1).get_node("Wheel1").scale = Vector3(vehicle_types[vehicle_type]["radius_wheel_m"], vehicle_types[vehicle_type]["radius_wheel_m"]/4.0, vehicle_types[vehicle_type]["radius_wheel_m"])
	
	get_carbody().get_wheel(2).suspension_stiffness = vehicle_types[vehicle_type]["suspension_stiffness"]
	get_carbody().get_wheel(2).suspension_travel = vehicle_types[vehicle_type]["suspension_travel"]
	get_carbody().get_wheel(2).wheel_radius = vehicle_types[vehicle_type]["radius_wheel_m"]
	get_carbody().get_wheel(2).get_node("Wheel2").scale = Vector3(vehicle_types[vehicle_type]["radius_wheel_m"], vehicle_types[vehicle_type]["radius_wheel_m"]/4.0, vehicle_types[vehicle_type]["radius_wheel_m"])
		
	get_carbody().get_wheel(3).suspension_stiffness = vehicle_types[vehicle_type]["suspension_stiffness"]
	get_carbody().get_wheel(3).suspension_travel = vehicle_types[vehicle_type]["suspension_travel"]
	get_carbody().get_wheel(3).wheel_radius = vehicle_types[vehicle_type]["radius_wheel_m"]
	get_carbody().get_wheel(3).get_node("Wheel3").scale = Vector3(vehicle_types[vehicle_type]["radius_wheel_m"], vehicle_types[vehicle_type]["radius_wheel_m"]/4.0, vehicle_types[vehicle_type]["radius_wheel_m"])
	
	get_carbody().get_wheel(4).suspension_stiffness = vehicle_types[vehicle_type]["suspension_stiffness"]
	get_carbody().get_wheel(4).suspension_travel = vehicle_types[vehicle_type]["suspension_travel"]
	get_carbody().get_wheel(4).wheel_radius = vehicle_types[vehicle_type]["radius_wheel_m"]
	get_carbody().get_wheel(4).get_node("Wheel4").scale = Vector3(vehicle_types[vehicle_type]["radius_wheel_m"], vehicle_types[vehicle_type]["radius_wheel_m"]/4.0, vehicle_types[vehicle_type]["radius_wheel_m"])
	
	if vehicle_types[vehicle_type]["four_wheel_drive"] == false:
		get_carbody().get_wheel(2).use_as_traction = false
		get_carbody().get_wheel(4).use_as_traction = false
		
	get_carbody().add_child(vehicle)
	get_carbody().set_light_positions(vehicle_light_positions)

	if pos != null:
		get_carbody().set_global_transform_origin(pos)
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
	# print("label LRBT="+str([get_label().margin_left, get_label().margin_right, get_label().margin_bottom, get_label().margin_top]))


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
	get_carbody().global_transform.origin = o

