extends Spatial

var town = null
var check_game_over_timer = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	var car
	for player_number in range(1,5):
		car = get_car_body(player_number)
		car.player_number = player_number
		get_node("./InstancePos"+str(player_number)+"/VC/CanvasLayer/Label").text = "Player "+str(player_number)+" Lives: 3"

		
func _process(delta):
	check_game_over_timer -= delta
	if Input.is_action_pressed("back"):
		reset_game()
	
	if check_game_over_timer < 0.0:
		var dead_cars = 0
		var num_cars = 0
		check_game_over_timer = 1.0
		for player_number in range(1,5):
			num_cars += 1
			var car = get_car_base(player_number)
			if car.lives_left < 0:
				dead_cars += 1
		if dead_cars >= (num_cars-1):
			
			reset_game()


func reset_game():
	var ret_val = get_tree().reload_current_scene()


func get_car_base(player_number):
	var car = get_node("./InstancePos"+str(player_number))
	car = car.get_node("VC")  #+str(player_number))
	car = car.get_node("V")  #+str(player_number))
	return car.get_node("CarBase")


func get_car_body(player_number):
	var car = get_car_base(player_number)
	return car.get_node("Body")
