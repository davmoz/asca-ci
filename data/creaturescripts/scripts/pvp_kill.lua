-- PvP Kill/Death Tracking
function onKill(player, target)
    if not target:isPlayer() then
        return true
    end

    if PvPSystem and PvPSystem.onKill then
        PvPSystem.onKill(player, target)
    end

    return true
end
