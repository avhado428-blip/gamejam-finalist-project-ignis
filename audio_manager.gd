extends Node
## AudioManager — every sound the game makes. FINAL NAME.
##
## No audio files ship with the placeholder build, so the whole library is
## synthesised at startup:
##   SFX   — short PCM tones / sweeps / noise
##   MUSIC — nine seamless, multi-layered cues that share a dedicated "Music" bus
##
## The bus carries an AudioEffectDistortion whose drive is driven per area, so the
## score literally comes apart as the player gets closer to the end.
## Swap _build_library() for real .ogg/.wav resources later — callers never change.
##
## The music is built additively: every tonal partial is snapped to a whole number
## of cycles inside the loop length and every hit is windowed to silence before the
## loop end, so the join is mathematically click-free. Percussive hits keep their
## full decay envelope inside the buffer.

const RATE := 22050            ## SFX sample rate (Hz)
const MUSIC_RATE := 7200       ## music sample rate (Hz) — 3.6 kHz bandwidth, keeps the build fast
const POOL_SIZE := 14
const MUSIC_BUS := "Music"
const CLIP_CEIL := 0.9         ## no rendered buffer exceeds this fraction of full scale
const SIN_SIZE := 4096

var _sounds: Dictionary = {}
var _players: Array = []
var _next: int = 0
var _music: AudioStreamPlayer
var _distortion: AudioEffectDistortion
var _current_music: String = ""
var _sin_tab: PackedFloat32Array


func _ready() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_setup_music_bus()
	_music = AudioStreamPlayer.new()
	_music.bus = MUSIC_BUS
	_music.volume_db = -15.0
	add_child(_music)
	_build_library()


func _setup_music_bus() -> void:
	var idx := AudioServer.get_bus_index(MUSIC_BUS)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, MUSIC_BUS)
	_distortion = AudioEffectDistortion.new()
	_distortion.mode = AudioEffectDistortion.MODE_LOFI
	_distortion.drive = 0.0
	_distortion.post_gain = 0.0
	AudioServer.add_bus_effect(idx, _distortion)
	AudioServer.set_bus_effect_enabled(idx, 0, false)


## 0 = clean, 1 = badly broken.
func set_music_distortion(value: float) -> void:
	if _distortion == null:
		return
	var v := clampf(value, 0.0, 1.0)
	_distortion.drive = v * 0.85
	_distortion.post_gain = -6.0 * v
	# AudioEffectDistortion has no wet/dry mix, so bypass it entirely when clean.
	var idx := AudioServer.get_bus_index(MUSIC_BUS)
	if idx >= 0:
		AudioServer.set_bus_effect_enabled(idx, 0, v > 0.01)


func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not _sounds.has(sfx_name):
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = _sounds[sfx_name]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


func play_music(music_name: String) -> void:
	if not _sounds.has(music_name) or _current_music == music_name:
		return
	_current_music = music_name
	_music.stream = _sounds[music_name]
	_music.play()


func stop_music() -> void:
	_music.stop()
	_current_music = ""


