extends "res://Scripts/Character.gd"

const HOLD_BREATH_DRAIN = 12.0
var _settings = preload("res://HoldBreath/HoldBreathSettings.tres")

func _is_holding() -> bool:
	if !gameData.isAiming or gameData.armStamina <= 5.0:
		return false
	if InputMap.has_action("hb_holdKey"):
		return Input.is_action_pressed("hb_holdKey")
	return Input.is_key_pressed(_settings.holdKey)

func Stamina(delta):
	if _is_holding():
		gameData.armStamina -= delta * HOLD_BREATH_DRAIN

		if gameData.bodyStamina > 0 and (gameData.isRunning or gameData.overweight or (gameData.isSwimming and gameData.isMoving)):
			if gameData.overweight or gameData.starvation or gameData.dehydration:
				gameData.bodyStamina -= delta * 4.0
			else:
				gameData.bodyStamina -= delta * 2.0
		elif gameData.bodyStamina < 100:
			if gameData.starvation or gameData.dehydration:
				gameData.bodyStamina += delta * 5.0
			else:
				gameData.bodyStamina += delta * 10.0
	else:
		super(delta)
