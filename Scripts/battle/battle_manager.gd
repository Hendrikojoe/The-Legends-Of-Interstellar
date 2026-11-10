extends Control
## Battle kartu 1 lawan 1.
##
## Musuh dipilih lewat `enemy_id` di Inspector (node Battle):
##   slimy   -> Chapter 1 (bisa Hancurkan / Maafkan setelah menang)
##   carrota -> Chapter 2 (Raining Soup, Chili Oil/Pedas, Healing)
##   hanpi   -> Chapter 3 (Pantulan Cermin, Sulap Kartu, Cermin Pecah)
##
## Aturan dasar: tiap giliran Alto memainkan 1 kartu, lalu musuh membalas
## sesuai "Intent" yang sudah diperlihatkan di atas layar.

signal battle_ended(player_won: bool)

enum State { PLAYER_TURN, ACTION_RESOLVING, ENEMY_TURN, WON, LOST }

const HAND_SIZE := 4
const MAIN_MENU_PATH := "res://Scenes/menu/main_menu.tscn"

## Pengaturan tiap musuh. Edit angka di sini untuk menyeimbangkan battle.
const ENEMIES := {
	"slimy": {
		"name": "Slimy",
		"max_hp": 40,
		"player_max_hp": 30,
		"crystal_cards": 0,
		"win_text": "SLIMY KALAH",
		"mercy_choice": true,
		"next_scene": "res://Scenes/chapter_2.tscn",
	},
	"carrota": {
		"name": "Carrota",
		"max_hp": 50,
		"player_max_hp": 50,
		"crystal_cards": 2,
		"win_text": "CARROTA KALAH",
		"mercy_choice": false,
		"next_scene": "res://Scenes/chapter_3.tscn",
	},
	"hanpi": {
		"name": "Hanpi-hanpi",
		"max_hp": 65,
		"player_max_hp": 50,
		"crystal_cards": 2,
		"win_text": "HANPI-HANPI KALAH",
		"mercy_choice": false,
		"next_scene": "res://Scenes/chapter_3_end.tscn",
	},
}

@export_enum("slimy", "carrota", "hanpi") var enemy_id: String = "slimy"
## Kosongkan untuk memakai next_scene bawaan musuh (lihat ENEMIES di atas).
@export_file("*.tscn") var next_scene_override: String = ""

var cfg: Dictionary = {}

var state: State = State.PLAYER_TURN
var turn_count: int = 1

var player_hp: int = 30
var player_max_hp: int = 30
var player_block: int = 0
## Status "Pedas" (burn) dari Carrota: kena damage tembus block tiap awal giliran Alto.
var player_burn_damage: int = 0
var player_burn_turns: int = 0

var enemy_hp: int = 40
var enemy_max_hp: int = 40
var enemy_block: int = 0
var enemy_name: String = "Slimy"
var enemy_intent: Dictionary = {}
## Status "Pantulan" (Hanpi): kartu serangan berikutnya memantul 50% damage ke Alto.
var enemy_reflect: bool = false
var enemy_phase: int = 1
var enemy_heal_cooldown: int = 0
var last_intent_name: String = ""

## Sulap Kartu (Hanpi): jumlah kartu yang akan dikunci di giliran Alto berikutnya.
var pending_lock: int = 0
var locked_uids: Array = []

var deck: Array = []
var hand: Array = []
var discard: Array = []
var rng := RandomNumberGenerator.new()

var alto_initial_pos: Vector2
var enemy_initial_pos: Vector2

@onready var enemy_name_label: Label = %EnemyName
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var enemy_hp_label: Label = %EnemyHPLabel
@onready var enemy_block_label: Label = %EnemyBlock
@onready var enemy_intent_label: Label = %EnemyIntent

@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var player_hp_label: Label = %PlayerHPLabel
@onready var player_block_label: Label = %PlayerBlock

@onready var turn_label: Label = %TurnLabel
@onready var log_label: RichTextLabel = %LogLabel
@onready var hand_container: HBoxContainer = %HandContainer
@onready var deck_label: Label = %DeckLabel
@onready var discard_label: Label = %DiscardLabel

