-- Author pkillboredom 2023

-- Defaults for Emancipation Grill.
local grill_delay_time           = 10 -- Time in seconds before the Emancipation Grill activates after placement.
local grill_fizzle_duration      = 4 -- Time in seconds that it takes for the Emancipation Grill to fizzle an object.
local grill_idle_volume          = 10 -- Volume of the Emancipation Grill's idle sound.
local grill_fizzle_volume        = 60 -- Volume of the Emancipation Grill's fizzle sound.
local grill_fizzle_limit         = 0 -- Number of times the grill may fizzle (not including projectiles and grenade ents) before breaking. 0 for infinite.
local grill_active_timer         = 0 -- Time in seconds that the Emancipation Grill will work before breaking. 0 for infinite.
local grill_max_distance         = 144 -- Maximum distance in hammer units that the emancipation grill can span.
--local grill_height               = 60 -- Height of the Emancipation Grill in Hammer Units.

local grill_fizzle_weapons       = 1 -- Boolean which controls whether the Grill fizzles weapons.
local grill_fling_weapons        = 0 -- Boolean which controls whether the Grill flings weapons. Requires ttt_grill_fizzle_weapons to be 1.
local grill_fizzle_corpses       = 1 -- Boolean which controls whether the Grill fizzles corpses.
local grill_fizzle_props         = 0 -- Boolean which controls whether the Grill fizzles props.
local grill_fizzle_projectiles   = 1 -- Boolean which controls whether the Grill fizzles projectiles.
local grill_fizzle_grenade_ents  = 1 -- Boolean which controls whether the Grill fizzles grenades.
local grill_fizzle_own_team      = 0 -- Boolean which controls whether the Grill fizzles the owner's team's weapons. Requires ttt_grill_fizzle_weapons to be 1.

local grill_fizzle_pistols       = 1 -- Boolean which controls whether the Grill fizzles pistols. Requires ttt_grill_fizzle_weapons to be 1.
local grill_fizzle_rifles        = 1 -- Boolean which controls whether the Grill fizzles rifles. Requires ttt_grill_fizzle_weapons to be 1.
local grill_fizzle_grenade_weaps = 1 -- Boolean which controls whether the Grill fizzles grenades (in inventory). Requires ttt_grill_fizzle_weapons to be 1.
local grill_fizzle_extra         = 1 -- Boolean which controls whether the Grill fizzles extra weapons. Requires ttt_grill_fizzle_weapons to be 1.
local grill_fizzle_special       = 1 -- Boolean which controls whether the Grill fizzles special weapons. Requires ttt_grill_fizzle_weapons to be 1.
local grill_fizzle_dna_scanner   = 0 -- Boolean which controls whether the Grill fizzles the DNA Scanner. Overrides grill_fizzle_special. Requires ttt_grill_fizzle_weapons to be 1.

