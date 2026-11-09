extends Control

signal battle_ended(player_won: bool)

enum State { PLAYER_TURN, ENEMY_TURN, WON, LOST }

const STARTING_HAND := 5
const DRAW_PER_TURN := 1
const MAX_HAND := 7
const MAX_ENERGY := 3
const STARTING_ENERGY := 3

var state: State = State.PLAYER_TURN
var turn_count: int = 1

var player_hp: int = 30
var player_max_hp: int = 30
var player_block: int = 0
var player_energy: int = 0

var enemy_hp: int = 40
var enemy_max_hp: int = 40
var enemy_block: int = 0
var enemy_name: String = "Slimy"
var enemy_intent: Dictionary = {}

var deck: Array = []
var hand: Array = []
var discard: Array = []
var rng := RandomNumberGenerator.new()

@onready var enemy_name_label: Label = %EnemyName
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var enemy_hp_label: Label = %EnemyHPLabel
@onready var enemy_block_label: Label = %EnemyBlock
@onready var enemy_intent_label: Label = %EnemyIntent

@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var player_hp_label: Label = %PlayerHPLabel
@onready var player_block_label: Label = %PlayerBlock
@onready var energy_label: Label = %EnergyLabel

@onready var turn_label: Label = %TurnLabel
@onready var log_label: RichTextLabel = %LogLabel
@onready var hand_container: HBoxContainer = %HandContainer
@onready var end_turn_button: Button = %EndTurnButton
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


func _ready() -> void:
	# Battle berjalan lewat kartu dan giliran, jadi kontrol platformer Alto dikunci.
	alto.can_move = false
	alto.auto_direction = 0.0
	alto.velocity = Vector2.ZERO
	alto.set_physics_process(false)
	rng.randomize()
	end_turn_button.pressed.connect(_on_end_turn_pressed)
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
	player_energy = 0
	enemy_hp = enemy_max_hp
	enemy_block = 0
	deck = _build_deck()
	deck.shuffle()
	hand.clear()
	discard.clear()
	log_label.clear()
	overlay.hide()
	choice_container.hide()
	_log("[b]Battle dimulai![/b] Melawan %s." % enemy_name)
	_draw_cards(STARTING_HAND)
	_begin_player_turn(true)
	_refresh_ui()


func _build_deck() -> Array:
	var cards: Array = []
	var defs := [
		{"id": "strike", "name": "Strike", "cost": 1, "type": "attack", "value": 6, "desc": "Deal 6 damage"},
		{"id": "strike", "name": "Strike", "cost": 1, "type": "attack", "value": 6, "desc": "Deal 6 damage"},
		{"id": "strike", "name": "Strike", "cost": 1, "type": "attack", "value": 6, "desc": "Deal 6 damage"},
		{"id": "strike", "name": "Strike", "cost": 1, "type": "attack", "value": 6, "desc": "Deal 6 damage"},
		{"id": "heavy", "name": "Heavy Blow", "cost": 2, "type": "attack", "value": 12, "desc": "Deal 12 damage"},
		{"id": "heavy", "name": "Heavy Blow", "cost": 2, "type": "attack", "value": 12, "desc": "Deal 12 damage"},
		{"id": "guard", "name": "Guard", "cost": 1, "type": "block", "value": 5, "desc": "Gain 5 block"},
		{"id": "guard", "name": "Guard", "cost": 1, "type": "block", "value": 5, "desc": "Gain 5 block"},
		{"id": "guard", "name": "Guard", "cost": 1, "type": "block", "value": 5, "desc": "Gain 5 block"},
		{"id": "bash", "name": "Bash", "cost": 2, "type": "attack", "value": 8, "desc": "Deal 8 damage"},
	]
	for i in defs.size():
		var c: Dictionary = defs[i].duplicate()
		c["uid"] = "%s_%d_%d" % [c.id, i, rng.randi()]
		cards.append(c)
	return cards


func _draw_cards(amount: int) -> void:
	for i in amount:
		if hand.size() >= MAX_HAND:
			_log("Hand penuh.")
			break
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
	player_energy = STARTING_ENERGY
	if not first_turn:
		turn_count += 1
		_draw_cards(DRAW_PER_TURN)
		_log("[color=yellow]— Giliran Pemain (Turn %d) —[/color]" % turn_count)
	else:
		_log("[color=yellow]— Giliran Pemain (Turn %d) —[/color]" % turn_count)
	enemy_intent = _choose_enemy_intent()
	_log("Intent musuh: %s" % _intent_text(enemy_intent))
	end_turn_button.disabled = false
	_refresh_ui()


