class_name LogoScene
extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Allow user to skip logo
func _input(event):
	if event is InputEventKey and event.pressed:  # not pressed=released
		change_scene()


func _on_Timer_timeout():
	change_scene()


func change_scene():
	var next_level_resource = load(Global.title_screen_folder)
	var next_level = next_level_resource.instance()
	get_tree().root.call_deferred("add_child", next_level)
	queue_free()
