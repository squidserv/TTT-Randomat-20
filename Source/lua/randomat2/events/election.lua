local EVENT = {}

util.AddNetworkString("ElectionNominateBegin")
util.AddNetworkString("ElectionNominateVoted")
util.AddNetworkString("ElectionNominateReset")
util.AddNetworkString("ElectionNominateEnd")
util.AddNetworkString("ElectionVoteBegin")
util.AddNetworkString("ElectionVoteVoted")
util.AddNetworkString("ElectionVoteReset")
util.AddNetworkString("ElectionVoteEnd")

CreateConVar("randomat_election_timer", 40, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "The number of seconds each round of voting lasts", 30, 180)
CreateConVar("randomat_election_winner_credits", 2, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "The number of credits given as a reward, if appropriate", 1, 10)
CreateConVar("randomat_election_vamp_turn_innocents", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Whether Vampires turn innocents. Otherwise, turns traitors")

EVENT.Title = "Election Day"
EVENT.AltTitle = ""
EVENT.id = "election"

local playersvoted = {}
local votableplayers = {}
local playervotes = {}

local function ClearTable(table)
    for k, _ in pairs(table) do
        table[k] = nil
    end
end

local function ResetVotes()
    ClearTable(playersvoted)

    net.Start("ElectionVoteReset")
    net.Broadcast()

    for k, _ in pairs(playervotes) do
        playervotes[k] = 0
    end
end

function EVENT:StartVotes(first, second)
    self:SmallNotify("Nominations are complete. Time to vote for President!")

    net.Start("ElectionVoteBegin")
        net.WriteString(first)
        net.WriteString(second)
    net.Broadcast()

    local electiontime = GetConVar("randomat_election_timer"):GetInt()
    local ticks = 0
    timer.Create("ElectionVoteTimer", 1, 0, function()
        ticks = ticks + 1
        if electiontime > 19 and ticks == electiontime - 10 then
            self:SmallNotify("10 seconds left on voting!")
        elseif ticks == electiontime then
            ticks = 0
            local votecount = 0
            for _, v in pairs(playervotes) do
                votecount = votecount + v
            end

            if votecount > 0 then
                -- Get the top two candidates by the vote count
                local firstcandidate = nil
                local firstvotes = -1
                local secondvotes = -1
                for k, v in SortedPairsByValue(playervotes, true) do
                    if firstvotes < 0 then
                        firstcandidate = k
                        firstvotes = v
                    elseif secondvotes < 0 then
                        secondvotes = v
                    end
                end

                -- Make sure there isn't a tie
                if firstvotes == secondvotes then
                    self:SmallNotify("There was a tie! A new round of voting will begin.")
                    ResetVotes()
                    return
                end

                timer.Remove("ElectionVoteTimer")
                net.Start("ElectionVoteEnd")
                net.Broadcast()

                -- Swear the president in
                for _, v in pairs(votableplayers) do
                    if v:Nick() == firstcandidate then
                        self:SwearIn(v)
                    end
                end
            else
                self:SmallNotify("Nobody was voted for. A new round of voting will begin.")
            end

            ResetVotes()
        end
    end)
end

local function ResetNominations()
    ClearTable(playersvoted)

    net.Start("ElectionNominateReset")
    net.Broadcast()

    for k, _ in pairs(playervotes) do
        playervotes[k] = 0
    end
end

function EVENT:StartNominations()
    net.Start("ElectionNominateBegin")
    net.Broadcast()

    local electiontime = GetConVar("randomat_election_timer"):GetInt()
    local ticks = 0
    timer.Create("ElectionNominateTimer", 1, 0, function()
        ticks = ticks + 1
        if electiontime > 19 and ticks == electiontime - 10 then
            self:SmallNotify("10 seconds left on voting!")
        elseif ticks == electiontime then
            ticks = 0
            local nominationcount = 0
            -- Only count players with at least one vote
            for _, v in pairs(playervotes) do
                if v > 0 then
                    nominationcount = nominationcount + 1
                end
            end

            -- There has to be at least 2 players nominated to continue
            if nominationcount > 1 then
                -- Get the top three nominations by the vote count
                local first = nil
                local firstvotes = -1
                local second = nil
                local secondvotes = -1
                local thirdvotes = -1
                for k, v in SortedPairsByValue(playervotes, true) do
                    if firstvotes < 0 then
                        first = k
                        firstvotes = v
                    elseif secondvotes < 0 then
                        second = k
                        secondvotes = v
                    elseif thirdvotes < 0 then
                        thirdvotes = v
                    end
                end

                -- If there are more than 2 nominations, make sure there isn't a tie
                if nominationcount > 2 and (firstvotes == secondvotes or secondvotes == thirdvotes) then
                    -- If either of the top pairs matches, that means there is a tie (at least 2-way, if not 3-way)
                    self:SmallNotify("There was a tie! A new round of voting will begin.")
                    ResetNominations()
                    return
                end

                timer.Remove("ElectionNominateTimer")
                net.Start("ElectionNominateEnd")
                net.Broadcast()

                -- Start vote for president
                self:StartVotes(first, second)
            else
                self:SmallNotify("Too few players were nominated. A new round of voting will begin.")
            end

            ResetNominations()
        end
    end)
end

function EVENT:SwearIn(winner)
    self:SmallNotify(winner:Nick() .. " has been elected President!")

    local credits = GetConVar("randomat_election_winner_credits"):GetInt()
    -- Wait 3 seconds before applying the affect
    timer.Simple(3, function()
        -- Innocent - Promote to Detective, give credits
        if winner:GetRole() == ROLE_INNOCENT or winner:GetRole() == ROLE_MERCENARY or winner:GetRole() == ROLE_PHANTOM or winner:GetRole() == ROLE_GLITCH then
            Randomat:SetRole(winner, ROLE_DETECTIVE)
            winner:AddCredits(credits)
        -- Traitor - Announce their role, and give their whole team free credits
        elseif winner:GetRole() == ROLE_TRAITOR or winner:GetRole() == ROLE_ASSASSIN or winner:GetRole() == ROLE_HYPNOTIST then
            self:SmallNotify("The President is " .. string.lower(self:GetRoleName(winner)) .. "!")

            for _, v in pairs(self:GetAlivePlayers(false)) do
                if v:GetRole() == ROLE_TRAITOR or v:GetRole() == ROLE_ASSASSIN or v:GetRole() == ROLE_HYPNOTIST then
                    v:AddCredits(credits)
                end
            end
        -- Jester - Kill them, winning the round
        -- Swapper - Kill them with a random player as the "attacker", swapping their roles
        elseif winner:GetRole() == ROLE_JESTER or winner:GetRole() == ROLE_SWAPPER then
            local attacker = self.owner
            if winner:GetRole() == ROLE_SWAPPER then
                repeat
                    attacker = self:GetAlivePlayers(true)[1]
                until attacker ~= winner
            end

            local dmginfo = DamageInfo()
            dmginfo:SetDamage(10000)
            dmginfo:SetAttacker(attacker)
            dmginfo:SetInflictor(game.GetWorld())
            dmginfo:SetDamageType(DMG_BULLET)
            dmginfo:SetDamageForce(Vector(0, 0, 0))
            dmginfo:SetDamagePosition(attacker:GetPos())
            winner:TakeDamageInfo(dmginfo)
        -- Killer - Kill all non-Jesters/Swappers so they win the round
        elseif winner:GetRole() == ROLE_KILLER then
            for _, v in pairs(self:GetAlivePlayers(false)) do
                if v:GetRole() ~= ROLE_JESTER and v:GetRole() ~= ROLE_SWAPPER and v ~= winner then
                    v:Kill()
                end
            end
        -- Zombie - Silently trigger the RISE FROM YOUR GRAVE event
        elseif winner:GetRole() == ROLE_ZOMBIE then
            self:SmallNotify("The President is " .. string.lower(self:GetRoleName(winner)) .. "!")
            Randomat:SilentTriggerEvent("grave", winner)
        elseif winner:GetRole() == ROLE_VAMPIRE then
            self:SmallNotify("The President is " .. string.lower(self:GetRoleName(winner)) .. "!")
            -- TODO: Convert all of the configured team to vampires. Be sure to strip special weapons and give claws
        end
    end)
end

function EVENT:Begin()
    for k, v in pairs(player.GetAll()) do
        if not (v:Alive() and v:IsSpec()) then
            votableplayers[k] = v
            playervotes[v:Nick()] = 0
        end
    end

    self:StartNominations()
end

function EVENT:End()
    timer.Remove("ElectionNominateTimer")
    timer.Remove("ElectionVoteTimer")
    net.Start("ElectionNominateEnd")
    net.Broadcast()
    net.Start("ElectionVoteEnd")
    net.Broadcast()
end

function EVENT:Condition()
    return not Randomat:IsEventActive("democracy")
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in pairs({"timer", "winner_credits"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 0
            })
        end
    end

    local checks = {}
    for _, v in pairs({"vamp_turn_innocents"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end

    return sliders, checks
end

net.Receive("ElectionNominateVoted", function(ln, ply)
    -- TODO: Uncomment this
    --for k, _ in pairs(playersvoted) do
    --    if k == ply then
    --        ply:PrintMessage(HUD_PRINTTALK, "You have already voted.")
    --        return
    --    end
    --end

    local num = 0
    local votee = net.ReadString()
    for _, v in pairs(votableplayers) do
        if v:Nick() == votee then
            playersvoted[ply] = v
            playervotes[votee] = playervotes[votee] + 1
            num = playervotes[votee]
        end
    end

    net.Start("ElectionNominateVoted")
        net.WriteString(votee)
        net.WriteInt(num, 32)
    net.Broadcast()
end)

net.Receive("ElectionVoteVoted", function(ln, ply)
    -- TODO: Uncomment this
    --for k, _ in pairs(playersvoted) do
    --    if k == ply then
    --        ply:PrintMessage(HUD_PRINTTALK, "You have already voted.")
    --        return
    --    end
    --end

    local num = 0
    local votee = net.ReadString()
    for _, v in pairs(votableplayers) do
        if v:Nick() == votee then
            playersvoted[ply] = v
            playervotes[votee] = playervotes[votee] + 1
            num = playervotes[votee]
        end
    end

    net.Start("ElectionVoteVoted")
        net.WriteString(votee)
        net.WriteInt(num, 32)
    net.Broadcast()
end)

Randomat:register(EVENT)