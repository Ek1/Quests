libQuest = {
	Title = "libQuest",	-- Not codereview friendly but enduser friendly version of the add-on's name
	Author = "Ek1",
	Description = "Libary for other add-on's to get quest data.",
	Version = "1.0",
	VariableVersion = "2",
	License = "BY-SA = Creative Commons Attribution-ShareAlike 4.0 International License",
	URL = "https://github.com/Ek1/libQuest"
}
local ADDON = "libQuest"	-- Variable used to refer to this add-on. Codereview friendly.

-- BEFORE_RELEASE turn all following to local.
-- Table about quest that's questId's are know. The questId works as index and thanks to Lua the missing entrys generate zero memory load.
local allQuests =  {} -- {questName, QuestRepeatableType = false/1/40, questStarters = {}, questRecipients = {}, zoneIds = {}}
-- Table to dublicate journal with corresponding index for outlogged character quest progress info's
local charactersOngoingQuests =  {} -- {questName, acceptedTime}
-- Table to keep track when quest was last done
local charactersQuestHistory =  {} -- {questName, QuestRepeatableType = false/1/40, questStarters = {}, questRecipients = {}, zoneIds = {}}

--[[
Order of qquest events usually firing
EVENT_QUEST_SHARED		Hyvällä säkällä joku jakaa sen jolloin quest id tulee heti kättelyssä.
EVENT_QUEST_ADDED		Itse questin lisäys journalIndex tauluun jolloin sekä ekan kerran kun journalIndex saa käyttöön
EVENT_QUEST_ADVANCED	Questi etenee joten paikka talteen missä sitä on voinut edistää
EVENT_QUEST_REMOVED		Questi poistuu journalIndex taulusta ja kerätty data tuupataan oikeaan data tauluun, viimistään nyt questId selviää
EVENT_QUEST_COMPLETE	Questi on valmis, paikka talteen ja viimistään nyt questType tulee selville
]]

-- Another player sharing a quest
-- API 100026	EVENT_QUEST_SHARED (number eventCode, number questId)
function libQuest.EVENT_QUEST_SHARED (_, sharedQuestId)
	d( libQuest.Title .. ":EVENT_QUEST_SHARED questID:" .. sharedQuestId )
	local sharedQuestName, characterName, _, displayName = GetOfferedQuestShareInfo (sharedQuestId)

--	allQuests[sharedQuestId] = tostring(sharedQuestName)
	table.insert(allQuests[sharedQuestId], tostring(sharedQuestName) )

	d( libQuest.Title .. ":EVENT_QUEST_SHARED questID:" .. sharedQuestId .. " sharedQuestName:" .. allQuests[sharedQuestId])
	d( allQuests )
--	incompleteQuestData taulun 1 sarake on varattu questId'lle
--	incompleteQuestData[1] = sharedQuestId

--	incompleteQuestData taulun 2 sarake on varattu questin nimelle
--	incompleteQuestData[1].[2] = sharedQuestName
end

-- API 100026	EVENT_QUEST_ADDED (number eventCode, number journalIndex, string questName, string objectiveName)
function libQuest.EVENT_QUEST_ADDED(_, addedToJournalIndex, addedQuestName, objectiveName)
	d( libQuest.Title .. ":EVENT_QUEST_ADDED " .. addedQuestName .. "  objectiveName:" .. objectiveName .. " to jouranlIndex " ..  addedToJournalIndex)

--[[	for i,v in ipairs(incompleteQuestData) do
		if v[1] == questName then
			if type(zones) == "table" then
				for _,zoneID in ipairs(zones) do
					table.insert(incompleteQuestData[i][2], zoneID)
				end 
			else
				table.insert(incompleteQuestData[i][2], zones)
			end
		end
	end

--	incompleteQuestData taulun 5 sarake on varattu toistolle
	if GetJournalQuestRepeatType(addedToJournalIndex) = 2 then	-- Weidly enough, API marks once-per-day-quests-types with number 2
		incompleteQuestData[addedQuestName].[5] = 1
		end
	elseif GetJournalQuestRepeatType(addedToJournalIndex) = 1 then	-- Same time API marks noRepeatLimit quests with number 1
		incompleteQuestData[addedQuestName].[5] = 40	-- Using 40 as it is the cap how many times repeatable quests can be done a day
		end
	else
		incompleteQuestData[addedQuestName].[5] = false	-- Unrepeatable quest are definative mark of a quest story
	end

--	incompleteQuestData taulun 3 sarake on varattu quest tyypille
	incompleteQuestData[addedQuestName].[3] = DataGetJournalQuestType(addedToJournalIndex)]]
