libQuest = {
	Title = "libQuest",
	Author = "Ek1",
	Description = "Libary for other add-on's to get quest data.",
	Version = "190508",
	VariableVersion = "1",
	License = "BY-SA = Creative Commons Attribution-ShareAlike 4.0 International License",
	URL = "https://github.com/Ek1/libQuest"
}
-- Tables about quest thats questI's are know
--local shareableQuestsIds = {questId, questName, zoneIds = {}, questStarters = {}, questRecipients = {} }
--local soloQuestsIds = {questId, questName, zoneIds = {}, questStarters = {}, questRecipients = {} }
--local craftingQuestsIds = {questId, questName, zoneIds = {}, questStarters = {}, questRecipients = {} }
local shareableQuestsIds, soloQuestsIds, craftingQuestsIds = {}

-- Work table where quests with unknown questI's are collected.
local questsIdsUnknown = {questName, questType, zoneIds = {}, questStarters = {}, questRecipients = {}, shareable = false}

--[[
Järjestys millä questeja voi tulla ja miten niitä ratkotaan.

NPC tai toinen pelaaja tarjoaa questin
]]

-- GetZoneId(GetUnitZoneIndex("player"))     antaa nykysen zoneIDn



EVENT_QUEST_SHARED (number eventCode, number questId)


OnQuestShared(eventCode, questId)



-- Trigger for added quest, note that quest can be also gained by sharing
function libQuest.EVENT_QUEST_ADDED(eventCode, addedToJournalIndex, addedQuestName, objectiveName)
	d( ADDON.Title .. ":EVENT_QUEST_ADDED " .. addedQuestName .. "  objectiveName:" .. objectiveName .. " to jouranlIndex " ..  journalIndex)

	if not questsIdsUnknown[addedQuestName] then
		questsIdsUnknown.[questName] = addedQuestName
		questsIdsUnknown.questType[GetJournalQuestType(addedToJournalIndex)]
		
		
	if not table.contains (questsIdsUnknown, questName) then
		table.insert (questsIdsUnknown, questName)
	end
end
	
--	questsIdsUnknown.insert (shareable, addedQuestName)
	
--	GetIsQuestSharable(number journalQuestIndex)
--	Returns: boolean isSharable


-- GetZoneId(GetUnitZoneIndex("player"))     antaa nykysen zoneIDn	

--- jos oli jaettavissa niin jaettuuihin questeihin, jos ei niin solo questeihin

end

EVENT_QUEST_ADVANCED (number eventCode, number journalIndex, string questName, boolean isPushed, boolean isComplete, boolean mainStepChanged)


-- EVENT_QUEST_COMPLETE (number eventCode, string questName, number level, number previousExperience, number currentExperience, number championPoints, QuestType questType, InstanceDisplayType instanceDisplayType)
function libQuest.EVENT_QUEST_COMPLETE (eventCode, questName, level, previousExperience, currentExperience, championPoints, questType, instanceDisplayType)
	d( ADDON.Title .. ":EVENT_QUEST_SHARE_REMOVED questID:" .. numberQuestId)
-- GetZoneId(GetUnitZoneIndex("player"))     antaa nykysen zoneIDn

end


-- EVENT_QUEST_REMOVED (number eventCode, boolean isCompleted, number journalIndex, string questName, number zoneIndex, number poiIndex, number questID)
function libQuest.EVENT_QUEST_REMOVED(eventCode, isCompleted, journalIndex, questName, zoneIndex, poiIndex, questID)
	d( ADDON.Title .. ":EVENT_QUEST_REMOVED questName:" .. questName .. " zoneIndex:" .. zoneIndex .. " poiIndex:" .. poiIndex .. " questID:" .. questID)
end

-- Questi lisätään jouranliin 
-- GetJournalQuestType(number journalQuestIndex)
-- Returns: number QuestType type



-- Lets fire up the add-on by registering for events and loading variables
function libQuest.Initialize()
	EVENT_MANAGER:RegisterForEvent(libQuest.Title, EVENT_QUEST_SHARED,	libQuest.EVENT_QUEST_SHARED)
	EVENT_MANAGER:RegisterForEvent(libQuest.Title, EVENT_QUEST_ADDED,	libQuest.EVENT_QUEST_ADDED)
	EVENT_MANAGER:RegisterForEvent(libQuest.Title, EVENT_QUEST_ADVANCED,	libQuest.EVENT_QUEST_ADVANCED)
	EVENT_MANAGER:RegisterForEvent(libQuest.Title, EVENT_QUEST_COMPLETE,	libQuest.EVENT_QUEST_COMPLETE)
	EVENT_MANAGER:RegisterForEvent(libQuest.Title, EVENT_QUEST_REMOVED,	libQuest.EVENT_QUEST_REMOVED)

	d( libQuest.Title .. ": initalization done")
end

-- Variable to keep count how many loads have been done before it was this ones turn.
local loadOrder = 0
function libQuest.OnAddOnLoaded(event, addonName)
  if addonName == libQuest.Title then
--	Seems it is our time so lets stop listening load trigger and initialize the add-on
	d( libQuest.Title .. ": load order " ..  loadOrder .. ", starting initalization")
	EVENT_MANAGER:UnregisterForEvent(libQuest.Title, EVENT_ADD_ON_LOADED)
	libQuest.Initialize()
  end
  loadOrder = loadOrder+1
end

-- Registering the addon's initializing event when add-on's are loaded 
EVENT_MANAGER:RegisterForEvent(libQuest.Title, EVENT_ADD_ON_LOADED, libQuest.OnAddOnLoaded)