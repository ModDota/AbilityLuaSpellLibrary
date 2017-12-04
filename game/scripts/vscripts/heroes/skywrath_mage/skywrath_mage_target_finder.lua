-- Helper function that finds a target to fire a secondary spell at. Relevant for all Skywrath's spells
-- that has a unit target (or chooses a specific target)
function SkywrathSpellsTargetFinder(caster, target, radius)    

    -- Find heroes around the target
    local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
                                      target:GetAbsOrigin(),
                                      nil,
                                      radius,
                                      DOTA_UNIT_TARGET_TEAM_ENEMY,
                                      DOTA_UNIT_TARGET_HERO,
                                      DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
                                      FIND_ANY_ORDER,
                                      false)

    -- Cycle for a target that is not the initial target    
    for _,enemy in pairs(enemies) do

        -- If a valid hero target was found, return it
        if enemy ~= target then          
            return enemy
        end
    end    

    -- If this check failed, check for creeps/creep heroes instead
    local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
                                      target:GetAbsOrigin(),
                                      nil,
                                      radius,
                                      DOTA_UNIT_TARGET_TEAM_ENEMY,
                                      DOTA_UNIT_TARGET_BASIC,
                                      DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
                                      FIND_ANY_ORDER,
                                      false)

    -- Cycle for a target that is not the initial target
    for _,enemy in pairs(enemies) do
      
        -- If a valid creep target was found, return it
        if enemy ~= target then
            return enemy
        end
    end    

    -- Otherwise, return nothing
    return nil
end

-- Helper function that finds a valid target position to fire at. Relevant for Mystic Flare only (point target spell)
function SkywrathSpellsPositionFinder(caster, target_point, radius, min_distance)  
    -- Find heroes around the target
    local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
                                      target_point,
                                      nil,
                                      radius,
                                      DOTA_UNIT_TARGET_TEAM_ENEMY,
                                      DOTA_UNIT_TARGET_HERO,
                                      DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
                                      FIND_ANY_ORDER,
                                      false)

    -- Cycle for a target that isn't in the initial target point area
    for _,enemy in pairs(enemies) do

        -- Check distance between found enemy and target point and make sure it's higher than the minimum distance
        local distance = (enemy:GetAbsOrigin() - target_point):Length2D()

        -- If a valid hero target was found, return it
        if distance > min_distance then          
            return enemy
        end
    end    

    -- If this check failed, check for creeps/creep heroes instead
    local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
                                      target:GetAbsOrigin(),
                                      nil,
                                      radius,
                                      DOTA_UNIT_TARGET_TEAM_ENEMY,
                                      DOTA_UNIT_TARGET_BASIC,
                                      DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
                                      FIND_ANY_ORDER,
                                      false)

    -- Cycle for a target that isn't in the initial target point area
    for _,enemy in pairs(enemies) do
      
        -- Check distance between found enemy and target point and make sure it's higher than the minimum distance
        local distance = (enemy:GetAbsOrigin() - target_point):Length2D()

        -- If a valid hero target was found, return it
        if distance > min_distance then          
            return enemy
        end
    end    

    -- Otherwise, return nothing
    return nil
end