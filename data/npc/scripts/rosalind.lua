local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Fresh seeds! Grow your own food and herbs!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am a farmer and seed seller. I can teach you about {farming} and sell you {seeds} and tools.'})
keywordHandler:addKeyword({'farming'}, StdModule.say, {npcHandler = npcHandler, text = 'Plant seeds in a farm plot, water them with a watering can, and harvest when ready! Different crops grow at different speeds. Ask about {crops} for details.'})
keywordHandler:addKeyword({'crops'}, StdModule.say, {npcHandler = npcHandler, text = 'Wheat and corn are quick growers. Herbs and mandrake take longer but are more valuable. Starflowers are the rarest crop!'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Ask for a {trade} to see my seeds and tools.'})
keywordHandler:addAliasKeyword({'wares'})
keywordHandler:addAliasKeyword({'seeds'})

shopModule:addBuyableItem({'wheat seeds'}, 30100, 10, 'wheat seeds')
shopModule:addBuyableItem({'corn seeds'}, 30101, 10, 'corn seeds')
shopModule:addBuyableItem({'potato seeds'}, 30102, 15, 'potato seeds')
shopModule:addBuyableItem({'carrot seeds'}, 30103, 15, 'carrot seeds')
shopModule:addBuyableItem({'tomato seeds'}, 30104, 20, 'tomato seeds')
shopModule:addBuyableItem({'onion seeds'}, 30105, 20, 'onion seeds')
shopModule:addBuyableItem({'garlic seeds'}, 30106, 25, 'garlic seeds')
shopModule:addBuyableItem({'lettuce seeds'}, 30107, 15, 'lettuce seeds')
shopModule:addBuyableItem({'pumpkin seeds'}, 30108, 30, 'pumpkin seeds')
shopModule:addBuyableItem({'basil seeds'}, 30109, 35, 'basil seeds')
shopModule:addBuyableItem({'herb seeds'}, 30114, 40, 'herb seeds')
shopModule:addBuyableItem({'mandrake seeds'}, 30115, 100, 'mandrake seeds')
shopModule:addBuyableItem({'starflower seeds'}, 30116, 200, 'starflower seeds')
shopModule:addBuyableItem({'watering can'}, 30120, 100, 'watering can')
shopModule:addBuyableItem({'garden hoe'}, 30121, 100, 'garden hoe')

npcHandler:addModule(FocusModule:new())
