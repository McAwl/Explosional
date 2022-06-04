extends Node


const COOLDOWN_TIMER_DEFAULTS = {"mine": 5.0, "rocket": 5.0, "missile": 20.0, "nuke": 60.0, "ballistic": 10.0}
# TODO some of these are being ignored, eg mine damage
const DAMAGE = {"mine": 1, "rocket": 5, "missile": 5, "nuke": 10, "ballistic": 5.0}
const DAMAGE_INDIRECT = {"mine": 1, "rocket": 1, "missile": 1, "nuke": 10, "ballistic": 1}
const SCENE = {"mine": "res://scenes/explosive.tscn", \
			   "rocket": "res://scenes/missile.tscn", \
			   "missile": "res://scenes/missile.tscn", \
			   "nuke": "res://scenes/explosive.tscn",
			   "ballistic": "res://scenes/missile.tscn"}
const TARGET_SPEED = {"rocket": 10.0, "missile": 10.0, "ballistic": 20.0}
const MUZZLE_SPEED = {"rocket": 10.0, "missile": 10.0, "ballistic": 20.0}

var weapon_types = {0: {"name": "mine", "vehicles": ["Racer"]}, \
					1: {"name": "rocket", "vehicles": ["Racer", "Rally", "Tank"]}, \
					2: {"name": "missile", "vehicles": ["Rally", "Tank", "Truck"]}, \
					3: {"name": "nuke", "vehicles": ["Racer", "Rally", "Tank", "Truck"]},
					4: {"name": "ballistic", "vehicles": ["Tank", "Truck"]}}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
