extends Node

var is_on_steam: bool = false
var is_on_steam_deck: bool = false
var is_online: bool = false
var is_owned: bool = false
var steam_id: int = 0
var steam_username: String = "[not set]"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.has_singleton("Steam"):
		OS.set_environment("SteamAppId", str(480))
		OS.set_environment("SteamGameId", str(480))
		
	var init_response: Dictionary = Steam.steamInitEx()
	if init_response['status'] != 0:
		printerr("[STEAM] Failed to initialize: %s Shutting down..." % str(init_response['verbal']))
		get_tree().quit()

	is_on_steam = true
	is_on_steam_deck = Steam.isSteamRunningOnSteamDeck()
	is_online = Steam.loggedOn()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	is_owned = Steam.isSubscribed()

	print_debug("Initialized Steam: ", steam_username)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
