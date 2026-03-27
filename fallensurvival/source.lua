--[[
	amongus.hook - Fallen Survival
	Clean source rewrite
]]

-- Services
local Players           = game:GetService('Players');
local RunService        = game:GetService('RunService');
local UserInputService  = game:GetService('UserInputService');
local Lighting          = game:GetService('Lighting');
local LocalPlayer       = Players.LocalPlayer;
local Camera            = workspace.CurrentCamera;
local Mouse             = LocalPlayer:GetMouse();

-- Libraries
local GITHUB_REPO = 'https://raw.githubusercontent.com/mainstreamed/amongus-hook/refs/heads/main/';

local function fetch(path)
	local response = request({Url = GITHUB_REPO .. path; Method = 'GET'});
	return response.Body;
end;

loadstring(fetch('assets/drawingSetup.lua'))();
local espLib = loadstring(fetch('assets/fallen/espLibrary.lua'))();
local uiLib  = loadstring(fetch('assets/uiLibrary.lua'))();

local playerESP = espLib.playerESP;
local entityESP = espLib.entityESP;
local npcESP    = espLib.npcESP;

-- Constants
local STAFF_GROUP_ID = 1154360;
local STAFF_MIN_RANK = 15;

local CONFIG_FOLDER = 'amghook\\fallen';

-- State
local state = {
	silent          = {};
	mousePos        = Vector2.new(0, 0);
	toolInfo        = nil;
	scanOrigin      = nil;
	fireRemote      = nil;
	connection      = nil;
	staffList       = {};
};

-- Drawings for aimbot
local aimDrawings = {
	fov = Drawing.new('Circle');
	snapline = Drawing.new('Line');
	hitscanIndicator = Drawing.new('Circle');
	manipulationIndicator = Drawing.new('Circle');
};
aimDrawings.fov.Thickness = 1;
aimDrawings.fov.Filled = false;
aimDrawings.fov.Color = Color3.new(1, 1, 1);
aimDrawings.fov.NumSides = 64;
aimDrawings.fov.Visible = false;

aimDrawings.snapline.Thickness = 1;
aimDrawings.snapline.Color = Color3.new(1, 1, 1);
aimDrawings.snapline.Visible = false;

aimDrawings.hitscanIndicator.Thickness = 1;
aimDrawings.hitscanIndicator.Filled = true;
aimDrawings.hitscanIndicator.Radius = 3;
aimDrawings.hitscanIndicator.Color = Color3.new(1, 0, 0);
aimDrawings.hitscanIndicator.Visible = false;

aimDrawings.manipulationIndicator.Thickness = 1;
aimDrawings.manipulationIndicator.Filled = true;
aimDrawings.manipulationIndicator.Radius = 3;
aimDrawings.manipulationIndicator.Color = Color3.new(0, 1, 0);
aimDrawings.manipulationIndicator.Visible = false;


-- ============================================
-- UI SETUP
-- ============================================
local window, flags = uiLib.windowClass.new({
	title = 'amongus.hook - Fallen Survival';
});

-- Tabs
local combatTab   = window:addTab('Combat');
local visualsTab  = window:addTab('Visuals');
local playerTab   = window:addTab('Player');
local miscTab     = window:addTab('Misc');

-- Combat Tab (Left)
local silentAimToggle = combatTab:addToggle({text = 'Silent Aim'; flag = 'silentAim_toggle'}, 1);
silentAimToggle:addKeypicker({flag = 'silentAim_keybind'; default = 'None'});

combatTab:addSlider({text = 'FOV Size'; min = 10; max = 500; default = 150; flag = 'silentAim_FOVSize'}, 1);
combatTab:addDropdown({text = 'Hit Part'; options = {'Head', 'Torso', 'closest'}; default = 'Torso'; flag = 'silentAim_hitpart'}, 1);
combatTab:addToggle({text = 'Visible Check'; flag = 'silentAim_visibleCheck'; default = true}, 1);
combatTab:addToggle({text = 'Team Check'; flag = 'silentAim_teamCheck'}, 1);
combatTab:addToggle({text = 'Dynamic FOV'; flag = 'silentAim_dynamicFOV'}, 1);
combatTab:addToggle({text = 'Auto Shoot'; flag = 'silentAim_autoShoot'}, 1);
combatTab:addToggle({text = 'Snapline'; flag = 'silentAim_snapline'}, 1);
combatTab:addToggle({text = 'Target NPCs'; flag = 'silentAim_targetNPCs'}, 1);

