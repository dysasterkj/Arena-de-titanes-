extends Node
## Sonido: efectos y música (wav de audio/).

const SFX_NAMES := ["swing", "hit", "hit_metal", "block", "break", "crit", "step", "push", "charge", "fire", "boom", "potion", "heal", "throw", "die", "win", "lose", "levelup", "crowd", "crowd_oh", "click", "buy", "coin"]
const MUSIC := {"menu": "music_menu", "battle": "music_battle"}

var sfx: Dictionary = {}
var music: Dictionary = {}
var music_player: AudioStreamPlayer
var pool: Array = []
var cur_track := ""
var music_on := true
var sfx_on := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -11.0
	add_child(music_player)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	for n in SFX_NAMES:
		var st = load("res://audio/%s.wav" % n)
		if st:
			sfx[n] = st
	for k in MUSIC:
		var st = load("res://audio/%s.wav" % MUSIC[k])
		if st is AudioStreamWAV:
			st.loop_mode = AudioStreamWAV.LOOP_FORWARD
			st.loop_begin = 0
			st.loop_end = st.data.size() / 2
			music[k] = st


func play(name: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if not sfx_on or not sfx.has(name):
		return
	for p in pool:
		if not p.playing:
			p.stream = sfx[name]
			p.pitch_scale = pitch
			p.volume_db = -4.0 + vol_db
			p.play()
			return


func play_music(track: String) -> void:
	cur_track = track
	_apply()


func _apply() -> void:
	if not music_on:
		music_player.stop()
		return
	if music.has(cur_track) and (music_player.stream != music[cur_track] or not music_player.playing):
		music_player.stream = music[cur_track]
		music_player.play()


func set_options(m: bool, s: bool) -> void:
	music_on = m
	sfx_on = s
	_apply()
