-- ============================================================================
-- Enchanting Action Script - Phase 2.6
-- ============================================================================
-- Use a Painite Crystal (Small/Medium/Large) on an equipment item to apply
-- a random enchantment. The crystal is consumed regardless of outcome.
--
-- Usage: player uses crystal on a piece of equipment in their inventory.
-- ============================================================================

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- The "item" is the Painite Crystal being used
	-- The "target" is the equipment the player clicked on

	if not target or target:isItem() == false then
		player:sendCancelMessage("You can only enchant equipment items.")
		return true
	end

	-- Verify the crystal is a valid Painite Crystal
	local crystalData = Enchanting.Crystals[item:getId()]
	if not crystalData then
		return false
	end

	-- Target must be in the player's inventory (not on the ground or in a container elsewhere)
	local targetPos = target:getPosition()
	if targetPos.x ~= 65535 then
		player:sendCancelMessage("You can only enchant items in your inventory.")
		return true
	end

	-- Delegate to the enchanting library
	Enchanting.enchant(player, item, target)
	return true
end
