extends RefCounted
## Sintetizador (solo desarrollo): genera los .wav de audio/ con sonidos de combate y música de arena.
## Ejecutar: godot --headless --path . --script tools/gen_audio.gd

const RATE := 22050

var rng := RandomNumberGenerator.new()


func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


func _hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


func to_wav(buf: PackedFloat32Array, gain: float = 0.9) -> AudioStreamWAV:
	var peak := 0.001
	for v in buf:
		peak = maxf(peak, absf(v))
	var k := minf(1.0, gain / peak) if peak > gain else 1.0
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i] * k, -1.0, 1.0) * 30000.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.stereo = false
	st.data = bytes
	return st


## wave: 0 seno, 1 cuadrada, 2 triángulo, 3 diente de sierra, 4 latón (armónicos)
func tone(buf: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, wave: int, vol: float, attack: float = 0.005, decay: float = 3.0, vib: float = 0.0) -> void:
	var n := int(dur * RATE)
	var s0 := int(start * RATE)
	if s0 >= buf.size():
		return
	n = mini(n, buf.size() - s0)
	var phase := 0.0
	for i in n:
		var tt := float(i) / RATE
		var f := lerpf(f0, f1, tt / dur)
		if vib > 0.0:
			f *= 1.0 + sin(tt * 38.0) * vib
		phase += f / RATE
		var ph := phase - floorf(phase)
		var s := 0.0
		match wave:
			0: s = sin(phase * TAU)
			1: s = 1.0 if ph < 0.5 else -1.0
			2: s = 4.0 * absf(ph - 0.5) - 1.0
			3: s = 2.0 * ph - 1.0
			4:
				for k in range(1, 7):
					s += sin(phase * TAU * k) / pow(float(k), 1.15)
				s *= 0.6
		var env := minf(1.0, tt / attack) * exp(-decay * tt / dur)
		buf[s0 + i] += s * env * vol


## Ruido con filtro pasa-bajos que va de lp0 a lp1 (Hz).
func noise(buf: PackedFloat32Array, start: float, dur: float, vol: float, lp0: float, lp1: float, attack: float = 0.003, decay: float = 3.0) -> void:
	var n := int(dur * RATE)
	var s0 := int(start * RATE)
	if s0 >= buf.size():
		return
	n = mini(n, buf.size() - s0)
	var y := 0.0
	for i in n:
		var tt := float(i) / RATE
		var fc := lerpf(lp0, lp1, tt / dur)
		var a := 1.0 - exp(-TAU * fc / RATE)
		y += a * ((rng.randf() * 2.0 - 1.0) - y)
		var env := minf(1.0, tt / attack) * exp(-decay * tt / dur)
		buf[s0 + i] += y * env * vol


func clang(buf: PackedFloat32Array, start: float, f: float, vol: float, dur: float = 0.5) -> void:
	var ratios := [1.0, 2.76, 5.4, 8.93]
	var vols := [1.0, 0.7, 0.45, 0.3]
	for i in 4:
		tone(buf, start, dur / (1.0 + i * 0.5), f * float(ratios[i]), f * float(ratios[i]) * 0.985, 0, vol * float(vols[i]), 0.001, 6.0)
	noise(buf, start, 0.04, vol * 0.8, 9000.0, 3000.0, 0.0005, 4.0)


