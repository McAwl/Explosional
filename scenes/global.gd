extends Node


var logo_scene_folder: String = "res://scenes/logo/logo.tscn"

var title_screen_folder: String = "res://scenes/title_screen/title_screen.tscn"

var start_scene: String = "res://scenes/start/start.tscn"

# main scene
var main_scene: String = "res://scenes/main/main.tscn"
var background_music_folder: String = "res://assets/audio/music/background"
var background_music_volume_db: float = 0.0
const BACKGROUND_MUSIC_MAX_VOLUME_DB: float = 0.0

var main_menu_scene: String = "res://scenes/main_menu/main_menu.tscn"

var instructions_scene: String = "res://scenes/instructions/instructions.tscn"

var final_score_scene: String = "res://scenes/final_score/final_score.tscn"

# effects folders
var explosion_folder: String = "res://effects/visual/explosion.tscn"

# vehicles
var vehicle_body_folder: String = "res://vehicles/vehicle_body.tscn"
const vehicle_detach_rigid_bodies_folder: String = "res://vehicles/vehicle_detach_rigid_bodies.gd"
var exploded_vehicle_part_folder: String = "res://vehicles/exploded_vehicle_part.tscn"
var vehicle_sound_volume_db: float = 0.0
const VEHICLE_SOUND_MAX_VOLUME_DB: float = 0.0

# player
var player_folder: String = "res://player/player.tscn"

# terrain
var tree_folder: String = "res://terrain/tree.tscn"
var grass_folder: String = "res://terrain/grass.tscn"
var raycast_procedural_veg_folder: String = "res://terrain/raycast_procedural_veg.tscn"

# weapons
var explosive_folder: String = "res://weapons/explosive/explosive.tscn"

# powerups
var power_up_folder: String = "res://power_ups/power_up.tscn"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass