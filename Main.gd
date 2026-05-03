extends Node

# HoldBreath -- holding the configured key while aiming reduces sway/recoil
# at the cost of arm stamina. Migrated from the overrideScript pattern (which
# took whole-method ownership of Recoil + Character) to pre/post hooks so
# other mods touching those methods can still compose.
#
# The modded behavior on Recoil.CalculateRecoil and Character.Stamina is a
# substitute for vanilla, not an enhancement. Without replace hooks, we get
# the same end state via the "stash-and-restore" pattern:
#   * Pre-hook: if predicate true, snapshot the fields vanilla will mutate.
#   * Vanilla runs.
#   * Post-hook: if snapshot exists, restore and apply our calc directly.
# Net effect == replace-with-skip_super, but the hook slots stay open for
# additional pre/post callbacks from other mods. Costs a few wasted vanilla
# cycles per tick when holding -- acceptable tradeoff.

var gameData = preload("res://Resources/GameData.tres")
var _settings = preload("res://HoldBreath/HoldBreathSettings.tres")

const HOLD_BREATH_DRAIN := 12.0
const HOLD_BREATH_SWAY_MULT := 0.2

var _was_holding := false
var _lib = null

# Stamina snapshots live on the autoload because gameData is a singleton --
# only one player. Recoil snapshots live on the caller node's meta because a
# scene can have multiple Recoil instances (one per active weapon).
var _stash_arm: float = -1.0     # -1 sentinel = no snapshot
var _stash_body: float = -1.0


func _ready() -> void:
	if Engine.has_meta("RTVModLib"):
		var lib = Engine.get_meta("RTVModLib")
		if lib._is_ready:
			_register_hooks()
		else:
			lib.frameworks_ready.connect(_register_hooks)
	else:
		push_warning("HoldBreath: RTVModLib not found; hooks unavailable")
	print("Hold Breath: Loaded")


func _register_hooks() -> void:
	_lib = Engine.get_meta("RTVModLib")
	_lib.hook_many({
		"recoil-calculaterecoil-pre":  _on_calc_recoil_pre,
		"recoil-calculaterecoil-post": _on_calc_recoil_post,
		"recoil-applyrecoil-post":     _on_apply_recoil_post,
		"character-stamina-pre":       _on_stamina_pre,
		"character-stamina-post":      _on_stamina_post,
	})
	print("Hold Breath: Hooks registered")


func _is_holding() -> bool:
	if !gameData.isAiming or gameData.armStamina <= 5.0:
		return false
	if InputMap.has_action("hb_holdKey"):
		return Input.is_action_pressed("hb_holdKey")
	return Input.is_key_pressed(_settings.holdKey)


# --- Recoil.CalculateRecoil ---------------------------------------------------
# Vanilla:
#   currentRotation = lerp(currentRotation, ZERO, delta * data.rotationRecovery)
#   rotation        = lerp(rotation, currentRotation, delta * data.rotationPower)
#   currentKick     = lerp(currentKick, ZERO, delta * data.kickRecovery)
#   position        = lerp(position, currentKick, delta * data.kickPower)
#
# Modded when holding (faster recovery + sway scaled down):
#   currentRotation = lerp(currentRotation, ZERO, delta * data.rotationRecovery * 5.0)
#   rotation        = lerp(rotation, currentRotation * SWAY_MULT, delta * data.rotationPower)
#   currentKick     = lerp(currentKick, ZERO, delta * data.kickRecovery * 3.0)
#   position        = lerp(position, currentKick * SWAY_MULT, delta * data.kickPower)

func _on_calc_recoil_pre(_delta: float) -> void:
	if not _is_holding():
		return
	var r: Node = _lib._caller
	if r == null:
		return
	# Snapshot every field vanilla will overwrite. Marker meta lets the post
	# hook know we stashed; absence means "not holding this tick, leave alone."
	r.set_meta("_hb_stash_currentRotation", r.currentRotation)
	r.set_meta("_hb_stash_currentKick",     r.currentKick)
	r.set_meta("_hb_stash_rotation",        r.rotation)
	r.set_meta("_hb_stash_position",        r.position)