-- Combat Tab (Right)
combatTab:addToggle({text = 'Hitscan'; flag = 'silentAim_hitscan'}, 2);
combatTab:addToggle({text = 'Hitscan Indicator'; flag = 'silentAim_hitscanIndicator'}, 2);
combatTab:addToggle({text = 'Instant Hit'; flag = 'silentAim_instantHit'}, 2);
combatTab:addToggle({text = 'Manipulation'; flag = 'silentAim_manipulation'}, 2);
combatTab:addToggle({text = 'Manipulation Indicator'; flag = 'silentAim_manipulationIndicator'}, 2);
combatTab:addSlider({text = 'Spread %'; min = 0; max = 100; default = 100; flag = 'spreadPercentage'}, 2);
combatTab:addSlider({text = 'Recoil %'; min = 0; max = 100; default = 100; flag = 'recoilPercentage'}, 2);
combatTab:addToggle({text = 'Always Shoot'; flag = 'alwaysShoot_toggle'; risky = true}, 2);
combatTab:addToggle({text = 'Combat Mode'; flag = 'combatMode_toggle'}, 2);

-- Visuals Tab (Left) - Player ESP
local espToggle = visualsTab:addToggle({text = 'Player ESP'; flag = 'playerESP_toggle'; default = true}, 1);
espToggle:addColourpicker({flag = 'playerESP_box_colour'; default = Color3.new(1, 1, 1)});
visualsTab:addToggle({text = 'ESP Names'; flag = 'playerESP_name'; default = true}, 1);
visualsTab:addToggle({text = 'ESP Distance'; flag = 'playerESP_distance'; default = true}, 1);
visualsTab:addToggle({text = 'ESP Health'; flag = 'playerESP_healthbar'; default = true}, 1);
visualsTab:addToggle({text = 'ESP Weapon'; flag = 'playerESP_weapon'; default = true}, 1);

local chamsToggle = visualsTab:addToggle({text = 'Local Chams'; flag = 'localChams_toggle'}, 1);
chamsToggle:addColourpicker({flag = 'localChams_colour'; default = Color3.new(1, 0, 1)});
visualsTab:addDropdown({text = 'Chams Material'; options = {'Neon', 'ForceField', 'Glass', 'SmoothPlastic'}; default = 'Neon'; flag = 'localChams_material'}, 1);
visualsTab:addSlider({text = 'Chams Transparency'; min = 0; max = 100; default = 50; flag = 'localChams_transparency'}, 1);

-- Visuals Tab (Right) - World ESP
visualsTab:addToggle({text = 'NPC ESP'; flag = 'npcESP_toggle'}, 2);
visualsTab:addToggle({text = 'Resource ESP'; flag = 'entityESP_toggle'}, 2);
visualsTab:addToggle({text = 'Airdrop ESP'; flag = 'airdropESP_toggle'}, 2);
visualsTab:addToggle({text = 'Animal ESP'; flag = 'animalESP_toggle'}, 2);
visualsTab:addToggle({text = 'X-Ray'; flag = 'xray_toggle'}, 2);
visualsTab:addToggle({text = 'Fullbright'; flag = 'fullbrightToggle'}, 2);
visualsTab:addToggle({text = 'FOV Changer'; flag = 'fovChanger_toggle'}, 2);
visualsTab:addSlider({text = 'FOV Amount'; min = 30; max = 120; default = 70; flag = 'fovChanger_amount'}, 2);

-- Player Tab (Left)
playerTab:addToggle({text = 'Speed Hack'; flag = 'speedHack_toggle'; risky = true}, 1);
playerTab:addSlider({text = 'Speed Amount'; min = 16; max = 100; default = 24; flag = 'speedHack_amount'}, 1);
playerTab:addToggle({text = 'Fly'; flag = 'fly_toggle'; risky = true}, 1);
playerTab:addSlider({text = 'Fly Speed'; min = 10; max = 200; default = 50; flag = 'fly_speed'}, 1);
playerTab:addToggle({text = 'No Fall Damage'; flag = 'noFallDamage_toggle'}, 1);
playerTab:addToggle({text = 'Silent Walk'; flag = 'silentWalk_toggle'}, 1);

