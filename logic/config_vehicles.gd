extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var types = {
	"Tank":		{"scene": "res://scenes/vehicle_tank.tscn", 
				"engine_force_value": 150,  # keep this at 1x mass
				"mass_kg/100": 200.0, 
				"suspension_stiffness": 100.0, 
				"suspension_travel": 0.1,
				"all_wheel_drive": true,
				"wheel_friction_slip": 15.0,
				"wheel_roll_influence": 0.9,
				"brake": 40.0}, 
	"Racer": 	{"scene": "res://scenes/vehicle_racer.tscn", 
				"engine_force_value": 220,  # keep this at 3x mass
				"mass_kg/100": 70.0, 
				"suspension_stiffness": 75.0, 
				"suspension_travel": 0.25,
				"all_wheel_drive": false,
				"wheel_friction_slip": 1.1,
				"wheel_roll_influence": 0.9,
				"brake": 10.0}, 
	"Rally": 	{"scene": "res://scenes/vehicle_rally.tscn", 
				"engine_force_value": 70,  # keep this at 3x mass
				"mass_kg/100": 50.0, 
				"suspension_stiffness": 40.0, 
				"suspension_travel": 2.0,
				"all_wheel_drive": true,
				"wheel_friction_slip": 1.3,
				"wheel_roll_influence": 0.9,
				"brake": 5.0}, 
	"Truck": 	{"scene": "res://scenes/vehicle_truck.tscn", 
				"engine_force_value": 200,  # keep this at 1x mass
				"mass_kg/100": 200.0, 
				"suspension_stiffness": 90.0, 
				"suspension_travel":0.2,
				"all_wheel_drive": false,
				"wheel_friction_slip":1.0,
				"wheel_roll_influence": 0.9,
				"brake": 40.0}}
									
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass