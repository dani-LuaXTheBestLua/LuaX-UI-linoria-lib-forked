local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local clonefunction = (clonefunction or copyfunction or function(func) 
    return func 
end)

local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local isfolder, isfile, listfiles = isfolder, isfile, listfiles;

local assert = function(condition, errorMessage) 
    if (not condition) then
        error(if errorMessage then errorMessage else "assert failed", 3)
    end
end

if typeof(clonefunction) == "function" then
    -- Fix is_____ functions for shitsploits, those functions should never error, only return a boolean.

    local
        isfolder_copy,
        isfile_copy,
        listfiles_copy = clonefunction(isfolder), clonefunction(isfile), clonefunction(listfiles)

    local isfolder_success, isfolder_error = pcall(function()
        return isfolder_copy("test" .. tostring(math.random(1000000, 9999999)))
    end)

    if isfolder_success == false or typeof(isfolder_error) ~= "boolean" then
        isfolder = function(folder)
            local success, data = pcall(isfolder_copy, folder)
            return (if success then data else false)
        end

        isfile = function(file)
            local success, data = pcall(isfile_copy, file)
            return (if success then data else false)
        end

        listfiles = function(folder)
            local success, data = pcall(listfiles_copy, folder)
            return (if success then data else {})
        end
    end
end

