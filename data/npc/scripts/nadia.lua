local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Food, rope, bags, and more! Your one-stop general store!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I run the general store. I sell {food}, {containers}, {rope}, {torches}, and other essentials.'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Just ask me for a {trade} to see everything I have.'})
keywordHandler:addAliasKeyword({'wares'})

-- Food
shopModule:addBuyableItem({'meat'}, 2666, 5, 'meat')
shopModule:addBuyableItem({'ham'}, 2671, 8, 'ham')
shopModule:addBuyableItem({'bread'}, 2689, 3, 'bread')
shopModule:addBuyableItem({'cheese'}, 2696, 6, 'cheese')
shopModule:addBuyableItem({'apple'}, 2674, 3, 'apple')
shopModule:addBuyableItem({'brown mushroom'}, 2789, 10, 'brown mushroom')
shopModule:addBuyableItem({'fish'}, 2667, 4, 'fish')

-- Containers
shopModule:addBuyableItem({'backpack'}, 1988, 20, 'backpack')
shopModule:addBuyableItem({'bag'}, 1987, 4, 'bag')

-- Tools/Essentials
shopModule:addBuyableItem({'rope'}, 2120, 50, 'rope')
shopModule:addBuyableItem({'torch'}, 2050, 2, 'torch')
shopModule:addBuyableItem({'candelabrum'}, 2041, 8, 'candelabrum')
shopModule:addBuyableItem({'parcel'}, 2595, 15, 'parcel')
shopModule:addBuyableItem({'letter'}, 2597, 10, 'letter')
shopModule:addBuyableItem({'label'}, 2599, 1, 'label')

-- Sell food
shopModule:addSellableItem({'meat'}, 2666, 2, 'meat')
shopModule:addSellableItem({'ham'}, 2671, 3, 'ham')

npcHandler:addModule(FocusModule:new())