func sfx_set() -> Dictionary:
	rng.seed = 4242
	var out := {}
	var b := _buf(0.3)
	noise(b, 0.0, 0.26, 0.55, 500.0, 4200.0, 0.06, 5.0)
	tone(b, 0.0, 0.2, 420.0, 900.0, 0, 0.08, 0.05, 6.0)
	out["swing"] = to_wav(b, 0.7)

	b = _buf(0.3)
	tone(b, 0.0, 0.22, 170.0, 50.0, 0, 0.95, 0.002, 9.0)
	noise(b, 0.0, 0.14, 0.7, 2500.0, 300.0, 0.001, 8.0)
	out["hit"] = to_wav(b)

	b = _buf(0.5)
	clang(b, 0.0, 780.0, 0.5, 0.45)
	tone(b, 0.0, 0.12, 140.0, 70.0, 0, 0.5, 0.002, 9.0)
	out["hit_metal"] = to_wav(b)

	b = _buf(0.5)
	clang(b, 0.0, 520.0, 0.55, 0.5)
	tone(b, 0.0, 0.18, 110.0, 55.0, 0, 0.9, 0.002, 8.0)
	out["block"] = to_wav(b)

	b = _buf(0.9)
	noise(b, 0.0, 0.7, 0.8, 6000.0, 500.0, 0.002, 3.5)
	clang(b, 0.0, 300.0, 0.6, 0.6)
	clang(b, 0.12, 410.0, 0.4, 0.5)
	tone(b, 0.0, 0.5, 200.0, 40.0, 0, 0.8, 0.002, 5.0)
	out["break"] = to_wav(b)

	b = _buf(1.3)
	tone(b, 0.0, 0.7, 95.0, 32.0, 0, 1.0, 0.002, 5.0)
	clang(b, 0.0, 900.0, 0.5, 0.5)
	noise(b, 0.0, 0.3, 0.9, 5000.0, 400.0, 0.001, 6.0)
	noise(b, 0.15, 1.1, 0.35, 1500.0, 2600.0, 0.3, 2.4)
	out["crit"] = to_wav(b)

	b = _buf(0.12)
	noise(b, 0.0, 0.1, 0.8, 700.0, 200.0, 0.001, 9.0)
	tone(b, 0.0, 0.08, 120.0, 70.0, 0, 0.4, 0.001, 8.0)
	out["step"] = to_wav(b, 0.6)

	b = _buf(0.35)
	tone(b, 0.0, 0.25, 130.0, 55.0, 0, 0.9, 0.002, 7.0)
	noise(b, 0.0, 0.25, 0.5, 1200.0, 200.0, 0.01, 6.0)
	out["push"] = to_wav(b)

	b = _buf(0.7)
	tone(b, 0.0, 0.6, 260.0, 1300.0, 0, 0.3, 0.2, 1.2, 0.01)
	tone(b, 0.0, 0.6, 520.0, 2600.0, 2, 0.12, 0.2, 1.2, 0.02)
	noise(b, 0.0, 0.6, 0.18, 1500.0, 6000.0, 0.3, 1.5)
	out["charge"] = to_wav(b, 0.7)

	b = _buf(0.7)
	noise(b, 0.0, 0.6, 0.7, 350.0, 3500.0, 0.1, 3.5)
	tone(b, 0.0, 0.5, 140.0, 380.0, 3, 0.15, 0.05, 4.0)
	out["fire"] = to_wav(b, 0.8)

	b = _buf(1.1)
	tone(b, 0.0, 0.9, 75.0, 28.0, 0, 1.0, 0.002, 4.0)
	noise(b, 0.0, 0.8, 0.9, 4000.0, 250.0, 0.002, 4.5)
	out["boom"] = to_wav(b)

	b = _buf(0.7)
	for i in 3:
		tone(b, i * 0.16, 0.14, 300.0 + i * 40.0, 520.0 + i * 40.0, 0, 0.5, 0.01, 5.0, 0.03)
		noise(b, i * 0.16, 0.1, 0.2, 800.0, 400.0, 0.01, 6.0)
	out["potion"] = to_wav(b, 0.7)

	b = _buf(1.0)
	for i in 4:
		tone(b, i * 0.1, 0.5, _hz(72 + [0, 4, 7, 12][i]), _hz(72 + [0, 4, 7, 12][i]), 0, 0.35, 0.004, 4.0)
		tone(b, i * 0.1, 0.5, _hz(84 + [0, 4, 7, 12][i]), _hz(84 + [0, 4, 7, 12][i]), 0, 0.12, 0.004, 5.0)
	out["heal"] = to_wav(b, 0.7)

	b = _buf(0.4)
	noise(b, 0.0, 0.3, 0.55, 1800.0, 6500.0, 0.03, 4.0)
	tone(b, 0.0, 0.25, 500.0, 1000.0, 0, 0.1, 0.03, 5.0)
	out["throw"] = to_wav(b, 0.7)

	b = _buf(1.2)
	tone(b, 0.0, 0.9, 180.0, 38.0, 0, 0.9, 0.003, 3.0)
	noise(b, 0.0, 0.6, 0.6, 900.0, 100.0, 0.003, 4.0)
	tone(b, 0.5, 0.5, 70.0, 30.0, 0, 0.7, 0.003, 4.0)
	out["die"] = to_wav(b)

	b = _buf(2.2)
	var notes := [60, 64, 67, 72, 76]
	for i in notes.size():
		var d := 0.55 if i < 4 else 1.3
		tone(b, i * 0.2, d, _hz(notes[i]), _hz(notes[i]), 4, 0.3, 0.03, 2.2, 0.006)
		tone(b, i * 0.2, d, _hz(notes[i] - 12), _hz(notes[i] - 12), 4, 0.18, 0.03, 2.2, 0.006)
	noise(b, 0.9, 1.2, 0.2, 1200.0, 2800.0, 0.3, 2.0)
	out["win"] = to_wav(b, 0.8)

	b = _buf(2.4)
	var dn := [57, 53, 50, 45]
	for i in dn.size():
		tone(b, i * 0.45, 0.8, _hz(dn[i]), _hz(dn[i]) * 0.97, 4, 0.34, 0.04, 2.0, 0.01)
		tone(b, i * 0.45, 0.8, _hz(dn[i] - 12), _hz(dn[i] - 12) * 0.97, 4, 0.22, 0.04, 2.0, 0.01)
	out["lose"] = to_wav(b, 0.8)

	b = _buf(1.4)
	for i in 5:
		var m: int = [64, 67, 71, 76, 83][i]
		tone(b, i * 0.1, 0.7, _hz(m), _hz(m), 4, 0.25, 0.01, 2.5, 0.005)
		tone(b, i * 0.1, 0.5, _hz(m + 12), _hz(m + 12), 0, 0.14, 0.004, 4.0)
	out["levelup"] = to_wav(b, 0.8)

	b = _buf(1.6)
	noise(b, 0.0, 1.5, 0.7, 1100.0, 2500.0, 0.5, 1.8)
	noise(b, 0.1, 1.3, 0.3, 2600.0, 3600.0, 0.6, 2.2)
	out["crowd"] = to_wav(b, 0.7)

	b = _buf(0.9)
	noise(b, 0.0, 0.8, 0.8, 700.0, 1400.0, 0.25, 2.5)
	tone(b, 0.0, 0.7, 330.0, 220.0, 3, 0.04, 0.2, 2.0, 0.02)
	out["crowd_oh"] = to_wav(b, 0.7)

	b = _buf(0.08)
	tone(b, 0.0, 0.06, 740.0, 640.0, 0, 0.5, 0.002, 5.0)
	out["click"] = to_wav(b, 0.6)

	b = _buf(0.5)
	for i in 3:
		tone(b, i * 0.09, 0.25, _hz(76 + [0, 4, 9][i]), _hz(76 + [0, 4, 9][i]), 2, 0.4, 0.003, 4.0)
	out["buy"] = to_wav(b, 0.7)

	b = _buf(0.22)
	tone(b, 0.0, 0.09, 988.0, 988.0, 1, 0.25, 0.002, 4.0)
	tone(b, 0.07, 0.15, 1319.0, 1319.0, 1, 0.25, 0.002, 4.0)
	out["coin"] = to_wav(b, 0.6)
	return out