@onready var overlay: ColorRect = %Overlay
@onready var result_label: Label = %ResultLabel
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton
@onready var choice_container: HBoxContainer = %ChoiceContainer
@onready var destroy_button: Button = %DestroyButton
@onready var forgive_button: Button = %ForgiveButton
@onready var continue_button: Button = %ContinueButton
@onready var alto: CharacterBody2D = $Stage/Alto
@onready var enemy: Node2D = $Stage/Enemy


func _ready() -> void:
	cfg = ENEMIES[enemy_id]
	enemy_name = cfg.name
	enemy_max_hp = cfg.max_hp
	player_max_hp = cfg.player_max_hp

	# Battle berjalan lewat kartu dan giliran, jadi kontrol platformer Alto dikunci.
	alto.can_move = false
	alto.auto_direction = 0.0
	alto.velocity = Vector2.ZERO
	alto.set_physics_process(false)
	enemy.show()
	alto_initial_pos = alto.position
	enemy_initial_pos = enemy.position
	rng.randomize()

	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	destroy_button.pressed.connect(_on_destroy_pressed)
	forgive_button.pressed.connect(_on_forgive_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

	start_battle()


func start_battle() -> void:
	state = State.PLAYER_TURN
	turn_count = 1
	player_hp = player_max_hp
	player_block = 0
	player_burn_damage = 0
	player_burn_turns = 0
	enemy_hp = enemy_max_hp
	enemy_block = 0
	enemy_reflect = false
	enemy_phase = 1
	enemy_heal_cooldown = 0
	last_intent_name = ""
	pending_lock = 0
	locked_uids.clear()
	alto.position = alto_initial_pos
	alto.modulate = Color.WHITE
	enemy.position = enemy_initial_pos
	enemy.modulate = Color.WHITE

	deck = _build_deck()
	deck.shuffle()
	hand.clear()
	discard.clear()
	log_label.clear()
	overlay.hide()
	choice_container.hide()
	continue_button.hide()

	_log("[b]Battle dimulai![/b] Melawan %s." % enemy_name)
	_begin_player_turn(true)


# ------------------------------------------------------------------ Kartu

func _build_deck() -> Array:
	var defs: Array = []
	_add_cards(defs, 4, {"id": "strike", "name": "Strike", "type": "attack", "value": 6, "desc": "Serangan Biasa\n(6 Damage)"})
	_add_cards(defs, 2, {"id": "heavy", "name": "Heavy Blow", "type": "attack", "value": 12, "desc": "Serangan Kuat\n(12 Damage)"})
	_add_cards(defs, 3, {"id": "guard", "name": "Guard", "type": "block", "value": 7, "desc": "Bertahan\n(+7 Block)"})
	_add_cards(defs, 2, {"id": "bash", "name": "Bash", "type": "attack", "value": 9, "desc": "Hantaman\n(9 Damage)"})
	_add_cards(defs, 1, {"id": "heal", "name": "Heal", "type": "heal", "value": 6, "desc": "Pemulihan\n(+6 HP, hapus Pedas)"})
	# Kartu cahaya dari kristal pemberian Raja (mulai dipakai setelah Slimy).
	_add_cards(defs, int(cfg.crystal_cards), {"id": "crystal", "name": "Crystal Light", "type": "attack", "value": 8, "pierce": true, "desc": "Cahaya Kristal\n(8 Damage, tembus Block)"})

	var cards: Array = []
	for i in defs.size():
		var c: Dictionary = defs[i].duplicate()
		c["uid"] = "%s_%d_%d" % [c.id, i, rng.randi()]
		cards.append(c)
	return cards


func _add_cards(into: Array, count: int, card: Dictionary) -> void:
	for i in count:
		into.append(card)


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


# ------------------------------------------------------------ Giliran Alto

func _begin_player_turn(first_turn: bool) -> void:
	state = State.PLAYER_TURN
	player_block = 0
	if not first_turn:
		turn_count += 1
	_log("[color=yellow]— Giliran Pemain (Turn %d) —[/color]" % turn_count)

	# Status Pedas: damage tembus block di awal giliran.
	if player_burn_turns > 0:
		player_hp = maxi(player_hp - player_burn_damage, 0)
		player_burn_turns -= 1
		_log("[color=orangered]Pedas! Kamu terbakar %d damage.[/color]" % player_burn_damage)
		if player_burn_turns <= 0:
			player_burn_damage = 0
		_flash(alto, Color(1.0, 0.45, 0.2))
		if player_hp <= 0:
			_refresh_ui()
			_check_end()
			return

	_draw_cards_until(HAND_SIZE)
	_apply_pending_lock()
	enemy_intent = _choose_enemy_intent()
	_log("Intent musuh: %s" % _intent_text(enemy_intent))

	_refresh_ui()
	_set_hand_buttons_disabled(false)


func _apply_pending_lock() -> void:
	locked_uids.clear()
	if pending_lock > 0:
		var order: Array = range(hand.size())
		order.shuffle()
		# Selalu sisakan minimal 1 kartu yang bisa dipakai.
		var count: int = mini(pending_lock, hand.size() - 1)
		for i in count:
			locked_uids.append(hand[order[i]].uid)
		pending_lock = 0
		if count > 0:
			_log("[color=violet]Sihir Hanpi-hanpi mengunci %d kartu di tanganmu![/color]" % count)
	_rebuild_hand_ui()


func _on_card_pressed(index: int) -> void:
	if state != State.PLAYER_TURN:
		return
	if index < 0 or index >= hand.size():
		return
	if hand[index].uid in locked_uids:
		return

	# Kunci input kartu saat aksi sedang diselesaikan
	state = State.ACTION_RESOLVING
	_set_hand_buttons_disabled(true)

	var card: Dictionary = hand[index]
	hand.remove_at(index)
	discard.append(card)
	locked_uids.clear()
	_rebuild_hand_ui()
	_set_hand_buttons_disabled(true)

	await _resolve_player_card(card)
	_refresh_ui()

	if _check_end():
		return

	# Jeda sejenak sebelum musuh otomatis membalas menyerang
	await get_tree().create_timer(0.5).timeout
	if state != State.ACTION_RESOLVING:
		return

	await _begin_enemy_turn()


func _resolve_player_card(card: Dictionary) -> void:
	if card.type == "attack":
		await _animate_player_attack()
		var dealt := _damage_enemy(int(card.value), bool(card.get("pierce", false)))
		_log("Kamu memakai [b]%s[/b]: %d damage ke musuh." % [card.name, dealt])
		if enemy_reflect:
			enemy_reflect = false
			var back := _damage_player(int(ceil(int(card.value) * 0.5)))
			_log("[color=violet]Cermin memantulkan seranganmu! Kamu menerima %d damage.[/color]" % back)
			_flash(alto, Color(0.8, 0.4, 1.0))
	elif card.type == "block":
		await _animate_player_buff(Color(0.4, 0.8, 1.0))
		player_block += int(card.value)
		_log("Kamu memakai [b]%s[/b]: +%d block." % [card.name, card.value])
	elif card.type == "heal":
		await _animate_player_buff(Color(0.4, 1.0, 0.5))
		var healed: int = mini(int(card.value), player_max_hp - player_hp)
		player_hp = mini(player_hp + int(card.value), player_max_hp)
		_log("Kamu memakai [b]%s[/b]: memulihkan %d HP." % [card.name, healed])
		if player_burn_turns > 0:
			player_burn_turns = 0
			player_burn_damage = 0
			_log("Efek Pedas hilang.")


# ----------------------------------------------------------- Giliran musuh

func _begin_enemy_turn() -> void:
	state = State.ENEMY_TURN
	enemy_block = 0
	enemy_reflect = false
	_refresh_ui()
	_log("[color=orange]— Musuh Menyerang! —[/color]")

	await get_tree().create_timer(0.3).timeout
	await _execute_enemy_intent()
	_refresh_ui()

	if _check_end():
		return

	# Jeda sebelum kembali ke giliran pemain
	await get_tree().create_timer(0.5).timeout
	_begin_player_turn(false)


func _choose_enemy_intent() -> Dictionary:
	var intent: Dictionary
	match enemy_id:
		"carrota":
			intent = _choose_carrota_intent()
		"hanpi":
			intent = _choose_hanpi_intent()
		_:
			intent = _choose_slimy_intent()
	last_intent_name = intent.name
	return intent


## Slimy: acak sederhana (tidak berubah dari versi sebelumnya).
func _choose_slimy_intent() -> Dictionary:
	var roll := rng.randi_range(1, 100)
	if roll <= 50:
		return {"name": "Normal Attack", "damage": rng.randi_range(5, 7)}
	elif roll <= 80:
		return {"name": "Heavy Attack", "damage": rng.randi_range(9, 13)}
	return {"name": "Defensive Stance", "block": rng.randi_range(5, 8)}


## Carrota (sang koki):
##   Chop         - serangan biasa
##   Raining Soup - hujan sup, banyak pukulan kecil (Guard cepat habis, 4 hit saat marah)
##   Chili Oil    - damage kecil + Pedas (3 giliran, tembus block). Heal kartu menghapusnya.
##   Healing      - memulihkan HP sendiri; hanya saat HP <= 50%, ada cooldown
func _choose_carrota_intent() -> Dictionary:
	var enraged: bool = enemy_hp * 2 <= enemy_max_hp
	if enraged and enemy_phase == 1:
		enemy_phase = 2
		_log("[color=orange]Carrota mulai serius! Masakannya makin ganas...[/color]")
	if enemy_heal_cooldown > 0:
		enemy_heal_cooldown -= 1

	if enraged and enemy_heal_cooldown == 0 and rng.randi_range(1, 100) <= 40:
		enemy_heal_cooldown = 4
		return {"name": "Healing", "heal": rng.randi_range(7, 9), "color": Color(0.4, 1.0, 0.5)}

	var roll := rng.randi_range(1, 100)
	if roll <= 30:
		return {"name": "Chop", "damage": rng.randi_range(6, 8)}
	elif roll <= 65:
		return {"name": "Raining Soup", "damage": 3, "hits": 4 if enraged else 3}
	return {"name": "Chili Oil", "damage": 3, "burn_damage": 3 if enraged else 2, "burn_turns": 3}


## Hanpi-hanpi (pesulap di balik cermin):
##   Magic Bolt     - sihir biasa
##   Cermin Pantul  - +block dan kartu serangan Alto berikutnya memantul 50% damage
##                    (counter: pakai Guard/Heal di giliran itu, atau serang dengan sadar risiko)
##   Sulap Kartu    - sedikit damage, mengunci kartu di tangan Alto giliran depan
##   Cermin Pecah   - (fase 2, HP <= 50%) 2 pukulan beruntun
## Skill yang sama tidak keluar dua kali berturut-turut.
func _choose_hanpi_intent() -> Dictionary:
	var enraged: bool = enemy_hp * 2 <= enemy_max_hp
	if enraged and enemy_phase == 1:
		enemy_phase = 2
		_log("[color=violet]Cermin Hanpi-hanpi retak! Sihirnya makin liar...[/color]")

	var pool: Array = []
	pool.append({"name": "Magic Bolt", "damage": rng.randi_range(10, 12) if enraged else rng.randi_range(8, 10)})
	pool.append({"name": "Cermin Pantul", "block": 8 if enraged else 6, "reflect": true, "color": Color(0.8, 0.5, 1.0)})
	pool.append({"name": "Sulap Kartu", "damage": 4, "lock": 3 if enraged else 2})
	if enraged:
		pool.append({"name": "Cermin Pecah", "damage": 6, "hits": 2})

	pool.shuffle()
	for candidate: Dictionary in pool:
		if candidate.name != last_intent_name:
			return candidate
	return pool[0]


func _intent_text(intent: Dictionary) -> String:
	if intent.is_empty():
		return "..."
	var parts: Array = []
	var dmg: int = int(intent.get("damage", 0))
	var hits: int = int(intent.get("hits", 1))
	if dmg > 0:
		parts.append("%d dmg" % dmg if hits <= 1 else "%d×%d dmg" % [hits, dmg])
	if intent.has("block"):
		parts.append("+%d block" % int(intent.block))
	if intent.has("heal"):
		parts.append("+%d HP" % int(intent.heal))
	if intent.has("burn_turns"):
		parts.append("Pedas %d dmg/%d giliran" % [int(intent.burn_damage), int(intent.burn_turns)])
	if intent.get("reflect", false):
		parts.append("pantulkan serangan")
	if intent.has("lock"):
		parts.append("kunci %d kartu" % int(intent.lock))
	return "%s (%s)" % [intent.name, ", ".join(parts)]


func _execute_enemy_intent() -> void:
	if enemy_intent.is_empty():
		return
	var it: Dictionary = enemy_intent
	var buff_color: Color = it.get("color", Color(0.4, 0.8, 1.0))

	# 1) Serangan (bisa beberapa pukulan)
	var dmg: int = int(it.get("damage", 0))
	if dmg > 0:
		var hits: int = int(it.get("hits", 1))
		for h in hits:
			await _animate_enemy_attack()
			var dealt := _damage_player(dmg)
			_log("%s memakai [b]%s[/b]! %d damage (diterima %d)." % [enemy_name, it.name, dmg, dealt])
			_refresh_ui()
			if player_hp <= 0:
				return

	# 2) Efek tambahan
	if it.has("block"):
		await _animate_enemy_buff(buff_color)
		enemy_block += int(it.block)
		_log("%s memakai [b]%s[/b] dan mendapat %d block." % [enemy_name, it.name, it.block])
	if it.has("heal"):
		await _animate_enemy_buff(buff_color)
		var healed: int = mini(int(it.heal), enemy_max_hp - enemy_hp)
		enemy_hp += healed
		_log("%s memakai [b]%s[/b] dan memulihkan %d HP." % [enemy_name, it.name, healed])
	if it.has("burn_turns"):
		player_burn_damage = maxi(player_burn_damage, int(it.burn_damage))
		player_burn_turns = maxi(player_burn_turns, int(it.burn_turns))
		_log("[color=orangered]Alto kepedasan! Pedas %d damage selama %d giliran.[/color]" % [player_burn_damage, player_burn_turns])
	if it.get("reflect", false):
		enemy_reflect = true
		_log("[color=violet]Cermin bersinar... serangan berikutnya akan dipantulkan![/color]")
	if it.has("lock"):
		pending_lock = int(it.lock)
		_log("[color=violet]Sihir mengintai kartu-kartumu...[/color]")


# ---------------------------------------------------------------- UI Kartu

func _rebuild_hand_ui() -> void:
	for child in hand_container.get_children():
		child.queue_free()
	for i in hand.size():
		var card: Dictionary = hand[i]
		var is_locked: bool = card.uid in locked_uids
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(150, 180)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.text = "%s\n\n%s" % [card.name, "[TERKUNCI]" if is_locked else card.desc]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.set_meta("locked", is_locked)
		btn.disabled = (state != State.PLAYER_TURN) or is_locked
		btn.pressed.connect(_on_card_pressed.bind(i))
		hand_container.add_child(btn)


func _set_hand_buttons_disabled(disabled: bool) -> void:
	for child in hand_container.get_children():
		if child is Button:
			child.disabled = disabled or bool(child.get_meta("locked", false))


# ---------------------------------------------------------------- Animasi

func _flash(node: Node2D, color: Color) -> void:
	var tw := create_tween()
	tw.tween_property(node, "modulate", color, 0.08)
	tw.tween_property(node, "modulate", Color.WHITE, 0.12)


func _animate_player_attack() -> void:
	var tw := create_tween()
	tw.tween_property(alto, "position:x", alto_initial_pos.x + 60.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(alto, "position:x", alto_initial_pos.x, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var hit_tw := create_tween()
	hit_tw.tween_interval(0.1)
	hit_tw.tween_property(enemy, "modulate", Color(1.0, 0.3, 0.3), 0.08)
	hit_tw.tween_property(enemy, "modulate", Color.WHITE, 0.12)
	await tw.finished


func _animate_player_buff(color: Color) -> void:
	var tw := create_tween()
	tw.tween_property(alto, "modulate", color, 0.15)
	tw.tween_property(alto, "modulate", Color.WHITE, 0.2)
	await tw.finished


func _animate_enemy_attack() -> void:
	var tw := create_tween()
	tw.tween_property(enemy, "position:x", enemy_initial_pos.x - 60.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(enemy, "position:x", enemy_initial_pos.x, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var hit_tw := create_tween()
	hit_tw.tween_interval(0.1)
	hit_tw.tween_property(alto, "modulate", Color(1.0, 0.3, 0.3), 0.08)
	hit_tw.tween_property(alto, "modulate", Color.WHITE, 0.12)
	await tw.finished


func _animate_enemy_buff(color: Color) -> void:
	var tw := create_tween()
	tw.tween_property(enemy, "modulate", color, 0.15)
	tw.tween_property(enemy, "modulate", Color.WHITE, 0.2)
	await tw.finished


# ----------------------------------------------------------------- Damage

## Mengembalikan damage yang benar-benar mengurangi HP musuh (setelah block).
func _damage_enemy(amount: int, pierce: bool = false) -> int:
	var remaining := amount
	if enemy_block > 0 and not pierce:
		var absorbed: int = mini(enemy_block, remaining)
		enemy_block -= absorbed
		remaining -= absorbed
	enemy_hp = maxi(enemy_hp - remaining, 0)
	return remaining


func _damage_player(amount: int) -> int:
	var remaining := amount
	if player_block > 0:
		var absorbed: int = mini(player_block, remaining)
		player_block -= absorbed
		remaining -= absorbed
	var dealt := remaining
	player_hp = maxi(player_hp - remaining, 0)
	return dealt


func _check_end() -> bool:
	if enemy_hp <= 0:
		state = State.WON
		_set_hand_buttons_disabled(true)
		_log("[b][color=green]Kamu menang![/color][/b]")
		create_tween().tween_property(enemy, "modulate:a", 0.25, 0.6)
		_show_result(true)
		battle_ended.emit(true)
		return true
	if player_hp <= 0:
		state = State.LOST
		_set_hand_buttons_disabled(true)
		_log("[b][color=red]Kamu kalah...[/color][/b]")
		_show_result(false)
		battle_ended.emit(false)
		return true
	return false


func _show_result(player_won: bool) -> void:
	overlay.show()
	result_label.text = String(cfg.win_text) if player_won else "ALTO KALAH"
	result_label.modulate = Color(0.4, 1.0, 0.5) if player_won else Color(1.0, 0.4, 0.4)
	var mercy: bool = bool(cfg.mercy_choice)
	choice_container.visible = player_won and mercy
	continue_button.visible = player_won and not mercy
	if player_won:
		(destroy_button if mercy else continue_button).grab_focus.call_deferred()


func _refresh_ui() -> void:
	enemy_name_label.text = enemy_name
	enemy_hp_bar.max_value = enemy_max_hp
	enemy_hp_bar.value = enemy_hp
	enemy_hp_label.text = "HP %d/%d" % [enemy_hp, enemy_max_hp]
	var enemy_status: Array = []
	if enemy_block > 0:
		enemy_status.append("Block: %d" % enemy_block)
	if enemy_reflect:
		enemy_status.append("PANTULAN aktif")
	enemy_block_label.text = "   ".join(enemy_status)
	enemy_intent_label.text = "Intent: %s" % _intent_text(enemy_intent)

	player_hp_bar.max_value = player_max_hp
	player_hp_bar.value = player_hp
	player_hp_label.text = "HP %d/%d" % [player_hp, player_max_hp]
	var player_status: Array = []
	if player_block > 0:
		player_status.append("Block: %d" % player_block)
	if player_burn_turns > 0:
		player_status.append("Pedas: %d dmg (%d giliran)" % [player_burn_damage, player_burn_turns])
	player_block_label.text = "   ".join(player_status)

	deck_label.text = "Deck: %d" % deck.size()
	discard_label.text = "Discard: %d" % discard.size()

	var turn_status := "Giliran Alto"
	if state == State.ENEMY_TURN:
		turn_status = "Giliran %s" % enemy_name
	elif state == State.ACTION_RESOLVING:
		turn_status = "Menyerang..."
	elif state == State.WON or state == State.LOST:
		turn_status = "Selesai"

	turn_label.text = "Turn %d — %s" % [turn_count, turn_status]


func _log(msg: String) -> void:
	log_label.append_text(msg + "\n")
	log_label.scroll_to_line(log_label.get_line_count() - 1)


# ---------------------------------------------------------- Tombol hasil

func _on_restart_pressed() -> void:
	start_battle()


func _on_menu_pressed() -> void:
	if ResourceLoader.exists(MAIN_MENU_PATH):
		get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_destroy_pressed() -> void:
	GameState.slimy_destroyed = true
	_continue_after_battle()


func _on_forgive_pressed() -> void:
	GameState.slimy_destroyed = false
	_continue_after_battle()


func _on_continue_pressed() -> void:
	_continue_after_battle()


func _continue_after_battle() -> void:
	choice_container.hide()
	continue_button.hide()
	result_label.text = "Alto melanjutkan perjalanan..."
	await get_tree().create_timer(1.2).timeout
	var target: String = next_scene_override if not next_scene_override.is_empty() else String(cfg.next_scene)
	get_tree().change_scene_to_file(target)
