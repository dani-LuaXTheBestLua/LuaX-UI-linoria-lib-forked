local ThemeManager = {}
ThemeManager.__index = ThemeManager

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

local Primordial = {
    FontColor = Color3.fromRGB(255, 255, 255),
    MainColor = Color3.fromRGB(24, 24, 24),
    BackgroundColor = Color3.fromRGB(18, 18, 18),
    AccentColor = Color3.fromRGB(220, 150, 180),
    OutlineColor = Color3.fromRGB(40, 40, 40),
    RiskColor = Color3.fromRGB(255, 50, 50),
    GlassEnabled = true,
    GlassTransparency = 0.28,
    OuterGlassTransparency = 0.32,
    UseBlur = true, BlurSize = 24,
    UseDarken = true, DarkenAmount = 55,
}

local Presets = {
    Primordial = Primordial,
    Midnight = { FontColor = Color3.fromRGB(220,220,255), MainColor = Color3.fromRGB(20,20,35), BackgroundColor = Color3.fromRGB(10,10,20), AccentColor = Color3.fromRGB(100,100,255), OutlineColor = Color3.fromRGB(40,40,70), RiskColor = Color3.fromRGB(255,60,60), GlassEnabled = true, GlassTransparency = 0.30, OuterGlassTransparency = 0.34, UseBlur = true, BlurSize = 24, UseDarken = true, DarkenAmount = 55 },
    Rose = { FontColor = Color3.fromRGB(255,220,225), MainColor = Color3.fromRGB(40,20,28), BackgroundColor = Color3.fromRGB(30,15,20), AccentColor = Color3.fromRGB(255,182,193), OutlineColor = Color3.fromRGB(60,30,40), RiskColor = Color3.fromRGB(255,60,60), GlassEnabled = true, GlassTransparency = 0.28, OuterGlassTransparency = 0.32, UseBlur = true, BlurSize = 24, UseDarken = true, DarkenAmount = 55 },
    Emerald = { FontColor = Color3.fromRGB(200,255,220), MainColor = Color3.fromRGB(18,30,22), BackgroundColor = Color3.fromRGB(10,20,15), AccentColor = Color3.fromRGB(50,200,120), OutlineColor = Color3.fromRGB(30,50,38), RiskColor = Color3.fromRGB(255,60,60), GlassEnabled = true, GlassTransparency = 0.28, OuterGlassTransparency = 0.32, UseBlur = true, BlurSize = 24, UseDarken = true, DarkenAmount = 55 },
    Crimson = { FontColor = Color3.fromRGB(255,220,220), MainColor = Color3.fromRGB(40,15,15), BackgroundColor = Color3.fromRGB(30,10,10), AccentColor = Color3.fromRGB(220,50,50), OutlineColor = Color3.fromRGB(60,25,25), RiskColor = Color3.fromRGB(255,60,60), GlassEnabled = true, GlassTransparency = 0.28, OuterGlassTransparency = 0.32, UseBlur = true, BlurSize = 24, UseDarken = true, DarkenAmount = 55 },
    Neon = { FontColor = Color3.fromRGB(220,255,250), MainColor = Color3.fromRGB(10,10,25), BackgroundColor = Color3.fromRGB(5,5,15), AccentColor = Color3.fromRGB(0,255,200), OutlineColor = Color3.fromRGB(20,20,45), RiskColor = Color3.fromRGB(255,60,60), GlassEnabled = true, GlassTransparency = 0.22, OuterGlassTransparency = 0.26, UseBlur = true, BlurSize = 30, UseDarken = true, DarkenAmount = 60 },
    Cyber = { FontColor = Color3.fromRGB(200,240,255), MainColor = Color3.fromRGB(10,18,30), BackgroundColor = Color3.fromRGB(5,10,20), AccentColor = Color3.fromRGB(0,200,255), OutlineColor = Color3.fromRGB(20,35,55), RiskColor = Color3.fromRGB(255,60,60), GlassEnabled = true, GlassTransparency = 0.24, OuterGlassTransparency = 0.28, UseBlur = true, BlurSize = 26, UseDarken = true, DarkenAmount = 58 },
    Gold = { FontColor = Color3.fromRGB(255,245,200), MainColor = Color3.fromRGB(35,28,10), BackgroundColor = Color3.fromRGB(25,20,5), AccentColor = Color3.fromRGB(255,215,0), OutlineColor = Color3.fromRGB(55,45,15), RiskColor = Color3.fromRGB(255,60,60), GlassEnabled = true, GlassTransparency = 0.28, OuterGlassTransparency = 0.32, UseBlur = true, BlurSize = 24, UseDarken = true, DarkenAmount = 55 },
    Amethyst = { FontColor = Color3.fromRGB(240,220,255), MainColor = Color3.fromRGB(35,20,50), BackgroundColor = Color3.fromRGB(25,15,35), AccentColor = Color3.fromRGB(180,100,255), OutlineColor = Color3.fromRGB(50,30,70), RiskColor = Color3.fromRGB(255,60,60), GlassEnabled = true, GlassTransparency = 0.28, OuterGlassTransparency = 0.32, UseBlur = true, BlurSize = 24, UseDarken = true, DarkenAmount = 55 },
    Ocean = { FontColor = Color3.fromRGB(200,240,255), MainColor = Color3.fromRGB(15,35,50), BackgroundColor = Color3.fromRGB(10,25,35), AccentColor = Color3.fromRGB(50,180,220), OutlineColor = Color3.fromRGB(25,55,75), RiskColor = Color3.fromRGB(255,60,60), GlassEnabled = true, GlassTransparency = 0.28, OuterGlassTransparency = 0.32, UseBlur = true, BlurSize = 24, UseDarken = true, DarkenAmount = 55 },
    Sunset = { FontColor = Color3.fromRGB(255,230,200), MainColor = Color3.fromRGB(50,25,15), BackgroundColor = Color3.fromRGB(40,20,10), AccentColor = Color3.fromRGB(255,140,50), OutlineColor = Color3.fromRGB(70,40,20), RiskColor = Color3.fromRGB(255,60,60), GlassEnabled = true, GlassTransparency = 0.28, OuterGlassTransparency = 0.32, UseBlur = true, BlurSize = 24, UseDarken = true, DarkenAmount = 55 },
    Forest = { FontColor = Color3.fromRGB(210,255,210), MainColor = Color3.fromRGB(15,30,15), BackgroundColor = Color3.fromRGB(10,20,10), AccentColor = Color3.fromRGB(80,200,80), OutlineColor = Color3.fromRGB(25,50,25), RiskColor = Color3.fromRGB(255,60,60), GlassEnabled = true, GlassTransparency = 0.28, OuterGlassTransparency = 0.32, UseBlur = true, BlurSize = 24, UseDarken = true, DarkenAmount = 55 },
    Mono = { FontColor = Color3.fromRGB(255,255,255), MainColor = Color3.fromRGB(25,25,25), BackgroundColor = Color3.fromRGB(15,15,15), AccentColor = Color3.fromRGB(200,200,200), OutlineColor = Color3.fromRGB(45,45,45), RiskColor = Color3.fromRGB(255,60,60), GlassEnabled = true, GlassTransparency = 0.28, OuterGlassTransparency = 0.32, UseBlur = true, BlurSize = 24, UseDarken = true, DarkenAmount = 55 },
    Blood = { FontColor = Color3.fromRGB(255,220,220), MainColor = Color3.fromRGB(25,8,8), BackgroundColor = Color3.fromRGB(15,5,5), AccentColor = Color3.fromRGB(180,0,0), OutlineColor = Color3.fromRGB(45,15,15), RiskColor = Color3.fromRGB(255,60,60), GlassEnabled = true, GlassTransparency = 0.28, OuterGlassTransparency = 0.32, UseBlur = true, BlurSize = 28, UseDarken = true, DarkenAmount = 60 },
    Royal = { FontColor = Color3.fromRGB(230,220,255), MainColor = Color3.fromRGB(30,20,55), BackgroundColor = Color3.fromRGB(20,15,40), AccentColor = Color3.fromRGB(140,100,255), OutlineColor = Color3.fromRGB(45,35,80), RiskColor = Color3.fromRGB(255,60,60), GlassEnabled = true, GlassTransparency = 0.28, OuterGlassTransparency = 0.32, UseBlur = true, BlurSize = 24, UseDarken = true, DarkenAmount = 55 },
}

