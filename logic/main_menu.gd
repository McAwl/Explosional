extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var version
var active = false
var timer = 0.5
var game_active = false
var players = {}
var max_line_length = 12
var player_selection = -1
var vehicle_selection = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	var output = []
	var _os_execute = OS.execute("git", PoolStringArray(["rev-list", "--count", "HEAD"]), true, output)
	print(str(output))
	if output.empty() or output[0].empty():
		push_error("Failed to fetch version. Make sure you have git installed and project is inside valid git directory.")
	else:
		version = output[0].trim_suffix("\n")
		$VersionText/VersionContainer/VersionText.text = "Explosional! BETA v0.0.116 Build "+ version + " 2022 McAwl"
	configure().resume()


func configure():
	#var apb = $MainSelection/MainContainer/ButtonsContainer/HBoxContainer2/AddPlayerButton
	var qmmb = $MainSelection/MainContainer/ButtonsContainer/HBoxContainer2/QuitToMainMenuButton
	$VehicleSelection.hide()
	print("game_active="+str(game_active))
	if game_active:
		get_resume_button().show()
		qmmb.show()
		$PlayerSelection.hide()
		get_resume_button().grab_focus()
		get_start_button().hide()
		#apb.hide()
	else:
		$PlayerSelection/GridContainer/Player1SelectButton.text = "Player 1 Racer"
		players[1] = {"name": "1", "vehicle": "Racer"}
		get_start_button().show()
		#apb.show()
		$PlayerSelection.show()
		qmmb.hide()
		yield()
		get_start_button().grab_focus() 
		get_resume_button().hide()


func set_visible(_visibile):
	$MainSelection.visible = _visibile
	$VersionText.visible = _visibile


func pause():
	active = true
	set_visible(true)
	timer = 0.5
	$MainSelection/MainContainer/ButtonsContainer/HBoxContainer2/ResumeButton.grab_focus()
	# enable the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func resume():
	# hide the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	active = false
	set_visible(false)
	get_parent().get_parent().get_parent().is_game_paused = false  # main scene
	get_tree().paused = false


func _input(event):
	if active == true and timer <= 0.0:
		if event is InputEventKey and not event.pressed:  # not pressed=released
			print("event.scancode="+str(event.scancode))
			if event.scancode == KEY_ESCAPE or event.scancode == KEY_P:  # if Input.is_action_just_released("pause") or Input.is_action_pressed("back"):
				print("resuming..")
				resume()


func _process(delta):
	if timer > 0.0:
		timer -= delta


func _on_ResumeButton_button_up():
	print("resume button pressed")
	resume()
	pass # Replace with function body.


func _on_StartButton_button_down():
	print("start button pressed")
	$PlayerSelection.show()
	start_game()
	#resume()
	#get_parent().get_parent().get_parent().reset_game()


func _on_OptionsButton_button_up():
	print("options button pressed")
	$OptionMenu.show()
	$OptionMenu/GridContainer/Option1Button.grab_focus()
	$PlayerSelection.hide()
	$MainSelection/MainContainer/ButtonsContainer.hide()



func _on_OptionBackButton_button_up():
	$OptionMenu.hide()
	$MainSelection/MainContainer/ButtonsContainer.show()
	if game_active:
		get_resume_button().grab_focus()
		$PlayerSelection.hide()
	else:
		get_start_button().grab_focus()
		$PlayerSelection.show()


func start_game():
	#players[1] = {"name": "1", "vehicle": "racer"}
	#players[2] = {"name": "2", "vehicle": "racer"}
	#players[3] = {"name": "3", "vehicle": "racer"}
	#players[4] = {"name": "4", "vehicle": "racer"}
	# var next_level_resource = load("res://scenes/instructions.tscn")
	var next_level_resource = load("res://scenes/town_scene.tscn")
	var next_level = next_level_resource.instance()
	# next_level.players = players
	StatePlayers.players = players
	StatePlayers.configure_players()
	print("players = "+str(players))
	get_tree().root.call_deferred("add_child", next_level)
	queue_free()


func _on_AddPlayerButton_button_up():
	$PlayerSelection/GridContainer/Player1SelectButton.grab_focus()


func _on_QuitToDesktop_button_up():
	print("quit to desktop button pressed")
	get_tree().quit()


func _on_QuitToMainMenuButton_button_up():
	pass # Replace with function body.


func get_racer():
	return $VehicleSelection/GridContainer/RacerButton


func _on_Player1SelectButton_button_up():
	show_vehicle_selection(1)


func _on_Player2SelectButton_button_up():
	show_vehicle_selection(2)
	$PlayerSelection/GridContainer/Player3SelectButton.disabled = false


func _on_Player3SelectButton_button_up():
	show_vehicle_selection(3)
	$PlayerSelection/GridContainer/Player4SelectButton.disabled = false


func _on_Player4SelectButton_button_up():
	show_vehicle_selection(4)


func _on_RacerButton_button_up():
	hide_vehicle_selection("Racer")


func _on_RallyButton_button_up():
	hide_vehicle_selection("Rally")


func _on_TankButton_button_up():
	hide_vehicle_selection("Tank")


func _on_TruckButton_button_up():
	hide_vehicle_selection("Truck")
	

func hide_vehicle_selection(_vehicle_selection):
	vehicle_selection = _vehicle_selection
	$MainSelection/MainContainer.show()
	$PlayerSelection.show()
	$VehicleSelection.hide()
	$PlayerSelection/GridContainer.get_node("Player"+str(player_selection)+"SelectButton").text = "Player "+str(player_selection)+" "+str(vehicle_selection)
	players[player_selection] = {"name": str(player_selection), "vehicle": vehicle_selection}
	$PlayerSelection/GridContainer.get_node("Player"+str(player_selection)+"SelectButton").grab_focus()


func show_vehicle_selection(_player_selection):
	player_selection = _player_selection
	$MainSelection/MainContainer.hide()
	$PlayerSelection.hide()
	$VehicleSelection.show()
	get_racer().grab_focus()


func get_resume_button():
	return $MainSelection/MainContainer/ButtonsContainer/HBoxContainer2/ResumeButton


func get_start_button():
	return $MainSelection/MainContainer/ButtonsContainer/HBoxContainer2/StartButton
