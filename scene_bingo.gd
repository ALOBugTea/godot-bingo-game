extends CanvasLayer

signal hit(bingo)
signal repeat(bingo)

signal line_trigger(bingo_nums_array)

@onready var bingo_grid: GridContainer = get_node("MarginContainer/bingoGridContainer")
@onready var bingo_label_total_gacha: Label = get_node("MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/Label2")

@onready var gacha_history: RichTextLabel = $MarginContainer/VBoxContainer/RichTextLabel

@onready var bingo_particle: GPUParticles2D = $GPUParticles2D
@onready var reset_button: Button = $ResetButton

@onready var failed_particle: GPUParticles2D = $GPUParticles2D2
@onready var hit_particle: GPUParticles2D = $GPUParticles2D3

@onready var gacha_result_total_display: VBoxContainer = $HBoxContainer
@onready var gacha_result_total_display_label: Label = $HBoxContainer/Label2

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var audio_stream_player_4: AudioStreamPlayer = $AudioStreamPlayer4


var bingo_lines : Dictionary = {}
var bingo_numbers : Array = []
var bingo_total_gacha : int = 0:
	set(value):
		if not bingo_label_total_gacha:
			await ready
		bingo_label_total_gacha.text = str(value) + " 次"
		gacha_result_total_display_label.text = bingo_label_total_gacha.text
		bingo_total_gacha = value

var bingoBoard = []

@export var is_sound : bool = true

enum HITTYPE {
	HIT,
	REPEAT,
	FAILED
}

class bingo:
	var number : int = 0
	var is_get : bool = false

func _ready() -> void:
	_init_bingo_table()

func _start_bingo_gacha() -> void:
	if is_sound:
		audio_stream_player.play()
	var player_got : int = _get_hit_bingos_size()
	var random_ring_out : int = floor(player_got/5)
	for n in random_ring_out:
		if randi_range(1, 100) > floor(bingo_total_gacha / 200):
			random_ring_out -= 1
	var random_number_range : int = random_ring_out + 1
	var range : Vector2 = Vector2(random_number_range * -1, random_number_range)
	var base_number : int = bingo_numbers.pick_random().number
	range.x = clamp(base_number + range.x, 1, 100) 
	range.y = clamp(base_number + range.y, 1, 100)
	var pickup_out_number : int = randi_range(range.x, range.y)
	if player_got != bingo_numbers.size():
		bingo_total_gacha += 1
	var hit_type : HITTYPE = _confirm_bingo_hit(pickup_out_number)
	if hit_type == HITTYPE.HIT:
		gacha_history.text += "恭喜你抽到了 {0}!\n".format([pickup_out_number])
		hit.emit(pickup_out_number)
		hit_particle.emitting = true
	if hit_type == HITTYPE.REPEAT:
		gacha_history.text += "你抽到了重複的 {0}!\n".format([pickup_out_number])
		repeat.emit(pickup_out_number)
	if hit_type == HITTYPE.FAILED:
		gacha_history.text += "朋友, 歪了個 {0}~\n".format([pickup_out_number])
		failed_particle.emitting = true
	_check_bingo_lines()
	if player_got == bingo_numbers.size() - 1 && hit_type == HITTYPE.HIT:
		bingo_particle.emitting = true
		while bingo_particle.emitting:
			if is_sound:
				audio_stream_player_4.play()
				await audio_stream_player_4.finished
			else:
				await get_tree().physics_frame
		reset_button.show()
		gacha_result_total_display.show()

func _confirm_bingo_hit(_bingo : int) -> HITTYPE:
	var result : HITTYPE = HITTYPE.FAILED
	var bingo = _bingo_number_repeat_search(_bingo)
	if bingo:
		if bingo.is_get:
			result = HITTYPE.REPEAT
		else:
			bingo.is_get = true
			result = HITTYPE.HIT
	return result

func _bingo_number_repeat_search(_bingo : int) -> bingo:
	for bingo in bingo_numbers:
		if bingo.number == _bingo:
			return bingo
	return null

func _is_bingo_exists(_bingo : int) -> bool:
	var bingo = _bingo_number_repeat_search(_bingo)
	var result : bool = bingo != null
	return result

func _is_bingo_hit(_bingo_class : bingo) -> bool:
	return _bingo_class.is_get


