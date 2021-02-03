--- @type RotationHelper RotationHelper
local _, RotationHelper = ...;

local TableInsert = tinsert;

RotationHelper.Spells = {};
RotationHelper.SpellFrames = {};

local LABs = {
	['LibActionButton-1.0'] = true,
	['LibActionButton-1.0-ElvUI'] = true,
};

local bfaConsumables = {
	[169299] = true, -- Potion of Unbridled Fury
	[168529] = true, -- Potion of Empowered Proximity
	[168506] = true, -- Potion of Focused Resolve
	[168489] = true, -- Superior Battle Potion of Agility
	[168498] = true, -- Superior Battle Potion of Intellect
	[168500] = true, -- Superior Battle Potion of Strength
	[163223] = true, -- Battle Potion of Agility
	[163222] = true, -- Battle Potion of Intellect
	[163224] = true, -- Battle Potion of Strength
	[152559] = true, -- Potion of Rising Death
	[152560] = true, -- Potion of Bursting Blood
};

local slConsumables = {
   -- TODO: implement
};

local CooldownType = {
   MAJOR = 1,
   MINOR = 2,
   OPTIONAL = 3,
};

local nextOverlayId = 0;

local reference = {
   x = -150,
   y = -40,
};

local offsets = {
   [1] = 0,
   [2] = -47,
   [3] = -84,
};

local abilityBounds = {
   [1] = {
      x = reference.x + offsets[1],
      y = reference.y,
      width = 50,
      height = 50,
   },
   [2] = {
      x = reference.x + offsets[2],
      y = reference.y,
      width = 40,
      height = 40,
   },
   [3] = {
      x = reference.x + offsets[3],
      y = reference.y,
      width = 30,
      height = 30,
   },
};

function RotationHelper:CreateOverlay()
   local id = nextOverlayId;
   nextOverlayId = nextOverlayId + 1;
   local frame = CreateFrame('Frame', 'RotationHelper_Overlay_' .. id, UIParent);
   frame:SetFrameStrata('HIGH');
   return frame;
end

--- Creates frame overlay over a specific frame, it doesn't need to be a button.
-- @param id - string id of overlay because frame can have multiple overlays
-- @param texture - optional custom texture
-- @param bounds - x/y/width/height of the frame
function RotationHelper:UpdateOverlay(frame, text, texture, bounds, color)
	local sizeMult = self.db.global.sizeMultiplier or 1;
   frame:SetPoint('CENTER', bounds.x, bounds.y);
	frame:SetWidth(bounds.width * sizeMult);
	frame:SetHeight(bounds.height * sizeMult);

	local frameTexture = frame.texture;
	if (frameTexture) then
		frameTexture:SetTexture(texture);
   else
		frameTexture = frame:CreateTexture('GlowOverlay', 'OVERLAY');
		frameTexture:SetTexture(texture);
      frame.texture = frameTexture;
   end
   frameTexture:SetAllPoints(frame);

   local frameText = frame.text;
   if (text) then
      if (not frameText) then
         local y = -(bounds.height / 2) - 10;
         frameText = frame:CreateFontString('GlowText', 'ARTWORK');
         frameText:SetFont('Fonts\\ARIALN.ttf', 14, 'OUTLINE');
         frameText:SetPoint('CENTER', 0, y);
         frame.text = frameText;
      end
      frameText:SetText(text);
   elseif (frameText) then
      frameText:SetText('');
   end

	if (color) then
		frameTexture:SetVertexColor(color.r, color.g, color.b, color.a);
	end
end

function RotationHelper:HideAllOverlays()
	for key, frameHolder in pairs(self.SpellFrames) do
		frameHolder.overlay:Hide();
	end
end

function RotationHelper:FindSpell(spellId)
	return self.Spells[spellId];
end

function RotationHelper:GlowConsumables(fd)
   if (fd.recurseIndex == 1 and (not self.db.global.disableConsumables)) then
      for itemId, _ in pairs(bfaConsumables) do
         local itemSpellId = self.ItemSpells[itemId];

         if itemSpellId then
            self:GlowCooldown(itemSpellId, self:ItemCooldown(itemId, 0).ready, CooldownType.OPTIONAL);
         end
      end
	end
end

function RotationHelper:GlowEssences(fd)
   if (fd.recurseIndex == 1 and fd.essences.major) then
      RotationHelper:GlowCooldown(fd.essences.major, fd.cooldown[fd.essences.major].ready, CooldownType.MINOR);
	end
end

function RotationHelper:GlowCooldown(spellId, condition, cdType)
   if (not cdType) then
      cdType = CooldownType.MAJOR;
   end

   -- TODO: implement
end

function RotationHelper:GlowSpell(index, spellId)
   if (spellId) then
      local bounds = abilityBounds[index];
      if (bounds) then
         local current = self.SpellFrames[index];
         if (not current) then
            current = {};
            current.overlay = self:CreateOverlay();
            self.SpellFrames[index] = current;
         end

         if (current.spellId ~= spellId) then
            current.spellId = spellId;
            local name, _, icon, _, _, _, _ = GetSpellInfo(spellId);

            if (not RotationHelper.db.global.debugMode) then
               name = nil;
            end

            self:UpdateOverlay(current.overlay, name, icon, bounds);
            current.overlay:Show();
         end
      end
   else
      RotationHelper:GlowClear(index);
   end
end

function RotationHelper:GlowClear(index)
   local current = self.SpellFrames[index];
   if (current and current.spellId) then
      current.spellId = nil;
      current.overlay:Hide();
   end
end
