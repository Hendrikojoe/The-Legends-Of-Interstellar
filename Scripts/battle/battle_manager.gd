extends Control

signal battle_ended(player_won: bool)

enum State { PLAYER_TURN, ACTION_RESOLVING, ENEMY_TURN, WON, LOST }

const HAND_SIZE := 4

var state: State = State.PLAYER_TURN
var turn_count: int = 1

var player_hp: int = 30
var player_max_hp: int = 30
var player_block: int = 0

var enemy_hp: int = 40
var enemy_max_hp: int = 40
var enemy_block: int = 0
var enemy_name: String = "Slimy"
var enemy_intent: Dictionary = {}

var deck: Array = []
var hand: Array = []
var discard: Array = []
var rng := RandomNumberGenerator.new()

var alto_initial_pos: Vector2
var slimy_initial_pos: Vector2

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
@onready var alto: CharacterBody2D = $Stage/Alto
@onready var slimy: Node2D = $Stage/Slimy


func _ready() -> void:
	# Battle berjalan lewat kartu dan giliran, jadi kontrol platformer Alto dikunci.
	alto.can_move = false
	alto.auto_direction = 0.0
	alto.velocity = Vector2.ZERO
	alto.set_physics_process(false)
	alto_initial_pos = alto.position
	slimy_initial_pos = slimy.position
	rng.randomize()

	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	destroy_button.pressed.connect(_on_destroy_pressed)
	forgive_button.pressed.connect(_on_forgive_pressed)

	start_battle()


func start_battle() -> void:
	state = State.PLAYER_TURN
	turn_count = 1
	player_hp = player_max_hp
	player_block = 0
	enemy_hp = enemy_max_hp
	enemy_block = 0
	alto.position = alto_initial_pos
	alto.modulate = Color.WHITE
	slimy.position = slimy_initial_pos
	slimy.modulate = Color.WHITE

	deck = _build_deck()
	deck.shuffle()
	hand.clear()
	discard.clear()
	log_label.clear()
	overlay.hide()
	choice_container.hide()

	_log("[b]Battle dimulai![/b] Melawan %s." % enemy_name)
	_begin_player_turn(true)


func _build_deck() -> Array:
	var cards: Array = []
	var defs := [
		{"id": "strike", "name": "Strike", "type": "attack", "value": 6, "desc": "Serangan Biasa\n(6 Damage)"},
		{"id": "strike", "name": "Strike", "type": "attack", "value": 6, "desc": "Serangan Biasa\n(6 Damage)"},
		{"id": "strike", "name": "Strike", "type": "attack", "value": 6, "desc": "Serangan Biasa\n(6 Damage)"},
		{"id": "strike", "name": "Strike", "type": "attack", "value": 6, "desc": "Serangan Biasa\n(6 Damage)"},
		{"id": "heavy", "name": "Heavy Blow", "type": "attack", "value": 12, "desc": "Serangan Kuat\n(12 Damage)"},
		{"id": "heavy", "name": "Heavy Blow", "type": "attack", "value": 12, "desc": "Serangan Kuat\n(12 Damage)"},
		{"id": "guard", "name": "Guard", "type": "block", "value": 7, "desc": "Bertahan\n(+7 Block)"},
		{"id": "guard", "name": "Guard", "type": "block", "value": 7, "desc": "Bertahan\n(+7 Block)"},
		{"id": "guard", "name": "Guard", "type": "block", "value": 7, "desc": "Bertahan\n(+7 Block)"},
		{"id": "bash", "name": "Bash", "type": "attack", "value": 9, "desc": "Hantaman\n(9 Damage)"},
		{"id": "bash", "name": "Bash", "type": "attack", "value": 9, "desc": "Hantaman\n(9 Damage)"},
		{"id": "heal", "name": "Heal", "type": "heal", "value": 6, "desc": "Pemulihan\n(+6 HP)"},
	]
	for i in defs.size():
		var c: Dictionary = defs[i].duplicate()
		c["uid"] = "%s_%d_%d" % [c.id, i, rng.randi()]
		cards.append(c)
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


