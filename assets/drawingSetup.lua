if (not _G or type(_G) ~= 'table') then
      return;
end;

local setGlobals = function(font, size)
      _G.GLOBAL_FONT = font;
      _G.GLOBAL_SIZE = size;
end;

if (not identifyexecutor or type(identifyexecutor) ~= 'function') then
      return setGlobals(1, 13);
end;

local success, executor = pcall(identifyexecutor);
if (not success) then
      return setGlobals(1, 13);
end;

local GLOBAL_FONT       =
      executor == 'Wave' and 1 or
      executor == 'Volt' and 2 or 1;


local GLOBAL_SIZE       =
      executor == 'Wave' and 13 or
      executor == 'Volt' and 15 or 13;

setGlobals(GLOBAL_FONT, GLOBAL_SIZE);