-- Player Tab (Right)
local zoomToggle = playerTab:addToggle({text = 'Zoom'; flag = 'zoom_toggle'}, 2);
zoomToggle:addKeypicker({flag = 'zoom_keybind'; default = 'None'; mode = 'hold'});
playerTab:addSlider({text = 'Zoom Amount'; min = 5; max = 70; default = 20; flag = 'zoom_amount'}, 2);
playerTab:addToggle({text = 'Instant Equip'; flag = 'instantEquip_toggle'}, 2);
playerTab:addToggle({text = 'Instant Loot'; flag = 'instantLoot_toggle'}, 2);
playerTab:addToggle({text = 'Increase Melee Range'; flag = 'increaseMeleeRange_toggle'}, 2);
playerTab:addSlider({text = 'Melee Range'; min = 1; max = 20; default = 5; flag = 'increaseMeleeRange_amount'}, 2);
playerTab:addToggle({text = 'Increase Melee Speed'; flag = 'increaseMeleeSpeed_toggle'}, 2);
playerTab:addSlider({text = 'Melee Speed'; min = 1; max = 10; default = 2; flag = 'increaseMeleeSpeed_amount'}, 2);

-- Misc Tab (Left)
miscTab:addToggle({text = 'Staff Detector'; flag = 'staffDetectorToggle'; default = true}, 1);
miscTab:addToggle({text = 'Disable Traps'; flag = 'disableTraps_toggle'}, 1);
miscTab:addToggle({text = 'Disable Spikes'; flag = 'disableSpikes_toggle'}, 1);

-- Misc Tab (Right) - Config
miscTab:addDropdown({text = 'Config'; options = {'config1', 'config2', 'config3'}; default = 'config1'; flag = 'configName'}, 2);
miscTab:addButton('Save Config', function()
	saveConfig();
end, 2);
miscTab:addButton('Load Config', function()
	loadConfig();
end, 2);


-- ============================================
-- GAME HOOKS
-- ============================================

-- Find fireRemote and weapon functions via getgc
local function setupGameHooks()
	if (not getgc) then return; end;

	local gcObjects = getgc(true);
	for _, obj in gcObjects do
		if (type(obj) ~= 'function') then continue; end;

		local info = debug.info(obj, 's');
		if (type(info) ~= 'string') then continue; end;

		if (string.find(info, 'ViewmodelController')) then
			local upvalues = debug.getupvalues(obj);
			local constants = debug.getconstants(obj);

			-- Find fireRemote from AssetContainer functions
			if (not state.fireRemote) then
				for _, uv in upvalues do
					if (type(uv) == 'function') then
						local uvInfo = debug.info(uv, 's');
						if (type(uvInfo) == 'string' and string.find(uvInfo, 'AssetContainer')) then
							state.fireRemote = uv;
							break;
						end;
					end;
				end;
			end;

			-- Find mouseButton1Down handler
			if (table.find(constants, 'DebugEnableVMMovement')) then
				local hookTarget = upvalues[5];
				if (type(hookTarget) == 'function') then
					local hookInfo = debug.info(hookTarget, 's');
					if (type(hookInfo) == 'string' and string.find(hookInfo, 'ViewmodelController')) then
						state.mouseButton1DownFunc = hookTarget;
					end;
				end;
			end;
		end;
	end;
end;

task.spawn(setupGameHooks);


-- ============================================
-- STAFF DETECTOR
-- ============================================

local function checkStaff(player)
	if (not flags.staffDetectorToggle or not flags.staffDetectorToggle.value) then return; end;
	if (not player or not player.Parent) then return; end;

	local success, rank = pcall(player.GetRankInGroup, player, STAFF_GROUP_ID);
	if (success and rank >= STAFF_MIN_RANK) then
		if (not table.find(state.staffList, player)) then
			table.insert(state.staffList, player);
			window:notify(string.format('Staff Detector: %s has joined your game!', player.DisplayName), 5);
		end;
	end;
end;

local function onStaffLeft(player)
	local idx = table.find(state.staffList, player);
	if (idx) then
		table.remove(state.staffList, idx);
		window:notify(string.format('Staff Detector: %s has left your game!', player.DisplayName), 5);
	end;
end;


