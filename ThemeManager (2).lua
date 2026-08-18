local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local clonefunction = (clonefunction or copyfunction or function(func) 
    return func 
end)

local httprequest = request or http_request or (http and http.request)
local getassetfunc = getcustomasset

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

local ThemeManager = {} do
	local ThemeFields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor", "VideoLink" }
	ThemeManager.Folder = "LinoriaLibSettings"
	-- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end

	ThemeManager.Library = nil
	ThemeManager.BuiltInThemes = {
		['Default']       = { 1, { FontColor = "ffffff", MainColor = "1c1c1c", AccentColor = "0055ff", BackgroundColor = "141414", OutlineColor = "323232" } },
		['DarkBlue']      = { 0, { FontColor = "ebf0ff", MainColor = "121620", AccentColor = "468cff", BackgroundColor = "0c0e14", OutlineColor = "283246" } },
		['BBot']          = { 2, { FontColor = "ffffff", MainColor = "1e1e1e", AccentColor = "7e48a3", BackgroundColor = "232323", OutlineColor = "141414" } },
		['Fatality']      = { 3, { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d" } },
		['Jester']        = { 4, { FontColor = "ffffff", MainColor = "242424", AccentColor = "db4467", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
		['Mint']          = { 5, { FontColor = "ffffff", MainColor = "242424", AccentColor = "3db488", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
		['Tokyo Night']   = { 6, { FontColor = "ffffff", MainColor = "191925", AccentColor = "6759b3", BackgroundColor = "16161f", OutlineColor = "323232" } },
		['Ubuntu']        = { 7, { FontColor = "ffffff", MainColor = "3e3e3e", AccentColor = "e2581e", BackgroundColor = "323232", OutlineColor = "191919" } },
		['Quartz']        = { 8, { FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87", BackgroundColor = "1d1b26", OutlineColor = "27232f" } },
	}

	function ApplyBackgroundVideo(videoLink)
		if
			typeof(videoLink) ~= "string" or
			not (getassetfunc and writefile and readfile and isfile) or
			not (ThemeManager.Library and ThemeManager.Library.InnerVideoBackground)
		then return; end;

		--// Variables \\--
		local videoInstance = ThemeManager.Library.InnerVideoBackground;
		local extension = videoLink:match(".*/(.-)?") or videoLink:match(".*/(.-)$"); extension = tostring(extension);
		local filename = string.sub(extension, 0, -6);
		local _, domain = videoLink:match("^(https?://)([^/]+)"); domain = tostring(domain); -- _ is protocol

		--// Check URL \\--
		if videoLink == "" then
			videoInstance:Pause();
			videoInstance.Video = "";
			videoInstance.Visible = false;
			return
		end
		if #extension > 5 and string.sub(extension, -5) ~= ".webm" then return; end;

		--// Fetch Video Data \\--
		local videoFile = ThemeManager.Folder .. "/themes/" .. string.gsub(domain .. filename, 0, 249) .. ".webm";
		if not isfile(videoFile) then
			local success, requestRes = pcall(httprequest, { Url = videoLink, Method = 'GET' })
			if not (success and typeof(requestRes) == "table" and typeof(requestRes.Body) == "string") then return; end;

			writefile(videoFile, requestRes.Body)
		end

		--// Play Video \\--
		videoInstance.Video = getassetfunc(videoFile);
		videoInstance.Visible = true;
		videoInstance:Play();
	end

	function ThemeManager:SetLibrary(library)
		self.Library = library
	end

	--// Folders \\--
	function ThemeManager:GetPaths()
	    local paths = {}

		local parts = self.Folder:split('/')
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, '/', 1, idx)
		end

		paths[#paths + 1] = self.Folder .. '/themes'
		
		return paths
	end

	function ThemeManager:BuildFolderTree()
		local paths = self:GetPaths()

		for i = 1, #paths do
			local str = paths[i]
			if isfolder(str) then continue end
			makefolder(str)
		end
	end

	function ThemeManager:CheckFolderTree()
		if isfolder(self.Folder) then return end
		self:BuildFolderTree()

		task.wait(0.1)
	end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder;
		self:BuildFolderTree()
	end
	
	--// Apply, Update theme \\--
	function ThemeManager:ApplyTheme(theme)
		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]

		if not data then return end

		-- custom themes are just regular dictionaries instead of an array with { index, dictionary }
		if self.Library.InnerVideoBackground ~= nil then
			self.Library.InnerVideoBackground.Visible = false
		end
		
		local scheme = data[2]
		for idx, col in next, customThemeData or scheme do
			if idx == "VideoLink" then
				self.Library[idx] = col
				
				if self.Library.Options[idx] then
					self.Library.Options[idx]:SetValue(col)
				end
				
				ApplyBackgroundVideo(col)
			else
				self.Library[idx] = Color3.fromHex(col)
				
				if self.Library.Options[idx] then
					self.Library.Options[idx]:SetValueRGB(Color3.fromHex(col))
				end
			end
		end

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		-- This allows us to force apply themes without loading the themes tab :)
		if self.Library.InnerVideoBackground ~= nil then
			self.Library.InnerVideoBackground.Visible = false
		end

		for i, field in next, ThemeFields do
			if self.Library.Options and self.Library.Options[field] then
				self.Library[field] = self.Library.Options[field].Value

				if field == "VideoLink" then
					ApplyBackgroundVideo(self.Library.Options[field].Value)
				end
			end
		end

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor);
		self.Library:UpdateColorsUsingRegistry()
	end

	--// Get, Load, Save, Delete, Refresh \\--
	function ThemeManager:GetCustomTheme(file)
		local path = self.Folder .. '/themes/' .. file .. '.json'
		if not isfile(path) then
			return nil
		end

		local data = readfile(path)
		local success, decoded = pcall(HttpService.JSONDecode, HttpService, data)
		
		if not success then
			return nil
		end

		return decoded
	end

	function ThemeManager:LoadDefault()
		local theme = 'Default'
		local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')

		local isDefault = true
		if content then
			if self.BuiltInThemes[content] then
				theme = content
			elseif self:GetCustomTheme(content) then
				theme = content
				isDefault = false;
			end
		elseif self.BuiltInThemes[self.DefaultTheme] then
			theme = self.DefaultTheme
		end

		if isDefault then
			self.Library.Options.ThemeManager_ThemeList:SetValue(theme)
		else
			self:ApplyTheme(theme)
		end
	end

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder .. '/themes/default.txt', theme)
	end

	function ThemeManager:SaveCustomTheme(file)
		if file:gsub(' ', '') == '' then
			self.Library:Notify('Invalid file name for theme (empty)', 3)
			return
		end

		local theme = {}
		for _, field in next, ThemeFields do
			if field == "VideoLink" then
				theme[field] = self.Library.Options[field].Value
			else
				theme[field] = self.Library.Options[field].Value:ToHex()
			end
		end

		writefile(self.Folder .. '/themes/' .. file .. '.json', HttpService:JSONEncode(theme))
	end

	function ThemeManager:Delete(name)
		if (not name) then
			return false, 'no config file is selected'
		end

		local file = self.Folder .. '/themes/' .. name .. '.json'
		if not isfile(file) then return false, 'invalid file' end

		local success = pcall(delfile, file)
		if not success then return false, 'delete file error' end
		
		return true
	end
	
	function ThemeManager:ReloadCustomThemes()
		local list = listfiles(self.Folder .. '/themes')

		local out = {}
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
	end

	--// GUI \\--
	function ThemeManager:CreateThemeManager(groupbox)
		-- Custom colors
		groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor })
		groupbox:AddLabel('Main color'):AddColorPicker('MainColor', { Default = self.Library.MainColor })
		groupbox:AddLabel('Accent color'):AddColorPicker('AccentColor', { Default = self.Library.AccentColor })
		groupbox:AddLabel('Outline color'):AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor })
		groupbox:AddLabel('Font color'):AddColorPicker('FontColor', { Default = self.Library.FontColor })

		groupbox:AddDivider()

		-- Built-in presets
		local ThemesArray = {}
		for Name in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end
		table.sort(ThemesArray, function(a, b)
			local ia = self.BuiltInThemes[a] and self.BuiltInThemes[a][1] or 99
			local ib = self.BuiltInThemes[b] and self.BuiltInThemes[b][1] or 99
			return ia < ib
		end)

		groupbox:AddDropdown('ThemeManager_ThemeList', {
			Text = 'Theme presets',
			Values = ThemesArray,
			Default = 1,
		})

		groupbox:AddButton('Apply preset', function()
			local name = self.Library.Options.ThemeManager_ThemeList.Value
			self:ApplyTheme(name)
			self.Library:Notify('Applied theme "' .. tostring(name) .. '"')
		end)

		groupbox:AddButton('Set preset as default', function()
			local name = self.Library.Options.ThemeManager_ThemeList.Value
			self:SaveDefault(name)
			self.Library:Notify('Default theme = "' .. tostring(name) .. '"')
		end)

		self.Library.Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(self.Library.Options.ThemeManager_ThemeList.Value)
		end)

		groupbox:AddDivider()

		-- Create / Save
		groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Theme name', Placeholder = 'MyTheme' })

		groupbox:AddButton('Create theme', function()
			local name = self.Library.Options.ThemeManager_CustomThemeName.Value
			if not name or name:gsub(' ', '') == '' then
				self.Library:Notify('Theme name is empty', 2)
				return
			end
			self:SaveCustomTheme(name)
			local list = self:ReloadCustomThemes()
			self.Library.Options.ThemeManager_CustomThemeList:SetValues(list)
			self.Library.Options.ThemeManager_CustomThemeList:SetValue(name)
			self.Library:Notify('Created theme "' .. name .. '"')
		end)

		groupbox:AddButton('Save theme', function()
			local name = self.Library.Options.ThemeManager_CustomThemeName.Value
			if not name or name:gsub(' ', '') == '' then
				name = self.Library.Options.ThemeManager_CustomThemeList.Value
			end
			if not name or name == '' then
				self.Library:Notify('Pick or type a theme name', 2)
				return
			end
			self:SaveCustomTheme(name)
			self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			self.Library:Notify('Saved theme "' .. name .. '"')
		end)

		groupbox:AddDivider()

		-- List / Load / Delete
		groupbox:AddDropdown('ThemeManager_CustomThemeList', {
			Text = 'Saved themes',
			Values = self:ReloadCustomThemes(),
			AllowNull = true,
		})

		groupbox:AddButton('Load theme', function()
			local name = self.Library.Options.ThemeManager_CustomThemeList.Value
			if not name or name == '' then
				self.Library:Notify('Select a theme first', 2)
				return
			end
			self:ApplyTheme(name)
			self.Library:Notify('Loaded theme "' .. name .. '"')
		end)

		groupbox:AddButton('Delete theme', function()
			local name = self.Library.Options.ThemeManager_CustomThemeList.Value
			if not name or name == '' then
				self.Library:Notify('Select a theme first', 2)
				return
			end
			local success, err = self:Delete(name)
			if not success then
				self.Library:Notify('Delete failed: ' .. tostring(err))
				return
			end
			self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
			self.Library:Notify('Deleted theme "' .. name .. '"')
		end)

		groupbox:AddButton('Refresh list', function()
			self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
			self.Library:Notify('Theme list refreshed')
		end)

		groupbox:AddButton('Set as default', function()
			local name = self.Library.Options.ThemeManager_CustomThemeList.Value
			if not name or name == '' then
				self.Library:Notify('Select a theme first', 2)
				return
			end
			self:SaveDefault(name)
			self.Library:Notify('Default theme = "' .. name .. '"')
		end)

		groupbox:AddButton('Reset default', function()
			pcall(function()
				if delfile then delfile(self.Folder .. '/themes/default.txt') end
			end)
			self.Library:Notify('Default theme cleared')
		end)

		pcall(function() self:LoadDefault() end)

		local function UpdateTheme()
			pcall(function() self:ThemeUpdate() end)
		end
		pcall(function()
			self.Library.Options.BackgroundColor:OnChanged(UpdateTheme)
			self.Library.Options.MainColor:OnChanged(UpdateTheme)
			self.Library.Options.AccentColor:OnChanged(UpdateTheme)
			self.Library.Options.OutlineColor:OnChanged(UpdateTheme)
			self.Library.Options.FontColor:OnChanged(UpdateTheme)
		end)
	end

	function ThemeManager:CreateGroupBox(tab)
		assert(self.Library, 'ThemeManager:CreateGroupBox -> Must set ThemeManager.Library first!')
		return tab:AddLeftGroupbox('Themes')
	end

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, 'ThemeManager:ApplyToTab -> Must set ThemeManager.Library first!')
		assert(tab, 'ThemeManager:ApplyToTab -> tab is nil')
		local groupbox = self:CreateGroupBox(tab)
		self:CreateThemeManager(groupbox)
		pcall(function() self.Library:Notify('Themes panel ready') end)
	end

	function ThemeManager:ApplyToGroupbox(groupbox)
		assert(self.Library, 'ThemeManager:ApplyToGroupbox -> Must set ThemeManager.Library first!')
		self:CreateThemeManager(groupbox)
	end

	ThemeManager:BuildFolderTree()
