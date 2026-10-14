function projectRoot = setupProject()
%SETUPPROJECT Configure the MATLAB path for this repository.
%   PROJECTROOT = SETUPPROJECT() adds only configuration and reusable source
%   folders to the MATLAB path. Data, results, documentation, and scripts are
%   intentionally excluded.

projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'config'));
addpath(genpath(fullfile(projectRoot, 'src')));
end

