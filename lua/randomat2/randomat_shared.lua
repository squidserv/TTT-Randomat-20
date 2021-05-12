function Randomat:IsInnocentTeam(ply, skip_detective)
    local role = ply:GetRole()
    return (not skip_detective and role == ROLE_DETECTIVE) or role == ROLE_INNOCENT or role == ROLE_MERCENARY or role == ROLE_PHANTOM or role == ROLE_GLITCH or role == ROLE_ROMANTIC or role == ROLE_DEPUTY
end

function Randomat:IsTraitorTeam(ply)
    if player.IsTraitorTeam then return player.IsTraitorTeam(ply) end
    local role = ply:GetRole()
    return role == ROLE_TRAITOR or role == ROLE_HYPNOTIST or role == ROLE_ASSASSIN or role == ROLE_DETRAITOR or role == ROLE_IMPERSONATOR
end

function Randomat:IsMonsterTeam(ply)
    local role = ply:GetRole()
    return role == ROLE_ZOMBIE or role == ROLE_VAMPIRE
end

function Randomat:IsJesterTeam(ply)
    local role = ply:GetRole()
    return role == ROLE_JESTER or role == ROLE_SWAPPER or role == ROLE_BEGGAR
end

function Randomat:IsIndependentTeam(ply)
    local role = ply:GetRole()
    return role == ROLE_KILLER or role == ROLE_DRUNK or role == ROLE_CLOWN
end

function Randomat:GetRoleColor(role)
    local color = nil
    if type(ROLE_COLORS) == "table" then
        color = ROLE_COLORS[role];
    end
    if color then return color end

    local role_colors = {
        [ROLE_INNOCENT] = Color(55, 170, 50, 255),
        [ROLE_TRAITOR] = Color(180, 50, 40, 255),
        [ROLE_DETECTIVE] = Color(50, 60, 180, 255),
        [ROLE_MERCENARY] = Color(245, 200, 0, 255),
        [ROLE_JESTER] = Color(180, 23, 253, 255),
        [ROLE_PHANTOM] = Color(82, 226, 255, 255),
        [ROLE_HYPNOTIST] = Color(255, 80, 235, 255),
        [ROLE_GLITCH] = Color(245, 106, 0, 255),
        [ROLE_ZOMBIE] = Color(69, 97, 0, 255),
        [ROLE_VAMPIRE] = Color(45, 45, 45, 255),
        [ROLE_SWAPPER] = Color(111, 0, 255, 255),
        [ROLE_ASSASSIN] = Color(112, 50, 0, 255),
        [ROLE_KILLER] = Color(50, 0, 70, 255),
        [ROLE_DETRAITOR] = Color(112, 27, 140, 255),
        [ROLE_ROMANTIC] =  Color(245, 200, 0, 255),
        [ROLE_DRUNK] = Color(255, 80, 235, 255),
        [ROLE_DEPUTY] =  Color(245, 200, 0, 255),
        [ROLE_IMPERSONATOR] = Color(245, 106, 0, 255),
        [ROLE_BEGGAR] = Color(180, 23, 253, 255),
        [ROLE_CLOWN] = Color(255, 80, 235, 255)
    }
    return role_colors[role]
end