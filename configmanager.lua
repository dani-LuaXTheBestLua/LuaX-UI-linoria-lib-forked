local ConfigManager = {}
ConfigManager.__index = ConfigManager

local HttpService = game:GetService("HttpService")

local function ensureFolder(path)
    if not isfolder or not makefolder then return end
    local parts = string.split(path, "/")
    local cur = ""
    for i, p in ipairs(parts) do
        cur = (i == 1) and p or (cur .. "/" .. p)
        if not isfolder(cur) then pcall(makefolder, cur) end
    end
end

local function listJsonFiles(folder)
    local out = {}
    if not listfiles or not isfolder then return out end
    if not isfolder(folder) then return out end
    for _, file in ipairs(listfiles(folder)) do
        local name = file:match("([^/\\]+)%.json$")
        if name then table.insert(out, name) end
    end
    table.sort(out)
    return out
end

local function deleteJsonFile(folder, name)
    if not delfile then return false end
    local path = folder .. "/" .. name .. ".json"
    if isfile and isfile(path) then pcall(delfile, path); return true end
    return false
end

function ConfigManager.new(Library, folder)
    local self = setmetatable({}, ConfigManager)
    self.Library = Library
    self.Folder = folder or "LuaXBeta/Configs"
    self.ConfigName = "default"
    self.AutoLoad = false
    self.Ignore = {}
    self.Metadata = {}
    self.OnSave = nil
    self.OnLoad = nil
    self.OnDelete = nil
    self.CreatedAt = os.time()
    self.MaxSlots = 64
    self.LastSaveTime = 0
    ensureFolder(self.Folder)
    return self
end

function ConfigManager:SetIgnoreIndexes(list)
    self.Ignore = {}
    for _, v in ipairs(list or {}) do self.Ignore[v] = true end
end

function ConfigManager:Ignore(key) self.Ignore[key] = true end
function ConfigManager:Unignore(key) self.Ignore[key] = nil end
function ConfigManager:IsIgnored(key) return self.Ignore[key] == true end
function ConfigManager:GetPath(name) return self.Folder .. "/" .. (name or self.ConfigName) .. ".json" end
function ConfigManager:SetMaxSlots(n) self.MaxSlots = math.max(1, math.floor(n or 64)) end

function ConfigManager:Capture()
    local data = {
        Toggles = {}, Options = {},
        Metadata = { Created = self.CreatedAt, Saved = os.time(), Version = 1, PlaceId = game.PlaceId, GameName = game.Name },
    }
    for key, toggle in next, (getgenv().Toggles or {}) do
        if not self:IsIgnored(key) then data.Toggles[key] = toggle.Value end
    end
    for key, option in next, (getgenv().Options or {}) do
        if not self:IsIgnored(key) then
            local t = option.Type
            if t == "Slider" or t == "Dropdown" or t == "Input" then
                data.Options[key] = { Type = t, Value = option.Value }
            elseif t == "KeyPicker" then
                data.Options[key] = { Type = t, Value = option.Value, Mode = option.Mode }
            elseif t == "ColorPicker" then
                data.Options[key] = { Type = t, Hex = option.Value:ToHex(), Transparency = option.Transparency or 0 }
            end
        end
    end
    return data
end

function ConfigManager:Save(name)
    name = name or self.ConfigName
    local data = self:Capture()
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok then return false end
    if writefile then
        pcall(function() ensureFolder(self.Folder); writefile(self:GetPath(name), encoded) end)
    end
    self.LastSaveTime = os.time()
    if self.OnSave then pcall(self.OnSave, name, data) end
    return true
end

function ConfigManager:SaveAs(name)
    if not name or name == "" then return false end
    if self:Count() >= self.MaxSlots then return false end
    self.ConfigName = name
    return self:Save(name)
end

function ConfigManager:Load(name)
    name = name or self.ConfigName
    if not readfile or not isfile then return false end
    local path = self:GetPath(name)
    if not isfile(path) then return false end
    local ok, content = pcall(readfile, path)
    if not ok then return false end
    local parsed
    ok, parsed = pcall(HttpService.JSONDecode, HttpService, content)
    if not ok or type(parsed) ~= "table" then return false end
    if parsed.Toggles then
        for key, value in next, parsed.Toggles do
            if not self:IsIgnored(key) and getgenv().Toggles[key] then
                pcall(function() getgenv().Toggles[key]:SetValue(value) end)
            end
        end
    end
    if parsed.Options then
        for key, opt in next, parsed.Options do
            if not self:IsIgnored(key) and getgenv().Options[key] then
                local target = getgenv().Options[key]
                local t = opt.Type or target.Type
                pcall(function()
                    if t == "Slider" or t == "Dropdown" or t == "Input" then
                        target:SetValue(opt.Value)
                    elseif t == "KeyPicker" then
                        target:SetValue({ opt.Value, opt.Mode })
                    elseif t == "ColorPicker" then
                        target:SetValueRGB(Color3.fromHex(opt.Hex), opt.Transparency or 0)
                    end
                end)
            end
        end
    end
    self.ConfigName = name
    self.Metadata[name] = parsed.Metadata
    if self.OnLoad then pcall(self.OnLoad, name, parsed) end
    return true
