local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local Lighting = game:GetService('Lighting');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local OldLibrary = getgenv().Library;
if type(OldLibrary) == 'table' and OldLibrary.ScreenGui then
    pcall(function()
        if OldLibrary.Unload then OldLibrary:Unload(); end
        OldLibrary.ScreenGui:Destroy();
    end);
    getgenv().Library = nil;
end

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = CoreGui;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    FontColor = Color3.fromRGB(255, 255, 255);
    MainColor = Color3.fromRGB(24, 24, 24);
    BackgroundColor = Color3.fromRGB(18, 18, 18);
    AccentColor = Color3.fromRGB(220, 140, 180); -- Primordial pink
    OutlineColor = Color3.fromRGB(40, 40, 40);
    RiskColor = Color3.fromRGB(255, 50, 50);
    RiskColor = Color3.fromRGB(255, 50, 50),

    Black = Color3.new(0, 0, 0);

    Font = Enum.Font.Code,
    FontSize = 14,

    OpenedFrames = {};
    DependencyBoxes = {};

    Signals = {};
    ScreenGui = ScreenGui;

    Toggled = false;
    WireframeDrag = true;
    ShowCustomCursor = true; -- custom cursor ON
    UseBlur = true;
    BlurSize = 24;
    UseDarken = true;
    DarkenAmount = 55;

    -- Glass UI (subtle, not pure white)
    GlassEnabled = true;
    -- Liquid glass across whole UI
    GlassTransparency = 0.28;
    GlassOutlineTransparency = 0.4;
    OuterGlassTransparency = 0.30;
    UseBlur = true;
    BlurSize = 30;
    UseDarken = true;
    DarkenAmount = 55;

    KeybindMode = 'All';

    NotifyConfig = {
        ClipDescendants  = false;
        MaxHeight        = 200;
        PosX             = 50;
        PosY             = 60;
        Transparency     = 60;
        Alignment        = "Center";
        BarSide          = "Bottom";
        SortOrder        = "Time";
    };
    NotifyQueue       = {};
    ActiveNotifyCount = 0;
    NotifyCounter     = 0;
};

Library.KeyPickerList = {};

Library.BlurEffect = Instance.new("BlurEffect")
Library.BlurEffect.Name = "LinoriaBlur"
Library.BlurEffect.Size = 0
Library.BlurEffect.Enabled = false
pcall(function() Library.BlurEffect.Parent = Lighting end)

do
    local OverlayGui = Instance.new("ScreenGui")
    OverlayGui.Name = "LinoriaBlurOverlay"
    OverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    OverlayGui.DisplayOrder = -9999
    ProtectGui(OverlayGui)
    OverlayGui.Parent = CoreGui

    Library.DarkOverlay = Instance.new("Frame")
    Library.DarkOverlay.Name = "DarkOverlay"
    Library.DarkOverlay.Size = UDim2.new(10, 0, 10, 0)
    Library.DarkOverlay.Position = UDim2.new(-5, 0, -5, 0)
    Library.DarkOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
    Library.DarkOverlay.BackgroundTransparency = 1
    Library.DarkOverlay.BorderSizePixel = 0
    Library.DarkOverlay.ZIndex = 1
    Library.DarkOverlay.Parent = OverlayGui
end

function Library:UpdateBlur()
    local open = Library.Toggled and Library.UseBlur;
    local targetSize = open and Library.BlurSize or 0;

    if open then
        Library.BlurEffect.Enabled = true;
    end

    Library.BlurEffect.Size = targetSize;

    if Library.DarkOverlay then
        local dark = Library.Toggled and Library.UseDarken;
        Library.DarkOverlay.BackgroundTransparency = dark and (1 - (Library.DarkenAmount / 100)) or 1;
    end

    if not open then
        Library.BlurEffect.Enabled = false;
    end
end

function Library:SetBlur(Size)
    Library.BlurSize = math.clamp(Size, 0, 56);
    if Library.Toggled and Library.UseBlur then
        Library.BlurEffect.Size = Library.BlurSize;
    end
end

-- Call this with any Groupbox to add a blur toggle + size slider
-- e.g. Library:AddBlurSlider(MyGroupbox)
function Library:AddBlurSlider(Groupbox)
    Groupbox:AddToggle('LinoriaUseBlur', {
        Text    = 'Background Blur';
        Default = Library.UseBlur;
        Tooltip = 'Blur the background when the menu is open';
        Callback = function(Value)
            Library.UseBlur = Value;
            Library:UpdateBlur();
        end;
    });
    Groupbox:AddSlider('LinoriaBlurSize', {
        Text     = 'Blur Amount';
        Default  = Library.BlurSize;
        Min      = 0;
        Max      = 56;
        Rounding = 0;
        Callback = function(Value)
            Library:SetBlur(Value);
        end;
    });
end

-- Call this with any Groupbox to add a darken toggle + amount slider
-- e.g. Library:AddDarkenSlider(MyGroupbox)
function Library:AddDarkenSlider(Groupbox)
    Groupbox:AddToggle('LinoriaUseDarken', {
        Text    = 'Background Darken';
        Default = Library.UseDarken;
        Tooltip = 'Darken the background when the menu is open';
        Callback = function(Value)
            Library.UseDarken = Value;
            Library:UpdateBlur();
        end;
    });
    Groupbox:AddSlider('LinoriaDarkenAmount', {
        Text     = 'Darken Amount';
        Default  = Library.DarkenAmount;
        Min      = 0;
        Max      = 100;
        Rounding = 0;
        Suffix   = '%';
        Callback = function(Value)
            Library.DarkenAmount = Value;
            Library:UpdateBlur();
        end;
    });
end

-- Control keybind frame background transparency (0 = opaque, 1 = invisible)
function Library:SetKeybindTransparency(Value)
    Value = math.clamp(Value, 0, 1);
    local Inner = Library.KeybindInner;
    if Library.KeybindFrame then
        Library.KeybindFrame.BackgroundTransparency = Value;
        Library.KeybindFrame.BorderSizePixel = Value >= 1 and 0 or 1;
        if not Inner then
            Inner = Library.KeybindFrame:FindFirstChildOfClass('Frame');
        end
    end
    if Inner then
        Inner.BackgroundTransparency = Value;
        Inner.BorderSizePixel = Value >= 1 and 0 or 1;
    end
    if Library.KeybindColorFrame then
        Library.KeybindColorFrame.BackgroundTransparency = Value;
    end
end

-- Call this with any Groupbox to add a keybind frame transparency slider
-- e.g. Library:AddKeybindTransparencySlider(MyGroupbox)
function Library:AddKeybindTransparencySlider(Groupbox)
    Groupbox:AddSlider('LinoriaKeybindTransparency', {
        Text     = 'Keybind Transparency';
        Default  = 0;
        Min      = 0;
        Max      = 100;
        Rounding = 0;
        Suffix   = '%';
        Callback = function(Value)
            Library:SetKeybindTransparency(Value / 100);
        end;
    });
end

function Library:SetFontSize(Size)
    Library.FontSize = Size
    for _, descendant in pairs(ScreenGui:GetDescendants()) do
        if descendant:IsA("TextLabel") or descendant:IsA("TextBox") or descendant:IsA("TextButton") then
            local offset = descendant:GetAttribute("FontSizeOffset")
            if offset then
                descendant.TextSize = Size + offset
            end
        end
    end
    local mobileUI = CoreGui:FindFirstChild("LinoriaMobileUI")
    if mobileUI then
        for _, descendant in pairs(mobileUI:GetDescendants()) do
            if descendant:IsA("TextLabel") or descendant:IsA("TextBox") or descendant:IsA("TextButton") then
                local offset = descendant:GetAttribute("FontSizeOffset")
                if offset then
                    descendant.TextSize = Size + offset
                end
            end
        end
    end
end

local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta

    if RainbowStep >= (1 / 60) then
        RainbowStep = 0

        Hue = Hue + (1 / 400);
        if Hue > 1 then
            Hue = 0;
        end;

        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();
    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name;
    end;
    table.sort(PlayerList, function(str1, str2) return str1 < str2 end);

    return PlayerList;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams();
    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name;
    end;
    table.sort(TeamList, function(str1, str2) return str1 < str2 end);
    
    return TeamList;
end;

function Library:SafeCallback(f, ...)
    if (not f) then
        return;
    end;
    if not Library.NotifyOnError then
        return f(...);
    end;

    local success, event = pcall(f, ...);
    if not success then
        local _, i = event:find(":%d+: ");
        if not i then
            return Library:Notify(event);
        end;
        return Library:Notify(event:sub(i + 1), 3);
    end;
end;

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;
    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;
    for Property, Value in next, Properties do
        pcall(function()
            _Instance[Property] = Value;
        end);
    end;

    if _Instance:IsA("TextLabel") or _Instance:IsA("TextBox") or _Instance:IsA("TextButton") then
        if Properties.TextSize then
            _Instance:SetAttribute("FontSizeOffset", Properties.TextSize - Library.FontSize)
        else
            _Instance:SetAttribute("FontSizeOffset", 0)
        end
    end

    return _Instance;
end;

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;

    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        LineJoinMode = Enum.LineJoinMode.Miter;
        Parent = Inst;
    });
end;

function Library:ApplyGlow(Inst)

end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize = Library.FontSize + 2;
        TextStrokeTransparency = 0;
    });
    Library:ApplyTextStroke(_Instance);

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);
    return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, Cutoff, IsWindow)
    Instance.Active = true;
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            local StartPos = Instance.Position
            local DragStart = Input.Position

            if (DragStart.Y - Instance.AbsolutePosition.Y) > (Cutoff or 40) then
                return
            end

            local Dragging = true
            local HasMoved = false
            local Wireframe = nil
            local ChangedConn, EndedConn

            ChangedConn = InputService.InputChanged:Connect(function(Change)
                if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                    local Delta = Change.Position - DragStart
                    
                    if IsWindow and Library.WireframeDrag then
                        if not HasMoved and Delta.Magnitude > 2 then
                            HasMoved = true
                            
                            Wireframe = Library:Create("Frame", {
                                Size = Instance.Size,
                                Position = Instance.Position,
                                AnchorPoint = Instance.AnchorPoint,
                                BackgroundColor3 = Library.MainColor,
                                BackgroundTransparency = 0.5,
                                Active = false,
                                ZIndex = 100000,
                                Parent = ScreenGui
                            })
                         
                            local stroke = Library:Create("UIStroke", {
                                Color = Library.AccentColor,
                                Thickness = 1,
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                                Parent = Wireframe
                            })
                        end
                        
                        if HasMoved and Wireframe then
                            Wireframe.Position = UDim2.new(
                                StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                                StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                            )
                        end
                    else
                        Instance.Position = UDim2.new(
                            StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                            StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                        )
                    end
                end
            end)

            EndedConn = InputService.InputEnded:Connect(function(EndInput)
                if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                    ChangedConn:Disconnect()
                    EndedConn:Disconnect()
                    
                    if IsWindow and Library.WireframeDrag and HasMoved and Wireframe then
                        Instance.Position = Wireframe.Position
                        
                        Wireframe:Destroy()
                        Wireframe = nil
                    end
                end
            end)
        end
    end)
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, Library.FontSize);
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,

        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,

        Visible = false,
    })

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y);
        TextSize = Library.FontSize;
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1,

        Parent = Tooltip;
    });
    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });
    Library:AddToRegistry(Label, {
        TextColor3 = 'FontColor',
    });
    local IsHovering = false

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return
        end

        IsHovering = true

        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true

        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

            return true;
        end;
    end;
end;

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

        return true;
    end;
end;

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update();
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end;

local function fontScale(font)
    if font == Enum.Font.Code then return 0.9 end;
    if font == Enum.Font.RobotoMono then return 0.92 end;
    if font == Enum.Font.GothamBold then return 0.95 end;
    if font == Enum.Font.SciFi then return 0.84 end;
    if font == Enum.Font.Arcade then return 0.78 end;
    if font == Enum.Font.FredokaOne then return 0.86 end;
    if font == Enum.Font.Cartoon then return 0.88 end;
    return 1;
end;

Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };

    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;

    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;

        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;

        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:UpdateColorsUsingRegistry()
    for Idx, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == 'string' then
                Object.Instance[Property] = Library[ColorIdx];
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end;
    end;
end;

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end

    if Library.OnUnload then
        Library.OnUnload()
    end
    
    if Library.BlurEffect then
        Library.BlurEffect:Destroy()
    end

    if Library.DarkOverlay and Library.DarkOverlay.Parent then
        Library.DarkOverlay.Parent:Destroy()
    end

    ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end))