-- ============================================
-- ESP SETUP
-- ============================================

-- Player ESP
local function setupPlayerESP()
	for _, player in Players:GetPlayers() do
		if (player ~= LocalPlayer) then
			playerESP.new(player);
			task.spawn(checkStaff, player);
		end;
	end;

	Players.PlayerAdded:Connect(function(player)
		playerESP.new(player);
		task.spawn(checkStaff, player);
	end);

	Players.PlayerRemoving:Connect(function(player)
		playerESP.remove(player);
		onStaffLeft(player);
	end);
end;

-- Entity/NPC ESP (scan workspace folders)
local function classifyModel(model)
	if (model.ClassName ~= 'Model') then return nil; end;
	local name = model.Name;

	-- NPCs
	if (name == 'Soldier' or name == 'Bruno' or name == 'Boris' or name == 'Brutus') then
		return 'npc', name;
	end;

	-- Animals
	if (string.find(name, 'PREFAB_ANIMAL_DEER')) then return 'animal', 'deer'; end;
	if (string.find(name, 'PREFAB_ANIMAL_WOLF')) then return 'animal', 'wolf'; end;
	if (string.find(name, 'PREFAB_ANIMAL_WILDBOAR')) then return 'animal', 'boar'; end;
	if (name == 'bradley' or name == 'scav') then return 'npc', name; end;

	-- Resources
	if (string.find(name, 'Phosphate_Node')) then return 'resource', 'phosphate'; end;
	if (string.find(name, 'Metal_Node')) then return 'resource', 'metal'; end;
	if (string.find(name, 'Stone_Node')) then return 'resource', 'stone'; end;
	if (string.find(name, 'Hemp')) then return 'resource', 'hemp'; end;

	-- Containers
	if (string.find(name, 'airdrop') or string.find(name, 'Care Package')) then return 'airdrop', 'airdrop'; end;

	return nil;
end;

local function scanWorkspace()
	for _, folder in workspace:GetChildren() do
		if (folder.ClassName ~= 'Folder') then continue; end;

		local function processChild(child)
			local category, name = classifyModel(child);
			if (not category) then return; end;

			if (category == 'npc') then
				npcESP.new(child, name, name, Color3.new(1, 0.3, 0.3));
			elseif (category == 'animal') then
				npcESP.new(child, name, name, Color3.new(0.8, 0.5, 0.2));
			elseif (category == 'resource') then
				entityESP.new(child, name, name, Color3.new(0.5, 1, 0.5));
			elseif (category == 'airdrop') then
				entityESP.new(child, name, 'airdrop', Color3.new(1, 1, 0));
			end;
		end;

		for _, descendant in folder:GetDescendants() do
			processChild(descendant);
		end;

		folder.DescendantAdded:Connect(processChild);
	end;
end;

task.spawn(setupPlayerESP);
task.spawn(scanWorkspace);


-- ============================================
-- SILENT AIM
-- ============================================

