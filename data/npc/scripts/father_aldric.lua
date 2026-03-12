local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am a priest of the temple. I can grant you divine {blessings} and {heal} your wounds.'})
keywordHandler:addKeyword({'heal'}, StdModule.say, {npcHandler = npcHandler, text = 'I can heal your wounds for free. Simply say {healing} and I will restore your health.'})

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, 'healing') then
		player:addHealth(player:getMaxHealth() - player:getHealth())
		player:addMana(player:getMaxMana() - player:getMana())
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
		npcHandler:say('You are healed, child. May the gods watch over you.', cid)
		return true
	end

	return true
end

local node1 = keywordHandler:addKeyword({'first bless'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to buy the first blessing for 10000 gold?'})
	node1:addChildKeyword({'yes'}, StdModule.bless, {npcHandler = npcHandler, bless = 1, premium = true, cost = 10000})
	node1:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'As you wish, child.'})

local node2 = keywordHandler:addKeyword({'second bless'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to buy the second blessing for 10000 gold?'})
	node2:addChildKeyword({'yes'}, StdModule.bless, {npcHandler = npcHandler, bless = 2, premium = true, cost = 10000})
	node2:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'As you wish, child.'})

local node3 = keywordHandler:addKeyword({'third bless'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to buy the third blessing for 10000 gold?'})
	node3:addChildKeyword({'yes'}, StdModule.bless, {npcHandler = npcHandler, bless = 3, premium = true, cost = 10000})
	node3:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'As you wish, child.'})

local node4 = keywordHandler:addKeyword({'fourth bless'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to buy the fourth blessing for 10000 gold?'})
	node4:addChildKeyword({'yes'}, StdModule.bless, {npcHandler = npcHandler, bless = 4, premium = true, cost = 10000})
	node4:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'As you wish, child.'})

local node5 = keywordHandler:addKeyword({'fifth bless'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to buy the fifth blessing for 10000 gold?'})
	node5:addChildKeyword({'yes'}, StdModule.bless, {npcHandler = npcHandler, bless = 5, premium = true, cost = 10000})
	node5:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'As you wish, child.'})

keywordHandler:addKeyword({'blessings'}, StdModule.say, {npcHandler = npcHandler, text = 'I can bestow five blessings upon you. Say {first bless}, {second bless}, {third bless}, {fourth bless}, or {fifth bless}. Each costs 10000 gold.'})

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
