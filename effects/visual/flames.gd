extends Particles


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func emission_box_extents(vol: Vector3) -> void:
	self.process_material.emission_box_extents = vol


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
