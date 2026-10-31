--!strict
-- Stand-alone Studio EDIT command. Captures the real official prefab hierarchy
-- for review without requiring or replacing any gameplay modules in the place.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(),"Pare o Play e execute em modo de edicao do Studio")
local AssetService=game:GetService("AssetService")
local ServerStorage=game:GetService("ServerStorage")
local Selection=game:GetService("Selection")
local sources={
    {Id="Rifle",AssetId=96131146947811},
    {Id="SMG",AssetId=119916677125479},
    {Id="Shotgun",AssetId=104068096273092},
    {Id="Pistol",AssetId=118912302094201},
}
local base="ZO_OfficialWeaponReview_"..tostring(os.time())
local label=base
local suffix=1
while ServerStorage:FindFirstChild(label) do suffix+=1;label=base.."_"..suffix end
local review=Instance.new("Folder")
review.Name=label
review:SetAttribute("ReviewOnly",true)
review:SetAttribute("Status","Loading")
review.Parent=ServerStorage
local captured,failed=0,0
local function path(root: Instance,item: Instance): string
    local names={item.Name}
    local parent=item.Parent
    while parent and item~=root do
        table.insert(names,1,parent.Name)
        if parent==root then break end
        parent=parent.Parent
    end
    return table.concat(names,"/")
end
local function unsafe(item: Instance): boolean
    return item:IsA("LuaSourceContainer") or item:IsA("RemoteEvent")
        or item:IsA("UnreliableRemoteEvent") or item:IsA("RemoteFunction")
        or item:IsA("BindableEvent") or item:IsA("BindableFunction") or item:IsA("PackageLink")
end
for _,source in sources do
    local container: Instance?=nil
    local entry: Folder?=nil
    local ok,problem=pcall(function()
        container=AssetService:LoadAssetAsync(source.AssetId)
        local root=container :: Instance
        assert(root and root.Parent==nil,"Expected a detached asset container")
        assert(not unsafe(root),"Unsupported executable root container")
        entry=Instance.new("Folder")
        local current=entry :: Folder
        current.Name=source.Id
        current:SetAttribute("SourceAssetId",source.AssetId)
        current:SetAttribute("OriginalRootClass",root.ClassName)
        current:SetAttribute("OriginalRootName",root.Name)
        local archived=Instance.new("Folder");archived.Name="ReviewSources";archived.Parent=current
        local nodes={root}
        for _,item in root:GetDescendants() do table.insert(nodes,item) end
        local lines={}
        local tools,meshes,scripts=0,0,0
        for _,item in nodes do
            local line=path(root,item).." ["..item.ClassName.."]"
            if item:IsA("Tool") then
                tools+=1
                line..=" RequiresHandle="..tostring(item.RequiresHandle).." DirectHandle="..tostring(item:FindFirstChild("Handle")~=nil)
            elseif item:IsA("MeshPart") then meshes+=1 end
            table.insert(lines,line)
            if item:IsA("LuaSourceContainer") then
                scripts+=1
                local text=Instance.new("StringValue")
                text.Name="Source_"..scripts
                text:SetAttribute("OriginalPath",path(root,item))
                text:SetAttribute("OriginalClass",item.ClassName)
                local readable,value=pcall(function() return (item :: LuaSourceContainer).Source end)
                text.Value=if readable then value else "Source unavailable: "..tostring(value)
                text:SetAttribute("SourceReadable",readable)
                text.Parent=archived -- Plain text is never executed or required.
            end
        end
        -- Preserve non-code children even if an upstream script owns geometry.
        -- All source paths above were recorded before changing this hierarchy.
        for _,item in nodes do
            if unsafe(item) then
                for _,child in item:GetChildren() do child.Parent=item.Parent end
                item:Destroy()
            elseif item:IsA("Sound") then
                item.Playing=false
                item.PlayOnRemove=false
            end
        end
        for _,item in root:GetDescendants() do assert(not unsafe(item),"Executable content survived review sanitization") end
        current:SetAttribute("ToolCount",tools)
        current:SetAttribute("MeshPartCount",meshes)
        current:SetAttribute("ArchivedSourceCount",scripts)
        local report=Instance.new("StringValue")
        report.Name="OriginalHierarchy"
        report.Value=table.concat(lines,"\n")
        report.Parent=current
        root.Parent=current
        current.Parent=review -- Only sanitized containers ever enter the DataModel.
        captured+=1
        print(("[K17 REVIEW] %s (%d): capturado; Tools=%d MeshParts=%d fontes-texto=%d")
            :format(source.Id,source.AssetId,tools,meshes,scripts))
        for index=1,math.min(#lines,12) do print("[K17 REVIEW]   "..lines[index]) end
        if #lines>12 then print("[K17 REVIEW]   Arvore completa em OriginalHierarchy.") end
    end)
    if not ok then
        failed+=1
        if entry then entry:Destroy() end
        if container then container:Destroy() end
        warn(("[K17 REVIEW] %s (%d): %s"):format(source.Id,source.AssetId,tostring(problem)))
    end
end
review:SetAttribute("CapturedCount",captured)
review:SetAttribute("FailedCount",failed)
review:SetAttribute("Status",if failed==0 then "Ready" elseif captured>0 then "Partial" else "Failed")
Selection:Set({review})
print(("[K17 REVIEW] Resultado: %d capturados; %d falhas. Pasta: ServerStorage.%s"):format(captured,failed,review.Name))
if captured>0 then
    print("[K17 REVIEW] Exporte a pasta selecionada como ZO_OfficialWeaponReview.rbxm ou .rbxmx e envie para integrar os modelos reais ao Git.")
    print("[K17 REVIEW] O jogo e os templates ativos nao foram substituidos. Os scripts capturados estao apenas como texto para revisao.")
else warn("[K17 REVIEW] Nenhum modelo capturado; envie as mensagens acima antes de exportar.") end
