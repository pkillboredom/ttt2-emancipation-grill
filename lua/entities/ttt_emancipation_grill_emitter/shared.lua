-- Author pkillboredom 2023

if SERVER then
    AddCSLuaFile()
end

ENT.Type = "anim"

ENT.ClassName = "ttt_emancipation_grill_emitter"
ENT.PrintName = "Emancipation Grill Emitter"
ENT.Author = "pkillboredom"
ENT.Spawnable = false

function ENT:Initialize()
    // set model to portal_cleanser_1.mdl
    self:SetModel("models/props/portal_cleanser_1.mdl")
    // scale to be 1/2 size x and y, CVAR ttt_grill_height for z
    --local scale = Vector(0.5, 0.5, GetConVar("ttt_grill_height"):GetInt())
    --local mat = Matrix()
    --mat:Scale(scale)
    --self:EnableMatrix("RenderMultiply", mat)
    // set as solid and unmovable
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
end