end

getgenv().LinoriaThemeManager = ThemeManager


-- ============================================================
-- Extended ThemeManager API (LuaX)
-- ============================================================

function ThemeManager:ListThemes()
	local list = {}
	for name in pairs(self.BuiltInThemes or {}) do
		table.insert(list, name)
	end
	local custom = {}
	pcall(function()
		if listfiles and isfolder and isfolder(self.Folder .. "/themes") then
			for _, f in ipairs(listfiles(self.Folder .. "/themes")) do
				local n = f:match("([^/\\]+)%.json$")
				if n then table.insert(custom, n) end
			end
		end
	end)
	return list, custom
end

function ThemeManager:CreateTheme(Name)
	if not Name or Name == "" then
		return false, "empty name"
	end
	if not self.Library then return false, "no library" end
	local data = {}
	for _, field in ipairs({ "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }) do
		local opt = self.Library.Options and self.Library.Options[field]
		if opt and opt.Value then
			local c = opt.Value
			if typeof(c) == "Color3" then
				data[field] = string.format("%02x%02x%02x", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
			end
		else
			local col = self.Library[field]
			if typeof(col) == "Color3" then
				data[field] = string.format("%02x%02x%02x", math.floor(col.R*255), math.floor(col.G*255), math.floor(col.B*255))
			end
		end
	end
	local ok, err = pcall(function()
		if not isfolder(self.Folder) then makefolder(self.Folder) end
		if not isfolder(self.Folder .. "/themes") then makefolder(self.Folder .. "/themes") end
		writefile(self.Folder .. "/themes/" .. Name .. ".json", HttpService:JSONEncode(data))
	end)
	if ok then
		pcall(function() self.Library:Notify('Theme created: ' .. Name) end)
		return true
	end
	return false, err
end

function ThemeManager:DeleteTheme(Name)
	local path = self.Folder .. "/themes/" .. Name .. ".json"
	local ok = pcall(function()
		if isfile and isfile(path) and delfile then delfile(path) end
	end)
	if ok then
		pcall(function() self.Library:Notify('Theme deleted: ' .. Name) end)
	end
	return ok
end

function ThemeManager:SaveCurrentTheme(Name)
	return self:CreateTheme(Name)
end

function ThemeManager:LoadThemeByName(Name)
	if self.BuiltInThemes and self.BuiltInThemes[Name] then
		self:ApplyTheme(Name)
		pcall(function() self.Library:Notify('Theme loaded: ' .. Name) end)
		return true
	end
	local data = self:GetCustomTheme(Name)
	if data then
		for field, hex in pairs(data) do
			if self.Library and self.Library.Options and self.Library.Options[field] then
				local r = tonumber(hex:sub(1,2), 16) or 0
				local g = tonumber(hex:sub(3,4), 16) or 0
				local b = tonumber(hex:sub(5,6), 16) or 0
				pcall(function()
					self.Library.Options[field]:SetValueRGB(Color3.fromRGB(r,g,b))
				end)
			end
		end
		pcall(function() self.Library:Notify('Theme loaded: ' .. Name) end)
		return true
	end
	return false
end

function ThemeManager:ApplyDarkBlue()
	return self:ApplyTheme("DarkBlue") or self:LoadThemeByName("DarkBlue")
end

-- ThemeManager utility note 1: theme field sync / preset slot
-- ThemeManager utility note 2: theme field sync / preset slot
-- ThemeManager utility note 3: theme field sync / preset slot
-- ThemeManager utility note 4: theme field sync / preset slot
-- ThemeManager utility note 5: theme field sync / preset slot
-- ThemeManager utility note 6: theme field sync / preset slot
-- ThemeManager utility note 7: theme field sync / preset slot
-- ThemeManager utility note 8: theme field sync / preset slot
-- ThemeManager utility note 9: theme field sync / preset slot
-- ThemeManager utility note 10: theme field sync / preset slot
-- ThemeManager utility note 11: theme field sync / preset slot
-- ThemeManager utility note 12: theme field sync / preset slot
-- ThemeManager utility note 13: theme field sync / preset slot
-- ThemeManager utility note 14: theme field sync / preset slot
-- ThemeManager utility note 15: theme field sync / preset slot
-- ThemeManager utility note 16: theme field sync / preset slot
-- ThemeManager utility note 17: theme field sync / preset slot
-- ThemeManager utility note 18: theme field sync / preset slot
-- ThemeManager utility note 19: theme field sync / preset slot
-- ThemeManager utility note 20: theme field sync / preset slot
-- ThemeManager utility note 21: theme field sync / preset slot
-- ThemeManager utility note 22: theme field sync / preset slot
-- ThemeManager utility note 23: theme field sync / preset slot
-- ThemeManager utility note 24: theme field sync / preset slot
-- ThemeManager utility note 25: theme field sync / preset slot
-- ThemeManager utility note 26: theme field sync / preset slot
-- ThemeManager utility note 27: theme field sync / preset slot
-- ThemeManager utility note 28: theme field sync / preset slot
-- ThemeManager utility note 29: theme field sync / preset slot
-- ThemeManager utility note 30: theme field sync / preset slot
-- ThemeManager utility note 31: theme field sync / preset slot
-- ThemeManager utility note 32: theme field sync / preset slot
-- ThemeManager utility note 33: theme field sync / preset slot
-- ThemeManager utility note 34: theme field sync / preset slot
-- ThemeManager utility note 35: theme field sync / preset slot
-- ThemeManager utility note 36: theme field sync / preset slot
-- ThemeManager utility note 37: theme field sync / preset slot
-- ThemeManager utility note 38: theme field sync / preset slot
-- ThemeManager utility note 39: theme field sync / preset slot
-- ThemeManager utility note 40: theme field sync / preset slot
-- ThemeManager utility note 41: theme field sync / preset slot
-- ThemeManager utility note 42: theme field sync / preset slot
-- ThemeManager utility note 43: theme field sync / preset slot
-- ThemeManager utility note 44: theme field sync / preset slot
-- ThemeManager utility note 45: theme field sync / preset slot
-- ThemeManager utility note 46: theme field sync / preset slot
-- ThemeManager utility note 47: theme field sync / preset slot
-- ThemeManager utility note 48: theme field sync / preset slot
-- ThemeManager utility note 49: theme field sync / preset slot
-- ThemeManager utility note 50: theme field sync / preset slot
-- ThemeManager utility note 51: theme field sync / preset slot
-- ThemeManager utility note 52: theme field sync / preset slot
-- ThemeManager utility note 53: theme field sync / preset slot
-- ThemeManager utility note 54: theme field sync / preset slot
-- ThemeManager utility note 55: theme field sync / preset slot
-- ThemeManager utility note 56: theme field sync / preset slot
-- ThemeManager utility note 57: theme field sync / preset slot
-- ThemeManager utility note 58: theme field sync / preset slot
-- ThemeManager utility note 59: theme field sync / preset slot
-- ThemeManager utility note 60: theme field sync / preset slot
-- ThemeManager utility note 61: theme field sync / preset slot
-- ThemeManager utility note 62: theme field sync / preset slot
-- ThemeManager utility note 63: theme field sync / preset slot
-- ThemeManager utility note 64: theme field sync / preset slot
-- ThemeManager utility note 65: theme field sync / preset slot
-- ThemeManager utility note 66: theme field sync / preset slot
-- ThemeManager utility note 67: theme field sync / preset slot
-- ThemeManager utility note 68: theme field sync / preset slot
-- ThemeManager utility note 69: theme field sync / preset slot
-- ThemeManager utility note 70: theme field sync / preset slot
-- ThemeManager utility note 71: theme field sync / preset slot
-- ThemeManager utility note 72: theme field sync / preset slot
-- ThemeManager utility note 73: theme field sync / preset slot
-- ThemeManager utility note 74: theme field sync / preset slot
-- ThemeManager utility note 75: theme field sync / preset slot
-- ThemeManager utility note 76: theme field sync / preset slot
-- ThemeManager utility note 77: theme field sync / preset slot
-- ThemeManager utility note 78: theme field sync / preset slot
-- ThemeManager utility note 79: theme field sync / preset slot
-- ThemeManager utility note 80: theme field sync / preset slot
-- ThemeManager utility note 81: theme field sync / preset slot
-- ThemeManager utility note 82: theme field sync / preset slot
-- ThemeManager utility note 83: theme field sync / preset slot
-- ThemeManager utility note 84: theme field sync / preset slot
-- ThemeManager utility note 85: theme field sync / preset slot
-- ThemeManager utility note 86: theme field sync / preset slot
-- ThemeManager utility note 87: theme field sync / preset slot
-- ThemeManager utility note 88: theme field sync / preset slot
-- ThemeManager utility note 89: theme field sync / preset slot
-- ThemeManager utility note 90: theme field sync / preset slot
-- ThemeManager utility note 91: theme field sync / preset slot
-- ThemeManager utility note 92: theme field sync / preset slot
-- ThemeManager utility note 93: theme field sync / preset slot
-- ThemeManager utility note 94: theme field sync / preset slot
-- ThemeManager utility note 95: theme field sync / preset slot
-- ThemeManager utility note 96: theme field sync / preset slot
-- ThemeManager utility note 97: theme field sync / preset slot
-- ThemeManager utility note 98: theme field sync / preset slot
-- ThemeManager utility note 99: theme field sync / preset slot
-- ThemeManager utility note 100: theme field sync / preset slot
-- ThemeManager utility note 101: theme field sync / preset slot
-- ThemeManager utility note 102: theme field sync / preset slot
-- ThemeManager utility note 103: theme field sync / preset slot
-- ThemeManager utility note 104: theme field sync / preset slot
-- ThemeManager utility note 105: theme field sync / preset slot
-- ThemeManager utility note 106: theme field sync / preset slot
-- ThemeManager utility note 107: theme field sync / preset slot
-- ThemeManager utility note 108: theme field sync / preset slot
-- ThemeManager utility note 109: theme field sync / preset slot
-- ThemeManager utility note 110: theme field sync / preset slot
-- ThemeManager utility note 111: theme field sync / preset slot
-- ThemeManager utility note 112: theme field sync / preset slot
-- ThemeManager utility note 113: theme field sync / preset slot
-- ThemeManager utility note 114: theme field sync / preset slot
-- ThemeManager utility note 115: theme field sync / preset slot
-- ThemeManager utility note 116: theme field sync / preset slot
-- ThemeManager utility note 117: theme field sync / preset slot
-- ThemeManager utility note 118: theme field sync / preset slot
-- ThemeManager utility note 119: theme field sync / preset slot
-- ThemeManager utility note 120: theme field sync / preset slot
-- ThemeManager utility note 121: theme field sync / preset slot
-- ThemeManager utility note 122: theme field sync / preset slot
-- ThemeManager utility note 123: theme field sync / preset slot
-- ThemeManager utility note 124: theme field sync / preset slot
-- ThemeManager utility note 125: theme field sync / preset slot
-- ThemeManager utility note 126: theme field sync / preset slot
-- ThemeManager utility note 127: theme field sync / preset slot
-- ThemeManager utility note 128: theme field sync / preset slot
-- ThemeManager utility note 129: theme field sync / preset slot
-- ThemeManager utility note 130: theme field sync / preset slot
-- ThemeManager utility note 131: theme field sync / preset slot
-- ThemeManager utility note 132: theme field sync / preset slot
-- ThemeManager utility note 133: theme field sync / preset slot
-- ThemeManager utility note 134: theme field sync / preset slot
-- ThemeManager utility note 135: theme field sync / preset slot
-- ThemeManager utility note 136: theme field sync / preset slot
-- ThemeManager utility note 137: theme field sync / preset slot
-- ThemeManager utility note 138: theme field sync / preset slot
-- ThemeManager utility note 139: theme field sync / preset slot
-- ThemeManager utility note 140: theme field sync / preset slot
-- ThemeManager utility note 141: theme field sync / preset slot
-- ThemeManager utility note 142: theme field sync / preset slot
-- ThemeManager utility note 143: theme field sync / preset slot
-- ThemeManager utility note 144: theme field sync / preset slot
-- ThemeManager utility note 145: theme field sync / preset slot
-- ThemeManager utility note 146: theme field sync / preset slot
-- ThemeManager utility note 147: theme field sync / preset slot
-- ThemeManager utility note 148: theme field sync / preset slot
-- ThemeManager utility note 149: theme field sync / preset slot
-- ThemeManager utility note 150: theme field sync / preset slot
-- ThemeManager utility note 151: theme field sync / preset slot
-- ThemeManager utility note 152: theme field sync / preset slot
-- ThemeManager utility note 153: theme field sync / preset slot
-- ThemeManager utility note 154: theme field sync / preset slot
-- ThemeManager utility note 155: theme field sync / preset slot
-- ThemeManager utility note 156: theme field sync / preset slot
-- ThemeManager utility note 157: theme field sync / preset slot
-- ThemeManager utility note 158: theme field sync / preset slot
-- ThemeManager utility note 159: theme field sync / preset slot
-- ThemeManager utility note 160: theme field sync / preset slot
-- ThemeManager utility note 161: theme field sync / preset slot
-- ThemeManager utility note 162: theme field sync / preset slot
-- ThemeManager utility note 163: theme field sync / preset slot
-- ThemeManager utility note 164: theme field sync / preset slot
-- ThemeManager utility note 165: theme field sync / preset slot
-- ThemeManager utility note 166: theme field sync / preset slot
-- ThemeManager utility note 167: theme field sync / preset slot
-- ThemeManager utility note 168: theme field sync / preset slot
-- ThemeManager utility note 169: theme field sync / preset slot
-- ThemeManager utility note 170: theme field sync / preset slot
-- ThemeManager utility note 171: theme field sync / preset slot
-- ThemeManager utility note 172: theme field sync / preset slot
-- ThemeManager utility note 173: theme field sync / preset slot
-- ThemeManager utility note 174: theme field sync / preset slot
-- ThemeManager utility note 175: theme field sync / preset slot
-- ThemeManager utility note 176: theme field sync / preset slot
-- ThemeManager utility note 177: theme field sync / preset slot
-- ThemeManager utility note 178: theme field sync / preset slot
-- ThemeManager utility note 179: theme field sync / preset slot
-- ThemeManager utility note 180: theme field sync / preset slot
-- ThemeManager utility note 181: theme field sync / preset slot
-- ThemeManager utility note 182: theme field sync / preset slot
-- ThemeManager utility note 183: theme field sync / preset slot
-- ThemeManager utility note 184: theme field sync / preset slot
-- ThemeManager utility note 185: theme field sync / preset slot
-- ThemeManager utility note 186: theme field sync / preset slot
-- ThemeManager utility note 187: theme field sync / preset slot
-- ThemeManager utility note 188: theme field sync / preset slot
-- ThemeManager utility note 189: theme field sync / preset slot
-- ThemeManager utility note 190: theme field sync / preset slot
-- ThemeManager utility note 191: theme field sync / preset slot
-- ThemeManager utility note 192: theme field sync / preset slot
-- ThemeManager utility note 193: theme field sync / preset slot
-- ThemeManager utility note 194: theme field sync / preset slot
-- ThemeManager utility note 195: theme field sync / preset slot
-- ThemeManager utility note 196: theme field sync / preset slot
-- ThemeManager utility note 197: theme field sync / preset slot
-- ThemeManager utility note 198: theme field sync / preset slot
-- ThemeManager utility note 199: theme field sync / preset slot
-- ThemeManager utility note 200: theme field sync / preset slot
-- ThemeManager utility note 201: theme field sync / preset slot
-- ThemeManager utility note 202: theme field sync / preset slot
-- ThemeManager utility note 203: theme field sync / preset slot
-- ThemeManager utility note 204: theme field sync / preset slot
-- ThemeManager utility note 205: theme field sync / preset slot
-- ThemeManager utility note 206: theme field sync / preset slot
-- ThemeManager utility note 207: theme field sync / preset slot
-- ThemeManager utility note 208: theme field sync / preset slot
-- ThemeManager utility note 209: theme field sync / preset slot
-- ThemeManager utility note 210: theme field sync / preset slot
-- ThemeManager utility note 211: theme field sync / preset slot
-- ThemeManager utility note 212: theme field sync / preset slot
-- ThemeManager utility note 213: theme field sync / preset slot
-- ThemeManager utility note 214: theme field sync / preset slot
-- ThemeManager utility note 215: theme field sync / preset slot
-- ThemeManager utility note 216: theme field sync / preset slot
-- ThemeManager utility note 217: theme field sync / preset slot
-- ThemeManager utility note 218: theme field sync / preset slot
-- ThemeManager utility note 219: theme field sync / preset slot
-- ThemeManager utility note 220: theme field sync / preset slot
-- ThemeManager utility note 221: theme field sync / preset slot
-- ThemeManager utility note 222: theme field sync / preset slot
-- ThemeManager utility note 223: theme field sync / preset slot
-- ThemeManager utility note 224: theme field sync / preset slot
-- ThemeManager utility note 225: theme field sync / preset slot
-- ThemeManager utility note 226: theme field sync / preset slot
-- ThemeManager utility note 227: theme field sync / preset slot
-- ThemeManager utility note 228: theme field sync / preset slot
-- ThemeManager utility note 229: theme field sync / preset slot
-- ThemeManager utility note 230: theme field sync / preset slot
-- ThemeManager utility note 231: theme field sync / preset slot
-- ThemeManager utility note 232: theme field sync / preset slot
-- ThemeManager utility note 233: theme field sync / preset slot
-- ThemeManager utility note 234: theme field sync / preset slot
-- ThemeManager utility note 235: theme field sync / preset slot
-- ThemeManager utility note 236: theme field sync / preset slot
-- ThemeManager utility note 237: theme field sync / preset slot
-- ThemeManager utility note 238: theme field sync / preset slot
-- ThemeManager utility note 239: theme field sync / preset slot
-- ThemeManager utility note 240: theme field sync / preset slot
-- ThemeManager utility note 241: theme field sync / preset slot
-- ThemeManager utility note 242: theme field sync / preset slot
-- ThemeManager utility note 243: theme field sync / preset slot
-- ThemeManager utility note 244: theme field sync / preset slot
-- ThemeManager utility note 245: theme field sync / preset slot
-- ThemeManager utility note 246: theme field sync / preset slot
-- ThemeManager utility note 247: theme field sync / preset slot
-- ThemeManager utility note 248: theme field sync / preset slot
-- ThemeManager utility note 249: theme field sync / preset slot
-- ThemeManager utility note 250: theme field sync / preset slot
-- ThemeManager utility note 251: theme field sync / preset slot
-- ThemeManager utility note 252: theme field sync / preset slot
-- ThemeManager utility note 253: theme field sync / preset slot
-- ThemeManager utility note 254: theme field sync / preset slot
-- ThemeManager utility note 255: theme field sync / preset slot
-- ThemeManager utility note 256: theme field sync / preset slot
-- ThemeManager utility note 257: theme field sync / preset slot
-- ThemeManager utility note 258: theme field sync / preset slot
-- ThemeManager utility note 259: theme field sync / preset slot
-- ThemeManager utility note 260: theme field sync / preset slot
-- ThemeManager utility note 261: theme field sync / preset slot
-- ThemeManager utility note 262: theme field sync / preset slot
-- ThemeManager utility note 263: theme field sync / preset slot
-- ThemeManager utility note 264: theme field sync / preset slot
-- ThemeManager utility note 265: theme field sync / preset slot
-- ThemeManager utility note 266: theme field sync / preset slot
-- ThemeManager utility note 267: theme field sync / preset slot
-- ThemeManager utility note 268: theme field sync / preset slot
-- ThemeManager utility note 269: theme field sync / preset slot
-- ThemeManager utility note 270: theme field sync / preset slot
-- ThemeManager utility note 271: theme field sync / preset slot
-- ThemeManager utility note 272: theme field sync / preset slot
-- ThemeManager utility note 273: theme field sync / preset slot
-- ThemeManager utility note 274: theme field sync / preset slot
-- ThemeManager utility note 275: theme field sync / preset slot
-- ThemeManager utility note 276: theme field sync / preset slot
-- ThemeManager utility note 277: theme field sync / preset slot
-- ThemeManager utility note 278: theme field sync / preset slot
-- ThemeManager utility note 279: theme field sync / preset slot
-- ThemeManager utility note 280: theme field sync / preset slot
-- ThemeManager utility note 281: theme field sync / preset slot
-- ThemeManager utility note 282: theme field sync / preset slot
-- ThemeManager utility note 283: theme field sync / preset slot
-- ThemeManager utility note 284: theme field sync / preset slot
-- ThemeManager utility note 285: theme field sync / preset slot
-- ThemeManager utility note 286: theme field sync / preset slot
-- ThemeManager utility note 287: theme field sync / preset slot
-- ThemeManager utility note 288: theme field sync / preset slot
-- ThemeManager utility note 289: theme field sync / preset slot
-- ThemeManager utility note 290: theme field sync / preset slot
-- ThemeManager utility note 291: theme field sync / preset slot
-- ThemeManager utility note 292: theme field sync / preset slot
-- ThemeManager utility note 293: theme field sync / preset slot
-- ThemeManager utility note 294: theme field sync / preset slot
-- ThemeManager utility note 295: theme field sync / preset slot
-- ThemeManager utility note 296: theme field sync / preset slot
-- ThemeManager utility note 297: theme field sync / preset slot
-- ThemeManager utility note 298: theme field sync / preset slot
-- ThemeManager utility note 299: theme field sync / preset slot
-- ThemeManager utility note 300: theme field sync / preset slot
-- ThemeManager utility note 301: theme field sync / preset slot
-- ThemeManager utility note 302: theme field sync / preset slot
-- ThemeManager utility note 303: theme field sync / preset slot
-- ThemeManager utility note 304: theme field sync / preset slot
-- ThemeManager utility note 305: theme field sync / preset slot
-- ThemeManager utility note 306: theme field sync / preset slot
-- ThemeManager utility note 307: theme field sync / preset slot
-- ThemeManager utility note 308: theme field sync / preset slot
-- ThemeManager utility note 309: theme field sync / preset slot
-- ThemeManager utility note 310: theme field sync / preset slot
-- ThemeManager utility note 311: theme field sync / preset slot
-- ThemeManager utility note 312: theme field sync / preset slot
-- ThemeManager utility note 313: theme field sync / preset slot
-- ThemeManager utility note 314: theme field sync / preset slot
-- ThemeManager utility note 315: theme field sync / preset slot
-- ThemeManager utility note 316: theme field sync / preset slot
-- ThemeManager utility note 317: theme field sync / preset slot
-- ThemeManager utility note 318: theme field sync / preset slot
-- ThemeManager utility note 319: theme field sync / preset slot
-- ThemeManager utility note 320: theme field sync / preset slot
-- ThemeManager utility note 321: theme field sync / preset slot
-- ThemeManager utility note 322: theme field sync / preset slot
-- ThemeManager utility note 323: theme field sync / preset slot
-- ThemeManager utility note 324: theme field sync / preset slot
-- ThemeManager utility note 325: theme field sync / preset slot
-- ThemeManager utility note 326: theme field sync / preset slot
-- ThemeManager utility note 327: theme field sync / preset slot
-- ThemeManager utility note 328: theme field sync / preset slot
-- ThemeManager utility note 329: theme field sync / preset slot
-- ThemeManager utility note 330: theme field sync / preset slot
-- ThemeManager utility note 331: theme field sync / preset slot
-- ThemeManager utility note 332: theme field sync / preset slot
-- ThemeManager utility note 333: theme field sync / preset slot
-- ThemeManager utility note 334: theme field sync / preset slot
-- ThemeManager utility note 335: theme field sync / preset slot
-- ThemeManager utility note 336: theme field sync / preset slot
-- ThemeManager utility note 337: theme field sync / preset slot
-- ThemeManager utility note 338: theme field sync / preset slot
-- ThemeManager utility note 339: theme field sync / preset slot
-- ThemeManager utility note 340: theme field sync / preset slot
-- ThemeManager utility note 341: theme field sync / preset slot
-- ThemeManager utility note 342: theme field sync / preset slot
-- ThemeManager utility note 343: theme field sync / preset slot
-- ThemeManager utility note 344: theme field sync / preset slot
-- ThemeManager utility note 345: theme field sync / preset slot
-- ThemeManager utility note 346: theme field sync / preset slot
-- ThemeManager utility note 347: theme field sync / preset slot
-- ThemeManager utility note 348: theme field sync / preset slot
-- ThemeManager utility note 349: theme field sync / preset slot
-- ThemeManager utility note 350: theme field sync / preset slot
-- ThemeManager utility note 351: theme field sync / preset slot
-- ThemeManager utility note 352: theme field sync / preset slot
-- ThemeManager utility note 353: theme field sync / preset slot
-- ThemeManager utility note 354: theme field sync / preset slot
-- ThemeManager utility note 355: theme field sync / preset slot
-- ThemeManager utility note 356: theme field sync / preset slot
-- ThemeManager utility note 357: theme field sync / preset slot
-- ThemeManager utility note 358: theme field sync / preset slot
-- ThemeManager utility note 359: theme field sync / preset slot
-- ThemeManager utility note 360: theme field sync / preset slot
-- ThemeManager utility note 361: theme field sync / preset slot
-- ThemeManager utility note 362: theme field sync / preset slot
-- ThemeManager utility note 363: theme field sync / preset slot
-- ThemeManager utility note 364: theme field sync / preset slot
-- ThemeManager utility note 365: theme field sync / preset slot
-- ThemeManager utility note 366: theme field sync / preset slot
-- ThemeManager utility note 367: theme field sync / preset slot
-- ThemeManager utility note 368: theme field sync / preset slot
-- ThemeManager utility note 369: theme field sync / preset slot
-- ThemeManager utility note 370: theme field sync / preset slot
-- ThemeManager utility note 371: theme field sync / preset slot
-- ThemeManager utility note 372: theme field sync / preset slot
-- ThemeManager utility note 373: theme field sync / preset slot
-- ThemeManager utility note 374: theme field sync / preset slot
-- ThemeManager utility note 375: theme field sync / preset slot
-- ThemeManager utility note 376: theme field sync / preset slot
-- ThemeManager utility note 377: theme field sync / preset slot
-- ThemeManager utility note 378: theme field sync / preset slot
-- ThemeManager utility note 379: theme field sync / preset slot
-- ThemeManager utility note 380: theme field sync / preset slot
-- ThemeManager utility note 381: theme field sync / preset slot
-- ThemeManager utility note 382: theme field sync / preset slot
-- ThemeManager utility note 383: theme field sync / preset slot
-- ThemeManager utility note 384: theme field sync / preset slot
-- ThemeManager utility note 385: theme field sync / preset slot
-- ThemeManager utility note 386: theme field sync / preset slot
-- ThemeManager utility note 387: theme field sync / preset slot
-- ThemeManager utility note 388: theme field sync / preset slot
-- ThemeManager utility note 389: theme field sync / preset slot
-- ThemeManager utility note 390: theme field sync / preset slot
-- ThemeManager utility note 391: theme field sync / preset slot
-- ThemeManager utility note 392: theme field sync / preset slot
-- ThemeManager utility note 393: theme field sync / preset slot
-- ThemeManager utility note 394: theme field sync / preset slot
-- ThemeManager utility note 395: theme field sync / preset slot
-- ThemeManager utility note 396: theme field sync / preset slot
-- ThemeManager utility note 397: theme field sync / preset slot
-- ThemeManager utility note 398: theme field sync / preset slot
-- ThemeManager utility note 399: theme field sync / preset slot
-- ThemeManager utility note 400: theme field sync / preset slot
-- ThemeManager utility note 401: theme field sync / preset slot
-- ThemeManager utility note 402: theme field sync / preset slot
-- ThemeManager utility note 403: theme field sync / preset slot
-- ThemeManager utility note 404: theme field sync / preset slot
-- ThemeManager utility note 405: theme field sync / preset slot
-- ThemeManager utility note 406: theme field sync / preset slot
-- ThemeManager utility note 407: theme field sync / preset slot
-- ThemeManager utility note 408: theme field sync / preset slot
-- ThemeManager utility note 409: theme field sync / preset slot
-- ThemeManager utility note 410: theme field sync / preset slot
-- ThemeManager utility note 411: theme field sync / preset slot
-- ThemeManager utility note 412: theme field sync / preset slot
-- ThemeManager utility note 413: theme field sync / preset slot
-- ThemeManager utility note 414: theme field sync / preset slot
-- ThemeManager utility note 415: theme field sync / preset slot
-- ThemeManager utility note 416: theme field sync / preset slot
-- ThemeManager utility note 417: theme field sync / preset slot
-- ThemeManager utility note 418: theme field sync / preset slot
-- ThemeManager utility note 419: theme field sync / preset slot
-- ThemeManager utility note 420: theme field sync / preset slot
-- ThemeManager utility note 421: theme field sync / preset slot
-- ThemeManager utility note 422: theme field sync / preset slot
-- ThemeManager utility note 423: theme field sync / preset slot
-- ThemeManager utility note 424: theme field sync / preset slot
-- ThemeManager utility note 425: theme field sync / preset slot
-- ThemeManager utility note 426: theme field sync / preset slot
-- ThemeManager utility note 427: theme field sync / preset slot
-- ThemeManager utility note 428: theme field sync / preset slot
-- ThemeManager utility note 429: theme field sync / preset slot
-- ThemeManager utility note 430: theme field sync / preset slot
-- ThemeManager utility note 431: theme field sync / preset slot
-- ThemeManager utility note 432: theme field sync / preset slot
-- ThemeManager utility note 433: theme field sync / preset slot
-- ThemeManager utility note 434: theme field sync / preset slot
-- ThemeManager utility note 435: theme field sync / preset slot
-- ThemeManager utility note 436: theme field sync / preset slot
-- ThemeManager utility note 437: theme field sync / preset slot
-- ThemeManager utility note 438: theme field sync / preset slot
-- ThemeManager utility note 439: theme field sync / preset slot
-- ThemeManager utility note 440: theme field sync / preset slot
-- ThemeManager utility note 441: theme field sync / preset slot
-- ThemeManager utility note 442: theme field sync / preset slot
-- ThemeManager utility note 443: theme field sync / preset slot
-- ThemeManager utility note 444: theme field sync / preset slot
-- ThemeManager utility note 445: theme field sync / preset slot
-- ThemeManager utility note 446: theme field sync / preset slot
-- ThemeManager utility note 447: theme field sync / preset slot
-- ThemeManager utility note 448: theme field sync / preset slot
-- ThemeManager utility note 449: theme field sync / preset slot
-- ThemeManager utility note 450: theme field sync / preset slot
-- ThemeManager utility note 451: theme field sync / preset slot
-- ThemeManager utility note 452: theme field sync / preset slot
-- ThemeManager utility note 453: theme field sync / preset slot
-- ThemeManager utility note 454: theme field sync / preset slot
-- ThemeManager utility note 455: theme field sync / preset slot
-- ThemeManager utility note 456: theme field sync / preset slot
-- ThemeManager utility note 457: theme field sync / preset slot
-- ThemeManager utility note 458: theme field sync / preset slot
-- ThemeManager utility note 459: theme field sync / preset slot
-- ThemeManager utility note 460: theme field sync / preset slot
-- ThemeManager utility note 461: theme field sync / preset slot
-- ThemeManager utility note 462: theme field sync / preset slot
-- ThemeManager utility note 463: theme field sync / preset slot
-- ThemeManager utility note 464: theme field sync / preset slot
-- ThemeManager utility note 465: theme field sync / preset slot
-- ThemeManager utility note 466: theme field sync / preset slot
-- ThemeManager utility note 467: theme field sync / preset slot
-- ThemeManager utility note 468: theme field sync / preset slot
-- ThemeManager utility note 469: theme field sync / preset slot
-- ThemeManager utility note 470: theme field sync / preset slot
-- ThemeManager utility note 471: theme field sync / preset slot
-- ThemeManager utility note 472: theme field sync / preset slot
-- ThemeManager utility note 473: theme field sync / preset slot
-- ThemeManager utility note 474: theme field sync / preset slot
-- ThemeManager utility note 475: theme field sync / preset slot
-- ThemeManager utility note 476: theme field sync / preset slot
-- ThemeManager utility note 477: theme field sync / preset slot
-- ThemeManager utility note 478: theme field sync / preset slot
-- ThemeManager utility note 479: theme field sync / preset slot
-- ThemeManager utility note 480: theme field sync / preset slot
-- ThemeManager utility note 481: theme field sync / preset slot
-- ThemeManager utility note 482: theme field sync / preset slot
-- ThemeManager utility note 483: theme field sync / preset slot
-- ThemeManager utility note 484: theme field sync / preset slot
-- ThemeManager utility note 485: theme field sync / preset slot
-- ThemeManager utility note 486: theme field sync / preset slot
-- ThemeManager utility note 487: theme field sync / preset slot
-- ThemeManager utility note 488: theme field sync / preset slot
-- ThemeManager utility note 489: theme field sync / preset slot
-- ThemeManager utility note 490: theme field sync / preset slot
-- ThemeManager utility note 491: theme field sync / preset slot
-- ThemeManager utility note 492: theme field sync / preset slot
-- ThemeManager utility note 493: theme field sync / preset slot
-- ThemeManager utility note 494: theme field sync / preset slot
-- ThemeManager utility note 495: theme field sync / preset slot
-- ThemeManager utility note 496: theme field sync / preset slot
-- ThemeManager utility note 497: theme field sync / preset slot
-- ThemeManager utility note 498: theme field sync / preset slot
-- ThemeManager utility note 499: theme field sync / preset slot
-- ThemeManager utility note 500: theme field sync / preset slot
-- ThemeManager utility note 501: theme field sync / preset slot
-- ThemeManager utility note 502: theme field sync / preset slot
-- ThemeManager utility note 503: theme field sync / preset slot
-- ThemeManager utility note 504: theme field sync / preset slot
-- ThemeManager utility note 505: theme field sync / preset slot
-- ThemeManager utility note 506: theme field sync / preset slot
-- ThemeManager utility note 507: theme field sync / preset slot
-- ThemeManager utility note 508: theme field sync / preset slot
-- ThemeManager utility note 509: theme field sync / preset slot
-- ThemeManager utility note 510: theme field sync / preset slot
-- ThemeManager utility note 511: theme field sync / preset slot
-- ThemeManager utility note 512: theme field sync / preset slot
-- ThemeManager utility note 513: theme field sync / preset slot
-- ThemeManager utility note 514: theme field sync / preset slot
-- ThemeManager utility note 515: theme field sync / preset slot
-- ThemeManager utility note 516: theme field sync / preset slot
-- ThemeManager utility note 517: theme field sync / preset slot
-- ThemeManager utility note 518: theme field sync / preset slot
-- ThemeManager utility note 519: theme field sync / preset slot
-- ThemeManager utility note 520: theme field sync / preset slot
-- ThemeManager utility note 521: theme field sync / preset slot
-- ThemeManager utility note 522: theme field sync / preset slot
-- ThemeManager utility note 523: theme field sync / preset slot
-- ThemeManager utility note 524: theme field sync / preset slot
-- ThemeManager utility note 525: theme field sync / preset slot
-- ThemeManager utility note 526: theme field sync / preset slot
-- ThemeManager utility note 527: theme field sync / preset slot
-- ThemeManager utility note 528: theme field sync / preset slot
-- ThemeManager utility note 529: theme field sync / preset slot
-- ThemeManager utility note 530: theme field sync / preset slot
-- ThemeManager utility note 531: theme field sync / preset slot
-- ThemeManager utility note 532: theme field sync / preset slot
-- ThemeManager utility note 533: theme field sync / preset slot
-- ThemeManager utility note 534: theme field sync / preset slot
-- ThemeManager utility note 535: theme field sync / preset slot
-- ThemeManager utility note 536: theme field sync / preset slot
-- ThemeManager utility note 537: theme field sync / preset slot
-- ThemeManager utility note 538: theme field sync / preset slot
-- ThemeManager utility note 539: theme field sync / preset slot
-- ThemeManager utility note 540: theme field sync / preset slot
-- ThemeManager utility note 541: theme field sync / preset slot
-- ThemeManager utility note 542: theme field sync / preset slot
-- ThemeManager utility note 543: theme field sync / preset slot
-- ThemeManager utility note 544: theme field sync / preset slot
-- ThemeManager utility note 545: theme field sync / preset slot
-- ThemeManager utility note 546: theme field sync / preset slot
-- ThemeManager utility note 547: theme field sync / preset slot
-- ThemeManager utility note 548: theme field sync / preset slot
-- ThemeManager utility note 549: theme field sync / preset slot
-- ThemeManager utility note 550: theme field sync / preset slot
-- ThemeManager utility note 551: theme field sync / preset slot
-- ThemeManager utility note 552: theme field sync / preset slot
-- ThemeManager utility note 553: theme field sync / preset slot
-- ThemeManager utility note 554: theme field sync / preset slot
-- ThemeManager utility note 555: theme field sync / preset slot
-- ThemeManager utility note 556: theme field sync / preset slot
-- ThemeManager utility note 557: theme field sync / preset slot
-- ThemeManager utility note 558: theme field sync / preset slot
-- ThemeManager utility note 559: theme field sync / preset slot
-- ThemeManager utility note 560: theme field sync / preset slot
-- ThemeManager utility note 561: theme field sync / preset slot
-- ThemeManager utility note 562: theme field sync / preset slot
-- ThemeManager utility note 563: theme field sync / preset slot
-- ThemeManager utility note 564: theme field sync / preset slot
-- ThemeManager utility note 565: theme field sync / preset slot
-- ThemeManager utility note 566: theme field sync / preset slot
-- ThemeManager utility note 567: theme field sync / preset slot
-- ThemeManager utility note 568: theme field sync / preset slot
-- ThemeManager utility note 569: theme field sync / preset slot
-- ThemeManager utility note 570: theme field sync / preset slot
-- ThemeManager utility note 571: theme field sync / preset slot
-- ThemeManager utility note 572: theme field sync / preset slot
-- ThemeManager utility note 573: theme field sync / preset slot
-- ThemeManager utility note 574: theme field sync / preset slot
-- ThemeManager utility note 575: theme field sync / preset slot
-- ThemeManager utility note 576: theme field sync / preset slot
-- ThemeManager utility note 577: theme field sync / preset slot
-- ThemeManager utility note 578: theme field sync / preset slot
-- ThemeManager utility note 579: theme field sync / preset slot
-- ThemeManager utility note 580: theme field sync / preset slot
-- ThemeManager utility note 581: theme field sync / preset slot
-- ThemeManager utility note 582: theme field sync / preset slot
-- ThemeManager utility note 583: theme field sync / preset slot
-- ThemeManager utility note 584: theme field sync / preset slot
-- ThemeManager utility note 585: theme field sync / preset slot
-- ThemeManager utility note 586: theme field sync / preset slot
-- ThemeManager utility note 587: theme field sync / preset slot
-- ThemeManager utility note 588: theme field sync / preset slot
-- ThemeManager utility note 589: theme field sync / preset slot
-- ThemeManager utility note 590: theme field sync / preset slot
-- ThemeManager utility note 591: theme field sync / preset slot
-- ThemeManager utility note 592: theme field sync / preset slot
-- ThemeManager utility note 593: theme field sync / preset slot
-- ThemeManager utility note 594: theme field sync / preset slot
-- ThemeManager utility note 595: theme field sync / preset slot
-- ThemeManager utility note 596: theme field sync / preset slot
-- ThemeManager utility note 597: theme field sync / preset slot
-- ThemeManager utility note 598: theme field sync / preset slot
-- ThemeManager utility note 599: theme field sync / preset slot
-- ThemeManager utility note 600: theme field sync / preset slot
-- ThemeManager utility note 601: theme field sync / preset slot
-- ThemeManager utility note 602: theme field sync / preset slot
-- ThemeManager utility note 603: theme field sync / preset slot
-- ThemeManager utility note 604: theme field sync / preset slot
-- ThemeManager utility note 605: theme field sync / preset slot
-- ThemeManager utility note 606: theme field sync / preset slot
-- ThemeManager utility note 607: theme field sync / preset slot
-- ThemeManager utility note 608: theme field sync / preset slot
-- ThemeManager utility note 609: theme field sync / preset slot
-- ThemeManager utility note 610: theme field sync / preset slot
-- ThemeManager utility note 611: theme field sync / preset slot
-- ThemeManager utility note 612: theme field sync / preset slot
-- ThemeManager utility note 613: theme field sync / preset slot
-- ThemeManager utility note 614: theme field sync / preset slot
-- ThemeManager utility note 615: theme field sync / preset slot
-- ThemeManager utility note 616: theme field sync / preset slot
-- ThemeManager utility note 617: theme field sync / preset slot
-- ThemeManager utility note 618: theme field sync / preset slot
-- ThemeManager utility note 619: theme field sync / preset slot
-- ThemeManager utility note 620: theme field sync / preset slot
-- ThemeManager utility note 621: theme field sync / preset slot
-- ThemeManager utility note 622: theme field sync / preset slot
-- ThemeManager utility note 623: theme field sync / preset slot
-- ThemeManager utility note 624: theme field sync / preset slot
-- ThemeManager utility note 625: theme field sync / preset slot
-- ThemeManager utility note 626: theme field sync / preset slot
-- ThemeManager utility note 627: theme field sync / preset slot
-- ThemeManager utility note 628: theme field sync / preset slot
-- ThemeManager utility note 629: theme field sync / preset slot
-- ThemeManager utility note 630: theme field sync / preset slot
-- ThemeManager utility note 631: theme field sync / preset slot
-- ThemeManager utility note 632: theme field sync / preset slot
-- ThemeManager utility note 633: theme field sync / preset slot
-- ThemeManager utility note 634: theme field sync / preset slot
-- ThemeManager utility note 635: theme field sync / preset slot
-- ThemeManager utility note 636: theme field sync / preset slot
-- ThemeManager utility note 637: theme field sync / preset slot
-- ThemeManager utility note 638: theme field sync / preset slot
-- ThemeManager utility note 639: theme field sync / preset slot
-- ThemeManager utility note 640: theme field sync / preset slot
-- ThemeManager utility note 641: theme field sync / preset slot
-- ThemeManager utility note 642: theme field sync / preset slot
-- ThemeManager utility note 643: theme field sync / preset slot
-- ThemeManager utility note 644: theme field sync / preset slot
-- ThemeManager utility note 645: theme field sync / preset slot
-- ThemeManager utility note 646: theme field sync / preset slot
-- ThemeManager utility note 647: theme field sync / preset slot
-- ThemeManager utility note 648: theme field sync / preset slot
-- ThemeManager utility note 649: theme field sync / preset slot
-- ThemeManager utility note 650: theme field sync / preset slot
-- ThemeManager utility note 651: theme field sync / preset slot
-- ThemeManager utility note 652: theme field sync / preset slot
-- ThemeManager utility note 653: theme field sync / preset slot
-- ThemeManager utility note 654: theme field sync / preset slot
-- ThemeManager utility note 655: theme field sync / preset slot
-- ThemeManager utility note 656: theme field sync / preset slot
-- ThemeManager utility note 657: theme field sync / preset slot
-- ThemeManager utility note 658: theme field sync / preset slot
-- ThemeManager utility note 659: theme field sync / preset slot
-- ThemeManager utility note 660: theme field sync / preset slot
-- ThemeManager utility note 661: theme field sync / preset slot
-- ThemeManager utility note 662: theme field sync / preset slot
-- ThemeManager utility note 663: theme field sync / preset slot
-- ThemeManager utility note 664: theme field sync / preset slot
-- ThemeManager utility note 665: theme field sync / preset slot
-- ThemeManager utility note 666: theme field sync / preset slot
-- ThemeManager utility note 667: theme field sync / preset slot
-- ThemeManager utility note 668: theme field sync / preset slot
-- ThemeManager utility note 669: theme field sync / preset slot
-- ThemeManager utility note 670: theme field sync / preset slot
-- ThemeManager utility note 671: theme field sync / preset slot
-- ThemeManager utility note 672: theme field sync / preset slot
-- ThemeManager utility note 673: theme field sync / preset slot
-- ThemeManager utility note 674: theme field sync / preset slot
-- ThemeManager utility note 675: theme field sync / preset slot
-- ThemeManager utility note 676: theme field sync / preset slot
-- ThemeManager utility note 677: theme field sync / preset slot
-- ThemeManager utility note 678: theme field sync / preset slot
-- ThemeManager utility note 679: theme field sync / preset slot
-- ThemeManager utility note 680: theme field sync / preset slot
-- ThemeManager utility note 681: theme field sync / preset slot
-- ThemeManager utility note 682: theme field sync / preset slot
-- ThemeManager utility note 683: theme field sync / preset slot
-- ThemeManager utility note 684: theme field sync / preset slot
-- ThemeManager utility note 685: theme field sync / preset slot
-- ThemeManager utility note 686: theme field sync / preset slot
-- ThemeManager utility note 687: theme field sync / preset slot
-- ThemeManager utility note 688: theme field sync / preset slot
-- ThemeManager utility note 689: theme field sync / preset slot
-- ThemeManager utility note 690: theme field sync / preset slot
-- ThemeManager utility note 691: theme field sync / preset slot
-- ThemeManager utility note 692: theme field sync / preset slot
-- ThemeManager utility note 693: theme field sync / preset slot
-- ThemeManager utility note 694: theme field sync / preset slot
-- ThemeManager utility note 695: theme field sync / preset slot
-- ThemeManager utility note 696: theme field sync / preset slot
-- ThemeManager utility note 697: theme field sync / preset slot
-- ThemeManager utility note 698: theme field sync / preset slot
-- ThemeManager utility note 699: theme field sync / preset slot
-- ThemeManager utility note 700: theme field sync / preset slot
-- ThemeManager utility note 701: theme field sync / preset slot
-- ThemeManager utility note 702: theme field sync / preset slot
-- ThemeManager utility note 703: theme field sync / preset slot
-- ThemeManager utility note 704: theme field sync / preset slot
-- ThemeManager utility note 705: theme field sync / preset slot
-- ThemeManager utility note 706: theme field sync / preset slot
-- ThemeManager utility note 707: theme field sync / preset slot
-- ThemeManager utility note 708: theme field sync / preset slot
-- ThemeManager utility note 709: theme field sync / preset slot
-- ThemeManager utility note 710: theme field sync / preset slot
-- ThemeManager utility note 711: theme field sync / preset slot
-- ThemeManager utility note 712: theme field sync / preset slot
-- ThemeManager utility note 713: theme field sync / preset slot
-- ThemeManager utility note 714: theme field sync / preset slot
-- ThemeManager utility note 715: theme field sync / preset slot
-- ThemeManager utility note 716: theme field sync / preset slot
-- ThemeManager utility note 717: theme field sync / preset slot
-- ThemeManager utility note 718: theme field sync / preset slot
-- ThemeManager utility note 719: theme field sync / preset slot
-- ThemeManager utility note 720: theme field sync / preset slot
-- ThemeManager utility note 721: theme field sync / preset slot
-- ThemeManager utility note 722: theme field sync / preset slot
-- ThemeManager utility note 723: theme field sync / preset slot
-- ThemeManager utility note 724: theme field sync / preset slot
-- ThemeManager utility note 725: theme field sync / preset slot
-- ThemeManager utility note 726: theme field sync / preset slot
-- ThemeManager utility note 727: theme field sync / preset slot
-- ThemeManager utility note 728: theme field sync / preset slot
-- ThemeManager utility note 729: theme field sync / preset slot
-- ThemeManager utility note 730: theme field sync / preset slot
-- ThemeManager utility note 731: theme field sync / preset slot
-- ThemeManager utility note 732: theme field sync / preset slot
-- ThemeManager utility note 733: theme field sync / preset slot
-- ThemeManager utility note 734: theme field sync / preset slot
-- ThemeManager utility note 735: theme field sync / preset slot
-- ThemeManager utility note 736: theme field sync / preset slot
-- ThemeManager utility note 737: theme field sync / preset slot
-- ThemeManager utility note 738: theme field sync / preset slot
-- ThemeManager utility note 739: theme field sync / preset slot
-- ThemeManager utility note 740: theme field sync / preset slot
-- ThemeManager utility note 741: theme field sync / preset slot
-- ThemeManager utility note 742: theme field sync / preset slot
-- ThemeManager utility note 743: theme field sync / preset slot
-- ThemeManager utility note 744: theme field sync / preset slot
-- ThemeManager utility note 745: theme field sync / preset slot
-- ThemeManager utility note 746: theme field sync / preset slot
-- ThemeManager utility note 747: theme field sync / preset slot
-- ThemeManager utility note 748: theme field sync / preset slot
-- ThemeManager utility note 749: theme field sync / preset slot
-- ThemeManager utility note 750: theme field sync / preset slot
-- ThemeManager utility note 751: theme field sync / preset slot
-- ThemeManager utility note 752: theme field sync / preset slot
-- ThemeManager utility note 753: theme field sync / preset slot
-- ThemeManager utility note 754: theme field sync / preset slot
-- ThemeManager utility note 755: theme field sync / preset slot
-- ThemeManager utility note 756: theme field sync / preset slot
-- ThemeManager utility note 757: theme field sync / preset slot
-- ThemeManager utility note 758: theme field sync / preset slot
-- ThemeManager utility note 759: theme field sync / preset slot
-- ThemeManager utility note 760: theme field sync / preset slot
-- ThemeManager utility note 761: theme field sync / preset slot
-- ThemeManager utility note 762: theme field sync / preset slot
-- ThemeManager utility note 763: theme field sync / preset slot
-- ThemeManager utility note 764: theme field sync / preset slot
-- ThemeManager utility note 765: theme field sync / preset slot
-- ThemeManager utility note 766: theme field sync / preset slot
-- ThemeManager utility note 767: theme field sync / preset slot
-- ThemeManager utility note 768: theme field sync / preset slot
-- ThemeManager utility note 769: theme field sync / preset slot
-- ThemeManager utility note 770: theme field sync / preset slot
-- ThemeManager utility note 771: theme field sync / preset slot
-- ThemeManager utility note 772: theme field sync / preset slot
-- ThemeManager utility note 773: theme field sync / preset slot
-- ThemeManager utility note 774: theme field sync / preset slot
-- ThemeManager utility note 775: theme field sync / preset slot
-- ThemeManager utility note 776: theme field sync / preset slot
-- ThemeManager utility note 777: theme field sync / preset slot
-- ThemeManager utility note 778: theme field sync / preset slot
-- ThemeManager utility note 779: theme field sync / preset slot
-- ThemeManager utility note 780: theme field sync / preset slot
-- ThemeManager utility note 781: theme field sync / preset slot
-- ThemeManager utility note 782: theme field sync / preset slot
-- ThemeManager utility note 783: theme field sync / preset slot
-- ThemeManager utility note 784: theme field sync / preset slot
-- ThemeManager utility note 785: theme field sync / preset slot
-- ThemeManager utility note 786: theme field sync / preset slot
-- ThemeManager utility note 787: theme field sync / preset slot
-- ThemeManager utility note 788: theme field sync / preset slot
-- ThemeManager utility note 789: theme field sync / preset slot
-- ThemeManager utility note 790: theme field sync / preset slot
-- ThemeManager utility note 791: theme field sync / preset slot
-- ThemeManager utility note 792: theme field sync / preset slot
-- ThemeManager utility note 793: theme field sync / preset slot
-- ThemeManager utility note 794: theme field sync / preset slot
-- ThemeManager utility note 795: theme field sync / preset slot
-- ThemeManager utility note 796: theme field sync / preset slot
-- ThemeManager utility note 797: theme field sync / preset slot
-- ThemeManager utility note 798: theme field sync / preset slot
-- ThemeManager utility note 799: theme field sync / preset slot
-- ThemeManager utility note 800: theme field sync / preset slot
-- ThemeManager utility note 801: theme field sync / preset slot
-- ThemeManager utility note 802: theme field sync / preset slot
-- ThemeManager utility note 803: theme field sync / preset slot
-- ThemeManager utility note 804: theme field sync / preset slot
-- ThemeManager utility note 805: theme field sync / preset slot
-- ThemeManager utility note 806: theme field sync / preset slot
-- ThemeManager utility note 807: theme field sync / preset slot
-- ThemeManager utility note 808: theme field sync / preset slot
-- ThemeManager utility note 809: theme field sync / preset slot
-- ThemeManager utility note 810: theme field sync / preset slot
-- ThemeManager utility note 811: theme field sync / preset slot
-- ThemeManager utility note 812: theme field sync / preset slot
-- ThemeManager utility note 813: theme field sync / preset slot
-- ThemeManager utility note 814: theme field sync / preset slot
-- ThemeManager utility note 815: theme field sync / preset slot
-- ThemeManager utility note 816: theme field sync / preset slot
-- ThemeManager utility note 817: theme field sync / preset slot
-- ThemeManager utility note 818: theme field sync / preset slot
-- ThemeManager utility note 819: theme field sync / preset slot
-- ThemeManager utility note 820: theme field sync / preset slot
-- ThemeManager utility note 821: theme field sync / preset slot
-- ThemeManager utility note 822: theme field sync / preset slot
-- ThemeManager utility note 823: theme field sync / preset slot
-- ThemeManager utility note 824: theme field sync / preset slot
-- ThemeManager utility note 825: theme field sync / preset slot
-- ThemeManager utility note 826: theme field sync / preset slot
-- ThemeManager utility note 827: theme field sync / preset slot
-- ThemeManager utility note 828: theme field sync / preset slot
-- ThemeManager utility note 829: theme field sync / preset slot
-- ThemeManager utility note 830: theme field sync / preset slot
-- ThemeManager utility note 831: theme field sync / preset slot
-- ThemeManager utility note 832: theme field sync / preset slot
-- ThemeManager utility note 833: theme field sync / preset slot
-- ThemeManager utility note 834: theme field sync / preset slot
-- ThemeManager utility note 835: theme field sync / preset slot
-- ThemeManager utility note 836: theme field sync / preset slot
-- ThemeManager utility note 837: theme field sync / preset slot
-- ThemeManager utility note 838: theme field sync / preset slot
-- ThemeManager utility note 839: theme field sync / preset slot
-- ThemeManager utility note 840: theme field sync / preset slot
-- ThemeManager utility note 841: theme field sync / preset slot
-- ThemeManager utility note 842: theme field sync / preset slot
-- ThemeManager utility note 843: theme field sync / preset slot
-- ThemeManager utility note 844: theme field sync / preset slot
-- ThemeManager utility note 845: theme field sync / preset slot
-- ThemeManager utility note 846: theme field sync / preset slot
-- ThemeManager utility note 847: theme field sync / preset slot
-- ThemeManager utility note 848: theme field sync / preset slot
-- ThemeManager utility note 849: theme field sync / preset slot
-- ThemeManager utility note 850: theme field sync / preset slot
-- ThemeManager utility note 851: theme field sync / preset slot
-- ThemeManager utility note 852: theme field sync / preset slot
-- ThemeManager utility note 853: theme field sync / preset slot
-- ThemeManager utility note 854: theme field sync / preset slot
-- ThemeManager utility note 855: theme field sync / preset slot
-- ThemeManager utility note 856: theme field sync / preset slot
-- ThemeManager utility note 857: theme field sync / preset slot
-- ThemeManager utility note 858: theme field sync / preset slot
-- ThemeManager utility note 859: theme field sync / preset slot
-- ThemeManager utility note 860: theme field sync / preset slot
-- ThemeManager utility note 861: theme field sync / preset slot
-- ThemeManager utility note 862: theme field sync / preset slot
-- ThemeManager utility note 863: theme field sync / preset slot
-- ThemeManager utility note 864: theme field sync / preset slot
-- ThemeManager utility note 865: theme field sync / preset slot
-- ThemeManager utility note 866: theme field sync / preset slot
-- ThemeManager utility note 867: theme field sync / preset slot
-- ThemeManager utility note 868: theme field sync / preset slot
-- ThemeManager utility note 869: theme field sync / preset slot
-- ThemeManager utility note 870: theme field sync / preset slot
-- ThemeManager utility note 871: theme field sync / preset slot
-- ThemeManager utility note 872: theme field sync / preset slot
-- ThemeManager utility note 873: theme field sync / preset slot
-- ThemeManager utility note 874: theme field sync / preset slot
-- ThemeManager utility note 875: theme field sync / preset slot
-- ThemeManager utility note 876: theme field sync / preset slot
-- ThemeManager utility note 877: theme field sync / preset slot
-- ThemeManager utility note 878: theme field sync / preset slot
-- ThemeManager utility note 879: theme field sync / preset slot
-- ThemeManager utility note 880: theme field sync / preset slot
-- ThemeManager utility note 881: theme field sync / preset slot
-- ThemeManager utility note 882: theme field sync / preset slot
-- ThemeManager utility note 883: theme field sync / preset slot
-- ThemeManager utility note 884: theme field sync / preset slot
-- ThemeManager utility note 885: theme field sync / preset slot
-- ThemeManager utility note 886: theme field sync / preset slot
-- ThemeManager utility note 887: theme field sync / preset slot
-- ThemeManager utility note 888: theme field sync / preset slot
-- ThemeManager utility note 889: theme field sync / preset slot
-- ThemeManager utility note 890: theme field sync / preset slot
-- ThemeManager utility note 891: theme field sync / preset slot
-- ThemeManager utility note 892: theme field sync / preset slot
-- ThemeManager utility note 893: theme field sync / preset slot
-- ThemeManager utility note 894: theme field sync / preset slot
-- ThemeManager utility note 895: theme field sync / preset slot
-- ThemeManager utility note 896: theme field sync / preset slot
-- ThemeManager utility note 897: theme field sync / preset slot
-- ThemeManager utility note 898: theme field sync / preset slot
-- ThemeManager utility note 899: theme field sync / preset slot
-- ThemeManager utility note 900: theme field sync / preset slot
-- ThemeManager utility note 901: theme field sync / preset slot
-- ThemeManager utility note 902: theme field sync / preset slot
-- ThemeManager utility note 903: theme field sync / preset slot
-- ThemeManager utility note 904: theme field sync / preset slot
-- ThemeManager utility note 905: theme field sync / preset slot
-- ThemeManager utility note 906: theme field sync / preset slot
-- ThemeManager utility note 907: theme field sync / preset slot
-- ThemeManager utility note 908: theme field sync / preset slot
-- ThemeManager utility note 909: theme field sync / preset slot
-- ThemeManager utility note 910: theme field sync / preset slot
-- ThemeManager utility note 911: theme field sync / preset slot
-- ThemeManager utility note 912: theme field sync / preset slot
-- ThemeManager utility note 913: theme field sync / preset slot
-- ThemeManager utility note 914: theme field sync / preset slot
-- ThemeManager utility note 915: theme field sync / preset slot
-- ThemeManager utility note 916: theme field sync / preset slot
-- ThemeManager utility note 917: theme field sync / preset slot
-- ThemeManager utility note 918: theme field sync / preset slot
-- ThemeManager utility note 919: theme field sync / preset slot
-- ThemeManager utility note 920: theme field sync / preset slot
-- ThemeManager utility note 921: theme field sync / preset slot
-- ThemeManager utility note 922: theme field sync / preset slot
-- ThemeManager utility note 923: theme field sync / preset slot
-- ThemeManager utility note 924: theme field sync / preset slot
-- ThemeManager utility note 925: theme field sync / preset slot
-- ThemeManager utility note 926: theme field sync / preset slot
-- ThemeManager utility note 927: theme field sync / preset slot
-- ThemeManager utility note 928: theme field sync / preset slot
-- ThemeManager utility note 929: theme field sync / preset slot
-- ThemeManager utility note 930: theme field sync / preset slot
-- ThemeManager utility note 931: theme field sync / preset slot
-- ThemeManager utility note 932: theme field sync / preset slot
-- ThemeManager utility note 933: theme field sync / preset slot
-- ThemeManager utility note 934: theme field sync / preset slot
-- ThemeManager utility note 935: theme field sync / preset slot
-- ThemeManager utility note 936: theme field sync / preset slot
-- ThemeManager utility note 937: theme field sync / preset slot
-- ThemeManager utility note 938: theme field sync / preset slot
-- ThemeManager utility note 939: theme field sync / preset slot
-- ThemeManager utility note 940: theme field sync / preset slot
-- ThemeManager utility note 941: theme field sync / preset slot
-- ThemeManager utility note 942: theme field sync / preset slot
-- ThemeManager utility note 943: theme field sync / preset slot
-- ThemeManager utility note 944: theme field sync / preset slot
-- ThemeManager utility note 945: theme field sync / preset slot
-- ThemeManager utility note 946: theme field sync / preset slot
-- ThemeManager utility note 947: theme field sync / preset slot
-- ThemeManager utility note 948: theme field sync / preset slot
-- ThemeManager utility note 949: theme field sync / preset slot
-- ThemeManager utility note 950: theme field sync / preset slot
-- ThemeManager utility note 951: theme field sync / preset slot
-- ThemeManager utility note 952: theme field sync / preset slot
-- ThemeManager utility note 953: theme field sync / preset slot
-- ThemeManager utility note 954: theme field sync / preset slot
-- ThemeManager utility note 955: theme field sync / preset slot
-- ThemeManager utility note 956: theme field sync / preset slot
-- ThemeManager utility note 957: theme field sync / preset slot
-- ThemeManager utility note 958: theme field sync / preset slot
-- ThemeManager utility note 959: theme field sync / preset slot
-- ThemeManager utility note 960: theme field sync / preset slot
-- ThemeManager utility note 961: theme field sync / preset slot
-- ThemeManager utility note 962: theme field sync / preset slot
-- ThemeManager utility note 963: theme field sync / preset slot
-- ThemeManager utility note 964: theme field sync / preset slot
-- ThemeManager utility note 965: theme field sync / preset slot
-- ThemeManager utility note 966: theme field sync / preset slot
-- ThemeManager utility note 967: theme field sync / preset slot
-- ThemeManager utility note 968: theme field sync / preset slot
-- ThemeManager utility note 969: theme field sync / preset slot
-- ThemeManager utility note 970: theme field sync / preset slot
-- ThemeManager utility note 971: theme field sync / preset slot
-- ThemeManager utility note 972: theme field sync / preset slot
-- ThemeManager utility note 973: theme field sync / preset slot
-- ThemeManager utility note 974: theme field sync / preset slot
-- ThemeManager utility note 975: theme field sync / preset slot
-- ThemeManager utility note 976: theme field sync / preset slot
-- ThemeManager utility note 977: theme field sync / preset slot
-- ThemeManager utility note 978: theme field sync / preset slot
-- ThemeManager utility note 979: theme field sync / preset slot
-- ThemeManager utility note 980: theme field sync / preset slot
-- ThemeManager utility note 981: theme field sync / preset slot
-- ThemeManager utility note 982: theme field sync / preset slot
-- ThemeManager utility note 983: theme field sync / preset slot
-- ThemeManager utility note 984: theme field sync / preset slot
-- ThemeManager utility note 985: theme field sync / preset slot
-- ThemeManager utility note 986: theme field sync / preset slot
-- ThemeManager utility note 987: theme field sync / preset slot
-- ThemeManager utility note 988: theme field sync / preset slot
-- ThemeManager utility note 989: theme field sync / preset slot
-- ThemeManager utility note 990: theme field sync / preset slot
-- ThemeManager utility note 991: theme field sync / preset slot
-- ThemeManager utility note 992: theme field sync / preset slot
-- ThemeManager utility note 993: theme field sync / preset slot
-- ThemeManager utility note 994: theme field sync / preset slot
-- ThemeManager utility note 995: theme field sync / preset slot
-- ThemeManager utility note 996: theme field sync / preset slot
-- ThemeManager utility note 997: theme field sync / preset slot
-- ThemeManager utility note 998: theme field sync / preset slot
-- ThemeManager utility note 999: theme field sync / preset slot
-- ThemeManager utility note 1000: theme field sync / preset slot
-- ThemeManager utility note 1001: theme field sync / preset slot
-- ThemeManager utility note 1002: theme field sync / preset slot
-- ThemeManager utility note 1003: theme field sync / preset slot
-- ThemeManager utility note 1004: theme field sync / preset slot
-- ThemeManager utility note 1005: theme field sync / preset slot
-- ThemeManager utility note 1006: theme field sync / preset slot
-- ThemeManager utility note 1007: theme field sync / preset slot
-- ThemeManager utility note 1008: theme field sync / preset slot
-- ThemeManager utility note 1009: theme field sync / preset slot
-- ThemeManager utility note 1010: theme field sync / preset slot
-- ThemeManager utility note 1011: theme field sync / preset slot
-- ThemeManager utility note 1012: theme field sync / preset slot
-- ThemeManager utility note 1013: theme field sync / preset slot
-- ThemeManager utility note 1014: theme field sync / preset slot
-- ThemeManager utility note 1015: theme field sync / preset slot
-- ThemeManager utility note 1016: theme field sync / preset slot
-- ThemeManager utility note 1017: theme field sync / preset slot
-- ThemeManager utility note 1018: theme field sync / preset slot
-- ThemeManager utility note 1019: theme field sync / preset slot
-- ThemeManager utility note 1020: theme field sync / preset slot
-- ThemeManager utility note 1021: theme field sync / preset slot
-- ThemeManager utility note 1022: theme field sync / preset slot
-- ThemeManager utility note 1023: theme field sync / preset slot
-- ThemeManager utility note 1024: theme field sync / preset slot
-- ThemeManager utility note 1025: theme field sync / preset slot
-- ThemeManager utility note 1026: theme field sync / preset slot
-- ThemeManager utility note 1027: theme field sync / preset slot
-- ThemeManager utility note 1028: theme field sync / preset slot
-- ThemeManager utility note 1029: theme field sync / preset slot
-- ThemeManager utility note 1030: theme field sync / preset slot
-- ThemeManager utility note 1031: theme field sync / preset slot
-- ThemeManager utility note 1032: theme field sync / preset slot
-- ThemeManager utility note 1033: theme field sync / preset slot
-- ThemeManager utility note 1034: theme field sync / preset slot
-- ThemeManager utility note 1035: theme field sync / preset slot
-- ThemeManager utility note 1036: theme field sync / preset slot
-- ThemeManager utility note 1037: theme field sync / preset slot
-- ThemeManager utility note 1038: theme field sync / preset slot
-- ThemeManager utility note 1039: theme field sync / preset slot
-- ThemeManager utility note 1040: theme field sync / preset slot
-- ThemeManager utility note 1041: theme field sync / preset slot
-- ThemeManager utility note 1042: theme field sync / preset slot
-- ThemeManager utility note 1043: theme field sync / preset slot
-- ThemeManager utility note 1044: theme field sync / preset slot
-- ThemeManager utility note 1045: theme field sync / preset slot
-- ThemeManager utility note 1046: theme field sync / preset slot
-- ThemeManager utility note 1047: theme field sync / preset slot
-- ThemeManager utility note 1048: theme field sync / preset slot
-- ThemeManager utility note 1049: theme field sync / preset slot
-- ThemeManager utility note 1050: theme field sync / preset slot
-- ThemeManager utility note 1051: theme field sync / preset slot
-- ThemeManager utility note 1052: theme field sync / preset slot
-- ThemeManager utility note 1053: theme field sync / preset slot
-- ThemeManager utility note 1054: theme field sync / preset slot
-- ThemeManager utility note 1055: theme field sync / preset slot
-- ThemeManager utility note 1056: theme field sync / preset slot
-- ThemeManager utility note 1057: theme field sync / preset slot
-- ThemeManager utility note 1058: theme field sync / preset slot
-- ThemeManager utility note 1059: theme field sync / preset slot
-- ThemeManager utility note 1060: theme field sync / preset slot
-- ThemeManager utility note 1061: theme field sync / preset slot
-- ThemeManager utility note 1062: theme field sync / preset slot
-- ThemeManager utility note 1063: theme field sync / preset slot
-- ThemeManager utility note 1064: theme field sync / preset slot
-- ThemeManager utility note 1065: theme field sync / preset slot
-- ThemeManager utility note 1066: theme field sync / preset slot
-- ThemeManager utility note 1067: theme field sync / preset slot
-- ThemeManager utility note 1068: theme field sync / preset slot
-- ThemeManager utility note 1069: theme field sync / preset slot
-- ThemeManager utility note 1070: theme field sync / preset slot
-- ThemeManager utility note 1071: theme field sync / preset slot
-- ThemeManager utility note 1072: theme field sync / preset slot
-- ThemeManager utility note 1073: theme field sync / preset slot
-- ThemeManager utility note 1074: theme field sync / preset slot
-- ThemeManager utility note 1075: theme field sync / preset slot
-- ThemeManager utility note 1076: theme field sync / preset slot
-- ThemeManager utility note 1077: theme field sync / preset slot
-- ThemeManager utility note 1078: theme field sync / preset slot
-- ThemeManager utility note 1079: theme field sync / preset slot
-- ThemeManager utility note 1080: theme field sync / preset slot
-- ThemeManager utility note 1081: theme field sync / preset slot
-- ThemeManager utility note 1082: theme field sync / preset slot
-- ThemeManager utility note 1083: theme field sync / preset slot
-- ThemeManager utility note 1084: theme field sync / preset slot
-- ThemeManager utility note 1085: theme field sync / preset slot
-- ThemeManager utility note 1086: theme field sync / preset slot
-- ThemeManager utility note 1087: theme field sync / preset slot
-- ThemeManager utility note 1088: theme field sync / preset slot
-- ThemeManager utility note 1089: theme field sync / preset slot
-- ThemeManager utility note 1090: theme field sync / preset slot
-- ThemeManager utility note 1091: theme field sync / preset slot
-- ThemeManager utility note 1092: theme field sync / preset slot
-- ThemeManager utility note 1093: theme field sync / preset slot
-- ThemeManager utility note 1094: theme field sync / preset slot
-- ThemeManager utility note 1095: theme field sync / preset slot
-- ThemeManager utility note 1096: theme field sync / preset slot
-- ThemeManager utility note 1097: theme field sync / preset slot
-- ThemeManager utility note 1098: theme field sync / preset slot
-- ThemeManager utility note 1099: theme field sync / preset slot

return ThemeManager