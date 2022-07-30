extends Node


signal change_weather

enum Weather {
	NORMAL=0,
	SNOW=1
}

enum GameMode {
	NOT_SET=0,
	COMPETITIVE=1,
	PEACEFUL=2,
	TOUGH=3
}

enum DamageType {
	DIRECT_HIT=0,
	INDIRECT_HIT=1,
	FORCE=2,
	LAVA=3,
	TEST=4,
	OFF_MAP=5,
}

enum Achievements {
	HOT_STUFF=0,
	SPEED_DEMON5=1,
	SPEED_DEMON10=2,
	OUT_OF_THIS_WORLD=3
}

var achievement_config: Dictionary = {
	Achievements.HOT_STUFF: {"nice_name": "Hot Stuff", "explanation": "Die in lava", "rare": false},
	Achievements.SPEED_DEMON5: {"nice_name": "Speed Demon 5", "explanation": "Drive at maximum speed for 5 seconds", "rare": false},
	Achievements.SPEED_DEMON5: {"nice_name": "Speed Demon 10", "explanation": "Drive at maximum speed for 10 seconds", "rare": true},
	Achievements.OUT_OF_THIS_WORLD: {"nice_name": "Out of this World", "explanation": "Drove off the map", "rare": true},
	}

var weather_model: Array = [
	{"type": Weather.NORMAL, "duration_s": 120.0, "max_wind_strength": 0.0, "fog_depth_curve": 4.75, "fog_depth_begin": 20.0, "visibility": 200.0}, 
	{"type": Weather.SNOW, "duration_s": 30.0, "max_wind_strength":300.0, "fog_depth_curve": 1.0, "fog_depth_begin": 0.0, "visibility": 50.0}
	]
	
var weather_state: Dictionary = {
	"index": 0,  
	"type": Weather.NORMAL, 
	"time_left_s": null, 
	"wind_direction": Vector3(0,0,0), 
	"wind_strength": 0.0,
	"wind_volume_db": -21.0,
	}
	
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var weather_recalc_timer = 1.0
var weather_change_duration_sec = 10.0

var air_strike_config: Dictionary = {
	"duration_sec": 10.0, 
	"interval_sec": 120.0, 
	"circle_radius_m": 10.0}

var game_mode: int = GameMode.COMPETITIVE

var logo_scene_folder: String = "res://scenes/logo/logo.tscn"

var title_screen_folder: String = "res://scenes/title_screen/title_screen.tscn"

var start_scene: String = "res://scenes/start/start.tscn"

var log_level = 2  # 1=error, 2=warning, etc up to 10 for very nested loops

# include a string here and any log command (regardless of log_level) with this as 3rd argument will print
var log_topics = []  # eg, "missile", "mine", "damage", "vehicle_respawn"

# main scene
var main_scene: String = "res://scenes/main/main.tscn"
var background_music_folder: String = "res://assets/audio/music/background"
var background_music_volume_db: float = 0.0

const BACKGROUND_MUSIC_MAX_VOLUME_DB: float = 0.0
const SLOW_MOTION_DURATION_SEC = 5.0

var main_menu_scene: String = "res://scenes/main_menu/main_menu.tscn"

var instructions_scene: String = "res://scenes/instructions/instructions.tscn"

var final_score_scene: String = "res://scenes/final_score/final_score.tscn"

# effects folders
var explosion_folder: String = "res://effects/visual/explosion.tscn"
var nuke_meshes_scene_folder: String = "res://weapons/nuke/nuke_mesh.tscn"
var shield_meshes_scene_folder: String = "res://power_ups/shield_powerup_mesh.tscn"
var health_meshes_scene_folder: String = "res://power_ups/health_powerup_mesh.tscn"

# vehicles
const VEHICLE_DETACH_RIGID_BODIES_FOLDER: String = "res://vehicles/vehicle_detach_rigid_bodies.gd"
const VEHICLE_SOUND_MAX_VOLUME_DB: float = 0.0
var vehicle_body_folder: String = "res://vehicles/vehicle_body.tscn"
var exploded_vehicle_part_folder: String = "res://vehicles/exploded_vehicle_part.tscn"
var vehicle_sound_volume_db: float = 0.0

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


