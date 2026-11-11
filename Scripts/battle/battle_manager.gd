extends Control
## Battle kartu bergiliran.
##
## Alur satu giliran: Alto memainkan SATU kartu -> musuh membalas dengan skill yang
## sudah ditampilkan sebagai kartu kecil di atas kepalanya.
## Data kartu & musuh ada di battle_data.gd.

signal battle_ended(player_won: bool)

enum State { PLAYER_TURN, ACTION_RESOLVING, ENEMY_TURN, WON, LOST }

const BattleData = preload("res://Scripts/battle/battle_data.gd")

const HAND_SIZE := 4
const PLAYER_MAX_HP := 30
const BURN_DAMAGE := 3
const SLOW_DAMAGE_MULT := 0.7
const REFLECT_RATIO := 0.5

## Ukuran kartu tangan Alto. Gambar asli 118x168 px; ubah CARD_SCALE untuk membesar/mengecilkan.
const CARD_SCALE := 1.5
const CARD_SRC_W := 118.0
const CARD_SRC_H := 168.0
const CARD_W := CARD_SRC_W * CARD_SCALE
const CARD_H := CARD_SRC_H * CARD_SCALE
const CARD_PEEK := CARD_H * 2.0 / 3.0    # tinggi kartu yang terlihat saat tidak di-hover
const CARD_RAISE := CARD_H - CARD_PEEK   # kartu naik segini saat di-hover (CARD_PEEK + CARD_RAISE = CARD_H)
## Area kosong (kotak coklat) di gambar kartu tempat deskripsi ditulis, dalam piksel gambar asli.
const CARD_TEXT_RECT := Rect2(23.0, 112.0, 72.0, 45.0)
## Ukuran font deskripsi: dicoba dari terbesar, mengecil otomatis sampai teks muat di area kartu.
const CARD_TEXT_MAX_FONT := 16
const CARD_TEXT_MIN_FONT := 8

const COLOR_HIT := Color(1.0, 0.3, 0.3)
const COLOR_BLOCK := Color(0.4, 0.8, 1.0)
const COLOR_HEAL := Color(0.4, 1.0, 0.5)

## Musuh yang dilawan (kunci di BattleData.ENEMIES). Kosong = "slimy".
@export var enemy_id: String = ""
## Scene yang dibuka setelah menang.
@export_file("*.tscn") var next_scene_on_win: String = ""
## true = setelah menang muncul pilihan Hancurkan / Maafkan (khusus Slimy).
@export var offer_mercy_choice: bool = false
## Dialog kemenangan khusus (opsional). Jika diisi di Inspector, dialog ini yang akan dipakai.
@export var custom_victory_dialogue: Array[Dictionary] = []

var state: State = State.PLAYER_TURN
var turn_count: int = 1

var player_hp: int = PLAYER_MAX_HP
var player_max_hp: int = PLAYER_MAX_HP
var player_block: int = 0
var player_status: Dictionary = {"slow": 0, "burn": 0, "dizzy": 0}

var enemy: Dictionary = {}
var enemy_name: String = ""
var enemy_hp: int = 0
var enemy_max_hp: int = 0
var enemy_block: int = 0
var enemy_status: Dictionary = {"reflect": 0, "strength": 0}
var enemy_intent: Dictionary = {}
var _last_skill_id: String = ""

var deck: Array = []
var hand: Array = []
var discard: Array = []
var rng := RandomNumberGenerator.new()

var alto_initial_pos: Vector2
var _leaving: bool = false

@onready var stage: Node2D = $Stage
@onready var background: Sprite2D = $Stage/Background
@onready var alto: CharacterBody2D = $Stage/Alto
@onready var enemy_view = $Stage/Enemy

@onready var enemy_name_label: Label = %EnemyName
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var enemy_hp_label: Label = %EnemyHPLabel
@onready var enemy_block_label: Label = %EnemyBlock
@onready var enemy_status_label: Label = %EnemyStatus
@onready var enemy_intent_label: Label = %EnemyIntent

@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var player_hp_label: Label = %PlayerHPLabel
@onready var player_block_label: Label = %PlayerBlock
@onready var player_status_label: Label = %PlayerStatus