func _build_library() -> void:
	_init_tables()

	# ───────────── movement / core verbs (recipes unchanged) ─────────────
	_sounds["jump"] = _tone(520.0, 0.11, "square", 0.35)
	_sounds["land"] = _tone(180.0, 0.09, "noise", 0.28)
	_sounds["shift"] = _sweep(900.0, 220.0, 0.32, "tri", 0.40)
	_sounds["shift_dull"] = _sweep(240.0, 120.0, 0.30, "sine", 0.22)
	_sounds["interact"] = _tone(740.0, 0.08, "square", 0.30)
	_sounds["switch"] = _sweep(520.0, 1040.0, 0.22, "square", 0.32)
	_sounds["checkpoint"] = _sweep(440.0, 880.0, 0.30, "sine", 0.35)
	_sounds["hurt"] = _sweep(400.0, 90.0, 0.22, "square", 0.40)
	_sounds["death"] = _sweep(300.0, 60.0, 0.60, "tri", 0.40)
	_sounds["ui"] = _tone(880.0, 0.05, "square", 0.25)
	_sounds["enemy_attack"] = _sweep(600.0, 160.0, 0.18, "square", 0.34)
	_sounds["enemy_hit"] = _tone(300.0, 0.10, "noise", 0.35)
	_sounds["enemy_die"] = _sweep(520.0, 70.0, 0.45, "tri", 0.40)
	_sounds["glitch"] = _tone(1400.0, 0.14, "noise", 0.22)
	_sounds["slash"] = _sweep(2800.0, 900.0, 0.16, "noise", 0.34)
	_sounds["wet"] = _tone(150.0, 0.30, "noise", 0.32)
	_sounds["thud"] = _tone(72.0, 0.42, "noise", 0.36)

	# ── the room itself: things heard from somewhere else ──
	_sounds["whisper"] = _sweep(340.0, 165.0, 1.35, "noise", 0.10)
	_sounds["breath"] = _sweep(240.0, 150.0, 1.70, "noise", 0.085)
	_sounds["drip"] = _sweep(880.0, 380.0, 0.13, "sine", 0.16)
	_sounds["creak"] = _sweep(150.0, 92.0, 0.80, "tri", 0.14)
	_sounds["stone"] = _tone(88.0, 0.45, "noise", 0.18)
	_sounds["heartbeat"] = _sweep(130.0, 58.0, 0.34, "sine", 0.26)
	_sounds["sting"] = _sweep(1200.0, 140.0, 0.90, "tri", 0.20)

	# ───────────── bestiary, boss and endgame mechanics ─────────────
	# fly_buzz — dense buzzing cluster, wings fighting each other.
	_sounds["fly_buzz"] = _render_env(0.22, 0.60, 0.01, 0.14, func(t: float) -> float:
		var tremolo := 0.6 + 0.4 * sin(TAU * 33.0 * t)
		var s := 0.0
		s += _osc_phase(120.0 * t, "square") * 0.50
		s += _osc_phase(181.0 * t, "square") * 0.35
		s += _osc_phase(243.0 * t, "square") * 0.28
		s += (randf() * 2.0 - 1.0) * 0.18
		return s * tremolo)

	# fly_die — wet pop, then a small tick as it lands.
	_sounds["fly_die"] = _render_env(0.20, 0.42, 0.0, 0.0, func(t: float) -> float:
		var e1 := exp(-t / 0.03)
		var s := _osc_phase(_ph_sweep(520.0, 90.0, t, 0.12), "sine") * e1 * 0.7
		s += (randf() * 2.0 - 1.0) * e1 * 0.6
		var tt := t - 0.10
		if tt > 0.0:
			s += sin(TAU * 1700.0 * tt) * exp(-tt / 0.015) * 0.4
		return s)

	# summon — a rising screech with an airy hiss behind it.
	_sounds["summon"] = _render_env(1.25, 1.10, 0.18, 0.7, func(t: float) -> float:
		var u := t / 1.25
		var s := _osc_phase(_ph_sweep(170.0, 1750.0, t, 1.25), "tri") * 0.6
		s += _osc_phase(_ph_sweep(340.0, 3500.0, t, 1.25), "sine") * 0.3
		s += (randf() * 2.0 - 1.0) * 0.25 * (0.3 + 0.7 * u)
		return s * (0.5 + 0.5 * sin(TAU * 7.0 * t)))

	# boss_roar — a long, low, saturated roar.
	_sounds["boss_roar"] = _render_env(1.6, 0.5, 0.12, 0.9, func(t: float) -> float:
		var f := 55.0 + 22.0 * sin(TAU * 2.1 * t)
		var s := _osc_phase(f * t, "square") * 0.55
		s += sin(TAU * 42.0 * t) * 0.80
		s += (randf() * 2.0 - 1.0) * 0.25
		return tanh(s * 2.3))

	# boss_hurt — a metallic shriek.
	_sounds["boss_hurt"] = _render_env(0.45, 0.45, 0.004, 0.14, func(t: float) -> float:
		var s := 0.0
		s += sin(TAU * 880.0 * t) * 0.55
		s += sin(TAU * 1327.0 * t) * 0.38
		s += sin(TAU * 2110.0 * t) * 0.26
		s += sin(TAU * 3190.0 * t) * 0.18
		s += (randf() * 2.0 - 1.0) * 0.20
		return s * (0.6 + 0.4 * sin(TAU * 38.0 * t)))

	# boss_step — a heavy, wet thud.
	_sounds["boss_step"] = _render_env(0.42, 0.5, 0.0, 0.0, func(t: float) -> float:
		var s := _osc_phase(_ph_sweep(130.0, 45.0, t, 0.3), "sine") * exp(-t / 0.10) * 0.9
		s += sin(TAU * 60.0 * t) * exp(-t / 0.16) * 0.6
		s += (randf() * 2.0 - 1.0) * exp(-t / 0.05) * 0.7
		return s)

	# fan_sweep — a fast airy whoosh.
	_sounds["fan_sweep"] = _render_env(0.5, 1.60, 0.08, 0.28, func(t: float) -> float:
		var u := t / 0.5
		var s := (randf() * 2.0 - 1.0) * 0.9 * (0.4 + 0.6 * u)
		s += _osc_phase(_ph_sweep(280.0, 2400.0, t, 0.5), "sine") * 0.22
		s += _osc_phase(_ph_sweep(140.0, 1200.0, t, 0.5), "tri") * 0.20
		return s * sin(PI * u))

	# blade_volley — a metallic ring-out with air.
	_sounds["blade_volley"] = _render_env(0.62, 0.4, 0.002, 0.0, func(t: float) -> float:
		var s := 0.0
		s += sin(TAU * 1240.0 * t) * exp(-t / 0.24)
		s += sin(TAU * 1893.0 * t) * exp(-t / 0.20)
		s += sin(TAU * 2570.0 * t) * exp(-t / 0.17)
		s += sin(TAU * 3317.0 * t) * exp(-t / 0.14)
		s += (randf() * 2.0 - 1.0) * exp(-t / 0.08) * 0.5
		return s)

	# boss_die — a long collapsing shriek that ends in a gong.
	_sounds["boss_die"] = _render_env(2.2, 0.5, 0.05, 0.0, func(t: float) -> float:
		var s := 0.0
		if t < 1.25:
			var ph := _ph_sweep(1700.0, 110.0, t, 1.25)
			s += _osc_phase(ph, "tri") * 0.5 * exp(-t / 0.9)
			s += _osc_phase(ph * 2.0, "sine") * 0.25 * exp(-t / 0.9)
			s += (randf() * 2.0 - 1.0) * 0.25 * exp(-t / 0.7)
		var tg := t - 0.55
		if tg > 0.0:
			var g := sin(TAU * 110.0 * tg) + 0.7 * sin(TAU * 163.0 * tg) + 0.5 * sin(TAU * 221.0 * tg) + 0.3 * sin(TAU * 297.0 * tg)
			s += g * 0.7 * exp(-tg / 0.95)
		return s)

	# ember — a tiny crackle.
	_sounds["ember"] = _render_env(0.09, 0.32, 0.0, 0.02, func(t: float) -> float:
		var s := randf() * 2.0 - 1.0
		if randf() < 0.5:
			s *= 0.3
		s += sin(TAU * 900.0 * t) * exp(-t / 0.02) * 0.3
		return s)

	# gate_hum — a low pulsing hum.
	_sounds["gate_hum"] = _render_env(0.9, 0.55, 0.05, 0.0, func(t: float) -> float:
		var pulse := 0.55 + 0.45 * sin(TAU * 6.0 * t)
		var s := sin(TAU * 50.0 * t) * 0.7 + sin(TAU * 100.0 * t) * 0.4 + sin(TAU * 151.0 * t) * 0.2
		s += (randf() * 2.0 - 1.0) * 0.08
		return s * pulse)

	# staff_up — a rising charge.
	_sounds["staff_up"] = _render_env(0.75, 1.60, 0.03, 0.0, func(t: float) -> float:
		var u := t / 0.75
		var s := _osc_phase(_ph_sweep(200.0, 1450.0, t, 0.75), "tri") * 0.55
		s += _osc_phase(_ph_sweep(410.0, 2900.0, t, 0.75), "sine") * 0.28
		s += (randf() * 2.0 - 1.0) * 0.16 * u
		return s * (0.25 + 0.75 * u))

	# zap — a crackling electric discharge.
	_sounds["zap"] = _render_env(0.24, 0.42, 0.0, 0.0, func(t: float) -> float:
		var s := sin(TAU * 2400.0 * t) * exp(-t / 0.03) * 0.4
		s += (randf() * 2.0 - 1.0) * exp(-t / 0.06) * 0.7
		if fmod(t, 0.028) < 0.010:
			s += (randf() * 2.0 - 1.0) * 0.7
		return s)

	# boss_bar — a soft UI tick.
	_sounds["boss_bar"] = _render_env(0.07, 0.50, 0.002, 0.02, func(t: float) -> float:
		return sin(TAU * 1400.0 * t) * 0.6 + sin(TAU * 2110.0 * t) * 0.3)

	# wind_low — a 1.5 s low wind swell.
	_sounds["wind_low"] = _render_env(1.5, 1.20, 0.25, 0.85, func(t: float) -> float:
		var u := t / 1.5
		var s := (randf() * 2.0 - 1.0) * 0.5
		s += sin(TAU * 70.0 * t) * 0.35 + sin(TAU * 111.0 * t) * 0.2
		return s * sin(PI * u))

	# ── the cues four rooms had been asking for into silence ──
	# play_sfx() returns early on a name it does not have, so a missing cue is never an
	# error — it is silence at exactly the moment the scene meant to speak. These four
	# are all called from somewhere already: the staff reveal and the credits lines ask
	# for a chime, the severed hand for a crack and then a shatter, and the tear for a
	# burst of static.

	# chime — two small bells, the second a beat behind the first.
	_sounds["chime"] = _render_env(1.10, 0.60, 0.004, 0.62, func(t: float) -> float:
		var s := sin(TAU * 1046.5 * t) * 0.55
		s += sin(TAU * 1568.0 * t) * 0.34
		s += sin(TAU * 2093.0 * t) * 0.17
		s += sin(TAU * 3136.0 * t) * 0.09
		var t2 := t - 0.16
		if t2 > 0.0:
			s += (sin(TAU * 1318.5 * t2) * 0.42 + sin(TAU * 2637.0 * t2) * 0.13) * exp(-t2 / 0.42)
		return s)

	# crack — a single dry snap with a short body under it, the way bone gives.
	_sounds["crack"] = _render_env(0.36, 0.60, 0.0, 0.06, func(t: float) -> float:
		var s := (randf() * 2.0 - 1.0) * exp(-t / 0.010)
		s += sin(TAU * 1800.0 * t) * exp(-t / 0.006) * 0.50
		s += _osc_phase(_ph_sweep(320.0, 88.0, t, 0.14), "sine") * exp(-t / 0.05) * 0.70
		return s)

	# shatter — the same break, but the whole thing going at once, and things falling.
	_sounds["shatter"] = _render_env(0.95, 0.55, 0.0, 0.22, func(t: float) -> float:
		var s := (randf() * 2.0 - 1.0) * exp(-t / 0.020) * 0.90
		s += (sin(TAU * 3140.0 * t) * 0.50 + sin(TAU * 4720.0 * t) * 0.28) * exp(-t / 0.015)
		# grains knocking themselves out against the floor while the tail lasts
		s += sin(TAU * 1600.0 * t) * sin(TAU * 7.0 * t) * 0.34 * exp(-t / 0.32)
		return s)

	# static_burst — hiss chopped by a hard gate, so it tears instead of just fizzing.
	_sounds["static_burst"] = _render_env(0.50, 0.42, 0.003, 0.13, func(t: float) -> float:
		var gate := 1.0 if fmod(t * 90.0, 1.0) < 0.62 else 0.0
		var s := (randf() * 2.0 - 1.0) * gate
		s += _osc_phase(_ph_sweep(2400.0, 300.0, t, 0.5), "square") * 0.35
		return s)

	# boss_charge — the telegraph: a rising tri-tone swell over a sub that never moves.
	# The gain is way over unity on purpose: the swell is u² × the tail's (1-u), which
	# peaks at 0.15, so a gain of 0.55 would land this cue at a tenth of full scale.
	_sounds["boss_charge"] = _render_env(0.90, 3.20, 0.05, 0.0, func(t: float) -> float:
		var u := t / 0.90
		var s := _osc_phase(_ph_sweep(150.0, 1180.0, t, 0.90), "tri") * 0.55
		s += _osc_phase(_ph_sweep(300.0, 2360.0, t, 0.90), "sine") * 0.22
		s += sin(TAU * 46.0 * t) * 0.40
		return s * (0.20 + 0.80 * u * u))

	# gate_open — the doorway waking: stone grinding, then light arriving.
	_sounds["gate_open"] = _render_env(1.80, 0.90, 0.06, 0.95, func(t: float) -> float:
		var u := t / 1.80
		var s := sin(TAU * 38.0 * t) * 0.55 + sin(TAU * 57.0 * t) * 0.32
		s += (randf() * 2.0 - 1.0) * 0.30
		s += _osc_phase(_ph_sweep(110.0, 880.0, t, 1.80), "sine") * 0.30 * u
		s += sin(TAU * 1320.0 * t) * 0.14 * u
		return s)

	# ───────────── MUSIC: nine seamless, multi-layered cues ─────────────
	var temple_tk: Array = []
	for i in range(15):
		temple_tk.append({"t": 0.9 * float(i), "a": 0.90 if i % 5 == 0 else 0.55})
	# The boss bar: the one cue that has to sound like it is coming at you. A bar is
	# 0.8 s at 150 BPM and the taiko never once stops for the sixteen of them —
	# downbeat and answer every bar, an extra pair on every third bar, and a
	# sixteenth-note fill rolling into the phrase that follows it. Everything the
	# fight is made of is a tritone away from everything else.
	var boss_tk: Array = []
	var boss_stabs: Array = []
	var boss_alarm: Array = []
	for bar in range(16):
		var t0 := 0.8 * float(bar)
		boss_tk.append({"t": t0, "a": 1.00})
		boss_tk.append({"t": t0 + 0.4, "a": 0.78})
		if bar % 3 == 2:
			boss_tk.append({"t": t0 + 0.2, "a": 0.42})
			boss_tk.append({"t": t0 + 0.6, "a": 0.54})
		if bar % 8 == 7:
			for s in range(4):
				boss_tk.append({"t": t0 + 0.5 + 0.1 * float(s), "a": 0.30 + 0.16 * float(s)})
		if bar % 2 == 0:
			boss_stabs.append(_b(t0, 82.4, 0.30, 0.20))       # the low brass on the bar
		if bar % 4 == 3:
			boss_alarm.append(_b(t0 + 0.4, 330.0, 0.26, 0.28))  # and the alarm behind it
	boss_alarm.append(_b(0.0, 55.0, 1.00, 1.60))               # the gong the loop opens on

	# music_calm — title / credits: sparse, almost warm.
	_sounds["music_calm"] = _music_track({
		"dur": 12.0, "peak": 0.55, "trem": [0.333, 0.12],
		"partials": [_p(55.0, 0.55), _p(110.0, 0.30, 0.2), _p(164.4, 0.16, 1.1), _p(219.2, 0.10, 2.3)],
		"wash": _make_wash(4, 260.0, 900.0, 0.045, 11),
		"bells": [_b(0.0, 440.0, 0.20, 0.9), _b(3.5, 554.0, 0.18, 0.9), _b(7.0, 659.0, 0.20, 0.9)],
		"kicks": [_k(2.0, 72.0, 44.0, 0.32, 0.30), _k(9.0, 72.0, 44.0, 0.28, 0.28)],
	})

	# music_tense — as before, but richer.
	_sounds["music_tense"] = _music_track({
		"dur": 12.0, "peak": 0.70, "trem": [0.25, 0.18],
		"partials": [_p(49.0, 0.50), _p(98.0, 0.32, 0.3), _p(146.9, 0.20, 1.4), _p(196.0, 0.12, 2.0), _p(103.9, 0.10, 0.5)],
		"wash": _make_wash(4, 220.0, 800.0, 0.06, 22),
		"bells": [_b(0.0, 392.0, 0.20, 0.8), _b(2.4, 466.0, 0.18, 0.8), _b(4.8, 392.0, 0.18, 0.8), _b(7.2, 349.0, 0.16, 0.8)],
		"kicks": [_k(1.2, 64.0, 40.0, 0.40, 0.22), _k(1.5, 64.0, 40.0, 0.28, 0.22), _k(6.0, 64.0, 40.0, 0.40, 0.22), _k(6.3, 64.0, 40.0, 0.28, 0.22)],
	})

	# music_broken — as before, but richer and unstable.
	_sounds["music_broken"] = _music_track({
		"dur": 12.0, "peak": 0.80, "trem": [1.5, 0.30],
		"partials": [_p(43.7, 0.50), _p(87.3, 0.30, 0.4), _p(116.6, 0.16, 1.7), _p(131.0, 0.12, 2.6)],
		"wash": _make_wash(5, 200.0, 1400.0, 0.10, 33),
		"bells": [_b(0.0, 330.0, 0.20, 0.7), _b(2.0, 466.0, 0.18, 0.7), _b(4.0, 277.0, 0.20, 0.7), _b(6.0, 415.0, 0.18, 0.7), _b(8.0, 220.0, 0.20, 0.7)],
		"kicks": [_k(3.0, 60.0, 38.0, 0.30, 0.20), _k(9.0, 60.0, 38.0, 0.30, 0.20)],
	})

	# music_hollow — areas 1-2: cold, sparse, long silences, distant.
	_sounds["music_hollow"] = _music_track({
		"dur": 14.0, "peak": 0.50, "trem": [0.143, 0.20],
		"partials": [_p(41.2, 0.50), _p(82.4, 0.22, 0.6), _p(123.6, 0.12, 1.9)],
		"wash": _make_wash(3, 180.0, 600.0, 0.030, 44),
		"bells": [_b(0.0, 294.0, 0.16, 1.0), _b(8.5, 220.0, 0.14, 1.0)],
		"kicks": [_k(6.0, 55.0, 36.0, 0.18, 0.30)],
	})

	# music_watch — areas 3-4: a slow heartbeat dread.
	_sounds["music_watch"] = _music_track({
		"dur": 12.0, "peak": 0.70, "trem": [0.25, 0.25],
		"partials": [_p(36.7, 0.50), _p(73.4, 0.30, 0.5), _p(110.0, 0.20, 1.3), _p(146.9, 0.12, 2.2)],
		"wash": _make_wash(4, 160.0, 650.0, 0.05, 55),
		"bells": [_b(0.0, 220.0, 0.16, 0.9), _b(6.0, 196.0, 0.14, 0.9)],
		"kicks": [_k(0.5, 60.0, 38.0, 0.45, 0.24), _k(0.8, 60.0, 38.0, 0.30, 0.24), _k(3.5, 60.0, 38.0, 0.45, 0.24), _k(3.8, 60.0, 38.0, 0.30, 0.24), _k(6.5, 60.0, 38.0, 0.45, 0.24), _k(6.8, 60.0, 38.0, 0.30, 0.24), _k(9.5, 60.0, 38.0, 0.45, 0.24), _k(9.8, 60.0, 38.0, 0.30, 0.24)],
	})

	# music_wound — areas 5-6: dissonant, breathing, unstable.
	_sounds["music_wound"] = _music_track({
		"dur": 12.0, "peak": 0.80, "trem": [0.167, 0.35],
		"partials": [_p(38.9, 0.50), _p(77.8, 0.28, 0.7), _p(98.0, 0.18, 1.5), _p(116.6, 0.14, 2.4)],
		"wash": _make_wash(4, 180.0, 1000.0, 0.08, 66),
		"bells": [_b(0.0, 311.0, 0.18, 0.7), _b(2.8, 233.0, 0.16, 0.7), _b(5.6, 277.0, 0.17, 0.7), _b(8.4, 196.0, 0.16, 0.7)],
		"kicks": [_k(2.0, 58.0, 36.0, 0.30, 0.22), _k(8.0, 58.0, 36.0, 0.30, 0.22)],
	})

	# music_temple — the blood temple at rest: ritual taiko, gong, heavy drone.
	_sounds["music_temple"] = _music_track({
		"dur": 14.0, "peak": 0.90, "trem": [0.071, 0.12],
		"partials": [_p(32.7, 0.55), _p(65.4, 0.34, 0.3), _p(98.1, 0.22, 1.2), _p(130.8, 0.14, 2.1)],
		"wash": _make_wash(4, 120.0, 500.0, 0.05, 77),
		"bells": [_b(0.0, 130.0, 0.30, 1.4), _b(7.0, 98.0, 0.26, 1.4)],
		"kicks": [_k(0.0, 45.0, 30.0, 0.40, 0.50)],
		"taiko": temple_tk,
	})

	# music_boss — the fight: twelve point eight seconds of taiko that never lets up, over a
	# drone built on the interval the whole cue is named for. Sixteen bars, so the loop
	# closes on the bar rather than mid-phrase.
	_sounds["music_boss"] = _music_track({
		"dur": 12.8, "peak": 0.95, "trem": [0.25, 0.22],
		"partials": [
			_p(55.0, 0.55), _p(77.8, 0.26, 0.4), _p(82.4, 0.30, 0.9),
			_p(110.0, 0.20, 1.6), _p(220.0, 0.10, 0.2),
		],
		"wash": _make_wash(5, 240.0, 2600.0, 0.085, 131),
		"bells": boss_alarm + boss_stabs,
		"kicks": [_k(8.0, 62.0, 40.0, 0.34, 0.24)],
		"taiko": boss_tk,
	})

	# music_after — after the boss: hollow relief.
	_sounds["music_after"] = _music_track({
		"dur": 12.0, "peak": 0.55, "trem": [0.167, 0.15],
		"partials": [_p(41.2, 0.50), _p(82.4, 0.24, 0.5), _p(123.6, 0.13, 1.6)],
		"wash": _make_wash(3, 180.0, 700.0, 0.035, 99),
		"bells": [_b(0.0, 246.0, 0.16, 0.9), _b(5.0, 196.0, 0.14, 0.9)],
		"kicks": [_k(3.0, 55.0, 36.0, 0.20, 0.30)],
	})


