extends HSlider


func _ready():
	max_value = Global.BACKGROUND_MUSIC_MAX_VOLUME_DB
	value = Global.background_music_volume_db
