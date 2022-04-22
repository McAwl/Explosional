extends AudioStreamPlayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	playing = true
	volume_db = -9.0
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var s = get_parent().get_parent().get_parent().get_speed()
	pitch_scale = 1.0 + fmod(s, 10.0)/10.0
