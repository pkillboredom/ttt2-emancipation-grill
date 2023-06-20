-- Author pkillboredom 2023

-- Where TRIGGER WORKAROUND is noted:
-- This is a workaround for engine behavior where trigger events are
-- not called when two triggers touch. See:  https://github.com/pmrowla/hl2sdk-csgo/blob/master/game/shared/physics_main_shared.cpp#L954


AddCSLuaFile()

ENT.Type = "point"

ENT.ClassName = "ttt_emancipation_grill"
ENT.PrintName = "Emancipation Grill"
ENT.Author = "pkillboredom"
ENT.Spawnable = false

local vec10 = Vector(10, 10, 0)

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "Emitter1Ent")
    self:NetworkVar("Entity", 1, "Emitter2Ent")
    self:NetworkVar("Vector", 2, "MaxBound")
    self:NetworkVar("Vector", 3, "MinBound")
    self:NetworkVar("Angle", 4, "BoundAngle")
    self:NetworkVar("Entity", 5, "SparkEnt")
end

function ENT:Initialize()
    -- set up touch data
    self.TouchingEntities = {}
    self.FizzlingEntities = {}

    -- set up think timer to check for overlapping entities
    self:NextThink(CurTime())

    if self:GetEmitter1Ent() == nil or self:GetEmitter2Ent() == nil then
        print("ERROR: Emancipation Grill is missing an emitter!")
        self:Remove()
        return false
    end
    -- get the distance between the two emitters
    local dist = self:GetEmitter1Ent():GetPos():Distance(self:GetEmitter2Ent():GetPos())
    -- get center of the box as the midpoint between the two emitters
    local center = (self:GetEmitter1Ent():GetPos() + self:GetEmitter2Ent():GetPos()) / 2
    -- get the nearest ceiling and floor from center
    local ceiling = util.TraceLine({
        start = center,
        endpos = center + Vector(0, 0, 1000),
        filter = function(ent) if ent:GetClass() == "func_brush" then return true end end
    }).HitPos
    print ("ceiling: " .. tostring(ceiling))
    local floor = util.TraceLine({
        start = center,
        endpos = center - Vector(0, 0, 1000),
        filter = function(ent) if ent:GetClass() == "func_brush" then return true end end
    }).HitPos
    print ("floor: " .. tostring(floor))
    -- create maxs and mins for a box dist units wide, 20 units deep, HEIGHT units tall
    -- clamp bounds to ceiling and floor's z in local space
    local HEIGHT = 128
    -- if z distance between ceiling and floor is less than HEIGHT, move center to halfway between ceiling and floor
    if ceiling.z - floor.z <= HEIGHT then
        center.z = (ceiling.z + floor.z) / 2
        -- move the emitters z down to be lined up with center
        self:GetEmitter1Ent():SetPos(Vector(self:GetEmitter1Ent():GetPos().x, self:GetEmitter1Ent():GetPos().y, center.z))
        self:GetEmitter2Ent():SetPos(Vector(self:GetEmitter2Ent():GetPos().x, self:GetEmitter2Ent():GetPos().y, center.z))
    end
    self:SetPos(center)
    local max = Vector(dist / 2, 10, HEIGHT/2)
    local min = Vector(-dist / 2, -10, -HEIGHT/2)
    max.z = math.Clamp(max.z, floor.z - center.z, ceiling.z - center.z)
    min.z = math.Clamp(min.z, floor.z - center.z, ceiling.z - center.z)
    self:SetMaxBound(max)
    self:SetMinBound(min)
    -- get orientation angle between the two emitters
    local ang = (self:GetEmitter2Ent():GetPos() - self:GetEmitter1Ent():GetPos()):Angle()
    self:SetBoundAngle(ang)
    -- debug draw a box with the angle
    debugoverlay.BoxAngles(self:GetPos(), self:GetMinBound(), self:GetMaxBound(), self:GetBoundAngle(), 300, Color(0, 255, 0, 50), false)
    debugoverlay.Box(self:GetPos(), self:GetMinBound(), self:GetMaxBound(), 300, Color(255, 0, 0, 50), false)

    -- create spark ent 
    self:SetSparkEnt(ents.Create("env_spark"))
    self:GetSparkEnt():SetPos(self:GetPos())
    self:GetSparkEnt():SetParent(self)
    self:GetSparkEnt():SetKeyValue("MaxDelay", "0.1")
    self:GetSparkEnt():SetKeyValue("Magnitude", "2")
    self:GetSparkEnt():SetKeyValue("TrailLength", "2")
    self:GetSparkEnt():Spawn()
    self:GetSparkEnt():Activate()
    -- add hook to EntityFireBullets to check if bullet will intersect with grill
    hook.Add("EntityFireBullets", "grill_bullet_check", function(shooterEnt, data)
        if IsValid(shooterEnt) then
            --print("EntityFireBullets: " .. shooterEnt:GetClass())
            -- check if bullet will pass through grill's OBB using TraceOBB
            local start = data.Src
            local endpos = data.Src + data.Dir * data.Distance
            local hitPoint = TraceOBB(start, endpos, self:GetPos(), self:GetMinBound(), self:GetMaxBound(), self:GetBoundAngle())
            
            -- if hit, change bullet's endpos to the hitpos
            if hitPoint ~= false then
                --print("hit grill!")
                endpos = hitPoint
                debugoverlay.Cross(endpos, 10, 10, Color(255, 0, 0), false)
                print("old distance: " .. data.Distance)
                data.Distance = endpos:Distance(start)
                print("new distance: " .. data.Distance)
                -- spark once at bullet endpos
                -- TODO: This does not work because the hook is called in a buggy context, see SetPos hover docs
                self:GetSparkEnt():SetPos(endpos) 
                self:GetSparkEnt():Input("SparkOnce", NULL, NULL, NULL)
                return true
            end
        end
    end)
