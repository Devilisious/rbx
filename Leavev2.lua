Material = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kinlei/MaterialLua/master/Module.lua"))()
local v32 = workspace:GetAttribute("DungeonSpawn"); -- Tower Spawn
getgenv().dungeonSetting = nil
getgenv().regularSetting = nil
local teleporter = require(game:GetService("ReplicatedStorage").ClientModules.Controllers.AfterLoad.TeleportController)
teleporter:Teleport({
    pos = v32, 
    areaName = nil, 
    regionName = "Dungeon", 
    leaveGamemode = true
})

local player = game.Players.LocalPlayer
local timer1 = game:GetService("Workspace").Resources.Gamemodes.DungeonLobby.Timers["Dungeon 1"].Timer.TextLabel
local timer2 = game:GetService("Workspace").Resources.Gamemodes.DungeonLobby.Timers["Dungeon 2"].Timer.TextLabel

local function createTextLabel(parent, position, text, size)
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = parent
    textLabel.Position = position
    textLabel.Size = UDim2.new(0, 100, 0, size)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextSize = 24
    textLabel.Text = text
    textLabel.TextStrokeTransparency = 0 -- set text stroke transparency to 0 to show border
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0) -- set text stroke color to black
	textLabel.TextStrokeTransparency = 0 -- set text stroke transparency to 0 to show border
    return textLabel
end

local function updateGui()
    local existingGui = player.PlayerGui:FindFirstChild("MyScreenGui")
    if existingGui then
        existingGui:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MyScreenGui"
    screenGui.Parent = player.PlayerGui

    local textLabel1 = createTextLabel(screenGui, UDim2.new(0.8, 0, 0, 0), "Dungeon 1/3: "..timer1.Text, 50)

    timer1:GetPropertyChangedSignal("Text"):Connect(function()
        textLabel1.Text = "Dungeon 1/3: "..timer1.Text
    end)
    
    local textLabel2 = createTextLabel(screenGui, UDim2.new(0.795, 0, 0, 30), "Dungeon 2: "..timer2.Text, 50)

    timer2:GetPropertyChangedSignal("Text"):Connect(function()
        textLabel2.Text = "Dungeon 2: "..timer2.Text
    end)
end

updateGui()

local playerName = game.Players.LocalPlayer.Name
local playerGui = game:GetService("Players")[playerName].PlayerGui
local background = playerGui.Dungeon:WaitForChild("Background")
local active = background:WaitForChild("Active")
local roomLabel = active:WaitForChild("RoomLabel")
roomLabel.Text = "NotStarted yet <3"

-- Create global values table
getgenv().values = {
    easyDungeon = 50,
    hardDungeon = 50,
    insaneDungeon = 50,
    tower = 50,
    Timer = 60,
}

local currentFloor = nil
local timer = nil

local function resetTimer()
    timer = os.clock()
end

local function printTextValue()
    local test = getgenv().values.tower
    if string.find(roomLabel.Text, "Floor 1") or string.find(roomLabel.Text, "Room 1") then
        if dungeonSetting ~= nil then
            game:GetService('ReplicatedStorage').Packages.Knit.Services.LoadoutService.RE.EquipLoadout:FireServer(dungeonSetting)
        end
    end
    if string.find(roomLabel.Text, "Floor") or string.find(roomLabel.Text, "Room") then
        local floor = tonumber(string.match(roomLabel.Text, "%d+"))
        if currentFloor ~= floor then
            currentFloor = floor
            resetTimer()
        end
        if timer ~= nil then  -- Check if timer is not nil
            local elapsedTime = os.clock() - timer
            if elapsedTime > getgenv().values.Timer then
                local teleporter = require(game:GetService("ReplicatedStorage").ClientModules.Controllers.AfterLoad.TeleportController)
                teleporter:TeleportArea('Area 1')
                timer = nil
                if regularSetting ~= nil then
                    game:GetService('ReplicatedStorage').Packages.Knit.Services.LoadoutService.RE.EquipLoadout:FireServer(regularSetting)
                end
            end
        end
    end
end


-- Create a global variable to keep track of whether the hook should be enabled
getgenv().isHookEnabled = true

-- Create a variable to store the connection between the signal and the function
local connection = nil
-- Default values

-- Create Material UI
local UI = Material.Load({
    Title = "Auto leave dungeon",
    Style = 1,
    SizeX = 400,
    SizeY = 375,
    Theme = "Dark"
})

-- Create settings panel
local settings = UI.New({
    Title = "Settings"
})
-- Add enable toggle
local enableToggle = settings.Toggle({
    Text = "Enable",
    Callback = function(value)
        getgenv().isHookEnabled = value
        if getgenv().isHookEnabled then
            -- If the hook is enabled and there is no existing connection, create a new one
            if not connection then
                connection = game:GetService("RunService").Heartbeat:Connect(function()
                    if getgenv().isHookEnabled then
                        printTextValue()
                    end
                end)
            end
        else
            -- If the hook is disabled and there is an existing connection, disconnect it
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end,
    Enabled = false
})
-- Add sliders for each dungeon type
for _, dungeonType in ipairs({"Timer"}) do
    settings.Slider({
        Text = "* Leave Time * Dungeons/Tower",
        Callback = function(value)
            getgenv().values[dungeonType] = value
        end,
        Min = 1,
        Max = 60,
        Def = 60
    })
end
local nameToUuid = {} -- mapping between names and UUIDs

local setDungeonLoadout = settings.Dropdown({
    Text = "Selected Dungeon/Tower Loadout",
    Options = {},
    Callback = function(value)
        dungeonSetting = nameToUuid[value]
    end,
})

local setRegularLoadout = settings.Dropdown({
    Text = "Selected Farming Loadout",
    Options = {},
    Callback = function(value)
        regularSetting = nameToUuid[value]
        
    end,
})
local function updateLoadouts()
  local path = "Players.".. playerName ..".PlayerGui.Loadouts.Background.ImageFrame.Window.Frames.ItemsFrame.ItemsHolder.Scroll"
  local obj = game

  for name in string.gmatch(path, "[%a_]+") do
      obj = obj[name]
  end

  local options = {}
  local children = obj:GetChildren()
  for i, child in ipairs(children) do
      local loadoutName = child:FindFirstChild("LoadoutName")
      if loadoutName then
          local name = loadoutName.Text
          local uuid = child.Name
          table.insert(options, name)
          nameToUuid[name] = uuid
      end
  end
  
  setRegularLoadout:SetOptions(options)
  setDungeonLoadout:SetOptions(options)
end
  local updateloadoutsbtn = settings.Button({
    Text = "Update Loadouts",
    Callback = function()
        updateLoadouts()
        print("Dungeon setting = " .. dungeonSetting .. " regular Setting = " .. regularSetting)
    end
})
updateLoadouts()
