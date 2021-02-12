extends AudioStreamPlayer

const battle_theme = preload("res://assets/audio/battle_theme.ogg")
const field_theme = preload("res://assets/audio/field_theme.ogg")
const victory_fanfare = preload("res://assets/audio/victory_fanfare.ogg")
const slime_hit = preload("res://assets/audio/slime_hit.ogg")

var audioTimer
func play_sound(sound, volume):
	stream = sound
	volume_db = volume
	stop()
	play()

func play_timed_sound(sound, volume, seconds, resume_func):
	play_sound(sound, volume)
	# Timer to switch back to previous field theme
	audioTimer = Timer.new()
	audioTimer.set_wait_time(seconds)
	audioTimer.connect("timeout", self, resume_func) 
	add_child(audioTimer)
	audioTimer.start()

# Interface functions
func play_battle_theme():
	play_sound(battle_theme, -16)
func play_field_theme():
	play_sound(field_theme, -12)
func play_victory_fanfare():
	play_timed_sound(victory_fanfare, -8, 4, "_resume_field")
func play_slime_hit():
	play_timed_sound(slime_hit, -8, 0.5, "_resume_battle")

# Resume functions
func _resume_field():
	play_field_theme()
	audioTimer.stop()
func _resume_battle():
	play_battle_theme()
	audioTimer.stop()
