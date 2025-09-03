local drawing_new       = Drawing.new;
local getchildren       = game.GetChildren;
local findfirstchild    = game.FindFirstChild;
local getservice        = game.GetService;
local vector2_new       = Vector2.new;
local color3_new        = Color3.new;
local color3_fromrgb    = Color3.fromRGB;
local cframe_new        = CFrame.new;
local instance_new      = Instance.new;
local math_huge         = math.huge;
local math_max          = math.max;
local table_insert      = table.insert;
local table_find        = table.find;
local wait              = task.wait;

local userinputservice  = getservice(game, 'UserInputService');
local camera            = workspace.CurrentCamera
local camx              = camera.ViewportSize.X;
local menuwidth         = math_max(camx / 18, 120)

local createDrawing = function(type, properties, add)
	local drawing = drawing_new(type);
	if (properties) then
		for index, value in properties do
			drawing[index] = value;
		end
	end
	if (add) then
		for index, value in add do
			table_insert(value, drawing);
		end
	end
	return drawing;
end

-- main library
local flags = {};
local library = {
	inputs = { -- all functions used for inputs (to save connections)
		Up = {},
		Down = {},
		Right = {},
		Left = {},
		Return = {},
		Backspace = {},
	},
      helddown = {
            Up = false,
            Down = false,
      },
	tabinfo = { -- all tab data here
		active = false,
		amount = 0,
		selected = 1,
		tabs = {},
	},
	active = true,
	togglecallbacks = {};
	alldrawings = {}, -- all drawings get stored in here
}

--[[
local watermark = createDrawing('Text', {
	Text = base64.decode('QU1PTkdVUyBIT09LIChkaXNjb3JkLmdnLzJqeWNBY0t2ZHcp'),
	Position = vector2_new(camx/2, 0),
	Center = true,
	Visible = true,
	Size = 40,
	ZIndex = 99999999,
	Outline = true,
	Color = color3_new(1, 0, 0)
})
]]

-- library functions
do
	-- add arrow input function
	function library:dInput(key, func)
		table_insert(library.inputs[key], func);
	end
	function library:Unload()
		for _, value in library.alldrawings do
			value:Remove();
		end
		library.mainconnection:Disconect();
            library.inputended:Disconnect();
		library = nil;
	end
	function library:AddToToggle(_function)
		table.insert(library.togglecallbacks, _function);
	end;
	function library:Toggle(boolean)
		if (boolean == nil) then
			boolean = not library.active
		end

		for _, _function in library.togglecallbacks do
			_function(boolean);
		end;

		library.active = boolean;
		for _, tab in library.tabinfo.tabs do
			for _, drawing in tab.drawings do
				drawing.Visible = boolean;
			end
		end
	end
end
-- initialise
if (not _G.amonguslib_loaded) then
	do
		-- detecting inputs (reducing connections)
		library.mainconnection = userinputservice.InputBegan:Connect(function(key)
			local name = key.KeyCode.Name;
                  local funcs = library.inputs[name];
			if (not funcs) then
				return;
                  elseif (name == 'Right' or name == 'Left') then
				-- custom handler for sliders :);
                        library.helddown[name] = true;

                        for _, func in funcs do
                              task.spawn(func);
                        end;
                        return;
			end;
			for _, func in funcs do
				task.spawn(func);
			end;
		end);
            library.inputended = userinputservice.InputEnded:Connect(function(key)
                  local name = key.KeyCode.Name;
			if (name == 'Right' or name == 'Left') then
				library.helddown[name] = false;
			end;
		end);
		-- inputs for going up and down the tabs
		library:dInput('Right', function()
			if (not library.active) then
				library:Toggle(true);
			end;
		end)
		library:dInput('Left', function()
			if (not library.tabinfo.active and library.active) then
				library:Toggle(false);
			end;
		end)
		library:dInput('Up', function()
			local ti = library.tabinfo;
			if (library.active and not ti.active and ti.selected > 1) then
				ti.tabs[ti.selected]:hovered_();
				ti.selected-=1;
				ti.tabs[ti.selected]:hovered_();
			end;
		end)
		library:dInput('Down', function()
			local ti = library.tabinfo;
			if (library.active and not ti.active and ti.selected < ti.amount) then
				ti.tabs[ti.selected]:hovered_();
				ti.selected+=1;
				ti.tabs[ti.selected]:hovered_();
			end;
		end)
		library:dInput('Return', function()
			local ti = library.tabinfo;
			if (library.active and not ti.active) then
				task.wait()
				ti.tabs[ti.selected]:open();
			end
		end)
		library:dInput('Backspace', function()
			local ti = library.tabinfo;
			if (library.active and ti.active) then
				ti.tabs[ti.selected]:close();
			end
		end)
	end
