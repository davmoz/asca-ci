local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Heavy armor and shields! Protection for every adventurer!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I sell {armor} and {shields} to protect brave adventurers.'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Just ask me for a {trade} to see what I have.'})
keywordHandler:addAliasKeyword({'wares'})

-- Armors
shopModule:addBuyableItem({'leather armor'}, 2467, 25, 'leather armor')
shopModule:addBuyableItem({'chain armor'}, 2464, 200, 'chain armor')
shopModule:addBuyableItem({'brass armor'}, 2465, 450, 'brass armor')
shopModule:addBuyableItem({'plate armor'}, 2463, 1200, 'plate armor')
shopModule:addBuyableItem({'knight armor'}, 2476, 5000, 'knight armor')
shopModule:addBuyableItem({'crown armor'}, 2487, 12000, 'crown armor')
shopModule:addBuyableItem({'magic plate armor'}, 2472, 90000, 'magic plate armor')
shopModule:addBuyableItem({'scale armor'}, 2483, 260, 'scale armor')
shopModule:addBuyableItem({'golden armor'}, 2466, 20000, 'golden armor')

-- Shields
shopModule:addBuyableItem({'wooden shield'}, 2512, 15, 'wooden shield')
shopModule:addBuyableItem({'studded shield'}, 2526, 50, 'studded shield')
shopModule:addBuyableItem({'brass shield'}, 2511, 120, 'brass shield')
shopModule:addBuyableItem({'plate shield'}, 2510, 125, 'plate shield')
shopModule:addBuyableItem({'copper shield'}, 2530, 160, 'copper shield')
shopModule:addBuyableItem({'battle shield'}, 2513, 260, 'battle shield')
shopModule:addBuyableItem({'guardian shield'}, 2515, 2000, 'guardian shield')
shopModule:addBuyableItem({'crown shield'}, 2519, 8000, 'crown shield')
shopModule:addBuyableItem({'tower shield'}, 2528, 8000, 'tower shield')
shopModule:addBuyableItem({'viking shield'}, 2531, 260, 'viking shield')
shopModule:addBuyableItem({'dragon shield'}, 2516, 4000, 'dragon shield')

-- Sell
shopModule:addSellableItem({'leather armor'}, 2467, 5, 'leather armor')
shopModule:addSellableItem({'chain armor'}, 2464, 70, 'chain armor')
shopModule:addSellableItem({'brass armor'}, 2465, 150, 'brass armor')
shopModule:addSellableItem({'plate armor'}, 2463, 400, 'plate armor')
shopModule:addSellableItem({'knight armor'}, 2476, 1500, 'knight armor')
shopModule:addSellableItem({'wooden shield'}, 2512, 3, 'wooden shield')
shopModule:addSellableItem({'brass shield'}, 2511, 25, 'brass shield')
shopModule:addSellableItem({'battle shield'}, 2513, 95, 'battle shield')
shopModule:addSellableItem({'guardian shield'}, 2515, 700, 'guardian shield')
shopModule:addSellableItem({'crown shield'}, 2519, 2400, 'crown shield')

npcHandler:addModule(FocusModule:new())