@onready var turn_label: Label = %TurnLabel
@onready var log_label: RichTextLabel = %LogLabel
@onready var hand_container: HBoxContainer = %HandContainer
@onready var deck_label: Label = %DeckLabel
@onready var discard_label: Label = %DiscardLabel

@onready var overlay: ColorRect = %Overlay
@onready var result_label: Label = %ResultLabel
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton
@onready var actions_row: HBoxContainer = %Actions
@onready var choice_container: HBoxContainer = %ChoiceContainer
@onready var destroy_button: Button = %DestroyButton
@onready var forgive_button: Button = %ForgiveButton
@onready var dialogue_box = get_node_or_null("DialogueBox")


func _ready() -> void:
	if enemy_id.is_empty():
		enemy_id = "slimy"
	enemy = BattleData.ENEMIES[enemy_id]

	# Battle berjalan lewat kartu dan giliran, jadi kontrol platformer Alto dikunci.
	alto.can_move = false
	alto.auto_direction = 0.0
	alto.velocity = Vector2.ZERO
	alto.set_physics_process(false)
	# Kamera Alto dimatikan agar arena tidak bergeser mengikuti Alto.
	alto.camera.enabled = false
	alto_initial_pos = alto.position
	rng.randomize()

	background.texture = load(str(enemy["background"])) as Texture2D
	enemy_view.setup(enemy_id, enemy)

	# Tinggi area tangan mengikuti ukuran kartu (CARD_SCALE).
	hand_container.offset_top = -CARD_PEEK
	var hand_space := get_node_or_null("HUD/Layout/HandSpace") as Control
	if hand_space:
		hand_space.custom_minimum_size.y = CARD_PEEK

	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	destroy_button.pressed.connect(_on_destroy_pressed)
	forgive_button.pressed.connect(_on_forgive_pressed)

	start_battle()


func start_battle() -> void:
	state = State.PLAYER_TURN
	turn_count = 1
	_leaving = false
	player_hp = player_max_hp
	player_block = 0
	player_status = {"slow": 0, "burn": 0, "dizzy": 0}

	enemy_name = str(enemy["name"])
	enemy_max_hp = int(enemy["max_hp"])
	enemy_hp = enemy_max_hp
	enemy_block = 0
	enemy_status = {"reflect": 0, "strength": 0}
	enemy_intent = {}
	_last_skill_id = ""
	enemy_view.reset()

	alto.position = alto_initial_pos
	alto.modulate = Color.WHITE

	deck = _build_deck()
	deck.shuffle()
	hand.clear()
	discard.clear()
	log_label.clear()
	overlay.hide()
	choice_container.hide()
	actions_row.show()
	hand_container.show()
	if dialogue_box and dialogue_box.is_active:
		dialogue_box._close()

	_log("[b]Battle dimulai![/b] Melawan %s." % enemy_name)
	_begin_player_turn(true)


# ------------------------------------------------------------------ Deck

func _build_deck() -> Array:
	var cards: Array = []
	var n := 0
	for card_id in BattleData.ALTO_DECK:
		for i in int(BattleData.ALTO_DECK[card_id]):
			var card: Dictionary = BattleData.ALTO_CARDS[card_id].duplicate()
			card["id"] = card_id
			card["uid"] = "%s_%d_%d" % [card_id, n, rng.randi()]
			cards.append(card)
			n += 1
	return cards


func _draw_cards_until(target_count: int) -> void:
	while hand.size() < target_count:
		if deck.is_empty():
			if discard.is_empty():
				break
			deck = discard.duplicate()
			discard.clear()
			deck.shuffle()
			_log("Deck dikocok ulang dari discard.")
		hand.append(deck.pop_back())
	_rebuild_hand_ui()


# ---------------------------------------------------------- Giliran Alto

func _begin_player_turn(first_turn: bool) -> void:
	state = State.PLAYER_TURN
	player_block = 0
	if not first_turn:
		turn_count += 1
	_log("[color=yellow]- Giliran Pemain (Turn %d) -[/color]" % turn_count)

	_draw_cards_until(HAND_SIZE)

	# Terbakar: damage tiap awal giliran, menembus block.
	if int(player_status["burn"]) > 0:
		player_status["burn"] = int(player_status["burn"]) - 1
		player_hp = maxi(player_hp - BURN_DAMAGE, 0)
		_log("[color=orange]Alto terbakar! -%d HP.[/color]" % BURN_DAMAGE)
		_popup(alto.global_position + Vector2(0, -150), "-%d" % BURN_DAMAGE, Color(1.0, 0.6, 0.2))
		_flash_node(alto, Color(1.0, 0.6, 0.3))
		_refresh_ui()
		if _check_end():
			return

	enemy_intent = _choose_enemy_skill()
	enemy_view.show_intent(enemy_intent)
	_log("Musuh bersiap memakai [b]%s[/b]." % str(enemy_intent["name"]))

	_refresh_ui()
	_set_hand_buttons_disabled(false)


