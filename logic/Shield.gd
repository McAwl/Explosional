extends Spatial


var rng = RandomNumberGenerator.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var rotation_speed = delta * 100.0
	$Outer_shell.rotation_degrees.x += rng.randf()*rotation_speed
	$Outer_shell.rotation_degrees.y += rng.randf()*rotation_speed
	$Outer_shell.rotation_degrees.z += rng.randf()*rotation_speed
	$Inner_cut.rotation_degrees.x += rng.randf()*rotation_speed
	$Inner_cut.rotation_degrees.y += rng.randf()*rotation_speed
	$Inner_cut.rotation_degrees.z += rng.randf()*rotation_speed
