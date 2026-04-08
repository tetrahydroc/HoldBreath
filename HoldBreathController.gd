extends "res://Scripts/Controller.gd"

func Headbob(delta):
	if gameData.isAiming and Input.is_action_pressed("sprint") and gameData.armStamina > 0:
		# Kill headbob while holding breath
		bob.position.x = lerp(bob.position.x, 0.0, delta * 10.0)
		bob.position.y = lerp(bob.position.y, 0.0, delta * 10.0)
		return

	super(delta)
