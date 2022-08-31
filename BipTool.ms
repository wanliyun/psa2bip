/*

 BipTool for 3ds Max
 
 Created by lwk 20211231
 
 1.Change Name (Prefix and Delimiter)
 2.Create Biped reference to Object Struct
 */

global g_prefixFrom
global g_prefixTo
global g_includeChildren


if (g_prefixFrom     == undefined) then g_prefixFrom     = "Bip01"
if (g_prefixTo     == undefined) then g_prefixTo     = "Bip001"
if (g_includeChildren     == undefined) then g_includeChildren     = false


function GetAllChildNode parentNode ret=
(
	append ret parentNode
    for childnode in parentNode.children do
    (
		GetAllChildNode childnode ret
    )
)


fn getOjects includeChild = (
	local selectionArray = selection as array
	if (selectionArray.count == 0) then(
		messageBox "need select Object!"
		return undefined
	)
	
	if(includeChild) then (
		if (selectionArray.count != 1) then(
			messageBox "Cannot select more than one Object!"
			return undefined
		)
		
		local ret = #()
		GetAllChildNode selectionArray[1] ret
		return ret
	)
	return selectionArray
)


fn  DoChangPrefix = (
	local objs = getOjects(g_includeChildren)
	if objs == undefined then return undefined
	for i = 1 to objs.count do (
		if findString objs[i].name g_prefixFrom  == 1 then(
			local a = substring objs[i].name (g_prefixFrom.count + 1) -1
			objs[i].name = g_prefixTo + a
		)
		
	)
)

fn replaceDelimiter myStrg fromStr toStr =(
	for i = 1 to myStrg.count do (
		if myStrg[i] == fromStr then (
			myStrg[i] = toStr
			)
		)
	return myStrg
)


fn DoReplaceDelimiter dFrom dTo = (
	local objs = getOjects(g_includeChildren)
	for i = 1 to objs.count do (
		objs[i].name = replaceDelimiter objs[i].name  dFrom  dTo
	)
)


fn GetNameParrentCount objs rootName postFix = (
	local namePattern = rootName + postFix
	local ret = 0
	for i = 1 to objs.count do(
			if (matchPattern objs[i].name pattern:namePattern ) then ret +=1
	)
	return ret
)
	
fn FindObjByName objs rootName nameStr = (
	local namePattern = rootName + nameStr
	for i = 1 to objs.count do(
		if (matchPattern objs[i].name pattern:namePattern ) then return objs[i]
	)
	return undefined
)

fn getParentNamePostfix objs rootName nodeName = (
	local obj = FindObjByName objs rootName   nodeName
	if obj == undefined then return undefined
	if obj.parent == undefined then return undefined
	local idx = rootName.count+1
	local ret = subString obj.parent.name idx -1
	return ret
)

fn resetParent rootName objName parentName = (
	if parentName == undefined then return undefined
	objName = rootName + objName
	local obj = getNodeByName  objName
	if obj == undefined then return undefined
	
	parentName = rootName + parentName
	local parentObj = getNodeByName  parentName
	if parentObj == undefined then return undefined
	obj.parent = parentObj
)

