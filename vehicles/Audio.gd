extends Spatial


# Built-in methods

func _ready():
	pass # Replace with function body.


# Signal methods

func _on_TimerCheckSoundVolume_timeout():
	for ch in get_children():
		if ch is AudioStreamPlayer:
			ch.volume_db = Global.vehicle_sound_volume_db

