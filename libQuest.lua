libQuest = {
	TITLE = "libQuest",	-- Not codereview friendly but enduser friendly version of the add-on's name
	AUTHOR = "Ek1",
	DESCRIPTION = "Libary for other add-on's to get quest data.",
	VERSION = "1.0",
	VARIABLEVERSION = "20190710",
	LIECENSE = "BY-SA = Creative Commons Attribution-ShareAlike 4.0 International License",
	URL = "https://github.com/Ek1/libQuest"
}
local ADDON = "libQuest"	-- Variable used to refer to this add-on. Codereview friendly.

-- BEFORE_RELEASE turn all following to local.
-- Table about quest that's questId's are know. The questId works as index and thanks to Lua the missing entrys generate zero memory load.
allQuestIds = {} --	{questName, QuestRepeatableType = false/1/40, questStarters = {}, questRecipients = {}, zoneIds = {}}
allQuestIds[0] = 0
-- Table to keep track what quests names have multiple questIds
allQuestNames = {} --	{ {questId} }
allQuestNames[0] = 0
-- Table to dublicate journal with corresponding index for outlogged character quest progress info's
charactersOngoingQuests = {} -- {questName, acceptedTime}
charactersOngoingQuests[0] = 0
-- Table to keep track when quest was last done
charactersQuestHistory = {} -- {timestamp}
charactersQuestHistory[0] = 0

lastQuestIdRemoved = {}
-- BEFORE_RELEASE turn all above to local.

--[[	Order of the quest events usually firing
	EVENT_QUEST_SHARED		First chance to get questId combined with GetOfferedQuestShareInfo(sharedQuestId)
	EVENT_QUEST_ADDED		Quest is added to journal and thus it can be milked for more info
	EVENT_QUEST_ADVANCED	Quest advances thus its completion area is revealed
	EVENT_QUEST_REMOVED		Second and last chance to gain questId
	EVENT_QUEST_COMPLETE	Quest is marked as complete and its questType is revealed
]]

-- Another player sharing a quest
-- API 100026	EVENT_QUEST_SHARED (number eventCode, number questId)
function libQuest.EVENT_QUEST_SHARED (_, sharedQuestId)

	local questName, characterName, millisecondsSinceRequest, displayName = GetOfferedQuestShareInfo(sharedQuestId)

	libQuest.setNameToQuestId(questName, sharedQuestId)
	allQuestIds[sharedQuestId].shareable = true

	libQuest.setQuestIdToName(sharedQuestId, questName)

--	d( libQuest.TITLE .. ":EVENT_QUEST_SHARED questId:" .. sharedQuestId )
end

-- NPC offering a quest?
-- API 100026	EVENT_QUEST_OFFERED (number eventCode)
function libQuest.EVENT_QUEST_OFFERED (eventCode)
--	d( libQuest.TITLE .. ":EVENT_QUEST_OFFERED eventCode:" .. eventCode )
end

-- New quest gained and its initial info collected
-- API 100026	EVENT_QUEST_ADDED (number eventCode, number journalIndex, string questName, string objectiveName)
function libQuest.EVENT_QUEST_ADDED(_, addedToJournalIndex, addedQuestName, objectiveName)
--	d( libQuest.TITLE .. ":EVENT_QUEST_ADDED " .. addedQuestName .. "  objectiveName:" .. objectiveName .. " to jouranlIndex " ..  addedToJournalIndex)

--	Updating the journalIndex with the added quest data
	charactersOngoingQuests[addedToJournalIndex] = {}
	charactersOngoingQuests[addedToJournalIndex].name = addedQuestName
	charactersOngoingQuests[addedToJournalIndex].objectiveName = objectiveName
	charactersOngoingQuests[addedToJournalIndex].acceptedTime = os.time()
	charactersOngoingQuests[addedToJournalIndex].shareable = GetIsQuestSharable(addedToJournalIndex)
	charactersOngoingQuests[addedToJournalIndex].repeatable = GetJournalQuestRepeatType(addedToJournalIndex)

	if not charactersOngoingQuests[0] then
		charactersOngoingQuests[0] = 1
	else
		charactersOngoingQuests[0] = charactersOngoingQuests[0] + 1
	end
	-- GetJournalQuestInfo(number journalQuestIndex)
	-- Returns: string questName, string backgroundText, string activeStepText, number activeStepType, string activeStepTrackerOverrideText, boolean completed, boolean tracked, number questLevel, boolean pushed, number questType, number InstanceDisplayType instanceDisplayType