end

if SERVER then
    hook.Add("TTTCanSearchCorpse", "FizzleRagdollSearchHook", function(ply, rag)
        -- check for fizzling nw var
        if rag:GetNWBool("FizzleRagdoll") == true then
            return false
        end
    end)
end

function ENT:OnRemove()
    --print("some asshole removed me!")
end

function ENT:HandleTouch(ent)
    if IsValid(ent) then
        print("HandleTouch: " .. ent:GetClass())
        if ent:IsPlayer() then
            if GetConVar("ttt_grill_fizzle_weapons"):GetBool() == true then
                -- Fling logic if CVAR ttt_grill_fling_weapons is true
                if GetConVar("ttt_grill_fling_weapons"):GetBool() == true then
                    if GetConVar("ttt_grill_fizzle_pistols"):GetBool() == true then
                        local pistols = ent:GetWeaponsOnSlot(2)
                        for _, v in pairs(pistols) do
                            self:FlingEnt(v, ent, self)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_rifles"):GetBool() == true then
                        local rifles = ent:GetWeaponsOnSlot(3)
                        for _, v in pairs(rifles) do
                            self:FlingEnt(v, ent, self)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_grenade_weaps"):GetBool() == true then
                        local grenade_weaps = ent:GetWeaponsOnSlot(4)
                        for _, v in pairs(grenade_weaps) do
                            self:FlingEnt(v, ent, self)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_extra"):GetBool() == true then
                        local extras = ent:GetWeaponsOnSlot(7)
                        for _, v in pairs(extras) do
                            self:FlingEnt(v, ent, self)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_special"):GetBool() == true then
                        local special = ent:GetWeaponsOnSlot(8)
                        for _, v in pairs(special) do
                            if v:GetClass() == "weapon_ttt_wtester" 
                                    and GetConVar("ttt_grill_fizzle_dna_scanner"):GetBool() == false then
                                -- do nothing
                            elseif v:GetClass() == "weapon_cigarro" then -- dont take away my smoky twizzles
                                -- do nothing
                            else
                                self:FlingEnt(v, ent, self)
                            end
                        end
                    end
                else -- Fizzle logic if CVAR ttt_grill_fling_weapons is false
                    if GetConVar("ttt_grill_fizzle_pistols"):GetBool() == true then
                        local pistols = ent:GetWeaponsOnSlot(2)
                        for _, v in pairs(pistols) do
                            self:FizzleEnt(v, ent)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_rifles"):GetBool() == true then
                        local rifles = ent:GetWeaponsOnSlot(3)
                        for _, v in pairs(rifles) do
                            self:FizzleEnt(v, ent)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_grenade_weaps"):GetBool() == true then
                        local grenade_weaps = ent:GetWeaponsOnSlot(4)
                        for _, v in pairs(grenade_weaps) do
                            self:FizzleEnt(v, ent)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_extra"):GetBool() == true then
                        local extras = ent:GetWeaponsOnSlot(7)
                        for _, v in pairs(extras) do
                            self:FizzleEnt(v, ent)
                        end
                    end
                    if GetConVar("ttt_grill_fizzle_special"):GetBool() == true then
                        local special = ent:GetWeaponsOnSlot(8)
                        for _, v in pairs(special) do
                            if v:GetClass() == "weapon_ttt_wtester" 
                                    and GetConVar("ttt_grill_fizzle_dna_scanner"):GetBool() == false then
                                -- do nothing
                            elseif v:GetClass() == "weapon_cigarro" then -- dont take away my smoky twizzles
                                -- do nothing
                            else
                                self:FizzleEnt(v, ent)
                            end
                        end
                    end
                end
            end
        -- if the ent has ttt_basegrenade_proj as a base class and has been thrown by a player
        elseif (ent:GetClass() == "ttt_basegrenade_proj" or ent.Base == "ttt_basegrenade_proj") 
                and ent:GetOwner():IsPlayer() then
            -- if the CVAR ttt_grill_fizzle_grenade_ents is true
            if GetConVar("ttt_grill_fizzle_grenade_ents"):GetBool() == true then
                self:FizzleEnt(ent, _)
            end
        -- if the ent is a weapon not owned by a player AND the CVAR ttt_grill_fizzle_weapons is true
        elseif ent:IsWeapon() and not ent:GetOwner():IsPlayer() 
                and GetConVar("ttt_grill_fizzle_weapons"):GetBool() == true then
            -- fling if fling enabled
            if GetConVar("ttt_grill_fling_weapons"):GetBool() == true then
                self:FlingEnt(ent, _, self)
            else
                self:FizzleEnt(ent, _)
            end
        elseif ent:GetClass() == "prop_ragdoll" then
            if GetConVar("ttt_grill_fizzle_corpses"):GetBool() == true and CORPSE.GetPlayerNick(ent, false) ~= false then
                self:FizzleEnt(ent, _)
            end
        elseif ent:GetClass() == "prop_physics" then
        end
    end
