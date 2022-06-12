extends AudioStreamPlayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var timer_0_1s: float = 0.1
var audio_max_speed_timer: float = 18.0  # time in track where maximum speed occurs, don't go past this
var audio_min_speed_timer: float = 10.0  # time in track where min speed occurs, start from this point
# var loop_duration = 0.5  # keep looping back this far

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if playing == true:
		timer_0_1s -= delta
		if timer_0_1s <= 0.0:
			timer_0_1s = 0.1
			# var speed = get_parent().get_parent().get_parent().get_speed()
			# var engine_force_value_ewma = get_parent().get_parent().get_parent().engine_force_ewma
			var speed: float = get_parent().get_parent().get_parent().get_speed()
			pitch_scale = 1.0 + (speed/30.0)
			#if engine_force_value_ewma != null:
			#	pitch_scale = 1.0 + engine_force_value_ewma/20.0

