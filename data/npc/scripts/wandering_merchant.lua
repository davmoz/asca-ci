local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Rare items from distant lands! You won't find these anywhere else!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I travel from land to land, trading exotic {wares}. Ask for a {trade} to see what I have!'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'I carry rare items from across the world. Ask for a {trade}!'})
keywordHandler:addAliasKeyword({'wares'})

shopModule:addBuyableItem({'scarab coin'}, 2159, 500, 'scarab coin')
shopModule:addBuyableItem({'protection amulet'}, 2200, 700, 'protection amulet')
shopModule:addBuyableItem({'garlic necklace'}, 2199, 50, 'garlic necklace')
shopModule:addBuyableItem({'stealth ring'}, 2165, 5000, 'stealth ring')
shopModule:addBuyableItem({'magic lightwand'}, 2163, 400, 'magic lightwand')

shopModule:addSellableItem({'scarab coin'}, 2159, 100, 'scarab coin')
shopModule:addSellableItem({'gold nugget'}, 2157, 850, 'gold nugget')

npcHandler:addModule(FocusModule:new())
