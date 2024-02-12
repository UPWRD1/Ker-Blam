extends Node

@onready var Player = preload("res://Player.tscn")
@onready var OtherPlayer = preload("res://OtherPlayers.tscn")

@onready var map = preload("res://scenes/main.tscn")

var client

func _ready():
	set_process(false)
	pass

func join_server():
	#var client = ENetMultiplayerPeer.new()
	#var err = client.create_client("LOCALHOST", 4242)
	#if err != OK:
		#print("Unable to connect")
		#return
	#multiplayer.multiplayer_peer = client
	client = WebSocketMultiplayerPeer.new()
	var err = client.create_client("127.0.0.1:4242", TLSOptions.client())
	if err != OK:
		print("Unable to connect")
		return
	multiplayer.multiplayer_peer = client
	set_process(true)
	connected_to_server()

func connection_failed():
	print("Connection failed!")
	
func server_disconnected():
	print("Server disconnected")
	
func connected_to_server():
	print("Connected to server")
	var nmap = map.instantiate()
	nmap.name = "Map"
	get_tree().root.add_child(nmap)

#func add_player(peer_id):
	#var player = Player.instantiate()
	#player.name = str(peer_id)
	#add_child(player)

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)

@rpc("any_peer")
func instance_player(id, location):
	print("Instancing player ", id, " at ", location)
	var p = Player if get_tree().get_multiplayer().get_unique_id() == id else OtherPlayer
	var player_instance = Global.instance_node(p, Nodes, location)
	player_instance.name = str(id)
	add_child(player_instance)
	if get_tree().get_multiplayer().get_unique_id() == id:
		for i in get_tree().get_multiplayer().get_peers():
			if i != 1:
				instance_player(i, location)
	
func _process(delta):
	client.poll()
