local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local STORAGE_TASK = 50300
local STORAGE_TASK_COUNT = 50301
local STORAGE_TASK_MONSTER = 50302

local tasks = {
	{name = "rotworms", display = "Rotworms", count = 30, expReward = 8000, goldReward = 2000, minLevel = 15},
	{name = "cyclops", display = "Cyclopes", count = 25, expReward = 15000, goldReward = 5000, minLevel = 30},
	{name = "dragons", display = "Dragons", count = 20, expReward = 40000, goldReward = 10000, minLevel = 60},
	{name = "dragon lords", display = "Dragon Lords", count = 15, expReward = 80000, goldReward = 20000, minLevel = 80},
	{name = "demons", display = "Demons", count = 10, expReward = 150000, goldReward = 50000, minLevel = 130},
}

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am the Hunter\'s Guild Master. I assign hunting {tasks} to brave adventurers.'})

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, 'tasks') or msgcontains(msg, 'task') or msgcontains(msg, 'quest') then
		local taskState = player:getStorageValue(STORAGE_TASK)
		if taskState < 1 or taskState > #tasks then
			-- Assign new task
			local level = player:getLevel()
			local availableTasks = {}
			for i, task in ipairs(tasks) do
				if level >= task.minLevel then
					table.insert(availableTasks, i)
				end
			end
			if #availableTasks == 0 then
				npcHandler:say('You are not strong enough for any tasks yet. Come back when you are at least level 15.', cid)
				return true
			end
			local taskId = availableTasks[math.random(#availableTasks)]
			npcHandler:say('I have a task for you: Slay ' .. tasks[taskId].count .. ' ' .. tasks[taskId].display .. '. The reward is ' .. tasks[taskId].expReward .. ' experience and ' .. tasks[taskId].goldReward .. ' gold. Do you accept?', cid)
			npcHandler.topic[cid] = taskId
			return true
		else
			-- Check progress
			local task = tasks[taskState]
			local killCount = math.max(0, player:getStorageValue(STORAGE_TASK_COUNT))
			if killCount >= task.count then
				player:addExperience(task.expReward, true)
				player:addMoney(task.goldReward)
				player:setStorageValue(STORAGE_TASK, 0)
				player:setStorageValue(STORAGE_TASK_COUNT, 0)
				npcHandler:say('Outstanding! You have completed the ' .. task.display .. ' task! Here is your reward: ' .. task.expReward .. ' experience and ' .. task.goldReward .. ' gold. Ask for more {tasks} when ready!', cid)
			else
				npcHandler:say('You have slain ' .. killCount .. ' of ' .. task.count .. ' ' .. task.display .. '. Keep hunting!', cid)
			end
			return true
		end
	end

	if msgcontains(msg, 'yes') and npcHandler.topic[cid] and npcHandler.topic[cid] > 0 then
		local taskId = npcHandler.topic[cid]
		player:setStorageValue(STORAGE_TASK, taskId)
		player:setStorageValue(STORAGE_TASK_COUNT, 0)
		player:setStorageValue(STORAGE_TASK_MONSTER, taskId)
		npcHandler:say('Good hunting! Slay ' .. tasks[taskId].count .. ' ' .. tasks[taskId].display .. ' and return to me for your reward.', cid)
		npcHandler.topic[cid] = 0
		return true
	elseif msgcontains(msg, 'no') and npcHandler.topic[cid] and npcHandler.topic[cid] > 0 then
		npcHandler:say('Come back when you feel more courageous.', cid)
		npcHandler.topic[cid] = 0
		return true
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
