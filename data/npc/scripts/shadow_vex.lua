local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local STORAGE_SHADOW_QUEST = 50500
local STORAGE_SHADOW_FACTION = 50501

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am the Shadow Master. I lead the {Shadow Faction}. We deal in secrets, stealth, and power.'})

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, 'shadows') or msgcontains(msg, 'shadow faction') or msgcontains(msg, 'faction') then
		local factionState = player:getStorageValue(STORAGE_SHADOW_FACTION)
		if factionState < 1 then
			npcHandler:say('The Shadow Faction operates in darkness. We value cunning, stealth, and ambition. Join us and gain access to forbidden knowledge and powerful equipment. Do you wish to walk in the shadows?', cid)
			npcHandler.topic[cid] = 1
		else
			npcHandler:say('You already walk in the shadows. Ask about your next {task}.', cid)
		end
		return true
	end

	if msgcontains(msg, 'task') or msgcontains(msg, 'quest') or msgcontains(msg, 'mission') then
		local questState = player:getStorageValue(STORAGE_SHADOW_QUEST)
		local factionState = player:getStorageValue(STORAGE_SHADOW_FACTION)
		if factionState < 1 then
			npcHandler:say('You must first join the {Shadow Faction}.', cid)
			return true
		end

		if questState < 1 then
			npcHandler:say('Steal a document from the royal library. It contains information we need. Bring it to me. Will you do this?', cid)
			npcHandler.topic[cid] = 2
		elseif questState == 1 then
			npcHandler:say('Have you obtained the document?', cid)
			npcHandler.topic[cid] = 3
		elseif questState == 2 then
			npcHandler:say('A rival assassin threatens our operations. Eliminate this threat by exploring the catacombs. Will you?', cid)
			npcHandler.topic[cid] = 4
		elseif questState == 3 then
			npcHandler:say('Have you dealt with the rival?', cid)
			npcHandler.topic[cid] = 5
		else
			npcHandler:say('You have proven yourself a true shadow agent. The darkness embraces you.', cid)
		end
		return true
	end

	if msgcontains(msg, 'yes') then
		if npcHandler.topic[cid] == 1 then
			player:setStorageValue(STORAGE_SHADOW_FACTION, 1)
			npcHandler:say('Welcome to the shadows, ' .. player:getName() .. '. Your first {task} awaits.', cid)
		elseif npcHandler.topic[cid] == 2 then
			player:setStorageValue(STORAGE_SHADOW_QUEST, 1)
			npcHandler:say('Find the document in the library. Be discreet. Return when you have it.', cid)
		elseif npcHandler.topic[cid] == 3 then
			if player:getItemCount(2175) >= 1 then
				player:removeItem(2175, 1)
				player:setStorageValue(STORAGE_SHADOW_QUEST, 2)
				player:addExperience(10000, true)
				player:addItem(2152, 8)
				npcHandler:say('Excellent work. The shadows reward their own. Here is your payment. Ask about your next {task}.', cid)
			else
				npcHandler:say('You do not have the document. Find a book in the library area and bring it to me.', cid)
			end
		elseif npcHandler.topic[cid] == 4 then
			player:setStorageValue(STORAGE_SHADOW_QUEST, 3)
			npcHandler:say('The rival hides in the catacombs beneath the city. Deal with this threat.', cid)
		elseif npcHandler.topic[cid] == 5 then
			if player:getLevel() >= 40 then
				player:setStorageValue(STORAGE_SHADOW_QUEST, 4)
				player:addExperience(30000, true)
				player:addItem(2165, 1) -- stealth ring
				npcHandler:say('The rival is no more. Take this stealth ring as a token of the shadows\' gratitude.', cid)
			else
				npcHandler:say('You are not yet strong enough. Return at level 40 or higher.', cid)
			end
		end
		npcHandler.topic[cid] = 0
		return true
	elseif msgcontains(msg, 'no') then
		npcHandler:say('The shadows wait for no one... but perhaps they will wait for you.', cid)
		npcHandler.topic[cid] = 0
		return true
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