local BaseAddons = {};
do
    local Funcs = {};

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        assert(Info.Default, 'AddColorPicker: Missing default value.');

        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end;
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);
            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;

        ColorPicker:SetHSVFromRGB(ColorPicker.Value);
        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(0, 28, 0, 14);
            ZIndex = 6;
            Parent = ToggleLabel;
        });
        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(0, 27, 0, 13);
            ZIndex = 5;
            Image = 'http://www.roblox.com/asset/?id=12977615774';
            Visible = not not Info.Transparency;
            Parent = DisplayFrame;
        });

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        });
        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
        end)

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });
        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });
        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });
        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        });
        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapInner;
        });
        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        });
        local CursorInner = Library:Create('ImageLabel', {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex = 20;
            Parent = CursorOuter;
        })

        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        });
        local HueCursor = Library:Create('Frame', { 
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = 18;
            Parent = HueSelectorInner;
        });

        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner;
        });
        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = HueBoxOuter;
        });
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = HueBoxInner;
        });

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor;
            TextSize = Library.FontSize;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 20,
            Parent = HueBoxInner;
        });

        Library:ApplyTextStroke(HueBox);

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        });
        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = Library.FontColor
        });
        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor;
        
        if Info.Transparency then 
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = PickerFrameInner;
            });
            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = TransparencyBoxOuter;
            });
            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' });

            Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 20;
                Parent = TransparencyBoxInner;
            });
            TransparencyCursor = Library:Create('Frame', { 
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 21;
                Parent = TransparencyBoxInner;
            });
        end;

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = Library.FontSize;
            Text = ColorPicker.Title,
            TextWrapped = false;
            ZIndex = 16;
            Parent = PickerFrameInner;
        });
        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,
                Visible = false,
                Parent = ScreenGui
            })

            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = ContextMenu.Container;
            });
            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = ContextMenu.Inner;
            });
            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            });
            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end

            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end

                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end

            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)

            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            function ContextMenu:Show()
                self.Container.Visible = true
            end

            function ContextMenu:Hide()
                self.Container.Visible = false
            end

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then
                    Callback = function() end
                end

                local Button = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = Library.FontSize - 1;
                    Text = Str;
                    ZIndex = 16;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                });
                Library:OnHighlight(Button, Button, 
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor' }
                );
                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end

                    Callback()
                end)
            end

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)

            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then
                    return Library:Notify('You have not copied a color!', 2)
                end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)


            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('Copied hex code to clipboard!', 2)
            end)

            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', '))
                Library:Notify('Copied RGB values to clipboard!', 2)
            end)

        end

        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor', });
        Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor', });

        local SequenceTable = {};
        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
        end;

        local HueSelectorGradient = Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent = HueSelectorInner;
        });
        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end

            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end

            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);

            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value;
                BackgroundTransparency = ColorPicker.Transparency;
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            });
            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value;
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0);
            end;

            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0);

            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value);
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value);
        end;

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            Func(ColorPicker.Value)
        end;

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false;
                    Library.OpenedFrames[Frame] = nil;
                end;
            end;

            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = true;
        end;
        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;
        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local function UpdateColor(PosX, PosY)
                    local MinX = SatVibMap.AbsolutePosition.X;
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X;
                    local MouseX = math.clamp(PosX, MinX, MaxX);

                    local MinY = SatVibMap.AbsolutePosition.Y;
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
                    local MouseY = math.clamp(PosY, MinY, MaxY);

                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();
                end

                UpdateColor(Input.Position.X, Input.Position.Y)

                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateColor(Change.Position.X, Change.Position.Y)
                    end
                end)

                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end
        end);
        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local function UpdateHue(PosY)
                    local MinY = HueSelectorInner.AbsolutePosition.Y;
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y;
                    local MouseY = math.clamp(PosY, MinY, MaxY);

                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();
                end

                UpdateHue(Input.Position.Y)

                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateHue(Change.Position.Y)
                    end
                end)

                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end
        end);
        DisplayFrame.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end;
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end);

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    local function UpdateAlpha(PosX)
                        local MinX = TransparencyBoxInner.AbsolutePosition.X;
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X;
                        local MouseX = math.clamp(PosX, MinX, MaxX);

                        ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX));
                        ColorPicker:Display();
                    end

                    UpdateAlpha(Input.Position.X)

                    local ChangedConn = InputService.InputChanged:Connect(function(Change)
                        if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                            UpdateAlpha(Change.Position.X)
                        end
                    end)

                    local EndedConn
                    EndedConn = InputService.InputEnded:Connect(function(EndInput)
                        if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                            ChangedConn:Disconnect()
                            EndedConn:Disconnect()
                            Library:AttemptSave()
                        end
                    end)
                end
            end);
        end;

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;
                local DFPos = DisplayFrame.AbsolutePosition;
                local DFSize = DisplayFrame.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < DFPos.Y or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    if not (Mouse.X >= DFPos.X and Mouse.X <= DFPos.X + DFSize.X
                        and Mouse.Y >= DFPos.Y and Mouse.Y <= DFPos.Y + DFSize.Y) then
                        ColorPicker:Hide();
                    end
                end;

                if not Library:IsMouseOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))

        function ColorPicker:GetTransparency()
            return ColorPicker.Transparency;
        end;

        function ColorPicker:OnTransparencyChanged(Func)
            ColorPicker.TransparencyChanged = Func;
            Func(ColorPicker.Transparency);
        end;

        local _OrigDisplay = ColorPicker.Display;
        ColorPicker.Display = function(self)
            _OrigDisplay(self);
            Library:SafeCallback(ColorPicker.TransparencyChanged, ColorPicker.Transparency);
        end;

        ColorPicker:Display();
        ColorPicker.DisplayFrame = DisplayFrame

        Options[Idx] = ColorPicker;

        return self;
    end;

    function Funcs:AddColorPickerAlpha(Idx, Info)
        Info = Info or {};
        if Info.Transparency == nil then
            Info.Transparency = 0;
        end;
        return Funcs.AddColorPicker(self, Idx, Info);
    end;

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self;
        local ToggleLabel = self.TextLabel;
        local Container = self.Container;

        assert(Info.Default, 'AddKeyPicker: Missing default value.');

        local KeyPicker = {
            Value = Info.Default;
            Toggled = false;
            Mode = Info.Mode or 'Toggle';
            Type = 'KeyPicker';
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;

            SyncToggleState = Info.SyncToggleState or false;
        };
        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' }
            Info.Mode = 'Toggle'
        end

        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 6;
            Parent = ToggleLabel;
        });
        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = PickOuter;
        });
        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = Library.FontSize - 1;
            Text = Info.Default;
            TextWrapped = true;
            ZIndex = 8;
            Parent = PickInner;
        });
        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
            Size = UDim2.new(0, 60, 0, 45 + 2);
            Visible = false;
            ZIndex = 14;
            Parent = ScreenGui;
        });
        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
        end);
        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 15;
            Parent = ModeSelectOuter;
        });
        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        });
        local KeybindEntry = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Visible = false,
            ZIndex = 110,
            Parent = Library.KeybindContainer,
        })

        local ContainerLabel = Library:CreateLabel({
            Position = UDim2.new(0, 2, 0, 0),
            Size = UDim2.new(1, -4, 1, 0),
            TextSize = Library.FontSize - 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 111,
            Parent = KeybindEntry,
        }, true)

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
        local ModeButtons = {};

        for Idx, Mode in next, Modes do
            local ModeButton = {};
            local Label = Library:CreateLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = Library.FontSize - 1;
                Text = Mode;
                ZIndex = 16;
                Parent = ModeSelectInner;
            });
            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect();
                end;

                KeyPicker.Mode = Mode;

                Label.TextColor3 = Library.AccentColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';

                ModeSelectOuter.Visible = false;
            end;
            function ModeButton:Deselect()
                KeyPicker.Mode = nil;
                Label.TextColor3 = Library.FontColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
            end;

            Label.InputBegan:Connect(function(Input)
                if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                    ModeButton:Select();
                    Library:AttemptSave();
                end;
            end);
            if Mode == KeyPicker.Mode then
                ModeButton:Select();
            end;

            ModeButtons[Mode] = ModeButton;
        end;

        function KeyPicker:Update()
            if Info.NoUI then
                return;
            end;

            local State = KeyPicker:GetState();

            local displayKey = (KeyPicker.Value == 'None') and '...' or KeyPicker.Value
            ContainerLabel.Text = string.format('[%s] %s (%s)', displayKey, Info.Text, KeyPicker.Mode);
            local kbMode = Library.KeybindMode or 'All'
            if kbMode == 'Active' then
                KeybindEntry.Visible = State == true
            elseif kbMode == 'Toggled' then
                local parentOn = false
                if ParentObj and ParentObj.Type == 'Toggle' then
                    parentOn = ParentObj.Value == true
                elseif KeyPicker.SyncToggleState and ParentObj then
                    parentOn = ParentObj.Value == true
                else
                    parentOn = true
                end
                KeybindEntry.Visible = parentOn
            else
                KeybindEntry.Visible = true
            end

            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor;
            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor';

            local YSize = 0
            local XSize = 0

            for _, Frame in next, Library.KeybindContainer:GetChildren() do
                if Frame:IsA('Frame') and Frame.Visible then
                    YSize = YSize + 18;
                    local LabelChild = Frame:FindFirstChildOfClass('TextLabel')
                    if LabelChild and (LabelChild.TextBounds.X + 20 > XSize) then
                        XSize = LabelChild.TextBounds.X + 20 
                    end
                end;
            end;

            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10 + 15, 210), 0, YSize + 23)
        end;
        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true;
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then
                    return false;
                end

                local Key = KeyPicker.Value;
                if Key == 'MB1' or Key == 'MB2' or Key == 'Touch' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                        or Key == 'Touch' and true
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value]);
                end;
            else
                return KeyPicker.Toggled;
            end;
        end;

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2];
            DisplayLabel.Text = Key;
            KeyPicker.Value = Key;
            ModeButtons[Mode]:Select();
            KeyPicker:Update();
        end;

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end

        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            Callback(KeyPicker.Value)
        end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
            table.insert(Library.KeyPickerList, KeyPicker)
        end

        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
        end

        local Picking = false;
        local LongPressTime = Info.LongPressTime or 0.55;
        local TouchMoveThreshold = Info.TouchMoveThreshold or 10;

        local function OpenModeSelect()
            ModeSelectOuter.Visible = true;
        end;

        local function BeginPicking()
            if Picking then
                return;
            end;

            Picking = true;

            DisplayLabel.Text = '';

            local Break;
            local Text = '';

            task.spawn(function()
                while (not Break) do
                    if Text == '...' then
                        Text = '';
                    end;

                    Text = Text .. '.';
                    DisplayLabel.Text = Text;

                    wait(0.4);
                end;
            end);

            wait(0.2);

            local Event;
            Event = InputService.InputBegan:Connect(function(Input)
                local Key;

                if Input.UserInputType == Enum.UserInputType.Keyboard then
                    Key = Input.KeyCode.Name;
                elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Key = 'MB1';
                elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                    Key = 'MB2';
                elseif Input.UserInputType == Enum.UserInputType.Touch then
                    Key = 'Touch';
                end;

                if not Key then
                    return;
                end;

                Break = true;
                Picking = false;

                DisplayLabel.Text = Key;
                KeyPicker.Value = Key;
                Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
                Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)

                Library:AttemptSave();
                Event:Disconnect();
            end);
        end;

        PickOuter.InputBegan:Connect(function(Input)
            if Library:MouseIsOverOpenedFrame() then
                return;
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                BeginPicking();
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                OpenModeSelect();
            elseif Input.UserInputType == Enum.UserInputType.Touch then
                local StartPosition = Input.Position;
                local TouchMoved = false;
                local TouchEnded = false;
                local LongPressed = false;
                local ChangedConn;
                local EndedConn;

                ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change == Input then
                        if (Change.Position - StartPosition).Magnitude > TouchMoveThreshold then
                            TouchMoved = true;
                        end;
                    end;
                end);

                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input then
                        TouchEnded = true;

                        if ChangedConn then
                            ChangedConn:Disconnect();
                        end;

                        if EndedConn then
                            EndedConn:Disconnect();
                        end;

                        if (not LongPressed) and (not TouchMoved) then
                            task.spawn(BeginPicking);
                        end;
                    end;
                end);

                task.delay(LongPressTime, function()
                    if TouchEnded or TouchMoved then
                        return;
                    end;

                    LongPressed = true;

                    if ChangedConn then
                        ChangedConn:Disconnect();
                    end;

                    if EndedConn then
                        EndedConn:Disconnect();
                    end;

                    OpenModeSelect();
                end);
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (not Picking) then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value;

                    if Key == 'MB1' or Key == 'MB2' or Key == 'Touch' then
                        if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
                        or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2 
                        or Key == 'Touch' and Input.UserInputType == Enum.UserInputType.Touch then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end;
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled;
                            KeyPicker:DoClick()
                        end;
                    end;
                end;

                KeyPicker:Update();
            end;
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ModeSelectOuter.Visible = false;
                end;
            end;
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if (not Picking) then
                KeyPicker:Update();
            end;
        end))

        KeyPicker:Update();
        Options[Idx] = KeyPicker;

        return self;
    end;

    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

local BaseGroupbox = {};

