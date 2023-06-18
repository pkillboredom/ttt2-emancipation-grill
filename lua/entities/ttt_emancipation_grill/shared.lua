-- Author pkillboredom 2023

if SERVER then
    AddCSLuaFile()
end

ENT.Type = "anim"


ENT.ClassName = "ttt_emancipation_grill"
ENT.PrintName = "Emancipation Grill"
ENT.Author = "pkillboredom"
ENT.Spawnable = false

local SourceEmitter1 = nil
local SourceEmitter2 = nil

function ENT:Initialize()
    // set model to a plate included in the game
    self:SetModel("models/hunter/plates/plate1x2.mdl")
    -- Set to dev white texture
    self:SetMaterial("models/debug/debugwhite")
    // make model not collide with anything
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_OBB)
end

function ENT:SetupEmitterSources(Emitter1, Emitter2)
    if not IsValid(Emitter1) or not IsValid(Emitter2) then return false end
    SourceEmitter1 = Emitter1
    SourceEmitter2 = Emitter2
    self:SetParent(SourceEmitter1)

    self:SetPos(SourceEmitter1:GetPos() + (SourceEmitter2:GetPos() - SourceEmitter1:GetPos()) / 2)
    self:SetAngles((SourceEmitter2:GetPos() - SourceEmitter1:GetPos()):Angle())

    local dist = SourceEmitter1:GetPos():Distance(SourceEmitter2:GetPos())
    print("Distance between emitters: " .. dist)
    -- Find a model that fits. Doesn't work right. Replace all of this later...
    if dist <= 50 then
        self:SetModel("models/hunter/plates/plate1x2.mdl")
        self:PhysicsInit(SOLID_OBB)
        -- scale to distance. each 1x1 in these plates is 50 units^2
        self:SetModelScale(50 / dist, 0)
    elseif dist <= 100 then
        self:SetModel("models/hunter/plates/plate2x2.mdl")
        self:PhysicsInit(SOLID_OBB)
        self:SetModelScale(100 / dist, 0)
    elseif dist <= 150 then
        self:SetModel("models/hunter/plates/plate2x3.mdl")
        self:PhysicsInit(SOLID_OBB)
        self:SetModelScale(150 / dist, 0)
        -- Need to rotate this model 90 degrees around x axis
        self:SetAngles(Angle(self:GetAngles().x + 90, self:GetAngles().y, self:GetAngles().z))
    elseif dist <= 200 then
        self:SetModel("models/hunter/plates/plate2x4.mdl")
        self:PhysicsInit(SOLID_OBB)
        self:SetModelScale(200 / dist, 0)
        self:SetAngles(Angle(self:GetAngles().x + 90, self:GetAngles().y, self:GetAngles().z))
    elseif dist <= 250 then
        self:SetModel("models/hunter/plates/plate2x5.mdl")
        self:PhysicsInit(SOLID_OBB)
        self:SetModelScale(250 / dist, 0)
        self:SetAngles(Angle(self:GetAngles().x + 90, self:GetAngles().y, self:GetAngles().z))
    else -- dist > 250
        self:SetModel("models/hunter/plates/plate2x6.mdl")
        self:PhysicsInit(SOLID_OBB)
        self:SetModelScale(300 / dist, 0)
        self:SetAngles(Angle(self:GetAngles().x + 90, self:GetAngles().y, self:GetAngles().z))
    end

    -- rotate model 90 degrees around z axis
    self:SetAngles(Angle(self:GetAngles().x, self:GetAngles().y, self:GetAngles().z + 90))
end

