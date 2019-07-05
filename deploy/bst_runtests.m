function runtests(forced)

if nargin < 1 || isempty(forced)
    forced = 0;
end

% If Brainstorm is not running, start it
if ~isappdata(0, 'BrainstormRunning')
    brainstorm server;
end

% Make sure we are not already running a test
isTestingFile = bst_fullfile(bst_get('BrainstormUserDir'), 'is_testing.txt');
if exist(isTestingFile, 'file') == 2
    fileID = fopen(isTestingFile, 'r');
    isTesting = fscanf(fileID, '%d');
    fclose(fileID);
    if isTesting
        disp('Testing already in progress.');
        if ~forced
            return;
        end
    end
end

% Lock for testing
fileID = fopen(isTestingFile, 'w');
fprintf(fileID,'%d', 1);
fclose(fileID);

% Clear previous tests results
testFile = bst_fullfile(bst_get('BrainstormUserDir'), 'test_result.txt');
if exist(testFile, 'file') == 2
    delete(testFile);
end

% Initialize test result structure
testInfo = struct();
testInfo.StartTime = datestr(datetime('now'));
testInfo.Tests = struct('Name', [], 'Result', [], 'ElapsedTime', []);
iTest = 1;

% Find all processes
allProcesses = dir(bst_fullfile(bst_get('BrainstormHomeDir'), 'toolbox', 'process', 'functions', 'process_*.m'));
for iProcess = 1:length(allProcesses)
    % Run Test function of process
    processName = allProcesses(iProcess).name(9:end-2);
    processFunc = str2func(allProcesses(iProcess).name(1:end-2));
    try
        tic;
        result = processFunc('Test');
        skip = 0;
    catch e
        % If we could not find a Test() function for this process, skip it
        if strcmpi(e.identifier, 'MATLAB:dispatcher:InexactCaseMatch')
            skip = 1;
        % If we encountered another exception, assume the test failed
        else
            result = 0;
        end
    end
    % Save test result
    if skip
        disp(['Warning: No Test found for process ' processName]);
    else
        testInfo.Tests(iTest).Name = processName;
        testInfo.Tests(iTest).Result = result;
        testInfo.Tests(iTest).ElapsedTime = toc;
        iTest = iTest + 1;
    end
end

% Print tests output
testInfo.EndTime = datestr(datetime('now'));
fid = fopen(testFile, 'wt');
jsonText = bst_jsonencode(testInfo);
fprintf(fid, jsonText);
fclose(fid);

% Remove testing lock
fileID = fopen(isTestingFile, 'w');
fprintf(fileID,'%d', 0);
fclose(fileID);
