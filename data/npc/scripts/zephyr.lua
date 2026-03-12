local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Runes and arcane reagents! Fuel your magic here!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I deal in {runes} and magical {reagents}. The arcane is my trade.'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Just ask me for a {trade} to see my magical wares.'})
keywordHandler:addAliasKeyword({'wares'})

-- Runes
shopModule:addBuyableItem({'intense healing'}, 2265, 95, 1, 'intense healing rune')
shopModule:addBuyableItem({'ultimate healing'}, 2273, 175, 1, 'ultimate healing rune')
shopModule:addBuyableItem({'magic wall'}, 2293, 350, 3, 'magic wall rune')
shopModule:addBuyableItem({'destroy field'}, 2261, 45, 3, 'destroy field rune')
shopModule:addBuyableItem({'light magic missile'}, 2287, 40, 10, 'light magic missile rune')
shopModule:addBuyableItem({'heavy magic missile'}, 2311, 120, 10, 'heavy magic missile rune')
shopModule:addBuyableItem({'great fireball'}, 2304, 180, 4, 'great fireball rune')
shopModule:addBuyableItem({'explosion'}, 2313, 250, 6, 'explosion rune')
shopModule:addBuyableItem({'sudden death'}, 2268, 350, 3, 'sudden death rune')
shopModule:addBuyableItem({'paralyze'}, 2278, 700, 1, 'paralyze rune')
shopModule:addBuyableItem({'animate dead'}, 2316, 375, 1, 'animate dead rune')
shopModule:addBuyableItem({'convince creature'}, 2290, 80, 1, 'convince creature rune')
shopModule:addBuyableItem({'chameleon'}, 2291, 210, 1, 'chameleon rune')
shopModule:addBuyableItem({'disintegrate'}, 2310, 80, 3, 'disintegrate rune')
shopModule:addBuyableItem({'fire field'}, 2301, 28, 3, 'fire field rune')
shopModule:addBuyableItem({'energy field'}, 2277, 38, 3, 'energy field rune')
shopModule:addBuyableItem({'poison field'}, 2285, 21, 3, 'poison field rune')
shopModule:addBuyableItem({'fire wall'}, 2303, 61, 4, 'fire wall rune')
shopModule:addBuyableItem({'energy wall'}, 2279, 85, 4, 'energy wall rune')
shopModule:addBuyableItem({'poison wall'}, 2289, 52, 4, 'poison wall rune')
shopModule:addBuyableItem({'fire bomb'}, 2305, 147, 2, 'fire bomb rune')
shopModule:addBuyableItem({'soulfire'}, 2308, 46, 3, 'soulfire rune')
shopModule:addBuyableItem({'energy bomb'}, 2262, 203, 2, 'energy bomb rune')

-- Reagents / misc
shopModule:addBuyableItem({'blank rune'}, 2260, 10, 'blank rune')
shopModule:addBuyableItem({'spellbook'}, 2175, 150, 'spellbook')

npcHandler:addModule(FocusModule:new())
