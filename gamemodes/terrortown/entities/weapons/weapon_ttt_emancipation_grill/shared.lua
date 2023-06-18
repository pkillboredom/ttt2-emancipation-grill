-- Author pkillboredom 2023

if SERVER then
    AddCSLuaFile()
    // TODO: add resource for buy icon
    resource.AddFile("materials/vgui/ttt/blue_template_icon.vmt")
end

SWEP.Base                   = "weapon_tttbase"
SWEP.PrintName              = "Emancipation Grill"
SWEP.ViewModel              = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel             = "models/weapons/w_defuser.mdl"
SWEP.DrawCrosshair		    = true

if CLIENT then
    SWEP.Slot = 6
    SWEP.ViewModelFOV = 10
    
    SWEP.Icon = "vgui/ttt/blue_template_icon.vtf"

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "Place an Emancipation Grill."
    };
end

SWEP.HoldType               = "slam"
SWEP.Primary.ClipSize		= 1
SWEP.Primary.DefaultClip	= 1
SWEP.Primary.Automatic		= false
SWEP.Primary.Delay          = 1
SWEP.Primary.Ammo		    = "none"
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		    = "none"
SWEP.Secondary.Delay        = 2

SWEP.Kind                   = WEAPON_EQUIP
SWEP.CanBuy                 = {ROLE_TRAITOR}
SWEP.LimitedStock           = false -- Set to true after testing!
SWEP.WeaponID               = AMMO_DEFUSER
SWEP.Cost                   = 1


-- Grill emitters come in two parts. Need to track if the player has placed one of them.
local firstEmitterEnt = nil
local secondEmitterEnt = nil

local placeSound = Sound("ambient/energy/weld1.wav")

function SWEP:Initialize()
    firstEmitterEnt = nil
    secondEmitterEnt = nil
end