do
    local Funcs = {};
    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Container = Groupbox.Container;
        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container;
        });
    end;

    function Funcs:AddRow(Columns)
        local Groupbox = self
        local Container = Groupbox.Container

        local ColumnsCount = type(Columns) == 'number' and math.max(1, Columns) or 2

        local RowOuter = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            ZIndex = 1,
            Parent = Container
        })

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = RowOuter
        })

        local Boxes = {}

        for i = 1, ColumnsCount do
            local Box = { Type = 'Groupbox' }

            local BoxContainer = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Size = UDim2.new(1 / ColumnsCount, -((ColumnsCount - 1) * 8) / ColumnsCount, 1, 0),
                ZIndex = 1,
                Parent = RowOuter
            })

            local BoxLayout = Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = BoxContainer
            })

            Box.Container = BoxContainer
            setmetatable(Box, BaseGroupbox)

            function Box:Resize()
                local maxHeight = 0
                for _, child in next, RowOuter:GetChildren() do
                    if child:IsA('Frame') then
                        local layout = child:FindFirstChildOfClass('UIListLayout')
                        if layout and layout.AbsoluteContentSize.Y > maxHeight then
                            maxHeight = layout.AbsoluteContentSize.Y
                        end
                    end
                end
                RowOuter.Size = UDim2.new(1, 0, 0, maxHeight)
                if Groupbox.Resize then
                    Groupbox:Resize()
                end
            end

            BoxLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Box:Resize()
            end)

            table.insert(Boxes, Box)
        end

        Groupbox:AddBlank(1)
        if Groupbox.Resize then Groupbox:Resize() end

        return unpack(Boxes)
    end;
    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {};

        local Groupbox = self;
        local Container = Groupbox.Container;

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = Library.FontSize;
            Text = Text;
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });
        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            });
        end

        Label.TextLabel = TextLabel;
        Label.Container = Container;
        function Label:SetText(Text)
            TextLabel.Text = Text

            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end

            Groupbox:Resize();
        end

        if (not DoesWrap) then
            setmetatable(Label, BaseAddons);
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Label;
    end;
    function Funcs:AddButton(...)
        local Button = {};
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end

            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
        end

        ProcessButtonParams('Button', Button, ...)

        local Groupbox = self;
        local Container = Groupbox.Container;

        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -4, 0, 20);
                ZIndex = 5;
            });
            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer;
            });
            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = Library.FontSize;
                Text = Button.Text;
                ZIndex = 6;
                Parent = Inner;
            });

            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
                });
                Rotation = 90;
                Parent = Inner;
            });
            Library:AddToRegistry(Outer, {
                BorderColor3 = 'Black';
            });
            Library:AddToRegistry(Inner, {
                BackgroundColor3 = 'MainColor';
                BorderColor3 = 'OutlineColor';
            });
            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'Black' }
            );
            return Outer, Inner, Label
        end

        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent')
                local connection = event:Once(function(...)

                    if type(validator) == 'function' and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    connection:disconnect()
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end

            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then
                    return false
                end

                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                    return false
                end

                return true
            end

            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end
 
                if Button.Locked then return end

                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' })

                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = 'Are you sure?'
                    Button.Locked = true

                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })

                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)

                    if clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    return
                end

                Library:SafeCallback(Button.Func);
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        InitEvents(Button)

        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then
                Library:AddToolTip(tooltip, self.Outer)
            end
            return self
        end

        function Button:AddButton(...)
            local SubButton = {}

            ProcessButtonParams('SubButton', SubButton, ...)

            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)

            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer

            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then
                    Library:AddToolTip(tooltip, self.Outer)
                 end
                return SubButton
            end

            if type(SubButton.Tooltip) == 'string' then
                SubButton:AddTooltip(SubButton.Tooltip)
            end

            InitEvents(SubButton)
            return SubButton
        end

        if type(Button.Tooltip) == 'string' then
            Button:AddTooltip(Button.Tooltip)
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Button;
    end;

    function Funcs:AddDivider()
        local Groupbox = self;
        local Container = self.Container

        local Divider = {
            Type = 'Divider',
        }

        Groupbox:AddBlank(2);
        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 5);
            ZIndex = 5;
            Parent = Container;
        });
        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DividerOuter;
        });
        Library:AddToRegistry(DividerOuter, {
            BorderColor3 = 'Black';
        });
        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Groupbox:AddBlank(9);
        Groupbox:Resize();
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Callback = Info.Callback or function(Value) end;
        };
        local Groupbox = self;
        local Container = Groupbox.Container;

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = Library.FontSize;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        Groupbox:AddBlank(1);

        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });
        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        });
        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, TextBoxOuter)
        end

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = TextBoxInner;
        });
        local Container = Library:Create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants = true;

            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);

            ZIndex = 7;
            Parent = TextBoxInner;
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = Info.Placeholder or '';

            Text = Info.Default or '';
            TextColor3 = Library.FontColor;
            TextSize = Library.FontSize;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;

            ZIndex = 7;
            Parent = Container;
        });

        Library:ApplyTextStroke(Box);
        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength);
            end;

            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Textbox.Value
                end
            end

            Textbox.Value = Text;
            Box.Text = Text;

            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed, Textbox.Value);
        end;

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end

                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        end

        local function Update()
            local PADDING = 2
            local reveal = Container.AbsoluteSize.X

            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

                    local currentCursorPos = Box.Position.X.Offset + width

                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end

        task.spawn(Update)

        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, {
            TextColor3 = 'FontColor';
        });

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func;
            Func(Textbox.Value);
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        Options[Idx] = Textbox;

        return Textbox;
    end;

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';

            Callback = Info.Callback or function(Value) end;
            Addons = {},
            Risky = Info.Risky,
        };
        local Groupbox = self;
        local Container = Groupbox.Container;

        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black';
        });
        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        });
        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0);
            Position = UDim2.new(1, 6, 0, 0);
            TextSize = Library.FontSize;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleInner;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        });
        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 170, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        });
        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        function Toggle:UpdateColors()
            Toggle:Display();
        end;
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRegion)
        end

        function Toggle:Display()
            local on = Toggle.Value
            ToggleInner.BackgroundColor3 = on and Library.AccentColor or Library.MainColor;
            ToggleInner.BorderColor3 = on and Library.AccentColorDark or Library.OutlineColor;
            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = on and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = on and 'AccentColorDark' or 'OutlineColor';
        end;

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func(Toggle.Value);
        end;

        function Toggle:SetValue(Bool)
            Bool = (not not Bool);
            Toggle.Value = Bool;
            Toggle:Display();

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;
        ToggleRegion.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value)
                Library:AttemptSave();
            end;
        end);
        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
        end

        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();

        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);

        Toggles[Idx] = Toggle;

        Library:UpdateDependencyBoxes();

        return Toggle;
    end;

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default, 'AddSlider: Missing default value.');
        assert(Info.Text, 'AddSlider: Missing slider text.');
        assert(Info.Min, 'AddSlider: Missing minimum value.');
        assert(Info.Max, 'AddSlider: Missing maximum value.');
        assert(Info.Rounding, 'AddSlider: Missing rounding value.');
        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type = 'Slider';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;
        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = Library.FontSize;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });
            Groupbox:AddBlank(3);
        end

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = 'Black';
        });
        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = SliderOuter;
        });
        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3 = Library.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner;
        });
        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor';
            BorderColor3 = 'AccentColorDark';
        });
        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = 8;
            Parent = Fill;
        });

        Library:AddToRegistry(HideBorderRight, {
            BackgroundColor3 = 'AccentColor';
        });
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = Library.FontSize;
            Text = 'Infinite';
            ZIndex = 9;
            Parent = SliderInner;
        });
        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter)
        end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
            Fill.BorderColor3 = Library.AccentColorDark;
        end;

        function Slider:Display()
            local Suffix = Info.Suffix or '';
            if Info.Compact then
                DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
            elseif Info.HideMax then
                DisplayLabel.Text = string.format('%s', Slider.Value .. Suffix)
            else
                DisplayLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix);
            end

            local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize));
            pcall(function()
                TweenService:Create(Fill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, X, 1, 0);
                }):Play()
            end)
            Fill.Size = UDim2.new(0, X, 1, 0);

            HideBorderRight.Visible = not (X == Slider.MaxSize or X == 0);
        end;
        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func(Slider.Value);
        end;
        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value);
            end;


            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end;
        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max));
        end;
        function Slider:SetValue(Str)
            local Num = tonumber(Str);
            if (not Num) then
                return;
            end;

            Num = math.clamp(Num, Slider.Min, Slider.Max);

            Slider.Value = Num;
            Slider:Display();

            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed, Slider.Value);
        end;
        SliderInner.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                
                local function UpdateSlider(PosX)
                    local gPos = Fill.AbsolutePosition.X
                    
                    local Diff = PosX - gPos
                    local nX = math.clamp(Diff, 0, Slider.MaxSize)

                    local nValue = Slider:GetValueFromXOffset(nX);
                    local OldValue = Slider.Value;
    
                    Slider.Value = nValue;

                    Slider:Display();

                    if nValue ~= OldValue then
                        Library:SafeCallback(Slider.Callback, Slider.Value);
                        Library:SafeCallback(Slider.Changed, Slider.Value);
                    end;
                end

                UpdateSlider(Input.Position.X)

                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateSlider(Change.Position.X)
                    end
                end)

                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end;
        end);

        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();

        Options[Idx] = Slider;

        return Slider;
    end;
    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString();
            Info.AllowNull = true;
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString();
            Info.AllowNull = true;
        end;

        assert(Info.Values, 'AddDropdown: Missing dropdown value list.');
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

        if (not Info.Text) then
            Info.Compact = true;
        end;

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
            SpecialType = Info.SpecialType;
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local RelativeOffset = 0;
        if not Info.Compact then
            local DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = Library.FontSize;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });
            Groupbox:AddBlank(3);
        end

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = 'Black';
        });
        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        });
        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = DropdownInner;
        });

        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex = 8;
            Parent = DropdownInner;
        });
        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = Library.FontSize;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            ZIndex = 7;
            Parent = DropdownInner;
        });
        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, DropdownOuter)
        end

        local MAX_DROPDOWN_ITEMS = 8;
        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui;
        });
        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1);
        end;

        local function RecalculateListSize(YSize)
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, YSize or (MAX_DROPDOWN_ITEMS * 20 + 2))
        end;
        RecalculateListPosition();
        RecalculateListSize();

        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition);

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        });
        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        });
        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = 'AccentColor'
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        });
        function Dropdown:Display()
            local Values = Dropdown.Values;
            local Str = '';

            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ', ';
                    end;
                end;

                Str = Str:sub(1, #Str - 2);
            else
                Str = Dropdown.Value or '';
            end;

            ItemList.Text = (Str == '' and '--' or Str);
        end;
        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {};
                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value);
                end;

                return T;
            else
                return Dropdown.Value and 1 or 0;
            end;
        end;

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values;
            local Buttons = {};

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    Element:Destroy();
                end;
            end;

            local Count = 0;

            for Idx, Value in next, Values do
                local Table = {};
                Count = Count + 1;

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    ZIndex = 23;
                    Active = true,
                    Parent = Scrolling;
                });
                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });
                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = Library.FontSize;
                    Text = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 25;
                    Parent = Button;
                });

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                );
                local Selected;

                if Info.Multi then
                    Selected = Dropdown.Value[Value];
                else
                    Selected = Dropdown.Value == Value;
                end;

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value];
                    else
                        Selected = Dropdown.Value == Value;
                    end;

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
                end;
                ButtonLabel.InputBegan:Connect(function(Input)
                    if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                        local Try = not Selected;

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value[Value] = true;
                                else
                                    Dropdown.Value[Value] = nil;
                                end;
                            else
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value = Value;
                                else
                                    Dropdown.Value = nil;
                                end;

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton();
                                end;
                            end;

                            Table:UpdateButton();
                            Dropdown:Display();

                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);

                            Library:AttemptSave();
                        end;
                    end;
                end);

                Table:UpdateButton();
                Dropdown:Display();

                Buttons[Button] = Table;
            end;
            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1);

            local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1;
            RecalculateListSize(Y);
        end;

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues;
            end;

            Dropdown:BuildDropdownList();
        end;

        function Dropdown:OpenDropdown()
            ListOuter.Visible = true;
            Library.OpenedFrames[ListOuter] = true;
            DropdownArrow.Rotation = 180;
        end;

        function Dropdown:CloseDropdown()
            ListOuter.Visible = false;
            Library.OpenedFrames[ListOuter] = nil;
            DropdownArrow.Rotation = 0;
        end;

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func;
            Func(Dropdown.Value);
        end;

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {};
                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true
                    end;
                end;

                Dropdown.Value = nTable;
            else
                if (not Val) then
                    Dropdown.Value = nil;
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val;
                end;
            end;

            Dropdown:BuildDropdownList();

            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
        end;

        DropdownOuter.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown();
                else
                    Dropdown:OpenDropdown();
                end;
            end;
        end);
        InputService.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    Dropdown:CloseDropdown();
                end;
            end;
        end);
        Dropdown:BuildDropdownList();
        Dropdown:Display();

        local Defaults = {}

        if type(Info.Default) == 'string' then
            local Idx = table.find(Dropdown.Values, Info.Default)
            if Idx then
                table.insert(Defaults, Idx)
            end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local Idx = table.find(Dropdown.Values, Value)
                if Idx then
                    table.insert(Defaults, Idx)
                end
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index];
                end

                if (not Info.Multi) then break end
            end

            Dropdown:BuildDropdownList();
            Dropdown:Display();
        end

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        Options[Idx] = Dropdown;

        return Dropdown;
    end;
    function Funcs:AddDependencyBox()
        local Depbox = {
            Dependencies = {};
        };
        
        local Groupbox = self;
        local Container = Groupbox.Container;

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = Container;
        });
        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder;
        });
        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame;
        });
        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
            Groupbox:Resize();
        end;

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Depbox:Resize();
        end);
        Holder:GetPropertyChangedSignal('Visible'):Connect(function()
            Depbox:Resize();
        end);
        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1];
                local Value = Dependency[2];

                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false;
                    Depbox:Resize();
                    return;
                end;
            end;

            Holder.Visible = true;
            Depbox:Resize();
        end;

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.');
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.');
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.');
            end;

            Depbox.Dependencies = Dependencies;
            Depbox:Update();
        end;

        Depbox.Container = Frame;

        setmetatable(Depbox, BaseGroupbox);

        table.insert(Library.DependencyBoxes, Depbox);

        return Depbox;
    end;

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;
do
    Library.NotificationStack = {};

    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency  = 1;
        Position                = UDim2.new(0, 0, 0, 40);
        Size                    = UDim2.new(0, 320, 1, -50);
        ZIndex                  = 100;
        Parent                  = ScreenGui;
    });
    Library:Create('UIListLayout', {
        Padding        = UDim.new(0, 4);
        FillDirection  = Enum.FillDirection.Vertical;
        SortOrder      = Enum.SortOrder.LayoutOrder;
        Parent         = Library.NotificationArea;
    });

    function Library:ConfigureNotifications(Cfg)
        local C = Library.NotifyConfig;
        for k, v in next, Cfg do C[k] = v end;

        local AnchorX = C.Alignment == "Left" and 0 or (C.Alignment == "Right" and 1 or 0.5);
        local AnchorY = C.BarSide == "Top" and 0 or 1;
        local VAlign  = C.BarSide == "Top" and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom;
        local HAlign  = C.Alignment == "Left" and Enum.HorizontalAlignment.Left or (C.Alignment == "Right" and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Center);

        Library.NotificationArea.AnchorPoint        = Vector2.new(AnchorX, AnchorY);
        Library.NotificationArea.Position           = UDim2.new(C.PosX / 100, 0, C.PosY / 100, 0);
        Library.NotificationArea.ClipsDescendants   = C.ClipDescendants;
        Library.NotificationArea.AutomaticSize      = Enum.AutomaticSize.XY;

        local SizeConstraint = Library.NotificationArea:FindFirstChildOfClass('UISizeConstraint');
        if C.ClipDescendants then
            if not SizeConstraint then
                SizeConstraint = Library:Create('UISizeConstraint', { Parent = Library.NotificationArea });
            end;
            SizeConstraint.MaxSize = Vector2.new(math.huge, C.MaxHeight);
        elseif SizeConstraint then
            SizeConstraint:Destroy();
        end;

        local Layout = Library.NotificationArea:FindFirstChildOfClass('UIListLayout');
        if Layout then
            Layout.VerticalAlignment    = VAlign;
            Layout.HorizontalAlignment  = HAlign;
        end;
    end;

    Library:ConfigureNotifications({});

    local WatermarkOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, -25);
        Size = UDim2.new(0, 213, 0, 20);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });
    Library:AddToRegistry(WatermarkInner, {
        BorderColor3 = 'AccentColor';
    });
    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = WatermarkInner;
    });
    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });
    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });
    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = Library.FontSize;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = InnerFrame;
    });
    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);

    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 210, 0, 20);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    });
    Library:ApplyGlow(KeybindOuter);

    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    });
    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);
    local ColorFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 102;
        Parent = KeybindInner;
    });
    Library:AddToRegistry(ColorFrame, {
        BackgroundColor3 = 'AccentColor';
    }, true);
    Library.KeybindInner = KeybindInner;
    Library.KeybindColorFrame = ColorFrame;
    local KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20);
        Position = UDim2.new(0, 0, 0, 2);
        TextXAlignment = Enum.TextXAlignment.Center,

        Text = 'Keybinds';
        ZIndex = 104;
        Parent = KeybindInner;
    });
    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20);
        ZIndex = 1;
        Parent = KeybindInner;
    });
    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });
    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        Parent = KeybindContainer,
    })

    Library.KeybindFrame = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;
    Library:MakeDraggable(KeybindOuter);
