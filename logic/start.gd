extends Node

var players = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func enable_name_textedit(player_num, player_linedit):
	get_node("Player"+str(player_num)+"Name").editable = true
	player_linedit.grab_focus()


func _process(_delta):
	
	if len(players)>0:
		$StartButton.disabled = false
		
	if len(players)==0 and Input.is_action_just_released("fire_player1"):
		enable_name_textedit(1, $Player1Name)
	if len(players)==1 and Input.is_action_just_released("fire_player2"):
		enable_name_textedit(2, $Player2Name)
	if len(players)==2 and Input.is_action_just_released("fire_player3"):
		enable_name_textedit(3, $Player3Name)
	if len(players)==3 and Input.is_action_just_released("fire_player4"):
		enable_name_textedit(4, $Player4Name)
		
	if len($Player1Name.text) > 0:
		players[1] = {"name": $Player1Name.text}
		if len($Player1Name.text) > 12:
			$Player1Name.editable = false
	if len($Player2Name.text) > 0:
		players[2] = {"name": $Player2Name.text}
		if len($Player2Name.text) > 12:
			$Player2Name.editable = false
	if len($Player3Name.text) > 0:
		players[3] = {"name": $Player3Name.text}
		if len($Player3Name.text) > 12:
			$Player3Name.editable = false
	if len($Player4Name.text) > 0:
		players[4] = {"name": $Player4Name.text}
		if len($Player4Name.text) > 12:
			$Player4Name.editable = false
			
	if len(players)>0 and Input.is_action_just_released("ui_select"):
		_on_Button_pressed()


func _on_Button_pressed():
	var next_level_resource = load("res://scenes/instructions.tscn")
	var next_level = next_level_resource.instance()
	next_level.players = players
	get_tree().root.call_deferred("add_child", next_level)
	queue_free()
