
global g_SearchFBXRecurse = true
global g_FBXRootDir="D:\\p5art\\Assets\\Res\\effect\\model\\qt"
global g_ReplaceOriFBX = true
global g_SkipWhenNoMaterial = true
global g_CleanAnimation = false
global g_CleanLight = true
global g_CleanCamera = true


-------------------------------------------------------------------
pluginManager.loadClass FBXIMPORTER
pluginManager.loadClass FBXEXPORTER


fn ClearMaxScene =
(
	--max select all
	--if $ != undefined then delete $
	resetMaxFile #noPrompt
)


fn WalkDir path pattern recurse=
(
	local files = getFiles(path + pattern)
	if recurse then(
		local dirs = getDirectories(path + "/*")
		for dir in dirs do(
			local xx = WalkDir dir pattern recurse
			join files(xx)
		)
	)
	return files
)



fn CleanMat filePath = (
	ClearMaxScene()
	importFile filePath #noPrompt
	max select all

	local needSave = not g_SkipWhenNoMaterial
	Sel = selection as Array
	
	for i = 1 to Sel.count do(
		local obj = Sel[i]
		--print obj.name
		local hasMat = isProperty obj "material"
		if hasMat then(
			if obj.material != null then(
				obj.material = null
				--print "CleanMat"
				needSave = true
			)
		)
	)
	
	local outPath = filePath +".out.fbx"
	if g_ReplaceOriFBX then outPath = filePath
	
	if needSave then(
		if g_CleanAnimation then( FBXExporterSetParam "Animation" 	false)
		if g_CleanLight 	then( FBXExporterSetParam "Lights" 	false)
		if g_CleanCamera 	then( FBXExporterSetParam "Cameras" 	true)
		
		exportFile outPath #noPrompt using:FBXEXP
	)else(
		print("Skipped")
	)
)



fn CleanMats rootDir recurse = (
	/*
	print "xx:"
	print g_ReplaceOriFBX
	print g_SkipWhenNoMaterial
	print g_CleanAnimation
	print g_CleanLight
	print g_CleanCamera
	*/
	
	files = WalkDir ROOT_Dir "/*.fbx" recurse
	print files.count
	
	for i = 1 to files.count do (
		print("ProcessFile:"+ files[i])
		CleanMat files[i]
	)
)

------------------------------------------------------------------
-- UI
rollout fbxCleanerRollOut "FBX Cleaner"
(
	-- copyright label
	label     Lbl1 "Version 1.01"
	label     Lbl2 "3D Max2021 Tested"

	group "Chose FBX File"
	(
		label    Lbl10           "This tool will Clean Unused Material" align:#left
		label    Lbl11           "From FBX" align:#left
		label    Lbl12           ""
		edittext EdMeshPath      "Path to FBXRootDir" text: g_FBXRootDir width:280 across:2
		button   BtnBrowseMesh   "..."     align:#right height:16
		checkbox ChkMeshRecurse  "Look in subfolders" checked:g_SearchFBXRecurse
		
	)
	
	group "Options"
	(
		checkbox ChkReplaceOriFBX  "Replace Orign File" checked:g_ReplaceOriFBX
		checkbox ChkSkipWhenNoMaterial  "Skip When No Material" checked:g_SkipWhenNoMaterial
		checkbox ChkCleanAnimation  "Clean Animation" checked:g_CleanAnimation
		checkbox ChkCleanLight  "Clean Light" checked:g_CleanLight
		checkbox ChkCleanCamera  "Clean Camera" checked:g_CleanCamera
	)
	group "Action"
	(
		button   BtnStart "StartClean"
	)

	on EdMeshPath        		changed val 	do g_FBXRootDir = val
	on ChkMeshRecurse    		changed state 	do g_SearchFBXRecurse = state
	on ChkReplaceOriFBX	 	 	changed state 	do g_ReplaceOriFBX = state
	on ChkSkipWhenNoMaterial	changed state 	do g_SkipWhenNoMaterial = state
	on ChkCleanAnimation	 	changed state 	do g_CleanAnimation = state
	on ChkCleanLight	 		changed state 	do g_CleanLight = state
	on ChkCleanCamera	 		changed state 	do g_CleanCamera = state
	
	on BtnBrowseMesh     pressed do
	(
		dir = getSavePath caption:"Directory for FBX lookup" initialDir:g_FBXRootDir
		if dir != undefined then
		(
			g_FBXRootDir    = dir
			EdMeshPath.text = dir
		)
	)
	on BtnStart   pressed do (
		with redraw off
		(
			with undo off
			(
				CleanMats g_FBXRootDir g_SearchFBXRecurse
			)
		)
	)
)


if fbxCleanerFloater != undefined do closeRolloutFloater fbxCleanerFloater	-- close old window if visible
fbxCleanerFloater = newRolloutFloater "FBX Batch Cleaner" 350 350 300 100 	-- create new window

addRollout fbxCleanerRollOut fbxCleanerFloater

