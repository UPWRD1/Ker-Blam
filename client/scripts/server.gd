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
	get_tree().root.add_child(map.instantiate())

#func add_player(peer_id):
	#var player = Player.instantiate()
	#player.name = str(peer_id)
	#add_child(player)

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)

@rpc("any_peer")
func update_transform(_position, _rotation, _velocity):
	pass

@rpc
func instance_player(id, location):
	print("Instancing player ", id, " at ", location)
	var p = Player if get_tree().get_multiplayer().get_unique_id() == id else OtherPlayer
	var player_instance = Global.instance_node(p, Nodes, location)
	player_instance.name = str(id)
	if get_tree().get_multiplayer().get_unique_id() == id:
		for i in get_tree().get_multiplayer().get_peers():
			if i != 1:
				instance_player(i, location)

@rpc("unreliable", "any_peer")
func update_player_transform(id, nposition, nrotation, nvelocity):
	if get_tree().get_multiplayer().get_unique_id() != id:
		Nodes.get_node(str(id)).update_transform(nposition, nrotation, nvelocity)



func _process(_delta):
	client.poll()
