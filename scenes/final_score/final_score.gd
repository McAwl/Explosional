class_name FinalScore
extends Node2D


# Declare member variables here. Examples:
var player_winner_name


# Built-in methods

func _ready():
	$Label.text = "Player "+str(player_winner_name)+" wins!"
	Engine.time_scale = 1.0
	# hide the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _process(_delta):
	print("Engine.time_scale = "+str(Engine.time_scale))


# Signal methods

func _on_StartButton_pressed():
	reset_game()


func _on_TimerReset_timeout():
	reset_game()


# Public methods

func reset_game():
	queue_free()
	#var _ret_val = get_tree().change_scene("res://scenes/start.tscn")  #get_tree().reload_current_scene()
	var next_level_resource = load(Global.logo_scene_folder)
	var next_level = next_level_resource.instance() as LogoScene
	get_tree().root.call_deferred("add_child", next_level)
	get_tree().paused = false
	queue_free()

