extends Spatial

var player_number
var lives_left = 3


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func init(_player_number, _number_players, _missile_homing):
	print("init")
	# Add a car to the player
	var carbase = load("res://scenes/car_base.tscn").instance()
	carbase.name = "CarBase"
	player_number = _player_number
	get_viewport().add_child(carbase)
	get_carbody().player_number = player_number
	get_carbody().missile_homing = _missile_homing
	set_label("Player: "+str(player_number)+" Lives: "+str(lives_left))

	
	name = "InstancePos"+str(player_number)
	
	if _number_players == 2:
		set_viewport_container_two()
	elif _number_players == 4:
		set_viewport_container_four()
	else:  # TODO
		set_viewport_container_four()


func set_viewport_container_two():
	if player_number == 1:
		set_viewport_container(0, 1920, 540, 0)
	elif player_number == 2:
		set_viewport_container(0, 1920, 1080, 540)


func set_viewport_container_four():
	if player_number == 1:
		set_viewport_container(0, 960, 540, 0)
	elif player_number == 2:
		set_viewport_container(960, 1920, 540, 0)
	elif player_number == 3:
		set_viewport_container(0, 960, 1080, 540)
	elif player_number == 4:
		set_viewport_container(960, 1920, 1080, 540)


func set_viewport_container(left, right, bottom, top):
	$VC.margin_left = left
	$VC.margin_right = right
	$VC.margin_bottom = bottom
	$VC.margin_top = top


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
	var carbody = get_carbase().get_node("Body")
	if carbody == null:
		print("Warning: carbody="+str(carbody)+", print_tree: ")
		print_tree()
	return carbody


func set_label(s):
	$VC.get_node( "CanvasLayer/Label").text = s


func set_global_transform_origin(o):
	get_carbody().global_transform.origin = o


func set_missile_homing(_missile_homing):
	get_carbody().missile_homing = _missile_homing


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
