extends Node


const COOLDOWN_TIMER_DEFAULTS: Dictionary = {"mine": 5.0, "rocket": 5.0, "missile": 20.0, "nuke": 60.0, "ballistic": 10.0}
# TODO some of these are being ignored, eg mine damage
const DAMAGE: Dictionary = {"mine": 1, "rocket": 5, "missile": 5, "nuke": 10, "ballistic": 5.0}
const DAMAGE_INDIRECT: Dictionary = {"mine": 1, "rocket": 1, "missile": 1, "nuke": 10, "ballistic": 1}
const SCENE: Dictionary = {"mine": "res://scenes/explosive.tscn", \
			   "rocket": "res://scenes/missile.tscn", \
			   "missile": "res://scenes/missile.tscn", \
			   "nuke": "res://scenes/explosive.tscn",
			   "ballistic": "res://scenes/missile.tscn"}
const TARGET_SPEED: Dictionary = {"rocket": 10.0, "missile": 10.0, "ballistic": 20.0}
const MUZZLE_SPEED: Dictionary = {"rocket": 10.0, "missile": 10.0, "ballistic": 20.0}
enum WEAPONS {MINE=0, ROCKET=1, MISSILE=2, NUKE=3, BALLISTIC=4}
var weapon_types: Dictionary = {WEAPONS.MINE: {"name": "mine", "vehicles": ["Racer"]}, \
					WEAPONS.ROCKET: {"name": "rocket", "vehicles": ["Racer", "Rally", "Tank"]}, \
					WEAPONS.MISSILE: {"name": "missile", "vehicles": ["Rally", "Tank", "Truck"]}, \
					WEAPONS.NUKE: {"name": "nuke", "vehicles": []},  # disabled initially, PowerUp enables it ."Racer", "Rally", "Tank", "Truck"]},
					WEAPONS.BALLISTIC: {"name": "ballistic", "vehicles": ["Tank", "Truck"]}}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
