extends "res://Scripts/Recoil.gd"

# Reduce sway to 20% while holding breath
const HOLD_BREATH_SWAY_MULT = 0.2

func CalculateRecoil(delta):
	var holding = gameData.isAiming and Input.is_action_pressed("sprint") and gameData.armStamina > 5.0

	if holding:
		# Dampen existing sway much faster
		currentRotation = lerp(currentRotation, Vector3.ZERO, delta * data.rotationRecovery * 5.0)
		rotation = lerp(rotation, currentRotation * HOLD_BREATH_SWAY_MULT, delta * data.rotationPower)

		currentKick = lerp(currentKick, Vector3.ZERO, delta * data.kickRecovery * 3.0)
		position = lerp(position, currentKick * HOLD_BREATH_SWAY_MULT, delta * data.kickPower)
	else:
		super(delta)

func ApplyRecoil():
	super()
	# If holding breath during a shot, reduce the recoil applied
	if gameData.isAiming and Input.is_action_pressed("sprint") and gameData.armStamina > 5.0:
		currentRotation *= 0.5
		currentKick *= 0.5
