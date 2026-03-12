local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Helmets, boots, and leg armor! Complete your outfit here!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I sell {helmets}, {boots}, and {leg armor} of all kinds.'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Just ask me for a {trade} to see my offers.'})
keywordHandler:addAliasKeyword({'wares'})

-- Helmets
shopModule:addBuyableItem({'leather helmet'}, 2461, 12, 'leather helmet')
shopModule:addBuyableItem({'studded helmet'}, 2482, 63, 'studded helmet')
shopModule:addBuyableItem({'chain helmet'}, 2458, 52, 'chain helmet')
shopModule:addBuyableItem({'brass helmet'}, 2460, 120, 'brass helmet')
shopModule:addBuyableItem({'iron helmet'}, 2459, 390, 'iron helmet')
shopModule:addBuyableItem({'steel helmet'}, 2457, 580, 'steel helmet')
shopModule:addBuyableItem({'crown helmet'}, 2491, 2500, 'crown helmet')
shopModule:addBuyableItem({'warrior helmet'}, 2475, 5000, 'warrior helmet')
shopModule:addBuyableItem({'royal helmet'}, 2498, 30000, 'royal helmet')

-- Legs
shopModule:addBuyableItem({'leather legs'}, 2649, 10, 'leather legs')
shopModule:addBuyableItem({'studded legs'}, 2468, 90, 'studded legs')
shopModule:addBuyableItem({'chain legs'}, 2648, 200, 'chain legs')
shopModule:addBuyableItem({'brass legs'}, 2478, 195, 'brass legs')
shopModule:addBuyableItem({'plate legs'}, 2647, 500, 'plate legs')
shopModule:addBuyableItem({'knight legs'}, 2477, 5000, 'knight legs')
shopModule:addBuyableItem({'crown legs'}, 2488, 12000, 'crown legs')
shopModule:addBuyableItem({'golden legs'}, 2470, 30000, 'golden legs')

-- Boots
shopModule:addBuyableItem({'leather boots'}, 2643, 10, 'leather boots')
shopModule:addBuyableItem({'sandals'}, 2642, 2, 'sandals')
shopModule:addBuyableItem({'steel boots'}, 2645, 30000, 'steel boots')
shopModule:addBuyableItem({'boots of haste'}, 2195, 30000, 'boots of haste')
shopModule:addBuyableItem({'golden boots'}, 2646, 50000, 'golden boots')

-- Sell
shopModule:addSellableItem({'leather helmet'}, 2461, 4, 'leather helmet')
shopModule:addSellableItem({'chain helmet'}, 2458, 17, 'chain helmet')
shopModule:addSellableItem({'brass helmet'}, 2460, 30, 'brass helmet')
shopModule:addSellableItem({'iron helmet'}, 2459, 150, 'iron helmet')
shopModule:addSellableItem({'steel helmet'}, 2457, 230, 'steel helmet')
shopModule:addSellableItem({'crown helmet'}, 2491, 800, 'crown helmet')
shopModule:addSellableItem({'leather legs'}, 2649, 2, 'leather legs')
shopModule:addSellableItem({'chain legs'}, 2648, 50, 'chain legs')
shopModule:addSellableItem({'plate legs'}, 2647, 115, 'plate legs')
shopModule:addSellableItem({'knight legs'}, 2477, 1500, 'knight legs')
shopModule:addSellableItem({'leather boots'}, 2643, 2, 'leather boots')

npcHandler:addModule(FocusModule:new())
