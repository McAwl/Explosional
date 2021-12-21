extends Node

var players = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func enable_name_textedit(player_num):
	get_node("Player"+str(player_num)+"Name").readonly = false


func _process(_delta):
	
	if len(players)>0:
		$StartButton.disabled = false
		
	if len(players)==0 and Input.is_action_just_released("fire_player1"):
		enable_name_textedit(1)
	if len(players)==1 and Input.is_action_just_released("fire_player2"):
		enable_name_textedit(2)
	if len(players)==2 and Input.is_action_just_released("fire_player3"):
		enable_name_textedit(3)
	if len(players)==3 and Input.is_action_just_released("fire_player4"):
		enable_name_textedit(4)
		
	if len($Player1Name.text) > 0:
		players[1] = {"name": $Player1Name.text}
		if len($Player1Name.text) > 10:
			$Player1Name.readonly = true
	if len($Player2Name.text) > 0:
		players[2] = {"name": $Player2Name.text}
		if len($Player2Name.text) > 10:
			$Player2Name.readonly = true
	if len($Player3Name.text) > 0:
		players[3] = {"name": $Player3Name.text}
		if len($Player3Name.text) > 10:
			$Player3Name.readonly = true
	if len($Player4Name.text) > 0:
		players[4] = {"name": $Player4Name.text}
		if len($Player4Name.text) > 10:
			$Player4Name.readonly = true


func _on_Button_pressed():
	var next_level_resource = load("res://scenes/town_scene.tscn")
	var next_level = next_level_resource.instance()
	next_level.players = players
	#next_level.load_saved_game = true
	get_tree().root.call_deferred("add_child", next_level)
	queue_free()
