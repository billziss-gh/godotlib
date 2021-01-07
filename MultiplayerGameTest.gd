extends Node2D

func _ready():
    $HostAddresses.text = $MultiplayerGame.get_local_addresses().join("\n")
    $Address.text = $MultiplayerGame.join_address
    $Port.text = String($MultiplayerGame.network_port)
    $MaxClients.text = String($MultiplayerGame.max_joiners)
    $Timeout.text = String($MultiplayerGame.start_game_timeout)

func populate_mgnode():
    $MultiplayerGame.join_address = $Address.text
    $MultiplayerGame.network_port = int($Port.text)
    $MultiplayerGame.max_joiners = int($MaxClients.text)
    $MultiplayerGame.start_game_timeout = int($Timeout.text)

func _on_HostButton_pressed():
    populate_mgnode()
    $StartButton.disabled = false
    $StopButton.disabled = false
    $MultiplayerGame.host()

func _on_JoinButton_pressed():
    populate_mgnode()
    $StartButton.disabled = true
    $StopButton.disabled = true
    $MultiplayerGame.join()

func _on_LeaveButton_pressed():
    #$HostButton.disabled = false
    #$JoinButton.disabled = false
    #$LeaveButton.disabled = true
    $StartButton.disabled = true
    $StopButton.disabled = true
    $MultiplayerGame.leave()

func _on_StartButton_pressed():
    $MultiplayerGame.start_game()

func _on_StopButton_pressed():
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
