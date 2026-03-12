local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Gems, rings, and amulets! Only the finest quality!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am a jeweler. I buy and sell {gems}, {rings}, and {amulets}.'})
keywordHandler:addKeyword({'gems'}, StdModule.say, {npcHandler = npcHandler, text = 'I buy raw gems found in mines and dungeons. Bring me your small diamonds, rubies, emeralds, and sapphires!'})
keywordHandler:addKeyword({'jewelry'}, StdModule.say, {npcHandler = npcHandler, text = 'I sell enchanted rings and amulets with various magical properties.'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Ask for a {trade} to see my collection.'})
keywordHandler:addAliasKeyword({'wares'})

-- Buy gems from players
shopModule:addSellableItem({'small diamond'}, 2145, 300, 'small diamond')
shopModule:addSellableItem({'small ruby'}, 2147, 250, 'small ruby')
shopModule:addSellableItem({'small emerald'}, 2149, 250, 'small emerald')
shopModule:addSellableItem({'small sapphire'}, 2146, 250, 'small sapphire')
shopModule:addSellableItem({'small amethyst'}, 2150, 200, 'small amethyst')
shopModule:addSellableItem({'gold nugget'}, 2157, 850, 'gold nugget')
shopModule:addSellableItem({'wedding ring'}, 2121, 100, 'wedding ring')

-- Sell rings and amulets
shopModule:addBuyableItem({'ring of healing'}, 2214, 2000, 'ring of healing')
shopModule:addBuyableItem({'life ring'}, 2205, 900, 'life ring')
shopModule:addBuyableItem({'energy ring'}, 2167, 2000, 'energy ring')
shopModule:addBuyableItem({'stealth ring'}, 2165, 5000, 'stealth ring')
shopModule:addBuyableItem({'power ring'}, 2166, 100, 'power ring')
shopModule:addBuyableItem({'sword ring'}, 2207, 100, 'sword ring')
shopModule:addBuyableItem({'axe ring'}, 2208, 100, 'axe ring')
shopModule:addBuyableItem({'club ring'}, 2209, 100, 'club ring')
shopModule:addBuyableItem({'protection amulet'}, 2200, 700, 'protection amulet')
shopModule:addBuyableItem({'bronze amulet'}, 2172, 100, 'bronze amulet')
shopModule:addBuyableItem({'dragon necklace'}, 2201, 1000, 'dragon necklace')
shopModule:addBuyableItem({'elven amulet'}, 2198, 500, 'elven amulet')
shopModule:addBuyableItem({'garlic necklace'}, 2199, 50, 'garlic necklace')

npcHandler:addModule(FocusModule:new())