func _on_card_pressed(index: int) -> void:
	if state != State.PLAYER_TURN:
		return
	if index < 0 or index >= hand.size():
		return

	# Kunci input kartu saat aksi sedang diselesaikan.
	state = State.ACTION_RESOLVING
	_set_hand_buttons_disabled(true)

	# Pusing: kartu yang dimainkan dipilih acak.
	if int(player_status["dizzy"]) > 0:
		player_status["dizzy"] = int(player_status["dizzy"]) - 1
		var random_index := rng.randi_range(0, hand.size() - 1)
		if random_index != index:
			_log("[color=violet]Alto pusing! Kartu terpilih secara acak.[/color]")
		index = random_index

	var card: Dictionary = hand[index]
	hand.remove_at(index)
	discard.append(card)
	_rebuild_hand_ui()
	_set_hand_buttons_disabled(true)

	await _resolve_player_card(card)
	_tick_after_player_card()
	_refresh_ui()

	if _check_end():
		return

	# Jeda sejenak sebelum musuh membalas.
	await get_tree().create_timer(0.5, false).timeout
	if state != State.ACTION_RESOLVING:
		return
	await _begin_enemy_turn()


func _resolve_player_card(card: Dictionary) -> void:
	var damage := int(card["damage"])
	var block := int(card["block"])
	var heal := int(card["heal"])
	_log("Kamu memakai [b]%s[/b]." % str(card["name"]))

	if damage > 0:
		await _animate_player_attack()
		if int(player_status["slow"]) > 0:
			damage = int(float(damage) * SLOW_DAMAGE_MULT)
			_log("[color=gray]Alto lambat: damage berkurang jadi %d.[/color]" % damage)
		if int(enemy_status["reflect"]) > 0:
			var bounced := int(float(damage) * REFLECT_RATIO)
			var taken := _damage_player(bounced)
			enemy_view.bounce_bubble()
			_flash_node(alto, COLOR_HIT)
			_popup(alto.global_position + Vector2(0, -150), "-%d" % taken, COLOR_HIT)
			_log("[color=cyan]Serangan dipantulkan gelembung![/color] Alto menerima %d damage." % taken)
		else:
			var dealt := _damage_enemy(damage)
			enemy_view.flash(COLOR_HIT)
			_popup(enemy_view.global_position + Vector2(0, -150), "-%d" % dealt, Color(1.0, 0.85, 0.3))
			_log("%d damage ke %s." % [dealt, enemy_name])

	if block > 0:
		player_block += block
		if damage <= 0:
			await _animate_player_buff(COLOR_BLOCK)
		else:
			_flash_node(alto, COLOR_BLOCK)
		_popup(alto.global_position + Vector2(0, -150), "+%d Block" % block, COLOR_BLOCK)
		_log("+%d block." % block)

	if heal > 0:
		var healed := mini(heal, player_max_hp - player_hp)
		player_hp += healed
		if damage <= 0 and block <= 0:
			await _animate_player_buff(COLOR_HEAL)
		else:
			_flash_node(alto, COLOR_HEAL)
		_popup(alto.global_position + Vector2(0, -180), "+%d HP" % healed, COLOR_HEAL)
		_log("Memulihkan %d HP." % healed)


func _tick_after_player_card() -> void:
	if int(player_status["slow"]) > 0:
		player_status["slow"] = int(player_status["slow"]) - 1
	if int(enemy_status["reflect"]) > 0:
		enemy_status["reflect"] = int(enemy_status["reflect"]) - 1
		if int(enemy_status["reflect"]) == 0:
			enemy_view.set_reflect(false)


# ---------------------------------------------------------- Giliran musuh

