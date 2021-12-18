extends Spatial

var town = null
var check_game_over_timer = 1.0
var missile_homing = false
var num_players
var players
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	num_players = len(players)
	var spawn_points = get_spawn_points()
	for player_number in range(1, num_players+1):
		var player_instance = load("res://scenes/player.tscn").instance()
		var pos = spawn_points[player_number-1].global_transform.origin
		player_instance.init(player_number, num_players, missile_homing, players[player_number]["name"], pos)
		add_child(player_instance)


func get_spawn_points():
	return get_node("SpawnPoints").get_children()


func get_random_spawn_point():
	var spawn_points = get_spawn_points()
	return spawn_points[randi() % spawn_points.size()].global_transform.origin
	
	
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


func reset_game():
	queue_free()
	var _ret_val = get_tree().change_scene("res://scenes/start.tscn")  #get_tree().reload_current_scene()


