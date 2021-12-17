extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # $Button.connect("pressed", self, "_button_pressed")
	


func _on_Button_pressed():
	var next_level_resource = load("res://scenes/town_scene.tscn")
	var next_level = next_level_resource.instance()
	next_level.num_players = int($TextEdit.text)
	#next_level.load_saved_game = true
	get_tree().root.call_deferred("add_child", next_level)
	queue_free()
