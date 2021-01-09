# MultiplayerGame.gd
#
# Copyright 2021 Bill Zissimopoulos

extends Node

signal host_event(connected, detail)
signal join_event(connected, detail)
signal game_event(status, arg)
signal peer_event(connected, id)

enum GameStatus {
    STOP,
    PREPARE,
    PLAY,
    _READY,
}

export var network_port: int = 10000
export var max_joiners: int = 1
export var join_address: String = "127.0.0.1"
export var start_game_timeout: int = 10

var error_messages = {
    "": "",
    "connection_failed": "connection to host failed",
    "server_disconnected": "host disconnected",
    "create_server": "cannot host game",
    "create_client": "cannot join game",
}

var _tree: SceneTree
var _rng: RandomNumberGenerator
var _start_game_timer: Timer
var _game_peers = {}
var _game_index: int

func _init():
    _rng = RandomNumberGenerator.new()
    _rng.randomize()
    _start_game_timer = Timer.new()
    _start_game_timer.autostart = false
    _start_game_timer.one_shot = true
    _start_game_timer.connect("timeout", self, "_start_game_timeout")
    add_child(_start_game_timer)
    _game_index = randi()

func _enter_tree():
    _tree = get_tree()
    _tree.connect("connected_to_server", self, "_connected_to_server")
    _tree.connect("connection_failed", self, "_connection_failed")
    _tree.connect("server_disconnected", self, "_server_disconnected")
    _tree.connect("network_peer_connected", self, "_network_peer_connected")
    _tree.connect("network_peer_disconnected", self, "_network_peer_disconnected")

func _exit_tree():
    _tree.disconnect("connected_to_server", self, "_connected_to_server")
    _tree.disconnect("connection_failed", self, "_connection_failed")
    _tree.disconnect("server_disconnected", self, "_server_disconnected")
    _tree.disconnect("network_peer_connected", self, "_network_peer_connected")
    _tree.disconnect("network_peer_disconnected", self, "_network_peer_disconnected")
    _tree = null

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
    if _game_peers.has(id):
        call_deferred("emit_signal",
            "peer_event", true, id)

func _network_peer_disconnected(id):
    if _game_peers.has(id):
        call_deferred("emit_signal",
            "peer_event", false, id)

func get_error_message(detail):
    return error_messages.get(detail, "unknown error")

func get_local_addresses():
    var p: PoolStringArray
    for a in IP.get_local_addresses():
        if a.begins_with("127.") or a.begins_with("169.254.") or ":" in a:
            continue
        p.append(a)
    return p

func host():
    var peer = _tree.network_peer if null != _tree.network_peer else NetworkedMultiplayerENet.new()
    var err = peer.create_server(network_port, max_joiners)
    _tree.network_peer = peer
    if 0 != err:
        call_deferred("emit_signal",
            "host_event", false, "create_server")
    else:
        call_deferred("emit_signal",
            "host_event", true, "")

func join():
    var peer = _tree.network_peer if null != _tree.network_peer else NetworkedMultiplayerENet.new()
    var err = peer.create_client(join_address, network_port)
    _tree.network_peer = peer
    if 0 != err:
        call_deferred("emit_signal",
            "join_event", false, "create_client")

func leave():
    var peer = _tree.network_peer
    if null != peer:
        if _tree.is_network_server():
            _reset_game()
            peer.close_connection()
            call_deferred("emit_signal",
                "host_event", false, "")
        else:
            peer.close_connection()
            call_deferred("emit_signal",
                "join_event", false, "")
        _tree.network_peer = null

func start_game(arg = null):
    assert(_tree.is_network_server())
    if not _game_peers.empty():
        return
    #_tree.network_peer.refuse_new_connections = true
    _game_peers[1] = GameStatus.PREPARE
    for id in _tree.get_network_connected_peers():
        _game_peers[id] = GameStatus.PREPARE
    _game_index = _rng.randi()
    for id in _game_peers:
        rpc_id(id, "_update_game", GameStatus.PREPARE, _game_index, arg)
    _start_game_timer.start(start_game_timeout)

func _start_game_timeout():
    stop_game()

func stop_game():
    assert(_tree.is_network_server())
    for id in _game_peers:
        rpc_id(id, "_update_game", GameStatus.STOP, _game_index, null)
    _reset_game()

func _reset_game():
    _start_game_timer.stop()
    _game_peers.clear()
    _game_index = _rng.randi()

func ready_to_game():
    rpc_id(1, "_update_game", GameStatus._READY, _game_index, null)

func get_game_peers():
    return _game_peers.keys()

remotesync func _update_game(status, index, arg):
    #print("_update_game sender_id=", _tree.get_rpc_sender_id(), " status=", status, " index=", index)
    var sender_id = _tree.get_rpc_sender_id()
    match status:
        GameStatus.PREPARE:
            if 1 == sender_id:
                _game_index = index
                call_deferred("emit_signal",
                    "game_event", status, arg)
        GameStatus.PLAY:
            if 1 == sender_id:
                if _game_index == index:
                    call_deferred("emit_signal",
                        "game_event", status, arg)
        GameStatus.STOP:
            if 1 == sender_id:
                call_deferred("emit_signal",
                    "game_event", status, arg)
        GameStatus._READY:
            if _tree.is_network_server() and \
                _game_index == index and \
                GameStatus.PREPARE == _game_peers.get(sender_id):
                _game_peers[sender_id] = GameStatus._READY
                var ready: bool = true
                for id in _game_peers:
                    if GameStatus._READY != _game_peers[id]:
                        ready = false
                        break
                if ready:
                    _start_game_timer.stop()
                    for id in _game_peers:
                        rpc_id(id, "_update_game", GameStatus.PLAY, _game_index, null)
