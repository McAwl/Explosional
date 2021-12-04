extends Spatial

var real_bomb
var bomb_dropped = false
var bomb_exploded = false
var bomb_timer = 0.0
var print_timer = 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func set_label(new_label):
	get_node( "../../CanvasLayer/Label").text = new_label


func get_player():
	return get_parent().get_parent().get_parent()


func reset_car():
	
	get_player().lives_left -= 1
	if get_player().lives_left < 0:
		get_parent().set_label("Player: "+str($Body.player_number)+" Game Over")
		visible = false
	else:
		get_player().set_label("Player: "+str($Body.player_number)+" Lives: "+str(get_player().lives_left))
		$Body.global_transform.origin = Vector3(54.0, 10.0, 60.0)
		$Body.linear_velocity = Vector3(0.0, 0.0, 0.0)
		$Body.speed = 0.0
		$Body.angular_velocity = Vector3(0.0, 0.0, 0.0)
		$Body.rotation_degrees = Vector3(0.0, 0.0, 0.0)


func _process(delta):
	
	if $Body.global_transform.origin.y < -50.0:
		reset_car()
			
	print_timer += delta
	if print_timer > 10.0:
		if $Body.player_number == 1:
			#print("player "+str($Body.player_number)+" bomb_timer="+str(bomb_timer))
			print("player "+str($Body.player_number)+" $Body.global_transform="+str($Body.global_transform))
		print_timer = 0.0
	