end

function ENT:Think()
    if SERVER then
        local worldMins = self:LocalToWorld(self:GetMinBound())
        local worldMaxs = self:LocalToWorld(self:GetMaxBound())
        local worldCenter = self:GetPos()

        local entities = ents.FindInBox(worldMins, worldMaxs)

        -- iterate through entities and check if they are touching the trigger
        for _, ent in ipairs(entities) do
            if ent ~= self then
                -- if ent is in fizzling table, skip it
                if self.FizzlingEntities[ent] then
                    -- skip this entity
                else if (ent:IsWeapon() or ent:IsPlayer()) then
                    --print("weapon/player found: " .. ent:GetClass())
                    -- check if ent phys obj is inside obb
                    -- get center of ent collision bounds
                    local worldPos = ent:LocalToWorld(ent:OBBCenter())
                    local localPos = self:WorldToLocal(worldPos)
                    local isEntCenterInOBB = IsPointInOBB(worldPos, worldCenter, self:GetBoundAngle(), self:GetMinBound(), self:GetMaxBound(), ent:IsPlayer())
                    --print ("isEntCenterInOBB: " .. tostring(isEntCenterInOBB))
                    -- check if the entity is already touching the trigger
                    if isEntCenterInOBB and not self.TouchingEntities[ent] then
                        -- entity just started touching the trigger, so call HandleTouch
                        self:HandleTouch(ent)
                        self.TouchingEntities[ent] = true
                    end
                elseif (ent:GetClass() == "prop_ragdoll" and CORPSE.GetPlayerNick(ent, false) ~= false) then
                    if GetConVar("ttt_grill_fizzle_corpses"):GetBool() == true then
                        if AreOBBsIntersecting(self:GetPos(), self:GetMinBound(), self:GetMaxBound(), self:GetBoundAngle(), ent:GetPos(), ent:OBBMins(), ent:OBBMaxs(), ent:GetAngles()) then
                            self:HandleTouch(ent)
                            self.TouchingEntities[ent] = true
                        end
                    end
                end
            end
        end

        -- iterate through touching entities and check if they are still overlapping with the trigger
        for ent, _ in pairs(self.TouchingEntities) do
            -- if ent is no longer valid or is in the fizzling table, remove from table
            if not IsValid(ent) or self.FizzlingEntities[ent] then
                self.TouchingEntities[ent] = nil
            else
                -- if ent is not intersecting with the trigger, remove from table and call EndTouch
                if (ent:IsWeapon() or ent:IsPlayer()) then
                    local worldPos = ent:GetPos()
                    local localPos = self:WorldToLocal(worldPos)
                    if not IsPointInOBB(worldPos, worldCenter, self:GetBoundAngle(), self:GetMinBound(), self:GetMaxBound(), ent:IsPlayer()) then
                        self.TouchingEntities[ent] = nil
                        --self:EndTouch(ent)
                    end
                elseif (ent:GetClass() == "prop_ragdoll") then
                    if not AreOBBsIntersecting(self:GetPos(), self:GetMinBound(), self:GetMaxBound(), self:GetBoundAngle(), ent:GetPos(), ent:OBBMins(), ent:OBBMaxs(), ent:GetAngles()) then
                        self.TouchingEntities[ent] = nil
                    end
                end
            end
        end

        -- set up next think timer for 1/33rd of a second
        self:NextThink(CurTime() + (1 / 33))
        return true
    end
