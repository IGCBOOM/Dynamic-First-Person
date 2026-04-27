AddCSLuaFile()

-- init global addon table
DynamicFirstPerson = DynamicFirstPerson or {}

--[[

Available Hooks:

    DFPInitialize - Shared - Called when the addon is first initialized
    DFPReload - Shared - Called when the addon is reloaded via dfp_reload

--]]

DynamicFirstPerson.Initalize = function()

    -- Init ConVars
    DynamicFirstPerson.ConVars = DynamicFirstPerson.ConVars or {}

    if CLIENT then

        -- View cvars
        DynamicFirstPerson.ConVars.ViewMode = CreateClientConVar("dfp_cl_viewmode", "2", true, true, "View mode of the addon: 0 = Disabled, 1 = Fixed, 2 = Dynamic")
        DynamicFirstPerson.ConVars.UseEyeAttach = CreateClientConVar("dfp_cl_useeyeattach", "1", true, true, "Use eye attachment instead of head bone for view height if available (will fallback to headbone if not).")

        -- Firstperson Body cvars
        DynamicFirstPerson.ConVars.FPBEnabled = CreateClientConVar("dfp_cl_fpbenabled", "1", true, true, "Enable or disable the firstperson body.")
        DynamicFirstPerson.ConVars.FPBViewOverride = CreateClientConVar("dfp_cl_fpbviewoverride", "0", true, true, "Override auto disable due to view mode. Firstperson body is automatically disabled when dynamic view mode is 0 or as it doesn't look right (FPB could clip into view).")
        DynamicFirstPerson.ConVars.FPBHideHeadAttachedBones = CreateClientConVar("dfp_cl_fpbhideheadattachedbones", "0", true, true, "Hide all bones attached to head bone (like hair, accessories, etc.).")

    end

    local SERVER_FLAGS = { 
        FCVAR_SERVER_CAN_EXECUTE,
        FCVAR_ARCHIVE,
        FCVAR_REPLICATED
    }

    -- Server/Shared cvars
    DynamicFirstPerson.ConVars.Enabled = CreateConVar("dfp_sv_enabled", "1", SERVER_FLAGS, "Enabled or disable the addon server-wide.")
    DynamicFirstPerson.ConVars.DebugMode = CreateConVar("dfp_sv_debugmode", "0", SERVER_FLAGS, "Enabled or disable debug mode for additional console printing.")
    DynamicFirstPerson.ConVars.HullResize = CreateConVar("dfp_sv_hullresize", "1", SERVER_FLAGS, "Enabled or disable resizing of the hull size to the playermodel.")
    DynamicFirstPerson.ConVars.HullXYMax = CreateConVar("dfp_sv_hullxymax", "64", SERVER_FLAGS, "Max hull size across XY axis (width/depth).")
    DynamicFirstPerson.ConVars.HullZMax = CreateConVar("dfp_sv_hullzmax", "256", SERVER_FLAGS, "Max hull size across Z axis (height).")
    DynamicFirstPerson.ConVars.HullZMaxCrouch = CreateConVar("dfp_sv_hullzmaxcrouch", "256", SERVER_FLAGS, "Max hull size across Z axis (height) while crouching.")
    DynamicFirstPerson.ConVars.HullXYMin = CreateConVar("dfp_sv_hullxymin", "8", SERVER_FLAGS, "Min hull size across XY axis (width/depth).")
    DynamicFirstPerson.ConVars.HullZMin = CreateConVar("dfp_sv_hullzmin", "6", SERVER_FLAGS, "Min hull size across Z axis (height).")
    DynamicFirstPerson.ConVars.HullZMinCrouch = CreateConVar("dfp_sv_hullzmincrouch", "6", SERVER_FLAGS, "Min hull size across Z axis (height) while crouching.")

    -- Playermodel specific saved settings
    DynamicFirstPerson.SavedPlyMdlSettings = DynamicFirstPerson.SavedPlyMdlSettings or {}

    --[[

    This table is for saving height/hull modifications specific to a playermodel since the general settings
    might not work for every model that it comes across unfortunatly.
    The table is in the following format (name not always capitalized, just an example):

    DynamicFirstPerson.SavedPlyMdlSettings.PLAYERMODEL = {
        HullOverride = {
            XY = float, -- positive values only
            Z = float -- positive values only
        },
        View = {
            AdditionalHeight = float, -- positive or negative values
        },
        FPB = {
            XOffset = float, -- positive or negative values 
            YOffset = float -- positive or negative values 
        },
        BonesToHide = {
            "BONE_NAME_1", -- names of bones to hide for the playermodel
            "BONE_NAME_2",
            ...
        },
        CustomHeadBone = "HEAD_BONE_NAME", -- for defining a custom headbone if the model does not use the standard ValveBiped
    }

    Not all elements could be present at once so make sure to check.

    Also, this table is shared since it contains both hull/view/fpb modifiers.

    As a result only some elements are available on the server via direct access (not using net lib).

    Server should technically have only hull information since thats what it needs, view/fpb is controlled by player.

    There is no realiable way for the server to enforce player viewheight or fpb settings since 
    even if we checked the player could just spoof the output due to how the addon works.
    TLDR, it's not worth the processing power to even check, though effort will be made to sync.

    Client should always have everything of this table for the player (not other players though) in theory.

    --]]

    -- Load/Save funcs
    
    DynamicFirstPerson.LoadPlayermodelSettings = function()
        if file.Exists("dfp_plymdlsettings.json", "DATA") then
        
            settingsData = file.Read("dfp_plymdlsettings.json")
            settingsTbl = util.JSONToTable(settingsData, false, true)

            if settingsTbl then
                DynamicFirstPerson.SavedPlyMdlSettings = settingsTbl
            end

        end
    end

    DynamicFirstPerson.SavePlayermodelSettings = function()
        
        jsonTbl = util.TableToJSON(DynamicFirstPerson.SavedPlyMdlSettings, true)
        file.Write("dfp_plymdlsettings.json", jsonTbl)

    end

    -- load saved files here
    DynamicFirstPerson.LoadPlayermodelSettings()

    -- create debug funcs for printing and easy tracking

    local side
    if SERVER then
        side = "SERVER"
    else
        side = "CLIENT"
    end

    DynamicFirstPerson.Print = function(...)
        MsgN("[DFP - ", side, "] ", ...)
    end

    DynamicFirstPerson.DebugPrint = function(...)
        if DynamicFirstPerson.ConVars.DebugMode:GetBool() then
            MsgN("[DFP - ", side, " - DEBUG] ", ...)
        end
    end

end

include("dfp/shared.lua")

if SERVER then
    include("dfp/server.lua")
else
    include("dfp/client.lua")
end

hook.Add("Initialize", "dfp.Initalize", function()
    DynamicFirstPerson.Initalize()
    hook.Run("DFPInitialize")
    DynamicFirstPerson.Print("Initialized!")
end)

concommand.Add("dfp_reload", function()
    DynamicFirstPerson.Initalize()
    hook.Run("DFPReload")
    DynamicFirstPerson.Print("Reloaded!")
end, nil, "Reload the Dynamic First Person addon.")

concommand.Add("dfp_loadplymdlsettings", function()
    DynamicFirstPerson.LoadPlayermodelSettings()
    DynamicFirstPerson.Print("Loaded playermodel settings file!")
end, nil, "helpText")

concommand.Add("dfp_saveplymdlsettings", function()
    DynamicFirstPerson.SavePlayermodelSettings()
    DynamicFirstPerson.Print("Saved playermodel settings file!")
end, nil, "helpText")