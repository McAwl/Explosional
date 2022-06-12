extends HSlider


# Called when the node enters the scene tree for the first time.
func _ready():
	max_value = Global.VEHICLE_SOUND_MAX_VOLUME_DB
	value = Global.vehicle_sound_volume_db
