local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Enchant your equipment with the power of Painite crystals!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am an enchantress. I sell {crystals} and teach the art of {enchanting}.'})
keywordHandler:addKeyword({'enchanting'}, StdModule.say, {npcHandler = npcHandler, text = 'Use a Painite crystal on a piece of equipment to enchant it. Small crystals add minor bonuses, while large crystals can add powerful enchantments!'})
keywordHandler:addKeyword({'crystals'}, StdModule.say, {npcHandler = npcHandler, text = 'I sell three types: small, medium, and large Painite crystals. Each provides different levels of enchantment power.'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Ask for a {trade} to see my crystal selection.'})
keywordHandler:addAliasKeyword({'wares'})

shopModule:addBuyableItem({'small painite crystal'}, 30600, 500, 'small painite crystal')
shopModule:addBuyableItem({'medium painite crystal'}, 30601, 2000, 'medium painite crystal')
shopModule:addBuyableItem({'large painite crystal'}, 30602, 8000, 'large painite crystal')

shopModule:addSellableItem({'small painite crystal'}, 30600, 200, 'small painite crystal')
shopModule:addSellableItem({'medium painite crystal'}, 30601, 800, 'medium painite crystal')
shopModule:addSellableItem({'large painite crystal'}, 30602, 3000, 'large painite crystal')

npcHandler:addModule(FocusModule:new())
