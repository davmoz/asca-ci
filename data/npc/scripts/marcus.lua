local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Fine swords and axes! Come take a look!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am the finest weapon smith in all the land. I sell {swords}, {axes}, and {clubs}.'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Just ask me for a {trade} to see my offers.'})
keywordHandler:addAliasKeyword({'wares'})
keywordHandler:addAliasKeyword({'stuff'})

-- Swords
shopModule:addBuyableItem({'sword'}, 2376, 85, 'sword')
shopModule:addBuyableItem({'two handed sword'}, 2377, 450, 'two handed sword')
shopModule:addBuyableItem({'bright sword'}, 2407, 1000, 'bright sword')
shopModule:addBuyableItem({'fire sword'}, 2392, 4000, 'fire sword')
shopModule:addBuyableItem({'giant sword'}, 2393, 17000, 'giant sword')
shopModule:addBuyableItem({'magic longsword'}, 2390, 50000, 'magic longsword')
shopModule:addBuyableItem({'serpent sword'}, 2409, 6000, 'serpent sword')
shopModule:addBuyableItem({'spike sword'}, 2383, 8000, 'spike sword')
shopModule:addBuyableItem({'broad sword'}, 2413, 500, 'broad sword')
shopModule:addBuyableItem({'short sword'}, 2406, 26, 'short sword')
shopModule:addBuyableItem({'sabre'}, 2385, 35, 'sabre')
shopModule:addBuyableItem({'rapier'}, 2384, 15, 'rapier')
shopModule:addBuyableItem({'carlin sword'}, 2395, 473, 'carlin sword')

-- Axes
shopModule:addBuyableItem({'axe'}, 2386, 20, 'axe')
shopModule:addBuyableItem({'battle axe'}, 2378, 235, 'battle axe')
shopModule:addBuyableItem({'hatchet'}, 2388, 25, 'hatchet')
shopModule:addBuyableItem({'double axe'}, 2387, 260, 'double axe')
shopModule:addBuyableItem({'fire axe'}, 2432, 8000, 'fire axe')
shopModule:addBuyableItem({'knight axe'}, 2430, 2000, 'knight axe')
shopModule:addBuyableItem({'stonecutter axe'}, 2431, 24000, 'stonecutter axe')

-- Clubs
shopModule:addBuyableItem({'mace'}, 2398, 90, 'mace')
shopModule:addBuyableItem({'battle hammer'}, 2417, 350, 'battle hammer')
shopModule:addBuyableItem({'morning star'}, 2394, 430, 'morning star')
shopModule:addBuyableItem({'clerical mace'}, 2423, 170, 'clerical mace')
shopModule:addBuyableItem({'war hammer'}, 2391, 1200, 'war hammer')

-- Sell prices
shopModule:addSellableItem({'sword'}, 2376, 25, 'sword')
shopModule:addSellableItem({'two handed sword'}, 2377, 195, 'two handed sword')
shopModule:addSellableItem({'battle axe'}, 2378, 80, 'battle axe')
shopModule:addSellableItem({'axe'}, 2386, 7, 'axe')
shopModule:addSellableItem({'mace'}, 2398, 30, 'mace')
shopModule:addSellableItem({'broad sword'}, 2413, 70, 'broad sword')
shopModule:addSellableItem({'fire sword'}, 2392, 1000, 'fire sword')
shopModule:addSellableItem({'double axe'}, 2387, 90, 'double axe')
shopModule:addSellableItem({'war hammer'}, 2391, 470, 'war hammer')
shopModule:addSellableItem({'morning star'}, 2394, 100, 'morning star')
shopModule:addSellableItem({'hatchet'}, 2388, 8, 'hatchet')

npcHandler:addModule(FocusModule:new())