func _on_end_turn_pressed() -> void:
	if state != State.PLAYER_TURN:
		return
	end_turn_button.disabled = true
	_discard_hand()
	_begin_enemy_turn()


func _discard_hand() -> void:
	for c in hand:
		discard.append(c)
	hand.clear()
	_rebuild_hand_ui()


func _begin_enemy_turn() -> void:
	state = State.ENEMY_TURN
	enemy_block = 0
	_log("[color=orange]— Giliran Musuh —[/color]")
	_refresh_ui()
	await get_tree().create_timer(0.6).timeout
	_execute_enemy_intent()
	if _check_end():
		return
	await get_tree().create_timer(0.4).timeout
	_begin_player_turn(false)


func _choose_enemy_intent() -> Dictionary:
	var roll := rng.randi_range(1, 100)
	if roll <= 45:
		return {"type": "attack", "name": "Normal Attack", "value": rng.randi_range(5, 7)}
	elif roll <= 75:
		return {"type": "attack", "name": "Heavy Attack", "value": rng.randi_range(10, 14)}
	else:
		return {"type": "defend", "name": "Defensive Turn", "value": rng.randi_range(6, 10)}


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
		var dmg: int = enemy_intent.value
		var dealt := _damage_player(dmg)
		_log("%s menyerang! %d damage (diterima %d)." % [enemy_name, dmg, dealt])
	elif enemy_intent.type == "defend":
		enemy_block += int(enemy_intent.value)
		_log("%s bertahan dan mendapat %d block." % [enemy_name, enemy_intent.value])
	_refresh_ui()


func _rebuild_hand_ui() -> void:
	for child in hand_container.get_children():
		child.queue_free()
	for i in hand.size():
		var card: Dictionary = hand[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(150, 200)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.text = "%s\n[%d Energy]\n\n%s" % [card.name, card.cost, card.desc]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_card_pressed.bind(i))
		hand_container.add_child(btn)
	_update_hand_affordability()


func _update_hand_affordability() -> void:
	var buttons := hand_container.get_children()
	for i in buttons.size():
		if i >= hand.size():
			break
		var btn := buttons[i] as Button
		var can_play: bool = state == State.PLAYER_TURN and player_energy >= int(hand[i].cost)
		btn.disabled = not can_play


func _on_card_pressed(index: int) -> void:
	if state != State.PLAYER_TURN:
		return
	if index < 0 or index >= hand.size():
		return
	var card: Dictionary = hand[index]
	var cost: int = int(card.cost)
	if player_energy < cost:
		_log("Energy tidak cukup.")
		return
	player_energy -= cost
	hand.remove_at(index)
	_resolve_card(card)
	discard.append(card)
	_rebuild_hand_ui()
	_refresh_ui()
	_check_end()


func _resolve_card(card: Dictionary) -> void:
	if card.type == "attack":
		var dealt := _damage_enemy(int(card.value))
		_log("Kamu memakai [b]%s[/b]: %d damage ke musuh." % [card.name, dealt])
	elif card.type == "block":
		player_block += int(card.value)
		_log("Kamu memakai [b]%s[/b]: +%d block." % [card.name, card.value])


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
		end_turn_button.disabled = true
		_log("[b][color=green]Kamu menang![/color][/b]")
		_show_result(true)
		result_label.text = "SLIMY KALAH"
		choice_container.show()
		battle_ended.emit(true)
		return true
	if player_hp <= 0:
		state = State.LOST
		end_turn_button.disabled = true
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
	energy_label.text = "Energy: %d/%d" % [player_energy, MAX_ENERGY]

	deck_label.text = "Deck: %d" % deck.size()
	discard_label.text = "Discard: %d" % discard.size()
	turn_label.text = "Turn %d — %s" % [turn_count, "Player" if state == State.PLAYER_TURN else ("Enemy" if state == State.ENEMY_TURN else "End")]
	_update_hand_affordability()


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
	# Bab selanjutnya belum tersedia; kembalikan pemain ke Chapter 1 setelah pilihan disimpan.
	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file("res://Scenes/chapter_1.tscn")