function ThemeManager.new(Library, folder)
    local self = setmetatable({}, ThemeManager)
    self.Library = Library
    self.Folder = folder or "LuaXBeta/Themes"
    self.ThemeName = "Primordial"
    self.AutoLoad = false
    self.Metadata = {}
    self.OnApply = nil
    self.OnSave = nil
    self.OnLoad = nil
    self.OnDelete = nil
    self.LastApplyTime = 0
    ensureFolder(self.Folder)
    return self
end

function ThemeManager:GetPath(name) return self.Folder .. "/" .. (name or self.ThemeName) .. ".json" end

function ThemeManager:Capture()
    local L = self.Library
    return {
        FontColor = L.FontColor,
        MainColor = L.MainColor,
        BackgroundColor = L.BackgroundColor,
        AccentColor = L.AccentColor,
        OutlineColor = L.OutlineColor,
        RiskColor = L.RiskColor,
        GlassEnabled = L.GlassEnabled,
        GlassTransparency = L.GlassTransparency,
        OuterGlassTransparency = L.OuterGlassTransparency,
        UseBlur = L.UseBlur, BlurSize = L.BlurSize,
        UseDarken = L.UseDarken, DarkenAmount = L.DarkenAmount,
        FontFace = L.CurrentFont and L.CurrentFont.Name or "Code",
    }
