local addonName, Addon = ...

local function CopyTable(source)
    local result = {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            result[key] = CopyTable(value)
        else
            result[key] = value
        end
    end
    return result
end

local function ApplyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = type(value) == "table" and CopyTable(value) or value
        elseif type(value) == "table" and type(target[key]) == "table" then
            ApplyDefaults(target[key], value)
        end
    end
end

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

-- Some client forks (e.g. non-retail/mixed-API flavors such as "Forever")
-- may not register the BackdropTemplate mixin that retail has required
-- since 8.0. On such clients SetBackdrop is built into the base Frame
-- mixin instead, so creating the frame without the template still works.
function Addon:CreateBackdropFrame(frameType, name, parent, inherits)
    local backdropInherits = inherits and (inherits .. ",BackdropTemplate") or "BackdropTemplate"
    local ok, frame = pcall(CreateFrame, frameType, name, parent, backdropInherits)
    if ok then
        return frame
    end
    return CreateFrame(frameType, name, parent, inherits)
end

-- C_Timer is a relatively recent (MoP+) global. Fall back to an
-- OnUpdate-driven ticker so delayed actions still work on clients that
-- lack it.
function Addon:After(delay, callback)
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, callback)
        return
    end

    local ticker = CreateFrame("Frame")
    local elapsed = 0
    ticker:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= delay then
            ticker:SetScript("OnUpdate", nil)
            callback()
        end
    end)
end

function Addon:InitializeDatabase()
    EmoteRingDB = EmoteRingDB or {}
    local legacySlots = type(EmoteRingDB.slots) == "table" and CopyTable(EmoteRingDB.slots) or nil
    local previousSchema = tonumber(EmoteRingDB.schemaVersion) or 0
    ApplyDefaults(EmoteRingDB, self.defaults)
    self.db = EmoteRingDB

    if legacySlots and previousSchema < 2 then
        for index = 1, 8 do
            if self.catalogByID[legacySlots[index]] then
                self.db.layouts[1].slots[index] = legacySlots[index]
            end
        end
    end

    self.db.schemaVersion = 2
    self.db.defaultLayout = math.max(1, math.min(4, tonumber(self.db.defaultLayout) or 1))
    for layoutIndex = 1, 4 do
        local layout = self.db.layouts[layoutIndex]
        layout.name = strtrim(tostring(layout.name or ""))
        if layout.name == "" then
            layout.name = self.defaults.layouts[layoutIndex].name
        end
        for slotIndex = 1, 8 do
            if not self.catalogByID[layout.slots[slotIndex]] then
                layout.slots[slotIndex] = self.defaults.layouts[layoutIndex].slots[slotIndex]
            end
        end
    end

    self.db.ringScale = math.max(0.75, math.min(1.35, tonumber(self.db.ringScale) or 1))
    self.db.minimapAngle = tonumber(self.db.minimapAngle) or 220
    self.activeLayout = self.db.defaultLayout
    self.optionsLayout = self.db.defaultLayout
end

function Addon:ResetDatabase()
    EmoteRingDB = CopyTable(self.defaults)
    self.db = EmoteRingDB
    self.activeLayout = self.db.defaultLayout
    self.optionsLayout = self.db.defaultLayout

    if self.RefreshRing then
        self:RefreshRing()
    end
    if self.RefreshOptions then
        self:RefreshOptions()
    end
    if self.UpdateMinimapButton then
        self:UpdateMinimapButton()
    end
end

function Addon:GetLayout(layoutIndex)
    if not self.db or not self.db.layouts then
        return nil
    end
    return self.db.layouts[layoutIndex or self.activeLayout or self.db.defaultLayout or 1]
end

function Addon:GetEntry(slotIndex, layoutIndex)
    local layout = self:GetLayout(layoutIndex)
    return layout and self.catalogByID[layout.slots[slotIndex]] or nil
end

function Addon:SetActiveLayout(layoutIndex)
    layoutIndex = math.max(1, math.min(4, tonumber(layoutIndex) or 1))
    if self.activeLayout == layoutIndex then
        return
    end
    self.activeLayout = layoutIndex
    if self.RefreshRing then
        self:RefreshRing()
    end
end

function Addon:MoveSlot(layoutIndex, slotIndex, direction)
    local layout = self:GetLayout(layoutIndex)
    if not layout then
        return
    end
    local other = slotIndex + direction
    if other < 1 or other > 8 then
        return
    end
    layout.slots[slotIndex], layout.slots[other] = layout.slots[other], layout.slots[slotIndex]
    self:RefreshRing()
    self:RefreshOptions()