-- Create Con Vars
CreateConVar("ttt_grill_delay_time", grill_delay_time, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fizzle_duration", grill_fizzle_duration, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_idle_volume", grill_idle_volume, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fizzle_volume", grill_fizzle_volume, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fizzle_limit", grill_fizzle_limit, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_active_timer", grill_active_timer, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_max_distance", grill_max_distance, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
--CreateConVar("ttt_grill_height", grill_height, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fizzle_weapons", grill_fizzle_weapons, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fling_weapons", grill_fling_weapons, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fizzle_corpses", grill_fizzle_corpses, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fizzle_props", grill_fizzle_props, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fizzle_projectiles", grill_fizzle_projectiles, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fizzle_grenade_ents", grill_fizzle_grenade_ents, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fizzle_own_team", grill_fizzle_own_team, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fizzle_pistols", grill_fizzle_pistols, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fizzle_rifles", grill_fizzle_rifles, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fizzle_grenade_weaps", grill_fizzle_grenade_weaps, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fizzle_extra", grill_fizzle_extra, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fizzle_special", grill_fizzle_special, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar("ttt_grill_fizzle_dna_scanner", grill_fizzle_dna_scanner, {FCVAR_NOTIFY, FCVAR_ARCHIVE})

-- Set-up ULX ConVars
hook.Add('TTTUlxInitCustomCVar', 'TTTEmancipationGrillInitRWCvar', function(name)
    ULib.replicatedWritableCvar('ttt_grill_delay_time', 'rep_ttt_grill_delay_time', GetConVar('ttt_grill_delay_time'):GetInt(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fizzle_duration', 'rep_ttt_grill_fizzle_duration', GetConVar('ttt_grill_fizzle_duration'):GetInt(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_idle_volume', 'rep_ttt_grill_idle_volume', GetConVar('ttt_grill_idle_volume'):GetInt(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fizzle_volume', 'rep_ttt_grill_fizzle_volume', GetConVar('ttt_grill_fizzle_volume'):GetInt(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fizzle_limit', 'rep_ttt_grill_fizzle_limit', GetConVar('ttt_grill_fizzle_limit'):GetInt(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_active_timer', 'rep_ttt_grill_active_timer', GetConVar('ttt_grill_active_timer'):GetInt(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_max_distance', 'rep_ttt_grill_max_distance', GetConVar('ttt_grill_max_distance'):GetInt(), true, false, name)
    --ULib.replicatedWritableCvar('ttt_grill_height', 'rep_ttt_grill_height', GetConVar('ttt_grill_height'):GetInt(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fizzle_weapons', 'rep_ttt_grill_fizzle_weapons', GetConVar('ttt_grill_fizzle_weapons'):GetBool(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fling_weapons', 'rep_ttt_grill_fling_weapons', GetConVar('ttt_grill_fling_weapons'):GetBool(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fizzle_corpses', 'rep_ttt_grill_fizzle_corpses', GetConVar('ttt_grill_fizzle_corpses'):GetBool(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fizzle_props', 'rep_ttt_grill_fizzle_props', GetConVar('ttt_grill_fizzle_props'):GetBool(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fizzle_projectiles', 'rep_ttt_grill_fizzle_projectiles', GetConVar('ttt_grill_fizzle_projectiles'):GetBool(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fizzle_grenade_ents', 'rep_ttt_grill_fizzle_grenade_ents', GetConVar('ttt_grill_fizzle_grenade_ents'):GetBool(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fizzle_own_team', 'rep_ttt_grill_fizzle_own_team', GetConVar('ttt_grill_fizzle_own_team'):GetBool(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fizzle_pistols', 'rep_ttt_grill_fizzle_pistols', GetConVar('ttt_grill_fizzle_pistols'):GetBool(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fizzle_rifles', 'rep_ttt_grill_fizzle_rifles', GetConVar('ttt_grill_fizzle_rifles'):GetBool(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fizzle_grenade_weaps', 'rep_ttt_grill_fizzle_grenade_weaps', GetConVar('ttt_grill_fizzle_grenade_weaps'):GetBool(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fizzle_extra', 'rep_ttt_grill_fizzle_extra', GetConVar('ttt_grill_fizzle_extra'):GetBool(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fizzle_special', 'rep_ttt_grill_fizzle_special', GetConVar('ttt_grill_fizzle_special'):GetBool(), true, false, name)
    ULib.replicatedWritableCvar('ttt_grill_fizzle_dna_scanner', 'rep_ttt_grill_fizzle_dna_scanner', GetConVar('ttt_grill_fizzle_dna_scanner'):GetBool(), true, false, name)
end)

if SERVER then
    AddCSLuaFile()

    -- A billion years of CVar replication boilerplate follows...
    -- (I have no idea if this is needed in 2023, but the TTT item/swep I am referencing does it.
    -- Thanks to https:--github.com/BadgerCode/TTT-Barnacle)
    hook.Add("TTT2SyncGlobals", "ttt_emancipation_grill_sync_convars", function()
        SetGlobalInt("ttt_grill_delay_time", GetConVar("ttt_grill_delay_time"):GetInt())
        SetGlobalInt("ttt_grill_fizzle_duration", GetConVar("ttt_grill_fizzle_duration"):GetInt())
        SetGlobalInt("ttt_grill_idle_volume", GetConVar("ttt_grill_idle_volume"):GetInt())
        SetGlobalInt("ttt_grill_fizzle_volume", GetConVar("ttt_grill_fizzle_volume"):GetInt())
        SetGlobalInt("ttt_grill_fizzle_limit", GetConVar("ttt_grill_fizzle_limit"):GetInt())
        SetGlobalInt("ttt_grill_active_timer", GetConVar("ttt_grill_active_timer"):GetInt())
        SetGlobalInt("ttt_grill_max_distance", GetConVar("ttt_grill_max_distance"):GetInt())
        --SetGlobalInt("ttt_grill_height", GetConVar("ttt_grill_height"):GetInt())
        SetGlobalInt("ttt_grill_fizzle_weapons", GetConVar("ttt_grill_fizzle_weapons"):GetBool())
        SetGlobalInt("ttt_grill_fling_weapons", GetConVar("ttt_grill_fling_weapons"):GetBool())
        SetGlobalInt("ttt_grill_fizzle_corpses", GetConVar("ttt_grill_fizzle_corpses"):GetBool())
        SetGlobalInt("ttt_grill_fizzle_props", GetConVar("ttt_grill_fizzle_props"):GetBool())
        SetGlobalInt("ttt_grill_fizzle_projectiles", GetConVar("ttt_grill_fizzle_projectiles"):GetBool())
        SetGlobalInt("ttt_grill_fizzle_grenade_ents", GetConVar("ttt_grill_fizzle_grenade_ents"):GetBool())
        SetGlobalInt("ttt_grill_fizzle_own_team", GetConVar("ttt_grill_fizzle_own_team"):GetBool())
        SetGlobalInt("ttt_grill_fizzle_pistols", GetConVar("ttt_grill_fizzle_pistols"):GetBool())
        SetGlobalInt("ttt_grill_fizzle_rifles", GetConVar("ttt_grill_fizzle_rifles"):GetBool())
        SetGlobalInt("ttt_grill_fizzle_grenade_weaps", GetConVar("ttt_grill_fizzle_grenade_weaps"):GetBool())
        SetGlobalInt("ttt_grill_fizzle_extra", GetConVar("ttt_grill_fizzle_extra"):GetBool())
        SetGlobalInt("ttt_grill_fizzle_special", GetConVar("ttt_grill_fizzle_special"):GetBool())
        SetGlobalInt("ttt_grill_fizzle_dna_scanner", GetConVar("ttt_grill_fizzle_dna_scanner"):GetBool())

        cvars.AddChangeCallback("ttt_grill_delay_time", function(cv, old, new)
            SetGlobalInt("ttt_grill_delay_time", tonumber(new))
        end)
        cvars.AddChangeCallback("ttt_grill_fizzle_duration", function(cv, old, new)
            SetGlobalInt("ttt_grill_fizzle_duration", tonumber(new))
        end)
        cvars.AddChangeCallback("ttt_grill_idle_volume", function(cv, old, new)
            SetGlobalInt("ttt_grill_idle_volume", tonumber(new))
        end)
        cvars.AddChangeCallback("ttt_grill_fizzle_volume", function(cv, old, new)
            SetGlobalInt("ttt_grill_fizzle_volume", tonumber(new))
        end)
        cvars.AddChangeCallback("ttt_grill_fizzle_limit", function(cv, old, new)
            SetGlobalInt("ttt_grill_fizzle_limit", tonumber(new))
        end)
        cvars.AddChangeCallback("ttt_grill_active_timer", function(cv, old, new)
            SetGlobalInt("ttt_grill_active_timer", tonumber(new))
        end)
        cvars.AddChangeCallback("ttt_grill_max_distance", function(cv, old, new)
            SetGlobalInt("ttt_grill_max_distance", tonumber(new))
        end)
        -- cvars.AddChangeCallback("ttt_grill_height", function(cv, old, new)
        --     SetGlobalInt("ttt_grill_height", tonumber(new))
        -- end)
        cvars.AddChangeCallback("ttt_grill_fizzle_weapons", function(cv, old, new)
            SetGlobalInt("ttt_grill_fizzle_weapons", tobool(new))
        end)
        cvars.AddChangeCallback("ttt_grill_fling_weapons", function(cv, old, new)
            SetGlobalInt("ttt_grill_fling_weapons", tobool(new))
        end)
        cvars.AddChangeCallback("ttt_grill_fizzle_corpses", function(cv, old, new)
            SetGlobalInt("ttt_grill_fizzle_corpses", tobool(new))
        end)
        cvars.AddChangeCallback("ttt_grill_fizzle_props", function(cv, old, new)
            SetGlobalInt("ttt_grill_fizzle_props", tobool(new))
        end)
        cvars.AddChangeCallback("ttt_grill_fizzle_projectiles", function(cv, old, new)
            SetGlobalInt("ttt_grill_fizzle_projectiles", tobool(new))
        end)
        cvars.AddChangeCallback("ttt_grill_fizzle_grenade_ents", function(cv, old, new)
            SetGlobalInt("ttt_grill_fizzle_grenade_ents", tobool(new))
        end)
        cvars.AddChangeCallback("ttt_grill_fizzle_own_team", function(cv, old, new)
            SetGlobalInt("ttt_grill_fizzle_own_team", tobool(new))
        end)
        cvars.AddChangeCallback("ttt_grill_fizzle_pistols", function(cv, old, new)
            SetGlobalInt("ttt_grill_fizzle_pistols", tobool(new))
        end)
        cvars.AddChangeCallback("ttt_grill_fizzle_rifles", function(cv, old, new)
            SetGlobalInt("ttt_grill_fizzle_rifles", tobool(new))
        end)
        cvars.AddChangeCallback("ttt_grill_fizzle_grenade_weaps", function(cv, old, new)
            SetGlobalInt("ttt_grill_fizzle_grenade_weaps", tobool(new))
        end)
        cvars.AddChangeCallback("ttt_grill_fizzle_extra", function(cv, old, new)
            SetGlobalInt("ttt_grill_fizzle_extra", tobool(new))
        end)
        cvars.AddChangeCallback("ttt_grill_fizzle_special", function(cv, old, new)
            SetGlobalInt("ttt_grill_fizzle_special", tobool(new))
        end)
        cvars.AddChangeCallback("ttt_grill_fizzle_dna_scanner", function(cv, old, new)
            SetGlobalInt("ttt_grill_fizzle_dna_scanner", tobool(new))
        end)

    end)
end    

if CLIENT then
    hook.Add('TTTUlxModifyAddonsSettings', 'TTTEmancipationGrillModifySettings', function(name)
        local optionHeight = 30
        local grillSettingsPanel = xlib.makelistlayout{w = 415, h = 318, parent = xgui.null}

        local basicSettingsCollapse = vgui.Create("DCollapsibleCategory", grillSettingsPanel)
        basicSettingsCollapse:SetSize(390, 100)
        basicSettingsCollapse:SetExpanded(1)
        basicSettingsCollapse:SetLabel("Basic Settings")

        local basicSettingsPanelList = vgui.Create("DPanelList", basicSettingsCollapse)
        basicSettingsPanelList:SetPos(5, 25)
        basicSettingsPanelList:SetSize(390, 8 * optionHeight)
        --basicSettingsPanelList:SetSize(390, 7 * optionHeight)
        basicSettingsPanelList:SetSpacing(5)

        basicSettingsPanelList:AddItem(xlib.makeslider{
            label = "Grill Start Delay Time", 
            tooltip = "Time in seconds before the Emancipation Grill activates after placement.\n[ttt_grill_delay_time (default: " .. grill_delay_time .. ")]",
            repconvar = "rep_ttt_grill_delay_time", 
            min = 0, 
            max = 60, 
            parent = basicSettingsPanelList
        })

        basicSettingsPanelList:AddItem(xlib.makeslider{
            label = "Grill Fizzle Duration", 
            tooltip = "Time in seconds that it takes for the Emancipation Grill to fizzle an object.\n[ttt_grill_fizzle_duration (default: " .. grill_fizzle_duration .. ")]",
            repconvar = "rep_ttt_grill_fizzle_duration", 
            min = 0, 
            max = 20, 
            parent = basicSettingsPanelList
        })
        
        basicSettingsPanelList:AddItem(xlib.makeslider{
            label = "Grill Idle Volume", 
            tooltip = "Volume of the Emancipation Grill when it is idle.\n[ttt_grill_idle_volume (default: " .. grill_idle_volume .. ")]",
            repconvar = "rep_ttt_grill_idle_volume", 
            min = 0, 
            max = 300, 
            parent = basicSettingsPanelList
        })

        basicSettingsPanelList:AddItem(xlib.makeslider{
            label = "Grill Fizzle Volume", 
            tooltip = "Volume of the Emancipation Grill's fizzle sound.\n[ttt_grill_fizzle_volume (default: " .. grill_fizzle_volume .. ")]",
            repconvar = "rep_ttt_grill_fizzle_volume", 
            min = 0, 
            max = 300, 
            parent = basicSettingsPanelList
        })

        basicSettingsPanelList:AddItem(xlib.makeslider{
            label = "Grill Fizzle Limit", 
            tooltip = "Number of times the grill may fizzle (not including projectiles and grenade ents) before breaking. 0 for infinite.\n[ttt_grill_fizzle_limit (default: " .. grill_fizzle_limit .. ")]",
            repconvar = "rep_ttt_grill_fizzle_limit", 
            min = 0, 
            max = 20, 
            parent = basicSettingsPanelList
        })

        basicSettingsPanelList:AddItem(xlib.makeslider{
            label = "Grill Active Timer", 
            tooltip = "Time in seconds that the Emancipation Grill will work before breaking. 0 for infinite.\n[ttt_grill_active_timer (default: " .. grill_active_timer .. ")]",
            repconvar = "rep_ttt_grill_active_timer", 
            min = 0, 
            max = 240, 
            parent = basicSettingsPanelList
        })

        -- max_distance
        basicSettingsPanelList:AddItem(xlib.makeslider{
            label = "Grill Max Distance", 
            tooltip = "Maximum distance in HU that the Emancipation Grill can span.\n[ttt_grill_max_distance (default: " .. grill_max_distance .. ")]",
            repconvar = "rep_ttt_grill_max_distance", 
            min = 0, 
            max = 400, 
            parent = basicSettingsPanelList
        })

        -- -- height
        -- basicSettingsPanelList:AddItem(xlib.makeslider{
        --     label = "Grill Height", 
        --     tooltip = "Height of the Emancipation Grill. Gordon Freeman is 72 HU tall.\n[ttt_grill_height (default: " .. grill_height .. ")]",
        --     repconvar = "rep_ttt_grill_height", 
        --     min = 0, 
        --     max = 200, 
        --     parent = basicSettingsPanelList
        -- })

        local fizzleSettingsCollapse = vgui.Create("DCollapsibleCategory", grillSettingsPanel)
        fizzleSettingsCollapse:SetSize(390, 100)
        fizzleSettingsCollapse:SetExpanded(1)
        fizzleSettingsCollapse:SetLabel("Fizzle Settings")

        local fizzleSettingsPanelList = vgui.Create("DPanelList", fizzleSettingsCollapse)
        fizzleSettingsPanelList:SetPos(5, 25)
        fizzleSettingsPanelList:SetSize(390, 6 * optionHeight)
        fizzleSettingsPanelList:SetSpacing(5)
        
        -- weapons
        fizzleSettingsPanelList:AddItem(xlib.makecheckbox{
            label = "Fizzle Weapons?", 
            tooltip = "Boolean which controls whether the Grill fizzles weapons.\n[ttt_grill_fizzle_weapons (default: " .. grill_fizzle_weapons .. ")]",
            repconvar = "rep_ttt_grill_fizzle_weapons", 
            parent = fizzleSettingsPanelList
        })

        -- corpses
        fizzleSettingsPanelList:AddItem(xlib.makecheckbox{
            label = "Fizzle Corpses?", 
            tooltip = "Boolean which controls whether the Grill fizzles corpses.\n[ttt_grill_fizzle_corpses (default: " .. grill_fizzle_corpses .. ")]",
            repconvar = "rep_ttt_grill_fizzle_corpses", 
            parent = fizzleSettingsPanelList
        })

        -- props
        fizzleSettingsPanelList:AddItem(xlib.makecheckbox{
            label = "Fizzle Props?", 
            tooltip = "Boolean which controls whether the Grill fizzles props.\n[ttt_grill_fizzle_props (default: " .. grill_fizzle_props .. ")]",
            repconvar = "rep_ttt_grill_fizzle_props", 
            parent = fizzleSettingsPanelList
        })

        --projectiles
        fizzleSettingsPanelList:AddItem(xlib.makecheckbox{
            label = "Fizzle Projectiles?", 
            tooltip = "Boolean which controls whether the Grill fizzles projectiles.\n[ttt_grill_fizzle_projectiles (default: " .. grill_fizzle_projectiles .. ")]",
            repconvar = "rep_ttt_grill_fizzle_projectiles", 
            parent = fizzleSettingsPanelList
        })

        -- grenade_ents
        fizzleSettingsPanelList:AddItem(xlib.makecheckbox{
            label = "Fizzle Grenade Ents?", 
            tooltip = "Boolean which controls whether the Grill fizzles grenade ents (live grenades).\n[ttt_grill_fizzle_grenade_ents (default: " .. grill_fizzle_grenade_ents .. ")]",
            repconvar = "rep_ttt_grill_fizzle_grenade_ents", 
            parent = fizzleSettingsPanelList
        })

        -- own_team
        fizzleSettingsPanelList:AddItem(xlib.makecheckbox{
            label = "Fizzle Own Team?", 
            tooltip = "Boolean which controls whether the Grill affects members of the team that placed it.\n[ttt_grill_fizzle_own_team (default: " .. grill_fizzle_own_team .. ")]",
            repconvar = "rep_ttt_grill_fizzle_own_team", 
            parent = fizzleSettingsPanelList
        })

        local fizzleInventorySettingsCollapse = vgui.Create("DCollapsibleCategory", grillSettingsPanel)
        fizzleInventorySettingsCollapse:SetSize(390, 100)
        fizzleInventorySettingsCollapse:SetExpanded(0)
        fizzleInventorySettingsCollapse:SetLabel("Fizzle Inventory Settings")

        local fizzleInventorySettingsPanelList = vgui.Create("DPanelList", fizzleInventorySettingsCollapse)
        fizzleInventorySettingsPanelList:SetPos(5, 25)
        fizzleInventorySettingsPanelList:SetSize(390, 7 * optionHeight)
        fizzleInventorySettingsPanelList:SetSpacing(5)

        fizzleInventorySettingsPanelList:AddItem(xlib.makecheckbox{
            label = "Fling Instead?",
            tooltip = "Boolean which controls whether the Grill flings items instead of fizzling them.\n[ttt_grill_fling_instead (default: " .. grill_fling_instead .. ")]",
            repconvar = "rep_ttt_grill_fling_weapons",
            parent = fizzleInventorySettingsPanelList
        })

        -- pistols
        fizzleInventorySettingsPanelList:AddItem(xlib.makecheckbox{
            label = "Fizzle Pistols?", 
            tooltip = "Boolean which controls whether the Grill fizzles pistols.\n[ttt_grill_fizzle_pistols (default: " .. grill_fizzle_pistols .. ")]",
            repconvar = "rep_ttt_grill_fizzle_pistols", 
            parent = fizzleInventorySettingsPanelList
        })

        -- rifles (and all other slot 2 items)
        fizzleInventorySettingsPanelList:AddItem(xlib.makecheckbox{
            label = "Fizzle Rifles/Shotguns/SMG/Etc?", 
            tooltip = "Boolean which controls whether the Grill fizzles primary weapons.\n[ttt_grill_fizzle_rifles (default: " .. grill_fizzle_rifles .. ")]",
            repconvar = "rep_ttt_grill_fizzle_rifles", 
            parent = fizzleInventorySettingsPanelList
        })

        -- grenade_weaps
        fizzleInventorySettingsPanelList:AddItem(xlib.makecheckbox{
            label = "Fizzle Grenade Weaps?", 
            tooltip = "Boolean which controls whether the Grill fizzles grenade weapons.\n[ttt_grill_fizzle_grenade_weaps (default: " .. grill_fizzle_grenade_weaps .. ")]",
            repconvar = "rep_ttt_grill_fizzle_grenade_weaps", 
            parent = fizzleInventorySettingsPanelList
        })

        -- extra
        fizzleInventorySettingsPanelList:AddItem(xlib.makecheckbox{
            label = "Fizzle Extra?", 
            tooltip = "Boolean which controls whether the Grill fizzles extra slot weapons.\n[ttt_grill_fizzle_extra (default: " .. grill_fizzle_extra .. ")]",
            repconvar = "rep_ttt_grill_fizzle_extra", 
            parent = fizzleInventorySettingsPanelList
        })

        -- special
        fizzleInventorySettingsPanelList:AddItem(xlib.makecheckbox{
            label = "Fizzle Special?", 
            tooltip = "Boolean which controls whether the Grill fizzles special slot weapons.\n[ttt_grill_fizzle_special (default: " .. grill_fizzle_special .. ")]",
            repconvar = "rep_ttt_grill_fizzle_special", 
            parent = fizzleInventorySettingsPanelList
        })

        -- dna_scanner
        fizzleInventorySettingsPanelList:AddItem(xlib.makecheckbox{
            label = "Fizzle DNA Scanner?", 
            tooltip = "Boolean which controls whether the Grill fizzles DNA scanners. This overrides Fizzle Special.\n[ttt_grill_fizzle_dna_scanner (default: " .. grill_fizzle_dna_scanner .. ")]",
            repconvar = "rep_ttt_grill_fizzle_dna_scanner", 
            parent = fizzleInventorySettingsPanelList
        })

        xgui.hookEvent("onProcessModules", nil, grillSettingsPanel.processModules)
        xgui.addSubModule("Emancipation Grill", grillSettingsPanel, nil, name)
    end)
end