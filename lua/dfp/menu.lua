-- File for all menus (tools and otherwise)
if SERVER then return end

hook.Add("AddToolMenuCategories", "DFP.ToolMenuCatagory", function()
    spawnmenu.AddToolCategory("Utilities", "DFPToolMenu", "#dfp_name")
end)

hook.Add("PopulateToolMenu", "DFP.ToolMenu", function()
    
    spawnmenu.AddToolMenuOption("Utilities", "DFPToolMenu", "DFP_Tool_Menu", "#dfp_tool_menu", nil, nil, function(pnl)

        -- options

        pnl:Help("#dfp_tool_menu_help")

        -- client

        pnl:CheckBox("#dfp_enable_checkbox", "dfp_cl_fpbenabled")
        pnl:ControlHelp("#dfp_enable_checkbox_help")

        pnl:CheckBox("#dfp_fpb_view_override", "dfp_cl_fpbviewoverride")
        pnl:ControlHelp("#dfp_fpb_view_override_help")

        pnl:CheckBox("#dfp_hide_head_attached_bones", "dfp_cl_fpbhideheadattachedbones")
        pnl:ControlHelp("#dfp_hide_head_attached_bones_help")

        pnl:CheckBox("#dfp_use_eye_attach", "dfp_cl_useeyeattach")
        pnl:ControlHelp("#dfp_use_eye_attach_help")

        local viewMode = pnl:ComboBox("#dfp_view_mode", "dfp_cl_viewmode")
        viewMode:AddChoice("#dfp_view_mode_disabled", "0")
        viewMode:AddChoice("#dfp_view_mode_fixed", "1")
        viewMode:AddChoice("#dfp_view_mode_dynamic", "2")
        pnl:ControlHelp("#dfp_view_mode_help")

        pnl:Help(" ")

        -- shared / replicated

        pnl:CheckBox("#dfp_addon_enabled", "dfp_sv_enabled")
        pnl:ControlHelp("#dfp_addon_enabled_help")

        pnl:CheckBox("#dfp_debug_mode", "dfp_sv_debugmode")
        pnl:ControlHelp("#dfp_debug_mode_help")

        pnl:CheckBox("#dfp_hull_resize", "dfp_sv_hullresize")
        pnl:ControlHelp("#dfp_hull_resize_help")

        pnl:NumSlider("#dfp_hull_xy_min", "dfp_sv_hullxymin", 0, 128, 0)
        pnl:ControlHelp("#dfp_hull_xy_min_help")

        pnl:NumSlider("#dfp_hull_xy_max", "dfp_sv_hullxymax", 0, 128, 0)
        pnl:ControlHelp("#dfp_hull_xy_max_help")

        pnl:NumSlider("#dfp_hull_z_min", "dfp_sv_hullzmin", 0, 256, 0)
        pnl:ControlHelp("#dfp_hull_z_min_help")

        pnl:NumSlider("#dfp_hull_z_max", "dfp_sv_hullzmax", 0, 256, 0)
        pnl:ControlHelp("#dfp_hull_z_max_help")

        pnl:NumSlider("#dfp_hull_z_min_crouch", "dfp_sv_hullzmincrouch", 0, 256, 0)
        pnl:ControlHelp("#dfp_hull_z_min_crouch_help")

        pnl:NumSlider("#dfp_hull_z_max_crouch", "dfp_sv_hullzmaxcrouch", 0, 256, 0)
        pnl:ControlHelp("#dfp_hull_z_max_crouch_help")

        pnl:Help(" ")

        -- actions

        pnl:Button("#dfp_open_playermodel_settings", "dfp_openplayermodelsettings")
        pnl:ControlHelp("#dfp_open_playermodel_settings_help")

        pnl:Button("#dfp_reload_addon", "dfp_reload")
        pnl:ControlHelp("#dfp_reload_addon_help")

        pnl:Button("#dfp_load_playermodel_settings", "dfp_loadplymdlsettings")
        pnl:ControlHelp("#dfp_load_playermodel_settings_help")

        pnl:Button("#dfp_save_playermodel_settings", "dfp_saveplymdlsettings")
        pnl:ControlHelp("#dfp_save_playermodel_settings_help")

    end)

end)

-- playermodel settings menu