local function getClosestTarget()
	if (not flags.silentAim_toggle.value) then
		state.silent = {};
		return;
	end;

	local best = {distance = flags.silentAim_FOVSize.value};
	local hitpart = flags.silentAim_hitpart.value;
	local visCheck = flags.silentAim_visibleCheck.value;
	local teamCheck = flags.silentAim_teamCheck.value;

	-- Players
	for player, espData in playerESP.playerCache do
		if (not player.Parent) then continue; end;
		if (not espData.current or not espData.current.active) then continue; end;

		local rootPart = espData.current.rootPart;
		local humanoid = espData.current.humanoid;
		local character = espData.current.character;
		if (not rootPart or not humanoid or humanoid.Health <= 0) then continue; end;

		local targetPos;
		if (hitpart == 'Head') then
			local head = character:FindFirstChild('Head');
			targetPos = head and head.Position or rootPart.Position;
		elseif (hitpart == 'Torso') then
			targetPos = rootPart.Position;
		else -- closest
			targetPos = rootPart.Position;
		end;

		-- Use rebuilt position if available (desync resolution)
		if (espData.current.rebuiltPos) then
			targetPos = espData.current.rebuiltPos;
		end;

		local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos);
		if (not onScreen) then continue; end;

		local screenVec = Vector2.new(screenPos.X, screenPos.Y);
		local dist = (screenVec - state.mousePos).Magnitude;

		if (dist > best.distance) then continue; end;

		-- Visible check
		if (visCheck) then
			local origin = Camera.CFrame.Position;
			local params = RaycastParams.new();
			params.FilterType = Enum.RaycastFilterType.Exclude;
			params.FilterDescendantsInstances = {LocalPlayer.Character, character};
			local result = workspace:Raycast(origin, targetPos - origin, params);
			if (result) then continue; end;
		end;

		best = {
			distance = dist;
			player = player;
			character = character;
			vector3 = targetPos;
			vector2 = screenVec;
			humanoid = humanoid;
			rootPart = rootPart;
		};
	end;

	-- NPCs
	if (flags.silentAim_targetNPCs.value) then
		for entity, espData in npcESP.npcCache do
			if (not entity.Parent) then continue; end;
			local rootPart = entity:FindFirstChild('HumanoidRootPart');
			local humanoid = entity:FindFirstChild('Humanoid');
			if (not rootPart or not humanoid or humanoid.Health <= 0) then continue; end;

			local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position);
			if (not onScreen) then continue; end;

			local screenVec = Vector2.new(screenPos.X, screenPos.Y);
			local dist = (screenVec - state.mousePos).Magnitude;

			if (dist < best.distance) then
				best = {
					distance = dist;
					character = entity;
					vector3 = rootPart.Position;
					vector2 = screenVec;
					humanoid = humanoid;
					rootPart = rootPart;
				};
			end;
		end;
	end;

	state.silent = best;
end;


-- ============================================
-- LOCAL CHAMS
-- ============================================

local chamsHighlight = nil;

local function updateChams()
	local character = LocalPlayer.Character;
	if (not character) then return; end;

	if (flags.localChams_toggle.value) then
		if (not chamsHighlight or chamsHighlight.Parent ~= character) then
			if (chamsHighlight) then chamsHighlight:Destroy(); end;
			chamsHighlight = Instance.new('Highlight');
			chamsHighlight.Parent = character;
		end;
		chamsHighlight.FillColor = flags.localChams_colour.value;
		chamsHighlight.FillTransparency = flags.localChams_transparency.value / 100;
		chamsHighlight.OutlineTransparency = 1;
	elseif (chamsHighlight) then
		chamsHighlight:Destroy();
		chamsHighlight = nil;
	end;
end;


-- ============================================
-- X-RAY
-- ============================================

local originalTransparencies = {};

local function toggleXray(enabled)
	if (enabled) then
		for _, obj in workspace:GetDescendants() do
			if (obj:IsA('BasePart') and not obj:IsDescendantOf(LocalPlayer.Character or game)) then
				if (obj.Transparency < 0.5) then
					originalTransparencies[obj] = obj.Transparency;
					obj.Transparency = 0.7;
				end;
			end;
		end;
	else
		for obj, transparency in originalTransparencies do
			if (obj.Parent) then
				obj.Transparency = transparency;
			end;
		end;
		originalTransparencies = {};
	end;
end;

flags.xray_toggle:OnChanged(function(value)
	toggleXray(value);
end);


-- ============================================
-- FULLBRIGHT
-- ============================================

local originalLighting = {};

local function toggleFullbright(enabled)
	if (enabled) then
		originalLighting.Ambient = Lighting.Ambient;
		originalLighting.FogEnd = Lighting.FogEnd;
		Lighting.Ambient = Color3.new(1, 1, 1);
		Lighting.FogEnd = 100000;
	else
		if (originalLighting.Ambient) then
			Lighting.Ambient = originalLighting.Ambient;
			Lighting.FogEnd = originalLighting.FogEnd;
		end;
	end;
end;

flags.fullbrightToggle:OnChanged(function(value)
	toggleFullbright(value);
end);


-- ============================================
-- SPEED HACK
-- ============================================

local function applySpeedHack()
	if (not flags.speedHack_toggle.value) then return; end;
	local character = LocalPlayer.Character;
	if (not character) then return; end;
	local rootPart = character:FindFirstChild('HumanoidRootPart');
	local humanoid = character:FindFirstChild('Humanoid');
	if (not rootPart or not humanoid) then return; end;

	local moveDir = humanoid.MoveDirection;
	local speed = flags.speedHack_amount.value;
	rootPart.Velocity = Vector3.new(moveDir.X * speed, rootPart.Velocity.Y, moveDir.Z * speed);
