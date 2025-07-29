extends CharacterBody2D

const BATTERY_DEPLETION      = 10.0
const BATTERY_RECOVERY       = 5.0
const STAMINA_DEPLETION      = 15.0
const STAMINA_RECOVERY       = 5.0
const FLASHLIGHT_TOGGLE_DELAY = 0.2
const SANITY_DEPLETION       = 5.0
const SANITY_RECOVERY        = 2.5

@export var speed             = 200.0
@export var sprint_multiplier = 1.7
@export var stamina          = 100.0

@onready var sanity_label    = get_node("./CanvasLayer/Control/SanityLabel")
@onready var flashlight      = $FlashLight
@onready var blur_rect       = $CanvasLayer/BlurOverlay
@onready var flicker_timer   = $FlashLightFlicker

var battery                  = 100.0
var sanity                   = 100.0
var toggle_timer             = 0.0
var can_sprint               = true
var is_sprinting             = false
var is_near_recharge_port    = false
var is_recharging            = false

func _physics_process(delta):
	# Clamps
	battery = clamp(battery, 0.0, 100.0)
	stamina = clamp(stamina, 0.0, 100.0)
	sanity  = clamp(sanity,  0.0, 100.0)

	# MOVEMENT Walk
	var input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()

	# MOVEMENT Sprint
	if can_sprint and Input.is_action_pressed("sprint") and stamina > 0.0:
		is_sprinting = true
		stamina -= STAMINA_DEPLETION * delta
		if stamina <= 0.0:
			stamina = 0.0
			can_sprint = false
	else:
		is_sprinting = false
		stamina = min(100.0, stamina + STAMINA_RECOVERY * delta)
		if not can_sprint and stamina >= 25.0:
			can_sprint = true

	# MOVEMENT Speed
	var current_speed = speed
	if is_sprinting:
		current_speed = speed * sprint_multiplier

	velocity = input_vector * current_speed
	move_and_slide()

	# BLUR
	var shader_mat = blur_rect.material as ShaderMaterial
	if shader_mat:
		var blur_amount = 0.0
		if is_sprinting:
			blur_amount = 1.0
		shader_mat.set_shader_parameter("blur_amount", blur_amount)

	# LIGHT Toggle
	toggle_timer -= delta
	if Input.is_action_just_pressed("toggle_flashlight") and toggle_timer <= 0.0:
		flashlight.visible = not flashlight.visible
		toggle_timer = FLASHLIGHT_TOGGLE_DELAY

	# LIGHT Battery drain
	if flashlight.visible and battery > 0.0 and not is_recharging:
		battery -= BATTERY_DEPLETION * delta

	# LIGHT Battery enforcement
	if battery <= 0.0:
		flashlight.visible = false
		toggle_timer = FLASHLIGHT_TOGGLE_DELAY

	# LIGHT Battery recharge
	if is_recharging and battery < 100.0:
		battery += BATTERY_RECOVERY * delta
	is_recharging = is_near_recharge_port and battery < 100.0

	# LIGHT Flicker
	if battery <= 10.0 and flicker_timer.is_stopped():
		flicker_timer.start()
	elif battery > 10.0 and not flicker_timer.is_stopped():
		flicker_timer.stop()
		flashlight.visible = true

	# SANITY Drain & Recover
	if not flashlight.visible:
		sanity -= SANITY_DEPLETION * delta
	else:
		sanity += SANITY_RECOVERY * delta

	# SANITY Game over
	if sanity <= 0.0:
		_on_game_over()
	
	# DEBUG -------------------------------------------------------------------------------------------------------------------
	sanity_label.text = "sanity: " + str(round(sanity))

func _on_FlashLightFlicker_timeout():
	if battery <= 10.0:
		flashlight.visible = not flashlight.visible

func _on_recharge_port_body_entered(body: Node2D) -> void:
	if body == self:
		is_near_recharge_port = true

func _on_recharge_port_body_exited(body: Node2D) -> void:
	if body == self:
		is_near_recharge_port = false

func _on_game_over():
	# get_tree().change_scene("res://scenes/GameOver.tscn")
	print("game over")