func _get_hit_bingos_size() -> int:
	var result : int = 0
	for bingo in bingo_numbers:
		if bingo.is_get:
			result += 1
	return result

func _init_bingo_table() -> void:
	for i in 5:
		bingo_lines["row_"+str(i + 1)] = false
		bingo_lines["col_"+str(i + 1)] = false
	bingo_lines["crosslt_rb"] = false
	bingo_lines["crossrt_lb"] = false
	bingo_total_gacha = 0
	bingoBoard.clear()
	bingo_numbers.clear()
	gacha_result_total_display.hide()
	var range : Vector2i = Vector2i(1, 100)
	for n in 25:
		var randomNumber : int
		while true:
			if n == 7:
				range = _gen_bingo_range()
			randomNumber = randi_range(range.x, range.y)
			if not _is_bingo_exists(randomNumber):
				break
		var _bingo = bingo.new()
		_bingo.number = randomNumber
		bingo_numbers.push_back(_bingo)
	bingo_grid.bingo_numbers = bingo_numbers
	
	for i in 5:
		var temp_array := []
		for j in 5:
			temp_array.append(bingo_numbers[i * 5 + j])
		bingoBoard.append(temp_array)
	

func _check_bingo_lines() -> Array:
	var completed_lines : Array[String] = []

	for i in 5:
		var hit_count : int = 0
		var numbers : Array = []
		var line_name := "row_" + str(i + 1)
		for bn in bingoBoard[i]:
			if _is_bingo_hit(bn):
				hit_count += 1
				numbers.append(bn.number)
			if hit_count >= 5:
				completed_lines.append(line_name)
				if not bingo_lines[line_name]:
					bingo_lines[line_name] = true
					line_trigger.emit(numbers)

	for i in 5:
		var hit_count : int = 0
		var numbers : Array = []
		var line_name := "col_" + str(i + 1)
		for j in 5:
			var bn = bingoBoard[j][i]
			if _is_bingo_hit(bn):
				hit_count += 1
				numbers.append(bn.number)
			if hit_count >= 5:
				completed_lines.append(line_name)
				if not bingo_lines[line_name]:
					bingo_lines[line_name] = true
					line_trigger.emit(numbers)

	var cross_line1 : Array = []
	var cross_line2 : Array = []
	for i in 5:
		cross_line1.append(bingoBoard[i][i])
		cross_line2.append(bingoBoard[i][4-i])

	var line_name := "crosslt_rb"
	var hit_count : int = 0
	var numbers : Array = []
	for bn in cross_line1:
		if _is_bingo_hit(bn):
			hit_count += 1
			numbers.append(bn.number)
	if hit_count >= 5:
		completed_lines.append(line_name)
	if not bingo_lines[line_name]:
		bingo_lines[line_name] = true
		line_trigger.emit(numbers)

	line_name = "crossrt_lb"
	numbers.clear()
	hit_count = 0
	for bn in cross_line2:
		if _is_bingo_hit(bn):
			hit_count += 1
			numbers.append(bn.number)
	if hit_count >= 5:
		completed_lines.append("crossrt_lb")
	if not bingo_lines[line_name]:
		bingo_lines[line_name] = true
		line_trigger.emit(numbers)

	return completed_lines

func _gen_bingo_range() -> Vector2i:
	var range: Vector2i = Vector2i(0, 999)
	for _bn in bingo_numbers:
		var bn = _bn.number
		if bn > range.x:
			range.x = bn
		if bn < range.y:
			range.y = bn
	var randiff = range.y - range.x
	if randiff < 25:
		var range_fixed = 25 - randiff
		if range.y + range_fixed < 100:
			range.y += range_fixed
		elif range.x - range_fixed > 0:
			range.x -= range_fixed
	return range


#var is_using : bool = false

func _on_single_gacha_button_down() -> void:
	#if is_using:
		#return
	#is_using = true
	_start_bingo_gacha()
	#is_using = false

func _on_ten_gacha_button_down() -> void:
	#if is_using:
		#return
	#is_using = true
	for n in 10:
		_start_bingo_gacha()
		await get_tree().create_timer(0.1).timeout
	#is_using = false

func _on_reset_button_button_down() -> void:
	reset_button.hide()
	_init_bingo_table()
	gacha_history.text = ""
