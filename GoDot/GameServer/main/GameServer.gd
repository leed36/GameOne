extends Node

onready var PlayerContainer = preload("res://main/PlayerContainer/PlayerContainer.tscn") # Relative path

var network = NetworkedMultiplayerENet.new()
var port = 1908
const MAX_PLAYERS = 100

var clientClock = 0
var decimalCollector : float = 0
var latencyArray = []
var latency = 0
var deltaLatency = 0


func _ready():
#	Gateway.connect_to_server("server1", "server1", false) # for testing
	start_server()
	
func _physics_process(delta):
	clientClock += int(delta * 1000) + deltaLatency
	deltaLatency = 0 
	decimalCollector += (delta * 1000) - int(delta * 1000)
	if decimalCollector >= 1.00:
		clientClock += 1
		decimalCollector -= 1.00

func start_server():
	network.create_server(port, MAX_PLAYERS)
	get_tree().set_network_peer(network)
	
	network.connect("peer_connected", self, "_peer_connected")
	network.connect("peer_disconnected", self, "_peer_disconnected")
	Log.DEBUG("game server started!")

func create_player_container(playerId):
	var newPlayerContainer = PlayerContainer.instance()
	newPlayerContainer.name = str(playerId)
	add_child(newPlayerContainer, true)
	#var playerContainer = get_node(str(playerId))
	#fill_player_container(playerContainer)

func _peer_connected(playerId):
	Log.INFO("connected Id: " + String(playerId))
	create_player_container(playerId)
	
func _peer_disconnected(playerId):
	Log.INFO("disconnected Id: " + String(playerId))
	if has_node(str(playerId)):
		get_node(str(playerId)).queue_free()
		StateProcessing.playerStateCollection.erase(playerId)
		StateProcessing.playerList.erase(playerId)
		rpc_id(0, "despawn_player", playerId)

remote func fetch_server_time(clientTime):
	var playerId = get_tree().get_rpc_sender_id()
	rpc_id(playerId, "return_server_time", OS.get_system_time_msecs(), clientTime)
	
remote func determine_latency(clientTime):
	var playerId = get_tree().get_rpc_sender_id()
	rpc_id(playerId, "return_latency", clientTime)

remote func receive_player_state(playerState):
	var playerId = get_tree().get_rpc_sender_id()
	var collection = StateProcessing.playerStateCollection
	if collection.has(playerId):
		if collection[playerId]["T"] < playerState["T"]:
			collection[playerId] = playerState
	else:
		collection[playerId] = playerState

func send_world_state(worldState):
	rpc_unreliable_id(0, "receive_world_state", worldState)

remote func start_game():
	pass

remote func game_starting():
	pass
	
#Combat rpc calls
func player_hit(playerId, damage):
	rpc_id(0, "send_player_hit", playerId, damage)

remote func attack(attack, clientClock):
	var playerId = get_tree().get_rpc_sender_id()
	rpc_id(0, "receive_attack", clientClock, playerId, attack, 10)
