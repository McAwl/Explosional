extends Node2D
class_name FinalScore


# Declare member variables here. Examples:
var player_winner_name


# Called when the node enters the scene tree for the first time.
func _ready():
	$Label.text = "Player "+str(player_winner_name)+" wins!"


func reset_game():
	queue_free()
	var _ret_val = get_tree().change_scene("res://scenes/start.tscn")  #get_tree().reload_current_scene()


func _on_StartButton_pressed():
	reset_game()