end

function Addon:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffc44dEmoteRing:|r " .. tostring(message))
end

function Addon:PlayUISound(soundID)
    if self.db and self.db.playSounds and soundID then
        PlaySound(soundID, "SFX")
    end
end

function Addon:GetPrettyBinding()
    local first, second = GetBindingKey("CLICK EmoteRingBindingButton:LeftButton")
    if not first then
        first, second = GetBindingKey("EMOTERING_OPEN")
    end
    if not first then
        return self.L.NOT_BOUND
    end

    local text = GetBindingText(first, "KEY_", 1)
    if second then
        text = text .. " / " .. GetBindingText(second, "KEY_", 1)
    end
    return text
end

function Addon:CreateSecureBindingButton()
    if self.bindingButton then
        return
    end

    local button = CreateFrame("Button", "EmoteRingBindingButton", UIParent, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyDown", "AnyUp")
    button:SetAttribute("type", "macro")
    button:SetAttribute("macrotext", "")

    button:SetScript("PreClick", function(self, _, down)
        if not down then
            if not InCombatLockdown() then
                if self.secureMouseoverLocked then
                    self:SetAttribute("macrotext", self.pendingHadTarget and "/targetlasttarget" or "/cleartarget")
                else
                    self:SetAttribute("macrotext", "")
                end
            end

            -- PreClick runs before the secure restore macro. Execute the
            -- selected emote now while the secured mouseover is still target.
            Addon:ReleaseRing(true)
            return
        end

        if InCombatLockdown() then
            return
        end

        self.secureMouseoverLocked = nil
        self.pendingMouseoverGUID = nil
        self.pendingMouseoverName = nil
        self.pendingHadTarget = nil

        if Addon.db.preferMouseover and UnitExists("mouseover") then
            local mouseoverGUID = UnitGUID("mouseover")
            local mouseoverName = UnitName("mouseover")
            local currentGUID = UnitGUID("target")
            if not IsSecret(mouseoverGUID) and not IsSecret(mouseoverName)
                and mouseoverGUID ~= currentGUID then
                self.pendingMouseoverGUID = mouseoverGUID
                self.pendingMouseoverName = mouseoverName
                self.pendingHadTarget = UnitExists("target") and true or false
                self:SetAttribute("macrotext", "/target [@mouseover,exists]")
            end
        end
    end)

    button:SetScript("PostClick", function(self, _, down)
        if down then
            Addon:OpenRing(false)

            if self.pendingMouseoverGUID and Addon.ring then
                local targetGUID = UnitGUID("target")
                if not IsSecret(targetGUID) and targetGUID == self.pendingMouseoverGUID then
                    self.secureMouseoverLocked = true
                    Addon.ring.subjectGUID = self.pendingMouseoverGUID
                    Addon.ring.subjectName = self.pendingMouseoverName
                    Addon.ring.subjectState = {
                        locked = true,
                        hadTarget = self.pendingHadTarget,
                    }
                    if Addon.db.showTarget then
                        Addon.ring.targetText:SetText(Addon.L.TARGET:format(self.pendingMouseoverName))
                    end
                end
            end

        else
            if not InCombatLockdown() then
                self:SetAttribute("macrotext", "")
            end
            self.secureMouseoverLocked = nil
            self.pendingMouseoverGUID = nil
            self.pendingMouseoverName = nil
            self.pendingHadTarget = nil
        end
    end)

    self.bindingButton = button
    self:MigrateLegacyBinding()
end

function Addon:MigrateLegacyBinding()
    if InCombatLockdown() or not self.bindingButton then
        return false
    end

    local first, second = GetBindingKey("EMOTERING_OPEN")
    if not first and not second then
        return true
    end

    if first then
        SetBinding(first)
        SetBindingClick(first, "EmoteRingBindingButton", "LeftButton")
    end
    if second then
        SetBinding(second)
        SetBindingClick(second, "EmoteRingBindingButton", "LeftButton")
    end
    SaveBindings(GetCurrentBindingSet())
    return not GetBindingKey("EMOTERING_OPEN")
end

function Addon:CaptureSubject()
    local unit
    if self.db.preferMouseover and UnitExists("mouseover") then
        unit = "mouseover"
    elseif UnitExists("target") then
        unit = "target"
    elseif UnitExists("mouseover") then
        unit = "mouseover"
    end

    if not unit then
        return nil, nil, nil
    end

    local guid = UnitGUID(unit)
    local name = UnitName(unit)
    if IsSecret(guid) or IsSecret(name) then
        return nil, nil, nil
    end
    return guid, name, unit
end

function Addon:LockMouseoverSubject(unit, guid)
    -- Protected targeting is handled exclusively by the secure binding
    -- button and never from ordinary addon Lua.
    return nil
end

function Addon:RestoreMouseoverSubject(state)
    if not state or not state.locked or InCombatLockdown() then
        return
    end

    if state.hadTarget and TargetLastTarget then
        TargetLastTarget()
    elseif not state.hadTarget and ClearTarget then
        ClearTarget()
    end
end

function Addon:ResolveSubjectUnit(guid)
    if not guid then
        return nil
    end

    if UnitTokenFromGUID then
        local unit = UnitTokenFromGUID(guid)
        if unit and UnitExists(unit) then
            return unit
        end
    end

    local commonUnits = { "target", "mouseover", "focus", "softenemy", "softfriend" }
    for _, unit in ipairs(commonUnits) do
        local unitGUID = UnitGUID(unit)
        if not IsSecret(unitGUID) and unitGUID == guid then
            return unit
        end
    end

    for index = 1, 40 do
        local unit = "nameplate" .. index
        local unitGUID = UnitGUID(unit)
        if not IsSecret(unitGUID) and unitGUID == guid then
            return unit
        end
    end

    return nil
end

function Addon:PerformEntry(entry, subjectGUID)
    if not entry then
        return
    end

    if entry.action == "AFK" then
        if UnitIsAFK("player") then
            SendChatMessage("", "AFK")
        else
            SendChatMessage(GetLocale() == "deDE" and "Bin kurz weg." or "Away for a moment.", "AFK")
        end
        return
    elseif entry.action == "DND" then
        if UnitIsDND("player") then
            SendChatMessage("", "DND")
        else
            SendChatMessage(GetLocale() == "deDE" and "Bitte nicht stören." or "Please do not disturb.", "DND")
        end
        return
    end

    local currentTargetGUID = UnitGUID("target")
    if subjectGUID and not IsSecret(currentTargetGUID) and currentTargetGUID == subjectGUID then
        -- Omitting the unit is the most reliable way to address the current
        -- target, especially for NPC targets.
        DoEmote(entry.token)
        return
    end

    local unit = self:ResolveSubjectUnit(subjectGUID)
    if unit then
        DoEmote(entry.token, unit)
    else
        DoEmote(entry.token, "none")
    end
end

function Addon:OpenOptions()
    if self.settingsCategory and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(self.settingsCategory:GetID())
    elseif self.optionsPanel and InterfaceOptionsFrame_OpenToCategory then
        -- Legacy (pre-Dragonflight) options API, kept as a fallback for
        -- clients without the modern Settings namespace. Blizzard's own
        -- UI needs this call twice to focus the category reliably.
        InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
    else
        self:Print("/ering")
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        Addon:InitializeDatabase()
        Addon:CreateRing()
        Addon:CreateSecureBindingButton()
        Addon:CreateOptions()
        Addon:CreateMinimapButton()

        SLASH_EMOTERING1 = "/emotering"
        SLASH_EMOTERING2 = "/ering"
        SlashCmdList.EMOTERING = function(message)
            message = strtrim(message or ""):lower()
            if message == "reset" then
                Addon:ResetDatabase()
                Addon:Print(GetLocale() == "deDE" and "Einstellungen zurückgesetzt." or "Settings reset.")
            elseif message == "test" then
                Addon:OpenRing(true)
            else
                Addon:OpenOptions()
            end
        end
    elseif event == "PLAYER_LOGIN" then
        Addon:MigrateLegacyBinding()
        Addon:After(1, function()
            Addon:MigrateLegacyBinding()
            Addon:RefreshOptions()
        end)
    elseif event == "PLAYER_LOGOUT" then
        EmoteRingDB = Addon.db
    end
end)

function EmoteRing_OnBinding(keyState)
    if not Addon.db or not Addon.ring then
        return
    end

    local isDown = keyState == "down" or keyState == true or keyState == 1
    if isDown then
        if not InCombatLockdown() and Addon:MigrateLegacyBinding() then
            if not Addon.legacyMigrationNotice then
                Addon.legacyMigrationNotice = true
                Addon:Print(Addon.L.BINDING_MIGRATED)
            end
            return
        end
        Addon:OpenRing(false)
    else
        Addon:ReleaseRing()
    end
end
