extends Node


var current_track_num: int
var current_track = null
export var start_paused: bool = false


func _ready():
	randomize()
	
	# Randomise the track played first
	load_new_track()
	#current_track.stream_paused = start_paused
	

func _process(_delta):
	
	# always react to the toggle button quickly
	if Input.is_action_just_released("music_toggle") and current_track != null:
		if current_track.stream_paused == false:
			current_track.stream_paused = true
		else:
			current_track.stream_paused = false
	elif Input.is_action_just_released("music_next_track"):
		Global.debug_print(3, "Next music track...")
		load_new_track()


func _on_TimerCheckVolume_timeout():
	current_track.volume_db = Global.background_music_volume_db


func load_new_track() -> void:
	
	var old_track_num: int = current_track_num
	for i in [1,2,3,4,5,6]:  # 5 attempts to change to a different track
		if current_track_num == old_track_num:
			current_track_num = randi() % 6  # random tracks
	if current_track != null:  
		current_track.playing = false  # stop the old one first
	match current_track_num:
		1:
			current_track = $MusicTrack1
		2:
			current_track = $MusicTrack2
		3:
			current_track = $MusicTrack3
		4:
			current_track = $MusicTrack4
		5:
			current_track = $MusicTrack5
		6:
			current_track = $MusicTrack6
		_:
			current_track = $MusicTrack1
	current_track.playing = true


func set_pitch_scale(set_pitch):
	
	$MusicTrack1.pitch_scale = set_pitch
	$MusicTrack2.pitch_scale = set_pitch
	$MusicTrack3.pitch_scale = set_pitch
	$MusicTrack4.pitch_scale = set_pitch
	$MusicTrack5.pitch_scale = set_pitch
	$MusicTrack6.pitch_scale = set_pitch
	$Siren.pitch_scale = set_pitch
	$Wind.pitch_scale = set_pitch/2.0
	$Cinders.pitch_scale = set_pitch


func _on_TimerCheckMusic_timeout():
	if current_track != null:
		# once in a whie, check all music is disabled or move to the next track
		if current_track.playing == false and current_track.stream_paused == false:  # a song has finished, play the next one
			load_new_track()
