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


func effects_finished():
	for ch in get_children():
		if ch is Particles:
			if ch.emitting == true:
				return false
		if ch is AudioStreamPlayer:
			if ch.playing == true:
				return false
	return true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timer += delta
	if timer > 0.2:
		$LightBlast.visible = false

