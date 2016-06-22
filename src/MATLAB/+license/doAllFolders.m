dlist = dir('*');
for dd=1:length(dlist)
    if ~dlist(dd).isdir || length(dlist(dd).name)<4
        continue
    end
    if strcmp(dlist(dd).name,'+assign') | strcmp(dlist(dd).name,'+matlab_bgl')
        continue
    end
    goHeader(['.\' dlist(dd).name '\']);
    
end
goHeader('.\');