end
-- user functions
do
	function library:AddTab(text)
		-- tab startup
		local hovered = false;
		if (library.tabinfo.amount == 0) then
			hovered = true;
		end
		library.tabinfo.amount += 1;
		-- creating tab
		local tab = {
			hovered = false,
			opened = false,
			selected = 1,
			drawings = {},
			options = {
				amount = 0,
				stored = {},
			},
		}
		-- creating drawings
		do
			tab.drawings.base = createDrawing('Square', {
				Visible = true,
				Color = color3_fromrgb(0, 0, 0),
				Transparency = 0.5,
				Thickness = 1,
				Filled = true,
				Position = vector2_new(0, 40 + (library.tabinfo.amount * 15)),
				Size = vector2_new(menuwidth, 15),
				ZIndex = 0;
			}, {library.alldrawings})
			tab.drawings.text = createDrawing('Text', {
				Visible = true,
				Color = color3_fromrgb(255, 255, 255),
				Font = 1,
				Outline = true;
				Position = tab.drawings.base.Position,
				Size = 14,
				Center = false;
				Text = text,
				OutlineColor = color3_fromrgb(0, 0, 0);

				Transparency = 1,
				ZIndex = 1;
			}, {library.alldrawings})
			tab.drawings.arrow = createDrawing('Text', {
				Visible = true,
				Color = color3_fromrgb(255, 255, 255),
				Text = '<',
				Outline = true;
				Center = false;
				Font = 1,
				Position = tab.drawings.base.Position + vector2_new(menuwidth-10, 0),
				Size = 14,
				OutlineColor = color3_fromrgb(0, 0, 0);
				Transparency = 1,
				ZIndex = 1;
			}, {library.alldrawings})

		end
		-- functions
		do
			function tab:hovered_(boolean)
				if (boolean == nil) then
					boolean = not tab.hovered;
				end
				tab.hovered = boolean;
				if (boolean) then
					tab.drawings.base.Color = color3_fromrgb(255, 0, 0);
					return;
				end
				tab.drawings.base.Color = color3_fromrgb(0, 0, 0);
			end
			function tab:open()
				if (tab.opened or library.tabinfo.active) then
					return;
				end
				library.tabinfo.active = true;
				tab.opened = true;
				tab.drawings.arrow.Text = '>';
				for _, option in tab.options.stored do
					for _, drawing in option.drawings do
						drawing.Visible = true;
					end
				end
			end
			function tab:close()
				if (not tab.opened or not library.tabinfo.active) then
					return;
				end
				library.tabinfo.active = false;
				tab.opened = false;
				tab.drawings.arrow.Text = '<';
				for _, option in tab.options.stored do
					for _, drawing in option.drawings do
						drawing.Visible = false;
					end
				end
			end
			tab.navUp = function()
				if (tab.opened and tab.selected > 1) then
					local current = tab.options.stored[tab.selected];
					current.hovered = false;
					current.drawings.base.Color = color3_fromrgb(0, 0, 0);
					tab.selected -= 1;
					local current = tab.options.stored[tab.selected];
					current.hovered = true;
					current.drawings.base.Color = color3_fromrgb(255, 0, 0);
				end
			end
			tab.navDown = function()
				if (tab.opened and tab.selected < tab.options.amount) then
					local current = tab.options.stored[tab.selected];
					current.hovered = false;
					current.drawings.base.Color = color3_fromrgb(0, 0, 0);
					tab.selected += 1;
					local current = tab.options.stored[tab.selected];
					current.hovered = true;
					current.drawings.base.Color = color3_fromrgb(255, 0, 0);
				end
			end
			function tab:AddButton(name, func)
				tab.options.amount += 1;
				local button = {
					hovered = false,
					drawings = {},
				}
				-- drawings
				do
					button.drawings.base = createDrawing('Square', {
                                    Visible = false,
						Transparency = 0.5,
						Filled = true,
						Color = color3_fromrgb(0, 0, 0),
						Thickness = 1,

						Position = tab.drawings.base.Position + vector2_new(menuwidth + 10, tab.options.amount*15),
						Size = vector2_new(menuwidth, 15),
						ZIndex = 0;
					}, {library.alldrawings})
					button.drawings.text = createDrawing('Text', {
                                    Visible = false,
						Color = color3_fromrgb(255, 255, 255),
						Font = 1,
						Position = button.drawings.base.Position,
						Size = 14,
						Outline = true;
						Center = false;
						OutlineColor = color3_fromrgb(0, 0, 0);
						Transparency = 1,
						ZIndex = 1;
						Text = name or 'Button',
						ZIndex = 1;
					}, {library.alldrawings})
				end
				--functions 
				do
					button.press = function(boolean)
						if (not button.hovered or not tab.opened) then
							return;
						end;
						task.spawn(function()
							button.drawings.text.Color = color3_fromrgb(79, 79, 79);
							task.wait(0.05);
							button.drawings.text.Color = color3_fromrgb(255, 255, 255);
						end);
						task.spawn(func);
					end;
				end
				-- functionality / cleanup
				do
					library:dInput('Return', button.press)
					if (tab.options.amount == 1) then
						button.hovered = true;
						button.drawings.base.Color = color3_fromrgb(255, 0, 0);
					end
				end
				table_insert(tab.options.stored, button)
				return button;
			end;
			function tab:AddToggle(prop)
				tab.options.amount += 1;
				local toggle = {
					hovered = false,
					enabled = prop.default or false,
					flag = {
						value = prop.default or false,
					},
					callback = prop.callback or function() end,
					drawings = {},
				}
				-- flags
				do
					toggle.flag.Changed = function() end
					if (prop.flag) then
						function toggle.flag:OnChanged(func)
							toggle.flag.Changed = func;
							func(toggle.enabled);
						end
						flags[prop.flag] = toggle.flag
					end
				end
				-- drawings
				do
					toggle.drawings.base = createDrawing('Square', {
						Visible = false,
						Color = color3_fromrgb(0, 0, 0),
                                    Transparency = 0.5,
						Filled = true,
						Thickness = 1,
						Position = tab.drawings.base.Position + vector2_new(menuwidth + 10, tab.options.amount*15),
						Size = vector2_new(menuwidth, 15),
						ZIndex = 0;
					}, {library.alldrawings})
					toggle.drawings.text = createDrawing('Text', {
                                    Visible = false,
						Color = color3_fromrgb(255, 255, 255),
						Font = 1,
						Outline = true;
						Center = false;
						OutlineColor = color3_fromrgb(0, 0, 0);
						Position = toggle.drawings.base.Position,
						Size = 14,
						Text = prop.text or 'Toggle',
						Transparency = 1,
						ZIndex = 1;
					}, {library.alldrawings})
				end
				--functions 
				do
					toggle.toggle = function(boolean)
						if (not toggle.hovered or not tab.opened) then
							return;
						end
						if (boolean == nil) then
							boolean = not toggle.enabled;
						end
						toggle.enabled = boolean;
						toggle.flag.value = boolean
						toggle.flag.Changed(boolean)
						toggle.callback(boolean);
						if (boolean) then
							toggle.drawings.text.Color = color3_fromrgb(255, 255, 255);
							return; 
						end
						toggle.drawings.text.Color = color3_fromrgb(79, 79, 79);
					end;
					toggle.flag.setvalue = function(boolean)
						if (boolean == nil) then
							boolean = not toggle.enabled;
						end;
						toggle.enabled = boolean;
						toggle.flag.value = boolean
						toggle.flag.Changed(boolean)
						toggle.callback(boolean);
						if (boolean) then
							toggle.drawings.text.Color = color3_fromrgb(255, 255, 255);
							return; 
						end
						toggle.drawings.text.Color = color3_fromrgb(79, 79, 79);
					end;
				end
				-- functionality / cleanup
				do
					library:dInput('Return', toggle.toggle)
					if (toggle.enabled) then
						toggle.drawings.text.Color = color3_fromrgb(255, 255, 255); 
					else
						toggle.drawings.text.Color = color3_fromrgb(79, 79, 79);
					end
					if (tab.options.amount == 1) then
						toggle.hovered = true;
						toggle.drawings.base.Color = color3_fromrgb(255, 0, 0);
					end
				end
				table_insert(tab.options.stored, toggle)
				return toggle;
			end
			function tab:AddSlider(prop)
				tab.options.amount += 1
				local slider = {
					hovered = false,
					text = prop.text or 'Slider',
					value = prop.default or prop.min,
					suffix = prop.suffix or '',
					flag = {
						value = prop.default or prop.min,
					},
					callback = prop.callback or function() end,
					drawings = {},
				}
				-- flags
				do
					slider.flag.Changed = function() end
					if (prop.flag) then
						function slider.flag:OnChanged(func)
							slider.flag.Changed = func;
							func(slider.value)
						end
						flags[prop.flag] = slider.flag
					end
				end
				-- drawings
				do
					slider.drawings.base = createDrawing('Square', {
                                    Visible = false,
						Color = color3_fromrgb(0, 0, 0),
						Transparency = 0.5,
						Filled = true,
						Thickness = 1,
						Position = tab.drawings.base.Position + vector2_new(menuwidth + 10, tab.options.amount*15),
						Size = vector2_new(menuwidth, 15),
						ZIndex = 0;
					}, {library.alldrawings})
					slider.drawings.text = createDrawing('Text', {
                                    Visible = false,
						Text = '';
						Outline = true;
						Center = false;
						Color = color3_fromrgb(255, 255, 255),
						Font = 1,
						Position = slider.drawings.base.Position,
						Size = 14,
						OutlineColor = color3_fromrgb(0, 0, 0);
						Transparency = 1,
						ZIndex = 1;
					}, {library.alldrawings})
				end
				--functions 
				do
					slider.updatetext = function()
						slider.drawings.text.Text = slider.text..': '..slider.value..slider.suffix;
					end
					slider.increase = function()
						if (not slider.hovered or not tab.opened) then
							return;
						end;
                                    local index = 0;
                                    while true do -- yea fuck optimisation!;
                                          local val = slider.value + 1;
                                          if (val <= prop.max) then
                                                slider.value = val;
                                                slider.flag.value = val;
                                                slider.flag.Changed(val);
                                                slider.callback(val);
                                                slider.updatetext();
                                          end;
                                          index += 1;
                                          wait(math_max(0.7-(index/7), 0.05));
                                          if (not library.helddown.Right) then
                                                break;
                                          end;
                                    end;
					end;
					slider.decrease = function()
						if (not slider.hovered or not tab.opened) then
							return;
						end;

                                    local index = 0;
                                    while true do -- yea fuck optimisation!;
                                          local val = slider.value - 1;
                                          if (val >= prop.min) then
                                                slider.value = val;
                                                slider.flag.value = val;
                                                slider.flag.Changed(val);
                                                slider.callback(val);
                                                slider.updatetext();
                                          end;
                                          index += 1;
                                          wait(math_max(0.7-(index/7), 0.05));
                                          if (not library.helddown.Left) then
                                                break;
                                          end;
                                    end;
					end;
					slider.flag.setvalue = function(value)
						slider.value = value;
						slider.flag.value = value;
						slider.flag.Changed(value);
						slider.callback(value);
						slider.updatetext();
					end;
				end
				-- functionality / cleanup
				do
					slider.updatetext()

					library:dInput('Right', slider.increase);
					library:dInput('Left', slider.decrease);

					if (tab.options.amount == 1) then
						slider.hovered = true;
						slider.drawings.base.Color = color3_fromrgb(255, 0, 0);
					end
				end

				table_insert(tab.options.stored, slider)
				return slider;
			end;
                  function tab:AddDropdown(prop)
                        tab.options.amount += 1
				local dropdown = {
					hovered = false,
					text = prop.text or 'Dropdown',
					options = prop.options,
					value = prop.default or prop.options[1],
                              cycleindex = 1,
                              maxindex = #prop.options,
					flag = {
						value = prop.default or prop.options[1],
					},
					callback = prop.callback or function() end,
					drawings = {},
				};

                        -- flags
				do
					dropdown.flag.Changed = function() end;
					if (prop.flag) then
						function dropdown.flag:OnChanged(func)
							dropdown.flag.Changed = func;
							func(dropdown.value);
						end
						flags[prop.flag] = dropdown.flag;
					end;
				end;

                        -- drawings
                        do
                              dropdown.drawings.base = createDrawing('Square', {
                                    Visible = false,
						Color = color3_fromrgb(0, 0, 0),
						Transparency = 0.5,
						Filled = true,
						Thickness = 1,
						Position = tab.drawings.base.Position + vector2_new(menuwidth + 10, tab.options.amount*15),
						Size = vector2_new(menuwidth, 15),
						ZIndex = 0;
					}, {library.alldrawings})
					dropdown.drawings.text = createDrawing('Text', {
                                    Visible = false,
						Color = color3_fromrgb(255, 255, 255),
						Font = 1,
						Text = '';
						Outline = true;
						Center = false;
						Position = dropdown.drawings.base.Position,
						Size = 14,
						OutlineColor = color3_fromrgb(0, 0, 0);
						Transparency = 1,
						ZIndex = 1;
					}, {library.alldrawings})
                        end;

                        --functions 
				do
                              dropdown.setValue = function(value)
                                    dropdown.drawings.text.Text = `{dropdown.text}: {value}`;
                                    dropdown.value = value;
                                    dropdown.flag.value = value;
                                    dropdown.flag.Changed(value);
                                    dropdown.callback(value);
                              end;
                              dropdown.cycleRight = function()
                                    if (not dropdown.hovered or not tab.opened) then
							return;
						end;

                                    dropdown.cycleindex += 1;
                                    if (dropdown.cycleindex > dropdown.maxindex) then
                                          dropdown.cycleindex = 1;
                                    end;
                                    dropdown.setValue(dropdown.options[dropdown.cycleindex]);
                              end;
                              dropdown.cycleLeft = function()
                                    if (not dropdown.hovered or not tab.opened) then
							return;
						end;

                                    dropdown.cycleindex -= 1;
                                    if (dropdown.cycleindex < 1) then
                                          dropdown.cycleindex = dropdown.maxindex;
                                    end;
                                    dropdown.setValue(dropdown.options[dropdown.cycleindex]);
                              end;
                              dropdown.flag.setvalue = dropdown.setValue;
                        end;

                        -- functionality / cleanup
				do
                              dropdown.cycleindex = table_find(dropdown.options, dropdown.value);
                              dropdown.setValue(dropdown.value);

                              library:dInput('Right', dropdown.cycleRight);
					library:dInput('Left', dropdown.cycleLeft);
                              
                              if (tab.options.amount == 1) then
						dropdown.hovered = true;
						dropdown.drawings.base.Color = color3_fromrgb(255, 0, 0);
					end;
                        end;

                        table_insert(tab.options.stored, dropdown);
                        return dropdown;
                  end;
		end
		-- functionality / cleanup
		do
			tab:hovered_(hovered);
			library:dInput('Up', tab.navUp);
			library:dInput('Down', tab.navDown);
		end
		table_insert(library.tabinfo.tabs, tab);
		return tab;
	end
end
library.whitelist = {};
_G.amonguslib_loaded = true;

return library, flags;
