extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

enum AliveState {ALIVE=0, DYING=1, DEAD=2}
enum SpeedState {IDLE=0, STABLE=1, SPEEDING_UP=2, SLOWING_DOWN=3}

enum Type {
	RACER=0,
	RALLY=1,
	TANK=2,
	TRUCK=3
}

var nice_name: Dictionary = {
	Type.RACER: "Racer",
	Type.RALLY: "Rally",
	Type.TANK: "Tank",
	Type.TRUCK: "Truck",
}

var config: Dictionary = {
	Type.RACER:
		{"engine_force_value": 220,  # keep this at 3x mass
		"mass_kg/100": 70.0, 
		"suspension_stiffness": 75.0, "suspension_travel": 0.25,
		"all_wheel_drive": false,
		"wheel_friction_slip": 1.1,   # 0 is no grip, 1 is normal grip
		"wheel_roll_influence": 0.9,
		"brake": 10.0,
		"max_speed_km_hr": 200.0}, 
	Type.RALLY:
		{"engine_force_value": 70,  # keep this at 3x mass
		"mass_kg/100": 50.0, 
		"suspension_stiffness": 50.0, "suspension_travel": 2.0,
		"all_wheel_drive": true,
		"wheel_friction_slip": 1.3,   # 0 is no grip, 1 is normal grip
		"wheel_roll_influence": 0.9,
		"brake": 5.0,
		"max_speed_km_hr": 150.0}, 
	Type.TANK:
		{"engine_force_value": 400,  # keep this at 1x mass
		"mass_kg/100": 500.0, 
		"suspension_stiffness": 100.0, "suspension_travel": 1.0,
		"all_wheel_drive": true,
		"wheel_friction_slip": 15.0,  # 0 is no grip, 1 is normal grip
		"wheel_roll_influence": 0.1,
		"brake": 50.0,
		"max_speed_km_hr": 50.0}, 
	Type.TRUCK:
		{"engine_force_value": 350,  # keep this at 1x mass
		"mass_kg/100": 300.0, 
		"suspension_stiffness": 90.0, "suspension_travel":0.2,
		"all_wheel_drive": false,
		"wheel_friction_slip":1.0,   # 0 is no grip, 1 is normal grip
		"wheel_roll_influence": 0.5,
		"brake": 50.0,
		"max_speed_km_hr": 80.0}
	}

const STEER_SPEED: float = 1.5
const STEER_LIMIT: float = 0.6 #0.4
const EXPLOSION_STRENGTH: float = 50.0
const ENGINE_FORCE_VALUE_DEFAULT: int = 80


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
