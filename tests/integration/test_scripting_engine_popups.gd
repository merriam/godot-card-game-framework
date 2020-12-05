extends "res://tests/UTcommon.gd"

var cards := []
var card: Card
var target: Card

func before_all():
	cfc.fancy_movement = false

func after_all():
	cfc.fancy_movement = true

func before_each():
	setup_board()
	cards = draw_test_cards(5)
	yield(yield_for(0.5), YIELD)
	card = cards[0]
	target = cards[2]


func test_filtered_multiple_choice():
	card.scripts = {"card_flipped": {
				"trigger": "another",
				"filter_properties_trigger": {"Type": "Red"},
				"board": {
					"Rotate This Card": [
						{
							"name": "rotate_card",
							"subject": "self",
							"degrees": 90,
						}
					],
					"Flip This Card Face-down": [
						{
							"name": "flip_card",
							"subject": "self",
							"set_faceup": false,
						}
					]
				},
			},
	}
	yield(table_move(card, Vector2(100,200)), "completed")
	target.is_faceup = false
	yield(yield_for(0.1), YIELD)
	var menu = board.get_node("CardChoices")
	assert_true(menu.visible)
	menu._on_CardChoices_id_pressed(3)
	assert_eq("Rotate This Card",menu.selected_key)
	yield(yield_for(0.1), YIELD)
	menu.hide()
	assert_eq(card.card_rotation, 90,
			"Card should be rotated 90 degrees")
	yield(yield_for(0.1), YIELD)
	cards[3].is_faceup = false
	yield(yield_for(0.1), YIELD)
	menu = board.get_node("CardChoices")
	assert_null(menu, "menu should not appear when filter does not match")

func test_task_confirm_dialog() -> void:
	card.scripts = {"manual": {"hand": [
				{"name": "flip_card",
				"subject": "self",
				"is_optional_task": true,
				"set_faceup": false}]}}
	card.execute_scripts()
	var confirm = board.get_node("OptionalConfirmation")
	assert_true(confirm.visible)
	confirm._on_OptionalConfirmation_confirmed()
	assert_true(confirm.is_accepted, "Confirmation dialog accepted")
	confirm.hide()
	yield(yield_to(card._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_false(card.is_faceup,
			"Card should be face-down after accepted dialog")

	target.scripts = {"manual": {"hand": [
			{"name": "move_card_to_container",
			"subject": "target",
			"is_optional_task": true,
			"dest_container":  cfc.NMAP.discard},
			{"name": "flip_card",
			"subject": "self",
			"set_faceup": false}]}}
	target.execute_scripts()
	assert_true(target.is_faceup,
			"Card should not be face-down until after accepted dialog")
	confirm = board.get_node("OptionalConfirmation")
	confirm._on_OptionalConfirmation_cancelled()
	assert_false(confirm.is_accepted, "Confirmation dialog not accepted")
	confirm.hide()
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_false(target.is_faceup,
			"Card should be face-down after even afer other optional task cancelled")
	assert_false(target._is_targetting,
			"Card did not start targeting since dialogue cancelled")


func test_task_confirm_cost_dialog_cancelled_target() -> void:
	var confirm
	card.scripts = {"manual": {"hand": [
			{"name": "flip_card",
			"is_optional_task": true,
			"is_cost": true,
			"subject": "self",
			"set_faceup": false},
			{"name": "move_card_to_container",
			"subject": "target",
			"dest_container":  cfc.NMAP.discard}]}}
	card.execute_scripts()
	confirm = board.get_node("OptionalConfirmation")
	confirm._on_OptionalConfirmation_cancelled()
	confirm.hide()
	yield(yield_to(card._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_true(card.is_faceup,
			"Card should not be face-down with a cancelled cost dialog")
	assert_false(card._is_targetting,
			"Card should not start targeting once cost dialogue cancelled")


func test_task_confirm_cost_dialogue_accepted_target() -> void:
	var confirm
	card.scripts = {"manual": {"hand": [
			{"name": "flip_card",
			"is_optional_task": true,
			"is_cost": true,
			"subject": "self",
			"set_faceup": false},
			{"name": "move_card_to_container",
			"subject": "target",
			"dest_container":  cfc.NMAP.discard}]}}
	card.execute_scripts()
	confirm = board.get_node("OptionalConfirmation")
	confirm._on_OptionalConfirmation_confirmed()
	confirm.hide()
	yield(yield_for(0.5), YIELD)
	assert_true(card._is_targetting,
			"Card started targeting once dialogue accepted")
	yield(target_card(card,target), "completed")
	yield(yield_to(card._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_false(card.is_faceup,
			"Card should be face-down once the cost dialogue is accepted")

func test_script_confirm_dialog() -> void:
	var confirm
	card.scripts = {"manual": {
			"is_optional_board": true,
			"board": [
				{"name": "flip_card",
				"is_cost": true,
				"subject": "self",
				"set_faceup": false},
				{"name": "rotate_card",
				"subject": "self",
				"degrees":  180}]}}
	yield(table_move(card, Vector2(500,200)), "completed")
	card.execute_scripts()
	confirm = board.get_node("OptionalConfirmation")
	confirm._on_OptionalConfirmation_cancelled()
	confirm.hide()
	yield(yield_to(card._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_true(card.is_faceup,
			"Card has not have executed any tasks with cancelled script dialog")
	assert_eq(0, card.card_rotation,
			"Card has not have executed any tasks with cancelled script dialog")
	card.execute_scripts()
	confirm = board.get_node("OptionalConfirmation")
	confirm._on_OptionalConfirmation_confirmed()
	confirm.hide()
	yield(yield_to(card._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_false(card.is_faceup,
			"Card execute all tasks properly after script confirm")
	assert_eq(180, card.card_rotation,
			"Card execute all tasks properly after script confirm")
