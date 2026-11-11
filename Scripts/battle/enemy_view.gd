extends Node2D
## Tampilan musuh di arena battle.
##
## - Membuat animasi dari frame PNG (idle + satu animasi per skill) sesuai data musuh.
## - Menampilkan kartu skill kecil di atas kepala (intent), supaya pemain tahu serangan berikutnya.
## - Memainkan animasi skill + efek (proyektil / sinar / gelembung), lalu memanggil `on_impact`
##   tepat saat serangan "kena".

const BattleData = preload("res://Scripts/battle/battle_data.gd")

const FRAME_BASE_MS := 125.0
const INTENT_CARD_SCALE := 0.5

var enemy_id: String = ""
var data: Dictionary = {}

var _base_scale: float = 1.0
var _power_mult: float = 1.0
var _bubble: Sprite2D = null
var _bob_tween: Tween
var _card_bob_tween: Tween
var _intent_tween: Tween
var _flash_tween: Tween
var _scale_tween: Tween

@onready var body: AnimatedSprite2D = $Body
@onready var fx_root: Node2D = $Fx
@onready var intent_root: Node2D = $IntentRoot
@onready var intent_card: Sprite2D = $IntentRoot/Card
@onready var intent_label: Label = $IntentRoot/Label


func setup(id: String, enemy_data: Dictionary) -> void:
	enemy_id = id
	data = enemy_data

	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var anims: Dictionary = data["animations"]
	for anim_name in anims:
		var info: Dictionary = anims[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, bool(info["loop"]))
		frames.set_animation_speed(anim_name, 1000.0 / FRAME_BASE_MS)
		var durations: Array = info["ms"]
		for i in durations.size():
			var path := "%s%s/%s_%d.png" % [BattleData.ENEMY_DIR, enemy_id, anim_name, i + 1]
			var texture := load(path) as Texture2D
			frames.add_frame(anim_name, texture, float(durations[i]) / FRAME_BASE_MS)

	body.sprite_frames = frames
	body.centered = false
	# Titik kaki musuh = origin node ini, jadi posisi node = posisi tanah.
	var feet: Vector2 = data["feet"]
	body.offset = -feet
	_base_scale = float(data["display_height"]) / float(data["ref_height"])
	body.scale = Vector2.ONE * _base_scale
	body.play(&"idle")
	_start_idle_bob()
	_update_intent_position()


func reset() -> void:
	_power_mult = 1.0
	if _scale_tween:
		_scale_tween.kill()
	if _flash_tween:
		_flash_tween.kill()
	body.scale = Vector2.ONE * _base_scale
	body.modulate = Color.WHITE
	body.play(&"idle")
	hide_intent(false)
	if _bubble:
		_bubble.visible = false
	_start_idle_bob()
	_update_intent_position()


# ------------------------------------------------------------------ Idle

