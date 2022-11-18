Quests = {
	TITLE = "Quests",	-- Not codereview friendly but enduser friendly version of the add-on's name
	AUTHOR = "Ek1",
	DESCRIPTION = "Library for other add-on's to get quest data and to collect it.",
	VERSION = "1033.220402",
	VARIABLEVERSION = "1033.220402",
	LICENSE = "BY-SA = Creative Commons Attribution-ShareAlike 4.0 International License",
	URL = "https://github.com/Ek1/Quests"
}
local ADDON = "Quests"	-- Variable used to refer to this add-on. Codereview friendly.

-- BEFORE_RELEASE turn all following to local.
-- Table about quest that's questId's are know containing the quest data. The questId works as index and thanks to Lua the missing entrys generate zero memory load.
if not allQuestIds then
	allQuestIds = {}	--	{questName, RepeatableType, questStarters = {}, questRecipients = {}, zoneIds = {}}
	allQuestIds[0] = 0	-- Keeps track of how many questId's are known (sparse table, #allQuestIds wont work)
end
-- Table to keep track what quests names have multiple questIds
if not allQuestNames then
	allQuestNames	= {}	-- { {questId} }
	allQuestNames[0] = 0	-- Keeps track of how many quest names are known (non integer table, #allQuestNames wont work)
end

-- Table to dublicate journal with corresponding index for outlogged character quest progress info's and to access quest data on its completion 
charactersOngoingQuests = {}	-- {questName, acceptedTime}
-- Table to keep track when quest was last done
characterQuestHistory = {} -- {timestamp}
characterQuestHistory[0] = 0	-- Keeps track of how many unique quest's are done (sparse table, #characterQuestHistory wont work)
local lastQuestIdRemoved = {}
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
function Quests.EVENT_QUEST_SHARED (_, sharedQuestId)

	local questName, characterName, millisecondsSinceRequest, displayName = GetOfferedQuestShareInfo(sharedQuestId)

	Quests.setNameToQuestId(questName, sharedQuestId)
	allQuestIds[sharedQuestId].shareable = true

	Quests.setQuestIdToName(sharedQuestId, questName)

--	d( Quests.TITLE .. ":EVENT_QUEST_SHARED questId:" .. sharedQuestId )
end

-- NPC offering a quest
-- API 100026	EVENT_QUEST_OFFERED (number eventCode)
function Quests.EVENT_QUEST_OFFERED (eventCode)
--	d( Quests.TITLE .. ":EVENT_QUEST_OFFERED eventCode:" .. eventCode )
end

-- New quest gained and its initial info collected
-- API 100026	EVENT_QUEST_ADDED (number eventCode, number journalIndex, string questName, string objectiveName)
function Quests.EVENT_QUEST_ADDED(_, addedToJournalIndex, addedQuestName, objectiveName)
--	d( Quests.TITLE .. ":EVENT_QUEST_ADDED " .. addedQuestName .. "  objectiveName:" .. objectiveName .. " to jouranlIndex " ..  addedToJournalIndex)

--	Updating the journalIndex with the added quest data

	if not charactersOngoingQuests then
		charactersOngoingQuests = {}
	end

	charactersOngoingQuests[addedQuestName] = {}
	charactersOngoingQuests[addedQuestName].objectiveName = objectiveName
	charactersOngoingQuests[addedQuestName].acceptedTime = os.time()
	charactersOngoingQuests[addedQuestName].shareable = GetIsQuestSharable(addedToJournalIndex)
	charactersOngoingQuests[addedQuestName].repeatable = GetJournalQuestRepeatType(addedToJournalIndex)
	charactersOngoingQuests[addedQuestName].journalIndex = addedToJournalIndex

	-- GetJournalQuestInfo(number journalQuestIndex)
	-- Returns: string questName, string backgroundText, string activeStepText, number activeStepType, string activeStepTrackerOverrideText, boolean completed, boolean tracked, number questLevel, boolean pushed, number questType, number InstanceDisplayType instanceDisplayType
end

-- Quest advancing, more info gained and most importantly ZONE info gained
-- API 100026	EVENT_QUEST_ADVANCED (number eventCode, number journalIndex, string questName, boolean isPushed, boolean isComplete, boolean mainStepChanged)
function Quests.EVENT_QUEST_ADVANCED (_, journalIndex, questName, _, _, _)

	local questId = getQuestId(questName)
	local zoneIdWhereAdvanced = GetZoneId(GetUnitZoneIndex("player"))

	-- Precheck that we actually have the questId
	if type(questId) == "number" then
		-- The zoneId where the quest takes place is saved

		if type(allQuestIds[questId]) ~= "table" then
			allQuestIds[questId] = {}	--	{questName, RepeatableType, questStarters = {}, questRecipients = {}, zoneIds = {}}
		end
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
--	d( Quests.TITLE .. ":EVENT_QUEST_ADVANCED questName:" .. questName .. " in map " .. zoneIdWhereAdvanced .. " journalIndex:" .. journalIndex  .. " booleanisPushed:" .. tostring(booleanisPushed)  .. " booleanisComplete:" .. tostring(booleanisComplete) .. " booleanmainStepChanged:" .. tostring(booleanmainStepChanged))
end

-- 100028	EVENT_QUEST_CONDITION_COUNTER_CHANGED (number eventCode, number journalIndex, string questName, string conditionText, number QuestConditionType conditionType, number currConditionVal, number newConditionVal, number conditionMax, boolean isFailCondition, string stepOverrideText, boolean isPushed, boolean isComplete, boolean isConditionComplete, boolean isStepHidden, boolean isConditionCompleteStatusChanged, boolean isConditionCompletableBySiblingStatusChanged)
function Quests.EVENT_QUEST_CONDITION_COUNTER_CHANGED (_, journalIndex, questName, conditionText, QuestConditionType, currConditionVal, newConditionVal, conditionMax, isFailCondition, stepOverrideText, isPushed, isComplete, isConditionComplete, isStepHidden, isConditionCompleteStatusChanged, isConditionCompletableBySiblingStatusChanged)
--	d( Quests.TITLE .. ":EVENT_QUEST_CONDITION_COUNTER_CHANGED questName:" .. questName .. " conditionText:" .. conditionText .. " currConditionValues:" .. currConditionVal .. "->" .. newConditionVal .. "/" .. conditionMax .. " isConditionComplete:" .. tostring(isConditionComplete) .. " isComplete:" .. tostring(isComplete) )
end


-- EVENT_QUEST_REMOVED (number eventCode, boolean isCompleted, number journalIndex, string questName, number zoneIndex, number poiIndex, number questId)
function Quests.EVENT_QUEST_REMOVED (_, isCompleted, journalIndex, questName, zoneIndex, poiIndex, questId)
	lastQuestIdRemoved = questId

	Quests.setQuestIdToName(questId, questName)
	Quests.setNameToQuestId(questName, questId)

	-- First making sure the charactersOngoingQuests actually has a record of the # journalIndex
	if charactersOngoingQuests[questName] then
		-- If the quest was shareable, then pass that info to the allQuestIds
		if charactersOngoingQuests[questName].shareable then
			allQuestIds[questId].shareable = charactersOngoingQuests[questName].shareable
		end
		-- If the quest was repeatable, then pass that info to the allQuestIds
		if charactersOngoingQuests[questName].repeatable then
			allQuestIds[questId].repeatable = charactersOngoingQuests[questName].repeatable
		end
		-- reseting the journal index
		charactersOngoingQuests[questName] = nil
	end

	d( Quests.TITLE .. ":EVENT_QUEST_REMOVED questName:" .. questName .. " zoneIndex:" .. zoneIndex .. " poiIndex:" .. poiIndex .. " questId:" .. questId .. " in map " .. GetZoneId(GetUnitZoneIndex("player")) .. "  lastQuestIdRemoved:" .. lastQuestIdRemoved)
end -- QuestData was pushed to allQuestIds and allQuestNames

-- This is only called when actually completing a quest, thus gaining the rewards
-- API 100026	EVENT_QUEST_COMPLETE (number eventCode, string questName, number level, number previousExperience, number currentExperience, number championPoints, QuestType questType, InstanceDisplayType instanceDisplayType)
function Quests.EVENT_QUEST_COMPLETE (_, questName, _, _, _, _, questType, _)

	if not characterQuestHistory[lastQuestIdRemoved] then
		characterQuestHistory[0] = (characterQuestHistory[0] or 0) + 1
	end
	characterQuestHistory[lastQuestIdRemoved] = os.time()

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
	d( Quests.TITLE .. ":EVENT_QUEST_COMPLETE questName:" .. questName .. " that was questType:" .. questType .. " in map " .. zoneIdWhereAdvanced .. "  lastQuestIdRemoved:" .. lastQuestIdRemoved)
end


--	Fills allQuestIds with a (new) QuestId and its name.
function Quests.setNameToQuestId(questName, questId)

	-- If the index spot is not a table, create one and also increase the tables zero index by one that is keeping track of how many quests we know
	if type(allQuestIds[questId]) ~= "table" then
		allQuestIds[questId] = {}
		allQuestIds[0] = allQuestIds[0]+1 or 1
	end

	-- Fill the name to the table allQuestIds
	allQuestIds[questId].name = tostring(questName)
end

--	Fills allQuestNames with a new QuestId for a name. Don't feed nils and remember one name can have multiple QuestId's
function Quests.setQuestIdToName(questId, questName)
	if allQuestIds[questId] ~= nil then
		d("Common: we have already entry number " .. tostring(questId) .. " thus nothing to do.")
	elseif type(allQuestNames[questName]) ~= "table" then
		d (" Rare: 1st entry thus initialize table and populate with the first entry of " .. tostring(questId) )
		allQuestNames[questName] = {}
		allQuestNames[questName][1] = questId
	else
	d("Uncommon: Whee a new entry " .. tostring(questId) .. "! Lets snuggle it to the right spot for sake of sanity.")
	local inOrder = {}
	local i = 1
	local lookingForSpot = true
		while lookingForSpot do
			if allQuestNames[questName][i] < questId then
				inOrder[i] = allQuestNames[questName][i]
				d("allQuestNames[questName][i] < questId " .. tostring(inOrder[ii]) .. tostring(allQuestNames[questName][i]) )
			elseif questId < allQuestNames[questName][i] then
				inOrder[i+1] = questId
				lookingForSpot = false
--				d("Snugled " .. questId .. " to spot in " .. ii )
				local tale = i
				for ii = i+1, #allQuestNames[questName]+1 do
					inOrder[ii] = allQuestNames[questName][tale]
					tale = tale +1
				end
			end
			i = i + 1
		end
		d(inOrder)
--		for index,value in inOrder(t) do allQuestNames[questName][index] = value end
		allQuestNames[questName] = inOrder
		d(allQuestNames[questName])
	end
end

-- Above is core, below is the actual libary section interface for other add-ons

-- Get'ters: give questName and recieve the QuestId or nil if empty
function getQuestName(questId)
	return allQuestIds[questId].name or -1
end

function getQuestId(questName)
	return allQuestNames[questName] or -1
end

function getZoneIds(questId)
	return allQuestIds[questId].zones or -1
end

function getNumberOfQuestIdsKnown()
	return allQuestIds[0] or -1
end

function getCharactersLastCompletionOfQuestId(questId)
	return characterQuestHistory[QuestId] or -1
end

-- TODO: offer questId's POI's

-- Lets fire up the add-on by loading variables and registering for events
function Quests.Initialize()

	local WORLDNAME = GetWorldName()

	-- Loading character variables i.o. all incomplete quests
	-- allQuestIds allQuestNames charactersQuestHistory ongoingCharacterQuests
	-- ZO_SavedVars:NewCharacterIdSettings(savedVariableTable, version, namespace, defaults, profile)
	characterQuestHistory	= ZO_SavedVars:NewCharacterIdSettings("charactersQuestHistory", Quests.VARIABLEVERSION, nil, {}, WORLDNAME ) 
	charactersOngoingQuests	= ZO_SavedVars:NewCharacterIdSettings("ongoingCharacterQuests", Quests.VARIABLEVERSION, nil, {}, WORLDNAME ) 

	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_SHARED,	Quests.EVENT_QUEST_SHARED)
	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_OFFERED,	Quests.EVENT_QUEST_OFFERED)
	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_ADDED,	Quests.EVENT_QUEST_ADDED)
	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_ADVANCED,	Quests.EVENT_QUEST_ADVANCED)
	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_CONDITION_COUNTER_CHANGED,	Quests.EVENT_QUEST_CONDITION_COUNTER_CHANGED)
	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_COMPLETE,	Quests.EVENT_QUEST_COMPLETE)
	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_REMOVED,	Quests.EVENT_QUEST_REMOVED)

	if allQuestIds[0] and #charactersOngoingQuests and characterQuestHistory[0] then
		d( Quests.TITLE .. ": initalization done. Holding data of " .. allQuestIds[0] .. " quests and this characters " .. #charactersOngoingQuests .. " ongoing quest with history of " .. characterQuestHistory[0] .. " quests.")
	end
end

function Quests.OnQuestsLoaded(_, loadedAddOnName)
	if loadedAddOnName == ADDON then
	--	Seems it is our time so lets stop listening load trigger and initialize the add-on
		EVENT_MANAGER:UnregisterForEvent(ADDON, EVENT_ADD_ON_LOADED)
		Quests.Initialize()
	end
end
-- Registering the Quests's initializing event when add-on's are loaded 
EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_ADD_ON_LOADED, Quests.OnQuestsLoaded)