extends Spatial

var real_bomb
var bomb_dropped = false
var bomb_exploded = false
var bomb_timer = 0.0
var print_timer = 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	# reset_car()
	# get_player().lives_left += 1
	pass


func set_label(new_label):
	get_node( "../../CanvasLayer/Label").text = new_label


func get_player():
	return get_parent().get_parent().get_parent()



func reset_car():
	print("reset_car()")
	get_player().lives_left -= 1
	if get_player().lives_left < 0:
		# get_parent().set_label("Player: "+str($Body.player_number)+" Game Over")
		visible = false
	else:
		get_player().set_label($CarBody.player_number, get_player().lives_left, $CarBody.total_damage, $CarBody.weapons[$CarBody.weapon_select], $CarBody.weapons[$CarBody.weapon_select].cooldown_timer, $CarBody.weapons[$CarBody.weapon_select].damage)
		$CarBody.global_transform.origin = get_player().get_parent().get_random_spawn_point()  # Vector3(0.0, 0.0, 0.0)
		$CarBody.linear_velocity = Vector3(0.0, 0.0, 0.0)
		$CarBody.speed = 0.0
		$CarBody.angular_velocity = Vector3(0.0, 0.0, 0.0)
		$CarBody.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	$CarBody.reset_vals()
	$CarBody.reset_car = false


func _process(delta):
	
	if $CarBody.global_transform.origin.y < -50.0:
		reset_car()
			
	print_timer += delta
