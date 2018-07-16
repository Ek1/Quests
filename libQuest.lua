libQuest = {
	Title = "libQuest",
	Author = "Ek1",
	Description = "Libary for other add-on's to get quest data and to have an hook for questId's.",
	Version = "18.07.17",
	License = "BY-SA = Creative Commons Attribution-ShareAlike 4.0 International License"
}
local ADDON_NAME = "libQuest"
local sharable_quests = {}
local solo_quests = {}
local active_quests = {}

-- EVENT_QUEST_ADDED (number eventCode, number journalIndex, string questName, string objectiveName)
local function libQuest.added(eventCode, journalIndex, questName, objectiveName)
	d( libQuest.Version .. " EVENT_QUEST_ADDED " .. questName  )
	d( libQuest.Version .. " EVENT_QUEST_ADDED " .. objectiveName )
	end
-- Registering the funktion to the event manager
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_QUEST_ADDED, libQuest.added)

--[[
-- EVENT_QUEST_ADVANCED (number eventCode, number journalIndex, string questName, boolean isPushed, boolean isComplete, boolean mainStepChanged)
function libQuest.advanced(_, journalIndex, questName, isPushed, isComplete, mainStepChanged)
	d( libQuest.Version .. "EVENT_QUEST_ADVANCED " .. journalIndex )
	d( libQuest.Version .. "EVENT_QUEST_ADVANCED " .. questName)
	if isPushed then d( libQuest.Version .. "EVENT_QUEST_ADVANCED isPushed " ) end
	d( libQuest.Version .. "EVENT_QUEST_ADVANCED " .. tostring(isComplete))
	if isComplete then d( libQuest.Version .. "EVENT_QUEST_ADVANCED isComplete " ) end
	if mainStepChanged then d( libQuest.Version .. "EVENT_QUEST_ADVANCED mainStepChanged " ) end
end
-- Registering the funktion to the event manager
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_QUEST_ADVANCED, libQuest.advanced)

-- EVENT_QUEST_COMPLETE (number eventCode, string questName, number level, number previousExperience, number currentExperience, number championPoints, QuestType questType, InstanceDisplayType instanceDisplayType)
function libQuest.valmis(_, questName, _, _, _, _, questType, instanceDisplayType)
	d(" EVENT_QUEST_COMPLETE " .. questName .. questType .. instanceDisplayType )
end
-- Registering the funktion to the event manager
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_QUEST_COMPLETE, libQuest.valmis)
]]--.

-- EVENT_QUEST_REMOVED (number eventCode, boolean isCompleted, number journalIndex, string questName, number zoneIndex, number poiIndex, number questID)
function libQuest.poistettu(eventCode, isCompleted, journalIndex, questName, zoneIndex, poiIndex, questID)
	d( libQuest.Version .. " EVENT_QUEST_REMOVED questName:" .. questName .. " zoneIndex:" .. zoneIndex .. " poiIndex:" .. poiIndex .. " questID:" .. questID)
end
-- Registering the funktion to the event manager
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_QUEST_REMOVED, libQuest.poistettu)

-- EVENT_QUEST_SHARE_REMOVED (number eventCode, number questId)
function libQuest.EVENT_QUEST_SHARE_REMOVED(numberEventCode, numberQuestId)
	d( libQuest.Version .. " EVENT_QUEST_SHARE_REMOVED questID:" .. numberQuestId)
end
-- Registering the funktion to the event manager
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_QUEST_SHARE_REMOVED, libQuest.EVENT_QUEST_SHARE_REMOVED)

--[[
EVENT_QUEST_SHARED (number eventCode, number questId)

EVENT_QUEST_SHARE_REMOVED (number eventCode, number questId)


EVENT_ACTIVE_QUEST_TOOL_CHANGED (number eventCode, number journalIndex, number toolIndex)
EVENT_ACTIVE_QUEST_TOOL_CLEARED (number eventCode)
EVENT_HIDE_OBJECTIVE_STATUS (number eventCode)
EVENT_MOUSE_REQUEST_ABANDON_QUEST (number eventCode, number journalIndex, string name)

EVENT_QUEST_ADDED (number eventCode, number journalIndex, string questName, string objectiveName)

EVENT_QUEST_ADVANCED (number eventCode, number journalIndex, string questName, boolean isPushed, boolean isComplete, boolean mainStepChanged)

EVENT_QUEST_COMPLETE (number eventCode, string questName, number level, number previousExperience, number currentExperience, number championPoints, QuestType questType, InstanceDisplayType instanceDisplayType)

EVENT_QUEST_COMPLETE_ATTEMPT_FAILED_INVENTORY_FULL (number eventCode)
EVENT_QUEST_COMPLETE_DIALOG (number eventCode, number journalIndex)
EVENT_QUEST_CONDITION_COUNTER_CHANGED (number eventCode, number journalIndex, string questName, string conditionText, QuestConditionType conditionType, number currConditionVal, number newConditionVal, number conditionMax, boolean isFailCondition, string stepOverrideText, boolean isPushed, boolean isComplete, boolean isConditionComplete, boolean isStepHidden)
EVENT_QUEST_LIST_UPDATED (number eventCode)
EVENT_QUEST_LOG_IS_FULL (number eventCode)
EVENT_QUEST_OFFERED (number eventCode)
EVENT_QUEST_OPTIONAL_STEP_ADVANCED (number eventCode, string text)
EVENT_QUEST_POSITION_REQUEST_COMPLETE (number eventCode, number taskId, MapDisplayPinType pinType, number xLoc, number yLoc, number areaRadius, boolean insideCurrentMapWorld, boolean isBreadcrumb)
EVENT_QUEST_REMOVED (number eventCode, boolean isCompleted, number journalIndex, string questName, number zoneIndex, number poiIndex, number questID)
EVENT_QUEST_SHARED (number eventCode, number questId)
EVENT_QUEST_SHARE_REMOVED (number eventCode, number questId)
EVENT_QUEST_SHOW_JOURNAL_ENTRY (number eventCode, number journalIndex)
EVENT_QUEST_TIMER_PAUSED (number eventCode, number journalIndex, boolean isPaused)
EVENT_QUEST_TIMER_UPDATED (number eventCode, number journalIndex)
EVENT_QUEST_TOOL_UPDATED (number eventCode, number journalIndex, string questName, number countDelta, string iconFilename, number questItemId, string name)
EVENT_OBJECTIVES_UPDATED (number eventCode)
EVENT_OBJECTIVE_COMPLETED (number eventCode, number zoneIndex, number poiIndex, number level, number previousExperience, number currentExperience, number championPoints)
EVENT_OBJECTIVE_CONTROL_STATE (number eventCode, number objectiveKeepId, number objectiveObjectiveId, number battlegroundContext, string objectiveName, ObjectiveType objectiveType, ObjectiveControlEvent objectiveControlEvent, ObjectiveControlState objectiveControlState, number objectiveParam1, number objectiveParam2, MapDisplayPinType pinType)
EVENT_SCRIPTED_WORLD_EVENT_INVITE (number eventCode, number eventId, string scriptedEventName, string inviterName, string questName)
EVENT_SCRIPTED_WORLD_EVENT_INVITE_REMOVED (number eventCode, number eventId)
EVENT_TRACKING_UPDATE (number eventCode)
]]--