-- Achievement Check on Level Advance
function onAdvance(player, skill, oldLevel, newLevel)
    if AchievementSystem then
        if skill == SKILL__LEVEL then
            AchievementSystem.checkLevelAchievements(player)
        end
        if AchievementSystem.checkSkillAchievements then
            AchievementSystem.checkSkillAchievements(player, skill, newLevel)
        end
    end
    return true
end
