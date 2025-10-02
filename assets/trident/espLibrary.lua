local cloneref          = cloneref or function(...) return ...; end;
local compareinstances  = compareinstances or rawequal;

local runService        = cloneref(game:GetService('RunService'));

local currentCamera     = cloneref(workspace.CurrentCamera);


local createDrawing           = function(_type, properties, ...)
      local drawing = Drawing.new(_type);
      for i, value in properties do
            drawing[i] = value;
      end;
      for _, _table in {...} do
            table.insert(_table, drawing);
      end;
      return drawing;
end;
local getBoundingBox = function(model, maxsize: number?)
      local cframe, size = model:GetBoundingBox();
      if (maxsize) then
            size = Vector3.new(math.min(size.X, 5), math.min(size.Y, 6.7), math.min(size.Z, 5));
      end;
      return cframe, size;
end;
local worldToViewPoint = function(position)
      local pos, onscreen = currentCamera:WorldToViewportPoint(position);
      return Vector2.new(pos.X, pos.Y), onscreen, pos.Z;
end;

local executor 	= identifyexecutor and identifyexecutor() or 'unknown';

local GLOBAL_FONT = executor == 'AWP' and 0 or executor == 'Zenith' and 3 or 1;
local GLOBAL_SIZE	= executor == 'AWP' and 16 or executor == 'Zenith' and 15 or 13;

local espLibrary = {};


