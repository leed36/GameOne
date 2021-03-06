extends Node

onready var playerVerificationProcess = get_node("PlayerVerification")

var network = NetworkedMultiplayerENet.new()
var port = 1909
const MAX_PLAYERS = 100
var serverCount = 0
var gameServerList = {}

var expectedTokens = []

func _ready():
	start_server()
	
func start_server():
	network.create_server(port, MAX_PLAYERS)
	get_tree().set_network_peer(network)
	Log.DEBUG("master server started!")
	
	network.connect("peer_connected", self, "_peer_connected")
	network.connect("peer_disconnected", self, "_peer_disconnected")


func _peer_connected(clientId):
	print("connected Id: " + String(clientId))
	playerVerificationProcess.start(clientId)
	
func _peer_disconnected(clientId):
	print("disconnected Id: " + String(clientId))
	if has_node(str(clientId)):
		get_node(str(clientId)).queue_free()
		#playerStateCollection.erase(playerId)
		#get_node("GameLogic").playerList.erase(playerId)
		#rpc_id(0, "despawn_player", playerId)

func _on_TokenExpiration_timeout():
	var currentTime = OS.get_unix_time()
	var tokenTime
	if not expectedTokens == []:
		for i in range(expectedTokens.size() - 1, -1, -1):
			tokenTime = int(expectedTokens[i].right(64))
			if currentTime - tokenTime >= 30:
				expectedTokens.remove(i)
				
	print("Expected Tokens: ")
	print(expectedTokens)
	
remote func connect_as_server():
	var serverId = get_tree().get_rpc_sender_id()
	gameServerList[serverId] = { "gameSessions": 0 }
	
func fetch_token(playerId):
	Log.DEBUG("Fetching token from: " + str(playerId))
	rpc_id(playerId, "fetch_token")
	
remote func return_token(token):
	Log.DEBUG("received token, starting verification")
	var playerId = get_tree().get_rpc_sender_id()
	playerVerificationProcess.verify(playerId, token)

func return_token_verification_results(playerId, result):
	Log.DEBUG("token results received")
	rpc_id(playerId, "return_token_verification_results", result)
#	if result == true:
#		rpc_id(0, "spawn_new_player", playerId, Vector3(0, 20, 0))
	
remote func fetch_server_time(clientTime):
	var playerId = get_tree().get_rpc_sender_id()
	rpc_id(playerId, "return_server_time", OS.get_system_time_msecs(), clientTime)
	
remote func determine_latency(clientTime):
	var playerId = get_tree().get_rpc_sender_id()
	rpc_id(playerId, "return_latency", clientTime)

#Lobby calls
remote func request_create_lobby():
	var playerId = get_tree().get_rpc_sender_id()
	LobbyHandler.create_lobby(playerId)
	
func lobby_created(lobbyId):
	var playerId = get_tree().get_rpc_sender_id()
	rpc_id(0, "lobby_created", playerId, lobbyId)
	
remote func request_join_lobby(playerId, lobbyId):
	LobbyHandler.join_lobby(playerId, lobbyId)
	
func lobby_joined(lobbyId):
	var playerId = get_tree().get_rpc_sender_id()
	rpc_id(playerId, "return_lobby_joined", playerId, lobbyId)
	
remote func request_leave_lobby(lobbyId):
	var playerId = get_tree().get_rpc_sender_id()
	LobbyHandler.leave_lobby(playerId, lobbyId)
	
func lobby_left():
	var playerId = get_tree().get_rpc_sender_id()
	rpc_id(playerId, "return_lobby_left")

remote func request_start_game(lobbyId):
	LobbyHandler.start_game(lobbyId)
	
func game_starting(playerId, ip, port):
	rpc_id(playerId, "connect_to_game", "127.0.0.1", "1908")



