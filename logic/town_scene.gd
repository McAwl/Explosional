extends Spatial

var town = null
var check_game_over_timer = 1.0
var missile_homing = false
var num_players = 4


# Called when the node enters the scene tree for the first time.
func _ready():
	for player_number in range(1, num_players+1):
		var player_instance = load("res://scenes/player.tscn").instance()
		player_instance.init(player_number, num_players, missile_homing)
		#print("player_instance="+str(player_instance))
		#print("player_instance.get_body()="+str(player_instance.get_carbody()))
		player_instance.set_global_transform_origin($SpawnPoint.global_transform.origin)
		add_child(player_instance)


func get_players(ignore_player_number=false):
	var players_all = get_tree().get_nodes_in_group("player")  # 
	var players = []
	for player in players_all:  # range(1, num_players+1):
		if ignore_player_number == false:
			players.append(get_player(player.player_number))
		else:
			if ignore_player_number != player.player_number:
				players.append(get_player(player.player_number))
	return players


func get_player(player_number):
	return get_node("InstancePos"+str(player_number))
	

func get_bombs():
	return get_tree().get_nodes_in_group("bomb")
	

func _process(delta):
	
	if Input.is_action_pressed("missile_homing_toggle"):
		missile_homing = !missile_homing
		for player_number in range(1, num_players+1):
			get_player(player_number).set_missile_homing(missile_homing)
	
	
	check_game_over_timer -= delta
	if Input.is_action_pressed("back"):
		reset_game()
	
	if check_game_over_timer < 0.0:
		var dead_cars = 0
		var num_cars = 0
		check_game_over_timer = 1.0
		for player_number in range(1, num_players+1):
			num_cars += 1
			if get_player(player_number).lives_left < 0:
				dead_cars += 1
		if dead_cars >= (num_cars-1):
			
			reset_game()


func reset_game():
	var _ret_val = get_tree().reload_current_scene()

