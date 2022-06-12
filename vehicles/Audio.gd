extends Spatial


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_TimerCheckSoundVolume_timeout():
	for ch in get_children():
		if ch is AudioStreamPlayer:
			ch.volume_db = Global.vehicle_sound_volume_db