func _drum_kick(b: PackedFloat32Array, t0: float, v: float = 0.9) -> void:
	tone(b, t0, 0.24, 110.0, 42.0, 0, v, 0.001, 8.0)
	noise(b, t0, 0.04, v * 0.3, 1200.0, 300.0, 0.0005, 6.0)


func _drum_snare(b: PackedFloat32Array, t0: float, v: float = 0.5) -> void:
	noise(b, t0, 0.16, v, 4500.0, 1500.0, 0.0005, 6.0)
	tone(b, t0, 0.1, 220.0, 150.0, 0, v * 0.5, 0.001, 8.0)


func music_set() -> Dictionary:
	rng.seed = 999
	var out := {}
	out["music_battle"] = _render_battle()
	out["music_menu"] = _render_menu()
	return out


func _render_battle() -> AudioStreamWAV:
	var bpm := 108.0
	var beat := 60.0 / bpm
	var bars := 8
	var b := _buf(beat * 4.0 * bars)
	var roots := [45, 41, 43, 45]       # La, Fa, Sol, La (graves)
	var scale := [0, 3, 5, 7, 10, 12, 15]
	for bar in bars:
		var t0 := bar * beat * 4.0
		var root: int = roots[bar % 4]
		# bajo sostenido de latón grave
		tone(b, t0, beat * 3.9, _hz(root), _hz(root), 4, 0.3, 0.06, 0.6, 0.003)
		tone(b, t0, beat * 3.9, _hz(root + 7), _hz(root + 7), 4, 0.14, 0.06, 0.6, 0.003)
		# tambores de guerra
		_drum_kick(b, t0)
		_drum_kick(b, t0 + beat * 2.0, 0.8)
		_drum_kick(b, t0 + beat * 2.75, 0.6)
		_drum_snare(b, t0 + beat)
		_drum_snare(b, t0 + beat * 3.0)
		if bar % 2 == 1:
			_drum_snare(b, t0 + beat * 3.5, 0.35)
			_drum_snare(b, t0 + beat * 3.75, 0.3)
		for h in 8:
			noise(b, t0 + h * beat * 0.5, 0.04, 0.07, 9000.0, 6000.0, 0.001, 5.0)
		# melodía heroica en pentatónica menor
		var pattern := [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5]
		for k in pattern.size():
			if rng.randf() < 0.55:
				var deg: int = scale[rng.randi() % scale.size()]
				var m := root + 24 + deg
				tone(b, t0 + float(pattern[k]) * beat, beat * 0.6, _hz(m), _hz(m), 2, 0.1, 0.01, 3.5)
	return to_wav(b, 0.85)