end

function ThemeManager:Apply(theme)
    local L = self.Library
    if type(theme) ~= "table" then return end
    L.FontColor = theme.FontColor or L.FontColor
    L.MainColor = theme.MainColor or L.MainColor
    L.BackgroundColor = theme.BackgroundColor or L.BackgroundColor
    L.AccentColor = theme.AccentColor or L.AccentColor
    L.OutlineColor = theme.OutlineColor or L.OutlineColor
    L.RiskColor = theme.RiskColor or L.RiskColor
    if theme.GlassEnabled ~= nil then L.GlassEnabled = theme.GlassEnabled end
    if theme.GlassTransparency then L.GlassTransparency = theme.GlassTransparency end
    if theme.OuterGlassTransparency then L.OuterGlassTransparency = theme.OuterGlassTransparency end
    if theme.UseBlur ~= nil then L.UseBlur = theme.UseBlur end
    if theme.BlurSize then L.BlurSize = theme.BlurSize end
    if theme.UseDarken ~= nil then L.UseDarken = theme.UseDarken end
    if theme.DarkenAmount then L.DarkenAmount = theme.DarkenAmount end
    L.AccentColorDark = L:GetDarkerColor(L.AccentColor)
    L.AccentColorLight = L:GetLighterColor(L.AccentColor)
    pcall(function() L:UpdateColorsUsingRegistry() end)
    pcall(function()
        if L.WindowOuter then
            L.WindowOuter.BackgroundTransparency = L.GlassEnabled and L.OuterGlassTransparency or 0
            L.WindowOuter.BackgroundColor3 = L.BackgroundColor
        end
        if L.WindowInner then
            L.WindowInner.BackgroundTransparency = L.GlassEnabled and L.GlassTransparency or 0
            L.WindowInner.BackgroundColor3 = L.MainColor
        end
    end)
    pcall(function()
        if L.BlurEffect then
            L.BlurEffect.Size = L.UseBlur and L.BlurSize or 0
            L.BlurEffect.Enabled = L.UseBlur
        end
        if L.DarkOverlay then
            L.DarkOverlay.BackgroundTransparency = L.UseDarken and (1 - L.DarkenAmount / 100) or 1
        end
    end)
    pcall(function()
        local opts = getgenv().Options
        if opts then
            if opts.BackgroundColorPick then opts.BackgroundColorPick:SetValueRGB(L.BackgroundColor) end
            if opts.MainColorPick then opts.MainColorPick:SetValueRGB(L.MainColor) end
            if opts.AccentColorPick then opts.AccentColorPick:SetValueRGB(L.AccentColor) end
            if opts.OutlineColorPick then opts.OutlineColorPick:SetValueRGB(L.OutlineColor) end
            if opts.FontColorPick then opts.FontColorPick:SetValueRGB(L.FontColor) end
        end
    end)
    if theme.FontFace and L.ApplyFont then
        pcall(function() L:ApplyFont(theme.FontFace) end)
    end
    self.LastApplyTime = os.time()
    if self.OnApply then pcall(self.OnApply, theme) end
