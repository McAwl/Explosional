extends Node


var next_level_resource # = preload("res://scenes/main/main.tscn")

var build: String
var version: String
var active: bool = false
var timer: float = 0.5
var game_active: bool = false
var players: Dictionary = {}
var max_line_length: int = 12
var player_selection: int = -1
var vehicle_selection: int = -1 # ConfigVehicles.Type


# Built-in methods

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	next_level_resource = load(Global.main_scene)
	$LoadingText.hide()
	$OptionMenu.hide()
	$VersionText.show()
	$Instructions.hide()
	$Credits.hide()
	$MainSelection.show()
	$MainSelection/MainContainer.show()
	$MainSelection/MainContainer/ButtonsContainer.show()
	$MainSelection/MainContainer/ButtonsContainer/HBoxContainer2.show()
	$GameModeSelection.show()
	var output_build = []
	var output_version = []
	var _os_execute_build = OS.execute("git", PoolStringArray(["rev-list", "--count", "HEAD"]), true, output_build)
	var _os_execute_version = OS.execute("git", PoolStringArray(["describe", "--long", "--tags"]), true, output_version)
	#Global.debug_print(3, "output_build='"+str(output_build)+"'")
	#Global.debug_print(3, str(len(output_build)))
	#Global.debug_print(3, str(output_version))
	if output_build.empty() or output_build[0].empty():
		push_error("Failed to fetch version. Make sure you have git installed and project is inside valid git directory.")
	else:
		build = output_build[0].trim_suffix("\n")
	
	if output_version.empty() or output_version[0].empty():
		push_error("Failed to fetch tag. Make sure you have git installed and project is inside valid git directory.")
	else:
		version = output_version[0].trim_suffix("\n")
	
	if build == null or version == null:
		$VersionText/VersionContainer/VersionText.text = "Explosional v1.8.5-beta 2024 McAwl"
	else:
		if len(build) < 2 or len(version) < 2:
			$VersionText/VersionContainer/VersionText.text = "Explosional v1.8.5-beta 2024 McAwl" + str(len(version)) + " " + str(len(build))
		else:
			Global.debug_print(3, "version="+str(version)+", build="+str(build))
			Global.debug_print(3, "len version="+str(len(version))+", len build="+str(len(build)))
			$VersionText/VersionContainer/VersionText.text = "Explosional "+ version + " Build "+build+" 2024 McAwl" + str(len(version)) + " " + str(len(build))
	
	match Global.game_mode:
		Global.GameMode.COMPETITIVE:
			$GameModeSelection/CheckBox1Competitive.pressed = true
		Global.GameMode.PEACEFUL:
			$GameModeSelection/CheckBox2Peaceful.pressed = true
		Global.GameMode.TOUGH:
			$GameModeSelection/CheckBox3Tough.pressed = true

	
	if Global.build_options["vehicle_options"]["racer"] == false:
		$VehicleSelection/GridContainer/RacerButton.hint_tooltip = "disabled"
		$VehicleSelection/GridContainer/RacerButton.disabled = true
	
	if Global.build_options["vehicle_options"]["rally"] == false:
		$VehicleSelection/GridContainer/RallyButton.hint_tooltip = "disabled"
		$VehicleSelection/GridContainer/RallyButton.disabled = true
	
	if Global.build_options["vehicle_options"]["tank"] == false:
		$VehicleSelection/GridContainer/TankButton.hint_tooltip = "disabled"
		$VehicleSelection/GridContainer/TankButton.disabled = true
	
	if Global.build_options["vehicle_options"]["truck"] == false:
		$VehicleSelection/GridContainer/TruckButton.hint_tooltip = "disabled"
		$VehicleSelection/GridContainer/TruckButton.disabled = true
	
	configure().resume()


func _process(delta):
	if timer > 0.0:
		timer -= delta


func _input(event):
	if active == true and timer <= 0.0:
		if event is InputEventKey and not event.pressed:  # not pressed=released
			#Global.debug_print(3, "event.scancode="+str(event.scancode))
			if event.scancode == KEY_ESCAPE or event.scancode == KEY_P:  # if Input.is_action_just_released("pause") or Input.is_action_pressed("back"):
				#Global.debug_print(3, "resuming..")
				resume()


# Signal methods

func _on_ResumeButton_button_up():
	Global.debug_print(3, "resume button pressed")
	resume()
	pass # Replace with function body.


func _on_StartButton_button_down():
	Global.debug_print(3, "start button pressed")
	$PlayerSelection.show()
	start_game()


