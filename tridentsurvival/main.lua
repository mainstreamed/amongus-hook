local players           = game:GetService('Players');
local localplayer       = players.LocalPlayer;
if (not localplayer) then
      players:GetPropertyChangedSignal('LocalPlayer'):Wait();
      localplayer = players.LocalPlayer;
end;

local source = game:HttpGet('https://raw.githubusercontent.com/mainstreamed/amongus-hook/refs/heads/main/tridentsurvival/obfuscated.lua');
if (getgenv and getgenv().DEBUG_AMGHOOK) then
      source = 'getgenv().DEBUG_AMGHOOK = true;' .. source;
end;

-- Drawing Fix ( FUCK VOLCANO )
source = [==[
      if (not Drawing) then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/mainstreamed/amongus-hook/refs/heads/main/assets/trident/luaDrawing.lua"))();
      end;
]==] .. source;

local executor = identifyexecutor and identifyexecutor() or 'Unknown';

-- Main Load
local fastflag = getfflag and getfflag('DebugRunParallelLuaOnMainThread');
if (fastflag == 'true' or fastflag == 'True' or fastflag == true) then
      loadstring(source)();
      return;
elseif (run_on_actor) then

      local executors = { 'Volcano'; '' };
      if (table.find(executors, executor)) then
            return localplayer:Kick('Please use fflag - "#fflag-script" channel in discord');
      end;

      local actor = getactors and getactors()[1] or localplayer:FindFirstChildWhichIsA('Actor', true);
      if (actor) then
            return run_on_actor(actor, source);
      end;
end;
loadstring(source)();
