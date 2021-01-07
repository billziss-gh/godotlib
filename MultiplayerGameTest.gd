extends Node2D

func _ready():
    $Address.text = $MultiplayerGame.address
    $Port.text = String($MultiplayerGame.port)
    $MaxClients.text = String($MultiplayerGame.max_clients)

func populate_mgnode():
    $MultiplayerGame.address = $Address.text
    $MultiplayerGame.port = int($Port.text)
    $MultiplayerGame.max_clients = int($MaxClients.text)

func _on_HostButton_pressed():
    populate_mgnode()
    $HostButton.disabled = true
    $JoinButton.disabled = true
    $LeaveButton.disabled = false
    $StartButton.disabled = false
    $StopButton.disabled = true
    $MultiplayerGame.host()

func _on_JoinButton_pressed():
    populate_mgnode()
    $HostButton.disabled = true
    $JoinButton.disabled = true
    $LeaveButton.disabled = false
    $StartButton.disabled = true
    $StopButton.disabled = true
    $MultiplayerGame.join()

func _on_LeaveButton_pressed():
    $HostButton.disabled = false
    $JoinButton.disabled = false
    $LeaveButton.disabled = true
    $StartButton.disabled = true
    $StopButton.disabled = true
    $MultiplayerGame.leave()

func _on_StartButton_pressed():
    var timeout = int($Timeout.text)
    $StartButton.disabled = true
    $StopButton.disabled = false
    $MultiplayerGame.start_game(timeout)

func _on_StopButton_pressed():
    $StartButton.disabled = false
    $StopButton.disabled = true
    $MultiplayerGame.stop_game()

func _on_MultiplayerGame_host_event(connected, detail):
    print("host_event: ", connected, " ", detail)

func _on_MultiplayerGame_join_event(connected, detail):
    print("join_event: ", connected, " ", detail)

func _on_MultiplayerGame_peer_event(connected, id):
    print("peer_event: ", connected, " ", id)

func _on_MultiplayerGame_game_event(status):
    print("game_event: ", status)
    if $MultiplayerGame.GameStatus.PREPARE == status:
        $MultiplayerGame.ready_to_game()
