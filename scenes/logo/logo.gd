class_name LogoScene
extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var curr_app_size = get_tree().get_root().get_viewport().size
	var target_screen_size = OS.get_screen_size()
	print("current application  size="+str(curr_app_size))
	print("target screen size="+str(target_screen_size))
	if curr_app_size != target_screen_size:
		print("Resizing screen from "+str(curr_app_size)+" to "+str(target_screen_size))
		OS.set_window_size(target_screen_size)
	curr_app_size = get_tree().get_root().get_viewport().size


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
