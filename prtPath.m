function nfprtPath
%This function adds necessary directories for the gatool to your path.
P = genpath(prtRoot);
addpath(P);

%Remove some paths we don't need

removePath = [];
[string,remString] = strtok(P,pathsep);
while ~isempty(string);
    if ~isempty(strfind(string,[filesep '.svn']))
        removePath = cat(2,removePath,pathsep,string);
    end
    [string,remString] = strtok(remString,pathsep); %#ok
end
rmpath(removePath);