end

function ThemeManager:RestorePrimordial()
    self:Apply(Primordial)
    self.ThemeName = "Primordial"
end

function ThemeManager:Save(name)
    name = name or self.ThemeName
    local theme = self:Capture()
    local payload = {}
    for k, v in next, theme do
        if typeof(v) == "Color3" then payload[k] = { __c = v:ToHex() }
        else payload[k] = v end
    end
    payload.__meta = { Saved = os.time(), PlaceId = game.PlaceId, GameName = game.Name }
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, payload)
    if not ok then return false end
    if writefile then
        pcall(function() ensureFolder(self.Folder); writefile(self:GetPath(name), encoded) end)
    end
    if self.OnSave then pcall(self.OnSave, name, theme) end
    return true
end

function ThemeManager:Load(name)
    name = name or self.ThemeName
    if not readfile or not isfile then return false end
    local path = self:GetPath(name)
    if not isfile(path) then return false end
    local ok, content = pcall(readfile, path)
    if not ok then return false end
    local parsed
    ok, parsed = pcall(HttpService.JSONDecode, HttpService, content)
    if not ok or type(parsed) ~= "table" then return false end
    local theme = {}
    for k, v in next, parsed do
        if type(v) == "table" and v.__c then theme[k] = Color3.fromHex(v.__c)
        elseif k ~= "__meta" then theme[k] = v end
    end
    self:Apply(theme)
    self.ThemeName = name
    self.Metadata[name] = parsed.__meta
    if self.OnLoad then pcall(self.OnLoad, name, theme) end
    return true
end

function ThemeManager:Delete(name)
    name = name or self.ThemeName
    if delfile then
        pcall(delfile, self:GetPath(name))
        if self.OnDelete then pcall(self.OnDelete, name) end
        return true
    end
    return false
end

function ThemeManager:Exists(name)
    if not isfile then return false end
    return isfile(self:GetPath(name))
end

function ThemeManager:List() return listJsonFiles(self.Folder) end
function ThemeManager:Count() return #self:List() end
function ThemeManager:GetMetadata(name) return self.Metadata[name or self.ThemeName] end

function ThemeManager:SetAutoLoad(bool, name)
    self.AutoLoad = bool
    if name then self.ThemeName = name end
    if bool then self:Load(self.ThemeName) end
end

function ThemeManager:SetOnApply(fn) self.OnApply = fn end
function ThemeManager:SetOnSave(fn) self.OnSave = fn end
function ThemeManager:SetOnLoad(fn) self.OnLoad = fn end
function ThemeManager:SetOnDelete(fn) self.OnDelete = fn end

function ThemeManager:GetPreset(name) return Presets[name] or Primordial end
function ThemeManager:ApplyPreset(name) self:Apply(self:GetPreset(name)); self.ThemeName = name end

function ThemeManager:ListPresets()
    local out = {}
    for name, _ in next, Presets do table.insert(out, name) end
    table.sort(out)
    return out
end

function ThemeManager:Export()
    local theme = self:Capture()
    local payload = {}
    for k, v in next, theme do
        if typeof(v) == "Color3" then payload[k] = { __c = v:ToHex() }
        else payload[k] = v end
    end
    return payload
end

function ThemeManager:Import(data)
    if type(data) ~= "table" then return false end
    local theme = {}
    for k, v in next, data do
        if type(v) == "table" and v.__c then theme[k] = Color3.fromHex(v.__c)
        else theme[k] = v end
    end
    self:Apply(theme)
    return true
end

function ThemeManager:GetTimeSinceApply()
    if self.LastApplyTime == 0 then return -1 end
    return os.time() - self.LastApplyTime
end

