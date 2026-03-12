local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local STORAGE_PIRATE_QUEST = 51000

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am Captain Blackbeard! I sail the seas in search of treasure. I could use a brave hand for an {adventure}!'})

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, 'adventure') or msgcontains(msg, 'quest') or msgcontains(msg, 'treasure') then
		local questState = player:getStorageValue(STORAGE_PIRATE_QUEST)
		if questState < 1 then
			npcHandler:say('Yarr! I know the location of a buried treasure on a remote island. But I need someone to retrieve it. The island is crawling with monsters! Will you go for me? We split the loot fifty-fifty!', cid)
			npcHandler.topic[cid] = 1
		elseif questState == 1 then
			npcHandler:say('Did ye find the treasure? Bring me 10 gold coins as my share!', cid)
			npcHandler.topic[cid] = 2
		elseif questState == 2 then
			npcHandler:say('I have heard rumors of an even greater treasure - the Sunken Crown! It lies at the bottom of the ocean in a shipwreck. Will you dive for it?', cid)
			npcHandler.topic[cid] = 3
		elseif questState == 3 then
			npcHandler:say('Have ye found the Sunken Crown?', cid)
			npcHandler.topic[cid] = 4
		else
			npcHandler:say('Yarr! You are the bravest treasure hunter I have ever met!', cid)
		end
		return true
	end

	if msgcontains(msg, 'yes') then
		if npcHandler.topic[cid] == 1 then
			player:setStorageValue(STORAGE_PIRATE_QUEST, 1)
			npcHandler:say('Yarr harr! Head east across the sea. The treasure is buried on the beach of the island. Good luck, matey!', cid)
		elseif npcHandler.topic[cid] == 2 then
			if player:removeMoney(10) then
				player:setStorageValue(STORAGE_PIRATE_QUEST, 2)
				player:addExperience(15000, true)
				player:addItem(2152, 20) -- 20 platinum coins
				npcHandler:say('Yarr! Fair and square! Here be your half of the treasure: 20 platinum coins! Ask about more {adventure} when ready!', cid)
			else
				npcHandler:say('Ye do not even have 10 gold coins? What kind of treasure hunter are ye?!', cid)
			end
		elseif npcHandler.topic[cid] == 3 then
			player:setStorageValue(STORAGE_PIRATE_QUEST, 3)
			npcHandler:say('Dive into the ocean west of the harbor. The shipwreck lies deep below. Bring the Sunken Crown to me!', cid)
		elseif npcHandler.topic[cid] == 4 then
			if player:getLevel() >= 50 then
				player:setStorageValue(STORAGE_PIRATE_QUEST, 4)
				player:addExperience(40000, true)
				player:addItem(2498, 1) -- royal helmet
				npcHandler:say('YARR HARR HARR! The Sunken Crown! It be even more magnificent than I imagined! Take this royal helmet as your reward, matey!', cid)
			else
				npcHandler:say('Ye do not look strong enough to have survived that dive. Come back at level 50!', cid)
			end
		end
		npcHandler.topic[cid] = 0
		return true
	elseif msgcontains(msg, 'no') then
		npcHandler:say('Yarr... landlubber!', cid)
		npcHandler.topic[cid] = 0
		return true
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
