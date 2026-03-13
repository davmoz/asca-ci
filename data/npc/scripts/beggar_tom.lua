local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local voices = { {text = "Spare some gold for a poor beggar?"} }
npcHandler:addModule(VoiceModule:new(voices))

local STORAGE_BEGGAR_HELPED = 51300

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'Job? Ha! I am a professional beggar. Spare some {gold}?'})

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, 'gold') or msgcontains(msg, 'coin') or msgcontains(msg, 'donate') then
		local helped = player:getStorageValue(STORAGE_BEGGAR_HELPED)
		if helped < 1 then
			npcHandler:say('Would you spare 100 gold for a poor beggar? I will share a secret with you in return!', cid)
			npcHandler.topic[cid] = 1
		else
			npcHandler:say('You already helped me once. Bless your kind heart! I told you my secret already.', cid)
		end
		return true
	end

	if msgcontains(msg, 'yes') and npcHandler.topic[cid] == 1 then
		if player:removeMoney(100) then
			player:setStorageValue(STORAGE_BEGGAR_HELPED, 1)
			npcHandler:say('Bless you! Here is my secret: there is a hidden passage behind the old well near the temple. It leads to a small treasure room! Shh, do not tell anyone!', cid)
		else
			npcHandler:say('You do not even have 100 gold? You are poorer than me!', cid)
		end
		npcHandler.topic[cid] = 0
		return true
	elseif msgcontains(msg, 'no') and npcHandler.topic[cid] == 1 then
		npcHandler:say('Cold-hearted adventurer... maybe next time.', cid)
		npcHandler.topic[cid] = 0
		return true
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
