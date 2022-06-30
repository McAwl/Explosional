class_name Speedometer
extends MarginContainer

const MIN_ROTATION = -180.0
const MAX_ROTATION = 52.0
# Built-in methods


func _ready():
	$Needle.rect_rotation = MIN_ROTATION
	show()


# Public methods

func update_dial(_speed_km_hr, _max_speed_km_hr):
	print("update_dial: _speed_km_hr="+str(_speed_km_hr)+", _max_speed_km_hr="+str(_max_speed_km_hr))
	if _speed_km_hr < 0:
		$Needle.rect_rotation = MIN_ROTATION
	elif _speed_km_hr > _max_speed_km_hr:
		$Needle.rect_rotation = MAX_ROTATION
	else:
		$Needle.rect_rotation = MIN_ROTATION + ((MAX_ROTATION-MIN_ROTATION)*(_speed_km_hr)/_max_speed_km_hr)
	$LabelMax.text = str(_max_speed_km_hr)

