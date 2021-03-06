AddCSLuaFile()
ENT.Type = "anim"

function ENT:Initialize()
	self.Entity:SetModel("models/items/item_item_crate.mdl")
    self.Entity:PhysicsInit(SOLID_VPHYSICS)
    self.Entity:SetModelScale(1)
    self.Entity:SetHealth(250)
    if SERVER then
        self.Entity:PrecacheGibs()
    end

	local phys = self.Entity:GetPhysicsObject()
	if phys:IsValid() then
        phys:Wake()
    end
end

function ENT:OnRemove()
end

function ENT:Think()
end

function ENT:OnTakeDamage(dmgInfo)
    self.Entity:SetHealth(self.Entity:Health() - dmgInfo:GetDamage())
    if self.Entity:Health() <= 0 then
        self.Entity:GibBreakServer(Vector(1, 1, 1))
        self.Entity:Remove()
    end
    return true
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:Alive() or activator:IsSpec() then return end

    local blocklist = {}
    for blocked_id in string.gmatch(GetConVar("randomat_package_blocklist"):GetString(), '([^,]+)') do
        table.insert(blocklist, blocked_id:Trim())
    end

    Randomat:GiveRandomShopItem(activator, Randomat:GetShopRoles(), blocklist, false,
        -- gettrackingvar
        function()
            return activator.packageweptries
        end,
        -- settrackingvar
        function(value)
            activator.packageweptries = value
        end,
        -- onitemgiven
        function(isequip, id)
            Randomat:CallShopHooks(isequip, id, activator)
            if SERVER then
                Randomat:LogEvent("[RANDOMAT] " .. activator:Nick() .. " picked up the Care Package")
            end
        end)

	self:Remove()
end

function ENT:Break()
end