func _begin_enemy_turn() -> void:
	state = State.ENEMY_TURN
	enemy_block = 0
	_refresh_ui()
	_log("[color=orange]- Giliran %s -[/color]" % enemy_name)

	await get_tree().create_timer(0.3, false).timeout
	await _execute_enemy_skill()
	_refresh_ui()

	if _check_end():
		return

	# Jeda sebelum kembali ke giliran pemain.
	await get_tree().create_timer(0.5, false).timeout
	_begin_player_turn(false)


## Pilih skill berikutnya berdasarkan bobot + aturan di data musuh.
func _choose_enemy_skill() -> Dictionary:
	var skills: Dictionary = enemy["skills"]
	var candidates: Array = []
	var total := 0
	for skill_id in skills:
		var skill: Dictionary = skills[skill_id]
		if bool(skill.get("no_repeat", false)) and str(skill_id) == _last_skill_id:
			continue
		if skill.has("hp_below") and float(enemy_hp) > float(enemy_max_hp) * float(skill["hp_below"]):
			continue
		if skill.has("max_strength") and int(enemy_status["strength"]) >= int(skill["max_strength"]):
			continue
		if skill.has("gain") and (skill["gain"] as Dictionary).has("reflect") and int(enemy_status["reflect"]) > 0:
			continue
		candidates.append(skill_id)
		total += int(skill["weight"])

	if candidates.is_empty():
		for skill_id in skills:
			candidates.append(skill_id)
			total += int(skills[skill_id]["weight"])

	var roll := rng.randi_range(1, total)
	var picked = candidates[0]
	for skill_id in candidates:
		roll -= int(skills[skill_id]["weight"])
		if roll <= 0:
			picked = skill_id
			break

	_last_skill_id = str(picked)
	var chosen: Dictionary = (skills[picked] as Dictionary).duplicate()
	chosen["id"] = picked
	return chosen


func _execute_enemy_skill() -> void:
	if enemy_intent.is_empty():
		return
	var skill: Dictionary = enemy_intent
	_log("%s memakai [b]%s[/b]!" % [enemy_name, str(skill["name"])])
	var target := alto.global_position + Vector2(0.0, -80.0)
	await enemy_view.play_skill(skill, target, _on_enemy_skill_impact.bind(skill))
	enemy_intent = {}


## Dipanggil tepat saat serangan/efek musuh mengenai sasaran.
func _on_enemy_skill_impact(skill: Dictionary) -> void:
	var damage := int(skill.get("damage", 0))
	if damage > 0:
		damage += int(enemy_status["strength"])
		var dealt := _damage_player(damage)
		_flash_node(alto, COLOR_HIT)
		_popup(alto.global_position + Vector2(0, -150), "-%d" % dealt, COLOR_HIT)
		_log("%d damage (diterima %d)." % [damage, dealt])

	var block := int(skill.get("block", 0))
	if block > 0:
		enemy_block += block
		enemy_view.flash(COLOR_BLOCK)
		_popup(enemy_view.global_position + Vector2(0, -150), "+%d Block" % block, COLOR_BLOCK)
		_log("%s mendapat %d block." % [enemy_name, block])

	var heal := int(skill.get("heal", 0))
	if heal > 0:
		var healed := mini(heal, enemy_max_hp - enemy_hp)
		enemy_hp += healed
		_popup(enemy_view.global_position + Vector2(0, -150), "+%d HP" % healed, COLOR_HEAL)
		_log("%s memulihkan %d HP." % [enemy_name, healed])

	var inflict: Dictionary = skill.get("inflict", {})
	for status in inflict:
		player_status[status] = maxi(int(player_status[status]), int(inflict[status]))
		_log("[color=violet]Alto terkena %s (%d giliran).[/color]" % [_status_name(str(status)), int(inflict[status])])

	var gain: Dictionary = skill.get("gain", {})
	for status in gain:
		if str(status) == "strength":
			var cap := int(skill.get("max_strength", 999))
			enemy_status["strength"] = mini(int(enemy_status["strength"]) + int(gain[status]), cap)
			enemy_view.set_power(int(enemy_status["strength"]) / 4)
			_log("[color=red]%s makin kuat! Semua serangannya +%d damage.[/color]" % [enemy_name, int(enemy_status["strength"])])
		else:
			enemy_status[status] = maxi(int(enemy_status[status]), int(gain[status]))
			_log("[color=cyan]%s mendapat %s.[/color]" % [enemy_name, _status_name(str(status))])

	_refresh_ui()


