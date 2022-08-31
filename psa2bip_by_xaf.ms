/*
 Batch Export PSK/PSA to bip for 3ds Max
 
 Created by lwk 20211230
 */
global g_axImporterVersion

global g_meshDir
global g_meshRecurse
global g_keepXAFfile
global g_reuseXAFfile

if (g_meshDir     == undefined) then g_meshDir     = ""
if (g_meshRecurse == undefined) then g_meshRecurse = true
if (g_keepXAFfile == undefined) then g_keepXAFfile = false
if (g_reuseXAFfile == undefined) then g_reuseXAFfile = false


fn VerifyAXI =
(
	if (g_axImporterVersion == undefined) then
	(
		messageBox "ActorX Importer is not loaded!"
		return false
	)
	if (g_axImporterVersion < 133) then
	(
		messageBox "Your ActorX Importer script is too old, please update!"
		return false
	)
	return true
)


fn exportXAF xafFilename = (
	select $'Bip001' ; actionMan.executeAction 0 "40180"
	myObjs = $
	myObjs.count
	
	bipedNodes = #()
	for i = 1 to myObjs.count do (
		if findString myObjs[i].name "Bip001" == 1 then append bipedNodes myObjs[i] 
	)
	LoadSaveAnimation.saveAnimation xafFilename bipedNodes "" ""
	clearSelection()
)

fn ClearAllAnimation = (
	max select all
	if $ != undefined then maxops.deleteSelectedAnimation()
	clearSelection()
)

fn DoExportXAFAnim aniFileName =
(
	--if (findString aniFileName "act_run" == undefined ) then return undefined
	print ("ani:" + aniFileName)
	bones = FindAllBones()
	if (bones.count == 0) then
	(
		print "Mesh is not loaded!"
		return undefined
	)

	ClearAllAnimation()
	
	-- configure ActorX Importer
	g_playAnim = false
	(
		ImportPsaFile aniFileName 1 all:true
		for i = 1 to Anims.count do
		(
			local track = Anims[i]
			local trackName = track.Name
			local numFrames = track.NumRawFrames-1
			if (numFrames < 1) then numFrames = 1
			
			local savePath = aniFileName + "." + trackName + ".xaf"
			if ( g_reuseXAFfile and (doesFileExist savePath) ) then print("ReUse XAF File:" +savePath)  else exportXAF savePath
		)
	)
	g_playAnim = false

)

fn ExportXAFs path = (
	local files = getFiles(path + "/*.psa")
	for file in files do DoExportXAFAnim file
	local dirs = getDirectories(path + "/*")
	for dir in dirs do ExportXAFs dir
	)
	
	
fn DoExportBipAnim aniFileName =
(
	--if (findString aniFileName "walk" == undefined ) then return undefined
	print ("xaf:" + aniFileName)
	
	--clear all animations
	max select all
	macros.run "Animation Tools" "DeleteSelectedAnimation"
	
	LoadSaveAnimation.loadAnimation aniFileName $'Bip001*'
	local bipFileName = aniFileName + ".bip"
	biped.saveBipFile $'Bip001'.controller bipFileName
	
	if not g_keepXAFfile then deleteFile aniFileName
)

fn ExportBips path = (
	local files = getFiles(path + "/*.xaf")
	for file in files do DoExportBipAnim file
	local dirs = getDirectories(path + "/*")
	for dir in dirs do ExportBips dir
	)

function replaceSpace myStrg =(
	for i = 1 to myStrg.count do (
		if myStrg[i] == " " then (
			myStrg[i] = "-"
			)
		)
	return myStrg
)

