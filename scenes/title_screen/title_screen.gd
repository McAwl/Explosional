extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var players

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Allow user to skip logo
func _input(event):
	if event is InputEventKey and event.pressed:  # not pressed=released
		change_scene()


func _on_Timer_timeout():
	change_scene()


func change_scene() -> void:
	var next_level_resource = load(Global.main_menu_scene)
	var next_level = next_level_resource.instance()
	next_level.game_active = false
	get_tree().root.call_deferred("add_child", next_level)
	next_level.configure()
	queue_free()
