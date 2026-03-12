local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Rich veins of ore await! Get your pickaxe and start mining!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am a mining expert. I sell {pickaxes} and buy raw ores. Ask about {mining} for tips!'})
keywordHandler:addKeyword({'mining'}, StdModule.say, {npcHandler = npcHandler, text = 'Use a pickaxe on ore veins found in caves and mountains. Better pickaxes mine faster and can extract rarer ores. Ask about {ores} or {pickaxes}.'})
keywordHandler:addKeyword({'ores'}, StdModule.say, {npcHandler = npcHandler, text = 'Copper and tin are common. Iron is found deeper. Silver and gold are rare. Mithril, adamantite, and orichalcum are legendary!'})
keywordHandler:addKeyword({'pickaxes'}, StdModule.say, {npcHandler = npcHandler, text = 'I sell three types: basic, steel, and crystal. Crystal pickaxes are the best - they can mine any ore!'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Ask for a {trade} to see my mining supplies.'})
keywordHandler:addAliasKeyword({'wares'})

shopModule:addBuyableItem({'basic pickaxe'}, 30320, 200, 'basic pickaxe')
shopModule:addBuyableItem({'steel pickaxe'}, 30321, 1000, 'steel pickaxe')
shopModule:addBuyableItem({'crystal pickaxe'}, 30322, 5000, 'crystal pickaxe')

shopModule:addSellableItem({'copper ore'}, 30300, 25, 'copper ore')
shopModule:addSellableItem({'tin ore'}, 30301, 25, 'tin ore')
shopModule:addSellableItem({'iron ore'}, 30302, 50, 'iron ore')
shopModule:addSellableItem({'coal'}, 30303, 15, 'coal')
shopModule:addSellableItem({'silver ore'}, 30304, 100, 'silver ore')
shopModule:addSellableItem({'gold ore'}, 30305, 200, 'gold ore')
shopModule:addSellableItem({'mithril ore'}, 30306, 500, 'mithril ore')

npcHandler:addModule(FocusModule:new())
