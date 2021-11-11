extends Spatial


# Called when the node enters the scene tree for the first time.
func _ready():
	var car
	for player_number in range(1,5):
		car = get_node("./InstancePos"+str(player_number))
		car = car.get_node("VC")  #+str(player_number))
		car = car.get_node("V")  #+str(player_number))
		car = car.get_node("CarBase")
		car = car.get_node("Body")
		car.player_number = player_number
