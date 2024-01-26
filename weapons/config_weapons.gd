extends Node


enum Type {
	MINE=0, 
	ROCKET=1, 
	MISSILE=2, 
	NUKE=3, 
	BALLISTIC=4,
	BOMB=5,  # used for air-raids only
	BALLISTIC_MISSILE=6,
	TRUCK_MINE=7,
	AIR_BURST=8,
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
	NUKE=0, 
	SHIELD=1,
	HEALTH=2,
	FAST_REVERSE=3,
	}
	
const COOLDOWN_TIMER_DEFAULTS: Dictionary = {
	Type.MINE: 5.0,
	Type.ROCKET: 10.0, 
	Type.MISSILE: 60.0,  #20.0, changed as we're giving all weapons to the 
	Type.NUKE: 60.0, 
	Type.BALLISTIC: 60.0,  #5.0, changed as we're giving all weapons to the
	Type.BALLISTIC_MISSILE: 60.0,  #10.0, changed as we're giving all weapons to the
	Type.TRUCK_MINE: 30.0,
	Type.AIR_BURST: 30.0,
	}

const EXPLOSIVE_START_WAIT: float = 3.0  # wait time when first turned on to activation
const EXPLOSIVE_ACTIVE_WAIT: float = 1.0
const EXPLOSIVE_PROXIMITY_DISTANCE: float = 5.0
const FLASH_TIMER_WAIT: float = 0.25

# TODO remove this, if we want to completely move to damage due to force (acceleration)
# is this direct hit damage?
const DAMAGE: Dictionary = {
	Type.MINE: 1, 
	Type.ROCKET: 5, 
	Type.MISSILE: 5, 
	Type.NUKE: 10,
	Type.BALLISTIC: 5.0,
	Type.BALLISTIC_MISSILE: 10.0,
	Type.TRUCK_MINE: 3,
	Type.AIR_BURST: 3,  # this won't happen though
	}

# TODO: Do we want to keep this, or do we want to completely move to damage due to force (acceleration)
const DAMAGE_INDIRECT: Dictionary = {
	Type.MINE:  1,  
	Type.ROCKET: 1, 
	Type.MISSILE: 1,
	Type.NUKE: 5, 
	Type.BOMB: 1, 
	Type.BALLISTIC: 0,
	Type.BALLISTIC_MISSILE: 3,
	Type.TRUCK_MINE: 3,
	Type.AIR_BURST: 3,
	}
	
const SCENE: Dictionary = {
	Type.MINE: "res://weapons/explosive/explosive.tscn", \
	Type.ROCKET: "res://weapons/missile/missile.tscn", \
	Type.MISSILE: "res://weapons/missile/missile.tscn", \
	Type.NUKE: "res://weapons/explosive/explosive.tscn",
	Type.BALLISTIC: "res://weapons/missile/missile.tscn",
	Type.BALLISTIC_MISSILE: "res://weapons/missile/missile.tscn",
	Type.TRUCK_MINE: "res://weapons/explosive/explosive.tscn",
	Type.AIR_BURST: "res://weapons/missile/missile.tscn",
	}
	
const ICON: Dictionary = {
	Type.MINE: "icon_mine", \
	Type.ROCKET: "icon_rocket", \
	Type.MISSILE: "icon_missile", \
	Type.NUKE: "icon_nuke",
	Type.BALLISTIC: "icon_ballistic",
	Type.BALLISTIC_MISSILE: "icon_ballistic_missile",
	Type.AIR_BURST: "icon_air_burst",
	Type.TRUCK_MINE: "icon_truck_mine",
	}

# Speed when fired
const MUZZLE_SPEED: Dictionary = {
	Type.ROCKET: 10.0, 
	Type.MISSILE: 10.0, 
	Type.BALLISTIC: 20.0,  # at 50 it can fly through walls - be careful
	Type.BALLISTIC_MISSILE: 0.0,
	Type.AIR_BURST: 1.0,
	}

