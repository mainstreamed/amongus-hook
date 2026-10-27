
-- Development shims matching https://github.com/Luraph/macrosdk/blob/main/luraphsdk.lua.
if (not LPH_OBFUSCATED) then

      -- Callable Macros
      local passthrough = function<T>(value: T): T

            return value;
      end;

      LPH_ENCSTR = passthrough;
      LPH_STRENC = passthrough;
      LPH_ENCNUM = passthrough;
      LPH_NUMENC = passthrough;
      LPH_REWRITE = passthrough;
      LPH_ASSUME = passthrough;
      LPH_OPAQUE = passthrough;

      if (buffer) then
            local buffer_fromstring = buffer.fromstring;

            LPH_ENCBUF = function(value: string): buffer

                  return buffer_fromstring(value);
            end;
            LPH_BUFENC = function(value: string): buffer

                  return buffer_fromstring(value);
            end;
      end;

      LPH_CRASH = function()

      end;

      local table_unpack = table.unpack or unpack;
      local table_pack   = table.pack or function(...)

            return { n = select('#', ...); ... };
      end;

      local stackAllocation   = {};
      stackAllocation.__index = stackAllocation;

      function stackAllocation:clear(first: number?, last: number?)

            first = first or self.__base;
            last  = last or self.__end;

            for index = first, last do
                  self[index] = nil;
            end;
      end;

      function stackAllocation:unpack(first: number?, last: number?)

            first = first or self.__base;
            last  = last or self.__end;

            return table_unpack(self, first, last);
      end;

      function stackAllocation:pack(first: number?, last: number?)

            first = first or self.__base;
            last  = last or self.__end;

            return table_pack(table_unpack(self, first, last));
      end;

      stackAllocation.__len = function(self): number

            return self.__size;
      end;

      LPH_STACKALLOC = function(size: number, base: number?)

            base = base or 1;

            local allocation  = {};
            allocation.__size = size;
            allocation.__base = base;
            allocation.__end  = base + size - 1;

            return setmetatable(allocation, stackAllocation);
      end;

      LPH_PRECHECK = function(check: () -> any)

            check();
      end;

      -- Attributes And Options
      local attribute = function(...)

      end;

      LPH_ATTRIBUTES     = attribute;
      ENCRYPT            = attribute;
      VM                 = attribute;
      PRESET             = attribute;
      OPTIMIZE           = attribute;
      NO_UPVALUES        = attribute;
      ERROR_HANDLING     = attribute;
      UNSAFE_ENVIRONMENT = attribute;
      UNROLL             = attribute;
      INLINE             = attribute;
      TRANSFORM          = attribute;
      NONE               = attribute;
      OPAL               = attribute;
      ONYX               = attribute;
      FAST               = attribute;
      BALANCED           = attribute;
      SECURE             = attribute;
      EXTRACT            = attribute;
      CONTROL_FLOW       = attribute;
      REWRITE_NAMECALLS  = attribute;
      GLOBALS            = attribute;
      CONSTANTS          = attribute;
end;