end

function IsPointInOBB(point, center, angles, mins, maxs, isPlayer)
    -- convert angles to rotation matrix
    local rot = AngleToMatrix(angles)
    --PrintTable(rot)

    -- transform point into OBB space
    --print("point: " .. tostring(point))
    --print("center: " .. tostring(center))
    local localPoint = point - center
    --print("localPoint: " .. tostring(localPoint))
    local localPointRotated = Vector(
        rot[1]:Dot(localPoint),
        rot[2]:Dot(localPoint),
        rot[3]:Dot(localPoint)
    )
    -- debugoverlay.Sphere(center, 5, 300, Color(0, 255, 0), true)
    -- debugoverlay.Sphere(point, 5, 300, Color(0, 255, 255), true)


    -- check if point is inside OBB
    local isInOBB = localPointRotated.x >= mins.x and localPointRotated.x <= maxs.x
            and localPointRotated.y >= mins.y and localPointRotated.y <= maxs.y
            and localPointRotated.z >= mins.z and localPointRotated.z <= maxs.z
    -- if isInOBB then
    --     debugoverlay.Cross(center + localPointRotated, 10, 300, Color(0, 0, 255), true)
    -- end
    return isInOBB
end

function AreOBBsIntersecting(obb1Center, obb1Min, obb1Max, obb1Angles, obb2Center, obb2Min, obb2Max, obb2Angles)
    -- convert angles to rotation matrices
    local rot1 = AngleToMatrix(obb1Angles)
    local rot2 = AngleToMatrix(obb2Angles)

    -- calculate the axes of the first OBB
    local axes1 = {
        rot1[1],
        rot1[2],
        rot1[3]
    }

    -- calculate the axes of the second OBB
    local axes2 = {
        rot2[1],
        rot2[2],
        rot2[3]
    }

    -- calculate the vectors between the centers of the two OBBs
    local centerVec = obb2Center - obb1Center

    -- iterate over the axes of the first OBB
    for _, axis1 in ipairs(axes1) do
        -- project the center vector onto the axis
        local projection = centerVec:Dot(axis1)

        -- project the first OBB onto the axis
        local obb1Projection = {
            axis1:Dot(rot1[1] * obb1Min.x + rot1[2] * obb1Min.y + rot1[3] * obb1Min.z),
            axis1:Dot(rot1[1] * obb1Max.x + rot1[2] * obb1Min.y + rot1[3] * obb1Min.z),
            axis1:Dot(rot1[1] * obb1Min.x + rot1[2] * obb1Max.y + rot1[3] * obb1Min.z),
            axis1:Dot(rot1[1] * obb1Min.x + rot1[2] * obb1Min.y + rot1[3] * obb1Max.z),
            axis1:Dot(rot1[1] * obb1Max.x + rot1[2] * obb1Max.y + rot1[3] * obb1Min.z),
            axis1:Dot(rot1[1] * obb1Max.x + rot1[2] * obb1Min.y + rot1[3] * obb1Max.z),
            axis1:Dot(rot1[1] * obb1Min.x + rot1[2] * obb1Max.y + rot1[3] * obb1Max.z),
            axis1:Dot(rot1[1] * obb1Max.x + rot1[2] * obb1Max.y + rot1[3] * obb1Max.z)
        }

        -- project the second OBB onto the axis
        local obb2Projection = {
            axis1:Dot(rot2[1] * obb2Min.x + rot2[2] * obb2Min.y + rot2[3] * obb2Min.z),
            axis1:Dot(rot2[1] * obb2Max.x + rot2[2] * obb2Min.y + rot2[3] * obb2Min.z),
            axis1:Dot(rot2[1] * obb2Min.x + rot2[2] * obb2Max.y + rot2[3] * obb2Min.z),
            axis1:Dot(rot2[1] * obb2Min.x + rot2[2] * obb2Min.y + rot2[3] * obb2Max.z),
            axis1:Dot(rot2[1] * obb2Max.x + rot2[2] * obb2Max.y + rot2[3] * obb2Min.z),
            axis1:Dot(rot2[1] * obb2Max.x + rot2[2] * obb2Min.y + rot2[3] * obb2Max.z),
            axis1:Dot(rot2[1] * obb2Min.x + rot2[2] * obb2Max.y + rot2[3] * obb2Max.z),
            axis1:Dot(rot2[1] * obb2Max.x + rot2[2] * obb2Max.y + rot2[3] * obb2Max.z)
        }

        -- calculate the minimum and maximum projections of the two OBBs onto the axis
        local obb1MinProjection = math.min(unpack(obb1Projection))
        local obb1MaxProjection = math.max(unpack(obb1Projection))
        local obb2MinProjection = math.min(unpack(obb2Projection))
        local obb2MaxProjection = math.max(unpack(obb2Projection))

        -- check if the projections overlap
        if obb1MaxProjection < obb2MinProjection or obb2MaxProjection < obb1MinProjection then
            return false
        end
    end

    -- iterate over the axes of the second OBB
    for _, axis2 in ipairs(axes2) do
        -- project the center vector onto the axis
        local projection = centerVec:Dot(axis2)

        -- project the first OBB onto the axis
        local obb1Projection = {
            axis2:Dot(rot1[1] * obb1Min.x + rot1[2] * obb1Min.y + rot1[3] * obb1Min.z),
            axis2:Dot(rot1[1] * obb1Max.x + rot1[2] * obb1Min.y + rot1[3] * obb1Min.z),
            axis2:Dot(rot1[1] * obb1Min.x + rot1[2] * obb1Max.y + rot1[3] * obb1Min.z),
            axis2:Dot(rot1[1] * obb1Min.x + rot1[2] * obb1Min.y + rot1[3] * obb1Max.z),
            axis2:Dot(rot1[1] * obb1Max.x + rot1[2] * obb1Max.y + rot1[3] * obb1Min.z),
            axis2:Dot(rot1[1] * obb1Max.x + rot1[2] * obb1Min.y + rot1[3] * obb1Max.z),
            axis2:Dot(rot1[1] * obb1Min.x + rot1[2] * obb1Max.y + rot1[3] * obb1Max.z),
            axis2:Dot(rot1[1] * obb1Max.x + rot1[2] * obb1Max.y + rot1[3] * obb1Max.z)
        }

        -- project the second OBB onto the axis
        local obb2Projection = {
            axis2:Dot(rot2[1] * obb2Min.x + rot2[2] * obb2Min.y + rot2[3] * obb2Min.z),
            axis2:Dot(rot2[1] * obb2Max.x + rot2[2] * obb2Min.y + rot2[3] * obb2Min.z),
            axis2:Dot(rot2[1] * obb2Min.x + rot2[2] * obb2Max.y + rot2[3] * obb2Min.z),
            axis2:Dot(rot2[1] * obb2Min.x + rot2[2] * obb2Min.y + rot2[3] * obb2Max.z),
            axis2:Dot(rot2[1] * obb2Max.x + rot2[2] * obb2Max.y + rot2[3] * obb2Min.z),
            axis2:Dot(rot2[1] * obb2Max.x + rot2[2] * obb2Min.y + rot2[3] * obb2Max.z),
            axis2:Dot(rot2[1] * obb2Min.x + rot2[2] * obb2Max.y + rot2[3] * obb2Max.z),
            axis2:Dot(rot2[1] * obb2Max.x + rot2[2] * obb2Max.y + rot2[3] * obb2Max.z)
        }

        -- calculate the minimum and maximum projections of the two OBBs onto the axis
        local obb1MinProjection = math.min(unpack(obb1Projection))
        local obb1MaxProjection = math.max(unpack(obb1Projection))
        local obb2MinProjection = math.min(unpack(obb2Projection))
        local obb2MaxProjection = math.max(unpack(obb2Projection))

        -- check if the projections overlap
        if obb1MaxProjection < obb2MinProjection or obb2MaxProjection < obb1MinProjection then
            return false
        end
    end

    -- if all axes overlap, the OBBs are intersecting
    return true