func _on_OptionsButton_button_up():
	Global.debug_print(3, "options button pressed")
	$OptionMenu.show()
	$OptionMenu/GridContainer/Option1Button.grab_focus()
	$PlayerSelection.hide()
	$GameModeSelection.hide()
	$MainSelection/MainContainer/ButtonsContainer.hide()
	$OptionMenu/GridContainer/MusicVolume/MusicVolume.grab_focus()




func _on_OptionBackButton_button_up():
	$OptionMenu.hide()
	$MainSelection/MainContainer/ButtonsContainer.show()
	if game_active:
		get_resume_button().grab_focus()
		$PlayerSelection.hide()
		$GameModeSelection.show()
	else:
		get_start_button().grab_focus()
		$PlayerSelection.show()
		$GameModeSelection.show()


func _on_AddPlayerButton_button_up():
	$PlayerSelection/GridContainer/Player1SelectButton.grab_focus()


func _on_QuitToDesktop_button_up():
	Global.debug_print(3, "quit to desktop button pressed")
	get_tree().quit()


func _on_ResetGameButton_button_up():
	get_tree().root.get_node("MainScene").reset_game()



func _on_Player1SelectButton_button_up():
	show_vehicle_selection(1)


func _on_Player2SelectButton_button_up():
	show_vehicle_selection(2)
	$PlayerSelection/GridContainer/Player3SelectButton.disabled = false
	$PlayerSelection/GridContainer/Player2SelectButton/SubLabel.text = "Player added. Click to change vehicle"
	$PlayerSelection/GridContainer/Player3SelectButton/SubLabel.text = "Click to add player"


func _on_Player3SelectButton_button_up():
	show_vehicle_selection(3)
	$PlayerSelection/GridContainer/Player4SelectButton.disabled = false
	$PlayerSelection/GridContainer/Player3SelectButton/SubLabel.text = "Player added. Click to change vehicle"
	$PlayerSelection/GridContainer/Player4SelectButton/SubLabel.text = "Click to add player"


func _on_Player4SelectButton_button_up():
	show_vehicle_selection(4)
	$PlayerSelection/GridContainer/Player4SelectButton/SubLabel.text = "Player added. Click to change vehicle"


func _on_RacerButton_button_up():
	if Global.build_options["vehicle_options"]["racer"] == true:
		hide_vehicle_selection(ConfigVehicles.Type.RACER)
	else:
		return

func _on_RallyButton_button_up():
	if Global.build_options["vehicle_options"]["rally"] == true:
		hide_vehicle_selection(ConfigVehicles.Type.RALLY)
	else:
		return


func _on_TankButton_button_up():
	if Global.build_options["vehicle_options"]["tank"] == true:
		hide_vehicle_selection(ConfigVehicles.Type.TANK)
	else:
		return


func _on_TruckButton_button_up():
	if Global.build_options["vehicle_options"]["truck"] == true:
		hide_vehicle_selection(ConfigVehicles.Type.TRUCK)
	else:
		return


func _on_MusicVolume_value_changed(value):
	Global.background_music_volume_db = value


func _on_VehicleVolume_value_changed(value):
	Global.vehicle_sound_volume_db = value


func _on_WindSpeed_value_changed(value):
	Global.weather_model[Global.Weather.FIRE_STORM]["max_wind_strength"] = value


func _on_CheckBox1Competitive_button_up():
	Global.game_mode = Global.GameMode.COMPETITIVE
	$GameModeSelection/CheckBox2Peaceful.pressed = false
	$GameModeSelection/CheckBox3Tough.pressed = false


func _on_CheckBox2Peaceful_button_up():
	Global.game_mode = Global.GameMode.PEACEFUL
	$GameModeSelection/CheckBox1Competitive.pressed = false
	$GameModeSelection/CheckBox3Tough.pressed = false


func _on_CheckBox3Tough_button_up():
	Global.game_mode = Global.GameMode.TOUGH
	$GameModeSelection/CheckBox1Competitive.pressed = false
	$GameModeSelection/CheckBox2Peaceful.pressed = false


# Private methods


# Public methods

