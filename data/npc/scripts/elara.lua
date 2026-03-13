local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local STORAGE_BOOK_QUEST = 50200

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am the city librarian. I keep records of our history and {lore}. I also have a {quest} for the curious.'})
keywordHandler:addKeyword({'lore'}, StdModule.say, {npcHandler = npcHandler, text = 'Our world is ancient. The {Forgotten King} once ruled these lands. The {Oracle} on the island guides new adventurers. Dark forces stir in the {dungeons} below.'})
keywordHandler:addKeyword({'forgotten king'}, StdModule.say, {npcHandler = npcHandler, text = 'The Forgotten King was once a great ruler. His spirit lingers still, granting promotions to those who seek him out.'})
keywordHandler:addKeyword({'oracle'}, StdModule.say, {npcHandler = npcHandler, text = 'The Oracle resides on the starter island. It guides young adventurers in choosing their vocation and destiny.'})
keywordHandler:addKeyword({'dungeons'}, StdModule.say, {npcHandler = npcHandler, text = 'Beneath the city and in the surrounding wilds lie many dungeons. Speak with {Commander Thane} or {Karthus} for dungeon access.'})

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, 'quest') or msgcontains(msg, 'book') then
		local questState = player:getStorageValue(STORAGE_BOOK_QUEST)
		if questState < 1 then
			npcHandler:say('A rare book of ancient knowledge was lost in the wilderness. If you find it and bring it back, I will reward you handsomely. Will you search for it?', cid)
			npcHandler.topic[cid] = 1
		elseif questState == 1 then
			if player:getItemCount(2175) >= 1 then
				npcHandler:say('You found a book of knowledge! Let me examine it... Yes! This is the lost tome! Here is your reward.', cid)
				player:removeItem(2175, 1)
				player:addExperience(3000, true)
				player:addItem(2152, 3) -- 3 platinum
				player:setStorageValue(STORAGE_BOOK_QUEST, 2)
			else
				npcHandler:say('You have not yet found the lost book. Search the dungeons and wilderness for it.', cid)
			end
		else
			npcHandler:say('You have already completed my book quest. Thank you for recovering that knowledge!', cid)
		end
		return true
	end

	if msgcontains(msg, 'yes') and npcHandler.topic[cid] == 1 then
		player:setStorageValue(STORAGE_BOOK_QUEST, 1)
		npcHandler:say('Wonderful! The book was last seen somewhere in the northern wilderness. Good luck, |PLAYERNAME|!', cid)
		npcHandler.topic[cid] = 0
		return true
	elseif msgcontains(msg, 'no') and npcHandler.topic[cid] == 1 then
		npcHandler:say('Perhaps another time then.', cid)
		npcHandler.topic[cid] = 0
		return true
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
