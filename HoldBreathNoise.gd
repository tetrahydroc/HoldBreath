extends "res://Scripts/Noise.gd"

var _printed = false

func _physics_process(delta):
	if !_printed:
		print("Hold Breath Noise: Override active")
		_printed = true

	super(delta)

	# After base processing, override sway if holding breath
	if gameData.isAiming and Input.is_action_pressed("sprint") and gameData.armStamina > 0:
		finalFrequency = lerp(finalFrequency, 0.05, delta * 8.0)
		finalAmplitude = lerp(finalAmplitude, 0.0005, delta * 8.0)

		rotation.x = lerp(rotation.x, 0.0, delta * 6.0)
		rotation.y = lerp(rotation.y, 0.0, delta * 6.0)
		rotation.z = lerp(rotation.z, 0.0, delta * 6.0)