DynamicFirstPerson.OpenPlayermodelSettingsMenu = function()

    local frameW = 560
    local frameH = 760

    local frame
    local scroll

    local boneListView
    local hideBoneCombo
    local headBoneCombo

    local selectedBoneToAdd

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local modelPath = ply:GetModel()
    if not modelPath or modelPath == "" then return end

    local playermodelName = player_manager.TranslateToPlayerModelName(modelPath)
    if not playermodelName or playermodelName == "" then
        playermodelName = modelPath
    end

    playermodelName = string.lower(playermodelName)

    DynamicFirstPerson.SavedPlyMdlSettings[playermodelName] = DynamicFirstPerson.SavedPlyMdlSettings[playermodelName] or {}

    local settings = DynamicFirstPerson.SavedPlyMdlSettings[playermodelName]

    settings.HullOverride = settings.HullOverride or {}
    settings.View = settings.View or {}
    settings.FPB = settings.FPB or {}
    settings.BonesToHide = settings.BonesToHide or {}

    local liveBones = {}

    -- helper functions
    local function AddCategory(name)

        local cat = vgui.Create("DCollapsibleCategory", scroll)
        cat:Dock(TOP)
        cat:DockMargin(0, 0, 0, 8)
        cat:SetLabel(name)

        local panel = vgui.Create("DPanel")
        panel:DockPadding(8, 8, 8, 8)
        panel:SetPaintBackground(false)

        cat:SetContents(panel)

        return panel

    end

    local function AddButton(parent, text, callback)

        local btn = vgui.Create("DButton", parent)
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, 6)
        btn:SetText(text)
        btn.DoClick = callback

        return btn

    end

    local function AddNumSlider(parent, text, min, max, decimals, getFunc, setFunc)

        local slider = vgui.Create("DNumSlider", parent)
        slider:Dock(TOP)
        slider:DockMargin(0, 0, 0, 6)
        slider:SetText(text)
        slider:SetMin(min)
        slider:SetMax(max)
        slider:SetDecimals(decimals)
        slider:SetValue(getFunc())

        slider.OnValueChanged = function(_, val)
            setFunc(tonumber(val) or 0)
        end

        return slider

    end

    local function GetLiveBoneList()

        local boneTbl = {}
        local boneCount = ply:GetBoneCount() or 0

        for i = 0, boneCount - 1 do

            local boneName = ply:GetBoneName(i)

            if boneName and boneName ~= "" and boneName ~= "__INVALIDBONE__" then
                table.insert(boneTbl, boneName)
            end

        end

        table.sort(boneTbl, function(a, b)
            return string.lower(a) < string.lower(b)
        end)

        return boneTbl

    end

    local function RefreshLiveBoneCache()
        liveBones = GetLiveBoneList()
    end

    local function BoneExistsInList(tbl, value)

        for _, v in ipairs(tbl) do
            if v == value then
                return true
            end
        end

        return false

    end

    local function RefreshBoneListView()

        if not IsValid(boneListView) then return end

        boneListView:Clear()

        for _, boneName in ipairs(settings.BonesToHide or {}) do
            boneListView:AddLine(boneName)
        end

    end

    local function RefreshHideBoneCombo()

        if not IsValid(hideBoneCombo) then return end

        RefreshLiveBoneCache()

        hideBoneCombo:Clear()
        hideBoneCombo:SetValue("#dfp_pm_select_bone_to_hide")

        selectedBoneToAdd = nil

        for _, boneName in ipairs(liveBones) do
            hideBoneCombo:AddChoice(boneName)
        end

    end

    local function RefreshHeadBoneCombo()

        if not IsValid(headBoneCombo) then return end

        RefreshLiveBoneCache()

        headBoneCombo:Clear()

        for _, boneName in ipairs(liveBones) do
            headBoneCombo:AddChoice(boneName)
        end

        if settings.CustomHeadBone and settings.CustomHeadBone ~= "" then
            headBoneCombo:SetValue(settings.CustomHeadBone)
        else
            headBoneCombo:SetValue("#dfp_pm_select_head_bone")
        end

    end

    frame = vgui.Create("DFrame")
    frame:SetTitle("#dfp_pm_frame_title")
    frame:SetSize(frameW, frameH)
    frame:Center()
    frame:MakePopup()

    scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(8, 8, 8, 8)

    -- current playermodel

    do

        local panel = AddCategory("#dfp_pm_current_playermodel")

        local infoLabel = vgui.Create("DLabel", panel)
        infoLabel:Dock(TOP)
        infoLabel:SetWrap(true)
        infoLabel:SetAutoStretchVertical(true)
        infoLabel:SetText(string.format(language.GetPhrase("dfp_pm_current_playermodel_info"), playermodelName, modelPath))
        infoLabel:DockMargin(0, 0, 0, 8)

        AddButton(panel, "#dfp_pm_refresh_live_bone_lists", function()
            RefreshHideBoneCombo()
            RefreshHeadBoneCombo()
            RefreshBoneListView()
        end)

    end

    -- hull override

    do

        local panel = AddCategory("#dfp_pm_hull_override")

        AddNumSlider(panel, "#dfp_pm_hull_xy", 0, 100, 2,
            function()
                return settings.HullOverride.XY or 0
            end,
            function(val)
                settings.HullOverride.XY = math.max(0, val)
            end
        )

        AddNumSlider(panel, "#dfp_pm_hull_z", 0, 100, 2,
            function()
                return settings.HullOverride.Z or 0
            end,
            function(val)
                settings.HullOverride.Z = math.max(0, val)
            end
        )

    end

    -- view

    do

        local panel = AddCategory("#dfp_pm_view")

        AddNumSlider(panel, "#dfp_pm_additional_height", -100, 100, 2,
            function()
                return settings.View.AdditionalHeight or 0
            end,
            function(val)
                settings.View.AdditionalHeight = val
            end
        )

    end

    -- fpb

    do

        local panel = AddCategory("#dfp_pm_fpb")

        AddNumSlider(panel, "#dfp_pm_x_offset", -100, 100, 2,
            function()
                return settings.FPB.XOffset or 0
            end,
            function(val)
                settings.FPB.XOffset = val
            end
        )

        AddNumSlider(panel, "#dfp_pm_y_offset", -100, 100, 2,
            function()
                return settings.FPB.YOffset or 0
            end,
            function(val)
                settings.FPB.YOffset = val
            end
        )

    end

    -- custom head bone

    do

        local panel = AddCategory("#dfp_pm_custom_head_bone")

        headBoneCombo = vgui.Create("DComboBox", panel)
        headBoneCombo:Dock(TOP)
        headBoneCombo:DockMargin(0, 0, 0, 6)
        headBoneCombo:SetValue("#dfp_pm_select_head_bone")

        headBoneCombo.OnSelect = function(_, _, value)
            settings.CustomHeadBone = value
        end

        RefreshHeadBoneCombo()

        AddButton(panel, "#dfp_pm_refresh_head_bone_dropdown", function()
            RefreshHeadBoneCombo()
        end)

        AddButton(panel, "#dfp_pm_clear_custom_head_bone", function()
            settings.CustomHeadBone = nil
            RefreshHeadBoneCombo()
        end)

    end

    -- bones to hide

    do

        local panel = AddCategory("#dfp_pm_bones_to_hide")

        boneListView = vgui.Create("DListView", panel)
        boneListView:Dock(TOP)
        boneListView:SetTall(200)
        boneListView:DockMargin(0, 0, 0, 8)
        boneListView:AddColumn("#dfp_pm_bone_name")

        hideBoneCombo = vgui.Create("DComboBox", panel)
        hideBoneCombo:Dock(TOP)
        hideBoneCombo:DockMargin(0, 0, 0, 6)
        hideBoneCombo:SetValue("#dfp_pm_select_bone_to_hide")

        hideBoneCombo.OnSelect = function(_, _, value)
            selectedBoneToAdd = value
        end

        RefreshBoneListView()
        RefreshHideBoneCombo()

        AddButton(panel, "#dfp_pm_add_selected_bone", function()

            if not selectedBoneToAdd or selectedBoneToAdd == "" then return end

            settings.BonesToHide = settings.BonesToHide or {}

            if BoneExistsInList(settings.BonesToHide, selectedBoneToAdd) then return end

            table.insert(settings.BonesToHide, selectedBoneToAdd)

            table.sort(settings.BonesToHide, function(a, b)
                return string.lower(a) < string.lower(b)
            end)

            RefreshBoneListView()

        end)

        AddButton(panel, "#dfp_pm_refresh_bone_dropdown", function()
            RefreshHideBoneCombo()
        end)

        AddButton(panel, "#dfp_pm_remove_selected_bone", function()

            local selectedLine = boneListView:GetSelectedLine()
            if not selectedLine then return end

            table.remove(settings.BonesToHide, selectedLine)
            RefreshBoneListView()

        end)

        AddButton(panel, "#dfp_pm_clear_bone_list", function()

            settings.BonesToHide = {}
            RefreshBoneListView()

        end)

    end

    -- actions

    do

        local panel = AddCategory("#dfp_pm_actions")

        AddButton(panel, "#dfp_pm_remove_empty_subtables", function()

            if settings.HullOverride and settings.HullOverride.XY == nil and settings.HullOverride.Z == nil then
                settings.HullOverride = nil
            end

            if settings.View and settings.View.AdditionalHeight == nil then
                settings.View = nil
            end

            if settings.FPB and settings.FPB.XOffset == nil and settings.FPB.YOffset == nil then
                settings.FPB = nil
            end

            if settings.BonesToHide and #settings.BonesToHide == 0 then
                settings.BonesToHide = nil
            end

            if settings.CustomHeadBone == "" then
                settings.CustomHeadBone = nil
            end

        end)

        AddButton(panel, "#dfp_pm_delete_all_settings", function()

            DynamicFirstPerson.SavedPlyMdlSettings[playermodelName] = nil
            frame:Close()

        end)

        AddButton(panel, "#dfp_pm_print_current_settings", function()

            print("DynamicFirstPerson settings for " .. playermodelName)
            PrintTable(DynamicFirstPerson.SavedPlyMdlSettings[playermodelName] or {})

        end)

    end

end

concommand.Add("dfp_openplayermodelsettings", function()
    DynamicFirstPerson.OpenPlayermodelSettingsMenu()
end, nil, "#dfp_openplayermodelsettings_help")