end;


-- ============================================
-- FLY
-- ============================================

local function applyFly()
	if (not flags.fly_toggle.value) then return; end;
	local character = LocalPlayer.Character;
	if (not character) then return; end;
	local rootPart = character:FindFirstChild('HumanoidRootPart');
	if (not rootPart) then return; end;

	local speed = flags.fly_speed.value;
	local camCF = Camera.CFrame;
	local moveDir = Vector3.new(0, 0, 0);

	if (UserInputService:IsKeyDown(Enum.KeyCode.W)) then moveDir += camCF.LookVector; end;
	if (UserInputService:IsKeyDown(Enum.KeyCode.S)) then moveDir -= camCF.LookVector; end;
	if (UserInputService:IsKeyDown(Enum.KeyCode.D)) then moveDir += camCF.RightVector; end;
	if (UserInputService:IsKeyDown(Enum.KeyCode.A)) then moveDir -= camCF.RightVector; end;
	if (UserInputService:IsKeyDown(Enum.KeyCode.Space)) then moveDir += Vector3.new(0, 1, 0); end;
	if (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)) then moveDir -= Vector3.new(0, 1, 0); end;

	if (moveDir.Magnitude > 0) then
		moveDir = moveDir.Unit;
	end;

	rootPart.Anchored = true;
	rootPart.CFrame = rootPart.CFrame + (moveDir * speed * 0.016);
end;


-- ============================================
-- CONFIG SAVE / LOAD
-- ============================================

function saveConfig()
	local configName = flags.configName.value;
	local path = CONFIG_FOLDER .. '\\configs\\' .. configName;

	if (not isfolder(CONFIG_FOLDER)) then makefolder(CONFIG_FOLDER); end;
	if (not isfolder(CONFIG_FOLDER .. '\\configs')) then makefolder(CONFIG_FOLDER .. '\\configs'); end;

	local data = {};
	for name, flag in window.flags do
		if (name == 'configName') then continue; end;
		local entry = {type = flag.type; value = flag.value};
		if (flag.type == 'keypicker') then
			entry.key = flag.key;
		elseif (flag.type == 'colourpicker') then
			local c = flag.value;
			entry.value = {c.R, c.G, c.B};
		end;
		data[name] = entry;
	end;

	local success, json = pcall(game.GetService, game, 'HttpService');
	if (success) then
		writefile(path, json:JSONEncode(data));
		window:notify('Config saved!', 3);
	end;
end;

function loadConfig()
	local configName = flags.configName.value;
	local path = CONFIG_FOLDER .. '\\configs\\' .. configName;

	if (not isfile(path)) then
		window:notify('Config not found!', 3);
		return;
	end;

	local success, json = pcall(game.GetService, game, 'HttpService');
	if (not success) then return; end;

	local ok, data = pcall(json.JSONDecode, json, readfile(path));
	if (not ok or type(data) ~= 'table') then
		window:notify('Config corrupted!', 3);
		return;
	end;

	for name, entry in data do
		local flag = window.flags[name];
		if (not flag or not entry.type or entry.type ~= flag.type) then continue; end;

		local value = entry.value;
		if (flag.type == 'colourpicker' and type(value) == 'table') then
			value = Color3.new(value[1], value[2], value[3]);
		end;

		flag.self.setValue(value, entry.key);
	end;

	window:notify('Config loaded!', 3);
end;


-- ============================================
-- MAIN RENDER LOOP
-- ============================================

