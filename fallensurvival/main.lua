local GITHUB_REPO = 'https://raw.githubusercontent.com/mainstreamed/amongus-hook/refs/heads/main/';

local success, result = pcall(function()
	return loadstring(request({Url=GITHUB_REPO .. 'fallensurvival/deobfuscated.lua'; Method='GET'}).Body)();
end);

if (not success) then
	warn('[amongus.hook] fallen loader error:', result);
end;
