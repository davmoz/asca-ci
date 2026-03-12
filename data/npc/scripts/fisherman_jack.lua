local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Fresh fish! Caught this morning!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am a fisherman. I sell fresh {fish} and buy your catches. Ask for a {trade}!'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Ask for a {trade} to see my fish selection.'})
keywordHandler:addAliasKeyword({'wares'})

shopModule:addBuyableItem({'fish'}, 2667, 4, 'fish')
shopModule:addBuyableItem({'northern pike'}, 7158, 20, 'northern pike')

shopModule:addSellableItem({'fish'}, 2667, 2, 'fish')
shopModule:addSellableItem({'northern pike'}, 7158, 10, 'northern pike')
shopModule:addSellableItem({'rainbow trout'}, 7159, 20, 'rainbow trout')

npcHandler:addModule(FocusModule:new())
