extends Node

@onready var transition := $CanvasLayer/Transition
@onready var everything := $CanvasLayer
@onready var home_menu := $CanvasLayer/Menu1
@onready var lan_menu := $CanvasLayer/Menu2
@onready var address_entry := $CanvasLayer/Menu2/ColorRect/MainMenu/MarginContainer/VBoxContainer/AddressEntry 
@onready var bg := $CanvasLayer/Menu2/ColorRect
@onready var play_button := $CanvasLayer/Menu1/ColorRect/MainMenu/MarginContainer/VBoxContainer/PlayButton
#@onready var prog = transition.material.get("shader_parameter/progress")

const Player = preload("res://Player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	transition.show()
	home_menu.show()
	lan_menu.hide()

func _on_host_button_pressed() -> void:
	transition_in()
	await get_tree().create_timer(0.1).timeout
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	lan_menu.hide()
	bg.hide()
	await get_tree().create_timer(0.1).timeout
	add_player(multiplayer.get_unique_id())
	PlayerStats.mpstat = PlayerStats.MpStatus.HOSTING
	transition_out()
	
	#upnp_setup()

func _on_join_button_pressed() -> void:
	transition_in()
	lan_menu.hide()
	bg.hide()
	await get_tree().create_timer(0.1).timeout
	transition_out()
	PlayerStats.mpstat = PlayerStats.MpStatus.JOINING
	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	multiplayer.peer_connected.connect(add_player)

func add_player(peer_id: int) -> void:
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)

func remove_player(peer_id: int) -> void:
	var player := get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func upnp_setup() -> void:
	var upnp := UPNP.new()
		
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)

	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")

	var map_result := upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())

func _on_play_button_pressed() -> void:
	transition_in()
	await get_tree().create_timer(0.1).timeout
	home_menu.hide()
	lan_menu.show()
	transition_out()

func transition_in() -> void:
	var amt := 0.0
	while amt <= 1:
		amt += 0.05
		transition.material.set("shader_parameter/progress", amt)
		await get_tree().create_timer(0.01).timeout
		
func transition_out() -> void:
	var amt := 1.0
	while amt <= 1:
		amt -= 0.05
		transition.material.set("shader_parameter/progress", amt)
		await get_tree().create_timer(0.01).timeout

func _on_find_match_button_pressed() -> void:
	transition_in()
	await get_tree().create_timer(0.05).timeout
	Server.join_server()
	 # Replace with function body.
	transition_out()
	await get_tree().create_timer(0.05).timeout
	PlayerStats.mpstat = PlayerStats.MpStatus.CLIENT
	everything.hide()