func configure():
	#var apb = $MainSelection/MainContainer/ButtonsContainer/HBoxContainer2/AddPlayerButton
	var qmmb = $MainSelection/MainContainer/ButtonsContainer/HBoxContainer2/ResetGameButton
	$VehicleSelection.hide()
	#Global.debug_print(3, "game_active="+str(game_active))
	if game_active:
		get_resume_button().show()
		qmmb.show()
		$MainSelection.show()
		$MainSelection/MainContainer/ButtonsContainer.show()
		$MainSelection/MainContainer/TitleContainer.show()
		$PlayerSelection.hide()
		#$LoadingText.hide()
		get_resume_button().grab_focus()
		get_start_button().hide()
		#apb.hide()

	else:
		$PlayerSelection/GridContainer/Player1SelectButton.text = "Player 1 "+ConfigVehicles.nice_name[ConfigVehicles.Type.RACER]
		players[1] = {"name": "1", "vehicle": ConfigVehicles.Type.RACER}
		get_start_button().show()
		
		$MainSelection.show()
		$MainSelection/MainContainer/ButtonsContainer.show()
		$MainSelection/MainContainer/TitleContainer.show()
		#apb.show()
		$PlayerSelection.show()
		qmmb.hide()
		yield()
		get_start_button().grab_focus() 
		get_resume_button().hide()


func set_visible(_visibile) -> void:
	$MainSelection.visible = _visibile
	$VersionText.visible = _visibile
	$GameModeSelection.visible = _visibile


func pause() -> void:
	active = true
	set_visible(true)
	timer = 0.5
	$MainSelection/MainContainer/ButtonsContainer/HBoxContainer2/ResumeButton.grab_focus()
	# enable the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func resume() -> void:
	# hide the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	active = false
	set_visible(false)
	get_parent().get_parent().get_parent().is_game_paused = false  # main scene
	get_tree().paused = false


func start_game() -> void:
	
	$LoadingText.show()
	#$MainSelection/MainContainer.hide()
	$PlayerSelection.hide()
	$GameModeSelection.hide()
	yield(get_tree().create_timer(1),"timeout")
	var next_level = next_level_resource.instance()
	StatePlayers.players = players
	StatePlayers.configure_players()
	Global.debug_print(3, "main_menu:start_game(): players = "+str(players))
	get_tree().root.call_deferred("add_child", next_level)
	Global.debug_print(3, "main_menu:start_game(): get_tree().root.call_deferred", "scenes")
	queue_free()


func get_racer() -> Button:
	return $VehicleSelection/GridContainer/RacerButton as Button


func hide_vehicle_selection(_vehicle_selection: int) -> void:
	vehicle_selection = _vehicle_selection
	$MainSelection/MainContainer.show()
	$GameModeSelection.show()
	$PlayerSelection.show()
	$VehicleSelection.hide()
	$PlayerSelection/GridContainer.get_node("Player"+str(player_selection)+"SelectButton").text = "Player "+str(player_selection)+" "+str(ConfigVehicles.nice_name[vehicle_selection])
	players[player_selection] = {"name": str(player_selection), "vehicle": vehicle_selection}
	$PlayerSelection/GridContainer.get_node("Player"+str(player_selection)+"SelectButton").grab_focus()
	Global.debug_print(0, "hide_vehicle_selection(): _vehicle_selection="+str(_vehicle_selection))
	

func show_vehicle_selection(_player_selection: int) -> void:
	player_selection = _player_selection
	$MainSelection/MainContainer.hide()
	$GameModeSelection.hide()
	$PlayerSelection.hide()
	$VehicleSelection.show()
	get_racer().grab_focus()


func get_resume_button() -> Button:
	return $MainSelection/MainContainer/ButtonsContainer/HBoxContainer2/ResumeButton as Button


func get_start_button() -> Button:
	return $MainSelection/MainContainer/ButtonsContainer/HBoxContainer2/StartButton as Button


func _on_InstructionsButton_button_up():
	$Instructions.visible = true
	$MainSelection/MainContainer/ButtonsContainer.hide()
	$GameModeSelection.hide()
	$PlayerSelection.hide()
	$VehicleSelection.hide()


func _on_InstructionsBackButton_button_up():
	$Instructions.hide()
	$MainSelection/MainContainer/ButtonsContainer.show()
	$GameModeSelection.show()
	$PlayerSelection.show()
	$VehicleSelection.hide()


func _on_CreditsButton_button_up():
	$Credits.show()
	$Instructions.hide()
	$MainSelection/MainContainer/ButtonsContainer.hide()
	$GameModeSelection.hide()
	$PlayerSelection.hide()
	$VehicleSelection.hide()


func _on_CreditsBackButton_button_up():
	$Credits.hide()
	$Instructions.hide()
	$MainSelection/MainContainer/ButtonsContainer.show()
	$GameModeSelection.show()
	$PlayerSelection.show()
	$VehicleSelection.hide()
