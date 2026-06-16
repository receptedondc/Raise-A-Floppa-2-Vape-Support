
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end
local run = function(func)
	func()
end
local queue_on_teleport = queue_on_teleport or function() end
local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local lightingService = cloneref(game:GetService('Lighting'))
local marketplaceService = cloneref(game:GetService('MarketplaceService'))
local teleportService = cloneref(game:GetService('TeleportService'))
local httpService = cloneref(game:GetService('HttpService'))
local guiService = cloneref(game:GetService('GuiService'))
local groupService = cloneref(game:GetService('GroupService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local contextService = cloneref(game:GetService('ContextActionService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local isnetworkowner = identifyexecutor and table.find({'AWP', 'Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local vape = shared.vape
local tween = vape.Libraries.tween
local targetinfo = vape.Libraries.targetinfo
local getfontsize = vape.Libraries.getfontsize
local getcustomasset = vape.Libraries.getcustomasset

local TargetStrafeVector, SpiderShift, WaypointFolder
local Spider = {Enabled = false}
local Phase = {Enabled = false}

local function addBlur(parent)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 89, 1, 52)
	blur.Position = UDim2.fromOffset(-48, -31)
	blur.BackgroundTransparency = 1
	blur.Image = getcustomasset('newvape/assets/new/blur.png')
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(52, 31, 261, 502)
	blur.Parent = parent
	return blur
end

local function calculateMoveVector(vec)
	local c, s
	local _, _, _, R00, R01, R02, _, _, R12, _, _, R22 = gameCamera.CFrame:GetComponents()
	if R12 < 1 and R12 > -1 then
		c = R22
		s = R02
	else
		c = R00
		s = -R01 * math.sign(R12)
	end
	vec = Vector3.new((c * vec.X + s * vec.Z), 0, (c * vec.Z - s * vec.X)) / math.sqrt(c * c + s * s)
	return vec.Unit == vec.Unit and vec.Unit or Vector3.zero
end

local function isFriend(plr, recolor)
	if vape.Categories.Friends.Options['Use friends'].Enabled then
		local friend = table.find(vape.Categories.Friends.ListEnabled, plr.Name) and true
		if recolor then
			friend = friend and vape.Categories.Friends.Options['Recolor visuals'].Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	return table.find(vape.Categories.Targets.ListEnabled, plr.Name) and true
end

local function canClick()
	local mousepos = (inputService:GetMouseLocation() - guiService:GetGuiInset())
	for _, v in lplr.PlayerGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
		local obj = v:FindFirstAncestorOfClass('ScreenGui')
		if v.Active and v.Visible and obj and obj.Enabled then
			return false
		end
	end
	for _, v in coreGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
		local obj = v:FindFirstAncestorOfClass('ScreenGui')
		if v.Active and v.Visible and obj and obj.Enabled then
			return false
		end
	end
	return (not vape.gui.ScaledGui.ClickGui.Visible) and (not inputService:GetFocusedTextBox())
end

local function getTableSize(tab)
	local ind = 0
	for _ in tab do ind += 1 end
	return ind
end

local function getTool()
	return lplr.Character and lplr.Character:FindFirstChildWhichIsA('Tool', true) or nil
end

local function notif(...)
	return vape:CreateNotification(...)
end

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return (str:gsub('<[^<>]->', ''))
end

local function rakNetCheck(module)
	if not (raknet and raknet.add_send_hook and pcall(raknet.add_send_hook, function() end)) then
		notif(module, 'This feature requires raknet! (risky feature, please do not use on mains.)', 10, 'warning')
		return false
	end

	return true
end

run(function()
    local AutoClickFloppa
    local connection

    AutoClickFloppa = vape.Categories.Utility:CreateModule({
        Name = 'AutoClickFloppa',
        Function = function(callback)
            if callback then
                connection = game:GetService("RunService").RenderStepped:Connect(function()
                    local floppa = workspace:FindFirstChild("Floppa")
                    if floppa and floppa:FindFirstChild("ClickDetector") then
                        fireclickdetector(floppa.ClickDetector)
                    end
                end)
            else
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
            end
        end,
        Tooltip = 'Automatically clicks Floppa.'
    })
end)

run(function()
    local AutoCash
    local connection

    AutoCash = vape.Categories.Utility:CreateModule({
        Name = "AutoCash",
        Function = function(callback)
            if callback then
                connection = game:GetService("RunService").Heartbeat:Connect(function()
                    local lp = game.Players.LocalPlayer
                    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end

                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("BasePart") and (v.Name == "Money" or v.Name == "Money Bag") then
                            v.CFrame = hrp.CFrame
                            v.CanCollide = false
                            v.Transparency = 1
                        end
                    end
                end)
            else
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
            end
        end,
        Tooltip = "Auto collects cash"
    })
end)

run(function()
    local Disabler
    local connection
    local poops = {}

    Disabler = vape.Categories.World:CreateModule({
        Name = "Disabler",
        Function = function(callback)
            if callback then
                for _, poop in pairs(workspace:GetChildren()) do
                    if poop.Name == "Poop" then
                        table.insert(poops, poop)
                    end
                end

                connection = workspace.ChildAdded:Connect(function(newPoop)
                    if newPoop.Name == "Poop" then
                        table.insert(poops, newPoop)
                    end
                end)

                game:GetService("RunService").RenderStepped:Connect(function()
                    for _, aPoop in pairs(poops) do
                        if not aPoop:GetAttribute("NoTrip") then
                            local tripPart = aPoop:FindFirstChild("PoopPart"):FindFirstChild("TouchInterest")
                            tripPart:Destroy()
                            aPoop:SetAttribute("NoTrip", true)
                        end
                    end
                end)
            else
                poops = {}

                if connection then
                    connection:Disconnect()
                    connection = nil
                end
            end
        end,
        Tooltip = "Prevents poop trip effects",
        ExtraText = function()
            return 'Trip'
        end
    })
end)

run(function()
    local AutoSave
    local connection

    local saveRemote = game:GetService("ReplicatedStorage")
        :WaitForChild("Events")
        :WaitForChild("Save")

    AutoSave = vape.Categories.Utility:CreateModule({
        Name = "AutoSave",
        Function = function(callback)
            if callback then
                connection = game:GetService("RunService").Heartbeat:Connect(function()
                    saveRemote:FireServer()
                end)
            else
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
            end
        end,
        Tooltip = "Automatically saves your progress"
    })
end)

run(function()
    local AutoFeedFloppa
    local connection
    local threshold = 50

    local unlockRemote = game:GetService("ReplicatedStorage")
        :WaitForChild("Events")
        :WaitForChild("Unlock")

    AutoFeedFloppa = vape.Categories.Utility:CreateModule({
        Name = "AutoFeedFloppa",
        Function = function(callback)
            if callback then
                connection = game:GetService("RunService").Heartbeat:Connect(function()
                    local lp = game.Players.LocalPlayer
                    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end

                    local floppa = workspace:FindFirstChild("Floppa")
                    if not floppa then return end

                    local hunger = floppa:FindFirstChild("Configuration")
                        and floppa.Configuration:FindFirstChild("Hunger")

                    if hunger and hunger.Value >= threshold then
                        local bowl = workspace:FindFirstChild("KeyParts")
                            and workspace.KeyParts:FindFirstChild("Bowl")

                        if bowl then
                            for _, v in pairs(bowl:GetDescendants()) do
                                if v:IsA("BasePart") then
                                    v.CFrame = hrp.CFrame
                                    v.CanCollide = false
                                end
                            end

                            unlockRemote:FireServer("Floppa Food", "the_interwebs")
                        end
                    end
                end)
            else
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
            end
        end,
        Tooltip = "Automatically feeds Floppa when hungry"
    })

    AutoFeedFloppa:CreateSlider({
        Name = "Threshold",
        Min = 0,
        Max = 100,
        Default = 50,
        Decimal = 1,
        Function = function(val)
            threshold = val
        end
    })
end)

run(function()
	local lp = game:GetService("Players").LocalPlayer
	local SeedAura
	local SeedRange

	local function getHRP()
		local char = lp.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function start()
		task.spawn(function()
			while SeedAura.Enabled do
				local root = getHRP()
				local seeds = workspace:FindFirstChild("Seeds")

				if root and seeds then
					for _, v in ipairs(seeds:GetChildren()) do
						if v:IsA("BasePart") then
							local prompt = v:FindFirstChildOfClass("ProximityPrompt")
							if prompt then
								if (v.Position - root.Position).Magnitude <= SeedRange.Value then
									fireproximityprompt(prompt)
								end
							end
						end
					end
				end

				task.wait(0.1)
			end
		end)
	end

	SeedAura = vape.Categories.World:CreateModule({
		Name = "SeedAura",
		Tooltip = "Auto collects nearby seeds",
		Function = function(callback)
			if callback then
				start()
			end
		end
	})

	SeedRange = SeedAura:CreateSlider({
		Name = "Range",
		Min = 1,
		Max = 10,
		Default = 5
	})
end)

run(function()
	local lp = game:GetService("Players").LocalPlayer
	local Sprint
	local SpeedSlider

	local function applySpeed()
		local char = lp.Character
		local humanoid = char and char:FindFirstChild("Humanoid")

		if humanoid then
			humanoid.WalkSpeed = Sprint.Enabled and SpeedSlider.Value or 16
		end
	end

	local function start()
		task.spawn(function()
			while Sprint.Enabled do
				applySpeed()
				task.wait(0.1)
			end
			applySpeed() -- reset when turned off
		end)
	end

	Sprint = vape.Categories.Blatant:CreateModule({
		Name = 'Sprint',
		Tooltip = 'Sets your walkspeed',
		Function = function(callback)
			if callback then
				start()
			else
				applySpeed()
			end
		end
	})

	SpeedSlider = Sprint:CreateSlider({
		Name = 'Speed',
		Min = 16,
		Max = 100,
		Default = 16,
	})
end)

run(function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local lp = Players.LocalPlayer
	local cookingEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Cooking")

	local function getHRP()
		local char = lp.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function getPart(obj)
		if not obj then return nil end

		if obj:IsA("Model") then
			return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
		elseif obj:IsA("BasePart") then
			return obj
		end

		return nil
	end

	local function tpTo(obj)
		local hrp = getHRP()
		local part = getPart(obj)

		if hrp and part then
			hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
			return true
		end
	end

	local function firePrompt(obj)
		local part = getPart(obj)
		local prompt = part and part:FindFirstChildWhichIsA("ProximityPrompt")

		if prompt then
			fireproximityprompt(prompt)
			return true
		end
	end

	local function fireAllPrompts(obj)
		local part = getPart(obj)
		if not part then return end

		for _, prompt in ipairs(part:GetDescendants()) do
			if prompt:IsA("ProximityPrompt") then
				fireproximityprompt(prompt)
				task.wait(0.1)
			end
		end
	end

	local function cook()
		cookingEvent:FireServer("Add Ingredient", "Cheese")
		task.wait(0.3)

		cookingEvent:FireServer("Add Ingredient", "Bread")
		task.wait(0.3)

		cookingEvent:FireServer("Change Temperature", 3)
		task.wait(0.3)

		cookingEvent:FireServer("Cook")
	end

	-- cached paths
	local village = workspace:WaitForChild("Village")
	local market = village:WaitForChild("FoodMarket")

	local breadCrate = market:WaitForChild("Bread Crate")
	local cheeseCrate = market:WaitForChild("Cheese")
	local stove = workspace:WaitForChild("Key Parts"):WaitForChild("Stove")
	local floppa = workspace:WaitForChild("Floppa")

	local AutoFeed

	AutoFeed = vape.Categories.World:CreateModule({
		Name = "AutoFeed",
		Tooltip = "Automatically feeds you by getting ingredients and cooking",
		ExtraText = function()
			return "Burger"
		end,

		Function = function(callback)
			if callback then
				task.spawn(function()
					while AutoFeed.Enabled do
						-- WAIT FOR GRILLED CHEESE TO EXIST BEFORE CONTINUING
						local grilledCheese = workspace:FindFirstChild("Grilled Cheese")
						while not grilledCheese and AutoFeed.Enabled do
							task.wait(0.5)
							grilledCheese = workspace:FindFirstChild("Grilled Cheese")
						end
						
						if not AutoFeed.Enabled then break end

						-- Get ingredients and cook
						tpTo(breadCrate)
						task.wait(0.4)
						firePrompt(breadCrate)

						task.wait(0.4)

						tpTo(cheeseCrate)
						task.wait(0.4)
						firePrompt(cheeseCrate)

						task.wait(0.4)

						tpTo(stove)
						task.wait(0.4)
						cook()

						task.wait(1)

						-- Pick up Grilled Cheese
						if grilledCheese then
							tpTo(grilledCheese)
							task.wait(0.3)
							firePrompt(grilledCheese)
						end

						-- Equip the tool
						local tool = lp.Backpack:FindFirstChild("Grilled Cheese") or lp.Character:FindFirstChild("Grilled Cheese")

						if tool and tool:IsA("Tool") and lp.Character then
							local humanoid = lp.Character:FindFirstChild("Humanoid")
							if humanoid then
								humanoid:EquipTool(tool)
							end
						end

						-- Teleport to Floppa and fire all prompts
						task.wait(0.3)
						tpTo(floppa)
						task.wait(0.3)
						fireAllPrompts(floppa)

						task.wait(1)
					end
				end)
			end
		end
	})
end)
run(function()
	local lp = game:GetService("Players").LocalPlayer
	local lighting = game:GetService("Lighting")
	local rs = game:GetService("ReplicatedStorage")
	local events = rs:WaitForChild("Events")

	local collectRentEvent = events:WaitForChild("Collect Rent")
	local raiseRentEvent = events:WaitForChild("Raise Rent")

	local collectRent2Event = events:WaitForChild("Collect Rent 2")
	local raiseRent2Event = events:WaitForChild("Raise Rent 2")

	local AutoRent
	local hasFired = false

	local function getHRP()
		local char = lp.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function getHour()
		return tonumber(string.split(lighting.TimeOfDay, ":")[1])
	end

	-- 🔥 decide mode once per tick
	local function useRent2()
		return workspace:FindFirstChild("Unlocks")
			and workspace.Unlocks:FindFirstChild("Rich Roommate")
	end

	-- 🔥 ALWAYS scanning rent
	local function pullRent()
		local root = getHRP()
		if not root then return end

		if useRent2() then
			local rent2 = workspace:FindFirstChild("Rent 2")
			if rent2 and rent2:IsA("BasePart") then
				rent2.CanCollide = false
				rent2.Transparency = 1
				rent2.CFrame = root.CFrame
			end
		else
			for _, v in ipairs(workspace:GetChildren()) do
				if v.Name == "Rent" and v:IsA("BasePart") then
					v.CanCollide = false
					v.Transparency = 1
					v.CFrame = root.CFrame
				end
			end
		end
	end

	local function start()
		task.spawn(function()
			while AutoRent.Enabled do
				pullRent()

				local hour = getHour()
				local rent2 = useRent2()

				if hour == 12 and not hasFired then

					if rent2 then
						collectRent2Event:FireServer()
						task.wait(0.1)
						raiseRent2Event:FireServer()
					else
						collectRentEvent:FireServer()
						task.wait(0.1)
						raiseRentEvent:FireServer()
					end

					hasFired = true
				end

				if hour ~= 12 then
					hasFired = false
				end

				task.wait(0.1)
			end
		end)
	end

	AutoRent = vape.Categories.World:CreateModule({
		Name = "AutoRent",
		Tooltip = "Constant rent pickup + auto collect",
		Function = function(callback)
			if callback then
				hasFired = false
				start()
			end
		end
	})
end)

run(function()
	local lp = game:GetService("Players").LocalPlayer

	--// =======================
	--// EXIT HIGHLIGHTER (RENDER)
	--// =======================

	local highlightFolder = Instance.new("Folder")
	highlightFolder.Name = "ExitHighlights"
	highlightFolder.Parent = workspace
	
	local connection
	
	local function clearHighlights()
		for _, highlight in ipairs(highlightFolder:GetChildren()) do
			highlight:Destroy()
		end
	end
	
	local function resetExitAttributes()
		local backrooms = workspace:FindFirstChild("Backrooms")
		if not backrooms then return end
		
		local rooms = backrooms:FindFirstChild("Rooms")
		if not rooms then return end
		
		local function reset(parent)
			for _, child in ipairs(parent:GetChildren()) do
				if child:IsA("Model") and child.Name == "Exit" then
					child:SetAttribute("Highlighted", nil)
				end
				reset(child)
			end
		end
		
		reset(rooms)
	end
	
	local function highlightExits()
		clearHighlights()
		
		local backrooms = workspace:FindFirstChild("Backrooms")
		if not backrooms then return end
		
		local rooms = backrooms:FindFirstChild("Rooms")
		if not rooms then return end
		
		local function search(parent)
			for _, child in ipairs(parent:GetChildren()) do
				if child:IsA("Model") and child.Name == "Exit" and not child:GetAttribute("Highlighted") then
					local h = Instance.new("Highlight")
					h.FillColor = Color3.fromRGB(0, 0, 255)
					h.FillTransparency = 0.5
					h.OutlineColor = Color3.fromRGB(0, 0, 255)
					h.OutlineTransparency = 0.3
					h.Adornee = child
					h.Parent = highlightFolder
					
					child:SetAttribute("Highlighted", true)
				end
				search(child)
			end
		end
		
		search(rooms)
	end
	
	local ExitHighlighter = vape.Categories.Render:CreateModule({
		Name = "ExitHighlighter",
		Tooltip = "Highlights all Exit models",
		Function = function(callback)
			if callback then
				highlightExits()
				
				local rooms = workspace:FindFirstChild("Backrooms") and workspace.Backrooms:FindFirstChild("Rooms")
				if rooms then
					connection = rooms.DescendantAdded:Connect(function(desc)
						if ExitHighlighter.Enabled then
							if desc:IsA("Model") and desc.Name == "Exit" and not desc:GetAttribute("Highlighted") then
								task.wait(0.1)
								highlightExits()
							end
						end
					end)
				end
			else
				if connection then
					connection:Disconnect()
					connection = nil
				end
				
				clearHighlights()
				resetExitAttributes()
			end
		end,
		ExtraText = function()
			return "Backrooms"
		end
	})

	--// =======================
	--// AUTO EXIT (UTILITIES)
	--// =======================

	local AutoExit
	local RangeSlider

	local function getHRP()
		local char = lp.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function startAutoExit()
		task.spawn(function()
			while AutoExit.Enabled do
				local root = getHRP()
				local backrooms = workspace:FindFirstChild("Backrooms")

				if root and backrooms then
					for _, v in ipairs(backrooms:GetDescendants()) do
						if v:IsA("Model") and v.Name == "Exit" then
							local frame = v:FindFirstChild("Frame")
							local prompt = frame and frame:FindFirstChild("ProximityPrompt")

							if prompt and frame:IsA("BasePart") then
								local dist = (frame.Position - root.Position).Magnitude
								if dist <= RangeSlider.Value then
									fireproximityprompt(prompt)
								end
							end
						end
					end
				end

				task.wait(0.1)
			end
		end)
	end

	AutoExit = vape.Categories.Utility:CreateModule({
		Name = "AutoExit",
		Tooltip = "Auto uses nearby exits",
		Function = function(callback)
			if callback then
				startAutoExit()
			end
		end,
		ExtraText = function()
			return "Backrooms"
		end
	})

	RangeSlider = AutoExit:CreateSlider({
		Name = "Range",
		Min = 1,
		Max = 10,
		Default = 5
	})
end)

run(function()
	local Players = game:GetService("Players")
	local lp = Players.LocalPlayer

	local function getHRP()
		local char = lp.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function findTouchPart(tool)
		for _, descendant in ipairs(tool:GetDescendants()) do
			if descendant:IsA("TouchTransmitter") then
				local part = descendant.Parent
				if part and part:IsA("BasePart") then
					return part
				end
			end
		end
		return nil
	end

	local function pickupTool(tool)
		local hrp = getHRP()
		if not hrp then return end

		local part = findTouchPart(tool)
		if not part then return end

		pcall(function()
			for _, d in ipairs(tool:GetDescendants()) do
				if d:IsA("BasePart") then
					d.CanCollide = false
					d.AssemblyLinearVelocity = Vector3.zero
					d.AssemblyAngularVelocity = Vector3.zero
				end
			end

			tool:PivotTo(CFrame.new(hrp.Position))
		end)
	end

	local AutoPickup

	AutoPickup = vape.Categories.Utility:CreateModule({
		Name = "AutoPickup",

		Function = function(callback)
			if callback then
				task.spawn(function()
					while AutoPickup and AutoPickup.Enabled do
						task.wait(0.1)

						local hrp = getHRP()
						if not hrp then continue end

						for _, obj in ipairs(workspace:GetChildren()) do
							if obj:IsA("Tool") then
								pickupTool(obj)
							end
						end
					end
				end)
			end
		end, -- 🔥 THIS COMMA WAS MISSING

		ExtraText = function()
			return "Tools"
		end
	})
end)

run(function()
	local Players = game:GetService("Players")
	local lp = Players.LocalPlayer

	local TARGET_GEMS = {
		Sapphire = true,
		Diamond = true,
		Ruby = true,
		Emerald = true
	}

	local function getHRP()
		local char = lp.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function isGem(obj)
		return obj:IsA("MeshPart") and TARGET_GEMS[obj.Name]
	end

	local function pickup(obj)
		local hrp = getHRP()
		if not hrp then return end

		pcall(function()
			obj.CanCollide = false
			obj.AssemblyLinearVelocity = Vector3.zero
			obj.AssemblyAngularVelocity = Vector3.zero
			obj.CFrame = CFrame.new(hrp.Position)
		end)
	end

	local AutoGem

	AutoGem = vape.Categories.Utility:CreateModule({
		Name = "AutoGem",
		Tooltip = "Automatically collects gems",

		Function = function(callback)
			if callback then
				task.spawn(function()
					while AutoGem and AutoGem.Enabled do
						task.wait(0.1)

						for _, obj in ipairs(workspace:GetChildren()) do
							if isGem(obj) then
								pickup(obj)
							end
						end
					end
				end)
			end
		end,

		ExtraText = function()
			return "Pickup"
		end
	})
end)

run(function()
	local Players = game:GetService("Players")
	local lp = Players.LocalPlayer

	local water = workspace:WaitForChild("Water For Fishies")

	local function getRod()
		local char = lp.Character
		return char and char:FindFirstChild("Fishing Rod")
	end

	local function getHook(rod)
		return rod and rod:FindFirstChild("Hook")
	end

	local function getSparkles(hook)
		return hook and hook:FindFirstChild("Sparkles")
	end

	local function aimingAtWater()
		local mouse = lp:GetMouse()
		return mouse and mouse.Target == water
	end

	local AutoFish

	AutoFish = vape.Categories.Utility:CreateModule({
		Name = "AutoFish",

		Function = function(callback)
			if not callback then return end

			task.spawn(function()
				while AutoFish and AutoFish.Enabled do
					task.wait(0.1)

					-- 🎣 must have rod to even start a cycle
					local rod = getRod()
					if not rod then
						continue
					end

					local hook = getHook(rod)
					if not hook then
						continue
					end

					local sparkles = getSparkles(hook)
					if not sparkles then
						continue
					end

					-- 🎯 START CYCLE ONLY IF AIMING AT WATER
					if not aimingAtWater() then
						continue
					end

					-- =========================
					-- 🎣 CAST (ONCE PER CYCLE)
					-- =========================
					pcall(function()
						rod:Activate()
					end)

					-- cycle state
					local cycleActive = true
					local validWaterTarget = true

					-- =========================
					-- 🔁 REEL LOOP
					-- =========================
					while AutoFish and AutoFish.Enabled and cycleActive do

						-- ❌ rod unequipped → hard stop
						if not getRod() then
							cycleActive = false
							break
						end

						-- ❌ if user leaves water → finish cycle but DO NOT restart immediately
						if not aimingAtWater() then
							validWaterTarget = false
							cycleActive = false
							break
						end

						local hook2 = getHook(rod)
						local sparkles2 = hook2 and getSparkles(hook2)

						if not sparkles2 then
							cycleActive = false
							break
						end

						-- ✨ fish ready → reel loop
						if sparkles2.Enabled then
							pcall(function()
								rod:Activate()
								task.wait(0.1)
								rod:Activate()
							end)
						else
							task.wait(0.1)
						end
					end

					-- =========================
					-- 🧠 POST-CYCLE RULE
					-- =========================

					-- if cycle ended due to NOT aiming at water → wait until fully reset
					if not validWaterTarget then
						while AutoFish and AutoFish.Enabled do
							task.wait(0.2)

							-- only restart when rod exists AND player is aiming again
							if getRod() and aimingAtWater() then
								break
							end
						end
					end
				end
			end)
		end
	})
end)

run(function()
	local lp = game:GetService("Players").LocalPlayer

	local floppa = workspace:WaitForChild("Floppa")
	local wormholeMachine = workspace.Unlocks:FindFirstChild("Wormhole Machine")

	local mode = "Pet"

	local canRun = true
	local triggered = false

	local function getHRP()
		local char = lp.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function getPart(obj)
		if obj:IsA("Model") then
			return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
		elseif obj:IsA("BasePart") then
			return obj
		end
	end

	local function tpTo(obj)
		local hrp = getHRP()
		local part = getPart(obj)
		if hrp and part then
			hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
		end
	end

	local function firePrompts(obj)
		for _, d in ipairs(obj:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				pcall(function()
					fireproximityprompt(d)
				end)
			end
		end
	end

	local function getHappiness()
		local config = floppa:FindFirstChild("Toggles")
			and floppa.Toggles:FindFirstChild("Configuration")

		if not config then return 100 end

		local val = config:FindFirstChild("Happiness")
		if val and val:IsA("NumberValue") then
			return val.Value
		end

		return 100
	end

	local function doPet()
		tpTo(floppa)
		task.wait(0.2)
		firePrompts(floppa)
	end

	local function getCrystal()
		local c = wormholeMachine:FindFirstChild("Crystal")
		return c and c:FindFirstChild("Crystal")
	end

	local function getConverter()
		local u = workspace:FindFirstChild("Unlocks")
		return u and u:FindFirstChild("Crystal Converter")
	end

	local function doCrystal()
		local hrp = getHRP()
		if not hrp then return end

		local original = hrp.CFrame

		local crystal = getCrystal()
		if crystal then
			tpTo(crystal)
			task.wait(0.2)
			firePrompts(crystal)
		end

		local converter = getConverter()
		if converter then
			tpTo(converter)
			task.wait(0.2)
			firePrompts(converter)
		end

		task.wait(0.2)
		hrp.CFrame = original
	end

	local KeepHappy

	KeepHappy = vape.Categories.World:CreateModule({
		Name = "KeepHappy",

		Function = function(callback)
			if callback then
				task.spawn(function()

					while KeepHappy and KeepHappy.Enabled do
						task.wait(0.3)

						local threshold = ThresholdSlider and ThresholdSlider.Value or 100
						local happiness = getHappiness()

						-- 🔁 reset cycle ONLY when we leave low state
						if happiness > threshold then
							triggered = false
						end

						-- 🚫 already fired for this low cycle
						if triggered then
							continue
						end

						-- ❌ must be low AND allowed
						if happiness <= threshold and canRun then
							triggered = true

							if mode == "Pet" then
								doPet()

							elseif mode == "Space Crystal" then
								doCrystal()

							elseif mode == "Space Crystal + Pet" then
								doPet()
								task.wait(0.3)
								doCrystal()
							end

							-- 🔁 POST ACTION RULE (your 75 system)
							canRun = (getHappiness() >= 75)
						end
					end
				end)
			else
				triggered = false
				canRun = true
			end
		end,

		ExtraText = function()
			return mode
		end
	})

	local ModeDropdown = KeepHappy:CreateDropdown({
		Name = "Mode",
		List = {"Pet", "Space Crystal", "Space Crystal + Pet"},
		Function = function(v)
			mode = v
		end
	})

	local ThresholdSlider = KeepHappy:CreateSlider({
		Name = "Happiness Threshold",
		Min = 1,
		Max = 150,
		Default = 100
	})
end)

run(function()
	local lp = game:GetService("Players").LocalPlayer

	local EggAura
	local range = 5

	local function getHRP()
		local char = lp.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function getEgg()
		local au2 = workspace:FindFirstChild("AU2")
		if not au2 then return end

		local nest = au2:FindFirstChild("Dragon Nest")
		if not nest then return end

		return nest:FindFirstChild("Lava Egg")
	end

	local function firePrompt(obj)
		for _, d in ipairs(obj:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				fireproximityprompt(d)
			end
		end
	end

	EggAura = vape.Categories.World:CreateModule({
		Name = "EggAura",
		Tooltip = "Dragon",

		Function = function(callback)
			if callback then
				task.spawn(function()
					while EggAura and EggAura.Enabled do
						task.wait(0.15)

						local hrp = getHRP()
						local egg = getEgg()

						if hrp and egg and egg:IsA("BasePart") then
							local dist = (hrp.Position - egg.Position).Magnitude

							if dist <= range then
								firePrompt(egg)
							end
						end
					end
				end)
			end
		end,

		ExtraText = function()
			return "Dragon"
		end
	})

	EggAura:CreateSlider({
		Name = "Range",
		Min = 1,
		Max = 10,
		Default = 5,
		Function = function(v)
			range = v
		end
	})
end)

run(function()
	local rs = game:GetService("ReplicatedStorage")
	local events = rs:WaitForChild("Events")

	local spinEvent = events:WaitForChild("Slots Spin")
	local spinEvent2 = events:WaitForChild("Slots Spin2")

	local AutoGamble
	local NotifyBroken
	local NotifyFixed

	local delayTime = 10

	local selectedRegular = 1
	local selectedSuper = 1

	local disableRegular = false
	local disableSuper = false

	local lastRegular = nil
	local lastSuper = nil

	-- 💰 Regular
	local options = {
		{Value = 500000000000000, Text = "$5Q", Pos = 1},
		{Value = 2500000000000000, Text = "$25Q", Pos = 2},
		{Value = 5000000000000000, Text = "$50Q", Pos = 3},
		{Value = 10000000000000000, Text = "$100Q", Pos = 4},
		{Value = 25000000000000000, Text = "$250Q", Pos = 5},
		{Value = 50000000000000000, Text = "$500Q", Pos = 6},
	}

	-- 🟡 Super
	local goldOptions = {
		{Value = 1, Text = "1 Gold", Pos = 1},
		{Value = 3, Text = "3 Gold", Pos = 2},
		{Value = 10, Text = "10 Gold", Pos = 3},
	}

	-- 🔍 Machine check
	local function checkMachine()
		local unlocks = workspace:FindFirstChild("Unlocks")
		if not unlocks then return end

		-- Regular
		local reg = unlocks:FindFirstChild("Floppa Slots")
		if reg then
			local machine = reg:FindFirstChild("Machine")
			local sparks = machine and machine:FindFirstChild("Sparks")
			local isBroken = sparks and sparks.Enabled

			if lastRegular == nil then
				lastRegular = isBroken
			elseif isBroken ~= lastRegular then
				lastRegular = isBroken

				if isBroken then
					if NotifyBroken and NotifyBroken.Enabled then
						vape:CreateNotification("Broken", "Floppa Slots are now Down.", 30, "alert")
					end
				else
					if NotifyFixed and NotifyFixed.Enabled then
						vape:CreateNotification("Fixed", "Floppa Slots are now Working.", 30)
					end
				end
			end
		end

		-- Super
		local sup = unlocks:FindFirstChild("Super Floppa Slots")
		if sup then
			local machine = sup:FindFirstChild("Machine")
			local sparks = machine and machine:FindFirstChild("Sparks")
			local isBroken = sparks and sparks.Enabled

			if lastSuper == nil then
				lastSuper = isBroken
			elseif isBroken ~= lastSuper then
				lastSuper = isBroken

				if isBroken then
					if NotifyBroken and NotifyBroken.Enabled then
						vape:CreateNotification("Broken", "Super Floppa Slots are now Down.", 30, "alert")
					end
				else
					if NotifyFixed and NotifyFixed.Enabled then
						vape:CreateNotification("Fixed", "Super Floppa Slots are now Working.", 30)
					end
				end
			end
		end
	end

	AutoGamble = vape.Categories.World:CreateModule({
		Name = "AutoGamble",
		Tooltip = "Runs both slot machines",

		Function = function(callback)
			if callback then
				task.spawn(function()
					while AutoGamble and AutoGamble.Enabled do
						task.wait(delayTime)

						checkMachine()

						-- 🔁 Regular
						if not disableRegular then
							pcall(function()
								spinEvent:FireServer(options[selectedRegular])
							end)
						end

						-- 🔁 Super
						if not disableSuper then
							pcall(function()
								spinEvent2:FireServer(goldOptions[selectedSuper])
							end)
						end
					end
				end)
			end
		end,

		ExtraText = function()
			local texts = {}

			if not disableRegular then
				table.insert(texts, options[selectedRegular].Text)
			end

			if not disableSuper then
				table.insert(texts, goldOptions[selectedSuper].Text)
			end

			return #texts > 0 and table.concat(texts, ", ") or "Disabled"
		end
	})

	-- 🎯 Regular dropdown
	AutoGamble:CreateDropdown({
		Name = "Regular Amount",
		List = {"5Q", "25Q", "50Q", "100Q", "250Q", "500Q"},
		Function = function(val)
			for i, v in ipairs(options) do
				if v.Text:find(val) then
					selectedRegular = i
					break
				end
			end
		end
	})

	-- 🎯 Super dropdown
	AutoGamble:CreateDropdown({
		Name = "Super Amount",
		List = {"1 Gold", "3 Gold", "10 Gold"},
		Function = function(val)
			for i, v in ipairs(goldOptions) do
				if v.Text == val then
					selectedSuper = i
					break
				end
			end
		end
	})

	-- ⛔ Disable Regular
	AutoGamble:CreateToggle({
		Name = "Disable Regular Floppa Slots",
		Function = function(val)
			disableRegular = val
		end
	})

	-- ⛔ Disable Super
	AutoGamble:CreateToggle({
		Name = "Disable Super Floppa Slots",
		Function = function(val)
			disableSuper = val
		end
	})

	-- ⏱ Delay
	AutoGamble:CreateSlider({
		Name = "Delay (Seconds)",
		Min = 1,
		Max = 120,
		Default = 10,
		Function = function(val)
			delayTime = val
		end
	})

	-- 🔔 Notifications
	NotifyBroken = AutoGamble:CreateToggle({
		Name = "Notify when Broken",
		Function = function() end
	})

	NotifyFixed = AutoGamble:CreateToggle({
		Name = "Notify when Fixed",
		Function = function() end
	})
end)

run(function()
	local Players = game:GetService("Players")
	local lp = Players.LocalPlayer

	local function getHRP()
		local char = lp.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function pickupGold(part)
		local hrp = getHRP()
		if not hrp then return end

		pcall(function()
			part.Transparency = 1
			part.CanCollide = false
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
			part.CFrame = hrp.CFrame
		end)
	end

	local AutoGold

	AutoGold = vape.Categories.Utility:CreateModule({
		Name = "AutoGold",

		Function = function(callback)
			if callback then
				task.spawn(function()
					while AutoGold and AutoGold.Enabled do
						task.wait(0.1)

						local hrp = getHRP()
						if not hrp then continue end

						-- 🔍 Scan everything
						for _, obj in ipairs(workspace:GetDescendants()) do
							-- 🟡 Normal Gold
							if obj:IsA("MeshPart") and obj.Name == "Gold" then
								pickupGold(obj)
							end

							-- 💎 Divine Gold Bar
							if obj.Name == "Gold Bar" and obj:IsA("BasePart") then
								local parent = obj.Parent
								if parent and parent.Name == "Divine Gold" then
									pickupGold(obj)
								end
							end
						end
					end
				end)
			end
		end,

		ExtraText = function()
			return "Pickup"
		end
	})
end)

run(function()
    local rs = game:GetService("ReplicatedStorage")
    local events = rs:WaitForChild("Events")
    local mailEvent = events:WaitForChild("Mail")

    local AutoMail
    local mode = "All"

    local function getMailbox()
        local unlocks = workspace:FindFirstChild("Unlocks")
        if not unlocks then return end

        local mailbox = unlocks:FindFirstChild("Mailbox")
        if not mailbox then return end

        local box = mailbox:FindFirstChild("Box")
        if not box then return end

        local sparks = box:FindFirstChild("Sparkles")
        if not sparks then return end

        return box, sparks
    end

    local function colorMatch(color, target)
        return color and color == target
    end

    AutoMail = vape.Categories.World:CreateModule({
        Name = "AutoMail",

        Function = function(callback)
            if callback then
                task.spawn(function()
                    while AutoMail and AutoMail.Enabled do
                        task.wait(0.5)

                        local box, sparks = getMailbox()
                        if not box or not sparks then continue end

                        if not sparks.Enabled then continue end

                        local color = sparks.SparkleColor

                        -- 🎯 ALL
                        if mode == "All" then
                            if color == Color3.fromRGB(170, 0, 255)
                            or color == Color3.fromRGB(255, 170, 0) then
                                mailEvent:FireServer()
                            end
                        end

                        -- 💰 CASH
                        if mode == "Cash" then
                            if color == Color3.fromRGB(255, 170, 0) then
                                mailEvent:FireServer()
                            end
                        end

                        -- 📝 TEXT
                        if mode == "Text" then
                            if color == Color3.fromRGB(170, 0, 255) then
                                mailEvent:FireServer()
                            end
                        end
                    end
                end)
            end
        end,

        ExtraText = function()
            return mode
        end
    })

    AutoMail:CreateDropdown({
        Name = "Mode",
        List = {"All", "Text", "Cash"},
        Function = function(v)
            mode = v
        end
    })
end)
