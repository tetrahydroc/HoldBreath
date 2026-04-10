extends Node

var McmHelpers = load("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")
var settings = preload("res://HoldBreath/HoldBreathSettings.tres")

var config = ConfigFile.new()

const FILE_PATH = "user://MCM/HoldBreath"
const MOD_ID = "hold-breath"

func _ready() -> void:
	config.set_value("Keycode", "hb_holdKey", {
		"name" = "Hold Breath Key",
		"tooltip" = "Key to hold breath while aiming (reduces scope sway)",
		"default" = KEY_SHIFT,
		"value" = KEY_SHIFT
	})

	if McmHelpers != null:
		if !FileAccess.file_exists(FILE_PATH + "/config.ini"):
			DirAccess.open("user://").make_dir_recursive(FILE_PATH)
			config.save(FILE_PATH + "/config.ini")
		else:
			McmHelpers.CheckConfigurationHasUpdated(MOD_ID, config, FILE_PATH + "/config.ini")
			config.load(FILE_PATH + "/config.ini")

		_on_config_updated(config)

		McmHelpers.RegisterConfiguration(
			MOD_ID,
			"Hold Breath",
			FILE_PATH,
			"Configure the hold breath keybind",
			{
				"config.ini" = _on_config_updated
			}
		)

func _on_config_updated(_config: ConfigFile):
	settings.holdKey = _config.get_value("Keycode", "hb_holdKey")["value"]
	print("Hold Breath: Keybind updated to " + str(settings.holdKey))