# Built-in methods

func _ready():
	weather_state["time_left_s"] = weather_model[0]["duration_s"]


func _process(delta):
	weather_state["time_left_s"] -= delta
	if weather_state["time_left_s"] < 0.0:
		Global.debug_print(3, "weather_state['time_left_s'] < 0.0")
		toggle_weather()
	
	# Once a second, recalc the weather conditions
	weather_recalc_timer -= delta
	if weather_recalc_timer < 0.0:
		weather_recalc_timer = 1.0
	
		var mws = weather_model[weather_state["index"]]["max_wind_strength"]
		
		# random walk for wind direction
		var x = weather_state["wind_direction"].x
		var y = weather_state["wind_direction"].y
		var z = weather_state["wind_direction"].z
		
		weather_state["wind_direction"] = Vector3(0.9*x + 0.1*rng.randf_range(-1.0, 1.0), 0.9*y + 0.1*rng.randf_range(0.0, 1.0), 0.9*z + 0.1*rng.randf_range(-1.0, 1.0))
		weather_state["wind_direction"].x = clamp(weather_state["wind_direction"].x, -1.0, 1.0)
		weather_state["wind_direction"].y = clamp(weather_state["wind_direction"].y, -2.0, 2.0)
		weather_state["wind_direction"].z = clamp(weather_state["wind_direction"].z, -1.0, 1.0)
		
		# random walk for wind strength, but walk toward max/2
		weather_state["wind_strength"] = (0.9*weather_state["wind_strength"]) + (0.1*(mws/2.0))
		weather_state["wind_strength"] += rng.randf_range(-mws/2.0, mws/2.0) 
		weather_state["wind_strength"] = clamp(weather_state["wind_strength"], 0.0, mws)

		weather_state["wind_volume_db"] = clamp(-21.0+(28.0*weather_state["wind_strength"]/500.0), -21.0, 12.0)


# Private methods

func _set_weather(weather_change_dict: Dictionary) -> void:
	Global.debug_print(3, "set_weather()")
	#weather_state["wind_strength"] = 0.0  # weather_model[weather_state["index"]]["max_wind_strength"] / 2.0
	#Global.debug_print(3, "Setting wind_strength to "+str(weather_state["wind_strength"]))
	emit_signal("change_weather", weather_change_dict, weather_change_duration_sec)


# Public methods

func toggle_weather() -> void:
	var old_index = weather_state["index"]
	Global.debug_print(3, "toggle_weather()")
	# TODO: Can also be set by the player for debugging (for now), so make public for now, private later
	weather_state["index"] += 1
	if weather_state["index"] > len(weather_model) - 1:
		weather_state["index"] = 0
	weather_state["time_left_s"] = weather_model[weather_state["index"]]["duration_s"]
	weather_state["type"] = weather_state["index"]
	Global.debug_print(3, "toggle_weather() to index "+str(weather_state["index"]))
	Global.debug_print(3, "type is now "+str(weather_state["type"]))
	_set_weather(
		{
			"fog_depth_curve": [weather_model[old_index]["fog_depth_curve"], weather_model[weather_state["index"]]["fog_depth_curve"]], 
			"fog_depth_begin": [weather_model[old_index]["fog_depth_begin"], weather_model[weather_state["index"]]["fog_depth_begin"]], 
			"visibility": [weather_model[old_index]["visibility"], weather_model[weather_state["index"]]["visibility"]],
			"snow_visible": true if weather_state["type"] == Weather.SNOW else false,
		})


func debug_print(_log_level: int, message: String, _log_topic=null) -> void:
	if _log_level <= log_level:
		var space_str = ""
		for s in _log_level:
			space_str += " "
		print(space_str+str(message))
	elif _log_topic != null:
		if _log_topic in log_topics:
			var space_str = ""
			for s in _log_level:
				space_str += " "
			print(space_str+str(message))