function ENT:StartTouch(ent)
    if IsValid(ent) then
        print("StartTouch: " .. ent:GetClass())
        if ent:IsPlayer() then
            if GetConVar("ttt_grill_fizzle_weapons"):GetBool() == true then
                -- Fling logic if CVAR ttt_grill_fling_weapons is true
                if GetConVar("ttt_grill_fling_weapons"):GetBool() == true then
                    if GetConVar("ttt_grill_fizzle_pistols"):GetBool() == true then
                        local pistols = ent:GetWeaponsOnSlot(2)
                        for _, v in pairs(pistols) do
                            FlingEnt(v, ent, self)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_rifles"):GetBool() == true then
                        local rifles = ent:GetWeaponsOnSlot(3)
                        for _, v in pairs(rifles) do
                            FlingEnt(v, ent, self)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_grenade_weaps"):GetBool() == true then
                        local grenade_weaps = ent:GetWeaponsOnSlot(4)
                        for _, v in pairs(grenade_weaps) do
                            FlingEnt(v, ent, self)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_extra"):GetBool() == true then
                        local extras = ent:GetWeaponsOnSlot(7)
                        for _, v in pairs(extras) do
                            FlingEnt(v, ent, self)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_special"):GetBool() == true then
                        local special = ent:GetWeaponsOnSlot(8)
                        for _, v in pairs(special) do
                            if v:GetClass() == "weapon_ttt_wtester" and GetConVar("ttt_grill_fizzle_dna_scanner"):GetBool() == false then
                                -- do nothing
                            elseif v:GetClass() == "weapon_cigarro" then -- dont take away my smoky twizzles
                                -- do nothing
                            else
                                FlingEnt(v, ent, self)
                            end
                        end
                    end
                else -- Fizzle logic if CVAR ttt_grill_fling_weapons is false
                    if GetConVar("ttt_grill_fizzle_pistols"):GetBool() == true then
                        local pistols = ent:GetWeaponsOnSlot(2)
                        for _, v in pairs(pistols) do
                            FizzleEnt(v, ent)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_rifles"):GetBool() == true then
                        local rifles = ent:GetWeaponsOnSlot(3)
                        for _, v in pairs(rifles) do
                            FizzleEnt(v, ent)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_grenade_weaps"):GetBool() == true then
                        local grenade_weaps = ent:GetWeaponsOnSlot(4)
                        for _, v in pairs(grenade_weaps) do
                            FizzleEnt(v, ent)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_extra"):GetBool() == true then
                        local extras = ent:GetWeaponsOnSlot(7)
                        for _, v in pairs(extras) do
                            FizzleEnt(v, ent)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_special"):GetBool() == true then
                        local special = ent:GetWeaponsOnSlot(8)
                        for _, v in pairs(special) do
                            if v:GetClass() == "weapon_ttt_wtester" and GetConVar("ttt_grill_fizzle_dna_scanner"):GetBool() == false then
                                -- do nothing
                            elseif v:GetClass() == "weapon_cigarro" then -- dont take away my smoky twizzles
                                -- do nothing
                            else
                                FizzleEnt(v, ent)
                            end
                        end
                    end
                end
            end
        -- if the ent has ttt_basegrenade_proj as a base class and has been thrown by a player
        elseif (ent:GetClass() == "ttt_basegrenade_proj" or ent.Base == "ttt_basegrenade_proj") and ent:GetOwner():IsPlayer() then
            -- if the CVAR ttt_grill_fizzle_grenade_ents is true
            if GetConVar("ttt_grill_fizzle_grenade_ents"):GetBool() == true then
                FizzleEnt(ent, _)
            end
        -- if the ent is a weapon not owned by a player AND the CVAR ttt_grill_fizzle_weapons is true
        elseif ent:IsWeapon() and not ent:GetOwner():IsPlayer() and GetConVar("ttt_grill_fizzle_weapons"):GetBool() == true then
            -- fling if fling enabled
            if GetConVar("ttt_grill_fling_weapons"):GetBool() == true then
                FlingEnt(ent, _, self)
            else
                FizzleEnt(ent, _)
            end
        end
    end
end

function ENT:EndTouch(ent)

end

function ENT:Think()
    if SERVER then
        -- if the emitters are no longer valid, remove the grill
        if not IsValid(SourceEmitter1) or not IsValid(SourceEmitter2) then
            self:Remove()
        end
    end
end

function FlingEnt(ent, player, this)
    if ent:IsWeapon() and ent:GetOwner() == player then 
        -- make weapon drop
        player:DropWeapon(ent)
        -- make weapon fly away from the face they entered the collision volume at, ignoring z
        local playerpos = player:GetPos()
        ent:GetPhysicsObject():SetVelocity((Vector(playerpos.x, playerpos.y, this:GetPos().z) - this:GetPos()) * 1000)
    else
        -- make ent fly away from the face it entered the collision volume at, ignoring z
        local entpos = ent:GetPos()
        ent:GetPhysicsObject():SetVelocity((Vector(entpos.x, entpos.y, this:GetPos().z) - this:GetPos()) * 1000)
    end
    -- create an env_spark attached to the prop
    local spark = ents.Create("env_spark")
    spark:Spawn()
    spark:Activate()
    spark:SetPos(ent:GetPos())
    spark:SetKeyValue("MaxDelay", "0.8")
    spark:SetKeyValue("Magnitude", "2")
    spark:SetKeyValue("TrailLength", "2")
    spark:SetParent(ent)
    spark:Input("StartSpark", NULL, NULL, NULL)
    -- delete the spark ent after 2 seconds
    timer.Simple(2, function()
        if IsValid(spark) then
            spark:Remove()
        end
    end)
end

function FizzleEnt(ent, player)
    -- get the world model of the weapon
    local ent_worldmodel = ent:GetModel()
    local spawnpos = nil
    local newVel = nil
    -- check if this is a weapon held by player
    if ent:IsWeapon() and ent:GetOwner():IsPlayer() then
        -- remove the weapon from the player
        spawnpos = player:GetPos()
        newVel = player:GetAimVector() * 100
        player:StripWeapon(ent:GetClass())
    else
        -- set spawnpos to ent position
        spawnpos = ent:GetPos()
        -- newVel should be entity velocity 
        newVel = ent:GetVelocity()
        ent:Remove()
    end
    -- spawn the weapon as a prop at the player's position
    local prop = ents.Create("prop_physics")
    prop:SetModel(ent_worldmodel)
    -- spawn the prop
    prop:Spawn()
    prop:Activate()

    prop:SetPos(spawnpos)
    -- make prop black
    prop:SetColor(Color(0, 0, 0, 255))
    -- make prop drift forward with random deviation and spin slowly with randommness
    prop:GetPhysicsObject():SetVelocity(newVel)
    prop:GetPhysicsObject():ApplyTorqueCenter(VectorRand() * 10)
    -- make prop collide with nothing
    prop:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    prop:GetPhysicsObject():EnableGravity(false)

    -- create an env_spark attached to the prop
    local spark = ents.Create("env_spark")
    spark:Spawn()
    spark:Activate()
    spark:SetPos(prop:GetPos())
    spark:SetKeyValue("MaxDelay", "0.8")
    spark:SetKeyValue("Magnitude", "2")
    spark:SetKeyValue("TrailLength", "2")
    spark:SetParent(prop)
    spark:Input("StartSpark", NULL, NULL, NULL)

    timer.Simple(GetConVar("ttt_grill_fizzle_duration"):GetInt(), function()
        prop:Remove()
    end)
end