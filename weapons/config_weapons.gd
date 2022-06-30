extends Node


enum Type {
	MINE=0, 
	ROCKET=1, 
	MISSILE=2, 
	NUKE=3, 
	BALLISTIC=4,
	BOMB=5,  # used for air-raids only
	BALLISTIC_MISSILE=6,
	}

enum ExplosiveStage {
	TURNED_ON=0,  # 0=turned on, 
	INACTIVE=1,  # 1=inactive waiting for timer to count to 0,
	ACTIVE=2,  # 2=active, 
	TRIGGERED=3,  # 3=triggered (car proximity), 
	EXPLODE=4  # 4=explode, 
	EFFECTS=5  # 5=animation and sound
}

enum PowerupType {
	NUKE=1, 
	SHIELD=2,
	HEALTH=3
	}
	
const COOLDOWN_TIMER_DEFAULTS: Dictionary = {
	Type.MINE: 10.0, 
	Type.ROCKET: 20.0, 
	Type.MISSILE: 30.0, 
	Type.NUKE: 60.0, 
	Type.BALLISTIC: 10.0,
	Type.BALLISTIC_MISSILE: 30.0}

const EXPLOSIVE_START_WAIT: float = 3.0  # wait time when first turned on to activation
const EXPLOSIVE_ACTIVE_WAIT: float = 1.0
const EXPLOSIVE_PROXIMITY_DISTANCE: float = 5.0
const FLASH_TIMER_WAIT: float = 0.25

# TODO remove this, if we want to completely move to damage due to force (acceleration)
const DAMAGE: Dictionary = {
	Type.MINE: 1, 
	Type.ROCKET: 5, 
	Type.MISSILE: 5, 
	Type.NUKE: 10,
	Type.BALLISTIC: 5.0,
	Type.BALLISTIC_MISSILE: 10.0}

# TODO remove this, if we want to completely move to damage due to force (acceleration)
const DAMAGE_INDIRECT: Dictionary = {
	Type.MINE: {"damage": 0, "range": 10.0},  # does this make sense? no
	Type.ROCKET: {"damage": 1, "range": 10.0}, 
	Type.MISSILE: {"damage": 1, "range": 10.0}, 
	Type.NUKE: {"damage": 5, "range": 500.0}, 
	Type.BALLISTIC: {"damage": 0, "range": 10.0},
	Type.BALLISTIC_MISSILE: {"damage": 3, "range": 20.0},
	}
	
const SCENE: Dictionary = {
	Type.MINE: "res://weapons/explosive/explosive.tscn", \
	Type.ROCKET: "res://weapons/missile/missile.tscn", \
	Type.MISSILE: "res://weapons/missile/missile.tscn", \
	Type.NUKE: "res://weapons/explosive/explosive.tscn",
	Type.BALLISTIC: "res://weapons/missile/missile.tscn",
	Type.BALLISTIC_MISSILE: "res://weapons/missile/missile.tscn"}
	
const ICON: Dictionary = {
	Type.MINE: "icon_mine", \
	Type.ROCKET: "icon_rocket", \
	Type.MISSILE: "icon_missile", \
	Type.NUKE: "icon_nuke",
	Type.BALLISTIC: "icon_ballistic",
	Type.BALLISTIC_MISSILE: "icon_ballistic_missile"}
	
const TARGET_SPEED: Dictionary = {
	Type.ROCKET: 10.0, 
	Type.MISSILE: 10.0, 
	Type.BALLISTIC: 20.0,
	Type.BALLISTIC_MISSILE: 20.0}

const MUZZLE_SPEED: Dictionary = {
	Type.ROCKET: 10.0, 
	Type.MISSILE: 10.0, 
	Type.BALLISTIC: 20.0,
	Type.BALLISTIC_MISSILE: 0.0}

const HOMING_DELAY: Dictionary = {
	Type.MISSILE: 0.5,
	Type.BALLISTIC_MISSILE: 2.0,
}

const LIFETIME_SECONDS: Dictionary = {
	Type.ROCKET: 10.0, 
	Type.MISSILE: 10.0,
	Type.BALLISTIC_MISSILE: 20.0,
}

# TODO combine with indirect damage above
#explosion force = explosion_strength / (explosion_decrease*distance)+1.0 ^ explosion_exponent)
const EXPLOSION_STRENGTH: Dictionary = {
	Type.MINE: 2500.0, 
	Type.BOMB: 5000.0, 
	Type.ROCKET: 500.0,
	Type.MISSILE: 1000.0,
	Type.BALLISTIC_MISSILE: 1000.0,
	Type.NUKE: 10000.0,
	}

# TODO move to vehicle config
var vehicle_weapons: Dictionary = {
	Type.MINE: [ConfigVehicles.Type.RACER],
	Type.ROCKET: [ConfigVehicles.Type.RACER, ConfigVehicles.Type.RALLY, ConfigVehicles.Type.TANK],
	Type.MISSILE: [ConfigVehicles.Type.RALLY, ConfigVehicles.Type.TANK, ConfigVehicles.Type.TRUCK],
	Type.NUKE: [],  # disabled initially, PowerUp enables it ."Racer", "Rally", "Tank", "Truck"]},
	Type.BALLISTIC: [ConfigVehicles.Type.TANK, ConfigVehicles.Type.TRUCK],
	Type.BOMB: [],
	Type.BALLISTIC_MISSILE: [ConfigVehicles.Type.TANK],
	}

var explosion_range: Dictionary = {
	Type.MINE: 10.0, 
	Type.BOMB: 10.0, 
	Type.MISSILE: 10.0,
	Type.ROCKET: 10.0, 
	Type.BALLISTIC_MISSILE: 20.0,
	Type.NUKE: 1000.0}

var explosion_exponent: Dictionary = {
	Type.MINE: 1.5, 
	Type.BOMB: 1.5, 
	Type.NUKE: 1.05}

var explosion_decrease: Dictionary = {
	Type.MINE: 1.0, 
	Type.BOMB: 1.0, 
	Type.NUKE: 0.05}


# Built-in methods

func _ready():
	pass # Replace with function body.

