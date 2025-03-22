if not game:IsLoaded() then
	game.Loaded:Wait()
end;

local players 		= game:GetService('Players');
local localPlayer 	= players.LocalPlayer;
if (not localPlayer) then
	players:GetPropertyChangedSignal('LocalPlayer'):Wait();
	localPlayer = players.LocalPlayer;
end;

local executor 		= identifyexecutor and identifyexecutor() or 'Unknown';

local messagebox 	= messagebox;
local request 		= request or http_request;
local loadstring 	= loadstring;

if (type(messagebox) ~= 'function') then
	return localPlayer:Kick('[amongus.hook] missing alias ( messagebox ) - unsupported executor');
end;

local protectedMessagebox = function(body, title, id)
	local success, output = pcall(messagebox, body, title, id);
	if (not success) then
		localPlayer:Kick(`[amongus.hook] messagebox_error - {body}`);
		task.wait(9e9);
		return;
	end;
	return output;
end;
local protectedLoad = function(url)
	local success, response = pcall(request, {Url=url; Method='GET';});
	if (not success) then
		protectedMessagebox(`protectedLoad failed(1) - request error\n\nurl: {url}`, `amongus.hook [{executor}]`, 48);
		task.wait(9e9);
		return;
	elseif (type(response) ~= 'table' or type(response.Body) ~= 'string' or response.StatusCode ~= 200) then
            protectedMessagebox(`protectedLoad failed(2) - bad response\n\nurl: {url}`, `amongus.hook [{executor}]`, 48);
		task.wait(9e9);
		return;
      end;
      local loader = loadstring(response.Body);
      if (not loader) then
            protectedMessagebox(`protectedLoad failed(3) - syntax error\n\nurl: {url}`, `amongus.hook [{executor}]`, 48);
		task.wait(9e9);
		return;
      end;
      return loader();
end;

if (type(loadstring) ~= 'function') then
	return protectedMessagebox(`missing alias ( loadstring ) - unsupported executor`, `amongus.hook [{executor}]`, 48);
elseif (type(request) ~= 'function') then
	return protectedMessagebox(`missing alias ( request ) - unsupported executor`, `amongus.hook [{executor}]`, 48);
elseif (not Drawing) then
	protectedLoad('https://raw.githubusercontent.com/mainstreamed/amongus-hook/refs/heads/main/drawingfix.lua');
end;
	
local placeid = game.PlaceId;
local dir = 'https://raw.githubusercontent.com/mainstreamed/amongus-hook/main/';

local statuslist = {};

statuslist.fallensurvival = {
	name 		= 'Fallen Survival';
	status 		= 'Undetected';
	support 	= {'Wave'; 'AWP'};
};
statuslist.tridentsurvival = {
	name 		= 'Trident Survival';
	status 		= 'Undetected';
	support 	= {'Wave'; 'AWP'; 'Synapse Z'; 'MacSploit'; 'Velocity'};
};

local load = function(name)
	local game = statuslist[name];
	if (game.status ~= 'Undetected' and protectedMessagebox(`{game.name} is Currently Marked as {game.status}!\n\nAre You Sure You Want to Continue?`, `amongus.hook`, 52) ~= 6) then
		return;
	elseif (
		game.support and 
		not table.find(game.support, executor) and 
		protectedMessagebox(`Unsupported Executor!\n\n{executor} is not Officially Supported for {game.name}\nand may have Undefined Behaviour or even result in a BAN!\n\nAre You Sure You Want to Continue?`, `amongus.hook [{executor}]`, 52) ~= 6
	) then
		return;
	end;
	protectedLoad(`{dir}{name}/main.lua`);
end;

if (placeid == 13253735473) then
	return load('tridentsurvival');
elseif (placeid == 13800717766 or placeid == 15479377118 or placeid == 16849012343) then
    return load('fallensurvival');
end;
protectedMessagebox(`This Game is Unsupported!\n\nIf you believe this is incorrect, please open a ticket in our discord! - discord.gg/2jycAcKvdw`, `amongus.hook [{placeid}]`, 48);