# ══════════════════════════ SFX building blocks ══════════════════════════

func _tone(freq: float, dur: float, kind: String, gain: float) -> AudioStreamWAV:
	return _render(dur, gain, func(t: float) -> float:
		return _osc_phase(freq * t, kind))


func _sweep(f0: float, f1: float, dur: float, kind: String, gain: float) -> AudioStreamWAV:
	# Linear chirp with the phase solved analytically, so no state has to be
	# carried between samples: phase_cycles(t) = f0*t + (f1-f0)*t^2 / (2*dur)
	return _render(dur, gain, func(t: float) -> float:
		var cycles: float = f0 * t + (f1 - f0) * t * t / (2.0 * dur)
		return _osc_phase(cycles, kind))


## Analytic chirp phase in cycles, for one-shot sweeps built inside a lambda.
func _ph_sweep(f0: float, f1: float, t: float, dur: float) -> float:
	return f0 * t + (f1 - f0) * t * t / (2.0 * dur)


func _osc_phase(cycles: float, kind: String) -> float:
	var ph := fposmod(cycles, 1.0)
	match kind:
		"square":
			return 1.0 if ph < 0.5 else -1.0
		"tri":
			return absf(ph * 4.0 - 2.0) - 1.0
		"noise":
			return randf() * 2.0 - 1.0
		_:
			return sin(ph * TAU)