func _begin_player_turn(first_turn: bool) -> void:
	state = State.PLAYER_TURN
	player_block = 0
	if not first_turn:
		turn_count += 1
	_log("[color=yellow]— Giliran Pemain (Turn %d) —[/color]" % turn_count)

	_draw_cards_until(HAND_SIZE)
	enemy_intent = _choose_enemy_intent()
	_log("Intent musuh: %s" % _intent_text(enemy_intent))

	_refresh_ui()
	_set_hand_buttons_disabled(false)


func _on_card_pressed(index: int) -> void:
	if state != State.PLAYER_TURN:
		return
	if index < 0 or index >= hand.size():
		return

	# Kunci input kartu saat aksi sedang diselesaikan
	state = State.ACTION_RESOLVING
	_set_hand_buttons_disabled(true)

	var card: Dictionary = hand[index]
	hand.remove_at(index)
	discard.append(card)
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
		var dealt := _damage_enemy(int(card.value))
		_log("Kamu memakai [b]%s[/b]: %d damage ke musuh." % [card.name, dealt])
	elif card.type == "block":
		await _animate_player_buff(Color(0.4, 0.8, 1.0))
		player_block += int(card.value)
		_log("Kamu memakai [b]%s[/b]: +%d block." % [card.name, card.value])
	elif card.type == "heal":
		await _animate_player_buff(Color(0.4, 1.0, 0.5))
		var healed: int = mini(int(card.value), player_max_hp - player_hp)
		player_hp = mini(player_hp + int(card.value), player_max_hp)
		_log("Kamu memakai [b]%s[/b]: memulihkan %d HP." % [card.name, healed])


func _begin_enemy_turn() -> void:
	state = State.ENEMY_TURN
	enemy_block = 0
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
	var roll := rng.randi_range(1, 100)
	if roll <= 50:
		return {"type": "attack", "name": "Normal Attack", "value": rng.randi_range(5, 7)}
	elif roll <= 80:
		return {"type": "attack", "name": "Heavy Attack", "value": rng.randi_range(9, 13)}
	else:
		return {"type": "defend", "name": "Defensive Stance", "value": rng.randi_range(5, 8)}


func _intent_text(intent: Dictionary) -> String:
	if intent.is_empty():
		return "..."
	if intent.type == "attack":
		return "%s (%d dmg)" % [intent.name, intent.value]
	return "%s (+%d block)" % [intent.name, intent.value]


func _execute_enemy_intent() -> void:
	if enemy_intent.is_empty():
		return
	if enemy_intent.type == "attack":
		await _animate_enemy_attack()
		var dmg: int = enemy_intent.value
		var dealt := _damage_player(dmg)
		_log("%s menyerang! %d damage (diterima %d)." % [enemy_name, dmg, dealt])
	elif enemy_intent.type == "defend":
		await _animate_enemy_buff(Color(0.4, 0.8, 1.0))
		enemy_block += int(enemy_intent.value)
		_log("%s bersiap bertahan dan mendapat %d block." % [enemy_name, enemy_intent.value])


