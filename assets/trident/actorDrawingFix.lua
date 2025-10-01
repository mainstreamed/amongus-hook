-- SERIAL SIDE
local coreGUI           = game:GetService('CoreGui');

local drawingCache      = {};
local drawingID         = 0;
local communicator      = Instance.new('BindableEvent', coreGUI);
communicator.Name       = 'DRAWING_COMMUNICATOR';

communicator.Event:Connect(function(enviroment, action, ...)

      if (enviroment ~= 'parallel') then
            return;
      elseif (action == '__index') then
            local id, index = ...;
            communicator:Fire('serial', drawingCache[id][index]);

      elseif (action == 'new') then
            drawingID += 1;
            drawingCache[drawingID] = Drawing.new(...);

      elseif (action == '__newindex') then
            local id, index, value = ...;
            drawingCache[id][index] = value;

      elseif (action == 'remove') then
            drawingCache[...]:Remove();
      end;
end);

return [==[
      --!actor

      -- PARALLEL SIDE
      local drawingID         = 0;
      local drawingResponse   = nil;

      local communicator      = game:GetService('CoreGui'):FindFirstChild('DRAWING_COMMUNICATOR');
      communicator.Parent     = nil;

      communicator.Event:Connect(function(enviroment, value)
            if (enviroment ~= 'serial') then
                  return;
            end;
            drawingResponse = value;
      end);

      local permissionBypass  = Instance.new('BindableEvent');
      permissionBypass.Event:Connect(function(...)
            communicator:Fire(...);
      end);

      local new = function(_type)
            drawingID += 1;
            permissionBypass:Fire('parallel', 'new', _type);

            local drawID            = drawingID;
            local customDrawing     = newproxy(true);
            local objectMT          = getmetatable(customDrawing);

            objectMT.__index        = function(_, idx)

                  if (idx == 'Remove' or idx == 'Destroy') then
                        return function()
                              permissionBypass:Fire('parallel', 'remove', drawID);
                        end;
                  end;

                  permissionBypass:Fire('parallel', '__index', drawID, idx);
                  local response = drawingResponse;
                  drawingResponse = nil;

                  return response;
            end;
            objectMT.__newindex     = function(_, idx, nidx)
                  permissionBypass:Fire('parallel', '__newindex', drawID, idx, nidx);
            end;

            return customDrawing;
      end;

      getgenv().Drawing = {
            new   = new;
            Fonts = {
                  UI          = 0;
                  System      = 1;
                  Plex        = 2;
                  Monospace   = 3;
            };
      };
]==];
