extends RigidBody
class_name ExplodedVehiclePart

var timer_1_sec: float = 1.0
var timer_lifetime: float = 60.0
var max_lifetime: float = 60.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_lifetime(_max_lifetime) -> void:
	timer_lifetime = _max_lifetime
	max_lifetime = _max_lifetime
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	timer_1_sec -= delta
	timer_lifetime -= delta
	if timer_1_sec < 0.0:
		timer_1_sec = 1.0
		if has_node("smoke_trail") and rng.randf_range(0, 1.0) > (timer_lifetime/max_lifetime):
			if get_node("smoke_trail").amount > 1:
				get_node("smoke_trail").amount -= 1
				get_node("smoke_trail").emitting = true
			else:
				get_node("smoke_trail").emitting = false
		if rng.randf_range(0, 1.0) > (timer_lifetime/max_lifetime):
			print("av_lifetime_sec: vehicle mesh rigid body "+str(name)+"queue_free")
			queue_free()