end

function TraceOBB(traceStart, traceEnd, obbCenter, obbMin, obbMax, obbAngles)
    local obbRot = Matrix()
    obbRot:SetAngles(obbAngles)
    local localStart = traceStart - obbCenter
    --debugoverlay.Cross(traceStart, 10, 60, Color(255, 0, 0), true)
    local localEnd = traceEnd - obbCenter
    --debugoverlay.Cross(traceEnd, 10, 60, Color(255, 0, 0), true)
    local localStartRotated = Vector()
    localStartRotated.x = localStart.x * obbRot:GetForward().x + localStart.y * obbRot:GetForward().y + localStart.z * obbRot:GetForward().z
    localStartRotated.y = localStart.x * obbRot:GetRight().x + localStart.y * obbRot:GetRight().y + localStart.z * obbRot:GetRight().z
    localStartRotated.z = localStart.x * obbRot:GetUp().x + localStart.y * obbRot:GetUp().y + localStart.z * obbRot:GetUp().z
    debugoverlay.Cross(localStartRotated - obbCenter, 10, 60, Color(0, 255, 0), true)
    local localEndRotated = Vector()
    localEndRotated.x = localEnd.x * obbRot:GetForward().x + localEnd.y * obbRot:GetForward().y + localEnd.z * obbRot:GetForward().z
    localEndRotated.y = localEnd.x * obbRot:GetRight().x + localEnd.y * obbRot:GetRight().y + localEnd.z * obbRot:GetRight().z
    localEndRotated.z = localEnd.x * obbRot:GetUp().x + localEnd.y * obbRot:GetUp().y + localEnd.z * obbRot:GetUp().z
    debugoverlay.Cross(localEndRotated - obbCenter, 10, 60, Color(0, 255, 0), true)
    local worldHitPos = TraceAABB(localStartRotated, localEndRotated, obbMin, obbMax)
    if worldHitPos then
        local worldHitPosRotated = Vector()
        worldHitPosRotated.x = worldHitPos.x * obbRot:GetForward().x + worldHitPos.y * obbRot:GetRight().x + worldHitPos.z * obbRot:GetUp().x
        worldHitPosRotated.y = worldHitPos.x * obbRot:GetForward().y + worldHitPos.y * obbRot:GetRight().y + worldHitPos.z * obbRot:GetUp().y
        worldHitPosRotated.z = worldHitPos.x * obbRot:GetForward().z + worldHitPos.y * obbRot:GetRight().z + worldHitPos.z * obbRot:GetUp().z
        worldHitPosRotated = worldHitPosRotated + obbCenter
        return worldHitPosRotated
    end
    return false
