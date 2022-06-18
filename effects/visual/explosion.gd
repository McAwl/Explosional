extends Spatial
class_name Explosion

# This explosion scene is meant to be instanced when the explosion is needed,
# not stored in any scenes

# Called when the node enters the scene tree for the first time.
func _ready():
	$Visual/Main.show()
	$Visual/Smoke.show()
	$Visual/Light.show()
	pass


# start all the effects
func start_effects(from_parent) -> void:
	reparent(from_parent)  
	$Visual/Smoke.emitting = true
	$Visual/Smoke.reparent($Visual)
	$Visual/Light.visible = true
	$Visual/AnimationPlayer.play("Explode")
	$Audio/ExplosionSound.playing = true


# We reparent the explosion so the parent weapon can destroy itself
# without worrying it will stop any effects
func reparent(from_parent: Node):
	var old_global_transform_origin = global_transform.origin
	var new_parent = get_tree().root.get_node("MainScene")
	from_parent.remove_child(self)
	new_parent.add_child(self)
	set_as_toplevel(true)
	global_transform.origin = old_global_transform_origin


func effects_finished() -> bool:
	if $Visual.has_node("Smoke"):
		if $Visual/Smoke.emitting == true:
			return false
	if $Visual/AnimationPlayer.is_playing():
		return false
	if $Audio/ExplosionSound.playing == true:
		return false
	return true


func _on_TimerFailsafeDestroy_timeout():
	print("Warning: used TimerFailsafeDestroy for node "+self.name+" parent="+str(get_parent().name))
	queue_free()