end;

function Library:SetKeybindMode(Mode)
    assert(Mode == 'All' or Mode == 'Active' or Mode == 'Toggled',
        "SetKeybindMode: Mode must be 'All', 'Active', or 'Toggled'")
    Library.KeybindMode = Mode
    Library:RefreshKeybinds()
end

function Library:RefreshKeybinds()
    for _, kp in ipairs(Library.KeyPickerList) do
        if not kp.NoUI then
            pcall(function() kp:Update() end)
        end
    end
end

function Library:SetWatermarkVisibility(Bool)
    Library.Watermark.Visible = Bool;
end;

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, Library.FontSize);
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3);
    Library:SetWatermarkVisibility(true)

    Library.WatermarkText.Text = Text;
end;

function Library:SetNotifySide(Side)
    Library.NotifyConfig.BarSide = Side or "Bottom"
end

function Library:SetNotifyAlignment(Align)
    Library.NotifyConfig.Alignment = Align or "Center"
end

function Library:SetNotifyTransparency(Percent)
    Library.NotifyConfig.Transparency = math.clamp(Percent or 60, 0, 100)
end

function Library:SetNotifyDuration(Seconds)
    Library.NotifyDefaultTime = Seconds or 5
end

function Library:Notify(Text, Time)
    if not Text or Text == "" then return end;
    table.insert(Library.NotifyQueue, { Text = Text, Time = Time });
    Library:ProcessNotifyQueue();
end;

function Library:ProcessNotifyQueue()
    local C = Library.NotifyConfig;
    local ItemHeight = 22 + 4;
    while #Library.NotifyQueue > 0 do
        if C.ClipDescendants and (Library.ActiveNotifyCount + 1) * ItemHeight > C.MaxHeight then break end;
        local Item = table.remove(Library.NotifyQueue, 1);
        Library:SpawnNotify(Item.Text, Item.Time);
    end;
end;

function Library:SpawnNotify(Text, Time)
    local xw = (Library:GetTextBounds(Text, Library.CustomFontFace or Library.Font, 13) or 200);
    local H = 22;
    local NotifyTransparency = (Library.NotifyConfig.Transparency or 0) / 100;
    Library.NotifyCounter = Library.NotifyCounter + 1;
    local Outer = Library:Create('Frame', {
        BackgroundTransparency  = 1;
        BorderSizePixel         = 0;
        Size                    = UDim2.fromOffset(0, H);
        ClipsDescendants        = true;
        LayoutOrder             = Library.NotifyConfig.SortOrder == "Text Length" and #Text or Library.NotifyCounter;
        ZIndex                  = 100;
        Parent                  = Library.NotificationArea;
    });
    local Inner = Library:Create('Frame', {
        BackgroundColor3  = Library.MainColor;
        BackgroundTransparency = NotifyTransparency;
        BorderSizePixel   = 0;
        Size              = UDim2.new(1, 0, 1, 0);
        ZIndex            = 101;
        Parent            = Outer;
    });
    Library:AddToRegistry(Inner, { BackgroundColor3 = 'MainColor' });
    local InnerStroke = Library:Create('UIStroke', {
        Color       = Library.OutlineColor;
        Transparency = NotifyTransparency;
        Thickness   = 1;
        Parent      = Inner;
    });
    Library:AddToRegistry(InnerStroke, { Color = 'OutlineColor' });
    local GradientFrame = Library:Create('Frame', { BackgroundColor3 = Library.MainColor; BackgroundTransparency = NotifyTransparency; BorderSizePixel = 0; Position = UDim2.new(0, 1, 0, 1); Size = UDim2.new(1, -2, 1, -2); ZIndex = 102; Parent = Inner });
    Library:AddToRegistry(GradientFrame, { BackgroundColor3 = 'MainColor' });
    local G = Library:Create('UIGradient', { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)), ColorSequenceKeypoint.new(1, Library.MainColor) }); Rotation = -90; Parent = GradientFrame });
    Library:AddToRegistry(G, { Color = function() return ColorSequence.new({ ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)), ColorSequenceKeypoint.new(1, Library.MainColor) }) end });
    Library:CreateLabel({ Position = UDim2.new(0, 8, 0, 0); Size = UDim2.new(1, -8, 1, 0); Text = Text; TextXAlignment = Enum.TextXAlignment.Left; TextSize = 13; ZIndex = 103; Parent = GradientFrame });
    local BarSide = Library.NotifyConfig.BarSide or "Bottom";
    local AccentBarPos, AccentBarSize;
    if BarSide == "Top" then
        AccentBarPos  = UDim2.new(0, -1, 0, -1);
        AccentBarSize = UDim2.new(1, 2, 0, 3);
    elseif BarSide == "Bottom" then
        AccentBarPos  = UDim2.new(0, -1, 1, -2);
        AccentBarSize = UDim2.new(1, 2, 0, 3);
    elseif BarSide == "Left" then
        AccentBarPos  = UDim2.new(0, -1, 0, -1);
        AccentBarSize = UDim2.new(0, 3, 1, 2);
    else
        AccentBarPos  = UDim2.new(1, -2, 0, -1);
        AccentBarSize = UDim2.new(0, 3, 1, 2);
    end;
    Library:Create('Frame', {
        BackgroundColor3  = Library.AccentColor;
        BorderSizePixel   = 0;
        Position          = AccentBarPos;
        Size              = AccentBarSize;
        ZIndex            = 104;
        Parent            = Outer;
    });
    Library:AddToRegistry(Outer:GetChildren()[#Outer:GetChildren()], { BackgroundColor3 = 'AccentColor' }, true);
    pcall(Outer.TweenSize, Outer, UDim2.fromOffset(xw + 16, H), 'Out', 'Quad', 0.35, true);
    Library.ActiveNotifyCount = Library.ActiveNotifyCount + 1;
    task.spawn(function()
        task.wait(Time or Library.NotifyDefaultTime or 5);
        pcall(Outer.TweenSize, Outer, UDim2.fromOffset(0, H), 'Out', 'Quad', 0.35, true);
        task.wait(0.4);
        Outer:Destroy();
        Library.ActiveNotifyCount = Library.ActiveNotifyCount - 1;
        Library:ProcessNotifyQueue();
    end);
end;


function Library:MakeResizable(Frame, MinSize)
    MinSize = MinSize or Vector2.new(400, 300)
    local S = 16

    -- Hit area (invisible, catches input)
    local Hit = Instance.new('TextButton')
    Hit.BackgroundTransparency = 1
    Hit.BorderSizePixel = 0
    Hit.Size = UDim2.fromOffset(S + 8, S + 8)
    Hit.Position = UDim2.new(1, -(S + 8), 1, -(S + 8))
    Hit.Text = ''
    Hit.ZIndex = 200
    Hit.AutoButtonColor = false
    Hit.Parent = Frame

    -- Small pink corner handle (NOT a big circle)
    local Handle = Instance.new('Frame')
    Handle.BackgroundColor3 = Library.AccentColor
    Handle.BackgroundTransparency = 0.15
    Handle.BorderSizePixel = 0
    Handle.Size = UDim2.fromOffset(S, S)
    Handle.Position = UDim2.new(1, -S, 1, -S)
    Handle.ZIndex = 201
    Handle.Parent = Frame

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = Handle

    Library:AddToRegistry(Handle, { BackgroundColor3 = 'AccentColor' })

    -- 3 diagonal lines
    for i = 0, 2 do
        local Line = Instance.new('Frame')
        Line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Line.BackgroundTransparency = 0.35
        Line.BorderSizePixel = 0
        Line.Size = UDim2.fromOffset(9 - i * 2, 1)
        Line.Position = UDim2.fromOffset(3 + i, 11 - i * 3)
        Line.Rotation = -40
        Line.ZIndex = 202
        Line.Parent = Handle
    end

    local Dragging = false
    local StartMouse, StartSize
    local NormalColor = Library.AccentColor
    local HoverColor = Library:GetDarkerColor(Library.AccentColor)

    local function SetHover(on)
        NormalColor = Library.AccentColor
        HoverColor = Library:GetDarkerColor(Library.AccentColor)
        if on then
            Handle.BackgroundColor3 = HoverColor
            Handle.BackgroundTransparency = 0
        else
            Handle.BackgroundColor3 = NormalColor
            Handle.BackgroundTransparency = 0.15
        end
    end

    Hit.MouseEnter:Connect(function()
        SetHover(true)
    end)
    Hit.MouseLeave:Connect(function()
        if not Dragging then SetHover(false) end
    end)

    Hit.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            SetHover(true)
            StartMouse = Vector2.new(Input.Position.X, Input.Position.Y)
            StartSize = Frame.AbsoluteSize
        end
    end)

    Hit.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
            SetHover(false)
        end
    end)

    Library:GiveSignal(InputService.InputChanged:Connect(function(Input)
        if not Dragging then return end
        if Input.UserInputType ~= Enum.UserInputType.MouseMovement
            and Input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local Delta = Vector2.new(Input.Position.X, Input.Position.Y) - StartMouse
        local nx = math.clamp(StartSize.X + Delta.X, MinSize.X, 2500)
        local ny = math.clamp(StartSize.Y + Delta.Y, MinSize.Y, 2500)
        Frame.Size = UDim2.fromOffset(nx, ny)
    end))
end

