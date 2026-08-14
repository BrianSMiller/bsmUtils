function defs = readJsonDefinitions(jsonPath)
%READJSONDEFINITIONS Read a keyed JSON registry into a MATLAB struct.
%
%   defs = readJsonDefinitions(jsonPath)
%
%   Works for any flat JSON object keyed by ID, e.g. siteDefinitions.json
%   or detectorDefinitions.json. Each key becomes a field of defs, so
%   defs.(siteCode) or defs.(detectorID) gives you that entry's struct.
%
%   Mirrors siteDefinitions.R's jsonlite::fromJSON call. No schema
%   assumptions here on purpose -- callers pull the fields they need.
%
%   Example:
%       siteDefs = readJsonDefinitions(fullfile(awrRoot,'data/siteDefinitions_AWR.json'));
%       siteDefs.Kerguelen2015.latitude
%
%       detectorDefs = readJsonDefinitions(fullfile(awrRoot,'data/detectorDefinitions.json'));
%       fieldnames(detectorDefs)

if ~isfile(jsonPath)
    error('readJsonDefinitions:fileNotFound','JSON file not found: %s',jsonPath);
end

raw = fileread(jsonPath);
defs = jsondecode(raw);

end
