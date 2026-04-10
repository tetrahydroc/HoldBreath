extends Node

var gameData = preload("res://Resources/GameData.tres")
var _settings = preload("res://HoldBreath/HoldBreathSettings.tres")
var _was_holding = false

func _ready():
	overrideScript("res://HoldBreath/HoldBreathRecoil.gd")
	overrideScript("res://HoldBreath/HoldBreathCharacter.gd")
	print("Hold Breath: Loaded")

func overrideScript(modded_path: String):
	var script: Script = load(modded_path)
	if !script:
		print("Hold Breath: Failed to load " + modded_path)
		return
	script.reload()
	var parentScript = script.get_base_script()
	script.take_over_path(parentScript.resource_path)

func _is_holding() -> bool:
	if !gameData.isAiming or gameData.armStamina <= 5.0:
		return false
	if InputMap.has_action("hb_holdKey"):
		return Input.is_action_pressed("hb_holdKey")
	return Input.is_key_pressed(_settings.holdKey)

func _physics_process(delta):
	var scene = get_tree().current_scene
	if !scene:
		return

	var holding = _is_holding()

	var camera = scene.get_node_or_null("Core/Camera/Manager")
	if !camera:
		_was_holding = false
		return

	if holding:
		_was_holding = true
		for child in camera.get_children():
			var noise_node = child.get_node_or_null("Handling/Sway/Noise")
			if noise_node and noise_node.get_script():
				noise_node.finalFrequency = lerp(noise_node.finalFrequency, 0.05, delta * 8.0)
				noise_node.finalAmplitude = lerp(noise_node.finalAmplitude, 0.0005, delta * 8.0)
				noise_node.rotation.x = lerp(noise_node.rotation.x, 0.0, delta * 6.0)
				noise_node.rotation.y = lerp(noise_node.rotation.y, 0.0, delta * 6.0)
				noise_node.rotation.z = lerp(noise_node.rotation.z, 0.0, delta * 6.0)
				break
	elif _was_holding:
		_was_holding = false
		for child in camera.get_children():
			var noise_node = child.get_node_or_null("Handling/Sway/Noise")
			if noise_node and noise_node.get_script():
				noise_node.armMultiplier = 1.0
				break
