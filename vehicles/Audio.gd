extends Spatial


# Built-in methods

func _ready():
	pass # Replace with function body.


# Signal methods

func _on_TimerCheckSoundVolume_timeout():
	for ch in get_children():
		if ch is AudioStreamPlayer:
			ch.volume_db = Global.vehicle_sound_volume_db


func _on_TimerCheckSoundPitch_timeout():
	for asp in get_children():
		if asp is AudioStreamPlayer:
			if asp.name != "EngineSound":  # EngineSound checks this itself
				asp.pitch_scale = Engine.time_scale

