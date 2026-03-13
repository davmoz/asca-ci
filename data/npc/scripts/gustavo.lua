local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "The finest cuisine in all the land! Come taste my creations!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am the master chef! I teach {cooking} and sell cooking {ingredients}.'})
keywordHandler:addKeyword({'cooking'}, StdModule.say, {npcHandler = npcHandler, text = 'To cook, use ingredients on a stove, oven, or campfire. Cooked meals give temporary {buffs} that help in combat!'})
keywordHandler:addKeyword({'buffs'}, StdModule.say, {npcHandler = npcHandler, text = 'Different meals provide different bonuses. Hearty stew boosts health regeneration. Fish fillet boosts mana. Try different {recipes}!'})
keywordHandler:addKeyword({'recipes'}, StdModule.say, {npcHandler = npcHandler, text = 'Start with simple recipes: bread from flour, roasted meat from raw meat. Advanced recipes combine multiple ingredients for powerful buffs!'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Ask for a {trade} to see my ingredients!'})
keywordHandler:addAliasKeyword({'wares'})
keywordHandler:addAliasKeyword({'ingredients'})

shopModule:addBuyableItem({'meat'}, 2666, 5, 'meat')
shopModule:addBuyableItem({'ham'}, 2671, 8, 'ham')
shopModule:addBuyableItem({'fish'}, 2667, 4, 'fish')
shopModule:addBuyableItem({'cheese'}, 2696, 6, 'cheese')
shopModule:addBuyableItem({'bread'}, 2689, 3, 'bread')
shopModule:addBuyableItem({'egg'}, 2695, 3, 'egg')
shopModule:addBuyableItem({'flour'}, 2692, 5, 'flour')
shopModule:addBuyableItem({'brown mushroom'}, 2789, 10, 'brown mushroom')

npcHandler:addModule(FocusModule:new())
