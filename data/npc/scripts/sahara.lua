local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Carpet rides to the desert oasis and beyond!"} }
npcHandler:addModule(VoiceModule:new(voices))

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I offer carpet rides across the desert. Ask about {destinations}.'})
keywordHandler:addKeyword({'destinations'}, StdModule.say, {npcHandler = npcHandler, text = 'I can fly you to {Rhyves} for 150 gold. The desert winds are swift!'})
keywordHandler:addAliasKeyword({'travel'})

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, 'rhyves') then
		if npcHandler.topic[cid] ~= 1 then
			npcHandler:say('A carpet ride to Rhyves costs 150 gold. Shall I take you?', cid)
			npcHandler.topic[cid] = 1
			return true
		end
	end

	if msgcontains(msg, 'yes') and npcHandler.topic[cid] == 1 then
		if player:removeMoney(150) then
			npcHandler:say('Up, up and away! Enjoy the flight!', cid)
			npcHandler:releaseFocus(cid)
			player:teleportTo(Position(159, 387, 6))
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		else
			npcHandler:say('You do not have enough gold.', cid)
		end
		npcHandler.topic[cid] = 0
		return true
	elseif msgcontains(msg, 'no') and npcHandler.topic[cid] == 1 then
		npcHandler:say('Perhaps another time, friend.', cid)
		npcHandler.topic[cid] = 0
		return true
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
