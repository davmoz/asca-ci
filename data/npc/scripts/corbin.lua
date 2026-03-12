local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Potions, elixirs, and reagents! The finest alchemical supplies!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am an alchemist. I sell rare {ingredients} and can tell you about potion {recipes}.'})
keywordHandler:addKeyword({'alchemy'}, StdModule.say, {npcHandler = npcHandler, text = 'Alchemy is the art of combining ingredients into powerful potions and elixirs. I can teach you {recipes} if you are interested.'})
keywordHandler:addKeyword({'recipes'}, StdModule.say, {npcHandler = npcHandler, text = 'Combine herbs with vials of water to create basic potions. Add mushrooms for enhanced effects. Mandrake root makes the most potent elixirs!'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Ask for a {trade} to see my ingredients.'})
keywordHandler:addAliasKeyword({'wares'})
keywordHandler:addAliasKeyword({'ingredients'})

shopModule:addBuyableItem({'vial'}, 2006, 5, 'vial')
shopModule:addBuyableItem({'empty potion flask'}, 7636, 5, 'empty potion flask')
shopModule:addBuyableItem({'brown mushroom'}, 2789, 10, 'brown mushroom')
shopModule:addBuyableItem({'white mushroom'}, 2787, 15, 'white mushroom')
shopModule:addBuyableItem({'red mushroom'}, 2788, 20, 'red mushroom')
shopModule:addBuyableItem({'mandrake seeds'}, 30115, 100, 'mandrake seeds')
shopModule:addBuyableItem({'blank rune'}, 2260, 10, 'blank rune')

shopModule:addSellableItem({'brown mushroom'}, 2789, 4, 'brown mushroom')
shopModule:addSellableItem({'white mushroom'}, 2787, 6, 'white mushroom')
shopModule:addSellableItem({'red mushroom'}, 2788, 8, 'red mushroom')

npcHandler:addModule(FocusModule:new())
