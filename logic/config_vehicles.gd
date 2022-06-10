extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

enum VEHICLE_STATES {ALIVE=0, DYING=1, DEAD=2}

var types: Dictionary = {
	"Tank":		{"scene": "res://scenes/vehicle_tank.tscn", 
				"engine_force_value": 100,  # keep this at 1x mass
				"mass_kg/100": 100.0, 
				"suspension_stiffness": 100.0, "suspension_travel": 0.1,
				"all_wheel_drive": true,
				"wheel_friction_slip": 15.0,  # 0 is no grip, 1 is normal grip
				"wheel_roll_influence": 0.9,
				"brake": 20.0}, 
	"Racer": 	{"scene": "res://scenes/vehicle_racer.tscn", 
				"engine_force_value": 220,  # keep this at 3x mass
				"mass_kg/100": 70.0, 
				"suspension_stiffness": 75.0, "suspension_travel": 0.25,
				"all_wheel_drive": false,
				"wheel_friction_slip": 1.1,   # 0 is no grip, 1 is normal grip
				"wheel_roll_influence": 0.9,
				"brake": 10.0}, 
	"Rally": 	{"scene": "res://scenes/vehicle_rally.tscn", 
				"engine_force_value": 70,  # keep this at 3x mass
				"mass_kg/100": 50.0, 
				"suspension_stiffness": 40.0, "suspension_travel": 2.0,
				"all_wheel_drive": true,
				"wheel_friction_slip": 1.3,   # 0 is no grip, 1 is normal grip
				"wheel_roll_influence": 0.9,
				"brake": 5.0}, 
	"Truck": 	{"scene": "res://scenes/vehicle_truck.tscn", 
				"engine_force_value": 100,  # keep this at 1x mass
				"mass_kg/100": 100.0, 
				"suspension_stiffness": 90.0, "suspension_travel":0.2,
				"all_wheel_drive": false,
				"wheel_friction_slip":1.0,   # 0 is no grip, 1 is normal grip
				"wheel_roll_influence": 0.5,
				"brake": 20.0}}
									
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