func _render_menu() -> AudioStreamWAV:
	var bpm := 82.0
	var beat := 60.0 / bpm
	var bars := 8
	var b := _buf(beat * 4.0 * bars)
	var roots := [50, 46, 48, 45]       # Re, Sib, Do, La
	var arp := [0, 7, 12, 15, 12, 7, 10, 7]
	for bar in bars:
		var t0 := bar * beat * 4.0
		var root: int = roots[bar % 4]
		for off in [0, 7, 12, 15]:
			tone(b, t0, beat * 3.95, _hz(root + off), _hz(root + off), 4, 0.12, 0.35, 0.5, 0.004)
		_drum_kick(b, t0, 0.6)
		_drum_kick(b, t0 + beat * 2.0, 0.45)
		_drum_snare(b, t0 + beat * 3.0, 0.25)
		for i in 8:
			var m := root + 24 + int(arp[i])
			tone(b, t0 + i * beat * 0.5, beat * 0.9, _hz(m), _hz(m), 2, 0.1, 0.003, 6.0)
		if bar % 4 == 3:
			var m2 := root + 36
			tone(b, t0 + beat * 2.0, beat * 1.9, _hz(m2), _hz(m2), 4, 0.14, 0.05, 2.0, 0.006)
	return to_wav(b, 0.8)
