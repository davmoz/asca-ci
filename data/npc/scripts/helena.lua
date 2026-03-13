local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Bows, crossbows and ammunition! Best prices in town!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I sell {bows}, {crossbows}, and {ammunition} for hunters and paladins.'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Just ask me for a {trade} to see my offers.'})
keywordHandler:addAliasKeyword({'wares'})

shopModule:addBuyableItem({'bow'}, 2456, 400, 'bow')
shopModule:addBuyableItem({'crossbow'}, 2455, 500, 'crossbow')
shopModule:addBuyableItem({'arrow'}, 2544, 3, 1, 'arrow')
shopModule:addBuyableItem({'bolt'}, 2543, 4, 1, 'bolt')
shopModule:addBuyableItem({'poison arrow'}, 2545, 12, 1, 'poison arrow')
shopModule:addBuyableItem({'burst arrow'}, 2546, 28, 1, 'burst arrow')
shopModule:addBuyableItem({'power bolt'}, 2547, 7, 1, 'power bolt')
shopModule:addBuyableItem({'piercing bolt'}, 7363, 5, 1, 'piercing bolt')
shopModule:addBuyableItem({'spear'}, 2389, 9, 'spear')
shopModule:addBuyableItem({'throwing star'}, 2399, 42, 1, 'throwing star')
shopModule:addBuyableItem({'throwing knife'}, 2410, 25, 1, 'throwing knife')
shopModule:addBuyableItem({'royal spear'}, 7378, 15, 1, 'royal spear')
shopModule:addBuyableItem({'enchanted spear'}, 7367, 40, 1, 'enchanted spear')

shopModule:addBuyableItemContainer({'bp arrow'}, 2000, 2544, 60, 1, 'backpack of arrows')
shopModule:addBuyableItemContainer({'bp bolt'}, 2000, 2543, 80, 1, 'backpack of bolts')
shopModule:addBuyableItemContainer({'bp power bolt'}, 2000, 2547, 140, 1, 'backpack of power bolts')

shopModule:addSellableItem({'bow'}, 2456, 130, 'bow')
shopModule:addSellableItem({'crossbow'}, 2455, 150, 'crossbow')

npcHandler:addModule(FocusModule:new())
