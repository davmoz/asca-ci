local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local STORAGE_ARENA_WINS = 51200

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am the Arena Master! I manage the combat {arena} where fighters prove their worth.'})
keywordHandler:addKeyword({'rules'}, StdModule.say, {npcHandler = npcHandler, text = 'The arena rules are simple: fight or die! Each round costs 500 gold. Survive and earn glory and rewards! No killing blows - you will be healed when you fall.'})

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, 'arena') or msgcontains(msg, 'fight') then
		if player:getLevel() < 20 then
			npcHandler:say('You must be at least level 20 to enter the arena!', cid)
			return true
		end
		npcHandler:say('The arena entry fee is 500 gold. You will face combat challenges and earn experience and gold for each round survived. Enter the arena?', cid)
		npcHandler.topic[cid] = 1
		return true
	end

	if msgcontains(msg, 'yes') and npcHandler.topic[cid] == 1 then
		if player:removeMoney(500) then
			local wins = math.max(0, player:getStorageValue(STORAGE_ARENA_WINS))
			player:setStorageValue(STORAGE_ARENA_WINS, wins + 1)
			local expReward = 2000 + (wins * 500)
			player:addExperience(expReward, true)
			player:addHealth(player:getMaxHealth() - player:getHealth())
			player:addMana(player:getMaxMana() - player:getMana())
			player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
			npcHandler:say('FIGHT! You have conquered the arena! ' .. expReward .. ' experience earned! Total arena victories: ' .. (wins + 1) .. '. Come back for more!', cid)
		else
			npcHandler:say('You need 500 gold to enter the arena.', cid)
		end
		npcHandler.topic[cid] = 0
		return true
	elseif msgcontains(msg, 'no') and npcHandler.topic[cid] == 1 then
		npcHandler:say('Coward! Come back when you have the courage to fight!', cid)
		npcHandler.topic[cid] = 0
		return true
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
