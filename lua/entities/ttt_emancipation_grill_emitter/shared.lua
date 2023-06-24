-- Author pkillboredom 2023

AddCSLuaFile()
game.AddParticles("particles/cleansers.pcf")
PrecacheParticleSystem("portal_cleanser")
-- PrecacheParticleSystem("portal_cleanser_144")
-- PrecacheParticleSystem("portal_cleanser_50")
-- PrecacheParticleSystem("portal_cleanser_72")
-- PrecacheParticleSystem("portal_cleanser_100")
-- PrecacheParticleSystem("portal_cleanser_120")

ENT.Type = "anim"

ENT.ClassName = "ttt_emancipation_grill_emitter"
ENT.PrintName = "Emancipation Grill Emitter"
ENT.Author = "pkillboredom"
ENT.Spawnable = false


-- command to spawn particles
if ( SERVER ) then
	-- A test console command to see if the particle works, spawns the particle where the player is looking at. 
	concommand.Add( "testparticle", function( ply, cmd, args )
		ParticleEffect( "portal_cleanser", ply:GetEyeTrace().HitPos, Angle( 0, 0, 0 ) )
	end )
end

function ENT:Initialize()
    thisEnt = self
    // set model to portal_cleanser_1.mdl
    self:SetModel("models/props/portal_cleanser_1.mdl")
    // set as solid and unmovable
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
end