func _on_calc_recoil_post(delta: float) -> void:
	var r: Node = _lib._caller
	if r == null or not r.has_meta("_hb_stash_currentRotation"):
		return
	# Restore pre-vanilla state so our calc starts from the same input.
	r.currentRotation = r.get_meta("_hb_stash_currentRotation")
	r.currentKick     = r.get_meta("_hb_stash_currentKick")
	r.rotation        = r.get_meta("_hb_stash_rotation")
	r.position        = r.get_meta("_hb_stash_position")
	r.remove_meta("_hb_stash_currentRotation")
	r.remove_meta("_hb_stash_currentKick")
	r.remove_meta("_hb_stash_rotation")
	r.remove_meta("_hb_stash_position")
	# Modded calc.
	r.currentRotation = lerp(r.currentRotation, Vector3.ZERO, delta * r.data.rotationRecovery * 5.0)
	r.rotation        = lerp(r.rotation, r.currentRotation * HOLD_BREATH_SWAY_MULT, delta * r.data.rotationPower)
	r.currentKick     = lerp(r.currentKick, Vector3.ZERO, delta * r.data.kickRecovery * 3.0)
	r.position        = lerp(r.position, r.currentKick * HOLD_BREATH_SWAY_MULT, delta * r.data.kickPower)


# --- Recoil.ApplyRecoil -------------------------------------------------------
# Vanilla sets currentRotation/currentKick from data; we halve them when
# holding. Pure post-mutation -- no stash needed.
func _on_apply_recoil_post() -> void:
	if not _is_holding():
		return
	var r: Node = _lib._caller
	if r == null:
		return
	r.currentRotation *= 0.5
	r.currentKick *= 0.5


# --- Character.Stamina --------------------------------------------------------
# Vanilla runs body-stamina logic (drain on running/etc., regen otherwise) and
# arm-stamina logic (drain when aiming weapon, regen otherwise). Modded when
# holding: skip vanilla's arm logic entirely (no drain/regen from aiming),
# drain armStamina by HOLD_BREATH_DRAIN. Body logic only runs the *drain*
# branch, never the regen branch.

func _on_stamina_pre(_delta: float) -> void:
	if not _is_holding():
		return
	# armStamina>0 sentinel means we stashed this tick; reset to -1 every
	# post to avoid leaking state if the post somehow doesn't fire.
	_stash_arm = gameData.armStamina
	_stash_body = gameData.bodyStamina


func _on_stamina_post(delta: float) -> void:
	if _stash_arm < 0.0:
		return
	# Restore -- erase whatever vanilla just did.
	gameData.armStamina = _stash_arm
	gameData.bodyStamina = _stash_body
	_stash_arm = -1.0
	_stash_body = -1.0
	# Modded: arm always drains by HOLD_BREATH_DRAIN.
	gameData.armStamina -= delta * HOLD_BREATH_DRAIN
	# Modded body block: drain only, no regen path.
	if gameData.bodyStamina > 0 and (gameData.isRunning or gameData.overweight or (gameData.isSwimming and gameData.isMoving)):
		if gameData.overweight or gameData.starvation or gameData.dehydration:
			gameData.bodyStamina -= delta * 4.0
		else:
			gameData.bodyStamina -= delta * 2.0


# --- Noise lerping (autoload tick, not a hook) -------------------------------
# Walks the active camera tree to find the Noise node and damps its
# frequency/amplitude while holding. No good vanilla method to wrap (Noise
# nodes are scene-tree children, not a class with a stable hook target), and
# this runs once per frame total (not per-instance), so wrapping wouldn't
# save anything.

func _physics_process(delta: float) -> void:
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