# ------------------------------------------------------------------ Kartu UI

func _rebuild_hand_ui() -> void:
	for child in hand_container.get_children():
		hand_container.remove_child(child)
		child.queue_free()
	for i in hand.size():
		hand_container.add_child(_make_card_widget(hand[i], i))


func _make_card_widget(card: Dictionary, index: int) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(CARD_W, CARD_PEEK)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var button := TextureButton.new()
	button.texture_normal = load(str(card["art"])) as Texture2D
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.custom_minimum_size = Vector2(CARD_W, CARD_H)
	button.size = Vector2(CARD_W, CARD_H)
	button.position = Vector2.ZERO
	button.disabled = (state != State.PLAYER_TURN)
	button.modulate = Color(0.6, 0.6, 0.6) if button.disabled else Color.WHITE
	button.pressed.connect(_on_card_pressed.bind(index))
	button.mouse_entered.connect(_on_card_hover.bind(button, true))
	button.mouse_exited.connect(_on_card_hover.bind(button, false))
	button.focus_entered.connect(_on_card_hover.bind(button, true))
	button.focus_exited.connect(_on_card_hover.bind(button, false))

	# Gambar kartu Alto belum punya teks deskripsi, jadi ditulis oleh kode di area kosong.
	var text := str(card.get("text", ""))
	if not text.is_empty():
		var area: Vector2 = CARD_TEXT_RECT.size * CARD_SCALE
		var label := Label.new()
		# PENTING: aktifkan wrap & atur font SEBELUM ukuran diisi. Kalau size diisi lebih dulu,
		# Godot melebarkan label sesuai teks satu baris sehingga teks keluar dari kartu.
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# (Jangan pakai clip_text: huruf font Baskic8 lebih tinggi dari ascent-nya sehingga ujungnya terpotong.)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", _fit_card_font_size(label, text, area))
		label.add_theme_color_override("font_color", Color(0.22, 0.12, 0.06))
		label.add_theme_constant_override("line_spacing", 1)
		label.text = text
		label.custom_minimum_size = area
		label.position = CARD_TEXT_RECT.position * CARD_SCALE
		label.size = area
		button.add_child(label)

	slot.add_child(button)
	return slot


## Cari ukuran font terbesar yang membuat teks (setelah di-wrap) muat di dalam area deskripsi kartu.
func _fit_card_font_size(label: Label, text: String, area: Vector2) -> int:
	var font: Font = label.get_theme_default_font()
	if font == null:
		return CARD_TEXT_MIN_FONT
	for font_size in range(CARD_TEXT_MAX_FONT, CARD_TEXT_MIN_FONT - 1, -1):
		var needed: Vector2 = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, area.x, font_size)
		var line_h: float = font.get_height(font_size)
		var lines: float = maxf(roundf(needed.y / line_h), 1.0)
		if needed.y + (lines - 1.0) * 1.0 <= area.y:
			return font_size
	return CARD_TEXT_MIN_FONT