end

	
-- Quest advancing, more info gained and most importantly ZONE info gained
-- API 100026	EVENT_QUEST_ADVANCED (number eventCode, number journalIndex, string questName, boolean isPushed, boolean isComplete, boolean mainStepChanged)
function libQuest.EVENT_QUEST_ADVANCED (_, journalIndex, questName, booleanisPushed, booleanisComplete, booleanmainStepChanged)
	d( libQuest.Title .. ":EVENT_QUEST_ADVANCED questName:" .. questName .. " in map " .. GetZoneId(GetUnitZoneIndex("player")) .. " journalIndex:" .. journalIndex )

--	incompleteQuestData taulun 9 sarake on varattu zone id'eille johon nykynen sijainti pusketaan
--	incompleteQuestData[questName].[9] = GetZoneId(GetUnitZoneIndex("player"))
end

-- EVENT_QUEST_REMOVED (number eventCode, boolean isCompleted, number journalIndex, string questName, number zoneIndex, number poiIndex, number questID)
function libQuest.EVENT_QUEST_REMOVED (_, isCompleted, journalIndex, questName, zoneIndex, poiIndex, questID)
	d( libQuest.Title .. ":EVENT_QUEST_REMOVED questName:" .. questName .. " zoneIndex:" .. zoneIndex .. " poiIndex:" .. poiIndex .. " questID:" .. questID .. " in map " .. GetZoneId(GetUnitZoneIndex("player")))

-- Perkeleenmoinen myllerys jossa valmis paketti tuupataan oikeaan questi tauluun JOS isCompleted = true
-- incompleteQuestData[3] on Quest_type ja jos on 4 niin pusketaan craftingQuestsIds
-- incompleteQuestData[4] on shareable(false/true) ja ne pusketaan soloQuestsIds/shareableQuestsIds
-- incompleteQuestData[5] on repeatable ja jos false niin pusketaan storyQuestsIds
-- Lisäks pitäis kattoa onko kyseisen questin tiedot jo olemassa ja jos on niin lisätään vain puuttuvat eli eriävät tiedot

end -- Quest has been pushed to correct questDataTable.

-- API 100026	EVENT_QUEST_COMPLETE (number eventCode, string questName, number level, number previousExperience, number currentExperience, number championPoints, QuestType questType, InstanceDisplayType instanceDisplayType)
function libQuest.EVENT_QUEST_COMPLETE (_, questName, _, _, _, _, questType, _)
	d( libQuest.Title .. ":EVENT_QUEST_COMPLETE questName:" .. questName .. " that was questType:" .. questType .. " in map " .. GetZoneId(GetUnitZoneIndex("player")))

--	incompleteQuestData taulun 9 sarake on varattu zone id'eille johon nykynen sijainti pusketaan
--	incompleteQuestData[questName].[9] = GetZoneId(GetUnitZoneIndex("player"))
end


-- Lets fire up the add-on by registering for events and loading variables
function libQuest.Initialize()

	-- Loading account variables i.o. all quest with complete data
	allQuests = ZO_SavedVars:NewAccountWide("libQuest_allQuests", libQuest.variableVersion, nil, allQuests)
	-- Loading character variables i.o. all incomplete quests 
	charactersOngoingQuests	= ZO_SavedVars:NewCharacterIdSettings("libQuest_ongoingCharacterQuests", libQuest.variableVersion, nil, charactersOngoingQuests)
	charactersQuestHistory	= ZO_SavedVars:NewCharacterIdSettings("libQuest_charactersQuestHistory", libQuest.variableVersion, nil, charactersQuestHistory)

	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_SHARED,	libQuest.EVENT_QUEST_SHARED)
	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_ADDED,	libQuest.EVENT_QUEST_ADDED)
	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_ADVANCED,	libQuest.EVENT_QUEST_ADVANCED)
	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_COMPLETE,	libQuest.EVENT_QUEST_COMPLETE)
	EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_QUEST_REMOVED,	libQuest.EVENT_QUEST_REMOVED)

	d( libQuest.Title .. ": initalization done")
end

-- Variable to keep count how many loads have been done before it was this ones turn.
local loadOrder = 0
function libQuest.OnlibQuestLoaded(_, libQuestName)
	if libQuestName == ADDON then
	--	Seems it is our time so lets stop listening load trigger and initialize the add-on
		d( libQuest.Title .. ": load order " ..  loadOrder .. ", starting initalization")
		EVENT_MANAGER:UnregisterForEvent(ADDON, EVENT_ADD_ON_LOADED)
		libQuest.Initialize()
	end
loadOrder = loadOrder+1
end

-- Registering the libQuest's initializing event when add-on's are loaded 
EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_ADD_ON_LOADED, libQuest.OnlibQuestLoaded)

-- Above is core, time to introduce the actual libary section interface for other's aka getters

-- 
function libQuest.getQuestId(whatsMyId)
	return allQuests
end