func _start_idle_bob() -> void:
	if _bob_tween:
		_bob_tween.kill()
	body.position.y = 0.0
	var amplitude := float(data.get("idle_bob", 0.0))
	if amplitude <= 0.0:
		return
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(body, "position:y", -amplitude, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(body, "position:y", 0.0, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _head_height() -> float:
	return float(data["ref_height"]) * _base_scale * _power_mult


func _update_intent_position() -> void:
	intent_root.position = Vector2(0.0, -_head_height() - 58.0)


# ----------------------------------------------------------- Kartu intent

## Tampilkan kartu skill kecil di atas kepala musuh.
func show_intent(skill: Dictionary) -> void:
	intent_card.texture = load(str(skill["art"])) as Texture2D
	intent_card.scale = Vector2.ONE * INTENT_CARD_SCALE
	intent_label.text = str(skill.get("label", ""))
	_update_intent_position()

	if _intent_tween:
		_intent_tween.kill()
	if _card_bob_tween:
		_card_bob_tween.kill()

	intent_root.visible = true
	intent_root.scale = Vector2(0.2, 0.2)
	intent_root.modulate.a = 0.0
	_intent_tween = create_tween().set_parallel(true)
	_intent_tween.tween_property(intent_root, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intent_tween.tween_property(intent_root, "modulate:a", 1.0, 0.2)

	# Kartu melayang pelan supaya menarik perhatian.
	intent_card.position.y = 0.0
	_card_bob_tween = create_tween().set_loops()
	_card_bob_tween.tween_property(intent_card, "position:y", -4.0, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_bob_tween.tween_property(intent_card, "position:y", 0.0, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func hide_intent(animated: bool = true) -> void:
	if _card_bob_tween:
		_card_bob_tween.kill()
	if _intent_tween:
		_intent_tween.kill()
	if not intent_root.visible:
		return
	if not animated:
		intent_root.visible = false
		return
	_intent_tween = create_tween().set_parallel(true)
	_intent_tween.tween_property(intent_root, "scale", Vector2(1.35, 1.35), 0.18)
	_intent_tween.tween_property(intent_root, "modulate:a", 0.0, 0.18)
	_intent_tween.chain().tween_callback(func() -> void: intent_root.visible = false)


# ------------------------------------------------------------ Skill & efek

## Mainkan animasi skill + efek. `on_impact` dipanggil saat serangan mengenai target.
## Fungsi ini selesai setelah animasi kembali ke idle.
func play_skill(skill: Dictionary, target_global: Vector2, on_impact: Callable) -> void:
	hide_intent(true)
	var anim := str(skill.get("animation", ""))
	var has_anim := anim != "" and body.sprite_frames.has_animation(anim)
	if has_anim:
		body.play(anim)

	await get_tree().create_timer(float(skill.get("release_ms", 300)) / 1000.0, false).timeout
	await _play_fx(skill, target_global)
	if on_impact.is_valid():
		on_impact.call()

	if has_anim and body.animation == StringName(anim) and body.is_playing():
		await body.animation_finished
	body.play(&"idle")
	await get_tree().create_timer(0.15, false).timeout


func _play_fx(skill: Dictionary, target_global: Vector2) -> void:
	var fx: Dictionary = skill.get("fx", {})
	var fx_type := str(fx.get("type", "none"))
	if fx_type == "projectile":
		await _fx_projectile(fx, target_global)
	elif fx_type == "beam":
		await _fx_beam(fx, target_global)
	elif fx_type == "bubble":
		await _fx_bubble(fx)
	elif fx_type == "grow":
		await _fx_wind_up()
	elif fx_type == "glow":
		await _fx_glow(fx.get("color", Color(0.6, 1.0, 0.7, 1.0)))


func _muzzle_global() -> Vector2:
	var offset: Vector2 = data.get("muzzle", Vector2(-50, -80))
	return global_position + offset * _power_mult


func _fx_projectile(fx: Dictionary, target_global: Vector2) -> void:
	var textures: Array = fx["textures"]
	var duration := float(fx.get("duration", 0.35))
	var proj_scale := float(fx.get("scale", 0.5))
	var arc := float(fx.get("arc", 60.0))
	var spin := float(fx.get("spin", 0.0))
	var start := _muzzle_global()
	var last_tween: Tween = null

	for i in textures.size():
		var sprite := Sprite2D.new()
		sprite.texture = load(str(textures[i])) as Texture2D
		sprite.scale = Vector2.ONE * proj_scale
		sprite.flip_h = true  # gambar proyektil menghadap kanan, musuh menembak ke kiri
		fx_root.add_child(sprite)
		sprite.global_position = start
		var end := target_global + Vector2(0.0, float(i) * 16.0 - 8.0 * float(textures.size() - 1))

		var tween := create_tween().set_parallel(true)
		tween.tween_method(
			func(p: float) -> void: _move_projectile(sprite, start, end, arc, p),
			0.0, 1.0, duration)
		if spin != 0.0:
			tween.tween_property(sprite, "rotation", spin, duration)
		tween.chain().tween_callback(sprite.queue_free)
		last_tween = tween

		if i < textures.size() - 1:
			await get_tree().create_timer(0.14, false).timeout

	if last_tween != null:
		await last_tween.finished


func _move_projectile(sprite: Sprite2D, start: Vector2, end: Vector2, arc: float, p: float) -> void:
	if not is_instance_valid(sprite):
		return
	sprite.global_position = start.lerp(end, p) + Vector2(0.0, -arc * sin(p * PI))


func _fx_beam(fx: Dictionary, target_global: Vector2) -> void:
	var color: Color = fx.get("color", Color(0.5, 0.9, 1.0, 1.0))
	var width := float(fx.get("width", 26.0))

	var holder := Node2D.new()
	fx_root.add_child(holder)
	holder.global_position = _muzzle_global()
	var end_local := holder.to_local(target_global)

	var glow := _make_beam_line(end_local, Color(color.r, color.g, color.b, 0.75))
	var core := _make_beam_line(end_local, Color(1.0, 1.0, 1.0, 0.95))
	holder.add_child(glow)
	holder.add_child(core)

	var grow := create_tween().set_parallel(true)
	grow.tween_property(glow, "width", width, 0.12)
	grow.tween_property(core, "width", width * 0.35, 0.12)
	await grow.finished

	# Sinar memudar sendiri sementara pemanggil sudah lanjut ke damage.
	var fade := create_tween().set_parallel(true)
	fade.tween_property(glow, "width", 0.0, 0.3).set_delay(0.15)
	fade.tween_property(core, "width", 0.0, 0.3).set_delay(0.15)
	fade.chain().tween_callback(holder.queue_free)


func _make_beam_line(end_local: Vector2, color: Color) -> Line2D:
	var line := Line2D.new()
	line.points = PackedVector2Array([Vector2.ZERO, end_local])
	line.width = 0.0
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	line.material = material
	return line


func _fx_bubble(fx: Dictionary) -> void:
	_ensure_bubble(str(fx.get("texture", "")))
	var target := _bubble_target_scale()
	_bubble.visible = true
	_bubble.modulate.a = 0.0
	_bubble.scale = target * 0.3
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_bubble, "scale", target, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_bubble, "modulate:a", 0.8, 0.3)
	await tween.finished


func _ensure_bubble(texture_path: String) -> void:
	if _bubble != null:
		_bubble.position = Vector2(0.0, -_head_height() * 0.5)
		return
	_bubble = Sprite2D.new()
	_bubble.texture = load(texture_path) as Texture2D
	_bubble.position = Vector2(0.0, -_head_height() * 0.5)
	_bubble.visible = false
	add_child(_bubble)


func _bubble_target_scale() -> Vector2:
	var diameter := _head_height() * 1.35
	return Vector2.ONE * (diameter / float(_bubble.texture.get_width()))


## Gelembung pantul: tampil selama efek Reflect aktif.
func set_reflect(active: bool) -> void:
	if _bubble == null or active:
		return
	var tween := create_tween()
	tween.tween_property(_bubble, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void: _bubble.visible = false)


func bounce_bubble() -> void:
	if _bubble == null or not _bubble.visible:
		return
	var target := _bubble_target_scale()
	var tween := create_tween()
	tween.tween_property(_bubble, "scale", target * 1.15, 0.08)
	tween.tween_property(_bubble, "scale", target, 0.15)


func _fx_wind_up() -> void:
	var current := Vector2.ONE * _base_scale * _power_mult
	var tween := create_tween()
	tween.tween_property(body, "scale", Vector2(current.x * 1.08, current.y * 0.85), 0.18)
	tween.tween_property(body, "scale", current, 0.12)
	await tween.finished


func _fx_glow(color: Color) -> void:
	var tween := create_tween()
	tween.tween_property(body, "modulate", color, 0.2)
	tween.tween_property(body, "modulate", Color.WHITE, 0.3)
	await tween.finished


# ---------------------------------------------------------- Efek pendukung

## Kedip warna singkat (kena serangan / buff).
func flash(color: Color) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(body, "modulate", color, 0.08)
	_flash_tween.tween_property(body, "modulate", Color.WHITE, 0.14)


## Tubuh membesar sesuai jumlah stack Power (efek Biggy).
func set_power(stacks: int) -> void:
	_power_mult = 1.0 + 0.12 * float(stacks)
	_update_intent_position()
	if _scale_tween:
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.tween_property(body, "scale", Vector2.ONE * _base_scale * _power_mult, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func play_defeat() -> void:
	hide_intent(true)
	var tween := create_tween()
	tween.tween_property(body, "modulate", Color(1.0, 1.0, 1.0, 0.25), 0.8)