end

function ConfigManager:Delete(name)
    name = name or self.ConfigName
    local ok = deleteJsonFile(self.Folder, name)
    if ok and self.OnDelete then pcall(self.OnDelete, name) end
    return ok
end

function ConfigManager:Exists(name)
    if not isfile then return false end
    return isfile(self:GetPath(name))
end

function ConfigManager:List() return listJsonFiles(self.Folder) end
function ConfigManager:Count() return #self:List() end

function ConfigManager:Clear()
    local all = self:List()
    local success = 0
    for _, name in ipairs(all) do
        if self:Delete(name) then success = success + 1 end
    end
    return success
end

function ConfigManager:LoadMetadata(name)
    if not readfile or not isfile then return nil end
    local path = self:GetPath(name)
    if not isfile(path) then return nil end
    local ok, content = pcall(readfile, path)
    if not ok then return nil end
    local ok2, parsed = pcall(HttpService.JSONDecode, HttpService, content)
    if not ok2 or type(parsed) ~= "table" then return nil end
    return parsed.Metadata
end

function ConfigManager:SetAutoLoad(bool, name)
    self.AutoLoad = bool
    if name then self.ConfigName = name end
    if bool then self:Load(self.ConfigName) end
end

function ConfigManager:SetOnSave(fn) self.OnSave = fn end
function ConfigManager:SetOnLoad(fn) self.OnLoad = fn end
function ConfigManager:SetOnDelete(fn) self.OnDelete = fn end
function ConfigManager:Export() return self:Capture() end

function ConfigManager:Import(data, name)
    if type(data) ~= "table" then return false end
    name = name or self.ConfigName
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok then return false end
    if writefile then
        pcall(function() ensureFolder(self.Folder); writefile(self:GetPath(name), encoded) end)
    end
    return true
end

function ConfigManager:GetTimeSinceLastSave()
    if self.LastSaveTime == 0 then return -1 end
    return os.time() - self.LastSaveTime
end

function ConfigManager:Rename(oldName, newName)
    if not self:Exists(oldName) then return false end
    if self:Exists(newName) then return false end
    local loaded = self:Load(oldName)
    if not loaded then return false end
    self:Save(newName)
    self:Delete(oldName)
    return true
end

function ConfigManager:Duplicate(sourceName, targetName)
    if not self:Exists(sourceName) then return false end
    if self:Exists(targetName) then return false end
    if not readfile then return false end
    local path = self:GetPath(sourceName)
    local ok, content = pcall(readfile, path)
    if not ok then return false end
    if writefile then pcall(writefile, self:GetPath(targetName), content) end
    return true
end

function ConfigManager:Backup(name)
    name = name or self.ConfigName
    if not self:Exists(name) then return false end
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local backup = name .. "_backup_" .. timestamp
    return self:Duplicate(name, backup)
end

function ConfigManager:LoadNewest()
    local all = self:List()
    if #all == 0 then return false end
    local newest = all[1]
    local newestTime = 0
    for _, name in ipairs(all) do
        local meta = self:LoadMetadata(name)
        if meta and meta.Saved and meta.Saved > newestTime then
            newestTime = meta.Saved
            newest = name
        end
    end
    return self:Load(newest)
end

function ConfigManager:GetSlotInfo()
    local all = self:List()
    local info = {}
    for _, name in ipairs(all) do
        local meta = self:LoadMetadata(name)
        table.insert(info, {
            Name = name,
            Saved = meta and meta.Saved or 0,
            GameName = meta and meta.GameName or "",
            PlaceId = meta and meta.PlaceId or 0,
        })
    end
    return info
end