func _rebuild_hand_ui() -> void:
	for child in hand_container.get_children():
		child.queue_free()
	for i in hand.size():
		var card: Dictionary = hand[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(150, 180)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.text = "%s\n\n%s" % [card.name, card.desc]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.disabled = (state != State.PLAYER_TURN)
		btn.pressed.connect(_on_card_pressed.bind(i))
		hand_container.add_child(btn)


func _set_hand_buttons_disabled(disabled: bool) -> void:
	for child in hand_container.get_children():
		if child is Button:
			child.disabled = disabled


func _animate_player_attack() -> void:
	var tw := create_tween()
	tw.tween_property(alto, "position:x", alto_initial_pos.x + 60.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(alto, "position:x", alto_initial_pos.x, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var hit_tw := create_tween()
	hit_tw.tween_interval(0.1)
	hit_tw.tween_property(slimy, "modulate", Color(1.0, 0.3, 0.3), 0.08)
	hit_tw.tween_property(slimy, "modulate", Color.WHITE, 0.12)
	await tw.finished


func _animate_player_buff(color: Color) -> void:
	var tw := create_tween()
	tw.tween_property(alto, "modulate", color, 0.15)
	tw.tween_property(alto, "modulate", Color.WHITE, 0.2)
	await tw.finished


func _animate_enemy_attack() -> void:
	var tw := create_tween()
	tw.tween_property(slimy, "position:x", slimy_initial_pos.x - 60.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(slimy, "position:x", slimy_initial_pos.x, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var hit_tw := create_tween()
	hit_tw.tween_interval(0.1)
	hit_tw.tween_property(alto, "modulate", Color(1.0, 0.3, 0.3), 0.08)
	hit_tw.tween_property(alto, "modulate", Color.WHITE, 0.12)
	await tw.finished


func _animate_enemy_buff(color: Color) -> void:
	var tw := create_tween()
	tw.tween_property(slimy, "modulate", color, 0.15)
	tw.tween_property(slimy, "modulate", Color.WHITE, 0.2)
	await tw.finished


func _damage_enemy(amount: int) -> int:
	var original_amount := amount
	var remaining := amount
	if enemy_block > 0:
		var absorbed: int = mini(enemy_block, remaining)
		enemy_block -= absorbed
		remaining -= absorbed
	enemy_hp = maxi(enemy_hp - remaining, 0)
	return original_amount - remaining


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
		_show_result(true)
		result_label.text = "SLIMY KALAH"
		choice_container.show()
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
	result_label.text = "SLIMY KALAH" if player_won else "ALTO KALAH"
	result_label.modulate = Color(0.4, 1.0, 0.5) if player_won else Color(1.0, 0.4, 0.4)
	choice_container.visible = player_won


func _refresh_ui() -> void:
	enemy_name_label.text = enemy_name
	enemy_hp_bar.max_value = enemy_max_hp
	enemy_hp_bar.value = enemy_hp
	enemy_hp_label.text = "HP %d/%d" % [enemy_hp, enemy_max_hp]
	enemy_block_label.text = "Block: %d" % enemy_block if enemy_block > 0 else ""
	enemy_intent_label.text = "Intent: %s" % _intent_text(enemy_intent)

	player_hp_bar.max_value = player_max_hp
	player_hp_bar.value = player_hp
	player_hp_label.text = "HP %d/%d" % [player_hp, player_max_hp]
	player_block_label.text = "Block: %d" % player_block if player_block > 0 else ""

	deck_label.text = "Deck: %d" % deck.size()
	discard_label.text = "Discard: %d" % discard.size()

	var turn_status := "Giliran Alto"
	if state == State.ENEMY_TURN:
		turn_status = "Giliran Slimy"
	elif state == State.ACTION_RESOLVING:
		turn_status = "Menyerang..."
	elif state == State.WON or state == State.LOST:
		turn_status = "Selesai"

	turn_label.text = "Turn %d — %s" % [turn_count, turn_status]


func _log(msg: String) -> void:
	log_label.append_text(msg + "\n")
	log_label.scroll_to_line(log_label.get_line_count() - 1)


func _on_restart_pressed() -> void:
	start_battle()


func _on_menu_pressed() -> void:
	if ResourceLoader.exists("res://Scenes/menu/main_menu.tscn"):
		get_tree().change_scene_to_file("res://Scenes/menu/main_menu.tscn")


func _on_destroy_pressed() -> void:
	GameState.slimy_destroyed = true
	_continue_after_battle()


func _on_forgive_pressed() -> void:
	GameState.slimy_destroyed = false
	_continue_after_battle()


func _continue_after_battle() -> void:
	choice_container.hide()
	result_label.text = "Alto melanjutkan perjalanan..."
	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file("res://Scenes/chapter_2.tscn")
