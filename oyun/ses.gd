extends RefCounted
# Kodla üretilen sesler (dosya yok): AudioStreamWAV, 16 bit, mono. Açılışta bir kez üretilir, static önbellekte kalır
# (sahne yenilenince yeniden üretilmez). Efektler 22050 Hz, müzik 8000 Hz (yumuşak sinüs, tiz içerik yok).

const RATE := 22050.0
const MUSIC_RATE := 8000.0
const PEAK_MAX := 0.8  # test: hiçbir ses bunu aşmasın

static var bank := {}

# Çarpma sesi dosyaları (CC0, ses/LISANSLAR.md). Anahtar -> yol; eksik ya da bozuksa üretilmiş yedek kalır.
const FILES := {
	hit_fence = "res://ses/cit.ogg", hit_barrel = "res://ses/varil.ogg", hit_bucket = "res://ses/kova.ogg", hit_dog = "res://ses/kopek.ogg",
	hit_egg = "res://ses/yumurta.ogg", hit_cabbage = "res://ses/lahana.ogg", hit_rake = "res://ses/tirmik.ogg",
}


# Ayar dosyasından gelen değer bool değilse varsayılan (açık).
static func parse_on(v: Variant) -> bool:
	return v if v is bool else true


# Tek nota: f0'dan f1'e kayan, harm harmonikli (1/k genlik) sinüs + isteğe bağlı alçak geçiren gürültü; üstel sönüm.
static func note(f0: float, f1: float, dur: float, dec: float, harm := 1, noise := 0.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	var f := f0
	var ratio := pow(f1 / f0, 1.0 / n)
	var env := 1.0
	var k := exp(-dec / RATE)
	var norm := 0.0
	for h in harm:
		norm += 1.0 / (h + 1)
	var lp := 0.0
	var att := 0.004 * RATE
	var rel := 0.006 * RATE
	for i in n:
		ph += TAU * f / RATE
		f *= ratio
		env *= k
		var s := 0.0
		for h in harm:
			s += sin(ph * (h + 1)) / (h + 1)
		s /= norm
		if noise > 0.0:
			lp = lerpf(lp, randf() * 2.0 - 1.0, 0.5)
			s = s * (1.0 - noise) + lp * noise
		out[i] = s * env * minf(1.0, i / att) * minf(1.0, (n - i) / rel)
	return out


# Rüzgâr: gürültü, çan zarfı. c küçüldükçe daha boğuk.
static func whoosh(dur: float, c: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		lp = lerpf(lp, randf() * 2.0 - 1.0, c)
		var e := sin(PI * i / n)
		out[i] = lp * e * e
	return out


# Kıtır: kısa gürültü patlamaları (v: çeşit).
static func crunch(v: int) -> PackedFloat32Array:
	var n := int(0.12 * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := i / RATE
		lp = lerpf(lp, randf() * 2.0 - 1.0, 0.55)
		out[i] = lp * exp(-fmod(t, 0.045) * (70.0 + v * 30.0)) * (1.0 - t / 0.12)
	return out


# Parçaları art arda ekler.
static func seq(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out


# Zirveyi peak'e ölçekler (kırpma yok, her ses benzer yükseklikte), 16 bit mono.
static func to_wav(buf: PackedFloat32Array, rate: float, peak: float) -> AudioStreamWAV:
	var m := 0.0001
	for v in buf:
		m = maxf(m, absf(v))
	var g := peak / m * 32767.0
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(buf[i] * g))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(rate)
	wav.data = data
	return wav


# Müziğe nota ekler (döngü sonuna taşan kuyruk başa sarar: dikişte tık olmaz).
static func add_note(buf: PackedFloat32Array, start: int, f: float, len: int, dec: float, gain: float, h2: float) -> void:
	var n := buf.size()
	var ph := 0.0
	var env := gain
	var k := exp(-dec / MUSIC_RATE)
	for i in len:
		ph += TAU * f / MUSIC_RATE
		env *= k
		buf[(start + i) % n] += (sin(ph) + h2 * sin(ph * 2.0)) * env


# 8 sn döngü: C pentatonik, melodi + bas (16 vuruş x 0,5 sn).
static func music() -> AudioStreamWAV:
	var step := int(MUSIC_RATE * 0.5)
	var buf := PackedFloat32Array()
	buf.resize(step * 16)
	var mel := [659, 784, 880, 784, 659, 587, 523, 0, 587, 659, 784, 659, 587, 523, 587, 0]
	for i in 16:
		if mel[i] > 0:
			add_note(buf, i * step, mel[i], step * 14 / 10, 6.0, 0.5, 0.25)
	var bass := [131, 110, 98, 110]
	for i in 4:
		add_note(buf, i * 4 * step, bass[i], step * 3, 2.5, 0.6, 0.0)
	var wav := to_wav(buf, MUSIC_RATE, 0.5)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = buf.size()
	return wav


# Dosya seslerini yükler; olmayan ya da yüklenemeyen sessizce atlanır (yedek: make_all).
static func load_files(files := FILES) -> Dictionary:
	var out := {}
	for k in files:
		if ResourceLoader.exists(files[k]):
			var st = load(files[k])
			if st is AudioStream and st.get_length() > 0.02:
				out[k] = st
	return out


# Tüm efektler + müzik; ilk çağrıda üretilir.
static func make_all() -> Dictionary:
	if not bank.is_empty():
		return bank
	var b := {}
	b.jump = to_wav(note(280, 620, 0.14, 14), RATE, 0.5)
	b.land = to_wav(note(150, 70, 0.1, 28, 1, 0.25), RATE, 0.5)
	b.carrot = to_wav(seq([note(784, 784, 0.07, 12, 2), note(1175, 1175, 0.18, 14, 2)]), RATE, 0.5)
	b.bonk = to_wav(note(200, 80, 0.22, 14, 2, 0.15), RATE, 0.7)
	b.dash = to_wav(whoosh(0.32, 0.18), RATE, 0.5)
	b.throw = to_wav(whoosh(0.22, 0.3), RATE, 0.4)
	b.near = to_wav(note(1200, 1200, 0.05, 50), RATE, 0.35)
	b.bark = to_wav(note(420, 240, 0.17, 16, 4, 0.2), RATE, 0.6)
	b.goose = to_wav(note(560, 420, 0.17, 9, 4, 0.15), RATE, 0.55)
	b.win = to_wav(seq([note(523, 523, 0.11, 8, 2), note(659, 659, 0.11, 8, 2), note(784, 784, 0.11, 8, 2), note(1047, 1047, 0.4, 6, 2)]), RATE, 0.5)
	b.lose = to_wav(seq([note(392, 330, 0.16, 6, 2), note(330, 262, 0.16, 6, 2), note(262, 196, 0.4, 5, 2)]), RATE, 0.5)
	b.click = to_wav(note(660, 660, 0.05, 50), RATE, 0.4)
	b.hey = to_wav(note(330, 520, 0.24, 5, 4, 0.1), RATE, 0.6)
	b.crunch0 = to_wav(crunch(0), RATE, 0.6)
	b.crunch1 = to_wav(crunch(1), RATE, 0.6)
	# Çarpma seslerinin üretilmiş yedekleri (dosya yoksa bunlar çalar; tavuk her zaman bu)
	b.hit_fence = to_wav(note(320, 140, 0.12, 32, 3, 0.4), RATE, 0.5)
	b.hit_barrel = to_wav(note(130, 60, 0.2, 18, 2, 0.2), RATE, 0.55)
	b.hit_chicken = to_wav(seq([note(520, 760, 0.06, 20, 3, 0.1), note(480, 700, 0.06, 20, 3, 0.1), note(430, 620, 0.1, 14, 3, 0.1)]), RATE, 0.5)
	b.hit_dog = to_wav(note(300, 150, 0.13, 22, 4, 0.3), RATE, 0.55)
	b.hit_bucket = to_wav(seq([note(900, 860, 0.1, 18, 3, 0.1), note(1320, 1280, 0.12, 22, 3, 0.1)]), RATE, 0.45)
	b.hit_egg = to_wav(whoosh(0.1, 0.5), RATE, 0.5)
	b.hit_cabbage = to_wav(note(120, 60, 0.1, 30, 1, 0.2), RATE, 0.55)
	b.hit_rake = to_wav(note(1400, 1300, 0.08, 40, 2), RATE, 0.4)
	b.music = music()
	bank = b
	return b


# Dalga biçimi denetimi: boş dize = sağlam. Süre, tepe (<= PEAK_MAX), kırpma, sessizlik.
static func check(wav: AudioStreamWAV) -> String:
	var n := wav.data.size() / 2
	if n < 0.03 * wav.mix_rate:
		return "çok kısa"
	var peak := 0
	var clipped := 0
	for i in n:
		var v := absi(wav.data.decode_s16(i * 2))
		peak = maxi(peak, v)
		if v >= 32767:
			clipped += 1
	if clipped > 0:
		return "kırpılmış"
	if peak < 0.05 * 32767:
		return "neredeyse sessiz"
	if peak > PEAK_MAX * 32767:
		return "tepe çok yüksek"
	return ""