function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false;
    end

    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 0 end
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.15 end

    if type(Config.UseBlur) == 'boolean' then Library.UseBlur = Config.UseBlur end
    if type(Config.BlurSize) == 'number' then Library.BlurSize = Config.BlurSize end
    if type(Config.UseDarken) == 'boolean' then Library.UseDarken = Config.UseDarken end
    if type(Config.DarkenAmount) == 'number' then Library.DarkenAmount = Config.DarkenAmount end

    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(550, 650) end
    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end

    if InputService.TouchEnabled then
        local vp = Library.ScreenGui.AbsoluteSize
        local maxWidth = math.min(Config.Size.X.Offset, vp.X - 20)
      
        local maxHeight = math.min(Config.Size.Y.Offset, vp.Y - 60)
        Config.Size = UDim2.fromOffset(maxWidth, maxHeight)
    end

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end

    local Window = {
        Tabs = {};
    };

    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Library.BackgroundColor;
        BackgroundTransparency = Library.GlassEnabled and (Library.OuterGlassTransparency or 0.15) or 0;
        BorderSizePixel = 0;
        Position = Config.Position,
        Size = Config.Size,
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, 8); Parent = Outer; });
    Library:MakeDraggable(Outer, 25, true);
    Library:AddToRegistry(Outer, { BackgroundColor3 = 'BackgroundColor' });
    Library.WindowOuter = Outer;
    Library.WindowInner = nil; -- set after Inner
    Library.WindowConfigSize = Config.Size;
    pcall(function() Library:MakeResizable(Outer) end);

    local Inner = Library:Create('Frame', {
        Name = "Inner",
        BackgroundColor3 = Library.MainColor;
        BackgroundTransparency = Library.GlassEnabled and (Library.GlassTransparency or 0.12) or 0;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = Outer;
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, 7); Parent = Inner; });
    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });
    Library.WindowInner = Inner;
    -- Liquid glass stroke
    local GlassStroke = Library:Create('UIStroke', {
        Color = Library.OutlineColor;
        Transparency = Library.GlassEnabled and 0.3 or 0.1;
        Thickness = 1.2;
        Parent = Outer;
    });
    Library:AddToRegistry(GlassStroke, { Color = 'OutlineColor' });
    -- Liquid glass sheen (subtle top highlight, not white)
    local GlassSheen = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255);
        BackgroundTransparency = Library.GlassEnabled and 0.92 or 1;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 40);
        Position = UDim2.new(0, 0, 0, 0);
        ZIndex = 2;
        Parent = Inner;
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, 7); Parent = GlassSheen; });
    Library:Create('UIGradient', {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 1),
        });
        Rotation = 90;
        Parent = GlassSheen;
    });
    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 12, 0, 0);
        Size = UDim2.new(1, -24, 0, 25);
        Text = Config.Title or '';
        RichText = true; 
        TextXAlignment = Enum.TextXAlignment.Center;
        ZIndex = 3;
        Parent = Inner;
    });
    local MapNameLabel = Library:CreateLabel({
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 0);
        Size = UDim2.new(0, 200, 0, 25);
        Text = '';
        TextColor3 = Library.AccentColor,
        TextXAlignment = Enum.TextXAlignment.Right;
        TextSize = (Library.FontSize or 14) + 2;
        ZIndex = 3;
        Parent = Inner;
    });
    MapNameLabel:SetAttribute("FontSizeOffset", 2);
    Library:AddToRegistry(MapNameLabel, {
        TextColor3 = 'AccentColor';
    });
    task.spawn(function()
        local success, info = pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        end)
        if success and info and info.Name then
            MapNameLabel.Text = info.Name
        else
            MapNameLabel.Text = game.Name or "Unknown Map"
        end
    end)


    local TabBarOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 25);
        Size = UDim2.new(1, -16, 0, 29);
        ZIndex = 1;
        Parent = Inner;
    });
    Library:AddToRegistry(TabBarOuter, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });
    local TabBarInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = TabBarOuter;
    });
    Library:AddToRegistry(TabBarInner, {
        BackgroundColor3 = 'BackgroundColor';
    });
    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 4, 0, 4);
        Size = UDim2.new(1, -8, 1, -8);
        ZIndex = 1;
        Parent = TabBarInner;
    });
    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, Config.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea;
    });
    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 58);
        Size = UDim2.new(1, -16, 1, -66);
        ZIndex = 1;
        Parent = Inner;
    });
    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });
    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    });
    Library:AddToRegistry(MainSectionInner, {
        BackgroundColor3 = 'BackgroundColor';
    });
    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 8);
        Size = UDim2.new(1, -16, 1, -16);
        ZIndex = 2;
        Parent = MainSectionInner;
    });
    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });
    Outer.ClipsDescendants = true;
    local CornerCircle = Library:Create('Frame', {
        AnchorPoint      = Vector2.new(0.5, 0.5);
        BackgroundColor3 = Library.AccentColor;
        BackgroundTransparency = 0.5;
        BorderSizePixel  = 0;
        Position         = UDim2.new(1, 0, 1, 0);
        Size             = UDim2.fromOffset(46, 46);
        ZIndex           = 10;
        Parent           = Inner;
    });
    Library:Create('UICorner', {
        CornerRadius = UDim.new(1, 0);
        Parent       = CornerCircle;
    });
    Library:AddToRegistry(CornerCircle, {
        BackgroundColor3 = 'AccentColor';
    });
    CornerCircle.Active = true;
    CornerCircle.Parent = Outer;
    CornerCircle.ZIndex = 100;

    do
        local MinW = 420;
        local MinH = 340;

        local Resizing = false;
        local ResizeConn, EndConn;
        local StartSize, DragStart, DragType;
        local HasMoved = false;
        local Wireframe;

        local function StopResize()
            Resizing = false;
            if ResizeConn then ResizeConn:Disconnect(); ResizeConn = nil; end
            if EndConn then EndConn:Disconnect(); EndConn = nil; end
        end;

        local function StartResize(Position, FromType)
            if Resizing then return; end
            StopResize();

            Resizing = true;
            StartSize = Outer.Size;
            DragStart = Position;
            DragType = FromType;
            HasMoved = false;
            if Wireframe then Wireframe:Destroy(); Wireframe = nil; end

            ResizeConn = InputService.InputChanged:Connect(function(Change)
                local T = Change.UserInputType;
                if T ~= Enum.UserInputType.MouseMovement and T ~= Enum.UserInputType.Touch then return; end
                if DragType ~= Enum.UserInputType.Touch and T == Enum.UserInputType.Touch then return; end

                local Delta = Change.Position - DragStart;
                if not HasMoved and Delta.Magnitude <= 2 then return; end

                local TopLeft = Outer.AbsolutePosition;
                local VPSize = Library.ScreenGui.AbsoluteSize;

                local NewW = math.clamp(StartSize.X.Offset + Delta.X, MinW, VPSize.X - TopLeft.X);
                local NewH = math.clamp(StartSize.Y.Offset + Delta.Y, MinH, VPSize.Y - TopLeft.Y);

                if Library.WireframeDrag then
                    if not HasMoved then
                        HasMoved = true;

                        Wireframe = Library:Create('Frame', {
                            Size = UDim2.fromOffset(NewW, NewH);
                            Position = UDim2.fromOffset(TopLeft.X, TopLeft.Y);
                            BackgroundTransparency = 1;
                            Active = false;
                            ZIndex = 100000;
                            Parent = ScreenGui;
                        });

                        Library:Create('UIStroke', {
                            Color = Library.AccentColor;
                            Thickness = 1;
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                            Parent = Wireframe;
                        });
                    end;

                    if HasMoved and Wireframe then
                        Wireframe.Position = UDim2.fromOffset(TopLeft.X, TopLeft.Y);
                        Wireframe.Size = UDim2.fromOffset(NewW, NewH);
                    end;
                else
                    Outer.Size = UDim2.fromOffset(NewW, NewH);
                end;
            end);

            EndConn = InputService.InputEnded:Connect(function(EndInput)
                if EndInput.UserInputType == DragType then
                    if Library.WireframeDrag and HasMoved and Wireframe then
                        Outer.Size = Wireframe.Size;
                        Wireframe:Destroy();
                        Wireframe = nil;
                    end;
                    StopResize();
                end;
            end);
        end;

        local function OnHandlePressed(Position, InputType)
            StartResize(Position, InputType);
        end;

        CornerCircle.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                OnHandlePressed(Input.Position, Input.UserInputType);
            end;
        end);

        InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return; end
            if Resizing then return; end

            local WindowPos = Outer.AbsolutePosition;
            local WindowSize = Outer.AbsoluteSize;
            local CenterX = WindowPos.X + WindowSize.X;
            local CenterY = WindowPos.Y + WindowSize.Y;
            local P = Input.Position;
            local Rad = 26;
            local DX = CenterX - P.X;
            local DY = CenterY - P.Y;

            if (DX * DX) + (DY * DY) <= (Rad * Rad) then
                OnHandlePressed(P, Input.UserInputType);
            end;
        end);
    end;

    function Window:SetWindowTitle(Title)
        WindowLabel.Text = Title;
    end;
    function Window:AddTab(Name)
        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
        };

        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, Library.FontSize + 2);
        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0);
            ZIndex = 1;
            Parent = TabArea;
        });
        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });
        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, -1);
            Text = Name;
            ZIndex = 1;
            Parent = TabButton;
        });
        local TabIndicator = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 0, 2); 
            Visible = false; 
            ZIndex = 4;
            Parent = TabButton;
        });
        Library:AddToRegistry(TabIndicator, { BackgroundColor3 = 'AccentColor' });

        local Blocker = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 0, 0, 0);
            Visible = false;
            Parent = TabButton;
        });
        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        });
        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });
        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide;
        });
        for _, Side in next, { LeftSide, RightSide } do
            Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y);
            end);
        end;

        function Tab:ShowTab()
            for _, Tab in next, Window.Tabs do
                Tab:HideTab();
            end;

            Blocker.BackgroundTransparency = 0;
            TabButton.BackgroundColor3 = Library.MainColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor';
            TabFrame.Visible = true;
            TabIndicator.Visible = true;
        end;
        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1;
            TabButton.BackgroundColor3 = Library.BackgroundColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor';
            TabFrame.Visible = false;
            TabIndicator.Visible = false;
        end;
        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position;
            TabListLayout:ApplyLayout();
        end;
        function Tab:AddGroupbox(Info)
            local Groupbox = {};
            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BackgroundTransparency = Library.GlassEnabled and 0.20 or 0;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 507 + 2);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });
            Library:Create('UICorner', { CornerRadius = UDim.new(0, 6); Parent = BoxOuter; });
            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });
            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BackgroundTransparency = Library.GlassEnabled and 0.18 or 0;
                BorderColor3 = Color3.new(0, 0, 0);
                BorderSizePixel = 0;
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });
            Library:Create('UICorner', { CornerRadius = UDim.new(0, 5); Parent = BoxInner; });
            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });
            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 5;
                Parent = BoxInner;
            });
            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });
            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 0, 0, 2);
                TextSize = Library.FontSize;
                Text = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Center;
                ZIndex = 5;
                Parent = BoxInner;
            });
            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 4, 0, 20);
                Size = UDim2.new(1, -4, 1, -20);
                ZIndex = 1;
                Parent = BoxInner;
            });
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            });
            function Groupbox:Resize()
                local Size = 0;
                for _, Element in next, Groupbox.Container:GetChildren() do
                    if (not Element:IsA('UIListLayout')) and Element.Visible then
                        Size = Size + Element.Size.Y.Offset;
                    end;
                end;

                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
            end;

            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);
            Groupbox:AddBlank(3);
            Groupbox:Resize();

            Tab.Groupboxes[Info.Name] = Groupbox;

            return Groupbox;
        end;

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; });
        end;

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; });
        end;

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
            };

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });
            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });
            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });
            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });
            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 5;
                Parent = BoxInner;
            });
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            });
            function Tabbox:AddTab(Name)
                local Tab = {};
                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons;
                });
                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                });
                local TabHighlight = Library:Create('Frame', {
                    BackgroundColor3 = Library.AccentColor;
                    BorderSizePixel = 0;
                    Size = UDim2.new(1, 0, 0, 2);
                    Visible = false;
                    ZIndex = 10;
                    Parent = Button;
                });
                Library:AddToRegistry(TabHighlight, {
                    BackgroundColor3 = 'AccentColor';
                });
                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = Library.FontSize;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                });
                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                });
                Library:AddToRegistry(Block, {
                    BackgroundColor3 = 'BackgroundColor';
                });
                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 4, 0, 20);
                    Size = UDim2.new(1, -4, 1, -20);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                });
                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                });
                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide();
                    end;

                    Container.Visible = true;
                    Block.Visible = true;
                    TabHighlight.Visible = true;

                    Button.BackgroundColor3 = Library.BackgroundColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';

                    Tab:Resize();
                end;
                function Tab:Hide()
                    Container.Visible = false;
                    Block.Visible = false;
                    TabHighlight.Visible = false;

                    Button.BackgroundColor3 = Library.MainColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                end;
                function Tab:Resize()
                    local TabCount = 0;
                    for _, Tab in next, Tabbox.Tabs do
                        TabCount = TabCount + 1;
                    end;

                    for _, Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA('UIListLayout') then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
                        end;
                    end;

                    if (not Container.Visible) then
                        return;
                    end;

                    local Size = 0;

                    for _, Element in next, Tab.Container:GetChildren() do
                        if (not Element:IsA('UIListLayout')) and Element.Visible then
                            Size = Size + Element.Size.Y.Offset;
                        end;
                    end;

                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
                end;
                Button.InputBegan:Connect(function(Input)
                    if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show();
                        Tab:Resize();
                    end;
                end);

                Tab.Container = Container;
                Tabbox.Tabs[Name] = Tab;

                setmetatable(Tab, BaseGroupbox);

                Tab:AddBlank(3);
                Tab:Resize();

                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show();
                end;

                return Tab;
            end;

            Tab.Tabboxes[Info.Name or ''] = Tabbox;

            return Tabbox;
        end;
        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; });
        end;

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; });
        end;

        TabButton.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                Tab:ShowTab();
            end;
        end);
        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab();
        end;
        Window.Tabs[Name] = Tab;
        return Tab;
    end;

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    });
    function Library:Toggle()
        if Library._AnimLock then return end
        Library._AnimLock = true

        local opening = not Library.Toggled
        Library.Toggled = opening
        ModalElement.Modal = opening

        local FadeTime = (Config.MenuFadeTime or 0.2)
        local Style = Enum.EasingStyle.Quint
        local DirIn = Enum.EasingDirection.Out
        local DirOut = Enum.EasingDirection.In

        if opening then
            Outer.Visible = true
            Outer.Size = UDim2.fromOffset(
                math.max(1, Config.Size.X.Offset * 0.92),
                math.max(1, Config.Size.Y.Offset * 0.92)
            )
            Outer.BackgroundTransparency = 1
            if Inner then Inner.BackgroundTransparency = 1 end

            TweenService:Create(Outer, TweenInfo.new(FadeTime, Style, DirIn), {
                Size = Config.Size;
                BackgroundTransparency = Library.GlassEnabled and (Library.OuterGlassTransparency or 0.12) or 0;
            }):Play()
            if Inner then
                TweenService:Create(Inner, TweenInfo.new(FadeTime, Style, DirIn), {
                    BackgroundTransparency = Library.GlassEnabled and Library.GlassTransparency or 0;
                }):Play()
            end

            -- Lightweight cursor (no tight RenderStepped loop to avoid freezes)
            task.spawn(function()
                -- custom cursor always runs when toggled open
                local State = InputService.MouseIconEnabled
                local GuiService = game:GetService("GuiService")
                local Cursor = Instance.new("ImageLabel", ScreenGui)
                Cursor.Image = "http://www.roblox.com/asset/?id=4292970642"
                Cursor.BackgroundTransparency = 1
                Cursor.ZIndex = 100
                Cursor.Size = UDim2.fromOffset(17, 17)
                Cursor.Rotation = -45
                local conn
                conn = RunService.Heartbeat:Connect(function()
                    if not Library.Toggled or not ScreenGui.Parent then
                        if conn then conn:Disconnect() end
                        InputService.MouseIconEnabled = State
                        if Cursor then Cursor:Destroy() end
                        return
                    end
                    InputService.MouseIconEnabled = false
                    local mPos = InputService:GetMouseLocation()
                    Cursor.ImageColor3 = Library.AccentColor
                    Cursor.Position = UDim2.fromOffset(mPos.X, mPos.Y - GuiService:GetGuiInset().Y - 1)
                end)
            end)
            task.delay(FadeTime, function() Library._AnimLock = false end)
        else
            -- Closing animation
            local closeTween = TweenService:Create(Outer, TweenInfo.new(FadeTime, Style, DirOut), {
                Size = UDim2.fromOffset(
                    math.max(1, Config.Size.X.Offset * 0.92),
                    math.max(1, Config.Size.Y.Offset * 0.92)
                );
                BackgroundTransparency = 1;
            })
            if Inner then
                TweenService:Create(Inner, TweenInfo.new(FadeTime, Style, DirOut), {
                    BackgroundTransparency = 1;
                }):Play()
            end
            closeTween:Play()
            closeTween.Completed:Connect(function()
                Outer.Visible = false
                Outer.Size = Config.Size
                Outer.BackgroundTransparency = Library.GlassEnabled and (Library.OuterGlassTransparency or 0.12) or 0
                if Inner then
                    Inner.BackgroundTransparency = Library.GlassEnabled and Library.GlassTransparency or 0
                end
                Library._AnimLock = false
            end)
        end
        Library:UpdateBlur();
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif type(Library.ToggleKeybind) == 'string' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            task.spawn(Library.Toggle)
        end
    end))

    if Config.AutoShow then task.spawn(Library.Toggle) end

    Window.Holder = Outer;
    return Window;