## Seamless loop: every partial completes a whole number of cycles in `dur`,
## so the end of the buffer joins the beginning without a click.
func _drone(base: float, dur: float, wobble: float, noise_amt: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(RATE)
		var s := 0.0
		s += sin(TAU * base * t) * 0.50
		s += sin(TAU * base * 1.5 * t + 0.7) * 0.28
		s += sin(TAU * base * 2.0 * t + 1.9) * 0.16
		s *= 0.60 + 0.40 * sin(TAU * wobble * t)
		s += (randf() * 2.0 - 1.0) * noise_amt
		data.encode_s16(i * 2, int(clampf(s * 0.35, -1.0, 1.0) * 32767.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.stereo = false
	st.data = data
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_begin = 0
	st.loop_end = n
	return st


func _render(dur: float, gain: float, fn: Callable) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(RATE)
		var env: float = 1.0 - float(i) / float(n)
		env = env * env
		var v: float = clampf(float(fn.call(t)) * env * gain, -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32767.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.stereo = false
	st.data = data
	return st


## One-shot with a smooth attack, exponential tail and forced silence at the end.
## env(t) = ramp_up(t) * exp(-t/tau) * (1 - t/dur)
func _render_env(dur: float, gain: float, attack: float, tau: float, fn: Callable) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / float(RATE)
		var u := t / dur
		var env := 1.0
		if attack > 0.0:
			env = minf(1.0, t / attack)
		if tau > 0.0:
			env *= exp(-t / tau)
		env *= (1.0 - u)
		buf[i] = float(fn.call(t)) * env * gain
	return _wav_from_float(buf, RATE, false, CLIP_CEIL)


# ══════════════════════════ music building blocks ══════════════════════════

func _init_tables() -> void:
	_sin_tab = PackedFloat32Array()
	_sin_tab.resize(SIN_SIZE)
	for i in range(SIN_SIZE):
		_sin_tab[i] = sin(TAU * float(i) / float(SIN_SIZE))


## Snap a frequency so it completes a whole number of cycles in `dur` seconds
## (dur and the grid are reciprocals). Keeps every tonal layer loop-seamless.
func _snap(f: float, grid: float) -> float:
	var c: float = round(f / grid)
	if c < 1.0:
		c = 1.0
	return c * grid


func _p(f: float, a: float, ph: float = 0.0) -> Dictionary:
	return {"f": f, "a": a, "phase": ph}


func _b(t: float, f: float, a: float, d: float) -> Dictionary:
	return {"t": t, "f": f, "a": a, "d": d}


func _k(t: float, f0: float, f1: float, a: float, d: float) -> Dictionary:
	return {"t": t, "f0": f0, "f1": f1, "a": a, "d": d}


## A band of detuned sine partials, random phases, used as the filtered noise wash.
func _make_wash(count: int, f_lo: float, f_hi: float, amp: float, seed_val: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var arr: Array = []
	for i in range(count):
		arr.append({
			"f": rng.randf_range(f_lo, f_hi),
			"a": amp * rng.randf_range(0.45, 1.0),
			"phase": rng.randf(),
		})
	return arr


func _add_sine_layer(buf: PackedFloat32Array, n: int, f: float, a: float, phase0: float, rate: float) -> void:
	var step := f / rate
	var ph := fposmod(phase0, 1.0)
	var tab := _sin_tab
	for i in range(n):
		var idx := int(ph * SIN_SIZE)
		if idx >= SIN_SIZE:
			idx = SIN_SIZE - 1
		buf[i] += a * tab[idx]
		ph += step
		if ph >= 1.0:
			ph -= 1.0


## A struck bell / gong: inharmonic partials, fast attack, exponential decay
## windowed to silence before the loop end so nothing spills across the seam.
func _add_bell(buf: PackedFloat32Array, n: int, i0: int, f: float, a: float, decay: float, rate: float) -> void:
	if i0 >= n or a <= 0.0:
		return
	var hit_len := int(decay * 3.5 * rate)
	if hit_len < 2:
		return
	var L := mini(n - i0, hit_len)
	if L < 2:
		return
	var ratios := [1.0, 2.76, 4.80]
	var amps := [1.0, 0.55, 0.30]
	var win := PackedFloat32Array()
	win.resize(L)
	var rel := int(L * 0.82)
	for j in range(L):
		var tg := float(j) / rate
		var env := exp(-tg / decay) * minf(1.0, tg / 0.004)
		if j > rel:
			var q := 1.0 - float(j - rel) / float(L - rel)
			env *= q * q
		win[j] = env
	for pi in range(ratios.size()):
		var pf := f * float(ratios[pi])
		var pa := float(amps[pi])
		var step := pf / rate
		var ph := 0.0
		for j in range(L):
			var idx := int(ph * SIN_SIZE)
			if idx >= SIN_SIZE:
				idx = SIN_SIZE - 1
			buf[i0 + j] += a * pa * win[j] * _sin_tab[idx]
			ph += step
			if ph >= 1.0:
				ph -= floor(ph)


## A pitch-swept kick / heartbeat thump, fully contained inside the loop.
func _add_kick(buf: PackedFloat32Array, n: int, i0: int, f0: float, f1: float, a: float, decay: float, rate: float) -> void:
	if i0 >= n or a <= 0.0:
		return
	var hit_len := int(decay * 5.0 * rate)
	if hit_len < 2:
		return
	var L := mini(n - i0, hit_len)
	if L < 2:
		return
	var rel := int(L * 0.85)
	var ph := 0.0
	for j in range(L):
		var tg := float(j) / rate
		var env := exp(-tg / decay)
		if j < 3:
			env *= float(j) / 3.0
		if j > rel:
			var q := 1.0 - float(j - rel) / float(L - rel)
			env *= q * q
		var freq := lerpf(f0, f1, minf(1.0, tg / (decay * 2.0)))
		ph += freq / rate
		if ph >= 1.0:
			ph -= floor(ph)
		var idx := int(ph * SIN_SIZE)
		if idx >= SIN_SIZE:
			idx = SIN_SIZE - 1
		buf[i0 + j] += a * env * _sin_tab[idx]


## A taiko hit: a deep tone plus a short noisy skin slap.
func _add_taiko(buf: PackedFloat32Array, n: int, i0: int, a: float, rate: float) -> void:
	if i0 >= n or a <= 0.0:
		return
	var d := 0.12
	_add_kick(buf, n, i0, 115.0, 52.0, a, d, rate)
	var nd := 0.040
	var nl := int(nd * 5.0 * rate)
	var N := mini(n - i0, nl)
	for j in range(N):
		var tg := float(j) / rate
		var env := exp(-tg / nd) * minf(1.0, tg / 0.0015)
		buf[i0 + j] += a * 0.7 * env * (randf() * 2.0 - 1.0)


## Render one full music cue: layers -> tremolo -> normalise -> seamless WAV.
func _music_track(spec: Dictionary) -> AudioStreamWAV:
	var dur: float = spec["dur"]
	var peak: float = spec.get("peak", CLIP_CEIL)
	var n := int(MUSIC_RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var grid := 1.0 / dur

	for p in spec.get("partials", []):
		_add_sine_layer(buf, n, _snap(float(p["f"]), grid), float(p["a"]), float(p.get("phase", 0.0)), MUSIC_RATE)
	for w in spec.get("wash", []):
		_add_sine_layer(buf, n, _snap(float(w["f"]), grid), float(w["a"]), float(w["phase"]), MUSIC_RATE)
	for b in spec.get("bells", []):
		_add_bell(buf, n, int(float(b["t"]) * MUSIC_RATE), _snap(float(b["f"]), grid), float(b["a"]), float(b["d"]), MUSIC_RATE)
	for k in spec.get("kicks", []):
		_add_kick(buf, n, int(float(k["t"]) * MUSIC_RATE), float(k["f0"]), float(k["f1"]), float(k["a"]), float(k["d"]), MUSIC_RATE)
	for tk in spec.get("taiko", []):
		_add_taiko(buf, n, int(float(tk["t"]) * MUSIC_RATE), float(tk["a"]), MUSIC_RATE)

	var trem: Array = spec.get("trem", [])
	if trem.size() >= 2:
		var tf := _snap(float(trem[0]), grid)
		var td := float(trem[1])
		var tstep := tf / MUSIC_RATE
		var tph := 0.0
		for i in range(n):
			var idx := int(tph * SIN_SIZE)
			if idx >= SIN_SIZE:
				idx = SIN_SIZE - 1
			buf[i] *= (1.0 - td) + td * _sin_tab[idx]
			tph += tstep
			if tph >= 1.0:
				tph -= 1.0

	return _wav_from_float(buf, MUSIC_RATE, true, peak)


## Float buffer -> 16-bit mono WAV, scaled so the peak never exceeds `peak`.
func _wav_from_float(buf: PackedFloat32Array, rate: int, loop: bool, peak: float) -> AudioStreamWAV:
	var n := buf.size()
	var mx := 0.0
	for i in range(n):
		var v := absf(buf[i])
		if v > mx:
			mx = v
	var sc := 1.0
	if mx > peak and mx > 0.000001:
		sc = peak / mx
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var v := buf[i] * sc
		if v > CLIP_CEIL:
			v = CLIP_CEIL
		elif v < -CLIP_CEIL:
			v = -CLIP_CEIL
		data.encode_s16(i * 2, int(round(v * 32767.0)))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = rate
	st.stereo = false
	st.data = data
	if loop:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = n
	return st