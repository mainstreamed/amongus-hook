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

local GLOBAL_FONT = executor == 'AWP' and 0 or 1;
local GLOBAL_SIZE	= executor == 'AWP' and 15 or 13;

local BASE_ZINDEX = 1;

local espLibrary = {};


-- playerESP
do
      local playerESP = {
            playerCache = {};
            drawingCache = {};

            childAddedConnections = {};
            childRemovedConnections = {};
      };
      playerESP.__index = playerESP;

      playerESP.onChildAdded = function(_function)
            table.insert(playerESP.childAddedConnections, _function);
      end;
      playerESP.onChildRemoved = function(_function)
            table.insert(playerESP.childRemovedConnections, _function);
      end;
      playerESP.new = function(player: Player)
            local self = setmetatable({
                  player      = player;
                  connections = {};
                  allDrawings = nil;
                  drawings    = nil;
                  current     = nil;
            }, playerESP);

            local cache = playerESP.drawingCache[1];
            if (cache) then
                  table.remove(playerESP.drawingCache, 1);
                  
                  cache.name.Text = player.DisplayName;

                  self.allDrawings = cache.all;
                  self.drawings = cache;
            else
                  self:createDrawingCache();
            end;

            table.insert(self.connections, player.CharacterAdded:Connect(function(...)
                  return self:characterAdded(...);
            end));
            table.insert(self.connections, player.CharacterRemoving:Connect(function(...)
                  return self:characterRemoved(...);
            end));

            if (player.Character) then
                  self:characterAdded(player.Character, true);
            end;

            playerESP.playerCache[player] = self;

            return self;
      end;
      playerESP.remove = function(player: Player)
            local cache = playerESP.playerCache[player];
            playerESP.playerCache[player] = nil;

            for i = 1, #cache.connections do
                  cache.connections[i]:Disconnect();
            end;


            table.insert(playerESP.drawingCache, cache.drawings);
      end;

      function playerESP:createDrawingCache()
            local allDrawings = {};
            local drawings = {
                  box = createDrawing('Square', {
                        Visible           = false;
                        Thickness         = 1;
                        Color             = Color3.new(1, 1, 1);
                        Filled            = false;
                        ZIndex            = BASE_ZINDEX + 1;
                  }, allDrawings);
                  boxOutline = createDrawing('Square', {
                        Visible           = false;
                        Thickness         = 2;
                        Color             = Color3.new(0, 0, 0);
                        Filled            = false;
                        ZIndex            = BASE_ZINDEX;
                  }, allDrawings);

                  healthBar = createDrawing('Square', {
                        Visible           = false;
                        Thickness         = 1;
                        Filled            = true;
                        ZIndex            = BASE_ZINDEX + 1;
                  }, allDrawings);
                  healthBackground = createDrawing('Square', {
                        Visible           = false;
                        Color             = Color3.new(0.239215, 0.239215, 0.239215);
                        Transparency      = 0.7;
                        Thickness         = 1;
                        Filled            = true;
                        ZIndex            = BASE_ZINDEX;
                  }, allDrawings);

                  name = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = Color3.new(1, 1, 1);
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Text              = self.player.DisplayName;
                        Font              = GLOBAL_FONT;
                        ZIndex            = BASE_ZINDEX + 1;
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
                        ZIndex            = BASE_ZINDEX + 1;
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
                        ZIndex            = BASE_ZINDEX + 1;
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
      function playerESP:setNonActive()
            if (self.current.active == false) then
                  return;
            end;
            self.current.active = false;
            for i = 1, #self.allDrawings do
                  self.allDrawings[i].Visible = false;
            end;
      end;
      function playerESP:humanoidHealthChanged()
            local humanoid                = self.current.humanoid;

            local health                  = humanoid.Health;
            local maxHealth               = humanoid.MaxHealth;
            local healthPercentage        = health / maxHealth;

            if (self.current.rootPart and health > 0) then
                  self.current.active = true;
            else
                  self:setNonActive();
            end;



            self.current.health           = health;
            self.current.maxHealth        = maxHealth;
            self.current.healthPercentage = healthPercentage;

            self.drawings.healthBar.Color = Color3.new(1, 0, 0):Lerp(Color3.new(0, 1, 0), healthPercentage);
      end;
      function playerESP:setupHumanoid(humanoid: Humanoid, firstTime)

            self:humanoidHealthChanged();

            table.insert(self.connections, humanoid:GetPropertyChangedSignal('Health'):Connect(function()
                  self:humanoidHealthChanged();
            end));

            if (firstTime) then
                  local childAddedConnections = self.childAddedConnections;
                  local characterChildren = self.current.character:GetChildren();

                  for i = 1, #characterChildren do
                        local child = characterChildren[i];
                        for i = 1, #childAddedConnections do
                              childAddedConnections[i](self, child);
                        end;
                  end;
            end;
      end;
      function playerESP:loop(settings, distance)
            local current = self.current;

            local _, size              = getBoundingBox(current.character, 5);
            local goal              = current.rootPart.Position;

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
            self:renderDistance(vector2, offset, settings.distance, distance);
            self:renderHealthbar(vector2, offset, settings.healthbar);
            self:renderWeapon(vector2, offset, settings.weapon);
      end;
      function playerESP:primaryPartAdded()
            local primaryPart = self.current.character.PrimaryPart;

            if (primaryPart) then
                  self.current.rootPart = primaryPart;
                  if (self.current.humanoid and self.current.health > 0) then
                        self.current.active = true;
                  end;
            end;
      end;
      function playerESP:childAdded(child: Instance)

            if (child.ClassName == 'Humanoid') then
                  self.current.humanoid = child;
                  self:setupHumanoid(child);
            end;


            for i = 1, #self.childAddedConnections do
                  self.childAddedConnections[i](self, child);
            end;
      end;
      function playerESP:childRemoved(child)
            if (child == self.current.humanoid) then
                  self.current.humanoid = nil;
                  self:setNonActive();
            elseif (child == self.current.rootPart) then
                  self.current.rootPart = nil;
                  self:setNonActive();
            end;

            for i = 1, #self.childRemovedConnections do
                  self.childRemovedConnections[i](self, child);
            end;
      end;
      function playerESP:characterAdded(character: Model, firstTime)
            self.current = {
                  character   = character;
                  active      = false;

                  humanoid    = character:FindFirstChild('Humanoid');
                  rootPart    = character:FindFirstChild('HumanoidRootPart');


                  health      = nil;
                  weapon      = nil;
                  connection  = nil;
            };


            table.insert(self.connections, character:GetPropertyChangedSignal('PrimaryPart'):Connect(function()
                  self:primaryPartAdded();
            end));
            table.insert(self.connections, character.ChildAdded:Connect(function(...)
                  return self:childAdded(...);
            end));
            table.insert(self.connections, character.ChildRemoved:Connect(function(...)
                  return self:childRemoved(...);
            end));

            if (self.current.humanoid) then
                  self:setupHumanoid(self.current.humanoid, firstTime);
            end;

      end;
      function playerESP:characterRemoved(character)
            self.current = nil;

            for i = 1, #self.allDrawings do
                  self.allDrawings[i].Visible = false;
            end;
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
            name.Position     = vector2 - Vector2.new(0, offset.Y + name.Size);
      end;
      function playerESP:renderDistance(vector2, offset, enabled, _distance)
            local distance = self.drawings.distance;

            if (not enabled) then
                  distance.Visible          = false;
                  return;
            end;

            local Yoffset     = self.drawings.weapon.Visible and 13 or 0;
            local magnitude   = math.round( _distance or (currentCamera.CFrame.Position - self.current.rootPart.Position).Magnitude );
            
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

            weapon.Visible  = true;
            weapon.Position = vector2 + Vector2.new(0, offset.Y);
            weapon.Text     = self.current.weapon and string.lower(self.current.weapon.Name) or 'none';
      end;
      function playerESP:renderHealthbar(vector2, offset, enabled)
            if (not enabled) then
                  self.drawings.healthBar.Visible = false;
                  self.drawings.healthBackground.Visible = false;
                  return;
            end;

            local healthBar         = self.drawings.healthBar;
            local healthBackground  = self.drawings.healthBackground;

            healthBar.Visible = true;
            healthBackground.Visible = true;

            local basePosition = vector2 - offset - Vector2.new(5, 0);
            local baseSize = Vector2.new(3, offset.Y * 2);

            local healthLength = (baseSize.Y - 2) * self.current.healthPercentage;
            local healthPosition = basePosition + Vector2.new(1, 1 + (baseSize.Y - 2 - healthLength));
            local healthSize = Vector2.new(1, healthLength);

            healthBackground.Position     = basePosition;
            healthBackground.Size         = baseSize;

            healthBar.Position            = healthPosition;
            healthBar.Size                = healthSize;
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

      entityESP.new = function(entity: Model, settingName:string, name: string?, colour: Color3?)
            local self = setmetatable({
                  entity      = entity;
                  settingName = settingName;
                  
                  name        = name or entity.Name;
                  colour      = colour or Color3.new(1, 1, 1);

                  connections = {};
            }, entityESP);

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

            
            table.insert(self.connections, entity.AncestryChanged:Connect(function(child, parent)
                  if (child == entity and parent == nil) then
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
                        ZIndex            = BASE_ZINDEX + 1;
                  }, allDrawings);
                  boxOutline = createDrawing('Square', {
                        Visible           = false;
                        Filled            = false;
                        Thickness         = 1;
                        Color             = Color3.new(0, 0, 0);
                        ZIndex            = BASE_ZINDEX;
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
                        ZIndex            = BASE_ZINDEX;
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
                        ZIndex            = BASE_ZINDEX;
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
            local goal, size = getBoundingBox(self.entity);

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

            local magnitude   = math.round( _distance or (currentCamera.CFrame.Position - self.entity:GetPivot().Position).Magnitude );
            
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

      npcESP.new = function(entity: Model, settingName:string, name: string?, colour: Color3?)
            local self = setmetatable({
                  entity      = entity;
                  settingName = settingName;
                  
                  name        = name or entity.Name;
                  colour      = colour or Color3.new(1, 1, 1);

                  connections = {};
            }, npcESP);

            local cache = npcESP.drawingCache[1];
            if (cache) then
                  table.remove(npcESP.drawingCache, 1);
                  
                  cache.name.Text         = self.name;

                  cache.name.Color        = self.colour;
                  cache.box.Color         = self.colour;
                  cache.distance.Color    = self.colour;

                  self.allDrawings        = cache.all;
                  self.drawings           = cache;
            else
                  self:createDrawingCache();
            end;

            local humanoid = entity:FindFirstChildOfClass('Humanoid');
            if (humanoid and humanoid.Health > 0) then
                  
                  self.humanoid = humanoid;
                  table.insert(self.connections, entity.AncestryChanged:Connect(function(child, parent)
                        if (child == entity and parent == nil) then
                              return self:remove();
                        end;
                  end));
                  table.insert(self.connections, humanoid:GetPropertyChangedSignal('Health'):Connect(function()
                        if (humanoid.Health <= 0) then
                              return self:remove();
                        end;
                  end));

                  npcESP.npcCache[entity] = self;
                  self:setupHumanoid(humanoid);
                  return;
            end;


            local childAdded_connection;
            childAdded_connection = entity.ChildAdded:Connect(function(child)
                  if (child.ClassName ~= 'Humanoid') then
                        return;
                  end;


                  self.humanoid = child;
                  table.insert(self.connections, entity.AncestryChanged:Connect(function(child, parent)
                        if (child == entity and parent == nil) then
                              return self:remove();
                        end;
                  end));

                  npcESP.npcCache[entity] = self;
                  self:setupHumanoid(child);


                  childAdded_connection:Disconnect();
            end);
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
                        ZIndex            = BASE_ZINDEX + 1;
                  }, allDrawings);
                  boxOutline = createDrawing('Square', {
                        Visible           = false;
                        Filled            = false;
                        Thickness         = 1;
                        Color             = Color3.new(0, 0, 0);
                        ZIndex            = BASE_ZINDEX;
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
                        ZIndex            = BASE_ZINDEX;
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
                        ZIndex            = BASE_ZINDEX;
                  }, allDrawings);

                  healthBar = createDrawing('Square', {
                        Visible           = false;
                        Thickness         = 1;
                        Filled            = true;
                        ZIndex            = BASE_ZINDEX + 1;
                  }, allDrawings);
                  healthBackground = createDrawing('Square', {
                        Visible           = false;
                        Color             = Color3.new(0.239215, 0.239215, 0.239215);
                        Transparency      = 0.7;
                        Thickness         = 1;
                        Filled            = true;
                        ZIndex            = BASE_ZINDEX;
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
            local goal, size = getBoundingBox(self.entity);

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
            self:renderHealthbar(vector2, offset, settings.healthbar);
      end;
      
      function npcESP:humanoidHealthChanged()
            local humanoid          = self.humanoid;

            local health            = humanoid.Health;
            local maxHealth         = humanoid.MaxHealth;

            local healthPercentage  = health / maxHealth;
            
            self.health             = health;
            self.maxHealth          = maxHealth;
            self.healthPercentage   = healthPercentage;

            self.drawings.healthBar.Color = Color3.new(1, 0, 0):Lerp(Color3.new(0, 1, 0), healthPercentage);
      end;
      function npcESP:setupHumanoid(humanoid: Humanoid)

            self:humanoidHealthChanged();

            table.insert(self.connections, humanoid:GetPropertyChangedSignal('Health'):Connect(function()
                  self:humanoidHealthChanged();
            end));
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

            local magnitude   = math.round( _distance or (currentCamera.CFrame.Position - self.entity:GetPivot().Position).Magnitude );
            
            distance.Visible  = true;
            distance.Position = vector2 + Vector2.new(0, offset.Y);
            distance.Text     = `[{magnitude}]`;
      end;
      function npcESP:renderHealthbar(vector2, offset, enabled)
            if (not enabled) then
                  self.drawings.healthBar.Visible = false;
                  self.drawings.healthBackground.Visible = false;
                  return;
            end;

            local healthBar         = self.drawings.healthBar;
            local healthBackground  = self.drawings.healthBackground;

            healthBar.Visible = true;
            healthBackground.Visible = true;

            local basePosition = vector2 - offset - Vector2.new(5, 0);
            local baseSize = Vector2.new(3, offset.Y * 2);

            local healthLength = (baseSize.Y - 2) * self.healthPercentage;
            local healthPosition = basePosition + Vector2.new(1, 1 + (baseSize.Y - 2 - healthLength));
            local healthSize = Vector2.new(1, healthLength);

            healthBackground.Position     = basePosition;
            healthBackground.Size         = baseSize;

            healthBar.Position            = healthPosition;
            healthBar.Size                = healthSize;
      end;


      espLibrary.npcESP = npcESP;
end;


return espLibrary, 1;
