local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am a city guard. I keep the peace and protect the citizens.'})
keywordHandler:addKeyword({'help'}, StdModule.say, {npcHandler = npcHandler, text = 'If you need help, talk to the {Commander Thane} or visit the {temple} for healing.'})
keywordHandler:addKeyword({'name'}, StdModule.say, {npcHandler = npcHandler, text = 'I am a guard in service of the city.'})
keywordHandler:addKeyword({'city'}, StdModule.say, {npcHandler = npcHandler, text = 'This is a fine city. You can find {shops}, a {bank}, and the {temple} here.'})
keywordHandler:addKeyword({'shops'}, StdModule.say, {npcHandler = npcHandler, text = 'We have weapon, armor, magic, tool, potion, and general shops. Look for the shopkeepers around the market square.'})
keywordHandler:addKeyword({'bank'}, StdModule.say, {npcHandler = npcHandler, text = 'The bank is nearby. Talk to the Banker to manage your gold.'})
keywordHandler:addKeyword({'temple'}, StdModule.say, {npcHandler = npcHandler, text = 'The temple provides healing and blessings. Visit Father Aldric or Monk Samuel.'})
keywordHandler:addKeyword({'danger'}, StdModule.say, {npcHandler = npcHandler, text = 'Be careful outside the city walls. Monsters lurk in the wilderness and dungeons!'})

npcHandler:addModule(FocusModule:new())