end

-- Quest advancing, more info gained and most importantly ZONE info gained
-- API 100026	EVENT_QUEST_ADVANCED (number eventCode, number journalIndex, string questName, boolean isPushed, boolean isComplete, boolean mainStepChanged)
function libQuest.EVENT_QUEST_ADVANCED (_, journalIndex, questName, booleanisPushed, booleanisComplete, booleanmainStepChanged)

	local questId = getQuestId(questName)
	local zoneIdWhereAdvanced = GetZoneId(GetUnitZoneIndex("player"))

	-- TPrecheck that we actually have the questId
	if type(questId) == "number" then
		-- The zoneId where the quest takes place is saved
		if type(allQuestIds[questId].zones) ~= "table" then
			allQuestIds[questId].zones = {}
		end
		local seeking = true
		local i = 1
		while seeking do
			if not allQuestIds[questId].zones[i] then
				allQuestIds[questId].zones[i] = zoneIdWhereAdvanced
				seeking = false
			elseif allQuestIds[questId].zones[i] == zoneIdWhereAdvanced then
				seeking = false
			end
			allQuestIds[questId].zones[0] = i
			i = i + 1
		end	-- zoneId saving done
	end
--	d( libQuest.TITLE .. ":EVENT_QUEST_ADVANCED questName:" .. questName .. " in map " .. zoneIdWhereAdvanced .. " journalIndex:" .. journalIndex  .. " booleanisPushed:" .. tostring(booleanisPushed) )
end

-- EVENT_QUEST_REMOVED (number eventCode, boolean isCompleted, number journalIndex, string questName, number zoneIndex, number poiIndex, number questId)
function libQuest.EVENT_QUEST_REMOVED (_, isCompleted, journalIndex, questName, zoneIndex, poiIndex, questId)
	lastQuestIdRemoved = questId

	libQuest.setNameToQuestId(questName, questId)
	libQuest.setQuestIdToName(questId, questName)

	-- First making sure the charactersOngoingQuests actually has a record of the # journalIndex
	if charactersOngoingQuests[journalIndex] then
		-- If the quest was shareable, then pass that info to the allQuestIds
		if charactersOngoingQuests[journalIndex].shareable then
			allQuestIds[questId].shareable = charactersOngoingQuests[journalIndex].shareable
		end
		-- If the quest was repeatable, then pass that info to the allQuestIds
		if charactersOngoingQuests[journalIndex].repeatable then
			allQuestIds[questId].repeatable = charactersOngoingQuests[journalIndex].repeatable
		end
		-- reseting the journal index
		charactersOngoingQuests[journalIndex] = nil
	end
	charactersOngoingQuests[0] = charactersOngoingQuests[0] - 1

	d( libQuest.TITLE .. ":EVENT_QUEST_REMOVED questName:" .. questName .. " zoneIndex:" .. zoneIndex .. " poiIndex:" .. poiIndex .. " questId:" .. questId .. " in map " .. GetZoneId(GetUnitZoneIndex("player")) .. "  lastQuestIdRemoved:" .. lastQuestIdRemoved)
end -- QuestData was pushed to allQuestIds and allQuestNames

-- This is only called when actually completing a quest, thus gaining the rewards
-- API 100026	EVENT_QUEST_COMPLETE (number eventCode, string questName, number level, number previousExperience, number currentExperience, number championPoints, QuestType questType, InstanceDisplayType instanceDisplayType)
function libQuest.EVENT_QUEST_COMPLETE (_, questName, _, _, _, _, questType, _)

	charactersQuestHistory[lastQuestIdRemoved] = os.time()

	allQuestIds[lastQuestIdRemoved].name = tostring(questName)
	allQuestIds[lastQuestIdRemoved].type = questType

	local zoneIdWhereAdvanced = GetZoneId(GetUnitZoneIndex("player"))

	-- The zoneId where the quest takes place is saved
	if type(allQuestIds[lastQuestIdRemoved].zones) ~= "table" then
		allQuestIds[lastQuestIdRemoved].zones = {}
	end
	local seeking = true
	local i = 1
	while seeking do
		if not allQuestIds[lastQuestIdRemoved].zones[i] then
			allQuestIds[lastQuestIdRemoved].zones[i] = zoneIdWhereAdvanced
			seeking = false
		elseif allQuestIds[lastQuestIdRemoved].zones[i] == zoneIdWhereAdvanced then
			seeking = false
		end
		allQuestIds[lastQuestIdRemoved].zones[0] = i
		i = i + 1
	end	-- zoneId saving done
	d( libQuest.TITLE .. ":EVENT_QUEST_COMPLETE questName:" .. questName .. " that was questType:" .. questType .. " in map " .. zoneIdWhereAdvanced .. "  lastQuestIdRemoved:" .. lastQuestIdRemoved)