function ThemeManager:BuildUI(Tab)
    if not Tab then return end
    local left = Tab:AddLeftGroupbox("Theme")

    left:AddInput("ThemeNameInput", {
        Text = "Theme Name", Default = self.ThemeName, Placeholder = "Primordial", Finished = true,
        Callback = function(v) self.ThemeName = v end,
    })
    left:AddDropdown("ThemeListDropdown", {
        Text = "Theme List", Values = self:List(), Default = self.ThemeName, AllowNull = true,
        Callback = function(v) if v then self.ThemeName = v end end,
    })
    left:AddDropdown("ThemePresetDropdown", {
        Text = "Preset Theme", Values = self:ListPresets(), Default = "Primordial",
        Callback = function(v) if v then self:ApplyPreset(v) end end,
    })
    left:AddButton("Save Theme", function()
        self:Save(self.ThemeName)
        if self.Library and self.Library.Notify then
            self.Library:Notify({ Title = "Theme", Description = "Saved: " .. self.ThemeName, Time = 3 })
        end
    end)
    left:AddButton("Load Theme", function()
        self:Load(self.ThemeName)
        if self.Library and self.Library.Notify then
            self.Library:Notify({ Title = "Theme", Description = "Loaded: " .. self.ThemeName, Time = 3 })
        end
    end)
    left:AddButton("Overwrite Theme", function()
        self:Save(self.ThemeName)
        if self.Library and self.Library.Notify then
            self.Library:Notify({ Title = "Theme", Description = "Overwritten: " .. self.ThemeName, Time = 3 })
        end
    end)
    left:AddButton("Delete Theme", function()
        self:Delete(self.ThemeName)
        if self.Library and self.Library.Notify then
            self.Library:Notify({ Title = "Theme", Description = "Deleted: " .. self.ThemeName, Time = 3 })
        end
    end)
    left:AddButton("Refresh List", function()
        if getgenv().Options.ThemeListDropdown then
            getgenv().Options.ThemeListDropdown:SetValues(self:List())
        end
    end)
    left:AddToggle("ThemeAutoLoad", {
        Text = "Auto Load Theme", Default = self.AutoLoad,
        Callback = function(v)
            self.AutoLoad = v
            if v then self:Load(self.ThemeName) end
        end,
    })
    left:AddButton("Reset Primordial", function()
        self:RestorePrimordial()
        if self.Library and self.Library.Notify then
            self.Library:Notify({ Title = "Theme", Description = "Primordial restored", Time = 3 })
        end
    end)
    left:AddButton("Export Theme", function()
        local data = self:Export()
        local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if ok and setclipboard then
            pcall(setclipboard, encoded)
            if self.Library and self.Library.Notify then
                self.Library:Notify({ Title = "Theme", Description = "Exported to clipboard", Time = 3 })
            end
        end
    end)

    local right = Tab:AddRightGroupbox("Theme Colors")
    right:AddColorPicker("BackgroundColorPick", {
        Default = self.Library.BackgroundColor, Title = "Background",
        Callback = function(c) self.Library.BackgroundColor = c; self.Library:UpdateColorsUsingRegistry() end,
    })
    right:AddColorPicker("MainColorPick", {
        Default = self.Library.MainColor, Title = "Main",
        Callback = function(c) self.Library.MainColor = c; self.Library:UpdateColorsUsingRegistry() end,
    })
    right:AddColorPicker("AccentColorPick", {
        Default = self.Library.AccentColor, Title = "Accent",
        Callback = function(c)
            self.Library.AccentColor = c
            self.Library.AccentColorDark = self.Library:GetDarkerColor(c)
            self.Library.AccentColorLight = self.Library:GetLighterColor(c)
            self.Library:UpdateColorsUsingRegistry()
        end,
    })
    right:AddColorPicker("OutlineColorPick", {
        Default = self.Library.OutlineColor, Title = "Outline",
        Callback = function(c) self.Library.OutlineColor = c; self.Library:UpdateColorsUsingRegistry() end,
    })
    right:AddColorPicker("FontColorPick", {
        Default = self.Library.FontColor, Title = "Font",
        Callback = function(c) self.Library.FontColor = c; self.Library:UpdateColorsUsingRegistry() end,
    })

    return left, right
end

return ThemeManager