RunService.Heartbeat:Connect(function()
	local character = LocalPlayer.Character;
	local rootPart = character and character:FindFirstChild('HumanoidRootPart');
	local humanoid = character and character:FindFirstChild('Humanoid');

	-- Update mouse position
	state.mousePos = UserInputService:GetMouseLocation();

	-- FOV Circle
	if (flags.silentAim_toggle.value) then
		aimDrawings.fov.Visible = true;
		aimDrawings.fov.Position = state.mousePos;
		aimDrawings.fov.Radius = flags.silentAim_FOVSize.value;
	else
		aimDrawings.fov.Visible = false;
	end;

	-- Silent aim targeting
	getClosestTarget();

	-- Snapline
	if (flags.silentAim_snapline.value and state.silent.vector2) then
		aimDrawings.snapline.Visible = true;
		aimDrawings.snapline.From = state.mousePos;
		aimDrawings.snapline.To = state.silent.vector2;
	else
		aimDrawings.snapline.Visible = false;
	end;

	-- Hitscan indicator
	if (flags.silentAim_hitscanIndicator.value and state.silent.hitscanPosition) then
		local pos, onScreen = Camera:WorldToViewportPoint(state.silent.hitscanPosition);
		aimDrawings.hitscanIndicator.Visible = onScreen;
		aimDrawings.hitscanIndicator.Position = Vector2.new(pos.X, pos.Y);
	else
		aimDrawings.hitscanIndicator.Visible = false;
	end;

	-- Player ESP rendering
	if (flags.playerESP_toggle.value and rootPart) then
		local espSettings = {
			box       = true;
			name      = flags.playerESP_name.value;
			distance  = flags.playerESP_distance.value;
			healthbar = flags.playerESP_healthbar.value;
			weapon    = flags.playerESP_weapon.value;
		};
		for player, espData in playerESP.playerCache do
			if (espData.current and espData.current.active) then
				local dist = (espData.current.rootPart.Position - rootPart.Position).Magnitude;
				espData:loop(espSettings, dist);
			else
				espData:hideDrawings();
			end;
		end;
	else
		for _, espData in playerESP.playerCache do
			espData:hideDrawings();
		end;
	end;

	-- NPC ESP rendering
	if (flags.npcESP_toggle.value and rootPart) then
		local npcSettings = {box = true; name = true; distance = true; healthbar = true};
		for entity, espData in npcESP.npcCache do
			if (entity.Parent) then
				local entryRoot = entity:FindFirstChild('HumanoidRootPart');
				local dist = entryRoot and (entryRoot.Position - rootPart.Position).Magnitude or 9999;
				espData:loop(npcSettings, dist);
			else
				espData:hideDrawings();
				npcESP.npcCache[entity] = nil;
			end;
		end;
	else
		for _, espData in npcESP.npcCache do espData:hideDrawings(); end;
	end;

	-- Entity ESP rendering
	if (rootPart) then
		local showResources = flags.entityESP_toggle.value;
		local showAirdrops = flags.airdropESP_toggle.value;
		local showAnimals = flags.animalESP_toggle.value;
		local entitySettings = {box = true; name = true; distance = true};

		for entity, espData in entityESP.entityCache do
			if (not entity.Parent) then
				espData:hideDrawings();
				entityESP.entityCache[entity] = nil;
				continue;
			end;

			local show = false;
			local sn = espData.settingName;
			if (sn == 'airdrop' and showAirdrops) then show = true;
			elseif ((sn == 'phosphate' or sn == 'metal' or sn == 'stone' or sn == 'hemp') and showResources) then show = true;
			elseif ((sn == 'deer' or sn == 'wolf' or sn == 'boar') and showAnimals) then show = true;
			end;

			if (show) then
				local entryRoot = entity:FindFirstChild('HumanoidRootPart') or entity.PrimaryPart;
				local dist = entryRoot and (entryRoot.Position - rootPart.Position).Magnitude or 9999;
				espData:loop(entitySettings, dist);
			else
				espData:hideDrawings();
			end;
		end;
	end;

	-- FOV Changer
	if (flags.fovChanger_toggle.value) then
		Camera.FieldOfView = flags.fovChanger_amount.value;
	end;

	-- Zoom
	if (flags.zoom_toggle.value and flags.zoom_keybind.value) then
		Camera.FieldOfView = flags.zoom_amount.value;
	end;

	-- Speed Hack
	applySpeedHack();

	-- Fly
	applyFly();

	-- Local Chams
	updateChams();
end);

-- Disable traps
if (flags.disableTraps_toggle) then
	flags.disableTraps_toggle:OnChanged(function(value)
		for _, obj in workspace:GetDescendants() do
			if (obj.Name == 'TouchCollision' or obj.Name == 'CactusPart') then
				obj.CanTouch = not value;
			end;
		end;
	end);
end;

-- Staff check existing players on load
for _, player in Players:GetPlayers() do
	if (player ~= LocalPlayer) then
		task.spawn(checkStaff, player);
	end;
end;

window:notify('amongus.hook loaded!', 5);
