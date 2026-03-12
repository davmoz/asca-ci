local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local STORAGE_DRAGON_QUEST = 50900

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I study dragons. I know their weaknesses and strengths. If you are brave enough, I have a {quest} involving these magnificent beasts.'})

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, 'dragons') or msgcontains(msg, 'quest') then
		local questState = player:getStorageValue(STORAGE_DRAGON_QUEST)
		if questState < 1 then
			if player:getLevel() >= 45 then
				npcHandler:say('A dragon has made its lair in the eastern mountains, threatening our trade routes. Slay it and bring me proof. You must be brave! Will you accept this quest?', cid)
				npcHandler.topic[cid] = 1
			else
				npcHandler:say('You must be at least level 45 to face dragons. Train more and return.', cid)
			end
		elseif questState == 1 then
			npcHandler:say('Have you slain the dragon? I need proof of your victory.', cid)
			npcHandler.topic[cid] = 2
		elseif questState == 2 then
			if player:getLevel() >= 80 then
				npcHandler:say('A Dragon Lord has emerged from the deep caverns. This is far more dangerous. Will you face it?', cid)
				npcHandler.topic[cid] = 3
			else
				npcHandler:say('You have done well with the dragon, but the Dragon Lord requires level 80. Train more!', cid)
			end
		elseif questState == 3 then
			npcHandler:say('Have you defeated the Dragon Lord?', cid)
			npcHandler.topic[cid] = 4
		else
			npcHandler:say('You are a true dragon slayer! Songs will be sung of your bravery!', cid)
		end
		return true
	end

	if msgcontains(msg, 'yes') then
		if npcHandler.topic[cid] == 1 then
			player:setStorageValue(STORAGE_DRAGON_QUEST, 1)
			npcHandler:say('Go to the eastern mountains and slay the dragon! Return with proof of your deed.', cid)
		elseif npcHandler.topic[cid] == 2 then
			if player:getLevel() >= 50 then
				player:setStorageValue(STORAGE_DRAGON_QUEST, 2)
				player:addExperience(25000, true)
				player:addItem(2392, 1) -- fire sword
				npcHandler:say('Incredible! You have slain the dragon! Take this fire sword as your reward!', cid)
			else
				npcHandler:say('Hmm, you do not seem battle-hardened enough. Reach level 50 and I will believe you.', cid)
			end
		elseif npcHandler.topic[cid] == 3 then
			player:setStorageValue(STORAGE_DRAGON_QUEST, 3)
			npcHandler:say('The Dragon Lord dwells in the deepest part of the mountain caverns. Be prepared for a deadly fight!', cid)
		elseif npcHandler.topic[cid] == 4 then
			if player:getLevel() >= 85 then
				player:setStorageValue(STORAGE_DRAGON_QUEST, 4)
				player:addExperience(80000, true)
				player:addItem(2472, 1) -- magic plate armor
				npcHandler:say('LEGENDARY! You defeated a Dragon Lord! Take this magic plate armor as your reward. You are a true dragon slayer!', cid)
			else
				npcHandler:say('You need to be at least level 85 for me to believe you faced a Dragon Lord.', cid)
			end
		end
		npcHandler.topic[cid] = 0
		return true
	elseif msgcontains(msg, 'no') then
		npcHandler:say('The dragons wait for no one. Come back when you are ready.', cid)
		npcHandler.topic[cid] = 0
		return true
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