-- playerESP
do
      local playerESP = {
            playerCache = {};
            drawingCache = {};
      };
      playerESP.__index = playerESP;

      playerESP.new = function(player: table)

            local self = setmetatable({
                  
                  player      = player;
                  model       = rawget(player, 'model');

                  connections = {};
                  allDrawings = nil;
                  drawings    = nil;

            }, playerESP);

            if (typeof(self.model) ~= 'Instance') then
                  return;
            end;

            -- drawing cacher
            local cache = playerESP.drawingCache[1];
            if (cache) then
                  table.remove(playerESP.drawingCache, 1);
                  
                  -- cache.name.Text = 'player';

                  self.allDrawings  = cache.all;
                  self.drawings     = cache;
            else
                  self:createDrawingCache();
            end;

            -- setup
            self.rootPart = self.model:FindFirstChild('HumanoidRootPart');
            self.model.AncestryChanged:Connect(function(child, parent)
                  if (parent) then
                        return;
                  end;

                  self:remove();
            end);

            playerESP.playerCache[player] = self;
            return self;
      end;
      function playerESP:remove()
            playerESP.playerCache[self.player] = nil;
            self:hideDrawings();

            for i = 1, #self.connections do
                  self.connections[i]:Disconnect();
            end;

            table.insert(playerESP.drawingCache, self.drawings);
      end;

      function playerESP:createDrawingCache()
            local allDrawings = {};
            local drawings = {
                  box = createDrawing('Square', {
                        Visible           = false;
                        Thickness         = 1;
                        Color             = Color3.new(1, 1, 1);
                        Filled            = false;
                        ZIndex            = 1;
                  }, allDrawings);
                  boxOutline = createDrawing('Square', {
                        Visible           = false;
                        Thickness         = 2;
                        Color             = Color3.new(0, 0, 0);
                        Filled            = false;
                        ZIndex            = 0;
                  }, allDrawings);

                  -- healthBar = createDrawing('Square', {
                  --       Visible           = false;
                  --       Thickness         = 1;
                  --       Filled            = true;
                  --       ZIndex            = 1;
                  -- }, allDrawings);
                  -- healthBackground = createDrawing('Square', {
                  --       Visible           = false;
                  --       Color             = Color3.new(0.239215, 0.239215, 0.239215);
                  --       Transparency      = 0.7;
                  --       Thickness         = 1;
                  --       Filled            = true;
                  --       ZIndex            = 0
                  -- }, allDrawings);

                  name = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = Color3.new(1, 1, 1);
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Text              = 'player';
                        Font              = GLOBAL_FONT;
                        ZIndex            = 1;
                  }, allDrawings);
                  distance = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = Color3.new(1, 1, 1);
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Font              = GLOBAL_FONT;
                        ZIndex            = 1;
                  }, allDrawings);
                  weapon = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = Color3.new(1, 1, 1);
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Font              = GLOBAL_FONT;
                        ZIndex            = 1;
                  }, allDrawings);
            };
            drawings.all = allDrawings;

            self.drawings = drawings;
            self.allDrawings = allDrawings;
      end;
      function playerESP:hideDrawings()
            for i = 1, #self.allDrawings do
                  self.allDrawings[i].Visible = false;
            end;
      end;

      --character functions
      function playerESP:loop(settings, distance)
            local _, size           = getBoundingBox(self.model, 5);
            local goal              = self.rootPart.Position;

            local vector2, onscreen = worldToViewPoint(goal);
            if (not onscreen) then
                  return self:hideDrawings();
            end;

            local cframe = CFrame.new(goal, currentCamera.CFrame.Position);

            local x, y = -size.X / 2, size.Y / 2;
            local topright    = worldToViewPoint((cframe * CFrame.new(x, y, 0)).Position)
            local bottomright = worldToViewPoint((cframe * CFrame.new(x, -y, 0)).Position)

            local offset = Vector2.new(
                  math.max(topright.X - vector2.X, bottomright.X - vector2.X),
                  math.max((vector2.Y - topright.Y), (bottomright.Y - vector2.Y))
            );

            self:renderBox(vector2, offset, settings.box);
            self:renderName(vector2, offset, settings.name);
            self:renderDistance(vector2, offset, settings.distance);
            -- self:renderHealthbar(vector2, offset, settings.healthbar);
            self:renderWeapon(vector2, offset, settings.weapon);
      end;

      --render functions
      function playerESP:renderBox(vector2, offset, enabled)
            local drawings = self.drawings;

            if (not enabled) then
                  drawings.box.Visible          = false;
                  drawings.boxOutline.Visible   = false;
                  return;
            end;

            local fill        = drawings.box;
            local outline     = drawings.boxOutline;

            local position    = vector2 - offset;
            local size        = offset * 2;
            
            fill.Visible      = true;
            fill.Position     = position;
            fill.Size         = size;

            outline.Visible   = true;
            outline.Position  = position;
            outline.Size      = size;
      end;
      function playerESP:renderName(vector2, offset, enabled)
            local name = self.drawings.name;

            if (not enabled) then
                  name.Visible          = false;
                  return;
            end;
            
            name.Visible      = true;
            name.Text         = rawget(self.player, 'sleeping') and 'sleeper' or 'player';
            name.Position     = vector2 - Vector2.new(0, offset.Y + name.Size);
      end;
      function playerESP:renderDistance(vector2, offset, enabled, _distance)
            local distance = self.drawings.distance;

            if (not enabled) then
                  distance.Visible          = false;
                  return;
            end;

            local Yoffset     = self.drawings.weapon.Visible and 13 or 0;
            local magnitude   = math.round( _distance or (currentCamera.CFrame.Position - self.rootPart.Position).Magnitude );
            
            distance.Visible  = true;
            distance.Position = vector2 + Vector2.new(0, offset.Y + Yoffset);
            distance.Text     = `[{magnitude}]`;
      end;
      function playerESP:renderWeapon(vector2, offset, enabled)
            local weapon = self.drawings.weapon;

            if (not enabled) then
                  weapon.Visible          = false;
                  return;
            end;

            local weaponText        = 'none';
            local equippedItem      = rawget(self.player, 'equippedItem');

            if (equippedItem) then
                  weaponText = rawget(equippedItem, 'type') or 'none';
                  if (rawget(equippedItem, 'amt') > 1) then
                        weaponText = `{weaponText} x{ rawget(equippedItem, 'amt') }`;
                  end;
            end;

            weapon.Visible  = true;
            weapon.Position = vector2 + Vector2.new(0, offset.Y);
            weapon.Text     = weaponText;
      end;

      espLibrary.playerESP = playerESP;
