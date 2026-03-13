local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local STORAGE_ROYAL_QUEST = 50400
local STORAGE_ROYAL_FACTION = 50401

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am King Aldric, sovereign of this realm. I lead the {Royal Faction} and seek champions to defend our kingdom.'})

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, 'crown') or msgcontains(msg, 'royal faction') or msgcontains(msg, 'faction') then
		local factionState = player:getStorageValue(STORAGE_ROYAL_FACTION)
		if factionState < 1 then
			npcHandler:say('The Royal Faction stands for order, justice, and protection of the innocent. Join us and you will gain access to royal equipment and exclusive quests. Will you pledge loyalty to the crown?', cid)
			npcHandler.topic[cid] = 1
		else
			npcHandler:say('You are already a member of the Royal Faction. Ask about the next {quest} available to you.', cid)
		end
		return true
	end

	if msgcontains(msg, 'quest') or msgcontains(msg, 'mission') then
		local questState = player:getStorageValue(STORAGE_ROYAL_QUEST)
		local factionState = player:getStorageValue(STORAGE_ROYAL_FACTION)
		if factionState < 1 then
			npcHandler:say('You must first join the {Royal Faction} before I give you a quest.', cid)
			return true
		end

		if questState < 1 then
			npcHandler:say('A bandit camp has been established south of the city. Drive them out by slaying their leader. Will you undertake this quest?', cid)
			npcHandler.topic[cid] = 2
		elseif questState == 1 then
			npcHandler:say('Have you dealt with the bandit leader? Bring me proof of your deed.', cid)
			npcHandler.topic[cid] = 3
		elseif questState == 2 then
			npcHandler:say('An ancient artifact has been stolen from the royal treasury. Recover it from the thieves hideout. Will you accept?', cid)
			npcHandler.topic[cid] = 4
		elseif questState == 3 then
			npcHandler:say('Have you recovered the royal artifact?', cid)
			npcHandler.topic[cid] = 5
		else
			npcHandler:say('You have proven your loyalty beyond measure. You are a true champion of the crown!', cid)
		end
		return true
	end

	if msgcontains(msg, 'yes') then
		if npcHandler.topic[cid] == 1 then
			player:setStorageValue(STORAGE_ROYAL_FACTION, 1)
			npcHandler:say('Welcome to the Royal Faction, ' .. player:getName() .. '! Long live the crown! Ask me about available {quests}.', cid)
		elseif npcHandler.topic[cid] == 2 then
			player:setStorageValue(STORAGE_ROYAL_QUEST, 1)
			npcHandler:say('Brave soul! Go south and find the bandit camp. Slay their leader and return to me.', cid)
		elseif npcHandler.topic[cid] == 3 then
			if player:getLevel() >= 20 then
				player:setStorageValue(STORAGE_ROYAL_QUEST, 2)
				player:addExperience(10000, true)
				player:addItem(2152, 10)
				npcHandler:say('The realm thanks you! Here is your reward. Ask about the next {quest} when ready.', cid)
			else
				npcHandler:say('You must prove your worth. Reach level 20 and return.', cid)
			end
		elseif npcHandler.topic[cid] == 4 then
			player:setStorageValue(STORAGE_ROYAL_QUEST, 3)
			npcHandler:say('Find the thieves hideout and recover the royal artifact. It is said to be hidden in the eastern caves.', cid)
		elseif npcHandler.topic[cid] == 5 then
			if player:getLevel() >= 40 then
				player:setStorageValue(STORAGE_ROYAL_QUEST, 4)
				player:addExperience(30000, true)
				player:addItem(2160, 2) -- 2 crystal coins
				npcHandler:say('The artifact is returned! You have earned the highest honors of the crown. Here is a substantial reward!', cid)
			else
				npcHandler:say('You need to be stronger. Return when you are at least level 40.', cid)
			end
		end
		npcHandler.topic[cid] = 0
		return true
	elseif msgcontains(msg, 'no') then
		npcHandler:say('Very well. The crown is patient.', cid)
		npcHandler.topic[cid] = 0
		return true
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
