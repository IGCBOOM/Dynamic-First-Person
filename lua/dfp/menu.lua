-- File for all menus (tools and otherwise)

hook.Add("AddToolMenuCategories", "DFP.ToolMenuCatagory", function()
    spawnmenu.AddToolCategory("Utilities", "DFPToolMenu", "#dfp_name")
end)

hook.Add("PopulateToolMenu", "DFP.ToolMenu", function()
    
    spawnmenu.AddToolMenuOption("Utilities", "DFPToolMenu", "DFP_Tool_Menu", "#dfp_tool_menu", nil, nil, function(pnl)
    
        -- options

    end)

end)

-- pla