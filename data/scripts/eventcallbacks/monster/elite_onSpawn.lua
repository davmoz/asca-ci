-- Phase 3: Elite Monster Spawn System
-- Gives a small chance for any monster to spawn as an elite variant
-- Elite monsters have boosted stats and can drop legendary items

local ec = EventCallback

ec.onSpawn = function(self, position, startup, artificial)
	-- Don't create elites during server startup to avoid flooding
	if startup then
		return true
	end

	-- Try to make this monster elite
	if LegendaryItems then
		LegendaryItems.tryMakeElite(self)
	end

	return true
end
