local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local STORAGE_CATACOMBS_ACCESS = 50800

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I was once a great scholar. Now I guard the entrance to the ancient {catacombs}. Prove your worth and I shall grant you access.'})

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, 'catacombs') or msgcontains(msg, 'access') or msgcontains(msg, 'quest') then
		local accessState = player:getStorageValue(STORAGE_CATACOMBS_ACCESS)
		if accessState >= 1 then
			npcHandler:say('You already have access to the catacombs. Enter and face what lies below!', cid)
		else
			if player:getLevel() >= 50 then
				npcHandler:say('To gain access to the catacombs, you must prove you are at least level 50 and pay a tribute of 5000 gold. You meet the level requirement. Will you pay the tribute?', cid)
				npcHandler.topic[cid] = 1
			else
				npcHandler:say('You must be at least level 50 to enter the catacombs. Return when you are stronger.', cid)
			end
		end
		return true
	end

	if msgcontains(msg, 'yes') and npcHandler.topic[cid] == 1 then
		if player:removeMoney(5000) then
			player:setStorageValue(STORAGE_CATACOMBS_ACCESS, 1)
			player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
			npcHandler:say('The spirits accept your tribute. You may now enter the catacombs. Beware what lurks in the darkness!', cid)
		else
			npcHandler:say('You do not have enough gold. Come back with 5000 gold coins.', cid)
		end
		npcHandler.topic[cid] = 0
		return true
	elseif msgcontains(msg, 'no') and npcHandler.topic[cid] == 1 then
		npcHandler:say('The dead can wait... but can you?', cid)
		npcHandler.topic[cid] = 0
		return true
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
