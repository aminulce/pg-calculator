function [ idxS ] = idxFind( S,str )
    idxS = strfind(S, str);
    idxS = find(not(cellfun('isempty', idxS)));
end
