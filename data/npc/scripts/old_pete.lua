local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "A patient fisher always catches the biggest fish!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am a master fisherman. I can teach you about {fishing} and sell you {rods} and bait.'})
keywordHandler:addKeyword({'fishing'}, StdModule.say, {npcHandler = npcHandler, text = 'To fish, use a fishing rod on water tiles. Better rods catch rarer fish. You can also find treasure while fishing! Talk to me about {rods} or {tips}.'})
keywordHandler:addKeyword({'tips'}, StdModule.say, {npcHandler = npcHandler, text = 'Fish near the deep ocean for the best catches. At night, rare fish come closer to shore. And always bring plenty of worms!'})
keywordHandler:addKeyword({'rods'}, StdModule.say, {npcHandler = npcHandler, text = 'I sell basic fishing rods and upgraded versions. Better rods increase your catch rate and let you catch rarer fish!'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Ask for a {trade} to see my fishing supplies.'})
keywordHandler:addAliasKeyword({'wares'})

shopModule:addBuyableItem({'fishing rod'}, 2580, 150, 'fishing rod')
shopModule:addBuyableItem({'mechanical fishing rod'}, 30020, 500, 'mechanical fishing rod')
shopModule:addBuyableItem({'masterful fishing rod'}, 30021, 2000, 'masterful fishing rod')
shopModule:addBuyableItem({'worm'}, 3976, 2, 'worm')

shopModule:addSellableItem({'fish'}, 2667, 4, 'fish')
shopModule:addSellableItem({'northern pike'}, 7158, 15, 'northern pike')
shopModule:addSellableItem({'rainbow trout'}, 7159, 25, 'rainbow trout')

npcHandler:addModule(FocusModule:new())
