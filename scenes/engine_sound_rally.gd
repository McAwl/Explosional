extends AudioStreamPlayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var timer_0_1s = 0.1
export var gear_change_1 = [15.03, 15.46]
export var gear_change_2 = [45.6, 47.3]
export var increase_speed_1 = [16.1, 17.9]
export var increase_speed_2 = [10.8, 18.4]
export var slowing_down = [28.0, 36.0]
export var stable_speed = [93.5, 96.3]
export var idle = [4.5, 6.9, 10.0]  # min / [medium spots] / max
var current_position_sec
# var engine_force
var speed
var old_speed
var speed_ewma
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	playing = true
	volume_db = 0.0  # -9.0
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	timer_0_1s -= delta
	if timer_0_1s <= 0.0:
		timer_0_1s = 0.1
		current_position_sec = self.get_playback_position()
		old_speed = speed 
		speed = get_parent().get_parent().get_parent().get_speed()
		if speed != null and old_speed != null:
			speed_ewma = (0.01*speed) + (0.99*old_speed)
			# pitch_scale = 1.0 + speed/10.0
			if current_position_sec < idle[0]:
				self.play(idle[0])
			else:
				if speed < 5.0:
					if current_position_sec > idle[2]:
						if rng.randf_range(0, 1.0) < 0.5:
							self.play(idle[0])
						else:
							self.play(idle[1])
				else:
					if speed/speed_ewma >= 1.0:
						# speeding up
						if current_position_sec < increase_speed_2[0] or current_position_sec > increase_speed_2[1]:
							self.play(increase_speed_2[0])
					elif speed/speed_ewma < 1.0:
						# slowing down
						if current_position_sec < slowing_down[0] or current_position_sec > slowing_down[1]:
							self.play(slowing_down[0])
					else:  # code this later when we hysteresis
						# stable speed
						if current_position_sec < stable_speed[0] or current_position_sec > stable_speed[1]:
							self.play(stable_speed[0])
