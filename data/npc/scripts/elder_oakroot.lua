local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local STORAGE_NATURE_QUEST = 50600
local STORAGE_NATURE_FACTION = 50601

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am Elder Oakroot, guardian of the ancient forest. I lead the {Nature Faction} and protect the balance of the wild.'})

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, 'nature') or msgcontains(msg, 'nature faction') or msgcontains(msg, 'faction') then
		local factionState = player:getStorageValue(STORAGE_NATURE_FACTION)
		if factionState < 1 then
			npcHandler:say('The Nature Faction protects the forests, rivers, and creatures of the wild. We seek those who respect the natural order. Will you join the guardians of nature?', cid)
			npcHandler.topic[cid] = 1
		else
			npcHandler:say('You are one with nature. Ask about your next {quest}.', cid)
		end
		return true
	end

	if msgcontains(msg, 'quest') or msgcontains(msg, 'mission') then
		local questState = player:getStorageValue(STORAGE_NATURE_QUEST)
		local factionState = player:getStorageValue(STORAGE_NATURE_FACTION)
		if factionState < 1 then
			npcHandler:say('Join the {Nature Faction} first, young one.', cid)
			return true
		end

		if questState < 1 then
			npcHandler:say('Poachers have been killing the forest creatures. Drive them away by restoring the forest shrine. Bring me 5 brown mushrooms as an offering. Will you help?', cid)
			npcHandler.topic[cid] = 2
		elseif questState == 1 then
			npcHandler:say('Have you brought 5 brown mushrooms for the forest shrine?', cid)
			npcHandler.topic[cid] = 3
		elseif questState == 2 then
			npcHandler:say('A corrupted treant is spreading blight in the ancient grove. You must find and purify it. Will you take on this task?', cid)
			npcHandler.topic[cid] = 4
		elseif questState == 3 then
			npcHandler:say('Have you purified the corrupted treant?', cid)
			npcHandler.topic[cid] = 5
		else
			npcHandler:say('The forest sings your name, champion. You have restored balance to nature!', cid)
		end
		return true
	end

	if msgcontains(msg, 'yes') then
		if npcHandler.topic[cid] == 1 then
			player:setStorageValue(STORAGE_NATURE_FACTION, 1)
			npcHandler:say('The trees welcome you, ' .. player:getName() .. '. Ask about your first {quest}.', cid)
		elseif npcHandler.topic[cid] == 2 then
			player:setStorageValue(STORAGE_NATURE_QUEST, 1)
			npcHandler:say('Gather 5 brown mushrooms from the forest and bring them to me.', cid)
		elseif npcHandler.topic[cid] == 3 then
			if player:getItemCount(2789) >= 5 then
				player:removeItem(2789, 5)
				player:setStorageValue(STORAGE_NATURE_QUEST, 2)
				player:addExperience(8000, true)
				player:addItem(2152, 5)
				npcHandler:say('The mushrooms nourish the shrine. Nature is pleased! Here is your reward. Ask about more {quests}.', cid)
			else
				npcHandler:say('You need 5 brown mushrooms. Search the forest floor.', cid)
			end
		elseif npcHandler.topic[cid] == 4 then
			player:setStorageValue(STORAGE_NATURE_QUEST, 3)
			npcHandler:say('The corrupted treant lurks in the ancient grove to the north. Purify it with courage and strength!', cid)
		elseif npcHandler.topic[cid] == 5 then
			if player:getLevel() >= 35 then
				player:setStorageValue(STORAGE_NATURE_QUEST, 4)
				player:addExperience(25000, true)
				player:addItem(2181, 1) -- terra rod
				npcHandler:say('The blight is cleansed! Take this terra rod as a gift from the forest itself!', cid)
			else
				npcHandler:say('You must be stronger. The corrupted treant requires at least level 35 to face.', cid)
			end
		end
		npcHandler.topic[cid] = 0
		return true
	elseif msgcontains(msg, 'no') then
		npcHandler:say('The forest is patient. Return when you are ready.', cid)
		npcHandler.topic[cid] = 0
		return true
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
