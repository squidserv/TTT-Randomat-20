if SERVER then
    util.AddNetworkString("TTT_Zombified")
end

local EVENT = {}

EVENT.Title = "RISE FROM YOUR GRAVE"
EVENT.Description = "Causes anyone who dies to be resurrected as a Zombie"
EVENT.id = "grave"

CreateConVar("randomat_grave_health", 30, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "The health that the Zombies respawn with")

function EVENT:Begin()
    timer.Create("infrespawntimer", 1, 0, function()
        for _, ply in pairs(player.GetAll()) do
            -- If a player has died and they weren't a zombie or zombifying, zombify them
            if not ply:Alive() and ply:GetRole() ~= ROLE_ZOMBIE and ply:GetPData("IsZombifying", 0) ~= 1 then
                if SERVER then
                    net.Start("TTT_Zombified")
					net.WriteString(ply:Nick())
					net.Broadcast()
                end

                local body = ply.server_ragdoll or ply:GetRagdollEntity()
                ply:SpawnForRound(true)
                ply:SetCredits(0)
                ply:SetRole(ROLE_ZOMBIE)
                ply:SetZombiePrime(false)
                ply:SetHealth(GetConVar("randomat_grave_health"):GetInt())
                ply:SetMaxHealth(GetConVar("randomat_grave_health"):GetInt())
                ply:StripWeapons()
                ply:Give("weapon_zom_claws")
                if IsValid(body) then
                    ply:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
                    body:Remove()
                end
                SendFullStateUpdate()
            end
        end
    end)
end

function EVENT:End()
    timer.Remove("infrespawntimer")
end

function EVENT:Condition()
    return not Randomat:IsEventActive("prophunt") and not Randomat:IsEventActive("harpoon") and not Randomat:IsEventActive("slam") and not Randomat:IsEventActive("murder")
end

Randomat:register(EVENT)