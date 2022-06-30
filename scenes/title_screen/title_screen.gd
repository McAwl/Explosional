extends Node2D


var players


# Built-in methods

func _ready():
	pass


# Allow user to skip logo
func _input(event):
	if event is InputEventKey and event.pressed:  # not pressed=released
		_change_scene()


# Signal methods

func _on_Timer_timeout():
	_change_scene()


# Private methods

func _change_scene() -> void:
	var next_level_resource = load(Global.main_menu_scene)
	var next_level = next_level_resource.instance()
	next_level.game_active = false
	get_tree().root.call_deferred("add_child", next_level)
	next_level.configure()
	queue_free()


# Public methods