function ConfigManager:BuildUI(Tab)
    if not Tab then return end
    local left = Tab:AddLeftGroupbox("Config")

    left:AddInput("ConfigNameInput", {
        Text = "Config Name", Default = self.ConfigName, Placeholder = "default", Finished = true,
        Callback = function(v) self.ConfigName = v end,
    })
    left:AddDropdown("ConfigListDropdown", {
        Text = "Config List", Values = self:List(), Default = self.ConfigName, AllowNull = true,
        Callback = function(v) if v then self.ConfigName = v end end,
    })
    left:AddButton("Create Config", function()
        self:Save(self.ConfigName)
        if self.Library and self.Library.Notify then
            self.Library:Notify({ Title = "Config", Description = "Saved: " .. self.ConfigName, Time = 3 })
        end
    end)
    left:AddButton("Load Config", function()
        self:Load(self.ConfigName)
        if self.Library and self.Library.Notify then
            self.Library:Notify({ Title = "Config", Description = "Loaded: " .. self.ConfigName, Time = 3 })
        end
    end)
    left:AddButton("Overwrite Config", function()
        self:Save(self.ConfigName)
        if self.Library and self.Library.Notify then
            self.Library:Notify({ Title = "Config", Description = "Overwritten: " .. self.ConfigName, Time = 3 })
        end
    end)
    left:AddButton("Delete Config", function()
        self:Delete(self.ConfigName)
        if self.Library and self.Library.Notify then
            self.Library:Notify({ Title = "Config", Description = "Deleted: " .. self.ConfigName, Time = 3 })
        end
    end)
    left:AddButton("Refresh List", function()
        if getgenv().Options.ConfigListDropdown then
            getgenv().Options.ConfigListDropdown:SetValues(self:List())
        end
    end)
    left:AddButton("Backup Config", function()
        self:Backup(self.ConfigName)
        if self.Library and self.Library.Notify then
            self.Library:Notify({ Title = "Config", Description = "Backed up: " .. self.ConfigName, Time = 3 })
        end
    end)
    left:AddToggle("ConfigAutoLoad", {
        Text = "Auto Load Config", Default = self.AutoLoad,
        Callback = function(v)
            self.AutoLoad = v
            if v then self:Load(self.ConfigName) end
        end,
    })

    local right = Tab:AddRightGroupbox("Config Tools")
    right:AddButton("Save Auto-Execute", function()
        if not writefile then
            if self.Library and self.Library.Notify then
                self.Library:Notify({ Title = "Config", Description = "writefile not supported", Time = 3 })
            end
            return
        end
        if not isfolder("LuaXBeta") then pcall(makefolder, "LuaXBeta") end
        local src = "-- LuaXBeta auto-execute\nloadstring(game:HttpGet('https://raw.githubusercontent.com/dani-LuaXTheBestLua/LuaX-UI-linoria-lib-forked/refs/heads/main/LinoriaLibrary%20(10).lua'))()\n-- Your script here\n"
        pcall(writefile, "LuaXBeta/autoload.lua", src)
        if self.Library and self.Library.Notify then
            self.Library:Notify({ Title = "Config", Description = "Auto-execute saved", Time = 3 })
        end
    end)
    right:AddButton("Toggle Auto-Execute", function()
        if self.Library and self.Library.SetAutoExecute then
            local newState = not (self.Library.AutoExecute and self.Library.AutoExecute.Enabled)
            self.Library:SetAutoExecute(newState)
            if self.Library.Notify then
                self.Library:Notify({ Title = "Config", Description = "Auto-exec: " .. tostring(newState), Time = 3 })
            end
        end
    end)
    right:AddButton("Load Newest Config", function()
        self:LoadNewest()
        if self.Library and self.Library.Notify then
            self.Library:Notify({ Title = "Config", Description = "Loaded newest", Time = 3 })
        end
    end)
    right:AddButton("Clear All Configs", function()
        local count = self:Clear()
        if self.Library and self.Library.Notify then
            self.Library:Notify({ Title = "Config", Description = "Cleared " .. count .. " configs", Time = 3 })
        end
    end)
    right:AddButton("Export Config", function()
        local data = self:Export()
        local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if ok and setclipboard then
            pcall(setclipboard, encoded)
            if self.Library and self.Library.Notify then
                self.Library:Notify({ Title = "Config", Description = "Exported to clipboard", Time = 3 })
            end
        end
    end)
    right:AddSlider("ConfigMaxSlots", {
        Text = "Max Config Slots", Default = self.MaxSlots, Min = 8, Max = 256, Rounding = 0,
        Callback = function(v) self:SetMaxSlots(v) end,
    })
    right:AddLabel("Game: " .. tostring(game.PlaceId))
    right:AddLabel("Slot count: " .. tostring(self:Count()))

    return left, right
end

return ConfigManager
