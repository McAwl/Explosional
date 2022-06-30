class_name Flame
extends Particles


func _ready():
	pass # Replace with function body.


func emission_box_extents(vol: Vector3) -> void:
	self.process_material.emission_box_extents = vol

