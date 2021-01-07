# MultiplayerGame.gd
#
# Copyright 2021 Bill Zissimopoulos

extends Node

signal host_event(connected, detail)
signal join_event(connected, detail)
signal peer_event(connected, id)
signal game_event(status)

enum GameStatus {
    STOP,
    PREPARE,
    _READY,
    PLAY,
}

export var address: String = "127.0.0.1"
export var port: int = 10000
export var max_clients = 1

var messages = {
    "": "no error",
    "connection_failed": "connection failed",
    "server_disconnected": "server disconnected",
    "create_server": "cannot host game",
    "create_client": "cannot join game",
}

var _tree: SceneTree
var _status: int
var _network_server_peers = {}
var _timer

func _enter_tree():
    _tree = get_tree()

func _exit_tree():
    _tree = null

func _ready():
    _tree.connect("connected_to_server", self, "_connected_to_server")
    _tree.connect("connection_failed", self, "_connection_failed")
    _tree.connect("server_disconnected", self, "_server_disconnected")
    _tree.connect("network_peer_connected", self, "_network_peer_connected")
    _tree.connect("network_peer_disconnected", self, "_network_peer_disconnected")

func _connected_to_server():
    call_deferred("emit_signal",
        "join_event", true, "")

func _connection_failed():
    call_deferred("emit_signal",
        "join_event", false, "connection_failed")

func _server_disconnected():
    call_deferred("emit_signal",
        "join_event", false, "server_disconnected")

func _network_peer_connected(id):
    emit_signal("peer_event", true, id)

func _network_peer_disconnected(id):
    if _network_server_peers.has(id):
        _network_server_peers[id] = GameStatus.STOP
    emit_signal("peer_event", false, id)

func host():
    var peer = _tree.network_peer if null != _tree.network_peer else NetworkedMultiplayerENet.new()
    var err = peer.create_server(port, max_clients)
    _tree.network_peer = peer
    if 0 != err:
        call_deferred("emit_signal",
            "host_event", false, "create_server")
    else:
        call_deferred("emit_signal",
            "host_event", true, "")

func join():
    var peer = _tree.network_peer if null != _tree.network_peer else NetworkedMultiplayerENet.new()
    var err = peer.create_client(address, port)
    _tree.network_peer = peer
    if 0 != err:
        call_deferred("emit_signal",
            "join_event", false, "create_client")

func leave():
    var peer = _tree.network_peer
    if null != peer:
        if _tree.is_network_server():
            stop_game()
            peer.close_connection()
            call_deferred("emit_signal",
                "host_event", false, "")
        else:
            peer.close_connection()
            call_deferred("emit_signal",
                "join_event", false, "")
        _tree.network_peer = null

func start_game(timeout = 10):
    assert(_tree.is_network_server())
    assert(_network_server_peers.empty())
    _network_server_peers[1] = GameStatus.PREPARE
    for id in _tree.get_network_connected_peers():
        _network_server_peers[id] = GameStatus.PREPARE
    for id in _network_server_peers:
        rpc_id(id, "_update_game", GameStatus.PREPARE)
    _timer = _tree.create_timer(timeout)
    _timer.connect("timeout", self, "_start_timeout")

func _start_timeout():
    pass
    #stop_game()

func stop_game():
    assert(_tree.is_network_server())
    for id in _network_server_peers:
        if GameStatus.STOP != _network_server_peers[id]:
            rpc_id(id, "_update_game", GameStatus.STOP)
    _network_server_peers.clear()

func ready_to_game():
    rpc_id(1, "_update_game", GameStatus._READY)

remotesync func _update_game(status):
    #print("_update_game ", _tree.get_rpc_sender_id(), " ", status)
    var sender_id = _tree.get_rpc_sender_id()
    match status:
        GameStatus.PREPARE, GameStatus.PLAY, GameStatus.STOP:
            if 1 == sender_id and _status != status:
                _status = status
                call_deferred("emit_signal",
                    "game_event", status)
        GameStatus._READY:
            if _tree.is_network_server() and GameStatus.PREPARE == _network_server_peers.get(sender_id):
                _network_server_peers[sender_id] = GameStatus._READY
                var ready: bool = true
                for id in _network_server_peers:
                    if GameStatus._READY != _network_server_peers[id]:
                        ready = false
                        break
                if ready:
                    for id in _network_server_peers:
                        rpc_id(id, "_update_game", GameStatus.PLAY)
