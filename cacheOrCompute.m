function [result, wasCached] = cacheOrCompute(cacheFile, computeFn, varargin)
% cacheOrCompute  Generic load-from-cache-or-compute-and-save helper.
%
% Extracted from qcDetector.m's inline caching (2026-08-06) so the same
% load/warn/save behaviour can be reused across pipeline stages without
% hardcoding a path convention or duplicating the logic. qcDetector.m
% itself is NOT changed to use this yet -- see note at bottom.
%
%   result = cacheOrCompute(cacheFile, computeFn)
%   result = cacheOrCompute(cacheFile, computeFn, 'overwrite', true)
%
% Inputs
%   cacheFile - full path to the .mat cache file, e.g.
%               fullfile('data','qc',[cfg.name '.mat']) or
%               fullfile('data','cht',[siteCode '_bp20_gridded.mat']).
%               Caller builds this; no path convention is baked in here.
%   computeFn - function handle with NO arguments that performs the
%               actual (expensive) computation and returns one output.
%               Wrap whatever's needed in an anonymous function at the
%               call site, e.g.
%                 cacheOrCompute(cacheFile, @() qcDetector(cfg, true, false, false))
%               Note createCache=false in that example -- when wrapping
%               qcDetector specifically, disable ITS caching so this
%               wrapper is the only thing managing the cache file,
%               rather than the two disagreeing about it.
%
% Name-value args
%   createCache - if true (default), check cacheFile before computing,
%                 and save after a fresh compute. If false, caching is
%                 skipped entirely in both directions -- useful for
%                 one-off debugging without touching the cache.
%   overwrite   - if true, ignore any existing cache file and force a
%                 fresh compute, overwriting the cache afterward.
%                 Default false. No effect if createCache is false.
%   varName     - variable name used inside the .mat file. Default 'd',
%                 matching qcDetector.m's existing convention.
%
% Outputs
%   result    - the cached or freshly computed value.
%   wasCached - true if result came from cache, false if freshly computed.
%
% No staleness check against upstream inputs (no hash/mtime/size
% comparison) -- if whatever computeFn depends on changes, the cache
% won't know and will keep serving the old result until overwrite=true
% is passed explicitly. Same limitation as qcDetector.m's original
% inline version; not solved here either.
%
% NOT YET WIRED IN: qcDetector.m still has its own inline copy of this
% logic (hardcoded to data/qc/<cfg.name>.mat), not this function.
% Refactoring qcDetector.m to call this instead is a reasonable
% follow-up, but that file was just recovered from near-loss -- left
% alone here rather than touched again in the same pass. Ask before
% changing it.
%
% B. Miller, AAD, 2026

p = inputParser;
addParameter(p, 'createCache', true,  @(x) islogical(x) && isscalar(x));
addParameter(p, 'overwrite',   false, @(x) islogical(x) && isscalar(x));
addParameter(p, 'varName',     'd',   @(x) (ischar(x) || isstring(x)) && strlength(string(x)) > 0);
parse(p, varargin{:});
createCache = p.Results.createCache;
overwrite   = p.Results.overwrite;
varName     = char(p.Results.varName);

wasCached = false;

if createCache && exist(cacheFile, 'file') && ~overwrite
    warning('cacheOrCompute:loadedFromCache', ...
        ['Loading from cache instead of recomputing (%s exists). No ' ...
         'check has been made that the underlying inputs still match ' ...
         'this cache. Pass overwrite=true to force a fresh run.'], cacheFile);
    loaded = load(cacheFile, varName);
    result = loaded.(varName);
    wasCached = true;
    return;
end

result = computeFn();

if createCache
    cacheDir = fileparts(cacheFile);
    if ~isempty(cacheDir) && ~exist(cacheDir, 'dir')
        mkdir(cacheDir);
    end
    fprintf('cacheOrCompute: saving %s\n', cacheFile);
    s.(varName) = result;
    save(cacheFile, '-struct', 's');
end

end
