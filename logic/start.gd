extends Node

var players = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # $Button.connect("pressed", self, "_button_pressed")
	


func _on_ButtonAddPlayer1_pressed():
	 enable_name_textedit(1)


func _on_ButtonAddPlayer2_pressed():
	 enable_name_textedit(2)
	

func _on_ButtonAddPlayer3_pressed():
	 enable_name_textedit(3)
	
	
func _on_ButtonAddPlayer4_pressed():
	 enable_name_textedit(4)
	

func enable_name_textedit(player_num):
	if not str(player_num) in players:
		get_node("Player"+str(player_num)+"Name").readonly = false
	
	
func _process(_delta):
	if len($Player1Name.text) > 0:
		$ButtonAddPlayer1.disabled = true
		$ButtonAddPlayer2.disabled = false
		$StartButton.disabled = false
		players[1] = {"name": $Player1Name.text}
		if len($Player2Name.text) > 0:
			$ButtonAddPlayer2.disabled = true
			$ButtonAddPlayer3.disabled = false
			players[2] = {"name": $Player2Name.text}
			if len($Player3Name.text) > 0:
				$ButtonAddPlayer3.disabled = true
				$ButtonAddPlayer4.disabled = false
				players[3] = {"name": $Player3Name.text}
				if len($Player4Name.text) > 0:
					$ButtonAddPlayer4.disabled = true
					players[4] = {"name": $Player4Name.text}
			else:
				$ButtonAddPlayer4.disabled = true
		else:
			$ButtonAddPlayer3.disabled = true
	else:
		$ButtonAddPlayer2.disabled = true
		$StartButton.disabled = true

func _on_Button_pressed():
	var next_level_resource = load("res://scenes/town_scene.tscn")
	var next_level = next_level_resource.instance()
	next_level.players = players
	#next_level.load_saved_game = true
	get_tree().root.call_deferred("add_child", next_level)
	queue_free()
