extends Spatial


# Declare member variables here. Examples:
var timer = 0.0
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	for ch in get_children():
		if ch is Particles:
			ch.emitting = false
		if ch is OmniLight:
			ch.visible = false
		if ch is AudioStreamPlayer:
			ch.playing = false
		if 'Explosion_' in ch.name and ch is MeshInstance:
			ch.hide()
	pass


# start all the effects
func start_effects():
	for ch in get_children():
		if ch is Particles:
			ch.emitting = true
		if ch is OmniLight:
			ch.visible = true
		if ch is AudioStreamPlayer:
			# print("Found")
			ch.playing = true
		if 'Explosion_' in ch.name and ch is MeshInstance:
			ch.show()
			var ch2 = ch.get_node('AnimationPlayer')
			ch2.seek(0.0)
			ch2.play("Explode")


func effects_finished():
	for ch in get_children():
		if ch is Particles:
			if ch.emitting == true:
				return false
		if ch is AudioStreamPlayer:
			if ch.playing == true:
				return false
		if ch is MeshInstance:
			for ch2 in ch.get_children():
				if ch2 is AnimationPlayer:
					if ch2.is_playing():
						return false
	return true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timer += delta
	if timer > 0.2:
		$LightBlast.visible = false



func _on_TimerFailsafeDestroy_timeout():
	print("Warning: used TimerFailsafeDestroy for node "+self.name)
	queue_free()


