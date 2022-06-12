extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var players

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
func _on_Timer_timeout():
	var next_level_resource = load("res://scenes/town_scene.tscn")
	var next_level = next_level_resource.instance()
	next_level.players = players
	get_tree().root.call_deferred("add_child", next_level)
	queue_free()
