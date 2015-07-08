function edgeEditCount = GetFamilyTrackEditCount(familyID, bIncludeUser, bIncludeAuto)
    global EditList
    
    famHulls = Families.GetAllHulls(familyID);
    
    bChkEdits = arrayfun(@(x)((x.bUserEdit && bIncludeUser) || (~x.bUserEdit && bIncludeAuto)), EditList);
    chkEdits = EditList(bChkEdits);
    
    bEdgeEdits = arrayfun(@(x)(strcmp(x.action,'SetEdge') || strcmp(x.action,'RemoveEdge') || strcmp(x.action,'Mitosis')), chkEdits);
    edgeEdits = chkEdits(bEdgeEdits);
    
    bFamEdgeEdit = arrayfun(@(x)(any(ismember(x.input,famHulls))), edgeEdits);
    
    edgeEditCount = nnz(bFamEdgeEdit);
end