end

function TraceAABB(traceStart, traceEnd, aabbMin, aabbMax)
    local dir = traceEnd - traceStart
    local tmin = Vector(0, 0, 0)
    local tmax = Vector(0, 0, 0)

    -- calculate t values for each axis
    for i = 1, 3 do
        if dir[i] >= 0 then
            tmin[i] = (aabbMin[i] - traceStart[i]) / dir[i]
            tmax[i] = (aabbMax[i] - traceStart[i]) / dir[i]
        else
            tmin[i] = (aabbMax[i] - traceStart[i]) / dir[i]
            tmax[i] = (aabbMin[i] - traceStart[i]) / dir[i]
        end
    end

    -- find largest tmin and smallest tmax
    local largestTmin = math.max(tmin.x, tmin.y, tmin.z)
    local smallestTmax = math.min(tmax.x, tmax.y, tmax.z)

    -- check for intersection
    if smallestTmax >= largestTmin then
        local hitPos = traceStart + dir * largestTmin
        return hitPos
    end

    return false
end

function AngleToMatrix(ang)
    local matrix = {}
    local sinPitch = math.sin(math.rad(ang.p))
    local cosPitch = math.cos(math.rad(ang.p))
    local sinYaw = math.sin(math.rad(ang.y))
    local cosYaw = math.cos(math.rad(ang.y))
    local sinRoll = math.sin(math.rad(ang.r))
    local cosRoll = math.cos(math.rad(ang.r))

    matrix[1] = Vector(cosYaw * cosRoll, sinYaw * cosRoll, -sinRoll)
    matrix[2] = Vector(cosYaw * sinRoll * sinPitch - sinYaw * cosPitch, sinYaw * sinRoll * sinPitch + cosYaw * cosPitch, cosRoll * sinPitch)
    matrix[3] = Vector(cosYaw * sinRoll * cosPitch + sinYaw * sinPitch, sinYaw * sinRoll * cosPitch - cosYaw * sinPitch, cosRoll * cosPitch)

    return matrix
