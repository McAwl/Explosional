extends Spatial

var fake_bomb 
var real_bomb
var bomb_dropped = false
var bomb_exploded = false
var bomb_timer = 0.0
var print_timer = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	fake_bomb = $Body/Bomb


func reset_car():
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
			print("player "+str($Body.player_number)+" bomb_timer="+str(bomb_timer))
			print("player "+str($Body.player_number)+" $Body.global_transform="+str($Body.global_transform))
		print_timer = 0.0
	
	if real_bomb == null:
		real_bomb = get_node( "../../../../Bomb"+str($Body.player_number) )
		real_bomb.player_number = $Body.player_number
				
	if real_bomb.bomb_stage == 0:  # inactive
		
		if Input.is_action_pressed("bomb_player"+str($Body.player_number)):
			
			print("player "+str($Body.player_number)+" :")
			print("  fake_bomb.global_transform.origin = " +str(fake_bomb.global_transform.origin) )
			print("  real_bomb.global_transform.origin = "+ str( real_bomb.global_transform.origin ) )
			real_bomb.get_node("Body").global_transform.origin = fake_bomb.global_transform.origin  #.set_global_transform(fake_bomb.get_global_transform())
			real_bomb.get_node("Body").global_transform.origin[1] = real_bomb.get_node("Body").global_transform.origin[1]+2.0
			print("  real_bomb.global_transform.origin = "+str(real_bomb.global_transform.origin))
			real_bomb.bomb_stage = 1
			real_bomb.get_node("Body").visible = true
			
