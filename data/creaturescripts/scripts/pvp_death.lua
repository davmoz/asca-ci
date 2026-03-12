-- PvP Death Tracking
function onDeath(player, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
    if killer and killer:isPlayer() then
        if PvPSystem and PvPSystem.onDeath then
            PvPSystem.onDeath(player, killer)
        end
    end
    return true
end
