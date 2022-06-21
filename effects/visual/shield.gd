extends Spatial
class_name Shield


var rng: RandomNumberGenerator = RandomNumberGenerator.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	#var rotation_speed: float = delta * 100.0
	#$GlowingSphere.rotation_degrees.x += rng.randf()*delta*30.0
	#$GlowingSphere.rotation_degrees.y += rng.randf()*delta*30.0
	#$GlowingSphere.rotation_degrees.z += rng.randf()*delta*30.0
	#$OuterShell.rotation_degrees.x += rng.randf()*rotation_speed
	#$OuterShell.rotation_degrees.y += rng.randf()*rotation_speed
	##InnerCut.rotation_degrees.y += rng.randf()*rotation_speed
	#$InnerCut.rotation_degrees.z += rng.randf()*rotation_speed
