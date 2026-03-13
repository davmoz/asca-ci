local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "The ring of hammer on anvil is the sweetest music!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am the master smith. I can teach you about {smithing} and sell you the materials you need.'})
keywordHandler:addKeyword({'smithing'}, StdModule.say, {npcHandler = npcHandler, text = 'To smith items, you need metal bars and an anvil. Smelt ores at a furnace to get bars, then use the bars on an anvil. Start with {bronze} and work up to {orichalcum}!'})
keywordHandler:addKeyword({'bronze'}, StdModule.say, {npcHandler = npcHandler, text = 'Bronze is made by combining copper and tin bars. It is the first metal most smiths learn to work with.'})
keywordHandler:addKeyword({'orichalcum'}, StdModule.say, {npcHandler = npcHandler, text = 'Orichalcum is the rarest and most powerful metal. Only the most skilled smiths can work with it.'})
keywordHandler:addKeyword({'recipes'}, StdModule.say, {npcHandler = npcHandler, text = 'I can teach you many recipes. Bronze items are for beginners. Iron and steel for intermediates. Mithril and above for masters!'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Ask for a {trade} to see my wares.'})
keywordHandler:addAliasKeyword({'wares'})

-- Sell smithing materials
shopModule:addBuyableItem({'copper ore'}, 30300, 50, 'copper ore')
shopModule:addBuyableItem({'tin ore'}, 30301, 50, 'tin ore')
shopModule:addBuyableItem({'iron ore'}, 30302, 100, 'iron ore')
shopModule:addBuyableItem({'coal'}, 30303, 30, 'coal')

-- Buy back bars
shopModule:addSellableItem({'copper bar'}, 30400, 40, 'copper bar')
shopModule:addSellableItem({'tin bar'}, 30401, 40, 'tin bar')
shopModule:addSellableItem({'bronze bar'}, 30402, 60, 'bronze bar')
shopModule:addSellableItem({'iron bar'}, 30403, 80, 'iron bar')
shopModule:addSellableItem({'steel bar'}, 30404, 120, 'steel bar')

npcHandler:addModule(FocusModule:new())
