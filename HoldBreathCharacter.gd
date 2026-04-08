extends "res://Scripts/Character.gd"

# Holding breath drains arm stamina 6x faster than normal aiming
const HOLD_BREATH_DRAIN = 12.0

func Stamina(delta):
	var holding = gameData.isAiming and Input.is_action_pressed("sprint") and gameData.armStamina > 5.0

	if holding:
		# Drain arm stamina fast while holding breath
		gameData.armStamina -= delta * HOLD_BREATH_DRAIN

		# Body stamina still follows normal rules
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