end;

local function OnPlayerChange()
    local PlayerList = GetPlayersString();
    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList);
        end;
    end;
end;

Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);

if InputService.TouchEnabled then
    local MobileGui = Instance.new("ScreenGui")
    MobileGui.Name = "LinoriaMobileUI"
    MobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    ProtectGui(MobileGui)
    MobileGui.Parent = CoreGui

    local BTN_W, BTN_H = 88, 30
    local BTN_GAP      = 40  

    local function CreateMobileButton(name, text, startPos)
        local Outer = Library:Create('Frame', {
            Name             = name .. "Outer",
            BackgroundColor3 = Library.OutlineColor,
            BorderSizePixel  = 0,
            Position         = startPos,
            Size             = UDim2.new(0, BTN_W, 0, BTN_H),
            ZIndex           = 300,
            Parent           = MobileGui,
            Active           = true,
        })
        Library:AddToRegistry(Outer, { BackgroundColor3 = 'OutlineColor' })

        local AccentFrame = Library:Create('Frame', {
            Name             = name .. "Accent",
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel  = 0,
            Position         = UDim2.new(0, 1, 0, 1),
            Size             = UDim2.new(1, -2, 1, -2),
            ZIndex           = 301,
            Parent           = Outer,
        })
        Library:AddToRegistry(AccentFrame, { BackgroundColor3 = 'AccentColor' })

        local Inner = Library:Create('Frame', {
            Name             = name .. "Inner",
            BackgroundColor3 = Color3.fromRGB(8, 8, 12),
            BorderSizePixel  = 0,
            Position         = UDim2.new(0, 1, 0, 1),
            Size             = UDim2.new(1, -2, 1, -2),
            ZIndex           = 302,
            Parent           = AccentFrame,
        })

        local GradientOverlay = Library:Create('Frame', {
            Name             = name .. "Gradient",
            BackgroundColor3 = Color3.new(1, 1, 1), 
            BorderSizePixel  = 0,
            Size             = UDim2.new(1, 0, 1, 0),
            ZIndex           = 303,
            Parent           = Inner,
        })
        Library:Create('UIGradient', {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.90), 
                NumberSequenceKeypoint.new(1, 1.0)   
            }),
            Rotation = 90,
            Parent = GradientOverlay,
        })

        local Btn = Library:Create('TextButton', {
            Name                = name .. "Btn",
            BackgroundTransparency = 1,
            Size                = UDim2.new(1, 0, 1, 0),
            Font                = Enum.Font.Code,
            Text                = text,
            TextColor3          = Color3.fromRGB(255, 255, 255),
            TextSize            = Library.FontSize - 1,
            ZIndex              = 304,
            Parent              = Inner,
            Active              = true,
        })

        return Outer, Btn
    end

    local ToggleOuter, ToggleBtn = CreateMobileButton("Toggle", "Toggle UI",  UDim2.new(0, 10, 0, 10))
    local LockOuter,   LockBtn  = CreateMobileButton("Lock",   "Unlock UI",  UDim2.new(0, 10, 0, 10 + BTN_H + (BTN_GAP - BTN_H)))

    local IsUnlocked = false

    local function BindMobileButtonAction(Btn, Outer, ClickAction)
        local dragging  = false
        local dragInput = nil
        local dragStart = nil
        local startPos  = nil
        local hasMoved  = false

        Btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging  = true
                hasMoved  = false
                dragStart = input.Position
                startPos  = Outer.Position
                dragInput = input

                local connection
                connection = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        connection:Disconnect()
                        if not hasMoved then
                            ClickAction()
                        end
                    end
                end)
            end
        end)

        InputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                if delta.Magnitude > 3 then
                    hasMoved = true
                end
                if IsUnlocked and hasMoved then
                    Outer.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                end
            end
        end)
    end

    BindMobileButtonAction(ToggleBtn, ToggleOuter, function()
        Library:Toggle()
    end)

    BindMobileButtonAction(LockBtn, LockOuter, function()
        IsUnlocked = not IsUnlocked
        LockBtn.Text = IsUnlocked and "Lock UI" or "Unlock UI"
        LockBtn.TextColor3 = IsUnlocked
            and Library.AccentColor
            or  Color3.fromRGB(255, 255, 255)
    end)

    local _origUpdate = Library.UpdateColorsUsingRegistry
    Library.UpdateColorsUsingRegistry = function(self)
        _origUpdate(self)
    end
end



-- Auto-apply Primordial glass theme on load
function Library:ApplyPrimordialTheme()
    -- Always Primordial (from theme list)
    Library.FontColor = Color3.fromRGB(255, 255, 255)
    Library.MainColor = Color3.fromRGB(24, 24, 24)
    Library.BackgroundColor = Color3.fromRGB(18, 18, 18)
    Library.AccentColor = Color3.fromRGB(220, 140, 180)
    Library.OutlineColor = Color3.fromRGB(40, 40, 40)
    Library.RiskColor = Color3.fromRGB(255, 50, 50)
    Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
    Library.GlassEnabled = true
    Library.GlassTransparency = 0.28
    Library.OuterGlassTransparency = 0.30
    Library.UseBlur = true
    Library.BlurSize = 30
    Library.UseDarken = true
    Library.DarkenAmount = 55
    pcall(function() Library:UpdateColorsUsingRegistry() end)
    pcall(function() Library:UpdateBlur() end)
end

function Library:SetGlass(Enabled, Transparency)
    Library.GlassEnabled = Enabled ~= false
    if type(Transparency) == 'number' then
        Library.GlassTransparency = math.clamp(Transparency, 0, 0.85)
        Library.OuterGlassTransparency = math.clamp(Transparency + 0.02, 0, 0.9)
    end
    local outerT = Library.GlassEnabled and (Library.OuterGlassTransparency or 0.30) or 0
    local innerT = Library.GlassEnabled and (Library.GlassTransparency or 0.28) or 0
    pcall(function()
        if Library.WindowOuter then
            Library.WindowOuter.BackgroundTransparency = outerT
        end
        if Library.WindowInner then
            Library.WindowInner.BackgroundTransparency = innerT
        end
        -- Groupboxes glass
        if Library.ScreenGui then
            for _, d in ipairs(Library.ScreenGui:GetDescendants()) do
                if d:IsA('Frame') and d.Name ~= 'DarkOverlay' then
                    local reg = Library.RegistryMap[d]
                    if reg and reg.Properties and reg.Properties.BackgroundColor3 == 'BackgroundColor' then
                        d.BackgroundTransparency = Library.GlassEnabled and math.clamp(innerT * 0.7, 0, 0.5) or 0
                    end
                end
            end
        end
    end)
end

pcall(function() Library:ApplyPrimordialTheme() end)

