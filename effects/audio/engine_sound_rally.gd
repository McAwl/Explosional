extends AudioStreamPlayer

var timer_0_1s: float = 0.1

# Define periods in the audio where specific events happen
export var gear_change_1: Array = [15.03, 15.46]
export var gear_change_2: Array = [45.6, 47.3]
export var increase_speed_1: Array = [16.1, 17.9]
export var increase_speed_2: Array = [10.8, 18.4]
export var slowing_down: Array = [28.0, 36.0]
export var stable_speed: Array = [87.0, 89.0]
export var idle: Array = [4.5, 6.9, 10.0]  # min / [medium spots] / max

var current_position_sec: float

var accel: float
var speed: float
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


var state = ConfigVehicles.SpeedState.IDLE

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if playing == true:
		timer_0_1s -= delta
		if timer_0_1s <= 0.0:
			timer_0_1s = 0.1
			current_position_sec = self.get_playback_position()
			speed = get_parent().get_parent().get_parent().fwd_mps_0_1_ewma
			pitch_scale = 0.5 + (0.2*((10.0+speed)/10.0))
			accel = get_parent().get_parent().get_parent().acceleration_fwd_0_1_ewma
			if current_position_sec < idle[0]:
				self.play(idle[0])
			else:
				if speed < 2.0:  # idle speed
					if current_position_sec > idle[2]:
						if rng.randf_range(0, 1.0) < 0.5:  # randomly seek idle bits of the audio so it sounds less repetitive
							self.play(idle[0])
						else:
							self.play(idle[1])
						if state != 0:
							slowly_increase_volume(0.25)
					state = ConfigVehicles.SpeedState.IDLE
				else:
					if accel != null:
						if accel >= 0.01:  # speeding up
							if current_position_sec < increase_speed_2[0] or current_position_sec > increase_speed_2[1]:
								if current_position_sec > increase_speed_2[1] and state == 2:
									self.play(gear_change_1[0])  # change back down to the gear change and repeat
								else:
									self.play(increase_speed_2[0])
								if state != 2:
									slowly_increase_volume(0.5)
								state = ConfigVehicles.SpeedState.SPEEDING_UP
						elif accel < -0.01:  # slowing down
							if current_position_sec < slowing_down[0] or current_position_sec > slowing_down[1]:
								self.play(slowing_down[0])
								if state != 3:
									slowly_increase_volume(0.5)
							state = ConfigVehicles.SpeedState.STABLE
						else:  # stable speed
							if current_position_sec < stable_speed[0] or current_position_sec > stable_speed[1]:
								self.play(stable_speed[0])
								if state != 1:
									slowly_increase_volume(0.5)
							state = ConfigVehicles.SpeedState.SLOWING_DOWN
					else:  # stable speed
						if current_position_sec < stable_speed[0] or current_position_sec > stable_speed[1]:
							self.play(stable_speed[0])
							if state != 1:
								slowly_increase_volume(0.5)
						state = ConfigVehicles.SpeedState.STABLE


func slowly_increase_volume(duration_sec) -> void:
	$Tween.interpolate_property(self, "volume_db", Global.vehicle_sound_volume_db, Global.vehicle_sound_volume_db+6.0, duration_sec, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	
