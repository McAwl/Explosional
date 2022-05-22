extends Node


const COOLDOWN_TIMER_DEFAULTS = {"mine": 1.0, "rocket": 1.0, "missile": 1.0, "nuke": 10.0, "ballistic": 1.0}
const DAMAGE = {"mine": 2, "rocket": 5, "missile": 5, "nuke": 10, "ballistic": 5.0}
const DAMAGE_INDIRECT = {"mine": 1, "rocket": 1, "missile": 1, "nuke": 10, "ballistic": 1}
const SCENE = {"mine": "res://scenes/explosive.tscn", \
			   "rocket": "res://scenes/missile.tscn", \
			   "missile": "res://scenes/missile.tscn", \
			   "nuke": "res://scenes/explosive.tscn",
			   "ballistic": "res://scenes/missile.tscn"}
const TARGET_SPEED = {"rocket": 10.0, "missile": 10.0, "ballistic": 20.0}
const MUZZLE_SPEED = {"rocket": 10.0, "missile": 10.0, "ballistic": 20.0}

var weapon_types = {0: {"name": "mine"}, \
					1: {"name": "rocket"}, \
					2: {"name": "missile"}, \
					3: {"name": "nuke"},
					4: {"name": "ballistic"}}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
