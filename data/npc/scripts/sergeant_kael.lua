local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am the depot guard. I ensure the safety of all stored items and can tell you about the {depot} system.'})
keywordHandler:addKeyword({'depot'}, StdModule.say, {npcHandler = npcHandler, text = 'The depot is where you can safely store your items. Simply stand on a depot tile and you will see your depot chest. Each city has its own depot.'})
keywordHandler:addKeyword({'store'}, StdModule.say, {npcHandler = npcHandler, text = 'To store items, find a depot tile in any city. Stand on it and open the depot chest to manage your belongings.'})
keywordHandler:addKeyword({'help'}, StdModule.say, {npcHandler = npcHandler, text = 'I can tell you about the {depot} system, how to {store} items, and about {security} in this city.'})
keywordHandler:addKeyword({'security'}, StdModule.say, {npcHandler = npcHandler, text = 'Rest assured, your items are perfectly safe in the depot. No one else can access your stored belongings.'})

npcHandler:addModule(FocusModule:new())
