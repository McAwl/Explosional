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
	$Visual/Light.visible = true
	$Visual/AnimationPlayer.play("Explode")
	$Audio/ExplosionSound.playing = true


func effects_finished() -> bool:
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
