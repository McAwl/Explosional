extends RigidBody


export var muzzle_velocity = 5  #25
export var g = Vector3.DOWN * 1  # 20

var velocity = Vector3.ZERO
onready var lifetime_seconds = 2.0

	

func _process(delta):
	lifetime_seconds -= delta
	if lifetime_seconds < 0.0:
		queue_free()

func _physics_process(delta):
	velocity += g * delta
	look_at(transform.origin + velocity.normalized(), Vector3.UP)
	transform.origin += velocity * delta