-- Imports
local __IMPORTS = {};
return (function(...)
local __IMPORTS_1_REPO, __IMPORTS_1_LOBBY_IDS, __IMPORTS_1_GAME_IDS = (function()
      return 'https://raw.githubusercontent.com/mainstreamed/amongus-hook/main/fallensurvival', { 10228136016; }, ({ 13800717766; 15479377118; 16849012343; });
end)();
__IMPORTS[4] = (function()
      local select   = select;
      local rawlen   = rawlen;
      local typeof   = typeof;
      local tostring = tostring;
      
      local describeFlag = function(value: any): string
      
            local valueType = typeof(value);
      
            if (valueType == 'string' or valueType == 'number' or valueType == 'boolean') then
                  return tostring(value);
      
            elseif (valueType == 'table') then
                  return `table ({rawlen(value)})`;
            end;
            return valueType;
      end;
      local KickMessage = function(code: number, description: string, ...: any): string
      
            local message   = `amongus.hook error ({code})\n{description}`;
            local flagCount = select('#', ...);
      
            if (flagCount > 0) then
                  message ..= '\n';
            end;
      
            for idx = 1, flagCount do
                  message ..= `\nFlag({idx}): {describeFlag((select(idx, ...)))}`;
            end;
      
            return message;
      end;
      
      return KickMessage;
      
end)();
local __IMPORTS_3_kick = (function()
      local pcall       = pcall;
      local game        = game;
      local task_wait   = task.wait;
      
      local KickMessage = __IMPORTS[4];
      
      local selfKicked = false;
      
      local UpdateKickModal = function(reason: string?)
      
            local errorPrompt = (game:GetService('CoreGui') :: any).RobloxPromptGui.promptOverlay.ErrorPrompt;
      
            errorPrompt.MessageArea.ErrorFrame.ErrorMessage.Text  = reason or 'Internal Error';
            errorPrompt.TitleFrame.ErrorTitle.Text                = 'amongus.hook / Error';
      end;
      
      
      local UPDATE_KICK = Instance.new('BindableEvent');
      local SHUTDOWN    = Instance.new('BindableEvent');
      
      UPDATE_KICK.Event:Connect(function(...)
            pcall(UpdateKickModal, ...);
      end);
      SHUTDOWN.Event:Connect(function(...)
            game:Shutdown();
      end);
      
      local loopAllocated = 0;
      
      local kickPlayer = function(reason: string, override: boolean?)
      
            LPH_ATTRIBUTES(VM(NONE));
      
            if (selfKicked) then
                  return;
            end;
      
            local players = game:GetService('Players');
            
            if (not (players and players.LocalPlayer)) then
      
                  
                  SHUTDOWN:Fire();
                  return task_wait(9e9);
            end;
      
            players.LocalPlayer:Kick(reason);
            selfKicked = true;
      
            local allocated   = loopAllocated + 1;
            loopAllocated     = allocated;
      
            while (loopAllocated == allocated) do
      
                  UPDATE_KICK:Fire(reason);
                  task_wait(0.5);
            end;
            
            task_wait(9e9);
            return;
      end;
      
      -- Coded kick with a description and Flag(n) diagnostics (see kick-message.lua).
      
      return (kickPlayer);
      
end)();
local __IMPORTS_2_request = (function()
      
      local kickPlayer  = __IMPORTS_3_kick;
      local request     = request;
      
      local safeRequest = function(url: string)
      
            LPH_ATTRIBUTES( VM(NONE) );
      
            local success, response = pcall(request, {
                  Url    = url;
                  Method = 'GET';
            });
      
            if (not success) then
                  return kickPlayer(`request failed (0) {url}`);
      
            elseif (type(response) ~= 'table' or type(response.Body) ~= 'string' or response.StatusCode ~= 200) then
                  return kickPlayer(`request failed (1) {url}`);
            end;
      
            return response.Body;
      end;
      
      
      return (safeRequest);
      
end)();

-- Constants
local PRELOAD_NAME = 'preload.lua';

-- Helpers
local isInLobby = pcall(function()

      return (game:GetService('StarterGui') :: any).MainMenu.Main.ServerList;
end);

if (not isInLobby) then

      local INGAME_WARNING = 
            'Please inject from the lobby.\n\n' ..
            'Injecting while in-game is no longer supported.';

      local success = pcall(messagebox, INGAME_WARNING, 'amongus.hook', 48);

      if (not success) then
            return __IMPORTS_3_kick(INGAME_WARNING);
      end;
      return;
end;

local queueScript = function()

      local queueOnTeleport   = (queue_on_teleport or queueonteleport or queueteleport);

      if (type(queueOnTeleport) ~= 'function') then

            return __IMPORTS_3_kick(
                  'Your executor does not support queue_on_teleport.\n\n' ..
                  'Please use one of the supported executors.'
            );
      end;

      local preloadSource     = __IMPORTS_2_request(`{__IMPORTS_1_REPO}/{PRELOAD_NAME}`);
      local loadFunction, err = loadstring( preloadSource );

      if (type(loadFunction) ~= 'function') then

            return __IMPORTS_3_kick(
                  `Failed to load "{PRELOAD_NAME}";\n`..
                  `Syntax Error: {err}\n\n` ..
                  'DM mainstreamed with a screenshot.'
            );
      end;

      queueOnTeleport( string.format('loadstring(%q)();', preloadSource) );
      return;
end;

(function(...)
      local createDrawing = (function(...)
            
            local drawing_new  = Drawing.new;
            local table_insert = table.insert;
            
            local createDrawing = function(_type: string | () -> any, properties: { [string]: any }, ...: { any })
            
                  LPH_ATTRIBUTES(VM(NONE));
            
                  local drawing = if (type(_type) == 'function') then _type() else drawing_new(_type);
                  for property, value in properties do
                        drawing[property] = value;
                  end;
            
                  for _, _table in {...} do
                        table_insert(_table, drawing);
                  end;
            
                  return drawing;
            end;
            
            return createDrawing;
            
      end)();
      local RoundedSquare = (function(...)
            local drawing_new  = Drawing.new;
            local vector2      = Vector2.new;
            local table_insert = table.insert;
            
            local RoundedSquare = function()
            
                  LPH_ATTRIBUTES(VM(NONE));
            
                  local properties = {
                        Visible  = true;
                        Rounding = 0;
                        Size     = vector2(0, 0);
                        Color    = Color3.new(0, 0, 0);
                        Position = vector2(0, 0);
                        ZIndex   = 0;
                  };
            
                  local allDrawings  = {};
                  local middleFill   = drawing_new('Square');
                  local borderSquare = {
                        drawing_new('Square');
                        drawing_new('Square');
                        drawing_new('Square');
                        drawing_new('Square');
                  };
                  local borderRound  = {
                        drawing_new('Circle');
                        drawing_new('Circle');
                        drawing_new('Circle');
                        drawing_new('Circle');
                  };
            
                  table_insert(allDrawings, middleFill);
                  for i = 1, #borderRound do
                        borderRound[i].Radius    = properties.Rounding + 0.0001;
                        borderRound[i].Thickness = 1;
                        table_insert(allDrawings, borderRound[i]);
                  end;
                  for i = 1, #borderSquare do
                        table_insert(allDrawings, borderSquare[i]);
                  end;
            
                  for i = 1, #allDrawings do
                        local drawing = allDrawings[i];
                        drawing.Visible = properties.Visible;
                        drawing.Color   = properties.Color;
                        drawing.ZIndex  = properties.ZIndex;
                        drawing.Filled  = true;
                  end;
            
                  local updatePositions = function()
            
                        local position = properties.Position;
                        local size     = properties.Size;
                        local rounding = properties.Rounding;
            
                        -- Top / Bottom
                        local topSize = vector2(size.X - rounding * 2, rounding);
                        borderSquare[1].Size     = topSize;
                        borderSquare[2].Size     = topSize;
                        borderSquare[1].Position = vector2(position.X + rounding, position.Y);
                        borderSquare[2].Position = vector2(position.X + rounding, position.Y + size.Y - rounding);
            
                        -- Right / Left
                        local sideSize = vector2(rounding, size.Y - rounding * 2);
                        borderSquare[3].Size     = sideSize;
                        borderSquare[4].Size     = sideSize;
                        borderSquare[3].Position = vector2(position.X, position.Y + rounding);
                        borderSquare[4].Position = vector2(position.X + size.X - rounding, position.Y + rounding);
            
                        -- Corners
                        borderRound[1].Position = vector2(position.X + rounding, position.Y + rounding);
                        borderRound[2].Position = vector2(position.X + size.X - rounding, position.Y + rounding);
                        borderRound[3].Position = vector2(position.X + size.X - rounding, position.Y + size.Y - rounding);
                        borderRound[4].Position = vector2(position.X + rounding, position.Y + size.Y - rounding);
            
                        middleFill.Position = borderRound[1].Position;
                        middleFill.Size     = size - vector2(rounding * 2, rounding * 2);
            
                        for i = 1, #borderRound do
                              borderRound[i].Radius = rounding + 0.0001;
                        end;
                  end;
            
                  updatePositions();
            
                  local object   = newproxy(true);
                  local objectMT = getmetatable(object);
            
                  objectMT.__index = function(_, idx)
            
                        return properties[idx];
                  end;
                  objectMT.__newindex = function(_, idx, val)
            
            
                        if (properties[idx] == val) then
                              return;
                        end;
            
                        properties[idx] = val;
                        if (idx == 'Visible' or idx == 'ZIndex' or idx == 'Color') then
                              for i = 1, #allDrawings do
                                    allDrawings[i][idx] = val;
                              end;
            
                        elseif (idx == 'Rounding' or idx == 'Size' or idx == 'Position') then
                              updatePositions();
                        end;
                  end;
            
                  return object;
            end;
            
            return RoundedSquare;
            
      end)();
      
      local onLoad = ...;
      
      local userInputService = game:GetService('UserInputService');
      
      local COLORS = {
            border        = Color3.fromRGB(36, 36, 44);
            card          = Color3.fromRGB(17, 17, 22);
            text          = Color3.fromRGB(240, 240, 245);
            muted         = Color3.fromRGB(125, 125, 140);
            accent        = Color3.fromRGB(232, 65, 96);
            success       = Color3.fromRGB(80, 220, 130);
            button        = Color3.fromRGB(30, 30, 38);
            buttonHover   = Color3.fromRGB(40, 40, 50);
            buttonPressed = Color3.fromRGB(24, 24, 30);
            buttonBorder  = Color3.fromRGB(52, 52, 64);
      };
      
      local CARD_SIZE  = Vector2.new(260, 106);
      local TEXT_FONT  = Drawing.Fonts.UI;
      local TEXT_Z     = 6;
      local CHECK_SIZE = 8;
      local CHECK_GAP  = 6;
      
      local vector2    = Vector2.new;
      local math_floor = math.floor;
      local task_wait  = task.wait;
      
      -- Top-left as a screen fraction: right of Fallen's server list, over the tutorial panel
      local viewportSize = workspace.CurrentCamera.ViewportSize;
      local origin       = vector2(math_floor(viewportSize.X * 0.75), math_floor(viewportSize.Y * 0.41));
      
      -- Lines have From/To instead of Position, so they move separately
      local allDrawings = {};
      local allLines    = {};
      
      local roundedRect = function(position: Vector2, size: Vector2, radius: number, color: Color3, zIndex: number)
      
            return createDrawing(RoundedSquare, {
                  Position = position;
                  Size     = size;
                  Rounding = radius;
                  Color    = color;
                  ZIndex   = zIndex;
            }, allDrawings);
      end;
      
      local text = function(value: string, position: Vector2, size: number, color: Color3)
      
            return createDrawing('Text', {
                  Visible  = true;
                  Text     = value;
                  Position = position;
                  Size     = size;
                  Font     = TEXT_FONT;
                  Color    = color;
                  ZIndex   = TEXT_Z;
            }, allDrawings);
      end;
      
      local line = function(from: Vector2, to: Vector2)
      
            return createDrawing('Line', {
                  Visible   = true;
                  From      = from;
                  To        = to;
                  Color     = COLORS.text;
                  Thickness = 1.5;
                  ZIndex    = TEXT_Z;
            }, allLines);
      end;
      
      -- Card
      roundedRect(origin - Vector2.one, CARD_SIZE + vector2(2, 2), 11, COLORS.border, 1);
      roundedRect(origin, CARD_SIZE, 10, COLORS.card, 2);
      
      -- Header: "amongus" + accented ".hook"
      local brand = text('amongus', origin + vector2(16, 14), 17, COLORS.text);
      text('.hook', brand.Position + vector2(brand.TextBounds.X, 0), 17, COLORS.accent);
      
      -- Status Line
      local statusDot = createDrawing('Circle', {
            Visible  = true;
            Position = origin + vector2(19, 48);
            Radius   = 2.5;
            Filled   = true;
            Color    = COLORS.muted;
            ZIndex   = 4;
      }, allDrawings);
      local status = text('Ready to load', origin + vector2(27, 40), 12, COLORS.muted);
      
      -- Button
      local buttonPosition = origin + vector2(16, 66);
      local buttonSize     = vector2(CARD_SIZE.X - 32, 24);
      local buttonBorder   = roundedRect(buttonPosition - Vector2.one, buttonSize + vector2(2, 2), 6, COLORS.buttonBorder, 3);
      local buttonFill     = roundedRect(buttonPosition, buttonSize, 5, COLORS.button, 4);
      
      local label = createDrawing('Text', {
            Visible = true;
            Text    = 'Load amongus.hook';
            Size    = 13;
            Font    = TEXT_FONT;
            Color   = COLORS.text;
            Center  = true;
            ZIndex  = TEXT_Z;
      }, allDrawings);
      label.Position = buttonPosition + vector2(buttonSize.X / 2, (buttonSize.Y - label.TextBounds.Y) / 2);
      
      local isWithin = function(point: Vector2, position: Vector2, size: Vector2): boolean
      
            local offset = point - position;
            return offset.X >= 0 and offset.Y >= 0 and offset.X < size.X and offset.Y < size.Y;
      end;
      
      local moveBy = function(delta: Vector2)
      
            origin         += delta;
            buttonPosition += delta;
      
            for _, drawing in allDrawings do
                  drawing.Position += delta;
            end;
            for _, checkLine in allLines do
                  checkLine.From += delta;
                  checkLine.To   += delta;
            end;
      end;
      
      local setChecked = function()
      
            buttonFill.Color   = COLORS.accent;
            buttonBorder.Color = COLORS.accent;
            label.Text         = 'Queued';
            label.Center       = false;
      
            -- Centre the checkmark and label as one group
            local left   = buttonPosition.X + (buttonSize.X - CHECK_SIZE - CHECK_GAP - label.TextBounds.X) / 2;
            local middle = buttonPosition.Y + buttonSize.Y / 2;
            label.Position = vector2(left + CHECK_SIZE + CHECK_GAP, buttonPosition.Y + (buttonSize.Y - label.TextBounds.Y) / 2);
      
            local checkCorner = vector2(left + 3, middle + 3);
            line(vector2(left, middle), checkCorner);
            line(checkCorner, vector2(left + CHECK_SIZE, middle - 4));
      
            statusDot.Color = COLORS.success;
            status.Text     = 'Queued, join a server';
            status.Color    = COLORS.text;
      end;
      
      local queued, wasPressed, pressedOnButton = false, false, false;
      local dragFrom: Vector2? = nil;
      
      while (true) do
            local pressed  = userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1);
            local mouse    = userInputService:GetMouseLocation();
            local hovering = (not queued) and isWithin(mouse, buttonPosition, buttonSize);
      
            if (pressed and not wasPressed) then
                  pressedOnButton = hovering;
                  dragFrom        = if (not hovering and isWithin(mouse, origin, CARD_SIZE)) then mouse else nil;
      
            elseif (not pressed and wasPressed and pressedOnButton and hovering) then
                  queued = true;
                  onLoad();
                  setChecked();
            end;
      
            if (pressed and dragFrom) then
                  moveBy(mouse - dragFrom);
                  dragFrom = mouse;
            end;
      
            if (not queued) then
                  local fill = if (pressed and pressedOnButton and hovering) then COLORS.buttonPressed
                        elseif (hovering) then COLORS.buttonHover
                        else COLORS.button;
      
                  buttonFill.Color   = fill;
                  buttonBorder.Color = if (hovering) then COLORS.accent else COLORS.buttonBorder;
            end;
      
            wasPressed = pressed;
            task_wait();
      end;
      
end)(queueScript);
return;
end)(...)
