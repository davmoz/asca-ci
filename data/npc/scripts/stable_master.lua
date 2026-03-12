local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I look after the horses and mounts. In the future, you may be able to purchase {mounts} here!'})
keywordHandler:addKeyword({'help'}, StdModule.say, {npcHandler = npcHandler, text = 'I manage the stables. Talk to me about {mounts} or {travel} options.'})
keywordHandler:addKeyword({'mounts'}, StdModule.say, {npcHandler = npcHandler, text = 'Mounts are not yet available, but soon you will be able to buy and ride them! Check back later.'})
keywordHandler:addKeyword({'travel'}, StdModule.say, {npcHandler = npcHandler, text = 'For travel, speak with {Harlan} the boat captain or {Sahara} the carpet rider.'})

npcHandler:addModule(FocusModule:new())
