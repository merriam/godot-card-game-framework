extends "res://addons/gut/test.gd"

var board
var hand
var cards := []
var common = UTCommon.new()

# Takes care of simple drag&drop requests
func drag_drop(card: Card, target_position: Vector2, interpolation_speed := "fast") -> void:
	var mouse_yield_wait: float
	var mouse_speed: int
	if interpolation_speed == "fast":
		mouse_yield_wait = 0.3
		mouse_speed = 10
	else:
		mouse_yield_wait = 0.6
		mouse_speed = 3
	card._on_Card_mouse_entered()
	common.click_card(card)
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(target_position,card.position,mouse_speed)
	yield(yield_for(mouse_yield_wait), YIELD)
	common.drop_card(card,board._UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_to(card.get_node('Tween'), "tween_all_completed", 1), YIELD)

func before_each():
	board = autoqfree(TestVars.new().boardScene.instance())
	get_tree().get_root().add_child(board)
	common.setup_board(board)
	cards = common.draw_test_cards(5)
	hand = cfc.NMAP.hand
	yield(yield_for(1), YIELD)

func test_manipulation_buttons_not_messing_hand_focus():
	var card : Card
	card = cards[0]
	yield(drag_drop(card, Vector2(600,200)), 'completed')
	card._on_Card_mouse_entered()
	yield(yield_for(0.3), YIELD) # Wait to allow drawer to expand
	assert_eq(0, card.get_node("Control/Tokens/Drawer").self_modulate[3],
			"Drawer does not appear card hover when no card has no tokens")
	assert_eq(Vector2(card.get_node("Control").rect_size.x - 35,20), card.get_node("Control/Tokens/Drawer").rect_position,
			"Drawer does not extend when card hover when no card has no tokens")
	card._on_Card_mouse_exited()
	assert_eq(card._ReturnCode.FAILED,card.add_token("Should Fail"),
			"Adding non-defined token returns a FAILED")
	assert_eq(card._ReturnCode.CHANGED, card.add_token("tech"),
			"Adding new token returns a CHANGED result")
	var tech_token = card.get_token("tech")
	assert_eq("tech", tech_token.name, "New token takes the correct name")
	assert_eq("Tech", tech_token.get_node("Name").text,
			"Token label is name capitalized")
	assert_eq(card._ReturnCode.CHANGED, card.add_token("gold coin"),
			"Can add tokens which include spaces")
	assert_eq("Gold Coin", card.get_token("gold coin").get_node("Name").text,
			"Token with space in name label is name capitalized")
	pending("New token texture uses the correct file")
	assert_eq(1,tech_token.count,"New token starts at 1 counter")
	assert_eq("1",tech_token.get_node("CenterContainer/Count").text,
			"New token 1 counter label has the correct number")
	assert_eq(card._ReturnCode.CHANGED, card.add_token("tech"),
			"Increasing token counter returns a CHANGED result")
	assert_eq(2,tech_token.count,"Increased token at 2 counters")
	assert_eq("2",tech_token.get_node("CenterContainer/Count").text,
			"Token change increases label counter too")
	pending("get_tokens() returns correct amount of tokens")
	card._on_Card_mouse_entered()
	yield(yield_for(0.4), YIELD) # Wait to allow drawer to expand
	assert_eq(1, card.get_node("Control/Tokens/Drawer").self_modulate[3],
			"Drawer appears when card has tokens on mouse hover")
	assert_almost_eq(Vector2(card.get_node("Control").rect_size.x,20),
			card.get_node("Control/Tokens/Drawer").rect_position, Vector2(2,2),
			"Drawer extends on card hover card has tokens")
	var prev_y = card.get_node("Control/Tokens/Drawer").rect_size.y
	card.add_token("blood")
	yield(yield_for(0.1), YIELD) # Wait to allow drawer to expand
	assert_lt(prev_y, card.get_node("Control/Tokens/Drawer").rect_size.y,
			"When more tokens drawer size expands")
	card._on_Card_mouse_exited()
	yield(yield_for(0.4), YIELD) # Wait to allow drawer to close
	assert_eq(0, card.get_node("Control/Tokens/Drawer").self_modulate[3],
			"Drawer does not appear card hover when no card has no tokens")
	assert_almost_eq(Vector2(card.get_node("Control").rect_size.x - 35,20),
			card.get_node("Control/Tokens/Drawer").rect_position, Vector2(2,2),
			"Drawer does not extend when card hover when no card has no tokens")
	assert_eq(card._ReturnCode.FAILED,card.remove_token("Should Fail"),
			"Removing non-defined token returns a fail")
	assert_eq(card._ReturnCode.CHANGED, card.remove_token("tech"),
			"Removing token returns a CHANGED result")
	assert_eq(1,tech_token.count,"remove_token() buttons decreases amount")
	assert_eq("1",tech_token.get_node("CenterContainer/Count").text,
			"Counter label has the reduced number")
	assert_eq(card._ReturnCode.CHANGED, card.remove_token("tech"),
			"Removing token to 0 returns a CHANGED result")
	assert_freed(tech_token, "tech")
	pending("Reducing counter to 0, removes the token completely")
	pending("When Tokens are removed, drawer size decreases")
	pending("Drawer closes on drag")
	pending("Drawer closes on moveTo")
	pending("Drawer closes while Flip is ongoing")
	pending("Drawer reopens once Flip is completed")
	pending("Tokens removed when card leaves table")
	pending("Tokens not removed when card leaves with cfc.TOKENS_ONLY_ON_BOARD == false")
	pending("Two tokens can use the same texture but different names")
	pending("Drawer is drawn on top of other cards")
	pause_before_teardown()
