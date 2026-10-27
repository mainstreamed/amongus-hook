
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
local __IMPORTS_2_hold, __IMPORTS_2_release = (function()
      -- Imports
      
      -- Helpers
      local GetService = function(name: string)
      
            local success, service = pcall(game.GetService, game, name);
      
            if (not success) then
                  return nil;
            end;
            return service;
      end;
      
      -- Constants
      local CORE_GUI          = GetService('CoreGui');
      local CORE_PACKAGES     = GetService('CorePackages');
      
      -- Variables
      local scriptsEnabled    = false;
      local heldScripts       = {};
      local connections       = {};
      
      task.spawn(function() -- Detect Failed Preload
      
            local players     = game:GetService('Players');
            local localPlayer = players.LocalPlayer;
      
            if (not localPlayer) then
      
                  players:GetPropertyChangedSignal('LocalPlayer'):Wait();
                  localPlayer = players.LocalPlayer;
            end;
      
            local playerGui = localPlayer:WaitForChild('PlayerGui', math.huge);
            playerGui:WaitForChild('LoadingScreen', math.huge);
            
            if (scriptsEnabled) then
                  return;
            end;
      
            __IMPORTS_3_kick(
                  'Script loaded too late. Please rejoin from the lobby.\n\n' ..
                  'If this issue persists, please DM mainstreamed with a screenshot.'
            );
      end);
      
      local RunOnInstance = function(instance: Instance)
      
            if (
                  instance.ClassName ~= 'LocalScript'
                  and instance.ClassName ~= 'Script'
            ) then
                  return;
            end;
      
            if ((instance :: BaseScript).Enabled) then
      
                  (instance :: BaseScript).Enabled = false;
                  table.insert(heldScripts, instance);
            end;
            return;
      end;
      
      local HoldScripts = function()
      
            for _, service in game:GetChildren() do
                  
                  if (service == CORE_GUI or service == CORE_PACKAGES) then
                        continue;
                  end;
      
                  for _, instance in service:GetDescendants() do
                        RunOnInstance(instance);
                  end;
                  
                  table.insert(
                        connections,
                        service.DescendantAdded:Connect(RunOnInstance)
                  );
            end;
      end;
      
      local ReleaseScripts = function()
      
            scriptsEnabled = true;
      
            for _, connection in connections do
                  connection:Disconnect();  
            end;
            for _, script in heldScripts do
                  script.Enabled = true;
            end;
      
            table.clear(connections);
            table.clear(heldScripts);
      end;
      
      return HoldScripts, (ReleaseScripts);
      
end)();
local __IMPORTS_5_request = (function()
      
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

-- Game Check
local success, placeId  = pcall(function()
      return game.PlaceId;
end);

if ( success and not table.find(__IMPORTS_1_GAME_IDS, placeId)) then

      return; -- Incorrect Game;
end;

-- Constants
local INTERNAL_PRELOAD  = 'preload.internal.lua';

do -- Load Script

      __IMPORTS_2_hold();

      local internalSource     = __IMPORTS_5_request(`{__IMPORTS_1_REPO}/{INTERNAL_PRELOAD}`);      

      local loadFunction, err = loadstring( internalSource );
      
      if type(loadFunction) ~= 'function' then

            return __IMPORTS_3_kick(
                  `Failed to load "{INTERNAL_PRELOAD}";\n`..
                  `Syntax Error: {err}\n\n` ..
                  'DM mainstreamed with a screenshot.'
            );
      end;

      loadFunction( __IMPORTS_2_release );
end;

return;
end)(...)