# Eventual speed after firing
const FLYING_SPEED: Dictionary = {
	Type.ROCKET: 10.0, 
	Type.MISSILE: 10.0, 
	Type.BALLISTIC: 20.0,
	Type.BALLISTIC_MISSILE: 20.0,
	Type.AIR_BURST: 2.0,
	}

# Delay from launch before the homing turns on
const HOMING_DELAY: Dictionary = {
	Type.MISSILE: 0.5,
	Type.BALLISTIC_MISSILE: 2.0,
}

const LIFETIME_SECONDS: Dictionary = {
	Type.ROCKET: 10.0, 
	Type.MISSILE: 10.0,
	Type.BALLISTIC_MISSILE: 20.0,
	Type.AIR_BURST: 5.0,
	Type.TRUCK_MINE: 5.0,
}

# TODO combine with indirect damage above
#explosion force = explosion_strength / (explosion_decrease*distance)+1.0 ^ explosion_exponent)
const EXPLOSION_STRENGTH: Dictionary = {
	Type.MINE: 2500.0, 
	Type.BOMB: 5000.0, 
	Type.ROCKET: 500.0,
	Type.MISSILE: 1000.0,
	Type.BALLISTIC: 1000.0,
	Type.BALLISTIC_MISSILE: 1000.0,
	Type.NUKE: 10000.0,
	Type.AIR_BURST: 2000.0,
	Type.TRUCK_MINE: 2000.0,
	}

# TODO move to vehicle config
var vehicle_weapons: Dictionary = {
	Type.MINE: [ConfigVehicles.Type.RACER],
	Type.ROCKET: [ConfigVehicles.Type.RACER, ConfigVehicles.Type.RALLY, ConfigVehicles.Type.TANK],
	Type.MISSILE: [ConfigVehicles.Type.RACER, ConfigVehicles.Type.RALLY, ConfigVehicles.Type.TANK, ConfigVehicles.Type.TRUCK],
	Type.NUKE: [],  # disabled initially, PowerUp enables it ."Racer", "Rally", "Tank", "Truck"]},
	Type.BALLISTIC: [ConfigVehicles.Type.RACER, ConfigVehicles.Type.TANK, ConfigVehicles.Type.TRUCK],
	Type.BOMB: [],
	Type.BALLISTIC_MISSILE: [ConfigVehicles.Type.RACER, ConfigVehicles.Type.TANK],
	Type.TRUCK_MINE: [ConfigVehicles.Type.TRUCK],
	Type.AIR_BURST: [ConfigVehicles.Type.TRUCK],
	}

const EXPLOSION_RANGE: Dictionary = {
	Type.MINE: 10.0, 
	Type.BOMB: 10.0, 
	Type.MISSILE: 10.0,
	Type.ROCKET: 10.0, 
	Type.BALLISTIC_MISSILE: 20.0,
	Type.BALLISTIC: 10.0, 
	Type.NUKE: 1000.0,
	Type.TRUCK_MINE: 200.0,  # only line of sight. 1000=Infinite
	Type.AIR_BURST: 200.0,  # only line of sight. 1000=Infinite
	}

# TODO enforce these for indirect missile explosions
const EXPLOSION_EXPONENT: Dictionary = {
	Type.MINE: 1.5, 
	Type.BOMB: 1.5, 
	Type.NUKE: 1.05,
	Type.TRUCK_MINE: 1.05,
	Type.AIR_BURST: 1.05,
	}

# TODO enforce these for indirect missile explosions
const EXPLOSION_DECREASE: Dictionary = {
	Type.MINE: 1.0, 
	Type.BOMB: 1.0, 
	Type.NUKE: 0.05,
	Type.TRUCK_MINE: 0.05,
	Type.AIR_BURST: 0.05,
	}


# Built-in methods

func _ready():
	pass # Replace with function body.

