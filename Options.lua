--- @type RotationHelper RotationHelper
local _, RotationHelper = ...;

---@type StdUi
local StdUi = LibStub('StdUi');
local media = LibStub('LibSharedMedia-3.0');


RotationHelper.Textures = {
	{text = 'Ping', value = 'Interface\\Cooldown\\ping4'},
	{text = 'Star', value = 'Interface\\Cooldown\\star4'},
	{text = 'Starburst', value = 'Interface\\Cooldown\\starburst'},
};
RotationHelper.FinalTexture = nil;

RotationHelper.Colors = {
	Info = '|cFF1394CC',
	Error = '|cFFF0563D',
	Success = '|cFFBCCF02',
}

RotationHelper.Classes = {
	[1] = 'Warrior',
	[2] = 'Paladin',
	[3] = 'Hunter',
	[4] = 'Rogue',
	[5] = 'Priest',
	[6] = 'DeathKnight',
	[7] = 'Shaman',
	[8] = 'Mage',
	[9] = 'Warlock',
	[10] = 'Monk',
	[11] = 'Druid',
	[12] = 'DemonHunter',
}

RotationHelper.defaultOptions = {
	global = {
		enabled = true,
		disabledInfo = true,
		debugMode = false,
		forceSingle = false,
		onCombatEnter = false,
		interval = 0.15,
		sizeMultiplier = 1
	}
};

function RotationHelper:ResetSettings()
	self.db:ResetDB();
end

function RotationHelper:AddToBlizzardOptions()
	if self.optionsFrame then
		return
	end

	local optionsFrame = StdUi:PanelWithTitle(UIParent, 100, 100, 'RotationHelper Options');
	self.optionsFrame = optionsFrame;
	optionsFrame:Hide();
	optionsFrame.name = 'RotationHelper';

	StdUi:EasyLayout(optionsFrame, { padding = { top = 40 } });

	local reset = StdUi:Button(optionsFrame, 120, 24, 'Reset Options');
	reset:SetScript('OnClick', function() RotationHelper:ResetSettings(); end);

	--- GENERAL options

	local general = StdUi:Label(optionsFrame, 'General', 14);
	StdUi:SetTextColor(general, 'header');

	local enabled = StdUi:Checkbox(optionsFrame, 'Enable addon', 200, 24);
	enabled:SetChecked(RotationHelper.db.global.enabled);
	enabled.OnValueChanged = function(_, flag) RotationHelper.db.global.enabled = flag; end;

	local onCombatEnter = StdUi:Checkbox(optionsFrame, 'Enable upon entering combat', 200, 24);
	onCombatEnter:SetChecked(RotationHelper.db.global.onCombatEnter);
	onCombatEnter.OnValueChanged = function(_, flag) RotationHelper.db.global.onCombatEnter = flag; end;

	local forceSingle = StdUi:Checkbox(optionsFrame, 'Force single target mode', 200, 24);
	forceSingle:SetChecked(RotationHelper.db.global.forceSingle);
	forceSingle.OnValueChanged = function(_, flag) RotationHelper.db.global.forceSingle = flag; end;

	local disableConsumables = StdUi:Checkbox(optionsFrame, 'Disable consumable support', 200, 24);
	disableConsumables:SetChecked(RotationHelper.db.global.disableConsumables);
	disableConsumables.OnValueChanged = function(_, flag) RotationHelper.db.global.disableConsumables = flag; end;

	local interval = StdUi:SliderWithBox(optionsFrame, 100, 48, RotationHelper.db.global.interval, 0.01, 2);
	interval:SetPrecision(2);
	StdUi:AddLabel(optionsFrame, interval, 'Update Interval');
	interval.OnValueChanged = function(_, val) RotationHelper.db.global.interval = val; end;

	--- Debug options

	local debug = StdUi:Label(optionsFrame, 'Debug options', 14);
	StdUi:SetTextColor(debug, 'header');

	local debugMode = StdUi:Checkbox(optionsFrame, 'Enable debug mode', 200, 24);
	debugMode:SetChecked(RotationHelper.db.global.debugMode);
	debugMode.OnValueChanged = function(_, flag) RotationHelper.db.global.debugMode = flag; end;

	local disabledInfo = StdUi:Checkbox(optionsFrame, 'Enable info messages', 200, 24);
	disabledInfo:SetChecked(not RotationHelper.db.global.disabledInfo);
	disabledInfo.OnValueChanged = function(_, flag) RotationHelper.db.global.disabledInfo = not flag; end;

	--- UI layout

	optionsFrame:AddRow():AddElement(general);
	optionsFrame:AddRow():AddElements(enabled, onCombatEnter, { column = 'even' });
	optionsFrame:AddRow():AddElements(disableConsumables, forceSingle, {column = 'even'});
	optionsFrame:AddRow():AddElements(interval, {column = 'even'});
	optionsFrame:AddRow():AddElements(debug, {column = 'even'});
	optionsFrame:AddRow():AddElements(debugMode, disabledInfo, { column = 'even' });

	optionsFrame:SetScript('OnShow', function(of)
		of:DoLayout();
	end);

	InterfaceOptions_AddCategory(optionsFrame);
end
