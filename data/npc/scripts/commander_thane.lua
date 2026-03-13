local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

-- Storage keys for quests
local STORAGE_THANE_MISSION = 50100
local STORAGE_THANE_RATS = 50101
local STORAGE_THANE_WOLVES = 50102

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I command the city guard. I have {missions} for brave adventurers who wish to defend our city.'})

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, 'missions') or msgcontains(msg, 'mission') or msgcontains(msg, 'quest') then
		local missionState = player:getStorageValue(STORAGE_THANE_MISSION)
		if missionState < 1 then
			npcHandler:say('I have a mission for you. Rats have been infesting the sewers beneath the city. Slay 20 rats and return to me. Will you accept this {mission}?', cid)
			npcHandler.topic[cid] = 1
		elseif missionState == 1 then
			npcHandler:say('Have you slain 20 rats yet? The city depends on you!', cid)
			npcHandler.topic[cid] = 2
		elseif missionState == 2 then
			npcHandler:say('I have another mission. Wolves have been attacking travelers on the road. Slay 15 wolves. Will you do this?', cid)
			npcHandler.topic[cid] = 3
		elseif missionState == 3 then
			npcHandler:say('Have you dealt with the wolves yet?', cid)
			npcHandler.topic[cid] = 4
		else
			npcHandler:say('You have completed all my missions. You are a true hero of the city!', cid)
		end
		return true
	end

	if msgcontains(msg, 'yes') then
		if npcHandler.topic[cid] == 1 then
			player:setStorageValue(STORAGE_THANE_MISSION, 1)
			player:setStorageValue(STORAGE_THANE_RATS, 0)
			npcHandler:say('Good! Go into the sewers and slay 20 rats. Return when the deed is done.', cid)
			npcHandler.topic[cid] = 0
		elseif npcHandler.topic[cid] == 2 then
			local ratCount = player:getStorageValue(STORAGE_THANE_RATS)
			if ratCount >= 20 then
				player:setStorageValue(STORAGE_THANE_MISSION, 2)
				player:addExperience(5000, true)
				player:addItem(2152, 5) -- 5 platinum coins
				npcHandler:say('Excellent work! The sewers are cleaner already. Here is your reward: 5 platinum coins and combat experience! Ask about more {missions}.', cid)
			else
				npcHandler:say('You have only slain ' .. math.max(0, ratCount) .. ' of 20 rats. Keep hunting!', cid)
			end
			npcHandler.topic[cid] = 0
		elseif npcHandler.topic[cid] == 3 then
			player:setStorageValue(STORAGE_THANE_MISSION, 3)
			player:setStorageValue(STORAGE_THANE_WOLVES, 0)
			npcHandler:say('Brave soul! Slay 15 wolves near the roads and come back to me.', cid)
			npcHandler.topic[cid] = 0
		elseif npcHandler.topic[cid] == 4 then
			local wolfCount = player:getStorageValue(STORAGE_THANE_WOLVES)
			if wolfCount >= 15 then
				player:setStorageValue(STORAGE_THANE_MISSION, 4)
				player:addExperience(10000, true)
				player:addItem(2152, 10) -- 10 platinum coins
				npcHandler:say('The roads are safe again thanks to you! Here is your reward: 10 platinum coins and valuable experience!', cid)
			else
				npcHandler:say('You have only slain ' .. math.max(0, wolfCount) .. ' of 15 wolves. The roads are still dangerous.', cid)
			end
			npcHandler.topic[cid] = 0
		end
		return true
	elseif msgcontains(msg, 'no') then
		npcHandler:say('Come back when you are ready to serve.', cid)
		npcHandler.topic[cid] = 0
		return true
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
