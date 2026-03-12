local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Picks, shovels, ropes! Every adventurer needs the right tools!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I sell all manner of {tools} - picks, rods, farming tools, and crafting materials.'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Just ask me for a {trade} to see my wares.'})
keywordHandler:addAliasKeyword({'wares'})
keywordHandler:addAliasKeyword({'tools'})

shopModule:addBuyableItem({'pick'}, 2553, 50, 'pick')
shopModule:addBuyableItem({'shovel'}, 2554, 50, 'shovel')
shopModule:addBuyableItem({'rope'}, 2120, 50, 'rope')
shopModule:addBuyableItem({'machete'}, 2420, 35, 'machete')
shopModule:addBuyableItem({'crowbar'}, 2416, 50, 'crowbar')
shopModule:addBuyableItem({'fishing rod'}, 2580, 150, 'fishing rod')
shopModule:addBuyableItem({'scythe'}, 2550, 50, 'scythe')
shopModule:addBuyableItem({'torch'}, 2050, 2, 'torch')
shopModule:addBuyableItem({'watering can'}, 30120, 100, 'watering can')
shopModule:addBuyableItem({'garden hoe'}, 30121, 100, 'garden hoe')
shopModule:addBuyableItem({'basic pickaxe'}, 30320, 200, 'basic pickaxe')

shopModule:addSellableItem({'pick'}, 2553, 15, 'pick')
shopModule:addSellableItem({'shovel'}, 2554, 8, 'shovel')
shopModule:addSellableItem({'machete'}, 2420, 6, 'machete')

npcHandler:addModule(FocusModule:new())
