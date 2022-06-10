extends AudioStreamPlayer

var tracks: Array = []
var timer_0_5s: float = 1.0
var current_track_num: int
var background_music_folder = "res://assets/audio/music/background"

func _ready():
	stream_paused = false  # true
	randomize()
	
	# Search for music files 
	var dir = Directory.new()
	dir.open(background_music_folder)
	dir.list_dir_begin()
	
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and not file.ends_with(".import"):
			tracks.append(file)

	# Volume adjustment for specific tracks?
	# ts.volume_db = 0.0
	
	# Randomise the track played first
	load_new_track()
	

func _process(delta):
	
	timer_0_5s -= delta
	
	# always react to the toggle button quickly
	if Input.is_action_just_released("music_toggle"):
		if stream_paused == false:
			stream_paused = true
		else:
			stream_paused = false
	elif Input.is_action_just_released("music_next_track"):
		load_new_track()

	# once in a whie, check all music is disabled or move to the next track
	if timer_0_5s < 0.0:
		timer_0_5s = 0.5
		if playing == false and stream_paused == false:  # a song has finished, play the next one
			load_new_track()


func load_new_track() -> void:
	if len(tracks) > 0:
		var old_track_num: int = current_track_num
		if len(tracks) > 1:  # Randomise the next track
			for i in [1,2,3,4,5]:  # 5 attempts to change to a different track
				if current_track_num == old_track_num:
					current_track_num = randi() % len(tracks)  # random tracks
		stream = load(background_music_folder+"/"+tracks[current_track_num]) 
		playing = true
	else:
		print("Error: no music tracks")


