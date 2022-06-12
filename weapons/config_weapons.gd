extends Node

enum Type {
	MINE=0, 
	ROCKET=1, 
	MISSILE=2, 
	NUKE=3, 
	BALLISTIC=4,
	BOMB=5  # used for air-raids only
	}

const COOLDOWN_TIMER_DEFAULTS: Dictionary = {
	Type.MINE: 5.0, 
	Type.ROCKET: 5.0, 
	Type.MISSILE: 20.0, 
	Type.NUKE: 6.0, 
	Type.BALLISTIC: 10.0}

const DAMAGE: Dictionary = {
	Type.MINE: 1, 
	Type.ROCKET: 5, 
	Type.MISSILE: 5, 
	Type.NUKE: 10,
	Type.BALLISTIC: 5.0}
	
const DAMAGE_INDIRECT: Dictionary = {
	Type.MINE: {"damage": 1, "range": 10.0}, 
	Type.ROCKET: {"damage": 1, "range": 10.0}, 
	Type.MISSILE: {"damage": 1, "range": 10.0}, 
	Type.NUKE: {"damage": 5.0, "range": 10.0}, 
	Type.BALLISTIC: {"damage": 1, "range": 10.0}}
	
const SCENE: Dictionary = {
	Type.MINE: "res://weapons/explosive/explosive.tscn", \
	Type.ROCKET: "res://weapons/missile/missile.tscn", \
	Type.MISSILE: "res://weapons/missile/missile.tscn", \
	Type.NUKE: "res://weapons/explosive/explosive.tscn",
	Type.BALLISTIC: "res://weapons/missile/missile.tscn"}
	
const TARGET_SPEED: Dictionary = {
	Type.ROCKET: 10.0, 
	Type.MISSILE: 10.0, 
	Type.BALLISTIC: 20.0}

const MUZZLE_SPEED: Dictionary = {
	Type.ROCKET: 10.0, 
	Type.MISSILE: 10.0, 
	Type.BALLISTIC: 20.0}

# TODO move to vehicle config
var vehicle_weapons: Dictionary = {
	Type.MINE: [ConfigVehicles.Type.RACER],
	Type.ROCKET: [ConfigVehicles.Type.RACER, ConfigVehicles.Type.RALLY, ConfigVehicles.Type.TANK],
	Type.MISSILE: [ConfigVehicles.Type.RALLY, ConfigVehicles.Type.TANK, ConfigVehicles.Type.TRUCK],
	Type.NUKE: [],  # disabled initially, PowerUp enables it ."Racer", "Rally", "Tank", "Truck"]},
	Type.BALLISTIC: [ConfigVehicles.Type.TANK, ConfigVehicles.Type.TRUCK],
	Type.BOMB: []}

# explosion force = explosion_strength / (explosion_decrease*distance)+1.0 ^ explosion_exponent)
var explosion_strength: Dictionary = {
	Type.MINE: 2500.0, 
	Type.BOMB: 5000.0, 
	Type.NUKE: 10000.0}

var explosion_range: Dictionary = {
	Type.MINE: 10.0, 
	Type.BOMB: 10.0, 
	Type.NUKE: 1000.0}

var explosion_exponent: Dictionary = {
	Type.MINE: 1.5, 
	Type.BOMB: 1.5, 
	Type.NUKE: 1.05}

var explosion_decrease: Dictionary = {
	Type.MINE: 1.0, 
	Type.BOMB: 1.0, 
	Type.NUKE: 0.05}

const EXPLOSIVE_START_WAIT: float = 3.0  # wait time when first turned on to activation
const EXPLOSIVE_ACTIVE_WAIT: float = 1.0
const EXPLOSIVE_PROXIMITY_DISTANCE: float = 5.0
const FLASH_TIMER_WAIT: float = 0.25

enum ExplosiveStage {
	TURNED_ON=0,  # 0=turned on, 
	INACTIVE=1,  # 1=inactive waiting for timer to count to 0,
	ACTIVE=2,  # 2=active, 
	TRIGGERED=3,  # 3=triggered (car proximity), 
	EXPLODE=4  # 4=explode, 
	EFFECTS=5  # 5=animation and sound
}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