end;

-- entityESP
do
      local entityESP = {
            entityCache = {};
            drawingCache = {};

            childAddedConnections = {};
            childRemovedConnections = {};
      };
      entityESP.__index = entityESP;

      entityESP.new = function(entity: Model, name: string?, colour: Color3?)
            local self = setmetatable({
                  entity      = entity;
                  
                  name        = name or rawget(entity, 'type');
                  colour      = colour or Color3.new(1, 1, 1);
                  model       = rawget(entity, 'model');

                  connections = {};
            }, entityESP);

            if (type(self.name) ~= 'string') then
                  self.name = '???';
            elseif (typeof(self.model) ~= 'Instance') then
                  return;
            end;

            local cache = entityESP.drawingCache[1];
            if (cache) then
                  table.remove(entityESP.drawingCache, 1);
                  
                  cache.name.Text         = self.name;

                  cache.name.Color        = self.colour;
                  cache.box.Color         = self.colour;
                  cache.distance.Color    = self.colour;

                  self.allDrawings        = cache.all;
                  self.drawings           = cache;
            else
                  self:createDrawingCache();
            end;

            
            table.insert(self.connections, self.model.AncestryChanged:Connect(function(child, parent)
                  if (child == self.model and parent == nil) then
                        return self:remove();
                  end;
            end));

            entityESP.entityCache[entity] = self;
      end;
      function entityESP:remove()
            entityESP.entityCache[self.entity] = nil;
            
            self:hideDrawings();
            
            table.insert(entityESP.drawingCache, self.drawings);

            for i = 1, #self.connections do
                  self.connections[i]:Disconnect();
            end;
      end;
      function entityESP:createDrawingCache()
            local allDrawings = {};

            local drawings = {
                  box = createDrawing('Square', {
                        Visible           = false;
                        Filled            = false;
                        Thickness         = 1;
                        Color             = self.colour;
                        ZIndex            = 0;
                  }, allDrawings);
                  boxOutline = createDrawing('Square', {
                        Visible           = false;
                        Filled            = false;
                        Thickness         = 1;
                        Color             = Color3.new(0, 0, 0);
                        ZIndex            = -1;
                  }, allDrawings);

                  name = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = self.colour;
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Text              = self.name;
                        Font              = GLOBAL_FONT;
                        ZIndex            = 0;
                  }, allDrawings);
                  distance = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = self.colour;
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Font              = GLOBAL_FONT;
                        ZIndex            = 0;
                  }, allDrawings);
            };
            drawings.all = allDrawings;

            self.drawings = drawings;
            self.allDrawings = allDrawings;

      end;
      function entityESP:hideDrawings()
            for i = 1, #self.allDrawings do
                  self.allDrawings[i].Visible = false;
            end;
      end;
      function entityESP:loop(settings, distance)
            local goal, size = getBoundingBox(self.model);

            local vector2, onscreen = worldToViewPoint(goal.Position);
            if (not onscreen) then
                  return self:hideDrawings();
            end;

            local cframe = CFrame.new(goal.Position, currentCamera.CFrame.Position);

            local x, y = -size.X / 2, size.Y / 2;
            local topright    = worldToViewPoint((cframe * CFrame.new(x, y, 0)).Position)
            local bottomright = worldToViewPoint((cframe * CFrame.new(x, -y, 0)).Position)

            local offset = Vector2.new(
                  math.max(topright.X - vector2.X, bottomright.X - vector2.X),
                  math.max((vector2.Y - topright.Y), (bottomright.Y - vector2.Y))
            );

            self:renderBox(vector2, offset, settings.box);
            self:renderName(vector2, offset, settings.name);
            self:renderDistance(vector2, offset, settings.distance, distance);
      end;
      
      -- render functions
      function entityESP:renderBox(vector2, offset, enabled)
            local drawings = self.drawings;

            if (not enabled) then
                  drawings.box.Visible          = false;
                  drawings.boxOutline.Visible   = false;
                  return;
            end;

            local fill        = drawings.box;
            local outline     = drawings.boxOutline;

            local position    = vector2 - offset;
            local size        = offset * 2;
            
            fill.Visible      = true;
            fill.Position     = position;
            fill.Size         = size;

            outline.Visible   = true;
            outline.Position  = position;
            outline.Size      = size;
      end;
      function entityESP:renderName(vector2, offset, enabled)
            local name = self.drawings.name;

            if (not enabled) then
                  name.Visible          = false;
                  return;
            end;
            
            name.Visible      = true;
            name.Position     = vector2 - Vector2.new(0, offset.Y + name.Size);
      end;
      function entityESP:renderDistance(vector2, offset, enabled, _distance)
            local distance = self.drawings.distance;

            if (not enabled) then
                  distance.Visible          = false;
                  return;
            end;

            local magnitude   = math.round( _distance or (currentCamera.CFrame.Position - self.model:GetPivot().Position).Magnitude );
            
            distance.Visible  = true;
            distance.Position = vector2 + Vector2.new(0, offset.Y);
            distance.Text     = `[{magnitude}]`;
      end;

      espLibrary.entityESP = entityESP;
