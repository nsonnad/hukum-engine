HukumEngine.new_game("GAME3")
HukumEngine.add_player(HukumEngine.GameServer.via_tuple("GAME3"), "player1")
HukumEngine.add_player(HukumEngine.GameServer.via_tuple("GAME3"), "player2")
HukumEngine.add_player(HukumEngine.GameServer.via_tuple("GAME3"), "player3")
HukumEngine.add_player(HukumEngine.GameServer.via_tuple("GAME3"), "player4")
#HukumEngine.call_or_pass(pid)

#g1 = HukumEngine.calling(pid)
#p1 = Keyword.get(g1.players, g1.turn)
#first_card = Enum.at(p1.hand, 0)

#g2 = HukumEngine.play_first_card(pid, g1.turn, p1.team, first_card)
#p2 = Keyword.get(g2.players, g2.turn)
#called = HukumEngine.call_trump(pid, trump_to_call, p2.team)
