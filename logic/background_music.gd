extends Node

var play_music = true  # true
var tracks = []
var timer_1s = 1.0
var current_track
var current_track_num

func _ready():
	randomize()
	for ts in get_children():
		tracks.append(ts)
		ts.volume_db = 0.0
	if len(tracks) > 0:
		current_track_num = randi() % len(tracks)
		current_track = tracks[current_track_num]
		current_track.playing = true
		current_track.stream_paused = false
	else:
		print("Error: no music tracks")
	

func _process(delta):
	
	timer_1s -= delta
	
	# always react to the toggle button quickly
	if Input.is_action_just_released("music_toggle"):
		if play_music == false:
			play_music = true
			current_track.playing = true
			current_track.stream_paused = false
		else:
			play_music = false
			for ts in get_children():
				ts.playing = false
				ts.stream_paused = true

	# once in a whie, check all music is disabled or move to the next track
	if timer_1s < 0.0:
		timer_1s = 1.0

		if play_music == false:
			for ts in get_children():
				ts.playing = false
				ts.stream_paused = true
		else: # a song has finished, play the next one
			if current_track.playing == false:
				var old_track_num = current_track_num
				if len(tracks) > 1:
					for i in [1,2,3,4,5]:  # 5 attempts to change to a different track
						if current_track_num == old_track_num:
							current_track_num = randi() % len(tracks)  # random tracks
				current_track = tracks[current_track_num]
				current_track.playing = true
				current_track.stream_paused = false