-- Linoria fork glass/theme extension note 0
-- Linoria fork glass/theme extension note 1
-- Linoria fork glass/theme extension note 2
-- Linoria fork glass/theme extension note 3
-- Linoria fork glass/theme extension note 4
-- Linoria fork glass/theme extension note 5
-- Linoria fork glass/theme extension note 6
-- Linoria fork glass/theme extension note 7
-- Linoria fork glass/theme extension note 8
-- Linoria fork glass/theme extension note 9
-- Linoria fork glass/theme extension note 10
-- Linoria fork glass/theme extension note 11
-- Linoria fork glass/theme extension note 12
-- Linoria fork glass/theme extension note 13
-- Linoria fork glass/theme extension note 14
-- Linoria fork glass/theme extension note 15
-- Linoria fork glass/theme extension note 16
-- Linoria fork glass/theme extension note 17
-- Linoria fork glass/theme extension note 18
-- Linoria fork glass/theme extension note 19
-- Linoria fork glass/theme extension note 20
-- Linoria fork glass/theme extension note 21
-- Linoria fork glass/theme extension note 22
-- Linoria fork glass/theme extension note 23
-- Linoria fork glass/theme extension note 24
-- Linoria fork glass/theme extension note 25
-- Linoria fork glass/theme extension note 26
-- Linoria fork glass/theme extension note 27
-- Linoria fork glass/theme extension note 28
-- Linoria fork glass/theme extension note 29
-- Linoria fork glass/theme extension note 30
-- Linoria fork glass/theme extension note 31
-- Linoria fork glass/theme extension note 32
-- Linoria fork glass/theme extension note 33
-- Linoria fork glass/theme extension note 34
-- Linoria fork glass/theme extension note 35
-- Linoria fork glass/theme extension note 36
-- Linoria fork glass/theme extension note 37
-- Linoria fork glass/theme extension note 38
-- Linoria fork glass/theme extension note 39
-- Linoria fork glass/theme extension note 40
-- Linoria fork glass/theme extension note 41
-- Linoria fork glass/theme extension note 42
-- Linoria fork glass/theme extension note 43
-- Linoria fork glass/theme extension note 44
-- Linoria fork glass/theme extension note 45
-- Linoria fork glass/theme extension note 46
-- Linoria fork glass/theme extension note 47
-- Linoria fork glass/theme extension note 48
-- Linoria fork glass/theme extension note 49
-- Linoria fork glass/theme extension note 50
-- Linoria fork glass/theme extension note 51
-- Linoria fork glass/theme extension note 52
-- Linoria fork glass/theme extension note 53
-- Linoria fork glass/theme extension note 54
-- Linoria fork glass/theme extension note 55
-- Linoria fork glass/theme extension note 56
-- Linoria fork glass/theme extension note 57
-- Linoria fork glass/theme extension note 58
-- Linoria fork glass/theme extension note 59
-- Linoria fork glass/theme extension note 60
-- Linoria fork glass/theme extension note 61
-- Linoria fork glass/theme extension note 62
-- Linoria fork glass/theme extension note 63
-- Linoria fork glass/theme extension note 64
-- Linoria fork glass/theme extension note 65
-- Linoria fork glass/theme extension note 66
-- Linoria fork glass/theme extension note 67
-- Linoria fork glass/theme extension note 68
-- Linoria fork glass/theme extension note 69
-- Linoria fork glass/theme extension note 70
-- Linoria fork glass/theme extension note 71
-- Linoria fork glass/theme extension note 72
-- Linoria fork glass/theme extension note 73
-- Linoria fork glass/theme extension note 74
-- Linoria fork glass/theme extension note 75
-- Linoria fork glass/theme extension note 76
-- Linoria fork glass/theme extension note 77
-- Linoria fork glass/theme extension note 78
-- Linoria fork glass/theme extension note 79
-- Linoria fork glass/theme extension note 80
-- Linoria fork glass/theme extension note 81
-- Linoria fork glass/theme extension note 82
-- Linoria fork glass/theme extension note 83
-- Linoria fork glass/theme extension note 84
-- Linoria fork glass/theme extension note 85
-- Linoria fork glass/theme extension note 86
-- Linoria fork glass/theme extension note 87
-- Linoria fork glass/theme extension note 88
-- Linoria fork glass/theme extension note 89
-- Linoria fork glass/theme extension note 90
-- Linoria fork glass/theme extension note 91
-- Linoria fork glass/theme extension note 92
-- Linoria fork glass/theme extension note 93
-- Linoria fork glass/theme extension note 94
-- Linoria fork glass/theme extension note 95
-- Linoria fork glass/theme extension note 96
-- Linoria fork glass/theme extension note 97
-- Linoria fork glass/theme extension note 98
-- Linoria fork glass/theme extension note 99
-- Linoria fork glass/theme extension note 100
-- Linoria fork glass/theme extension note 101
-- Linoria fork glass/theme extension note 102
-- Linoria fork glass/theme extension note 103
-- Linoria fork glass/theme extension note 104
-- Linoria fork glass/theme extension note 105
-- Linoria fork glass/theme extension note 106
-- Linoria fork glass/theme extension note 107
-- Linoria fork glass/theme extension note 108
-- Linoria fork glass/theme extension note 109
-- Linoria fork glass/theme extension note 110
-- Linoria fork glass/theme extension note 111
-- Linoria fork glass/theme extension note 112
-- Linoria fork glass/theme extension note 113
-- Linoria fork glass/theme extension note 114
-- Linoria fork glass/theme extension note 115
-- Linoria fork glass/theme extension note 116
-- Linoria fork glass/theme extension note 117
-- Linoria fork glass/theme extension note 118
-- Linoria fork glass/theme extension note 119
-- Linoria fork glass/theme extension note 120
-- Linoria fork glass/theme extension note 121
-- Linoria fork glass/theme extension note 122
-- Linoria fork glass/theme extension note 123
-- Linoria fork glass/theme extension note 124
-- Linoria fork glass/theme extension note 125
-- Linoria fork glass/theme extension note 126
-- Linoria fork glass/theme extension note 127
-- Linoria fork glass/theme extension note 128
-- Linoria fork glass/theme extension note 129
-- Linoria fork glass/theme extension note 130
-- Linoria fork glass/theme extension note 131
-- Linoria fork glass/theme extension note 132
-- Linoria fork glass/theme extension note 133
-- Linoria fork glass/theme extension note 134
-- Linoria fork glass/theme extension note 135
-- Linoria fork glass/theme extension note 136
-- Linoria fork glass/theme extension note 137
-- Linoria fork glass/theme extension note 138
-- Linoria fork glass/theme extension note 139
-- Linoria fork glass/theme extension note 140
-- Linoria fork glass/theme extension note 141
-- Linoria fork glass/theme extension note 142
-- Linoria fork glass/theme extension note 143
-- Linoria fork glass/theme extension note 144
-- Linoria fork glass/theme extension note 145
-- Linoria fork glass/theme extension note 146
-- Linoria fork glass/theme extension note 147
-- Linoria fork glass/theme extension note 148
-- Linoria fork glass/theme extension note 149
-- Linoria fork glass/theme extension note 150
-- Linoria fork glass/theme extension note 151
-- Linoria fork glass/theme extension note 152
-- Linoria fork glass/theme extension note 153
-- Linoria fork glass/theme extension note 154
-- Linoria fork glass/theme extension note 155
-- Linoria fork glass/theme extension note 156
-- Linoria fork glass/theme extension note 157
-- Linoria fork glass/theme extension note 158
-- Linoria fork glass/theme extension note 159
-- Linoria fork glass/theme extension note 160
-- Linoria fork glass/theme extension note 161
-- Linoria fork glass/theme extension note 162
-- Linoria fork glass/theme extension note 163
-- Linoria fork glass/theme extension note 164
-- Linoria fork glass/theme extension note 165
-- Linoria fork glass/theme extension note 166
-- Linoria fork glass/theme extension note 167
-- Linoria fork glass/theme extension note 168
-- Linoria fork glass/theme extension note 169
-- Linoria fork glass/theme extension note 170
-- Linoria fork glass/theme extension note 171
-- Linoria fork glass/theme extension note 172
-- Linoria fork glass/theme extension note 173
-- Linoria fork glass/theme extension note 174
-- Linoria fork glass/theme extension note 175
-- Linoria fork glass/theme extension note 176
-- Linoria fork glass/theme extension note 177
-- Linoria fork glass/theme extension note 178
-- Linoria fork glass/theme extension note 179
-- Linoria fork glass/theme extension note 180
-- Linoria fork glass/theme extension note 181
-- Linoria fork glass/theme extension note 182
-- Linoria fork glass/theme extension note 183
-- Linoria fork glass/theme extension note 184
-- Linoria fork glass/theme extension note 185
-- Linoria fork glass/theme extension note 186
-- Linoria fork glass/theme extension note 187
-- Linoria fork glass/theme extension note 188
-- Linoria fork glass/theme extension note 189
-- Linoria fork glass/theme extension note 190
-- Linoria fork glass/theme extension note 191
-- Linoria fork glass/theme extension note 192
-- Linoria fork glass/theme extension note 193
-- Linoria fork glass/theme extension note 194
-- Linoria fork glass/theme extension note 195
-- Linoria fork glass/theme extension note 196
-- Linoria fork glass/theme extension note 197
-- Linoria fork glass/theme extension note 198
-- Linoria fork glass/theme extension note 199
-- Linoria fork glass/theme extension note 200
-- Linoria fork glass/theme extension note 201
-- Linoria fork glass/theme extension note 202
-- Linoria fork glass/theme extension note 203
-- Linoria fork glass/theme extension note 204
-- Linoria fork glass/theme extension note 205
-- Linoria fork glass/theme extension note 206
-- Linoria fork glass/theme extension note 207
-- Linoria fork glass/theme extension note 208
-- Linoria fork glass/theme extension note 209
-- Linoria fork glass/theme extension note 210
-- Linoria fork glass/theme extension note 211
-- Linoria fork glass/theme extension note 212
-- Linoria fork glass/theme extension note 213
-- Linoria fork glass/theme extension note 214
-- Linoria fork glass/theme extension note 215
-- Linoria fork glass/theme extension note 216
-- Linoria fork glass/theme extension note 217
-- Linoria fork glass/theme extension note 218
-- Linoria fork glass/theme extension note 219
-- Linoria fork glass/theme extension note 220
-- Linoria fork glass/theme extension note 221
-- Linoria fork glass/theme extension note 222
-- Linoria fork glass/theme extension note 223
-- Linoria fork glass/theme extension note 224
-- Linoria fork glass/theme extension note 225
-- Linoria fork glass/theme extension note 226
-- Linoria fork glass/theme extension note 227
-- Linoria fork glass/theme extension note 228
-- Linoria fork glass/theme extension note 229
-- Linoria fork glass/theme extension note 230
-- Linoria fork glass/theme extension note 231
-- Linoria fork glass/theme extension note 232
-- Linoria fork glass/theme extension note 233
-- Linoria fork glass/theme extension note 234
-- Linoria fork glass/theme extension note 235
-- Linoria fork glass/theme extension note 236
-- Linoria fork glass/theme extension note 237
-- Linoria fork glass/theme extension note 238
-- Linoria fork glass/theme extension note 239
-- Linoria fork glass/theme extension note 240
-- Linoria fork glass/theme extension note 241
-- Linoria fork glass/theme extension note 242
-- Linoria fork glass/theme extension note 243
-- Linoria fork glass/theme extension note 244
-- Linoria fork glass/theme extension note 245
-- Linoria fork glass/theme extension note 246
-- Linoria fork glass/theme extension note 247
-- Linoria fork glass/theme extension note 248
-- Linoria fork glass/theme extension note 249
-- Linoria fork glass/theme extension note 250
-- Linoria fork glass/theme extension note 251
-- Linoria fork glass/theme extension note 252
-- Linoria fork glass/theme extension note 253
-- Linoria fork glass/theme extension note 254
-- Linoria fork glass/theme extension note 255
-- Linoria fork glass/theme extension note 256
-- Linoria fork glass/theme extension note 257
-- Linoria fork glass/theme extension note 258
-- Linoria fork glass/theme extension note 259
-- Linoria fork glass/theme extension note 260
-- Linoria fork glass/theme extension note 261
-- Linoria fork glass/theme extension note 262
-- Linoria fork glass/theme extension note 263
-- Linoria fork glass/theme extension note 264
-- Linoria fork glass/theme extension note 265
-- Linoria fork glass/theme extension note 266
-- Linoria fork glass/theme extension note 267
-- Linoria fork glass/theme extension note 268
-- Linoria fork glass/theme extension note 269
-- Linoria fork glass/theme extension note 270
-- Linoria fork glass/theme extension note 271
-- Linoria fork glass/theme extension note 272
-- Linoria fork glass/theme extension note 273
-- Linoria fork glass/theme extension note 274
-- Linoria fork glass/theme extension note 275
-- Linoria fork glass/theme extension note 276
-- Linoria fork glass/theme extension note 277
-- Linoria fork glass/theme extension note 278
-- Linoria fork glass/theme extension note 279
-- Linoria fork glass/theme extension note 280
-- Linoria fork glass/theme extension note 281
-- Linoria fork glass/theme extension note 282
-- Linoria fork glass/theme extension note 283
-- Linoria fork glass/theme extension note 284
-- Linoria fork glass/theme extension note 285
-- Linoria fork glass/theme extension note 286
-- Linoria fork glass/theme extension note 287
-- Linoria fork glass/theme extension note 288
-- Linoria fork glass/theme extension note 289
-- Linoria fork glass/theme extension note 290
-- Linoria fork glass/theme extension note 291
-- Linoria fork glass/theme extension note 292
-- Linoria fork glass/theme extension note 293
-- Linoria fork glass/theme extension note 294
-- Linoria fork glass/theme extension note 295
-- Linoria fork glass/theme extension note 296
-- Linoria fork glass/theme extension note 297
-- Linoria fork glass/theme extension note 298
-- Linoria fork glass/theme extension note 299
-- Linoria fork glass/theme extension note 300
-- Linoria fork glass/theme extension note 301
-- Linoria fork glass/theme extension note 302
-- Linoria fork glass/theme extension note 303
-- Linoria fork glass/theme extension note 304
-- Linoria fork glass/theme extension note 305
-- Linoria fork glass/theme extension note 306
-- Linoria fork glass/theme extension note 307
-- Linoria fork glass/theme extension note 308
-- Linoria fork glass/theme extension note 309
-- Linoria fork glass/theme extension note 310
-- Linoria fork glass/theme extension note 311
-- Linoria fork glass/theme extension note 312
-- Linoria fork glass/theme extension note 313
-- Linoria fork glass/theme extension note 314
-- Linoria fork glass/theme extension note 315
-- Linoria fork glass/theme extension note 316
-- Linoria fork glass/theme extension note 317
-- Linoria fork glass/theme extension note 318
-- Linoria fork glass/theme extension note 319
-- Linoria fork glass/theme extension note 320
-- Linoria fork glass/theme extension note 321
-- Linoria fork glass/theme extension note 322
-- Linoria fork glass/theme extension note 323
-- Linoria fork glass/theme extension note 324
-- Linoria fork glass/theme extension note 325
-- Linoria fork glass/theme extension note 326
-- Linoria fork glass/theme extension note 327
-- Linoria fork glass/theme extension note 328
-- Linoria fork glass/theme extension note 329
-- Linoria fork glass/theme extension note 330
-- Linoria fork glass/theme extension note 331
-- Linoria fork glass/theme extension note 332
-- Linoria fork glass/theme extension note 333
-- Linoria fork glass/theme extension note 334
-- Linoria fork glass/theme extension note 335
-- Linoria fork glass/theme extension note 336
-- Linoria fork glass/theme extension note 337
-- Linoria fork glass/theme extension note 338
-- Linoria fork glass/theme extension note 339
-- Linoria fork glass/theme extension note 340
-- Linoria fork glass/theme extension note 341
-- Linoria fork glass/theme extension note 342
-- Linoria fork glass/theme extension note 343
-- Linoria fork glass/theme extension note 344
-- Linoria fork glass/theme extension note 345
-- Linoria fork glass/theme extension note 346
-- Linoria fork glass/theme extension note 347
-- Linoria fork glass/theme extension note 348
-- Linoria fork glass/theme extension note 349
-- Linoria fork glass/theme extension note 350
-- Linoria fork glass/theme extension note 351
-- Linoria fork glass/theme extension note 352
-- Linoria fork glass/theme extension note 353
-- Linoria fork glass/theme extension note 354
-- Linoria fork glass/theme extension note 355
-- Linoria fork glass/theme extension note 356
-- Linoria fork glass/theme extension note 357
-- Linoria fork glass/theme extension note 358
-- Linoria fork glass/theme extension note 359
-- Linoria fork glass/theme extension note 360
-- Linoria fork glass/theme extension note 361
-- Linoria fork glass/theme extension note 362
-- Linoria fork glass/theme extension note 363
-- Linoria fork glass/theme extension note 364
-- Linoria fork glass/theme extension note 365
-- Linoria fork glass/theme extension note 366
-- Linoria fork glass/theme extension note 367
-- Linoria fork glass/theme extension note 368
-- Linoria fork glass/theme extension note 369
-- Linoria fork glass/theme extension note 370
-- Linoria fork glass/theme extension note 371
-- Linoria fork glass/theme extension note 372
-- Linoria fork glass/theme extension note 373
-- Linoria fork glass/theme extension note 374
-- Linoria fork glass/theme extension note 375
-- Linoria fork glass/theme extension note 376
-- Linoria fork glass/theme extension note 377
-- Linoria fork glass/theme extension note 378
-- Linoria fork glass/theme extension note 379
-- Linoria fork glass/theme extension note 380
-- Linoria fork glass/theme extension note 381
-- Linoria fork glass/theme extension note 382
-- Linoria fork glass/theme extension note 383
-- Linoria fork glass/theme extension note 384
-- Linoria fork glass/theme extension note 385
-- Linoria fork glass/theme extension note 386
-- Linoria fork glass/theme extension note 387
-- Linoria fork glass/theme extension note 388
-- Linoria fork glass/theme extension note 389
-- Linoria fork glass/theme extension note 390
-- Linoria fork glass/theme extension note 391
-- Linoria fork glass/theme extension note 392
-- Linoria fork glass/theme extension note 393
-- Linoria fork glass/theme extension note 394
-- Linoria fork glass/theme extension note 395
-- Linoria fork glass/theme extension note 396
-- Linoria fork glass/theme extension note 397
-- Linoria fork glass/theme extension note 398
-- Linoria fork glass/theme extension note 399
-- Linoria fork glass/theme extension note 400
-- Linoria fork glass/theme extension note 401
-- Linoria fork glass/theme extension note 402
-- Linoria fork glass/theme extension note 403
-- Linoria fork glass/theme extension note 404
-- Linoria fork glass/theme extension note 405
-- Linoria fork glass/theme extension note 406
-- Linoria fork glass/theme extension note 407
-- Linoria fork glass/theme extension note 408
-- Linoria fork glass/theme extension note 409
-- Linoria fork glass/theme extension note 410
-- Linoria fork glass/theme extension note 411
-- Linoria fork glass/theme extension note 412
-- Linoria fork glass/theme extension note 413
-- Linoria fork glass/theme extension note 414
-- Linoria fork glass/theme extension note 415
-- Linoria fork glass/theme extension note 416
-- Linoria fork glass/theme extension note 417
-- Linoria fork glass/theme extension note 418
-- Linoria fork glass/theme extension note 419
-- Linoria fork glass/theme extension note 420
-- Linoria fork glass/theme extension note 421
-- Linoria fork glass/theme extension note 422
-- Linoria fork glass/theme extension note 423
-- Linoria fork glass/theme extension note 424
-- Linoria fork glass/theme extension note 425
-- Linoria fork glass/theme extension note 426
-- Linoria fork glass/theme extension note 427
-- Linoria fork glass/theme extension note 428
-- Linoria fork glass/theme extension note 429
-- Linoria fork glass/theme extension note 430
-- Linoria fork glass/theme extension note 431
-- Linoria fork glass/theme extension note 432
-- Linoria fork glass/theme extension note 433
-- Linoria fork glass/theme extension note 434
-- Linoria fork glass/theme extension note 435
-- Linoria fork glass/theme extension note 436
-- Linoria fork glass/theme extension note 437
-- Linoria fork glass/theme extension note 438
-- Linoria fork glass/theme extension note 439
-- Linoria fork glass/theme extension note 440
-- Linoria fork glass/theme extension note 441
-- Linoria fork glass/theme extension note 442
-- Linoria fork glass/theme extension note 443
-- Linoria fork glass/theme extension note 444
-- Linoria fork glass/theme extension note 445
-- Linoria fork glass/theme extension note 446
-- Linoria fork glass/theme extension note 447
-- Linoria fork glass/theme extension note 448
-- Linoria fork glass/theme extension note 449
-- Linoria fork glass/theme extension note 450
-- Linoria fork glass/theme extension note 451
-- Linoria fork glass/theme extension note 452
-- Linoria fork glass/theme extension note 453
-- Linoria fork glass/theme extension note 454
-- Linoria fork glass/theme extension note 455
-- Linoria fork glass/theme extension note 456
-- Linoria fork glass/theme extension note 457
-- Linoria fork glass/theme extension note 458
-- Linoria fork glass/theme extension note 459
-- Linoria fork glass/theme extension note 460
-- Linoria fork glass/theme extension note 461
-- Linoria fork glass/theme extension note 462
-- Linoria fork glass/theme extension note 463
-- Linoria fork glass/theme extension note 464
-- Linoria fork glass/theme extension note 465
-- Linoria fork glass/theme extension note 466
-- Linoria fork glass/theme extension note 467
-- Linoria fork glass/theme extension note 468
-- Linoria fork glass/theme extension note 469
-- Linoria fork glass/theme extension note 470
-- Linoria fork glass/theme extension note 471
-- Linoria fork glass/theme extension note 472
-- Linoria fork glass/theme extension note 473
-- Linoria fork glass/theme extension note 474
-- Linoria fork glass/theme extension note 475
-- Linoria fork glass/theme extension note 476
-- Linoria fork glass/theme extension note 477
-- Linoria fork glass/theme extension note 478
-- Linoria fork glass/theme extension note 479
-- Linoria fork glass/theme extension note 480
-- Linoria fork glass/theme extension note 481
-- Linoria fork glass/theme extension note 482
-- Linoria fork glass/theme extension note 483
-- Linoria fork glass/theme extension note 484
-- Linoria fork glass/theme extension note 485
-- Linoria fork glass/theme extension note 486
-- Linoria fork glass/theme extension note 487
-- Linoria fork glass/theme extension note 488
-- Linoria fork glass/theme extension note 489
-- Linoria fork glass/theme extension note 490
-- Linoria fork glass/theme extension note 491
-- Linoria fork glass/theme extension note 492
-- Linoria fork glass/theme extension note 493
-- Linoria fork glass/theme extension note 494
-- Linoria fork glass/theme extension note 495
-- Linoria fork glass/theme extension note 496
-- Linoria fork glass/theme extension note 497
-- Linoria fork glass/theme extension note 498
-- Linoria fork glass/theme extension note 499
-- Linoria fork glass/theme extension note 500
-- Linoria fork glass/theme extension note 501
-- Linoria fork glass/theme extension note 502
-- Linoria fork glass/theme extension note 503
-- Linoria fork glass/theme extension note 504
-- Linoria fork glass/theme extension note 505
-- Linoria fork glass/theme extension note 506
-- Linoria fork glass/theme extension note 507
-- Linoria fork glass/theme extension note 508
-- Linoria fork glass/theme extension note 509
-- Linoria fork glass/theme extension note 510
-- Linoria fork glass/theme extension note 511
-- Linoria fork glass/theme extension note 512
-- Linoria fork glass/theme extension note 513
-- Linoria fork glass/theme extension note 514
-- Linoria fork glass/theme extension note 515
-- Linoria fork glass/theme extension note 516
-- Linoria fork glass/theme extension note 517
-- Linoria fork glass/theme extension note 518
-- Linoria fork glass/theme extension note 519
-- Linoria fork glass/theme extension note 520
-- Linoria fork glass/theme extension note 521
-- Linoria fork glass/theme extension note 522
-- Linoria fork glass/theme extension note 523
-- Linoria fork glass/theme extension note 524
-- Linoria fork glass/theme extension note 525
-- Linoria fork glass/theme extension note 526
-- Linoria fork glass/theme extension note 527
-- Linoria fork glass/theme extension note 528
-- Linoria fork glass/theme extension note 529
-- Linoria fork glass/theme extension note 530
-- Linoria fork glass/theme extension note 531
-- Linoria fork glass/theme extension note 532
-- Linoria fork glass/theme extension note 533
-- Linoria fork glass/theme extension note 534
-- Linoria fork glass/theme extension note 535
-- Linoria fork glass/theme extension note 536
-- Linoria fork glass/theme extension note 537
-- Linoria fork glass/theme extension note 538
-- Linoria fork glass/theme extension note 539
-- Linoria fork glass/theme extension note 540
-- Linoria fork glass/theme extension note 541
-- Linoria fork glass/theme extension note 542
-- Linoria fork glass/theme extension note 543
-- Linoria fork glass/theme extension note 544
-- Linoria fork glass/theme extension note 545
-- Linoria fork glass/theme extension note 546
-- Linoria fork glass/theme extension note 547
-- Linoria fork glass/theme extension note 548
-- Linoria fork glass/theme extension note 549
-- Linoria fork glass/theme extension note 550
-- Linoria fork glass/theme extension note 551
-- Linoria fork glass/theme extension note 552
-- Linoria fork glass/theme extension note 553
-- Linoria fork glass/theme extension note 554
-- Linoria fork glass/theme extension note 555
-- Linoria fork glass/theme extension note 556
-- Linoria fork glass/theme extension note 557
-- Linoria fork glass/theme extension note 558
-- Linoria fork glass/theme extension note 559
-- Linoria fork glass/theme extension note 560
-- Linoria fork glass/theme extension note 561
-- Linoria fork glass/theme extension note 562
-- Linoria fork glass/theme extension note 563
-- Linoria fork glass/theme extension note 564
-- Linoria fork glass/theme extension note 565
-- Linoria fork glass/theme extension note 566
-- Linoria fork glass/theme extension note 567
-- Linoria fork glass/theme extension note 568
-- Linoria fork glass/theme extension note 569
-- Linoria fork glass/theme extension note 570
-- Linoria fork glass/theme extension note 571
-- Linoria fork glass/theme extension note 572
-- Linoria fork glass/theme extension note 573
-- Linoria fork glass/theme extension note 574
-- Linoria fork glass/theme extension note 575
-- Linoria fork glass/theme extension note 576
-- Linoria fork glass/theme extension note 577
-- Linoria fork glass/theme extension note 578
-- Linoria fork glass/theme extension note 579
-- Linoria fork glass/theme extension note 580
-- Linoria fork glass/theme extension note 581
-- Linoria fork glass/theme extension note 582
-- Linoria fork glass/theme extension note 583
-- Linoria fork glass/theme extension note 584
-- Linoria fork glass/theme extension note 585
-- Linoria fork glass/theme extension note 586
-- Linoria fork glass/theme extension note 587
-- Linoria fork glass/theme extension note 588
-- Linoria fork glass/theme extension note 589
-- Linoria fork glass/theme extension note 590
-- Linoria fork glass/theme extension note 591
-- Linoria fork glass/theme extension note 592
-- Linoria fork glass/theme extension note 593
-- Linoria fork glass/theme extension note 594
-- Linoria fork glass/theme extension note 595
-- Linoria fork glass/theme extension note 596
-- Linoria fork glass/theme extension note 597
-- Linoria fork glass/theme extension note 598
-- Linoria fork glass/theme extension note 599
-- Linoria fork glass/theme extension note 600
-- Linoria fork glass/theme extension note 601
-- Linoria fork glass/theme extension note 602
-- Linoria fork glass/theme extension note 603
-- Linoria fork glass/theme extension note 604
-- Linoria fork glass/theme extension note 605
-- Linoria fork glass/theme extension note 606
-- Linoria fork glass/theme extension note 607
-- Linoria fork glass/theme extension note 608
-- Linoria fork glass/theme extension note 609
-- Linoria fork glass/theme extension note 610
-- Linoria fork glass/theme extension note 611
-- Linoria fork glass/theme extension note 612
-- Linoria fork glass/theme extension note 613
-- Linoria fork glass/theme extension note 614
-- Linoria fork glass/theme extension note 615
-- Linoria fork glass/theme extension note 616
-- Linoria fork glass/theme extension note 617
-- Linoria fork glass/theme extension note 618
-- Linoria fork glass/theme extension note 619
-- Linoria fork glass/theme extension note 620
-- Linoria fork glass/theme extension note 621
-- Linoria fork glass/theme extension note 622
-- Linoria fork glass/theme extension note 623
-- Linoria fork glass/theme extension note 624
-- Linoria fork glass/theme extension note 625
-- Linoria fork glass/theme extension note 626
-- Linoria fork glass/theme extension note 627
-- Linoria fork glass/theme extension note 628
-- Linoria fork glass/theme extension note 629
-- Linoria fork glass/theme extension note 630
-- Linoria fork glass/theme extension note 631
-- Linoria fork glass/theme extension note 632
-- Linoria fork glass/theme extension note 633
-- Linoria fork glass/theme extension note 634
-- Linoria fork glass/theme extension note 635
-- Linoria fork glass/theme extension note 636
-- Linoria fork glass/theme extension note 637
-- Linoria fork glass/theme extension note 638
-- Linoria fork glass/theme extension note 639
-- Linoria fork glass/theme extension note 640
-- Linoria fork glass/theme extension note 641
-- Linoria fork glass/theme extension note 642
-- Linoria fork glass/theme extension note 643
-- Linoria fork glass/theme extension note 644
-- Linoria fork glass/theme extension note 645
-- Linoria fork glass/theme extension note 646
-- Linoria fork glass/theme extension note 647
-- Linoria fork glass/theme extension note 648
-- Linoria fork glass/theme extension note 649
-- Linoria fork glass/theme extension note 650
-- Linoria fork glass/theme extension note 651
-- Linoria fork glass/theme extension note 652
-- Linoria fork glass/theme extension note 653
-- Linoria fork glass/theme extension note 654
-- Linoria fork glass/theme extension note 655
-- Linoria fork glass/theme extension note 656
-- Linoria fork glass/theme extension note 657
-- Linoria fork glass/theme extension note 658
-- Linoria fork glass/theme extension note 659
-- Linoria fork glass/theme extension note 660
-- Linoria fork glass/theme extension note 661
-- Linoria fork glass/theme extension note 662
-- Linoria fork glass/theme extension note 663
-- Linoria fork glass/theme extension note 664
-- Linoria fork glass/theme extension note 665
-- Linoria fork glass/theme extension note 666
-- Linoria fork glass/theme extension note 667
-- Linoria fork glass/theme extension note 668
-- Linoria fork glass/theme extension note 669
-- Linoria fork glass/theme extension note 670
-- Linoria fork glass/theme extension note 671
-- Linoria fork glass/theme extension note 672
-- Linoria fork glass/theme extension note 673
-- Linoria fork glass/theme extension note 674
-- Linoria fork glass/theme extension note 675
-- Linoria fork glass/theme extension note 676
-- Linoria fork glass/theme extension note 677
-- Linoria fork glass/theme extension note 678
-- Linoria fork glass/theme extension note 679
-- Linoria fork glass/theme extension note 680
-- Linoria fork glass/theme extension note 681
-- Linoria fork glass/theme extension note 682
-- Linoria fork glass/theme extension note 683
-- Linoria fork glass/theme extension note 684
-- Linoria fork glass/theme extension note 685
-- Linoria fork glass/theme extension note 686
-- Linoria fork glass/theme extension note 687
-- Linoria fork glass/theme extension note 688
-- Linoria fork glass/theme extension note 689
-- Linoria fork glass/theme extension note 690
-- Linoria fork glass/theme extension note 691
-- Linoria fork glass/theme extension note 692
-- Linoria fork glass/theme extension note 693
-- Linoria fork glass/theme extension note 694
-- Linoria fork glass/theme extension note 695
-- Linoria fork glass/theme extension note 696
-- Linoria fork glass/theme extension note 697
-- Linoria fork glass/theme extension note 698
-- Linoria fork glass/theme extension note 699
-- Linoria fork glass/theme extension note 700
-- Linoria fork glass/theme extension note 701
-- Linoria fork glass/theme extension note 702
-- Linoria fork glass/theme extension note 703

-- Soft click / hover animation for options
function Library:PlayClickAnim(Frame)
    if not Frame or not Frame.Parent then return end
    pcall(function()
        local orig = Frame.Size
        local shrink = UDim2.new(orig.X.Scale, math.max(1, orig.X.Offset - 2), orig.Y.Scale, math.max(1, orig.Y.Offset - 1))
        local t1 = TweenService:Create(Frame, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = shrink })
        local t2 = TweenService:Create(Frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = orig })
        t1:Play()
        t1.Completed:Connect(function() t2:Play() end)
    end)
end

function Library:PlayToggleFlash(Frame, On)
    if not Frame then return end
    pcall(function()
        local target = On and Library.AccentColor or Library.MainColor
        TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = target;
        }):Play()
    end)
end


-- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. -- Linoria glass performance notes: cursor off by default, Heartbeat not RenderStepped, -- blur only on toggle, glass transparency static unless SetGlass called. 
getgenv().Library = Library
return Library