fn doCreateBip = (
	local objs = getOjects(true)
	if objs == undefined then return undefined
	local rootObj = objs[1]
	local rootName = rootObj.name
	local neckCount  = GetNameParrentCount objs rootName   " Neck*"
	local spineCount  = GetNameParrentCount objs rootName   " Spine*"
	format "rootName=% neckCount=% spineCount=%\n" rootName neckCount spineCount
	
	local toeLinkCount  = GetNameParrentCount objs rootName " L Toe0*"
	local toeCount  = GetNameParrentCount objs rootName  " L Toe*"
	local toeNub = GetNameParrentCount objs rootName  " L Toe0Nub"
	toeCount /= toeLinkCount
	toeLinkCount -= toeNub
	format "toeLinkCount=% toeCount=% toeNub=%\n" toeLinkCount toeCount toeNub
	
	local fingerLinkCount  = GetNameParrentCount objs rootName  " L Finger0*"
	local fingerCount  = GetNameParrentCount objs rootName   " L Finger*"
	local fingerNub = GetNameParrentCount objs rootName   " L Finger0Nub"
	fingerCount /= fingerLinkCount
	fingerLinkCount -= fingerNub
	format "fingerLinkCount=% fingerCount=% fingerNub=%\n" fingerLinkCount fingerCount fingerNub
	
	local upAramTwistLinkCount = GetNameParrentCount objs rootName   " LUpArmTwist*"
	local foreAramTwistLinkCount = GetNameParrentCount objs rootName   " L ForeTwist*"
	
	format "upAramTwistLinkCount=% upAramTwistLinkCount=% \n" upAramTwistLinkCount foreAramTwistLinkCount
	
	local thightTwistLinkCount = GetNameParrentCount objs rootName   " LThighTwist*"
	local calfTwistLinkCount = GetNameParrentCount objs rootName   " LCalfTwist*"
	
	format "thightTwistLinkCount=% calfTwistLinkCount=% \n" thightTwistLinkCount calfTwistLinkCount
	
	local Thigh = FindObjByName objs rootName " L Thigh"
	local trianglePelvis =  matchPattern Thigh.parent.name pattern:"*Spine*"
	local LClavicle = FindObjByName objs rootName " L Clavicle"
	local triangleNeck = matchPattern LClavicle.parent.name pattern:"*Spine*"
	format "Thigh.parent.name=% Clavicle.parent.name=% \n" Thigh.parent.name LClavicle.parent.name
	format "trianglePelvis=% triangleNeck=% \n" trianglePelvis triangleNeck
	
	local RThighTwistParentName = getParentNamePostfix objs rootName " RThighTwist"
	local LThighTwistParentName = getParentNamePostfix objs rootName " LThighTwist"
	format "RThighTwistParentName=[%] LThighTwistParentName=[%] \n" RThighTwistParentName LThighTwistParentName
	
	local RCalfTwistParentName = getParentNamePostfix objs rootName " RCalfTwist"
	local LCalfTwistParentName = getParentNamePostfix objs rootName " LCalfTwist"
	format "RCalfTwistParentName=[%] LCalfTwistParentName=[%] \n" RCalfTwistParentName LCalfTwistParentName
	
	
	local RUpArmTwistParentName = getParentNamePostfix objs rootName " RUpArmTwist"
	local LUpArmTwistParentName = getParentNamePostfix objs rootName " LUpArmTwist"
	format "RUpArmTwistParentName=[%] LUpArmTwistParentName=[%] \n" RUpArmTwistParentName LUpArmTwistParentName
	
	local RForeTwistParentName = getParentNamePostfix objs rootName " R ForeTwist"
	local LForeTwistParentName = getParentNamePostfix objs rootName " L ForeTwist"
	format "RForeTwistParentName=[%] LForeTwist=[%] \n" RForeTwistParentName LForeTwistParentName
	
	local newBiped = biped.createNew 2 0.0 [0,0,0] neckLinks:neckCount \
		spineLinks:spineCount fingers:fingerCount fingerLinks:fingerLinkCount \
		toes:toeCount toeLinks:toeLinkCount \
		trianglePelvis:trianglePelvis  triangleNeck:triangleNeck\
		forearmTwistLinks:foreAramTwistLinkCount upperarmTwistLinks:upAramTwistLinkCount\
		thighTwistLinks:thightTwistLinkCount calfTwistLinks:calfTwistLinkCount
		

	local newRootName = newBiped.name
	format "newRootName=%\n" newRootName
	
	resetParent newRootName " R ForeTwist" RForeTwistParentName
	resetParent newRootName " L ForeTwist" LForeTwistParentName
	
	resetParent newRootName " RUpArmTwist" RUpArmTwistParentName
	resetParent newRootName " LUpArmTwist" LUpArmTwistParentName
	
	resetParent newRootName " RCalfTwist" RCalfTwistParentName
	resetParent newRootName " LCalfTwist" LCalfTwistParentName
	
	resetParent newRootName " RThighTwist" RThighTwistParentName
	resetParent newRootName " LThighTwist" LThighTwistParentName
)

-- UI
rollout bipToolRollout "BipTool"
(
	-- copyright label
	label     Lbl1 "Version 1.01"
	label     Lbl2 "3D Max2021 Tested"

	group ""
	(
		label    Lbl00           "Effect On Chagne Name(Prefix&Delimiter)" align:#left
		label    Lbl02           ""
		checkbox ChkPrefixIncludeChildren  "Include Children" checked:g_includeChildren
	)
	
	group "Change Name(Prefix)"
	(
		label    Lbl10           "Change name of selected object and it's Children" align:#left
		label    Lbl12           ""
		edittext EdPrefixFrom      "From" text: g_prefixFrom width:100 across:2 align:#left
		edittext EdPrefixTo        "To" text: g_prefixTo width:100 across:2 align:#left
	
		
		button   BtnChgPrefix "ChangPrefix"
	)

	group  "Change Name(Delimiter)"
	(
		label    Lbl20           "Change name of selected object and it's Children" align:#left
		label    Lbl22           ""
		button   BtnDash2Space "Chang Dash[-] to Space[ ]"
		button   BtnSpace2Dash "Chang Space[ ] to Dash[-]"
	)
	
	on EdPrefixFrom        changed val 					do g_prefixFrom = val
	on EdPrefixTo        changed val 					do g_prefixTo = val
	on ChkPrefixIncludeChildren	 changed state 			do g_includeChildren = state
	on BtnChgPrefix     pressed 						do DoChangPrefix()
	
	
	on BtnDash2Space     pressed do DoReplaceDelimiter "-" " " 
	on BtnSpace2Dash     pressed do DoReplaceDelimiter " " "-" 


	group "Create Bip"
	(
		label    Lbl30           "Create Biped Ref to Struct of Selected Object" align:#left
		label    Lbl32           ""
		button   BtnCreateBip "Create Bip"
	)
	on BtnCreateBip    pressed do doCreateBip()
)

if fbxBipToolFloter != undefined do closeRolloutFloater fbxBipToolFloter	-- close old window if visible
fbxBipToolFloter = newRolloutFloater "BipTool" 350 440 300 100 	-- create new window

addRollout bipToolRollout fbxBipToolFloter