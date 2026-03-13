local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = {
	{text = "Hear ye! Hear ye! King Aldric seeks brave champions!"},
	{text = "Extra! Extra! New dungeons discovered beneath the city!"},
	{text = "The Hunter's Guild is recruiting! Speak with Artemis!"},
	{text = "Markets are open! Buy and sell at the depot!"},
}
npcHandler:addModule(VoiceModule:new(voices))

local news = {
	"King Aldric has announced new quests for loyal subjects! Visit the throne room.",
	"The Shadow Faction has been spotted near the eastern caves. Be on your guard!",
	"Elder Oakroot seeks nature lovers. Visit the forest commune!",
	"Captain Blackbeard has arrived at the docks. Treasure seekers, take note!",
	"Pyraxis reports increased dragon activity in the eastern mountains.",
	"The arena is open! Gladius welcomes all challengers!",
	"A mysterious wanderer has been seen near the old ruins.",
	"The weekly dungeon challenge resets soon. See Karthus for details!",
}

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am the town crier! I announce the latest {news} and events to all citizens.'})
keywordHandler:addKeyword({'news'}, StdModule.say, {npcHandler = npcHandler, text = news[math.random(#news)]})
keywordHandler:addAliasKeyword({'events'})
keywordHandler:addAliasKeyword({'announcements'})

npcHandler:addModule(FocusModule:new())
