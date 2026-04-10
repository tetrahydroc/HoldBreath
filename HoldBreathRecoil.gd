extends "res://Scripts/Recoil.gd"

const HOLD_BREATH_SWAY_MULT = 0.2
var _settings = preload("res://HoldBreath/HoldBreathSettings.tres")

func _is_holding() -> bool:
	if !gameData.isAiming or gameData.armStamina <= 5.0:
		return false
	if InputMap.has_action("hb_holdKey"):
		return Input.is_action_pressed("hb_holdKey")
	return Input.is_key_pressed(_settings.holdKey)

func CalculateRecoil(delta):
	if _is_holding():
		currentRotation = lerp(currentRotation, Vector3.ZERO, delta * data.rotationRecovery * 5.0)
		rotation = lerp(rotation, currentRotation * HOLD_BREATH_SWAY_MULT, delta * data.rotationPower)
		currentKick = lerp(currentKick, Vector3.ZERO, delta * data.kickRecovery * 3.0)
		position = lerp(position, currentKick * HOLD_BREATH_SWAY_MULT, delta * data.kickPower)
	else:
		super(delta)

func ApplyRecoil():
	super()
	if _is_holding():
		currentRotation *= 0.5
		currentKick *= 0.5