end;

-- npcESP
do
      local npcESP = {
            npcCache = {};
            drawingCache = {};
      };
      npcESP.__index = npcESP;

      npcESP.new = function(entity: Model, colour: Color3?)
            local self = setmetatable({
                  entity      = entity;
                  settingName = settingName;
                  
                  name        = rawget(entity, 'type') or 'npc';
                  colour      = colour or Color3.new(1, 1, 1);
                  model       = rawget(entity, 'model');

                  connections = {};
            }, npcESP);

            if (typeof(self.model) ~= 'Instance') then
                  return;
            elseif (type(self.name) ~= 'string') then
                  self.name = 'npc';
            end;

            -- drawing cacher
            local cache = npcESP.drawingCache[1];
            if (cache) then
                  table.remove(npcESP.drawingCache, 1);
                  
                  self.allDrawings  = cache.all;
                  self.drawings     = cache;
            else
                  self:createDrawingCache();
            end;

            -- updating drawing info
            local drawings = self.drawings;
            drawings.name.Text      = self.name;
            drawings.name.Color     = self.colour;
            drawings.box.Color      = self.colour;
            drawings.weapon.Color   = self.colour;
            drawings.distance.Color = self.colour;

            -- setup
            self.rootPart = self.model:FindFirstChild('HumanoidRootPart');
            self.model.AncestryChanged:Connect(function(child, parent)
                  if (parent) then
                        return;
                  end;
                  self:remove();
            end);

            npcESP.npcCache[entity] = self;
            return self;
      end;
      function npcESP:remove()
            npcESP.npcCache[self.entity] = nil;
            
            self:hideDrawings();
            
            table.insert(npcESP.drawingCache, self.drawings);

            for i = 1, #self.connections do
                  self.connections[i]:Disconnect();
            end;
      end;
      function npcESP:createDrawingCache()
            local allDrawings = {};

            local drawings = {
                  box = createDrawing('Square', {
                        Visible           = false;
                        Filled            = false;
                        Thickness         = 1;
                        Color             = self.colour;
                        ZIndex            = 0;
                  }, allDrawings);
                  boxOutline = createDrawing('Square', {
                        Visible           = false;
                        Filled            = false;
                        Thickness         = 1;
                        Color             = Color3.new(0, 0, 0);
                        ZIndex            = -1;
                  }, allDrawings);

                  name = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = self.colour;
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Text              = self.name;
                        Font              = GLOBAL_FONT;
                        ZIndex            = 0;
                  }, allDrawings);
                  distance = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = self.colour;
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Font              = GLOBAL_FONT;
                        ZIndex            = 0;
                  }, allDrawings);

                  weapon = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = Color3.new(1, 1, 1);
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Font              = GLOBAL_FONT;
                        ZIndex            = 1;
                  }, allDrawings);
            };
            drawings.all = allDrawings;

            self.drawings = drawings;
            self.allDrawings = allDrawings;

      end;
      function npcESP:hideDrawings()
            for i = 1, #self.allDrawings do
                  self.allDrawings[i].Visible = false;
            end;
      end;
      function npcESP:loop(settings, distance)
            local goal, size = getBoundingBox(self.model, Vector3.new(3, 5, 3));

            local vector2, onscreen = worldToViewPoint(goal.Position);
            if (not onscreen) then
                  return self:hideDrawings();
            end;

            local cframe = CFrame.new(goal.Position, currentCamera.CFrame.Position);

            local x, y = -size.X / 2, size.Y / 2;
            local topright    = worldToViewPoint((cframe * CFrame.new(x, y, 0)).Position)
            local bottomright = worldToViewPoint((cframe * CFrame.new(x, -y, 0)).Position)

            local offset = Vector2.new(
                  math.max(topright.X - vector2.X, bottomright.X - vector2.X),
                  math.max((vector2.Y - topright.Y), (bottomright.Y - vector2.Y))
            );

            self:renderBox(vector2, offset, settings.box);
            self:renderName(vector2, offset, settings.name);
            self:renderDistance(vector2, offset, settings.distance, distance);
            -- self:renderHealthbar(vector2, offset, settings.healthbar);
      end;

      -- render functions
      function npcESP:renderBox(vector2, offset, enabled)
            local drawings = self.drawings;

            if (not enabled) then
                  drawings.box.Visible          = false;
                  drawings.boxOutline.Visible   = false;
                  return;
            end;

            local fill        = drawings.box;
            local outline     = drawings.boxOutline;

            local position    = vector2 - offset;
            local size        = offset * 2;
            
            fill.Visible      = true;
            fill.Position     = position;
            fill.Size         = size;

            outline.Visible   = true;
            outline.Position  = position;
            outline.Size      = size;
      end;
      function npcESP:renderName(vector2, offset, enabled)
            local name = self.drawings.name;

            if (not enabled) then
                  name.Visible          = false;
                  return;
            end;
            
            name.Visible      = true;
            name.Position     = vector2 - Vector2.new(0, offset.Y + name.Size);
      end;
      function npcESP:renderDistance(vector2, offset, enabled, _distance)
            local distance = self.drawings.distance;

            if (not enabled) then
                  distance.Visible          = false;
                  return;
            end;

            local magnitude   = math.round( _distance or (currentCamera.CFrame.Position - self.model:GetPivot().Position).Magnitude );
            
            distance.Visible  = true;
            distance.Position = vector2 + Vector2.new(0, offset.Y);
            distance.Text     = `[{magnitude}]`;
      end;
      -- function npcESP:renderHealthbar(vector2, offset, enabled)
      --       if (not enabled) then
      --             self.drawings.healthBar.Visible = false;
      --             self.drawings.healthBackground.Visible = false;
      --             return;
      --       end;

      --       local healthBar         = self.drawings.healthBar;
      --       local healthBackground  = self.drawings.healthBackground;

      --       healthBar.Visible = true;
      --       healthBackground.Visible = true;

      --       local basePosition = vector2 - offset - Vector2.new(5, 0);
      --       local baseSize = Vector2.new(3, offset.Y * 2);

      --       local healthLength = (baseSize.Y - 2) * self.healthPercentage;
      --       local healthPosition = basePosition + Vector2.new(1, 1 + (baseSize.Y - 2 - healthLength));
      --       local healthSize = Vector2.new(1, healthLength);

      --       healthBackground.Position     = basePosition;
      --       healthBackground.Size         = baseSize;

      --       healthBar.Position            = healthPosition;
      --       healthBar.Size                = healthSize;
      -- end;


      espLibrary.npcESP = npcESP;
end;


return espLibrary, 1;
