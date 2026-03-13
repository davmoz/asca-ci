local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local STORAGE_DUNGEON_ACCESS = 51100
local STORAGE_DUNGEON_COOLDOWN = 51101

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am the Dungeon Master. I grant access to weekly {dungeon} challenges for those brave enough to enter.'})

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, 'dungeon') or msgcontains(msg, 'challenge') or msgcontains(msg, 'quest') then
		if player:getLevel() < 30 then
			npcHandler:say('You must be at least level 30 to enter the dungeon challenges. Train more!', cid)
			return true
		end

		local cooldown = player:getStorageValue(STORAGE_DUNGEON_COOLDOWN)
		local currentTime = os.time()
		if cooldown > 0 and currentTime < cooldown then
			local remaining = cooldown - currentTime
			local hours = math.floor(remaining / 3600)
			npcHandler:say('You must wait ' .. hours .. ' more hours before entering the dungeon again.', cid)
			return true
		end

		npcHandler:say('The weekly dungeon challenge awaits! Entry costs 1000 gold and you can enter once per week. Will you enter?', cid)
		npcHandler.topic[cid] = 1
		return true
	end

	if msgcontains(msg, 'yes') and npcHandler.topic[cid] == 1 then
		if player:removeMoney(1000) then
			player:setStorageValue(STORAGE_DUNGEON_ACCESS, 1)
			player:setStorageValue(STORAGE_DUNGEON_COOLDOWN, os.time() + (7 * 24 * 3600))
			player:addExperience(5000, true)
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			npcHandler:say('The dungeon portal opens! You have 7 days until your next entry. Good luck!', cid)
		else
			npcHandler:say('You need 1000 gold to enter the dungeon challenge.', cid)
		end
		npcHandler.topic[cid] = 0
		return true
	elseif msgcontains(msg, 'no') and npcHandler.topic[cid] == 1 then
		npcHandler:say('The dungeon awaits whenever you are ready.', cid)
		npcHandler.topic[cid] = 0
		return true
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
