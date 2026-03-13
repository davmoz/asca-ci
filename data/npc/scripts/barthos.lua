local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Cold drinks and warm meals! Rest your weary bones at my inn!"} }
npcHandler:addModule(VoiceModule:new(voices))

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am the innkeeper. I sell {food} and drinks, and I hear many {rumors} from travelers.'})

local rumors = {
	"They say a dragon was spotted in the mountains to the east. Speak with Pyraxis if you dare!",
	"I heard the Shadow Master has been recruiting. Dark times ahead, friend.",
	"Old Pete down by the docks says the fishing has been extraordinary lately.",
	"Commander Thane is looking for adventurers to clear the sewers. Easy gold!",
	"A mysterious wanderer has been seen near the old ruins. Wonder what he is after...",
	"The Elder Oakroot in the forest commune is seeking nature lovers for some task.",
	"Blackbeard the pirate has been spotted at the harbor. Watch your purse!",
	"The arena master Gladius is looking for fighters. Big prizes, they say!",
	"Rumor has it the Spectral Scholar guards the entrance to the ancient catacombs.",
	"King Aldric seeks champions. The royal guard is hiring!"
}

keywordHandler:addKeyword({'rumors'}, StdModule.say, {npcHandler = npcHandler, text = rumors[math.random(#rumors)]})
keywordHandler:addAliasKeyword({'rumor'})
keywordHandler:addAliasKeyword({'news'})

keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'Ask for a {trade} to see my food and drink.'})
keywordHandler:addAliasKeyword({'wares'})

shopModule:addBuyableItem({'meat'}, 2666, 5, 'meat')
shopModule:addBuyableItem({'ham'}, 2671, 8, 'ham')
shopModule:addBuyableItem({'bread'}, 2689, 3, 'bread')
shopModule:addBuyableItem({'cheese'}, 2696, 6, 'cheese')
shopModule:addBuyableItem({'apple'}, 2674, 3, 'apple')
shopModule:addBuyableItem({'brown mushroom'}, 2789, 10, 'brown mushroom')
shopModule:addBuyableItem({'cookie'}, 2687, 2, 'cookie')
shopModule:addBuyableItem({'fish'}, 2667, 4, 'fish')

npcHandler:addModule(FocusModule:new())