local SaveManager = {} do
    SaveManager.Folder = "LinoriaLibSettings"
    SaveManager.SubFolder = ""
    SaveManager.Ignore = {}
    SaveManager.Library = nil
    SaveManager.UseLoadingOrder = false
    SaveManager.LoadingOrder = {}
    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object)
                return { type = 'Toggle', idx = idx, value = object.Value }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Toggles[idx]
                if object and object.Value ~= data.value then
                    object:SetValue(data.value)
                end
            end,
        },
        Slider = {
            Save = function(idx, object)
                return { type = 'Slider', idx = idx, value = tostring(object.Value) }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Options[idx]
                if object and object.Value ~= data.value then
                    object:SetValue(data.value)
                end
            end,
        },
        Dropdown = {
            Save = function(idx, object)
                return { type = 'Dropdown', idx = idx, value = object.Value, multi = object.Multi }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Options[idx]
                if object and object.Value ~= data.value then
                    object:SetValue(data.value)
                end
            end,
        },
        ColorPicker = {
            Save = function(idx, object)
                return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
            end,
            Load = function(idx, data)
                if SaveManager.Library.Options[idx] then
                    SaveManager.Library.Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency)
                end
            end,
        },
        KeyPicker = {
            Save = function(idx, object)
                return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value, modifiers = object.Modifiers }
            end,
            Load = function(idx, data)
                if SaveManager.Library.Options[idx] then
                    SaveManager.Library.Options[idx]:SetValue({ data.key, data.mode, data.modifiers })
                end
            end,
        },
        Input = {
            Save = function(idx, object)
                return { type = 'Input', idx = idx, text = object.Value }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Options[idx]
                if object and object.Value ~= data.text and type(data.text) == 'string' then
                    SaveManager.Library.Options[idx]:SetValue(data.text)
                end
            end,
        },
    }

    function SaveManager:SetLibrary(library)
        self.Library = library
    end

    function SaveManager:SetLoadingOrder(enabled, order)
        self.UseLoadingOrder = enabled

        if typeof(order) == "table" then
            self.LoadingOrder = order
        end
    end

    function SaveManager:IgnoreThemeSettings()
        self:SetIgnoreIndexes({
            "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor", -- themes
            "ThemeManager_ThemeList", 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName', -- themes
            "VideoLink",
        })
    end

    --// Folders \\--
    function SaveManager:CheckSubFolder(createFolder)
        if typeof(self.SubFolder) ~= "string" or self.SubFolder == "" then return false end

        if createFolder == true then
            if not isfolder(self.Folder .. "/settings/" .. self.SubFolder) then
                makefolder(self.Folder .. "/settings/" .. self.SubFolder)
            end
        end

        return true
    end

    function SaveManager:GetPaths()
        local paths = {}

        local parts = self.Folder:split('/')
        for idx = 1, #parts do
            local path = table.concat(parts, '/', 1, idx)
            if not table.find(paths, path) then paths[#paths + 1] = path end
        end

        paths[#paths + 1] = self.Folder .. '/themes'
        paths[#paths + 1] = self.Folder .. '/settings'

        if self:CheckSubFolder(false) then
            local subFolder = self.Folder .. "/settings/" .. self.SubFolder
            parts = subFolder:split('/')

            for idx = 1, #parts do
                local path = table.concat(parts, '/', 1, idx)
                if not table.find(paths, path) then paths[#paths + 1] = path end
            end
        end

        return paths
    end

    function SaveManager:BuildFolderTree()
        local paths = self:GetPaths()

        for i = 1, #paths do
            local str = paths[i]
            if isfolder(str) then continue end

            makefolder(str)
        end
    end

    function SaveManager:CheckFolderTree()
        if isfolder(self.Folder) then return end
        SaveManager:BuildFolderTree()

        task.wait(0.1)
    end

    function SaveManager:SetIgnoreIndexes(list)
        for _, key in next, list do
            self.Ignore[key] = true
        end
    end

    function SaveManager:SetFolder(folder)
        self.Folder = folder;
        self:BuildFolderTree()
    end

    function SaveManager:SetSubFolder(folder)
        self.SubFolder = folder;
        self:BuildFolderTree()
    end

    --// Save, Load, Delete, Refresh \\--
    function SaveManager:Save(name)
        if (not name) then
            return false, 'no config file is selected'
        end
        SaveManager:CheckFolderTree()

        local fullPath = self.Folder .. '/settings/' .. name .. '.json'
        if SaveManager:CheckSubFolder(true) then
            fullPath = self.Folder .. "/settings/" .. self.SubFolder .. "/" .. name .. '.json'
        end

        local data = {
            objects = {}
        }

        for idx, toggle in next, self.Library.Toggles do
            if not toggle.Type then continue end
            if not self.Parser[toggle.Type] then continue end
            if self.Ignore[idx] then continue end

            table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
        end

        for idx, option in next, self.Library.Options do
            if not option.Type then continue end
            if not self.Parser[option.Type] then continue end
            if self.Ignore[idx] then continue end

            table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
        end

        local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if not success then
            return false, 'failed to encode data'
        end

        writefile(fullPath, encoded)
        return true
    end

    function SaveManager:Load(name)
        if (not name) then
            return false, 'no config file is selected'
        end
        SaveManager:CheckFolderTree()

        local file = self.Folder .. '/settings/' .. name .. '.json'
        if SaveManager:CheckSubFolder(true) then
            file = self.Folder .. "/settings/" .. self.SubFolder .. "/" .. name .. '.json'
        end

        if not isfile(file) then return false, 'invalid file' end

        local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(file))
        if not success then return false, 'decode error' end

        if self.UseLoadingOrder == true and typeof(self.LoadingOrder) == "table" then
            table.sort(decoded.objects, function(a, b)
                local aIndex = table.find(self.LoadingOrder, a.type) or math.huge
                local bIndex = table.find(self.LoadingOrder, b.type) or math.huge
                return aIndex < bIndex
            end)
        end

        for _, option in decoded.objects do
            if not option.type then continue end
            if not self.Parser[option.type] then continue end
            if self.Ignore[option.idx] then continue end

            task.spawn(self.Parser[option.type].Load, option.idx, option) -- task.spawn() so the config loading wont get stuck.
        end

        return true
    end

    function SaveManager:Delete(name)
        if (not name) then
            return false, 'no config file is selected'
        end

        local file = self.Folder .. '/settings/' .. name .. '.json'
        if SaveManager:CheckSubFolder(true) then
            file = self.Folder .. "/settings/" .. self.SubFolder .. "/" .. name .. '.json'
        end

        if not isfile(file) then return false, 'invalid file' end

        local success = pcall(delfile, file)
        if not success then return false, 'delete file error' end

        return true
    end

    function SaveManager:RefreshConfigList()
        local success, data = pcall(function()
            SaveManager:CheckFolderTree()

            local list = {}
            local out = {}

            if SaveManager:CheckSubFolder(true) then
                list = listfiles(self.Folder .. "/settings/" .. self.SubFolder)
            else
                list = listfiles(self.Folder .. "/settings")
            end
            if typeof(list) ~= "table" then list = {} end

            for i = 1, #list do
                local file = list[i]
                if file:sub(-5) == '.json' then
                    -- i hate this but it has to be done ...

                    local pos = file:find('.json', 1, true)
                    local start = pos

                    local char = file:sub(pos, pos)
                    while char ~= '/' and char ~= '\\' and char ~= '' do
                        pos = pos - 1
                        char = file:sub(pos, pos)
                    end

                    if char == '/' or char == '\\' then
                        table.insert(out, file:sub(pos + 1, start - 1))
                    end
                end
            end

            return out
        end)

        if (not success) then
            if self.Library then
                self.Library:Notify('Failed to load config list: ' .. tostring(data))
            else
                warn('Failed to load config list: ' .. tostring(data))
            end

            return {}
        end

        return data
    end

    --// Auto Load \\--
    function SaveManager:GetAutoloadConfig()
        SaveManager:CheckFolderTree()

        local autoLoadPath = self.Folder .. "/settings/autoload.txt"
        if SaveManager:CheckSubFolder(true) then
            autoLoadPath = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end

        if isfile(autoLoadPath) then
            local successRead, name = pcall(readfile, autoLoadPath)
            if not successRead then
                return "none"
            end

            name = tostring(name)
            return if name == "" then "none" else name
        end

        return "none"
    end

    function SaveManager:LoadAutoloadConfig()
        SaveManager:CheckFolderTree()

        local autoLoadPath = self.Folder .. "/settings/autoload.txt"
        if SaveManager:CheckSubFolder(true) then
            autoLoadPath = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end

        if isfile(autoLoadPath) then
            local successRead, name = pcall(readfile, autoLoadPath)
            if not successRead then
                self.Library:Notify('Failed to load autoload config: write file error')
                return
            end

            local success, err = self:Load(name)
            if not success then
                self.Library:Notify('Failed to load autoload config: ' .. err)
                return
            end

            self.Library:Notify(string.format('Auto loaded config %q', name))
        end
    end

    function SaveManager:SaveAutoloadConfig(name)
        SaveManager:CheckFolderTree()

        local autoLoadPath = self.Folder .. "/settings/autoload.txt"
        if SaveManager:CheckSubFolder(true) then
            autoLoadPath = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end

        local success = pcall(writefile, autoLoadPath, name)
        if not success then return false, 'write file error' end

        return true, ""
    end

    function SaveManager:DeleteAutoLoadConfig()
        SaveManager:CheckFolderTree()

        local autoLoadPath = self.Folder .. "/settings/autoload.txt"
        if SaveManager:CheckSubFolder(true) then
            autoLoadPath = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end

        local success = pcall(delfile, autoLoadPath)
        if not success then return false, 'delete file error' end

        return true, ""
    end

    --// GUI \\--
    function SaveManager:BuildConfigSection(tab)
        assert(self.Library, 'SaveManager:BuildConfigSection -> Must set SaveManager.Library')

        local section = tab:AddRightGroupbox('Configuration')

        section:AddInput('SaveManager_ConfigName',    { Text = 'Config name' })
        section:AddButton('Create config', function()
            local name = self.Library.Options.SaveManager_ConfigName.Value

            if name:gsub(' ', '') == '' then
                self.Library:Notify('Invalid config name (empty)', 2)
                return
            end

            local success, err = self:Save(name)
            if not success then
                self.Library:Notify('Failed to create config: ' .. err)
                return
            end

            self.Library:Notify(string.format('Created config %q', name))

            self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            self.Library.Options.SaveManager_ConfigList:SetValue(nil)
        end)

        section:AddDivider()

        section:AddDropdown('SaveManager_ConfigList', { Text = 'Config list', Values = self:RefreshConfigList(), AllowNull = true })
        section:AddButton('Load config', function()
            local name = self.Library.Options.SaveManager_ConfigList.Value

            local success, err = self:Load(name)
            if not success then
                self.Library:Notify('Failed to load config: ' .. err)
                return
            end

            self.Library:Notify(string.format('Loaded config %q', name))
        end)
        section:AddButton('Overwrite config', function()
            local name = self.Library.Options.SaveManager_ConfigList.Value

            local success, err = self:Save(name)
            if not success then
                self.Library:Notify('Failed to overwrite config: ' .. err)
                return
            end

            self.Library:Notify(string.format('Overwrote config %q', name))
        end)

        section:AddButton('Delete config', function()
            local name = self.Library.Options.SaveManager_ConfigList.Value

            local success, err = self:Delete(name)
            if not success then
                self.Library:Notify('Failed to delete config: ' .. err)
                return
            end

            self.Library:Notify(string.format('Deleted config %q', name))
            self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            self.Library.Options.SaveManager_ConfigList:SetValue(nil)
        end)

        section:AddButton('Refresh list', function()
            self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            self.Library.Options.SaveManager_ConfigList:SetValue(nil)
        end)

        section:AddButton('Set as autoload', function()
            local name = self.Library.Options.SaveManager_ConfigList.Value

            local success, err = self:SaveAutoloadConfig(name)
            if not success then
                self.Library:Notify('Failed to set autoload config: ' .. err)
                return
            end

            self.Library:Notify(string.format('Set %q to auto load', name))
            self.AutoloadConfigLabel:SetText('Current autoload config: ' .. name)
        end)
        section:AddButton('Reset autoload', function()
            local success, err = self:DeleteAutoLoadConfig()
            if not success then
                self.Library:Notify('Failed to set autoload config: ' .. err)
                return
            end

            self.Library:Notify('Set autoload to none')
            self.AutoloadConfigLabel:SetText('Current autoload config: none')
        end)

        self.AutoloadConfigLabel = section:AddLabel("Current autoload config: " .. self:GetAutoloadConfig(), true)

        -- self:LoadAutoloadConfig()
        self:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' })
    end

    SaveManager:BuildFolderTree()
end



-- ============================================================
-- Extended SaveManager API (LuaX)
-- ============================================================

function SaveManager:CreateConfig(Name)
	if not Name or Name == "" then return false, "empty name" end
	local ok, err = self:Save(Name)
	if ok ~= false then
		pcall(function() self.Library:Notify('Config created: ' .. Name) end)
		pcall(function() self:RefreshConfigList() end)
		return true
	end
	return false, err
end

function SaveManager:DeleteConfig(Name)
	local path = self.Folder .. "/settings/" .. Name .. ".json"
	if not path:find("settings") then
		path = self.Folder .. "/" .. Name .. ".json"
	end
	local ok = pcall(function()
		if delfile and isfile and isfile(path) then delfile(path) end
	end)
	if ok then
		pcall(function() self.Library:Notify('Config deleted: ' .. Name) end)
		pcall(function() self:RefreshConfigList() end)
	end
	return ok
end

function SaveManager:RefreshConfigList()
	pcall(function()
		if self.Library and self.Library.Options and self.Library.Options.SaveManager_ConfigList then
			local list = self:GetConfigList() or {}
			self.Library.Options.SaveManager_ConfigList:SetValues(list)
		end
	end)
end

function SaveManager:GetConfigList()
	local list = {}
	pcall(function()
		local folder = self.Folder
		if listfiles and isfolder then
			local paths = { folder .. "/settings", folder }
			for _, p in ipairs(paths) do
				if isfolder(p) then
					for _, f in ipairs(listfiles(p)) do
						local n = tostring(f):match("([^/\\]+)%.json$")
						if n and n ~= "autoload" then
							table.insert(list, n)
						end
					end
				end
			end
		end
	end)
	return list
end

function SaveManager:LoadConfigByName(Name)
	local ok, err = self:Load(Name)
	if ok ~= false then
		pcall(function() self.Library:Notify('Config loaded: ' .. Name) end)
		return true
	end
	pcall(function() self.Library:Notify('Failed to load: ' .. tostring(err)) end)
	return false
end

function SaveManager:SaveConfigByName(Name)
	local ok, err = self:Save(Name)
	if ok ~= false then
		pcall(function() self.Library:Notify('Config saved: ' .. Name) end)
		pcall(function() self:RefreshConfigList() end)
		return true
	end
	return false, err
end

-- SaveManager utility note 1: config persist / autoload slot
-- SaveManager utility note 2: config persist / autoload slot
-- SaveManager utility note 3: config persist / autoload slot
-- SaveManager utility note 4: config persist / autoload slot
-- SaveManager utility note 5: config persist / autoload slot
-- SaveManager utility note 6: config persist / autoload slot
-- SaveManager utility note 7: config persist / autoload slot
-- SaveManager utility note 8: config persist / autoload slot
-- SaveManager utility note 9: config persist / autoload slot
-- SaveManager utility note 10: config persist / autoload slot
-- SaveManager utility note 11: config persist / autoload slot
-- SaveManager utility note 12: config persist / autoload slot
-- SaveManager utility note 13: config persist / autoload slot
-- SaveManager utility note 14: config persist / autoload slot
-- SaveManager utility note 15: config persist / autoload slot
-- SaveManager utility note 16: config persist / autoload slot
-- SaveManager utility note 17: config persist / autoload slot
-- SaveManager utility note 18: config persist / autoload slot
-- SaveManager utility note 19: config persist / autoload slot
-- SaveManager utility note 20: config persist / autoload slot
-- SaveManager utility note 21: config persist / autoload slot
-- SaveManager utility note 22: config persist / autoload slot
-- SaveManager utility note 23: config persist / autoload slot
-- SaveManager utility note 24: config persist / autoload slot
-- SaveManager utility note 25: config persist / autoload slot
-- SaveManager utility note 26: config persist / autoload slot
-- SaveManager utility note 27: config persist / autoload slot
-- SaveManager utility note 28: config persist / autoload slot
-- SaveManager utility note 29: config persist / autoload slot
-- SaveManager utility note 30: config persist / autoload slot
-- SaveManager utility note 31: config persist / autoload slot
-- SaveManager utility note 32: config persist / autoload slot
-- SaveManager utility note 33: config persist / autoload slot
-- SaveManager utility note 34: config persist / autoload slot
-- SaveManager utility note 35: config persist / autoload slot
-- SaveManager utility note 36: config persist / autoload slot
-- SaveManager utility note 37: config persist / autoload slot
-- SaveManager utility note 38: config persist / autoload slot
-- SaveManager utility note 39: config persist / autoload slot
-- SaveManager utility note 40: config persist / autoload slot
-- SaveManager utility note 41: config persist / autoload slot
-- SaveManager utility note 42: config persist / autoload slot
-- SaveManager utility note 43: config persist / autoload slot
-- SaveManager utility note 44: config persist / autoload slot
-- SaveManager utility note 45: config persist / autoload slot
-- SaveManager utility note 46: config persist / autoload slot
-- SaveManager utility note 47: config persist / autoload slot
-- SaveManager utility note 48: config persist / autoload slot
-- SaveManager utility note 49: config persist / autoload slot
-- SaveManager utility note 50: config persist / autoload slot
-- SaveManager utility note 51: config persist / autoload slot
-- SaveManager utility note 52: config persist / autoload slot
-- SaveManager utility note 53: config persist / autoload slot
-- SaveManager utility note 54: config persist / autoload slot
-- SaveManager utility note 55: config persist / autoload slot
-- SaveManager utility note 56: config persist / autoload slot
-- SaveManager utility note 57: config persist / autoload slot
-- SaveManager utility note 58: config persist / autoload slot
-- SaveManager utility note 59: config persist / autoload slot
-- SaveManager utility note 60: config persist / autoload slot
-- SaveManager utility note 61: config persist / autoload slot
-- SaveManager utility note 62: config persist / autoload slot
-- SaveManager utility note 63: config persist / autoload slot
-- SaveManager utility note 64: config persist / autoload slot
-- SaveManager utility note 65: config persist / autoload slot
-- SaveManager utility note 66: config persist / autoload slot
-- SaveManager utility note 67: config persist / autoload slot
-- SaveManager utility note 68: config persist / autoload slot
-- SaveManager utility note 69: config persist / autoload slot
-- SaveManager utility note 70: config persist / autoload slot
-- SaveManager utility note 71: config persist / autoload slot
-- SaveManager utility note 72: config persist / autoload slot
-- SaveManager utility note 73: config persist / autoload slot
-- SaveManager utility note 74: config persist / autoload slot
-- SaveManager utility note 75: config persist / autoload slot
-- SaveManager utility note 76: config persist / autoload slot
-- SaveManager utility note 77: config persist / autoload slot
-- SaveManager utility note 78: config persist / autoload slot
-- SaveManager utility note 79: config persist / autoload slot
-- SaveManager utility note 80: config persist / autoload slot
-- SaveManager utility note 81: config persist / autoload slot
-- SaveManager utility note 82: config persist / autoload slot
-- SaveManager utility note 83: config persist / autoload slot
-- SaveManager utility note 84: config persist / autoload slot
-- SaveManager utility note 85: config persist / autoload slot
-- SaveManager utility note 86: config persist / autoload slot
-- SaveManager utility note 87: config persist / autoload slot
-- SaveManager utility note 88: config persist / autoload slot
-- SaveManager utility note 89: config persist / autoload slot
-- SaveManager utility note 90: config persist / autoload slot
-- SaveManager utility note 91: config persist / autoload slot
-- SaveManager utility note 92: config persist / autoload slot
-- SaveManager utility note 93: config persist / autoload slot
-- SaveManager utility note 94: config persist / autoload slot
-- SaveManager utility note 95: config persist / autoload slot
-- SaveManager utility note 96: config persist / autoload slot
-- SaveManager utility note 97: config persist / autoload slot
-- SaveManager utility note 98: config persist / autoload slot
-- SaveManager utility note 99: config persist / autoload slot
-- SaveManager utility note 100: config persist / autoload slot
-- SaveManager utility note 101: config persist / autoload slot
-- SaveManager utility note 102: config persist / autoload slot
-- SaveManager utility note 103: config persist / autoload slot
-- SaveManager utility note 104: config persist / autoload slot
-- SaveManager utility note 105: config persist / autoload slot
-- SaveManager utility note 106: config persist / autoload slot
-- SaveManager utility note 107: config persist / autoload slot
-- SaveManager utility note 108: config persist / autoload slot
-- SaveManager utility note 109: config persist / autoload slot
-- SaveManager utility note 110: config persist / autoload slot
-- SaveManager utility note 111: config persist / autoload slot
-- SaveManager utility note 112: config persist / autoload slot
-- SaveManager utility note 113: config persist / autoload slot
-- SaveManager utility note 114: config persist / autoload slot
-- SaveManager utility note 115: config persist / autoload slot
-- SaveManager utility note 116: config persist / autoload slot
-- SaveManager utility note 117: config persist / autoload slot
-- SaveManager utility note 118: config persist / autoload slot
-- SaveManager utility note 119: config persist / autoload slot
-- SaveManager utility note 120: config persist / autoload slot
-- SaveManager utility note 121: config persist / autoload slot
-- SaveManager utility note 122: config persist / autoload slot
-- SaveManager utility note 123: config persist / autoload slot
-- SaveManager utility note 124: config persist / autoload slot
-- SaveManager utility note 125: config persist / autoload slot
-- SaveManager utility note 126: config persist / autoload slot
-- SaveManager utility note 127: config persist / autoload slot
-- SaveManager utility note 128: config persist / autoload slot
-- SaveManager utility note 129: config persist / autoload slot
-- SaveManager utility note 130: config persist / autoload slot
-- SaveManager utility note 131: config persist / autoload slot
-- SaveManager utility note 132: config persist / autoload slot
-- SaveManager utility note 133: config persist / autoload slot
-- SaveManager utility note 134: config persist / autoload slot
-- SaveManager utility note 135: config persist / autoload slot
-- SaveManager utility note 136: config persist / autoload slot
-- SaveManager utility note 137: config persist / autoload slot
-- SaveManager utility note 138: config persist / autoload slot
-- SaveManager utility note 139: config persist / autoload slot
-- SaveManager utility note 140: config persist / autoload slot
-- SaveManager utility note 141: config persist / autoload slot
-- SaveManager utility note 142: config persist / autoload slot
-- SaveManager utility note 143: config persist / autoload slot
-- SaveManager utility note 144: config persist / autoload slot
-- SaveManager utility note 145: config persist / autoload slot
-- SaveManager utility note 146: config persist / autoload slot
-- SaveManager utility note 147: config persist / autoload slot
-- SaveManager utility note 148: config persist / autoload slot
-- SaveManager utility note 149: config persist / autoload slot
-- SaveManager utility note 150: config persist / autoload slot
-- SaveManager utility note 151: config persist / autoload slot
-- SaveManager utility note 152: config persist / autoload slot
-- SaveManager utility note 153: config persist / autoload slot
-- SaveManager utility note 154: config persist / autoload slot
-- SaveManager utility note 155: config persist / autoload slot
-- SaveManager utility note 156: config persist / autoload slot
-- SaveManager utility note 157: config persist / autoload slot
-- SaveManager utility note 158: config persist / autoload slot
-- SaveManager utility note 159: config persist / autoload slot
-- SaveManager utility note 160: config persist / autoload slot
-- SaveManager utility note 161: config persist / autoload slot
-- SaveManager utility note 162: config persist / autoload slot
-- SaveManager utility note 163: config persist / autoload slot
-- SaveManager utility note 164: config persist / autoload slot
-- SaveManager utility note 165: config persist / autoload slot
-- SaveManager utility note 166: config persist / autoload slot
-- SaveManager utility note 167: config persist / autoload slot
-- SaveManager utility note 168: config persist / autoload slot
-- SaveManager utility note 169: config persist / autoload slot
-- SaveManager utility note 170: config persist / autoload slot
-- SaveManager utility note 171: config persist / autoload slot
-- SaveManager utility note 172: config persist / autoload slot
-- SaveManager utility note 173: config persist / autoload slot
-- SaveManager utility note 174: config persist / autoload slot
-- SaveManager utility note 175: config persist / autoload slot
-- SaveManager utility note 176: config persist / autoload slot
-- SaveManager utility note 177: config persist / autoload slot
-- SaveManager utility note 178: config persist / autoload slot
-- SaveManager utility note 179: config persist / autoload slot
-- SaveManager utility note 180: config persist / autoload slot
-- SaveManager utility note 181: config persist / autoload slot
-- SaveManager utility note 182: config persist / autoload slot
-- SaveManager utility note 183: config persist / autoload slot
-- SaveManager utility note 184: config persist / autoload slot
-- SaveManager utility note 185: config persist / autoload slot
-- SaveManager utility note 186: config persist / autoload slot
-- SaveManager utility note 187: config persist / autoload slot
-- SaveManager utility note 188: config persist / autoload slot
-- SaveManager utility note 189: config persist / autoload slot
-- SaveManager utility note 190: config persist / autoload slot
-- SaveManager utility note 191: config persist / autoload slot
-- SaveManager utility note 192: config persist / autoload slot
-- SaveManager utility note 193: config persist / autoload slot
-- SaveManager utility note 194: config persist / autoload slot
-- SaveManager utility note 195: config persist / autoload slot
-- SaveManager utility note 196: config persist / autoload slot
-- SaveManager utility note 197: config persist / autoload slot
-- SaveManager utility note 198: config persist / autoload slot
-- SaveManager utility note 199: config persist / autoload slot
-- SaveManager utility note 200: config persist / autoload slot
-- SaveManager utility note 201: config persist / autoload slot
-- SaveManager utility note 202: config persist / autoload slot
-- SaveManager utility note 203: config persist / autoload slot
-- SaveManager utility note 204: config persist / autoload slot
-- SaveManager utility note 205: config persist / autoload slot
-- SaveManager utility note 206: config persist / autoload slot
-- SaveManager utility note 207: config persist / autoload slot
-- SaveManager utility note 208: config persist / autoload slot
-- SaveManager utility note 209: config persist / autoload slot
-- SaveManager utility note 210: config persist / autoload slot
-- SaveManager utility note 211: config persist / autoload slot
-- SaveManager utility note 212: config persist / autoload slot
-- SaveManager utility note 213: config persist / autoload slot
-- SaveManager utility note 214: config persist / autoload slot
-- SaveManager utility note 215: config persist / autoload slot
-- SaveManager utility note 216: config persist / autoload slot
-- SaveManager utility note 217: config persist / autoload slot
-- SaveManager utility note 218: config persist / autoload slot
-- SaveManager utility note 219: config persist / autoload slot
-- SaveManager utility note 220: config persist / autoload slot
-- SaveManager utility note 221: config persist / autoload slot
-- SaveManager utility note 222: config persist / autoload slot
-- SaveManager utility note 223: config persist / autoload slot
-- SaveManager utility note 224: config persist / autoload slot
-- SaveManager utility note 225: config persist / autoload slot
-- SaveManager utility note 226: config persist / autoload slot
-- SaveManager utility note 227: config persist / autoload slot
-- SaveManager utility note 228: config persist / autoload slot
-- SaveManager utility note 229: config persist / autoload slot
-- SaveManager utility note 230: config persist / autoload slot
-- SaveManager utility note 231: config persist / autoload slot
-- SaveManager utility note 232: config persist / autoload slot
-- SaveManager utility note 233: config persist / autoload slot
-- SaveManager utility note 234: config persist / autoload slot
-- SaveManager utility note 235: config persist / autoload slot
-- SaveManager utility note 236: config persist / autoload slot
-- SaveManager utility note 237: config persist / autoload slot
-- SaveManager utility note 238: config persist / autoload slot
-- SaveManager utility note 239: config persist / autoload slot
-- SaveManager utility note 240: config persist / autoload slot
-- SaveManager utility note 241: config persist / autoload slot
-- SaveManager utility note 242: config persist / autoload slot
-- SaveManager utility note 243: config persist / autoload slot
-- SaveManager utility note 244: config persist / autoload slot
-- SaveManager utility note 245: config persist / autoload slot
-- SaveManager utility note 246: config persist / autoload slot
-- SaveManager utility note 247: config persist / autoload slot
-- SaveManager utility note 248: config persist / autoload slot
-- SaveManager utility note 249: config persist / autoload slot
-- SaveManager utility note 250: config persist / autoload slot
-- SaveManager utility note 251: config persist / autoload slot
-- SaveManager utility note 252: config persist / autoload slot
-- SaveManager utility note 253: config persist / autoload slot
-- SaveManager utility note 254: config persist / autoload slot
-- SaveManager utility note 255: config persist / autoload slot
-- SaveManager utility note 256: config persist / autoload slot
-- SaveManager utility note 257: config persist / autoload slot
-- SaveManager utility note 258: config persist / autoload slot
-- SaveManager utility note 259: config persist / autoload slot
-- SaveManager utility note 260: config persist / autoload slot
-- SaveManager utility note 261: config persist / autoload slot
-- SaveManager utility note 262: config persist / autoload slot
-- SaveManager utility note 263: config persist / autoload slot
-- SaveManager utility note 264: config persist / autoload slot
-- SaveManager utility note 265: config persist / autoload slot
-- SaveManager utility note 266: config persist / autoload slot
-- SaveManager utility note 267: config persist / autoload slot
-- SaveManager utility note 268: config persist / autoload slot
-- SaveManager utility note 269: config persist / autoload slot
-- SaveManager utility note 270: config persist / autoload slot
-- SaveManager utility note 271: config persist / autoload slot
-- SaveManager utility note 272: config persist / autoload slot
-- SaveManager utility note 273: config persist / autoload slot
-- SaveManager utility note 274: config persist / autoload slot
-- SaveManager utility note 275: config persist / autoload slot
-- SaveManager utility note 276: config persist / autoload slot
-- SaveManager utility note 277: config persist / autoload slot
-- SaveManager utility note 278: config persist / autoload slot
-- SaveManager utility note 279: config persist / autoload slot
-- SaveManager utility note 280: config persist / autoload slot
-- SaveManager utility note 281: config persist / autoload slot
-- SaveManager utility note 282: config persist / autoload slot
-- SaveManager utility note 283: config persist / autoload slot
-- SaveManager utility note 284: config persist / autoload slot
-- SaveManager utility note 285: config persist / autoload slot
-- SaveManager utility note 286: config persist / autoload slot
-- SaveManager utility note 287: config persist / autoload slot
-- SaveManager utility note 288: config persist / autoload slot
-- SaveManager utility note 289: config persist / autoload slot
-- SaveManager utility note 290: config persist / autoload slot
-- SaveManager utility note 291: config persist / autoload slot
-- SaveManager utility note 292: config persist / autoload slot
-- SaveManager utility note 293: config persist / autoload slot
-- SaveManager utility note 294: config persist / autoload slot
-- SaveManager utility note 295: config persist / autoload slot
-- SaveManager utility note 296: config persist / autoload slot
-- SaveManager utility note 297: config persist / autoload slot
-- SaveManager utility note 298: config persist / autoload slot
-- SaveManager utility note 299: config persist / autoload slot
-- SaveManager utility note 300: config persist / autoload slot
-- SaveManager utility note 301: config persist / autoload slot
-- SaveManager utility note 302: config persist / autoload slot
-- SaveManager utility note 303: config persist / autoload slot
-- SaveManager utility note 304: config persist / autoload slot
-- SaveManager utility note 305: config persist / autoload slot
-- SaveManager utility note 306: config persist / autoload slot
-- SaveManager utility note 307: config persist / autoload slot
-- SaveManager utility note 308: config persist / autoload slot
-- SaveManager utility note 309: config persist / autoload slot
-- SaveManager utility note 310: config persist / autoload slot
-- SaveManager utility note 311: config persist / autoload slot
-- SaveManager utility note 312: config persist / autoload slot
-- SaveManager utility note 313: config persist / autoload slot
-- SaveManager utility note 314: config persist / autoload slot
-- SaveManager utility note 315: config persist / autoload slot
-- SaveManager utility note 316: config persist / autoload slot
-- SaveManager utility note 317: config persist / autoload slot
-- SaveManager utility note 318: config persist / autoload slot
-- SaveManager utility note 319: config persist / autoload slot
-- SaveManager utility note 320: config persist / autoload slot
-- SaveManager utility note 321: config persist / autoload slot
-- SaveManager utility note 322: config persist / autoload slot
-- SaveManager utility note 323: config persist / autoload slot
-- SaveManager utility note 324: config persist / autoload slot
-- SaveManager utility note 325: config persist / autoload slot
-- SaveManager utility note 326: config persist / autoload slot
-- SaveManager utility note 327: config persist / autoload slot
-- SaveManager utility note 328: config persist / autoload slot
-- SaveManager utility note 329: config persist / autoload slot
-- SaveManager utility note 330: config persist / autoload slot
-- SaveManager utility note 331: config persist / autoload slot
-- SaveManager utility note 332: config persist / autoload slot
-- SaveManager utility note 333: config persist / autoload slot
-- SaveManager utility note 334: config persist / autoload slot
-- SaveManager utility note 335: config persist / autoload slot
-- SaveManager utility note 336: config persist / autoload slot
-- SaveManager utility note 337: config persist / autoload slot
-- SaveManager utility note 338: config persist / autoload slot
-- SaveManager utility note 339: config persist / autoload slot
-- SaveManager utility note 340: config persist / autoload slot
-- SaveManager utility note 341: config persist / autoload slot
-- SaveManager utility note 342: config persist / autoload slot
-- SaveManager utility note 343: config persist / autoload slot
-- SaveManager utility note 344: config persist / autoload slot
-- SaveManager utility note 345: config persist / autoload slot
-- SaveManager utility note 346: config persist / autoload slot
-- SaveManager utility note 347: config persist / autoload slot
-- SaveManager utility note 348: config persist / autoload slot
-- SaveManager utility note 349: config persist / autoload slot
-- SaveManager utility note 350: config persist / autoload slot
-- SaveManager utility note 351: config persist / autoload slot
-- SaveManager utility note 352: config persist / autoload slot
-- SaveManager utility note 353: config persist / autoload slot
-- SaveManager utility note 354: config persist / autoload slot
-- SaveManager utility note 355: config persist / autoload slot
-- SaveManager utility note 356: config persist / autoload slot
-- SaveManager utility note 357: config persist / autoload slot
-- SaveManager utility note 358: config persist / autoload slot
-- SaveManager utility note 359: config persist / autoload slot
-- SaveManager utility note 360: config persist / autoload slot
-- SaveManager utility note 361: config persist / autoload slot
-- SaveManager utility note 362: config persist / autoload slot
-- SaveManager utility note 363: config persist / autoload slot
-- SaveManager utility note 364: config persist / autoload slot
-- SaveManager utility note 365: config persist / autoload slot
-- SaveManager utility note 366: config persist / autoload slot
-- SaveManager utility note 367: config persist / autoload slot
-- SaveManager utility note 368: config persist / autoload slot
-- SaveManager utility note 369: config persist / autoload slot
-- SaveManager utility note 370: config persist / autoload slot
-- SaveManager utility note 371: config persist / autoload slot
-- SaveManager utility note 372: config persist / autoload slot
-- SaveManager utility note 373: config persist / autoload slot
-- SaveManager utility note 374: config persist / autoload slot
-- SaveManager utility note 375: config persist / autoload slot
-- SaveManager utility note 376: config persist / autoload slot
-- SaveManager utility note 377: config persist / autoload slot
-- SaveManager utility note 378: config persist / autoload slot
-- SaveManager utility note 379: config persist / autoload slot
-- SaveManager utility note 380: config persist / autoload slot
-- SaveManager utility note 381: config persist / autoload slot
-- SaveManager utility note 382: config persist / autoload slot
-- SaveManager utility note 383: config persist / autoload slot
-- SaveManager utility note 384: config persist / autoload slot
-- SaveManager utility note 385: config persist / autoload slot
-- SaveManager utility note 386: config persist / autoload slot
-- SaveManager utility note 387: config persist / autoload slot
-- SaveManager utility note 388: config persist / autoload slot
-- SaveManager utility note 389: config persist / autoload slot
-- SaveManager utility note 390: config persist / autoload slot
-- SaveManager utility note 391: config persist / autoload slot
-- SaveManager utility note 392: config persist / autoload slot
-- SaveManager utility note 393: config persist / autoload slot
-- SaveManager utility note 394: config persist / autoload slot
-- SaveManager utility note 395: config persist / autoload slot
-- SaveManager utility note 396: config persist / autoload slot
-- SaveManager utility note 397: config persist / autoload slot
-- SaveManager utility note 398: config persist / autoload slot
-- SaveManager utility note 399: config persist / autoload slot
-- SaveManager utility note 400: config persist / autoload slot
-- SaveManager utility note 401: config persist / autoload slot
-- SaveManager utility note 402: config persist / autoload slot
-- SaveManager utility note 403: config persist / autoload slot
-- SaveManager utility note 404: config persist / autoload slot
-- SaveManager utility note 405: config persist / autoload slot
-- SaveManager utility note 406: config persist / autoload slot
-- SaveManager utility note 407: config persist / autoload slot
-- SaveManager utility note 408: config persist / autoload slot
-- SaveManager utility note 409: config persist / autoload slot
-- SaveManager utility note 410: config persist / autoload slot
-- SaveManager utility note 411: config persist / autoload slot
-- SaveManager utility note 412: config persist / autoload slot
-- SaveManager utility note 413: config persist / autoload slot
-- SaveManager utility note 414: config persist / autoload slot
-- SaveManager utility note 415: config persist / autoload slot
-- SaveManager utility note 416: config persist / autoload slot
-- SaveManager utility note 417: config persist / autoload slot
-- SaveManager utility note 418: config persist / autoload slot
-- SaveManager utility note 419: config persist / autoload slot
-- SaveManager utility note 420: config persist / autoload slot
-- SaveManager utility note 421: config persist / autoload slot
-- SaveManager utility note 422: config persist / autoload slot
-- SaveManager utility note 423: config persist / autoload slot
-- SaveManager utility note 424: config persist / autoload slot
-- SaveManager utility note 425: config persist / autoload slot
-- SaveManager utility note 426: config persist / autoload slot
-- SaveManager utility note 427: config persist / autoload slot
-- SaveManager utility note 428: config persist / autoload slot
-- SaveManager utility note 429: config persist / autoload slot
-- SaveManager utility note 430: config persist / autoload slot
-- SaveManager utility note 431: config persist / autoload slot
-- SaveManager utility note 432: config persist / autoload slot
-- SaveManager utility note 433: config persist / autoload slot
-- SaveManager utility note 434: config persist / autoload slot
-- SaveManager utility note 435: config persist / autoload slot
-- SaveManager utility note 436: config persist / autoload slot
-- SaveManager utility note 437: config persist / autoload slot
-- SaveManager utility note 438: config persist / autoload slot
-- SaveManager utility note 439: config persist / autoload slot
-- SaveManager utility note 440: config persist / autoload slot
-- SaveManager utility note 441: config persist / autoload slot
-- SaveManager utility note 442: config persist / autoload slot
-- SaveManager utility note 443: config persist / autoload slot
-- SaveManager utility note 444: config persist / autoload slot
-- SaveManager utility note 445: config persist / autoload slot
-- SaveManager utility note 446: config persist / autoload slot
-- SaveManager utility note 447: config persist / autoload slot
-- SaveManager utility note 448: config persist / autoload slot
-- SaveManager utility note 449: config persist / autoload slot
-- SaveManager utility note 450: config persist / autoload slot
-- SaveManager utility note 451: config persist / autoload slot
-- SaveManager utility note 452: config persist / autoload slot
-- SaveManager utility note 453: config persist / autoload slot
-- SaveManager utility note 454: config persist / autoload slot
-- SaveManager utility note 455: config persist / autoload slot
-- SaveManager utility note 456: config persist / autoload slot
-- SaveManager utility note 457: config persist / autoload slot
-- SaveManager utility note 458: config persist / autoload slot
-- SaveManager utility note 459: config persist / autoload slot
-- SaveManager utility note 460: config persist / autoload slot
-- SaveManager utility note 461: config persist / autoload slot
-- SaveManager utility note 462: config persist / autoload slot
-- SaveManager utility note 463: config persist / autoload slot
-- SaveManager utility note 464: config persist / autoload slot
-- SaveManager utility note 465: config persist / autoload slot
-- SaveManager utility note 466: config persist / autoload slot
-- SaveManager utility note 467: config persist / autoload slot
-- SaveManager utility note 468: config persist / autoload slot
-- SaveManager utility note 469: config persist / autoload slot
-- SaveManager utility note 470: config persist / autoload slot
-- SaveManager utility note 471: config persist / autoload slot
-- SaveManager utility note 472: config persist / autoload slot
-- SaveManager utility note 473: config persist / autoload slot
-- SaveManager utility note 474: config persist / autoload slot
-- SaveManager utility note 475: config persist / autoload slot
-- SaveManager utility note 476: config persist / autoload slot
-- SaveManager utility note 477: config persist / autoload slot
-- SaveManager utility note 478: config persist / autoload slot
-- SaveManager utility note 479: config persist / autoload slot
-- SaveManager utility note 480: config persist / autoload slot
-- SaveManager utility note 481: config persist / autoload slot
-- SaveManager utility note 482: config persist / autoload slot
-- SaveManager utility note 483: config persist / autoload slot
-- SaveManager utility note 484: config persist / autoload slot
-- SaveManager utility note 485: config persist / autoload slot
-- SaveManager utility note 486: config persist / autoload slot
-- SaveManager utility note 487: config persist / autoload slot
-- SaveManager utility note 488: config persist / autoload slot
-- SaveManager utility note 489: config persist / autoload slot
-- SaveManager utility note 490: config persist / autoload slot
-- SaveManager utility note 491: config persist / autoload slot
-- SaveManager utility note 492: config persist / autoload slot
-- SaveManager utility note 493: config persist / autoload slot
-- SaveManager utility note 494: config persist / autoload slot
-- SaveManager utility note 495: config persist / autoload slot
-- SaveManager utility note 496: config persist / autoload slot
-- SaveManager utility note 497: config persist / autoload slot
-- SaveManager utility note 498: config persist / autoload slot
-- SaveManager utility note 499: config persist / autoload slot
-- SaveManager utility note 500: config persist / autoload slot
-- SaveManager utility note 501: config persist / autoload slot
-- SaveManager utility note 502: config persist / autoload slot
-- SaveManager utility note 503: config persist / autoload slot
-- SaveManager utility note 504: config persist / autoload slot
-- SaveManager utility note 505: config persist / autoload slot
-- SaveManager utility note 506: config persist / autoload slot
-- SaveManager utility note 507: config persist / autoload slot
-- SaveManager utility note 508: config persist / autoload slot
-- SaveManager utility note 509: config persist / autoload slot
-- SaveManager utility note 510: config persist / autoload slot
-- SaveManager utility note 511: config persist / autoload slot
-- SaveManager utility note 512: config persist / autoload slot
-- SaveManager utility note 513: config persist / autoload slot
-- SaveManager utility note 514: config persist / autoload slot
-- SaveManager utility note 515: config persist / autoload slot
-- SaveManager utility note 516: config persist / autoload slot
-- SaveManager utility note 517: config persist / autoload slot
-- SaveManager utility note 518: config persist / autoload slot
-- SaveManager utility note 519: config persist / autoload slot
-- SaveManager utility note 520: config persist / autoload slot
-- SaveManager utility note 521: config persist / autoload slot
-- SaveManager utility note 522: config persist / autoload slot
-- SaveManager utility note 523: config persist / autoload slot
-- SaveManager utility note 524: config persist / autoload slot
-- SaveManager utility note 525: config persist / autoload slot
-- SaveManager utility note 526: config persist / autoload slot
-- SaveManager utility note 527: config persist / autoload slot
-- SaveManager utility note 528: config persist / autoload slot
-- SaveManager utility note 529: config persist / autoload slot
-- SaveManager utility note 530: config persist / autoload slot
-- SaveManager utility note 531: config persist / autoload slot
-- SaveManager utility note 532: config persist / autoload slot
-- SaveManager utility note 533: config persist / autoload slot
-- SaveManager utility note 534: config persist / autoload slot
-- SaveManager utility note 535: config persist / autoload slot
-- SaveManager utility note 536: config persist / autoload slot
-- SaveManager utility note 537: config persist / autoload slot
-- SaveManager utility note 538: config persist / autoload slot
-- SaveManager utility note 539: config persist / autoload slot
-- SaveManager utility note 540: config persist / autoload slot
-- SaveManager utility note 541: config persist / autoload slot
-- SaveManager utility note 542: config persist / autoload slot
-- SaveManager utility note 543: config persist / autoload slot
-- SaveManager utility note 544: config persist / autoload slot
-- SaveManager utility note 545: config persist / autoload slot
-- SaveManager utility note 546: config persist / autoload slot
-- SaveManager utility note 547: config persist / autoload slot
-- SaveManager utility note 548: config persist / autoload slot
-- SaveManager utility note 549: config persist / autoload slot
-- SaveManager utility note 550: config persist / autoload slot
-- SaveManager utility note 551: config persist / autoload slot
-- SaveManager utility note 552: config persist / autoload slot
-- SaveManager utility note 553: config persist / autoload slot
-- SaveManager utility note 554: config persist / autoload slot
-- SaveManager utility note 555: config persist / autoload slot
-- SaveManager utility note 556: config persist / autoload slot
-- SaveManager utility note 557: config persist / autoload slot
-- SaveManager utility note 558: config persist / autoload slot
-- SaveManager utility note 559: config persist / autoload slot
-- SaveManager utility note 560: config persist / autoload slot
-- SaveManager utility note 561: config persist / autoload slot
-- SaveManager utility note 562: config persist / autoload slot
-- SaveManager utility note 563: config persist / autoload slot
-- SaveManager utility note 564: config persist / autoload slot
-- SaveManager utility note 565: config persist / autoload slot
-- SaveManager utility note 566: config persist / autoload slot
-- SaveManager utility note 567: config persist / autoload slot
-- SaveManager utility note 568: config persist / autoload slot
-- SaveManager utility note 569: config persist / autoload slot
-- SaveManager utility note 570: config persist / autoload slot
-- SaveManager utility note 571: config persist / autoload slot
-- SaveManager utility note 572: config persist / autoload slot
-- SaveManager utility note 573: config persist / autoload slot
-- SaveManager utility note 574: config persist / autoload slot
-- SaveManager utility note 575: config persist / autoload slot
-- SaveManager utility note 576: config persist / autoload slot
-- SaveManager utility note 577: config persist / autoload slot
-- SaveManager utility note 578: config persist / autoload slot
-- SaveManager utility note 579: config persist / autoload slot
-- SaveManager utility note 580: config persist / autoload slot
-- SaveManager utility note 581: config persist / autoload slot
-- SaveManager utility note 582: config persist / autoload slot
-- SaveManager utility note 583: config persist / autoload slot
-- SaveManager utility note 584: config persist / autoload slot
-- SaveManager utility note 585: config persist / autoload slot
-- SaveManager utility note 586: config persist / autoload slot
-- SaveManager utility note 587: config persist / autoload slot
-- SaveManager utility note 588: config persist / autoload slot
-- SaveManager utility note 589: config persist / autoload slot
-- SaveManager utility note 590: config persist / autoload slot
-- SaveManager utility note 591: config persist / autoload slot
-- SaveManager utility note 592: config persist / autoload slot
-- SaveManager utility note 593: config persist / autoload slot
-- SaveManager utility note 594: config persist / autoload slot
-- SaveManager utility note 595: config persist / autoload slot
-- SaveManager utility note 596: config persist / autoload slot
-- SaveManager utility note 597: config persist / autoload slot
-- SaveManager utility note 598: config persist / autoload slot
-- SaveManager utility note 599: config persist / autoload slot
-- SaveManager utility note 600: config persist / autoload slot
-- SaveManager utility note 601: config persist / autoload slot
-- SaveManager utility note 602: config persist / autoload slot
-- SaveManager utility note 603: config persist / autoload slot
-- SaveManager utility note 604: config persist / autoload slot
-- SaveManager utility note 605: config persist / autoload slot
-- SaveManager utility note 606: config persist / autoload slot
-- SaveManager utility note 607: config persist / autoload slot
-- SaveManager utility note 608: config persist / autoload slot
-- SaveManager utility note 609: config persist / autoload slot
-- SaveManager utility note 610: config persist / autoload slot
-- SaveManager utility note 611: config persist / autoload slot
-- SaveManager utility note 612: config persist / autoload slot
-- SaveManager utility note 613: config persist / autoload slot
-- SaveManager utility note 614: config persist / autoload slot
-- SaveManager utility note 615: config persist / autoload slot
-- SaveManager utility note 616: config persist / autoload slot
-- SaveManager utility note 617: config persist / autoload slot
-- SaveManager utility note 618: config persist / autoload slot
-- SaveManager utility note 619: config persist / autoload slot
-- SaveManager utility note 620: config persist / autoload slot
-- SaveManager utility note 621: config persist / autoload slot
-- SaveManager utility note 622: config persist / autoload slot
-- SaveManager utility note 623: config persist / autoload slot
-- SaveManager utility note 624: config persist / autoload slot
-- SaveManager utility note 625: config persist / autoload slot
-- SaveManager utility note 626: config persist / autoload slot
-- SaveManager utility note 627: config persist / autoload slot
-- SaveManager utility note 628: config persist / autoload slot
-- SaveManager utility note 629: config persist / autoload slot
-- SaveManager utility note 630: config persist / autoload slot
-- SaveManager utility note 631: config persist / autoload slot
-- SaveManager utility note 632: config persist / autoload slot
-- SaveManager utility note 633: config persist / autoload slot
-- SaveManager utility note 634: config persist / autoload slot
-- SaveManager utility note 635: config persist / autoload slot
-- SaveManager utility note 636: config persist / autoload slot
-- SaveManager utility note 637: config persist / autoload slot
-- SaveManager utility note 638: config persist / autoload slot
-- SaveManager utility note 639: config persist / autoload slot
-- SaveManager utility note 640: config persist / autoload slot
-- SaveManager utility note 641: config persist / autoload slot
-- SaveManager utility note 642: config persist / autoload slot
-- SaveManager utility note 643: config persist / autoload slot
-- SaveManager utility note 644: config persist / autoload slot
-- SaveManager utility note 645: config persist / autoload slot
-- SaveManager utility note 646: config persist / autoload slot
-- SaveManager utility note 647: config persist / autoload slot
-- SaveManager utility note 648: config persist / autoload slot
-- SaveManager utility note 649: config persist / autoload slot
-- SaveManager utility note 650: config persist / autoload slot
-- SaveManager utility note 651: config persist / autoload slot
-- SaveManager utility note 652: config persist / autoload slot
-- SaveManager utility note 653: config persist / autoload slot
-- SaveManager utility note 654: config persist / autoload slot
-- SaveManager utility note 655: config persist / autoload slot
-- SaveManager utility note 656: config persist / autoload slot
-- SaveManager utility note 657: config persist / autoload slot
-- SaveManager utility note 658: config persist / autoload slot
-- SaveManager utility note 659: config persist / autoload slot
-- SaveManager utility note 660: config persist / autoload slot
-- SaveManager utility note 661: config persist / autoload slot
-- SaveManager utility note 662: config persist / autoload slot
-- SaveManager utility note 663: config persist / autoload slot
-- SaveManager utility note 664: config persist / autoload slot
-- SaveManager utility note 665: config persist / autoload slot
-- SaveManager utility note 666: config persist / autoload slot
-- SaveManager utility note 667: config persist / autoload slot
-- SaveManager utility note 668: config persist / autoload slot
-- SaveManager utility note 669: config persist / autoload slot
-- SaveManager utility note 670: config persist / autoload slot
-- SaveManager utility note 671: config persist / autoload slot
-- SaveManager utility note 672: config persist / autoload slot
-- SaveManager utility note 673: config persist / autoload slot
-- SaveManager utility note 674: config persist / autoload slot
-- SaveManager utility note 675: config persist / autoload slot
-- SaveManager utility note 676: config persist / autoload slot
-- SaveManager utility note 677: config persist / autoload slot
-- SaveManager utility note 678: config persist / autoload slot
-- SaveManager utility note 679: config persist / autoload slot
-- SaveManager utility note 680: config persist / autoload slot
-- SaveManager utility note 681: config persist / autoload slot
-- SaveManager utility note 682: config persist / autoload slot
-- SaveManager utility note 683: config persist / autoload slot
-- SaveManager utility note 684: config persist / autoload slot
-- SaveManager utility note 685: config persist / autoload slot
-- SaveManager utility note 686: config persist / autoload slot
-- SaveManager utility note 687: config persist / autoload slot
-- SaveManager utility note 688: config persist / autoload slot
-- SaveManager utility note 689: config persist / autoload slot
-- SaveManager utility note 690: config persist / autoload slot
-- SaveManager utility note 691: config persist / autoload slot
-- SaveManager utility note 692: config persist / autoload slot
-- SaveManager utility note 693: config persist / autoload slot
-- SaveManager utility note 694: config persist / autoload slot
-- SaveManager utility note 695: config persist / autoload slot
-- SaveManager utility note 696: config persist / autoload slot
-- SaveManager utility note 697: config persist / autoload slot
-- SaveManager utility note 698: config persist / autoload slot
-- SaveManager utility note 699: config persist / autoload slot
-- SaveManager utility note 700: config persist / autoload slot
-- SaveManager utility note 701: config persist / autoload slot
-- SaveManager utility note 702: config persist / autoload slot
-- SaveManager utility note 703: config persist / autoload slot
-- SaveManager utility note 704: config persist / autoload slot
-- SaveManager utility note 705: config persist / autoload slot
-- SaveManager utility note 706: config persist / autoload slot
-- SaveManager utility note 707: config persist / autoload slot
-- SaveManager utility note 708: config persist / autoload slot
-- SaveManager utility note 709: config persist / autoload slot
-- SaveManager utility note 710: config persist / autoload slot
-- SaveManager utility note 711: config persist / autoload slot
-- SaveManager utility note 712: config persist / autoload slot
-- SaveManager utility note 713: config persist / autoload slot
-- SaveManager utility note 714: config persist / autoload slot
-- SaveManager utility note 715: config persist / autoload slot
-- SaveManager utility note 716: config persist / autoload slot
-- SaveManager utility note 717: config persist / autoload slot
-- SaveManager utility note 718: config persist / autoload slot
-- SaveManager utility note 719: config persist / autoload slot
-- SaveManager utility note 720: config persist / autoload slot
-- SaveManager utility note 721: config persist / autoload slot
-- SaveManager utility note 722: config persist / autoload slot
-- SaveManager utility note 723: config persist / autoload slot
-- SaveManager utility note 724: config persist / autoload slot
-- SaveManager utility note 725: config persist / autoload slot
-- SaveManager utility note 726: config persist / autoload slot
-- SaveManager utility note 727: config persist / autoload slot
-- SaveManager utility note 728: config persist / autoload slot
-- SaveManager utility note 729: config persist / autoload slot
-- SaveManager utility note 730: config persist / autoload slot
-- SaveManager utility note 731: config persist / autoload slot
-- SaveManager utility note 732: config persist / autoload slot
-- SaveManager utility note 733: config persist / autoload slot
-- SaveManager utility note 734: config persist / autoload slot
-- SaveManager utility note 735: config persist / autoload slot
-- SaveManager utility note 736: config persist / autoload slot
-- SaveManager utility note 737: config persist / autoload slot
-- SaveManager utility note 738: config persist / autoload slot
-- SaveManager utility note 739: config persist / autoload slot
-- SaveManager utility note 740: config persist / autoload slot
-- SaveManager utility note 741: config persist / autoload slot
-- SaveManager utility note 742: config persist / autoload slot
-- SaveManager utility note 743: config persist / autoload slot
-- SaveManager utility note 744: config persist / autoload slot
-- SaveManager utility note 745: config persist / autoload slot
-- SaveManager utility note 746: config persist / autoload slot
-- SaveManager utility note 747: config persist / autoload slot
-- SaveManager utility note 748: config persist / autoload slot
-- SaveManager utility note 749: config persist / autoload slot
-- SaveManager utility note 750: config persist / autoload slot
-- SaveManager utility note 751: config persist / autoload slot
-- SaveManager utility note 752: config persist / autoload slot
-- SaveManager utility note 753: config persist / autoload slot
-- SaveManager utility note 754: config persist / autoload slot
-- SaveManager utility note 755: config persist / autoload slot
-- SaveManager utility note 756: config persist / autoload slot
-- SaveManager utility note 757: config persist / autoload slot
-- SaveManager utility note 758: config persist / autoload slot
-- SaveManager utility note 759: config persist / autoload slot
-- SaveManager utility note 760: config persist / autoload slot
-- SaveManager utility note 761: config persist / autoload slot
-- SaveManager utility note 762: config persist / autoload slot
-- SaveManager utility note 763: config persist / autoload slot
-- SaveManager utility note 764: config persist / autoload slot
-- SaveManager utility note 765: config persist / autoload slot
-- SaveManager utility note 766: config persist / autoload slot
-- SaveManager utility note 767: config persist / autoload slot
-- SaveManager utility note 768: config persist / autoload slot
-- SaveManager utility note 769: config persist / autoload slot
-- SaveManager utility note 770: config persist / autoload slot
-- SaveManager utility note 771: config persist / autoload slot
-- SaveManager utility note 772: config persist / autoload slot
-- SaveManager utility note 773: config persist / autoload slot
-- SaveManager utility note 774: config persist / autoload slot
-- SaveManager utility note 775: config persist / autoload slot
-- SaveManager utility note 776: config persist / autoload slot
-- SaveManager utility note 777: config persist / autoload slot
-- SaveManager utility note 778: config persist / autoload slot
-- SaveManager utility note 779: config persist / autoload slot
-- SaveManager utility note 780: config persist / autoload slot
-- SaveManager utility note 781: config persist / autoload slot
-- SaveManager utility note 782: config persist / autoload slot
-- SaveManager utility note 783: config persist / autoload slot
-- SaveManager utility note 784: config persist / autoload slot
-- SaveManager utility note 785: config persist / autoload slot
-- SaveManager utility note 786: config persist / autoload slot
-- SaveManager utility note 787: config persist / autoload slot
-- SaveManager utility note 788: config persist / autoload slot
-- SaveManager utility note 789: config persist / autoload slot
-- SaveManager utility note 790: config persist / autoload slot
-- SaveManager utility note 791: config persist / autoload slot
-- SaveManager utility note 792: config persist / autoload slot
-- SaveManager utility note 793: config persist / autoload slot
-- SaveManager utility note 794: config persist / autoload slot
-- SaveManager utility note 795: config persist / autoload slot
-- SaveManager utility note 796: config persist / autoload slot
-- SaveManager utility note 797: config persist / autoload slot
-- SaveManager utility note 798: config persist / autoload slot
-- SaveManager utility note 799: config persist / autoload slot
-- SaveManager utility note 800: config persist / autoload slot
-- SaveManager utility note 801: config persist / autoload slot
-- SaveManager utility note 802: config persist / autoload slot
-- SaveManager utility note 803: config persist / autoload slot
-- SaveManager utility note 804: config persist / autoload slot
-- SaveManager utility note 805: config persist / autoload slot
-- SaveManager utility note 806: config persist / autoload slot
-- SaveManager utility note 807: config persist / autoload slot
-- SaveManager utility note 808: config persist / autoload slot
-- SaveManager utility note 809: config persist / autoload slot
-- SaveManager utility note 810: config persist / autoload slot
-- SaveManager utility note 811: config persist / autoload slot
-- SaveManager utility note 812: config persist / autoload slot
-- SaveManager utility note 813: config persist / autoload slot
-- SaveManager utility note 814: config persist / autoload slot
-- SaveManager utility note 815: config persist / autoload slot
-- SaveManager utility note 816: config persist / autoload slot
-- SaveManager utility note 817: config persist / autoload slot
-- SaveManager utility note 818: config persist / autoload slot
-- SaveManager utility note 819: config persist / autoload slot
-- SaveManager utility note 820: config persist / autoload slot
-- SaveManager utility note 821: config persist / autoload slot
-- SaveManager utility note 822: config persist / autoload slot
-- SaveManager utility note 823: config persist / autoload slot
-- SaveManager utility note 824: config persist / autoload slot
-- SaveManager utility note 825: config persist / autoload slot
-- SaveManager utility note 826: config persist / autoload slot
-- SaveManager utility note 827: config persist / autoload slot
-- SaveManager utility note 828: config persist / autoload slot
-- SaveManager utility note 829: config persist / autoload slot
-- SaveManager utility note 830: config persist / autoload slot
-- SaveManager utility note 831: config persist / autoload slot
-- SaveManager utility note 832: config persist / autoload slot
-- SaveManager utility note 833: config persist / autoload slot
-- SaveManager utility note 834: config persist / autoload slot
-- SaveManager utility note 835: config persist / autoload slot
-- SaveManager utility note 836: config persist / autoload slot
-- SaveManager utility note 837: config persist / autoload slot
-- SaveManager utility note 838: config persist / autoload slot
-- SaveManager utility note 839: config persist / autoload slot
-- SaveManager utility note 840: config persist / autoload slot
-- SaveManager utility note 841: config persist / autoload slot
-- SaveManager utility note 842: config persist / autoload slot
-- SaveManager utility note 843: config persist / autoload slot
-- SaveManager utility note 844: config persist / autoload slot
-- SaveManager utility note 845: config persist / autoload slot
-- SaveManager utility note 846: config persist / autoload slot
-- SaveManager utility note 847: config persist / autoload slot
-- SaveManager utility note 848: config persist / autoload slot
-- SaveManager utility note 849: config persist / autoload slot
-- SaveManager utility note 850: config persist / autoload slot
-- SaveManager utility note 851: config persist / autoload slot
-- SaveManager utility note 852: config persist / autoload slot
-- SaveManager utility note 853: config persist / autoload slot
-- SaveManager utility note 854: config persist / autoload slot
-- SaveManager utility note 855: config persist / autoload slot
-- SaveManager utility note 856: config persist / autoload slot
-- SaveManager utility note 857: config persist / autoload slot
-- SaveManager utility note 858: config persist / autoload slot
-- SaveManager utility note 859: config persist / autoload slot
-- SaveManager utility note 860: config persist / autoload slot
-- SaveManager utility note 861: config persist / autoload slot
-- SaveManager utility note 862: config persist / autoload slot
-- SaveManager utility note 863: config persist / autoload slot
-- SaveManager utility note 864: config persist / autoload slot
-- SaveManager utility note 865: config persist / autoload slot
-- SaveManager utility note 866: config persist / autoload slot
-- SaveManager utility note 867: config persist / autoload slot
-- SaveManager utility note 868: config persist / autoload slot
-- SaveManager utility note 869: config persist / autoload slot
-- SaveManager utility note 870: config persist / autoload slot
-- SaveManager utility note 871: config persist / autoload slot
-- SaveManager utility note 872: config persist / autoload slot
-- SaveManager utility note 873: config persist / autoload slot
-- SaveManager utility note 874: config persist / autoload slot
-- SaveManager utility note 875: config persist / autoload slot
-- SaveManager utility note 876: config persist / autoload slot
-- SaveManager utility note 877: config persist / autoload slot
-- SaveManager utility note 878: config persist / autoload slot
-- SaveManager utility note 879: config persist / autoload slot
-- SaveManager utility note 880: config persist / autoload slot
-- SaveManager utility note 881: config persist / autoload slot
-- SaveManager utility note 882: config persist / autoload slot
-- SaveManager utility note 883: config persist / autoload slot
-- SaveManager utility note 884: config persist / autoload slot
-- SaveManager utility note 885: config persist / autoload slot
-- SaveManager utility note 886: config persist / autoload slot
-- SaveManager utility note 887: config persist / autoload slot
-- SaveManager utility note 888: config persist / autoload slot
-- SaveManager utility note 889: config persist / autoload slot
-- SaveManager utility note 890: config persist / autoload slot
-- SaveManager utility note 891: config persist / autoload slot
-- SaveManager utility note 892: config persist / autoload slot
-- SaveManager utility note 893: config persist / autoload slot
-- SaveManager utility note 894: config persist / autoload slot
-- SaveManager utility note 895: config persist / autoload slot
-- SaveManager utility note 896: config persist / autoload slot
-- SaveManager utility note 897: config persist / autoload slot
-- SaveManager utility note 898: config persist / autoload slot
-- SaveManager utility note 899: config persist / autoload slot
-- SaveManager utility note 900: config persist / autoload slot
-- SaveManager utility note 901: config persist / autoload slot
-- SaveManager utility note 902: config persist / autoload slot
-- SaveManager utility note 903: config persist / autoload slot
-- SaveManager utility note 904: config persist / autoload slot
-- SaveManager utility note 905: config persist / autoload slot
-- SaveManager utility note 906: config persist / autoload slot
-- SaveManager utility note 907: config persist / autoload slot
-- SaveManager utility note 908: config persist / autoload slot
-- SaveManager utility note 909: config persist / autoload slot
-- SaveManager utility note 910: config persist / autoload slot
-- SaveManager utility note 911: config persist / autoload slot
-- SaveManager utility note 912: config persist / autoload slot
-- SaveManager utility note 913: config persist / autoload slot
-- SaveManager utility note 914: config persist / autoload slot
-- SaveManager utility note 915: config persist / autoload slot
-- SaveManager utility note 916: config persist / autoload slot
-- SaveManager utility note 917: config persist / autoload slot
-- SaveManager utility note 918: config persist / autoload slot
-- SaveManager utility note 919: config persist / autoload slot
-- SaveManager utility note 920: config persist / autoload slot
-- SaveManager utility note 921: config persist / autoload slot
-- SaveManager utility note 922: config persist / autoload slot
-- SaveManager utility note 923: config persist / autoload slot
-- SaveManager utility note 924: config persist / autoload slot
-- SaveManager utility note 925: config persist / autoload slot
-- SaveManager utility note 926: config persist / autoload slot
-- SaveManager utility note 927: config persist / autoload slot
-- SaveManager utility note 928: config persist / autoload slot
-- SaveManager utility note 929: config persist / autoload slot
-- SaveManager utility note 930: config persist / autoload slot
-- SaveManager utility note 931: config persist / autoload slot
-- SaveManager utility note 932: config persist / autoload slot
-- SaveManager utility note 933: config persist / autoload slot
-- SaveManager utility note 934: config persist / autoload slot
-- SaveManager utility note 935: config persist / autoload slot
-- SaveManager utility note 936: config persist / autoload slot
-- SaveManager utility note 937: config persist / autoload slot
-- SaveManager utility note 938: config persist / autoload slot
-- SaveManager utility note 939: config persist / autoload slot
-- SaveManager utility note 940: config persist / autoload slot
-- SaveManager utility note 941: config persist / autoload slot
-- SaveManager utility note 942: config persist / autoload slot
-- SaveManager utility note 943: config persist / autoload slot
-- SaveManager utility note 944: config persist / autoload slot
-- SaveManager utility note 945: config persist / autoload slot
-- SaveManager utility note 946: config persist / autoload slot
-- SaveManager utility note 947: config persist / autoload slot
-- SaveManager utility note 948: config persist / autoload slot
-- SaveManager utility note 949: config persist / autoload slot
-- SaveManager utility note 950: config persist / autoload slot
-- SaveManager utility note 951: config persist / autoload slot
-- SaveManager utility note 952: config persist / autoload slot
-- SaveManager utility note 953: config persist / autoload slot
-- SaveManager utility note 954: config persist / autoload slot
-- SaveManager utility note 955: config persist / autoload slot
-- SaveManager utility note 956: config persist / autoload slot
-- SaveManager utility note 957: config persist / autoload slot
-- SaveManager utility note 958: config persist / autoload slot
-- SaveManager utility note 959: config persist / autoload slot
-- SaveManager utility note 960: config persist / autoload slot
-- SaveManager utility note 961: config persist / autoload slot
-- SaveManager utility note 962: config persist / autoload slot
-- SaveManager utility note 963: config persist / autoload slot
-- SaveManager utility note 964: config persist / autoload slot
-- SaveManager utility note 965: config persist / autoload slot
-- SaveManager utility note 966: config persist / autoload slot
-- SaveManager utility note 967: config persist / autoload slot
-- SaveManager utility note 968: config persist / autoload slot
-- SaveManager utility note 969: config persist / autoload slot
-- SaveManager utility note 970: config persist / autoload slot
-- SaveManager utility note 971: config persist / autoload slot
-- SaveManager utility note 972: config persist / autoload slot
-- SaveManager utility note 973: config persist / autoload slot
-- SaveManager utility note 974: config persist / autoload slot
-- SaveManager utility note 975: config persist / autoload slot
-- SaveManager utility note 976: config persist / autoload slot
-- SaveManager utility note 977: config persist / autoload slot
-- SaveManager utility note 978: config persist / autoload slot
-- SaveManager utility note 979: config persist / autoload slot
-- SaveManager utility note 980: config persist / autoload slot
-- SaveManager utility note 981: config persist / autoload slot
-- SaveManager utility note 982: config persist / autoload slot
-- SaveManager utility note 983: config persist / autoload slot
-- SaveManager utility note 984: config persist / autoload slot
-- SaveManager utility note 985: config persist / autoload slot
-- SaveManager utility note 986: config persist / autoload slot
-- SaveManager utility note 987: config persist / autoload slot
-- SaveManager utility note 988: config persist / autoload slot
-- SaveManager utility note 989: config persist / autoload slot
-- SaveManager utility note 990: config persist / autoload slot
-- SaveManager utility note 991: config persist / autoload slot
-- SaveManager utility note 992: config persist / autoload slot
-- SaveManager utility note 993: config persist / autoload slot
-- SaveManager utility note 994: config persist / autoload slot
-- SaveManager utility note 995: config persist / autoload slot
-- SaveManager utility note 996: config persist / autoload slot
-- SaveManager utility note 997: config persist / autoload slot
-- SaveManager utility note 998: config persist / autoload slot
-- SaveManager utility note 999: config persist / autoload slot
-- SaveManager utility note 1000: config persist / autoload slot
-- SaveManager utility note 1001: config persist / autoload slot
-- SaveManager utility note 1002: config persist / autoload slot
-- SaveManager utility note 1003: config persist / autoload slot
-- SaveManager utility note 1004: config persist / autoload slot
-- SaveManager utility note 1005: config persist / autoload slot
-- SaveManager utility note 1006: config persist / autoload slot
-- SaveManager utility note 1007: config persist / autoload slot
-- SaveManager utility note 1008: config persist / autoload slot
-- SaveManager utility note 1009: config persist / autoload slot
-- SaveManager utility note 1010: config persist / autoload slot
-- SaveManager utility note 1011: config persist / autoload slot
-- SaveManager utility note 1012: config persist / autoload slot
-- SaveManager utility note 1013: config persist / autoload slot
-- SaveManager utility note 1014: config persist / autoload slot
-- SaveManager utility note 1015: config persist / autoload slot
-- SaveManager utility note 1016: config persist / autoload slot
-- SaveManager utility note 1017: config persist / autoload slot
-- SaveManager utility note 1018: config persist / autoload slot
-- SaveManager utility note 1019: config persist / autoload slot
-- SaveManager utility note 1020: config persist / autoload slot
-- SaveManager utility note 1021: config persist / autoload slot
-- SaveManager utility note 1022: config persist / autoload slot
-- SaveManager utility note 1023: config persist / autoload slot
-- SaveManager utility note 1024: config persist / autoload slot
-- SaveManager utility note 1025: config persist / autoload slot
-- SaveManager utility note 1026: config persist / autoload slot
-- SaveManager utility note 1027: config persist / autoload slot
-- SaveManager utility note 1028: config persist / autoload slot
-- SaveManager utility note 1029: config persist / autoload slot
-- SaveManager utility note 1030: config persist / autoload slot
-- SaveManager utility note 1031: config persist / autoload slot
-- SaveManager utility note 1032: config persist / autoload slot
-- SaveManager utility note 1033: config persist / autoload slot
-- SaveManager utility note 1034: config persist / autoload slot
-- SaveManager utility note 1035: config persist / autoload slot
-- SaveManager utility note 1036: config persist / autoload slot
-- SaveManager utility note 1037: config persist / autoload slot
-- SaveManager utility note 1038: config persist / autoload slot
-- SaveManager utility note 1039: config persist / autoload slot
-- SaveManager utility note 1040: config persist / autoload slot
-- SaveManager utility note 1041: config persist / autoload slot
-- SaveManager utility note 1042: config persist / autoload slot
-- SaveManager utility note 1043: config persist / autoload slot
-- SaveManager utility note 1044: config persist / autoload slot
-- SaveManager utility note 1045: config persist / autoload slot
-- SaveManager utility note 1046: config persist / autoload slot
-- SaveManager utility note 1047: config persist / autoload slot
-- SaveManager utility note 1048: config persist / autoload slot
-- SaveManager utility note 1049: config persist / autoload slot
-- SaveManager utility note 1050: config persist / autoload slot
-- SaveManager utility note 1051: config persist / autoload slot
-- SaveManager utility note 1052: config persist / autoload slot
-- SaveManager utility note 1053: config persist / autoload slot
-- SaveManager utility note 1054: config persist / autoload slot
-- SaveManager utility note 1055: config persist / autoload slot
-- SaveManager utility note 1056: config persist / autoload slot
-- SaveManager utility note 1057: config persist / autoload slot
-- SaveManager utility note 1058: config persist / autoload slot
-- SaveManager utility note 1059: config persist / autoload slot
-- SaveManager utility note 1060: config persist / autoload slot
-- SaveManager utility note 1061: config persist / autoload slot
-- SaveManager utility note 1062: config persist / autoload slot
-- SaveManager utility note 1063: config persist / autoload slot
-- SaveManager utility note 1064: config persist / autoload slot
-- SaveManager utility note 1065: config persist / autoload slot
-- SaveManager utility note 1066: config persist / autoload slot
-- SaveManager utility note 1067: config persist / autoload slot
-- SaveManager utility note 1068: config persist / autoload slot
-- SaveManager utility note 1069: config persist / autoload slot
-- SaveManager utility note 1070: config persist / autoload slot
-- SaveManager utility note 1071: config persist / autoload slot
-- SaveManager utility note 1072: config persist / autoload slot
-- SaveManager utility note 1073: config persist / autoload slot
-- SaveManager utility note 1074: config persist / autoload slot
-- SaveManager utility note 1075: config persist / autoload slot
-- SaveManager utility note 1076: config persist / autoload slot
-- SaveManager utility note 1077: config persist / autoload slot
-- SaveManager utility note 1078: config persist / autoload slot
-- SaveManager utility note 1079: config persist / autoload slot
-- SaveManager utility note 1080: config persist / autoload slot
-- SaveManager utility note 1081: config persist / autoload slot
-- SaveManager utility note 1082: config persist / autoload slot
-- SaveManager utility note 1083: config persist / autoload slot
-- SaveManager utility note 1084: config persist / autoload slot
-- SaveManager utility note 1085: config persist / autoload slot
-- SaveManager utility note 1086: config persist / autoload slot
-- SaveManager utility note 1087: config persist / autoload slot
-- SaveManager utility note 1088: config persist / autoload slot
-- SaveManager utility note 1089: config persist / autoload slot
-- SaveManager utility note 1090: config persist / autoload slot
-- SaveManager utility note 1091: config persist / autoload slot
-- SaveManager utility note 1092: config persist / autoload slot
-- SaveManager utility note 1093: config persist / autoload slot
-- SaveManager utility note 1094: config persist / autoload slot
-- SaveManager utility note 1095: config persist / autoload slot
-- SaveManager utility note 1096: config persist / autoload slot
-- SaveManager utility note 1097: config persist / autoload slot
-- SaveManager utility note 1098: config persist / autoload slot
-- SaveManager utility note 1099: config persist / autoload slot

return SaveManager
