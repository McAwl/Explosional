extends HSlider


func _ready():
	min_value = 0.0
	max_value = 2.0*Global.weather_model[Global.Weather.SNOW]["max_wind_strength"]
	value = Global.weather_model[Global.Weather.SNOW]["max_wind_strength"]


