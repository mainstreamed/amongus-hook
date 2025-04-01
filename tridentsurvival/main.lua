local check_run_on_actor = function()
      if (identifyexecutor) then
            local exec = identifyexecutor();
            if (exec == 'AWP' or exec == 'Potassium') then
                  return true;
            end;
      end;

      local event = Instance.new('BindableEvent', game:GetService('CoreGui'));
      event.Name = 'communicator';

      local success = false;
      local connection;
      connection = event.Event:Connect(function(...)
            if (... == 'recieved') then
                  success = true;
                  event:Destroy();
                  connection:Disconnect();
            end;
      end);
      run_on_actor(Instance.new('Actor'), [[
            local event = game:GetService('CoreGui'):FindFirstChild('communicator');
            if (not event) then
                  return;
            end;
            event:Fire('recieved');
      ]]);
      task.wait();
      if (not success) then
            event:Destroy();
            connection:Disconnect();
            return false;
      end;
      return true;
end;


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

local fastflag = getfflag and getfflag('DebugRunParallelLuaOnMainThread');
if (fastflag == 'true' or fastflag == 'True' or fastflag == true) then
      loadstring(source)();
      return;
elseif (run_on_actor and check_run_on_actor()) then
      local actor = getactors and getactors()[1] or localplayer:FindFirstChildWhichIsA('Actor', true);
      if (actor) then
            return run_on_actor(actor, source);
      end;
end;
loadstring(source)();
