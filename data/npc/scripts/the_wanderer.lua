local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local STORAGE_WANDERER_QUEST = 50700
local STORAGE_WANDERER_RIDDLE = 50701

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I wander between worlds. I know many {secrets} hidden from mortal eyes.'})

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, 'secret') or msgcontains(msg, 'quest') then
		local questState = player:getStorageValue(STORAGE_WANDERER_QUEST)
		if questState < 1 then
			npcHandler:say('I will share a secret with you, but first you must answer a {riddle}. Are you ready?', cid)
			npcHandler.topic[cid] = 1
		elseif questState == 1 then
			npcHandler:say('Hmm... you answered the riddle. Now bring me a {rare item} to prove your dedication. I seek a magic plate armor. Do you have one?', cid)
			npcHandler.topic[cid] = 3
		elseif questState == 2 then
			npcHandler:say('You have proven yourself worthy. Seek the hidden passage behind the waterfall north of the city. An ancient treasure awaits. This is my final gift to you.', cid)
			player:setStorageValue(STORAGE_WANDERER_QUEST, 3)
		else
			npcHandler:say('We have no more business, traveler. Walk your own path now.', cid)
		end
		return true
	end

	if msgcontains(msg, 'riddle') and npcHandler.topic[cid] == 0 then
		npcHandler:say('I will share a secret with you, but first answer my riddle. Are you ready?', cid)
		npcHandler.topic[cid] = 1
		return true
	end

	if msgcontains(msg, 'yes') then
		if npcHandler.topic[cid] == 1 then
			npcHandler:say('Here is my riddle: I have cities, but no houses live there. I have mountains, but no trees grow there. I have water, but no fish swim there. What am I?', cid)
			npcHandler.topic[cid] = 2
			return true
		elseif npcHandler.topic[cid] == 3 then
			if player:getItemCount(2472) >= 1 then
				player:removeItem(2472, 1)
				player:setStorageValue(STORAGE_WANDERER_QUEST, 2)
				player:addExperience(50000, true)
				npcHandler:say('The magic plate armor! A worthy offering. In return, I grant you 50000 experience and knowledge of a hidden treasure. Ask me about the {secret} once more.', cid)
			else
				npcHandler:say('You do not have a magic plate armor. Return when you do.', cid)
			end
			npcHandler.topic[cid] = 0
			return true
		end
	elseif msgcontains(msg, 'no') then
		npcHandler:say('Then we have nothing to discuss... for now.', cid)
		npcHandler.topic[cid] = 0
		return true
	end

	if npcHandler.topic[cid] == 2 then
		if msgcontains(msg, 'map') then
			player:setStorageValue(STORAGE_WANDERER_QUEST, 1)
			npcHandler:say('Correct! A map has cities without houses, mountains without trees, and water without fish. You are clever indeed. Now, I need you to prove your dedication. Ask me about the {secret} again.', cid)
			npcHandler.topic[cid] = 0
		else
			npcHandler:say('Wrong answer. Think carefully. I have cities but no houses, mountains but no trees, water but no fish. What am I?', cid)
		end
		return true
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