fn CreateBiped = (
	local height = $'Bip001-Head'.position.z
	
	local neckCount = $'Bip001-Neck*'.count
	local spineCount = $'Bip001-Spine*'.count

	local toeLinkCount = $'Bip001-L-Toe0*'.count
	local toeCount = $'Bip001-L-Toe*'.count / toeLinkCount
	
	local fingerLinkCount = $'Bip001-L-Finger0*'.count
	local fingerCount = $'Bip001-L-Finger*'.count / fingerLinkCount

	local ThighParentNodeName = $'Bip001-L-Thigh'.parent.name
	local ClavicleParentName = $'Bip001-L-Clavicle'.parent.name
	
	ClearMaxScene()

	coordsys world
	local mybiped = biped.createNew height 0.0 [0,0,0] neckLinks:neckCount spineLinks:spineCount fingers:fingerCount fingerLinks:fingerLinkCount toes:toeCount toeLinks:toeLinkCount
	select mybiped ; actionMan.executeAction 0 "40180"
	myObjs = $
	for i = 1 to myObjs.count do (
		myObjs[i].name = replaceSpace(myObjs[i].name)
	)
	clearSelection()
	
	if $'Bip001-L-Thigh'.parent.name != ThighParentNodeName then (
		local parentNode = getNodeByName ThighParentNodeName
		$'Bip001-L-Thigh'.parent = parentNode
		$'Bip001-R-Thigh'.parent = parentNode
	)
	
	if $'Bip001-L-Clavicle'.parent.name != ClavicleParentName then (
		local parentNode = getNodeByName ClavicleParentName
		$'Bip001-L-Clavicle'.parent = parentNode
		$'Bip001-R-Clavicle'.parent = parentNode
	)
)
-- DoExportFbxMesh "D:\\test\\npc_shu_706\\npc_shu_706.psk"
fn DoExportFbxMesh psk_filename =
(
	local filename = getFilenameFile(psk_filename)
	local psk_dir = getFilenamePath(psk_filename)
	local fileName = copy filename
	toUpper fileName
	if (findString fileName "LOD" != undefined) then return undefined

	format "Exporting mesh %\n" psk_filename

	ClearMaxScene()
	
	xafFileNames = #()
	
	--step.1 import skeleton
	ImportPskFile psk_filename skelOnly:true
	if $Bip001 == undefined then (
		print("not Bip001 node find")
		return undefined
	)
	
	--step.2 convert all psa 2 xaf
	ExportXAFs psk_dir
	
	--step.3 construct biped obj
	CreateBiped()

	--step.4 convert all xaf 2 biped
	ExportBips psk_dir
)

fn ExportFbxMeshes path recurse =
(
	if (not VerifyAXI()) then return undefined
	local files = getFiles(path + "/*.psk*")

	for file in files do DoExportFbxMesh file
	if recurse then
	(
		local dirs = getDirectories(path + "/*")
		for dir in dirs do ExportFbxMeshes dir recurse
	)

	ClearMaxScene()
)


-- UI
rollout fbxExportRollout "PSK/PSA 2 Bip Batch Export"
(
	-- copyright label
	label     Lbl1 "Version 1.01"
	label     Lbl2 "3D Max2021 Tested"

	group "PSA->BIP"
	(
		label    Lbl10           "This tool will convert all PSA to BIP" align:#left
		label    Lbl11           "PSK file Need for Bone Struct" align:#left
		label    Lbl12           ""
		edittext EdMeshPath      "Path to RootDir" text: g_meshDir width:280 across:2
		button   BtnBrowseMesh   "..."     align:#right height:16
		checkbox ChkMeshRecurse  "Look in subfolders" checked:g_meshRecurse
		button   BtnExportMeshes "Export BIPs"
	)
	
	group "Debug"
	(
		checkbox ChkKeepXAF  "Keep XAF Files" checked:g_keepXAFfile
		checkbox ChkReuseXAFFiles  "Reuse XAF Files" checked:g_reuseXAFfile
	)

	on EdMeshPath        changed val do g_meshDir = val
	on ChkMeshRecurse    changed state do g_meshRecurse = state
	on ChkKeepXAF	 	 changed state do g_keepXAFfile = state
	on ChkReuseXAFFiles	 changed state do g_reuseXAFfile = state
	on BtnBrowseMesh     pressed do
	(
		dir = getSavePath caption:"Directory for mesh lookup" initialDir:g_meshDir
		if dir != undefined then
		(
			g_meshDir       = dir
			EdMeshPath.text = dir
		)
	)
	on BtnExportMeshes   pressed do (
		with redraw off
		(
			with undo off
			(
				ExportFbxMeshes g_meshDir g_meshRecurse
			)
		)
	)
)


if fbxExportFloater != undefined do closeRolloutFloater fbxExportFloater	-- close old window if visible
fbxExportFloater = newRolloutFloater "FBX Batch Export" 350 300 300 100 	-- create new window

addRollout fbxExportRollout fbxExportFloater
