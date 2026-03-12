-- Task Kill Tracking
function onKill(player, target)
    if not target:isMonster() then
        return true
    end

    if TaskSystem and TaskSystem.onKill then
        TaskSystem.onKill(player, target:getName())
    end

    -- Also update bestiary
    if Bestiary and Bestiary.onKill then
        Bestiary.onKill(player, target:getName())
    end

    return true
end
