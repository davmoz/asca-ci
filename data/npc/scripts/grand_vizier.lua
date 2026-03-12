local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am the Grand Vizier. I hold the power to grant vocation {promotions} to worthy adventurers.'})

local node1 = keywordHandler:addKeyword({'promot'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'I can promote you for 20000 gold coins. You must be at least level 20. Do you want me to promote you?'})
	node1:addChildKeyword({'yes'}, StdModule.promotePlayer, {npcHandler = npcHandler, cost = 20000, level = 20, text = 'Congratulations! You have been promoted. Use your new powers wisely.'})
	node1:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Return when you are ready, adventurer.', reset = true})

npcHandler:addModule(FocusModule:new())