func _on_card_hover(button: TextureButton, hovered: bool) -> void:
	if not is_instance_valid(button):
		return
	if hovered and button.disabled:
		return
	if button.has_meta("hover_tween"):
		var old: Tween = button.get_meta("hover_tween")
		if old:
			old.kill()
	var tween := button.create_tween()
	tween.tween_property(button, "position:y", -CARD_RAISE if hovered else 0.0, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	button.set_meta("hover_tween", tween)


func _set_hand_buttons_disabled(disabled: bool) -> void:
	for slot in hand_container.get_children():
		for child in slot.get_children():
			if child is TextureButton:
				child.disabled = disabled
				child.modulate = Color(0.6, 0.6, 0.6) if disabled else Color.WHITE
				if disabled:
					child.position.y = 0.0


# -------------------------------------------------------------- Animasi Alto

func _animate_player_attack() -> void:
	var tween := create_tween()
	tween.tween_property(alto, "position:x", alto_initial_pos.x + 60.0, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(alto, "position:x", alto_initial_pos.x, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished


func _animate_player_buff(color: Color) -> void:
	var tween := create_tween()
	tween.tween_property(alto, "modulate", color, 0.15)
	tween.tween_property(alto, "modulate", Color.WHITE, 0.2)
	await tween.finished


func _flash_node(node: CanvasItem, color: Color) -> void:
	var tween := create_tween()
	tween.tween_property(node, "modulate", color, 0.08)
	tween.tween_property(node, "modulate", Color.WHITE, 0.14)


## Angka kecil yang melayang naik lalu hilang (damage / heal / block).
func _popup(world_pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.z_index = 50
	stage.add_child(label)
	label.global_position = world_pos + Vector2(-30.0, 0.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "global_position:y", world_pos.y - 50.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


# --------------------------------------------------------------- Damage

func _damage_enemy(amount: int) -> int:
	var remaining := amount
	if enemy_block > 0:
		var absorbed := mini(enemy_block, remaining)
		enemy_block -= absorbed
		remaining -= absorbed
	enemy_hp = maxi(enemy_hp - remaining, 0)
	return remaining


func _damage_player(amount: int) -> int:
	var remaining := amount
	if player_block > 0:
		var absorbed := mini(player_block, remaining)
		player_block -= absorbed
		remaining -= absorbed
	player_hp = maxi(player_hp - remaining, 0)
	return remaining


# ------------------------------------------------------------ Hasil battle

func _check_end() -> bool:
	if enemy_hp <= 0:
		state = State.WON
		_set_hand_buttons_disabled(true)
		_log("[b][color=green]Kamu menang![/color][/b]")
		enemy_view.play_defeat()
		_on_battle_won()
		return true
	if player_hp <= 0:
		state = State.LOST
		_set_hand_buttons_disabled(true)
		_log("[b][color=red]Kamu kalah...[/color][/b]")
		enemy_view.hide_intent(true)
		_show_result(false)
		battle_ended.emit(false)
		return true
	return false


func _on_battle_won() -> void:
	var lines: Array = _get_victory_dialogue()
	if not lines.is_empty() and dialogue_box:
		hand_container.hide()
		await get_tree().create_timer(0.8, false).timeout
		dialogue_box.start(lines)
		await dialogue_box.dialogue_finished

	battle_ended.emit(true)
	if offer_mercy_choice:
		_show_result(true)
		choice_container.show()
	else:
		_continue_after_battle()


func _get_victory_dialogue() -> Array:
	if not custom_victory_dialogue.is_empty():
		return custom_victory_dialogue

	match enemy_id:
		"slimy":
			return [
				{
					"speaker": "Alto",
					"text": "akhk itu cukup kuat sekali",
				},
				{
					"speaker": enemy_name if not enemy_name.is_empty() else "Slimy",
					"text": "ampun jangan bunuh aku aku menyerah",
				},
			]
		"carrota":
			return [
				{
					"speaker": "Carrota",
					"text": "Ugh... sup andalanku... bagaimana bisa kau mengalahkanku...",
				},
				{
					"speaker": "Alto",
					"text": "Maafkan aku, Koki Carrota. Aku benar-benar tidak berniat jahat. Aku hanya sangat kelaparan dalam perjalanan menyelamatkan Putri Ellie.",
				},
				{
					"speaker": "Carrota",
					"text": "Menyelamatkan Putri Ellie...? Hah, kenapa tidak bilang dari tadi! Koki sejati tidak akan membiarkan seorang pejuang kelaparan.",
				},
				{
					"speaker": "Carrota",
					"text": "Ambillah sayuranku dan makanlah sampai kenyang untuk bekalmu ke goa Brok.",
				},
				{
					"speaker": "Alto",
					"text": "Terima kasih banyak, Koki Carrota! Aku akan segera melanjutkan perjalanan!",
				},
			]
		"hanpi":
			return [
				{
					"speaker": "Hanpi-hanpi",
					"text": "T-tidak mungkin... Sihir cerminku... hancur berkeping-keping?!",
				},
				{
					"speaker": "Alto",
					"text": "Permainan cerminmu sudah berakhir, Hanpi-hanpi! Cepat katakan, di mana Putri Ellie disekap?!",
				},
				{
					"speaker": "Hanpi-hanpi",
					"text": "Hihihi... Hebat sekali, Bintang Kecil. Kau berhasil menembus ilusi terdalamku...",
				},
				{
					"speaker": "Hanpi-hanpi",
					"text": "Jalan di balik reruntuhan ini akan membawamu langsung ke Goa Brok... Tapi di sana, kegelapan yang sesungguhnya sudah menantimu!",
				},
				{
					"speaker": "Alto",
					"text": "Aku tidak akan gentar. Demi Putri Ellie dan kedamaian dunia, aku akan terus melangkah!",
				},
			]
		_:
			return []


func _show_result(player_won: bool) -> void:
	overlay.show()
	result_label.text = ("%s KALAH" % enemy_name.to_upper()) if player_won else "ALTO KALAH"
	result_label.modulate = Color(0.4, 1.0, 0.5) if player_won else Color(1.0, 0.4, 0.4)
	choice_container.visible = player_won and offer_mercy_choice
	actions_row.visible = true


func _auto_continue() -> void:
	await get_tree().create_timer(1.6, false).timeout
	if state == State.WON and not _leaving:
		_continue_after_battle()


func _on_restart_pressed() -> void:
	start_battle()


func _on_menu_pressed() -> void:
	if ResourceLoader.exists("res://Scenes/ui/main_menu.tscn"):
		get_tree().change_scene_to_file("res://Scenes/ui/main_menu.tscn")


func _on_destroy_pressed() -> void:
	GameState.slimy_destroyed = true
	_continue_after_battle()


func _on_forgive_pressed() -> void:
	GameState.slimy_destroyed = false
	_continue_after_battle()


func _continue_after_battle() -> void:
	if _leaving:
		return
	_leaving = true
	choice_container.hide()
	actions_row.hide()
	overlay.show()
	result_label.text = "Alto melanjutkan perjalanan..."
	await get_tree().create_timer(1.2, false).timeout
	if next_scene_on_win.is_empty():
		print("[Battle] next_scene_on_win belum diisi (scene %s)." % scene_file_path)
		actions_row.show()
		_leaving = false
		return
	get_tree().change_scene_to_file(next_scene_on_win)


# ------------------------------------------------------------------- UI

func _refresh_ui() -> void:
	enemy_name_label.text = enemy_name
	enemy_hp_bar.max_value = enemy_max_hp
	enemy_hp_bar.value = enemy_hp
	enemy_hp_label.text = "HP %d/%d" % [enemy_hp, enemy_max_hp]
	enemy_block_label.text = ("Block: %d" % enemy_block) if enemy_block > 0 else ""
	enemy_status_label.text = _enemy_status_text()
	if enemy_intent.is_empty():
		enemy_intent_label.text = ""
	else:
		enemy_intent_label.text = str(enemy_intent.get("summary", ""))

	player_hp_bar.max_value = player_max_hp
	player_hp_bar.value = player_hp
	player_hp_label.text = "HP %d/%d" % [player_hp, player_max_hp]
	player_block_label.text = ("Block: %d" % player_block) if player_block > 0 else ""
	player_status_label.text = _player_status_text()

	deck_label.text = "Deck: %d" % deck.size()
	discard_label.text = "Discard: %d" % discard.size()

	var turn_status := "Giliran Alto"
	if state == State.ENEMY_TURN:
		turn_status = "Giliran %s" % enemy_name
	elif state == State.ACTION_RESOLVING:
		turn_status = "Menyerang..."
	elif state == State.WON or state == State.LOST:
		turn_status = "Selesai"
	turn_label.text = "Turn %d - %s" % [turn_count, turn_status]


func _status_name(status: String) -> String:
	match status:
		"slow":
			return "Lambat"
		"burn":
			return "Terbakar"
		"dizzy":
			return "Pusing"
		"reflect":
			return "Pantulan"
		"strength":
			return "Power"
	return status


func _player_status_text() -> String:
	var parts: Array = []
	for status in player_status:
		if int(player_status[status]) > 0:
			parts.append("%s %d" % [_status_name(str(status)), int(player_status[status])])
	return " | ".join(parts)


func _enemy_status_text() -> String:
	var parts: Array = []
	if int(enemy_status["reflect"]) > 0:
		parts.append("Pantulan %d" % int(enemy_status["reflect"]))
	if int(enemy_status["strength"]) > 0:
		parts.append("Power +%d" % int(enemy_status["strength"]))
	return " | ".join(parts)


func _log(msg: String) -> void:
	log_label.append_text(msg + "\n")
	log_label.scroll_to_line(log_label.get_line_count() - 1)
