extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var players

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _on_Timer_timeout():
	var next_level_resource = load("res://scenes/start.tscn")
	var next_level = next_level_resource.instance()
	get_tree().root.call_deferred("add_child", next_level)
	queue_free()