end


-- Lets fire up the add-on by registering for events and loading variables
function libQuest.Initialize()

	-- Loading account variables i.o. all quest with complete data or if none saved, create one
	allQuestIds	= libQuest_allQuestIds or {}
	allQuestNames	= libQuest_allQuestNames or {}

	-- Loading character variables i.o. all incomplete quests
	charactersOngoingQuests	= ZO_SavedVars:NewCharacterIdSettings("libQuest_ongoingCharacterQuests", libQuest.VARIABLEVERSION, GetWorldName(), charactersOngoingQuests) or {}
	charactersQuestHistory	= ZO_SavedVars:NewCharacterIdSettings("libQuest_charactersQuestHistory", libQuest.VARIABLEVERSION, GetWorldName(), charactersQuestHistory) or {}

	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_SHARED,	libQuest.EVENT_QUEST_SHARED)
	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_OFFERED,	libQuest.EVENT_QUEST_OFFERED)
	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_ADDED,	libQuest.EVENT_QUEST_ADDED)

	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_ADVANCED,	libQuest.EVENT_QUEST_ADVANCED)
	
	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_COMPLETE,	libQuest.EVENT_QUEST_COMPLETE)
	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_REMOVED,	libQuest.EVENT_QUEST_REMOVED)

	d( libQuest.TITLE .. ": initalization done. Holding data of " .. allQuestIds[0] .. " quests and this characters " .. table.getn{charactersOngoingQuests} .. " ongoing quest with history of " .. table.getn{charactersQuestHistory} .. " quests.")
end

-- Variable to keep count how many loads have been done before it was this ones turn.
local loadOrder = 1
function libQuest.OnlibQuestLoaded(_, libQuestName)
	if libQuestName == ADDON then
	--	Seems it is our time so lets stop listening load trigger and initialize the add-on
		d( libQuest.TITLE .. ": load order " ..  loadOrder .. ", starting initalization")
		EVENT_MANAGER:UnregisterForEvent(ADDON, EVENT_ADD_ON_LOADED)
		libQuest.Initialize()
	end
	loadOrder = loadOrder+1
end

-- Registering the libQuest's initializing event when add-on's are loaded 
EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_ADD_ON_LOADED, libQuest.OnlibQuestLoaded)


--	Set'ters:

--	Fills allQuestIds with a (new) QuestId and its name.
function libQuest.setNameToQuestId(questName, questId)

	-- If the index spot is not a table, create one and also increase the tables zero index by one that is keeping track of how many quests we know
	if type(allQuestIds[questId]) ~= "table" then
		allQuestIds[questId] = {}
		allQuestIds[0] = allQuestIds[0]+1
	end

	-- Fill the name to the table allQuestIds
	allQuestIds[questId].name = tostring(questName)
end

--	Fills allQuestNames with a new QuestId for a name. Don't feed nils and remember one name can have multiple QuestId's
function libQuest.setQuestIdToName(questId, questName)
	-- First entry? Create a table
	if type(allQuestNames[questName]) ~= "table" then
		allQuestNames[questName] = {}
		allQuestNames[0] = allQuestNames[0]+1
	end

	local seeking = true
	local i = 1
	while seeking do
		if not allQuestNames[questName][i] then
			allQuestNames[questName][i] = questId
			seeking = false
		elseif allQuestNames[questName][i] == questId then
			seeking = false
		end
		allQuestNames[questName][0] = i
		i = i + 1
	end	-- questId's saved under quest name
end

-- Above is core, below is the actual libary section interface for other add-ons

-- Get'ters: give questName and recieve the QuestId or nil if empty
function getQuestName(questId)
	return allQuestIds[questId].name
end

function getQuestId(questName)
	return allQuestNames[questName]
end

function getZoneIds(questId)
	return allQuestIds[questId].zones
end

function getNumberOfQuestIdsKnown()
	return allQuestIds[0]
end

-- TODO: offer questId's POI's