end

function ENT:FlingEnt(ent, player, this)
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

function ENT:FizzleEnt(ent, player)
    local propEnt = ent
    if (ent:GetClass() ~= "prop_ragdoll") then 
        -- get the world model of the weapon
        local ent_worldmodel = ent:GetModel()
        local spawnpos = nil
        local newVel = nil
        local propType = "prop_physics"
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
        propEnt = prop
        propEnt:SetPos(spawnpos)
        -- make prop drift forward with random deviation and spin slowly with randommness
        propEnt:GetPhysicsObject():SetVelocity(newVel)
    else
        propEnt:SetParent(nil)
        -- push ragdoll up toward the sky
        propEnt:SetVelocity(Vector(0, 0, 500))
        -- make ragdoll's bones have no gravity
        for i = 0, propEnt:GetPhysicsObjectCount() - 1 do
            local bone = propEnt:GetPhysicsObjectNum(i)
            if IsValid(bone) then
                bone:EnableGravity(false)
            end
        end
        -- find all weapon_zm_carry entities on players
        local carryEnts = ents.FindByClass("weapon_zm_carry")
        -- find the weapon_zm_carry entity that has EntHolding = propEnt
        for k, v in pairs(carryEnts) do
            if v.EntHolding == propEnt then
                -- set EntHolding to nil
                v.EntHolding = nil
            end
        end
        -- make this ragdoll unsearchable by adding NW bool FizzleRagdoll
        propEnt:SetNWBool("FizzleRagdoll", true)
    end

    -- make prop black
    propEnt:SetMaterial("models/debug/debugwhite")
    propEnt:SetColor(Color(0, 0, 0, 255))
    propEnt:GetPhysicsObject():ApplyTorqueCenter(VectorRand() * 10)
    -- make prop collide with nothing
    propEnt:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    propEnt:GetPhysicsObject():EnableGravity(false)

    -- add prop to fizzling table so that this function is not called again.
    self:FizzlingEntities[propEnt] = true

    -- create an env_spark attached to the prop
    local spark = ents.Create("env_spark")
    print("Created prop fizzle spark")
    spark:Spawn()
    spark:Activate()
    spark:SetPos(propEnt:GetPos())
    spark:SetKeyValue("MaxDelay", "0.8")
    spark:SetKeyValue("Magnitude", "2")
    spark:SetKeyValue("TrailLength", "2")
    spark:SetParent(propEnt)
    spark:Input("StartSpark", NULL, NULL, NULL)

    -- remove prop after CVAR ttt_grill_fizzle_duration seconds
    timer.Simple(GetConVar("ttt_grill_fizzle_duration"):GetInt(), function()
        if IsValid(propEnt) then
            -- remove prop from fizzling table
            self:FizzlingEntities[propEnt] = nil
            propEnt:Remove()
        end
    end)
end