-- Primary attack places the emitters.
-- The second emitter must be placed at the same vertical height as the first.
-- The second emitter must be placed within [CVAR ttt_grill_max_distance] units of the first.
-- Emitters can only be placed GRILL_PLACE_DISTANCE units or less away from the player.
-- Emitters must be placed on a solid surface.
-- Placing the second emitter will use the primary ammo and create the grill, 
-- which is a box between the two emitters with height [CVAR ttt_grill_height].
local EMITTER_PLACE_DISTANCE = 100
local EMITTER_MIN_DISTANCE = 25
local EMITTER_Z_SLOP = 30
function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end
   	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
    if SERVER then
        local ply = self.Owner
        if not IsValid(ply) then return end
        local vsrc = ply:GetPos()
        local vang = ply:GetForward()
        local vvel = ply:GetVelocity()
        local vpos = ply:GetEyeTrace().HitPos or nil
        local chkply = ply:GetEyeTrace().Entity or nil
        local pos = self.Owner:GetPos()
        -- check if player is looking at a valid surface and is within range
        if not vpos or vpos:Distance(pos) > EMITTER_PLACE_DISTANCE or (IsEntity(chkply) and IsValid(chkply)) then 
            print("Invalid surface or too far away.")
            return false 
        else
            print("Valid surface.")
        end
        -- check if player has already placed an emitter
        if not IsValid(firstEmitterEnt) then -- Emitter 1.
            -- place the emitter entity
            firstEmitterEnt = ents.Create("ttt_emancipation_grill_emitter")
            if IsValid(firstEmitterEnt) then
                firstEmitterEnt:SetPos(vpos)
                -- get the normal of the surface the player is looking at
                local normal = ply:GetEyeTrace().HitNormal
                -- set emitter to face toward hit surface normal
                firstEmitterEnt:SetAngles(normal:Angle())
                firstEmitterEnt:SetRenderMode(RENDERMODE_TRANSCOLOR)
                firstEmitterEnt:SetColor(Color(255, 255, 255, 127)) -- transparent while second is unplaced
                firstEmitterEnt:Spawn()
                firstEmitterEnt:Activate()
                firstEmitterEnt:SetOwner(ply)
                -- play sound
                self.Owner:EmitSound(placeSound, 25)
            end
        else
            -- check if player is looking at a position that is not too close to the first emitter
            if vpos:Distance(firstEmitterEnt:GetPos()) < EMITTER_MIN_DISTANCE then return false end
            -- get the position the player is looking at, but at the same height as the first emitter
            vpos_z_fixed = Vector(vpos.x, vpos.y, firstEmitterEnt:GetPos().z)
            -- check if player is looking at a position that is no more than EMITTER_Z_SLOP units above or below the first emitter
            if vpos_z_fixed.z > firstEmitterEnt:GetPos().z + EMITTER_Z_SLOP or vpos_z_fixed.z < firstEmitterEnt:GetPos().z - EMITTER_Z_SLOP then return false end
            -- check if vpos_z_fixed is within range of the first emitter
            if vpos_z_fixed:Distance(firstEmitterEnt:GetPos()) > GetConVar("ttt_grill_max_distance"):GetInt() then return false end
            -- looks good, place emitter 2
            secondEmitterEnt = ents.Create("ttt_emancipation_grill_emitter")
            if IsValid(secondEmitterEnt) then
                -- spend ammo
                self:TakePrimaryAmmo(1)
                secondEmitterEnt:SetPos(vpos_z_fixed)
                -- get the normal of the surface the player is looking at
                local normal = ply:GetEyeTrace().HitNormal
                -- set emitter to face toward hit surface normal
                secondEmitterEnt:SetAngles(normal:Angle())
                secondEmitterEnt:Spawn()
                secondEmitterEnt:Activate()
                secondEmitterEnt:SetOwner(ply)
                -- play sound
                self.Owner:EmitSound(placeSound, 25)
                -- set first emitter to solid color
                firstEmitterEnt:SetColor(Color(255, 255, 255, 255))
                -- make both emitters' angles face each other
                firstEmitterEnt:SetAngles((secondEmitterEnt:GetPos() - firstEmitterEnt:GetPos()):Angle())
                secondEmitterEnt:SetAngles((firstEmitterEnt:GetPos() - secondEmitterEnt:GetPos()):Angle())
                -- rotate both emitters -90 degrees around their forward axis
                firstEmitterEnt:SetAngles(firstEmitterEnt:GetAngles() + Angle(0, -90, 0))
                secondEmitterEnt:SetAngles(secondEmitterEnt:GetAngles() + Angle(0, -90, 0))
                -- create the grill entity
                local grillEnt = ents.Create("ttt_emancipation_grill") // TODO: create this entity!
                if IsValid(grillEnt) then
                    grillEnt:SetOwner(ply)
                    grillEnt:SetDamageOwner(ply)
                    grillEnt:Spawn()
                    grillEnt:SetupEmitterSources(firstEmitterEnt, secondEmitterEnt)
                    grillEnt:SetTrigger(true)
                    grillEnt:SetRenderMode(RENDERMODE_TRANSCOLOR)
                    grillEnt:SetColor(Color(0, 225, 255, 110))
                    grillEnt:Activate()
                    if self:Clip1() <= 0 then self:Remove() end
                end
            end
        end
    end
end

-- Secondary attack cancels emitter placement, which deletes the first emitter this player placed,
-- if a second one has not been placed yet.
function SWEP:SecondaryAttack()
    --if not self:CanSecondaryAttack() then return end
    self.Weapon:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
    if SERVER then
        local ply = self.Owner
        if not IsValid(ply) then return end
        -- check if player has already placed an emitter
        if IsValid(firstEmitterEnt) then
            -- check if player has already placed a second emitter
            if IsValid(secondEmitterEnt) then
                -- player has placed both emitters, do nothing
            else
                -- player has only placed the first emitter, so delete it
                firstEmitterEnt:Remove()
                firstEmitterEnt = nil
            end
        end
    end
end

if CLENT then
    function SWEP:Initialize()
        self:AddHUDHelp("Left click to place an emitter.", "Right click to cancel emitter placement.", false)
        return self.BaseClass.Initialize(self)
    end

    function SWEP:DrawWorldModel()
        if not IsValid(self.Owner) then
            self:DrawModel()
        end
    end
end

function SWEP:Reload()
    return false
end

function SWEP:OnDrop()
	self:Remove()
end