extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var version
var active = false
var timer = 0.5


# Called when the node enters the scene tree for the first time.
func _ready():
	var output = []
	OS.execute("git", PoolStringArray(["rev-list", "--count", "HEAD"]), true, output)
	print(str(output))
	if output.empty() or output[0].empty():
		push_error("Failed to fetch version. Make sure you have git installed and project is inside valid git directory.")
	else:
		version = output[0].trim_suffix("\n")
		$Control2/VersionContainer/VersionText.text = "Explosional! BETA v0.0.116 Build "+ version + " 2022 McAwl"


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_visible(_visibile):
	$Control.visible = _visibile
	$Control2.visible = _visibile


func pause():
	active = true
	set_visible(true)
	timer = 0.5
	$Control/MainContainer/ButtonsContainer/HBoxContainer2/ResumeButton.grab_focus()
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


func _on_StartButton_button_up():
	print("start button pressed")
	resume()
	get_parent().get_parent().get_parent().reset_game()


func _on_OptionsButton_button_up():
	print("options button pressed")


func _on_QuitButton_button_up():
	print("quit button pressed")
	get_tree().quit()


