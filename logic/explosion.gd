extends Spatial
class_name Explosion

# This explosion scene is meant to be instanced when the explosion is needed,
# not stored in any scenes

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# start all the effects
func start_effects() -> void:
	$Visual/Smoke.emitting = true
	reparent($Visual, $Visual/Smoke)
	$Visual/Light.visible = true
	$Visual/AnimationPlayer.play("Explode")
	$Audio/ExplosionSound.playing = true


# Reparent the smoke so the explosion can be deleted
func reparent(parent: Node, child: Node) -> void:
	var old_global_transform_origin = child.global_transform.origin
	parent.remove_child(child)
	get_tree().root.get_node("MainScene").add_child(child)
	child.set_as_toplevel(true)
	child.global_transform.origin = old_global_transform_origin


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
