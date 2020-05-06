function varargout = process_import_calcium_image(varargin)
% PROCESS_IMPORT_CALCIUM_IMAGE: Import a calcium image (WIP)

% @=============================================================================
% This function is part of the Brainstorm software:
% https://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2020 University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPLv3
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors: Martin Cousineau, 2020

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Import calcium image';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Import';
    sProcess.Index       = 42;
    sProcess.Description = [];
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'import'};
    sProcess.OutputTypes = {'results'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 0;
    % Option: Subject name
    sProcess.options.subjectname.Comment = 'Subject name:';
    sProcess.options.subjectname.Type    = 'subjectname';
    sProcess.options.subjectname.Value   = 'NewSubject';
    % Option: File to import
    sProcess.options.datafile.Comment = 'File to import:';
    sProcess.options.datafile.Type    = 'filename';
    sProcess.options.datafile.Value   = {...
        '', ...                                % Filename
        '', ...                                % FileFormat
        'open', ...                            % Dialog type: {open,save}
        'Open Calcium image...', ...           % Window title
        'ImportData', ...                      % LastUsedDir: {ImportData,ImportChannel,ImportAnat,ExportChannel,ExportData,ExportAnat,ExportProtocol,ExportImage,ExportScript}
        'single', ...                          % Selection mode: {single,multiple}
        'files', ...                           % Selection mode: {files,dirs,files_and_dirs}
        {{'.tif'}, 'TIFF image (*.tif)', 'TIFF'; ... % Get all the available file formats
         {'.mat'}, 'Suite2P Matlab output (Fall.mat)', 'SUITE2P'}, ... 
        'DataIn'};                             % DefaultFormats
    % Option: Sampling rate
    sProcess.options.samplingrate.Comment = 'Original sampling rate:';
    sProcess.options.samplingrate.Type    = 'value';
    sProcess.options.samplingrate.Value   = {300, 'Hz', 0};
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    OutputFiles = {};
    
    % ===== GET OPTIONS =====
    % Get subject name
    SubjectName = file_standardize(sProcess.options.subjectname.Value);
    if isempty(SubjectName)
        bst_report('Error', sProcess, [], 'Subject name is empty.');
        return
    end
    % Get filename to import
    FileName   = sProcess.options.datafile.Value{1};
    FileFormat = sProcess.options.datafile.Value{2};
    if isempty(FileName)
        bst_report('Error', sProcess, [], 'No file selected.');
        return
    end
    % Get sampling rate
    srate = sProcess.options.samplingrate.Value{1};
    if isempty(srate)
        bst_report('Error', sProcess, [], 'No sampling rate entered.');
        return
    end
    
    % ===== IMPORT FILES =====
    % Get subject 
    [sSubject, iSubject] = bst_get('Subject', SubjectName);
    % Create subject is it does not exist yet
    if isempty(sSubject)
        [sSubject, iSubject] = db_add_subject(SubjectName);
    end
    
    switch FileFormat
        case 'TIFF'
            % Read image metadata
            imgInfo = imfinfo(FileName);
            numImgs = size(imgInfo, 1);
            firstSlice = imread(FileName, 1)';
            
            % Create source object
            numSources = numel(firstSlice);
            numSamples = numImgs;
            dataMatrix = zeros(numSources, numSamples);

            % Read image
            bst_progress('start', 'Import calcium image', 'Reading image...', 0, numImgs);
            for iImg = 1:numImgs
                I = double(imread(FileName, iImg)');
                dataMatrix(:, iImg) = I(:);
                bst_progress('inc', 1);
            end
            avgSlice = reshape(mean(dataMatrix, 2), size(firstSlice));
            mipSlice = max(dataMatrix, [], 2);

            % Create "MRI" structure from average slice
            bst_progress('start', 'Import calcium image', 'Creating MRI object...');
            SaveCalciumMri(FileName, avgSlice, sSubject, iSubject);

            % Create "Surface" structure
            bst_progress('text', 'Creating surface object...');
            SurfaceFile = SaveCalciumSurface(FileName, size(firstSlice), sSubject, iSubject);

            % Create "Source" structure from whole data
            bst_progress('text', 'Creating source object...');
            OutputFiles{end + 1} = SaveCalciumSource(FileName, 'Raw calcium image', sSubject, dataMatrix, size(firstSlice), srate, SurfaceFile);

            % Create "Source" structure for MIP
            bst_progress('text', 'Creating MIP object...');
            OutputFiles{end + 1} = SaveCalciumSource(FileName, 'MIP calcium image', sSubject, mipSlice, size(firstSlice), srate, SurfaceFile);

        case 'SUITE2P'
            imgInfo = load(FileName);
            
            % Extract and normalize average slice
            avgSlice = double(imgInfo.ops.meanImg);
            avgMin = min(avgSlice(:));
            avgMax = max(avgSlice(:));
            avgSlice = (avgSlice - avgMin) / (avgMax - avgMin);
            
            % Extract and normalize maximum projection slice
            mipSlice = double(imgInfo.ops.max_proj);
            mipMin = min(mipSlice(:));
            mipMax = max(mipSlice(:));
            mipSlice = (mipSlice - mipMin) / (mipMax - mipMin);
            mipSlice = reshape(mipSlice, numel(mipSlice), 1);
            
            % Create "MRI" structure from average slice
            bst_progress('start', 'Import calcium image', 'Creating MRI object...');
            SaveCalciumMri(FileName, avgSlice, sSubject, iSubject);
            
            % Create "Surface" structure
            bst_progress('text', 'Creating surface object...');
            SurfaceFile = SaveCalciumSurface(FileName, size(avgSlice), sSubject, iSubject);
            
            % Create "Source" structure for MIP
            bst_progress('text', 'Creating MIP object...');
            [OutputFiles{end + 1}, iStudy, GridLoc] = SaveCalciumSource(FileName, 'MIP calcium image', sSubject, mipSlice, size(avgSlice), srate, SurfaceFile);
            
            % Import ROIs as scouts
            bst_progress('text', 'Importing ROIs...');
            import_label(SurfaceFile, FileName, 0, GridLoc);
            
            % Import processed data as matrix
            bst_progress('text', 'Creating matrix object...');
            SaveProcessedMatrix(FileName, imgInfo, iStudy, srate);
        otherwise
            bst_report('Error', sProcess, [], 'Unsupported file format.');
            return
    end
    
    bst_progress('stop');
end

function SaveCalciumMri(FileName, slice, sSubject, iSubject)
    sMri = db_template('mrimat');
    sMri.Comment = 'Calcium slice';
    % Ensure we have 3 dimensions
    switch ndims(slice)
        case 2
            sMri.Cube = cat(3, slice, slice);
        case 3
            sMri.Cube = slice;
        otherwise
            error('Invalid number of dimensions in image');
    end
    sMri.Voxsize = [1,1,1];
    sMri.SCS = db_template('scs');
    sMri.SCS.R = eye(3);
    sMri.SCS.T = zeros(3,1);
    
    % Get Protocol information
    ProtocolInfo     = bst_get('ProtocolInfo');
    ProtocolSubjects = bst_get('ProtocolSubjects');

    %% ===== SAVE MRI IN BRAINSTORM FORMAT =====
    % Use filename as comment
    % Get subject subdirectory
    subjectSubDir = bst_fileparts(sSubject.FileName);
    % Get imported base name
    [tmp__, importedBaseName] = bst_fileparts(FileName);
    importedBaseName = strrep(importedBaseName, 'subjectimage_', '');
    importedBaseName = strrep(importedBaseName, '_subjectimage', '');
    % Produce a default anatomy filename
    fileTag = 'calcium';
    BstMriFile = bst_fullfile(ProtocolInfo.SUBJECTS, subjectSubDir, ['subjectimage_' importedBaseName fileTag '.mat']);
    % Make this filename unique
    BstMriFile = file_unique(BstMriFile);
    % Save new MRI in Brainstorm format
    sMri = out_mri_bst(sMri, BstMriFile);

    %% ===== STORE NEW MRI IN DATABASE ======
    % New anatomy structure
    iAnatomy = length(sSubject.Anatomy) + 1;
    if iAnatomy > 0
        % Make sure name in database is unique
        allComments = {sSubject.Anatomy.Comment};
        MriComment = sMri.Comment;
        iSuffix = 2;
        while ismember(MriComment, allComments)
            MriComment = [sMri.Comment ' (' num2str(iSuffix) ')'];
            iSuffix = iSuffix + 1;
        end
    end
    sSubject.Anatomy(iAnatomy) = db_template('Anatomy');
    sSubject.Anatomy(iAnatomy).FileName = file_short(BstMriFile);
    sSubject.Anatomy(iAnatomy).Comment  = MriComment;
    % Default anatomy: do not change
    if isempty(sSubject.iAnatomy)
        sSubject.iAnatomy = iAnatomy;
    end

    % === Update database ===
    % Default subject
    if (iSubject == 0)
        ProtocolSubjects.DefaultSubject = sSubject;
    % Normal subject 
    else
        ProtocolSubjects.Subject(iSubject) = sSubject;
    end
    bst_set('ProtocolSubjects', ProtocolSubjects);

    % === Save first MRI as permanent default ===
    if (iAnatomy == 1)
        db_surface_default(iSubject, 'Anatomy', iAnatomy, 0);
    end


    %% ===== UPDATE GUI =====
    % Refresh tree
    panel_protocols('UpdateNode', 'Subject', iSubject);
    panel_protocols('SelectNode', [], 'subject', iSubject, -1 );
    % Save database
    db_save();
    % Unload MRI (if a MRI with the same name was previously loaded)
    bst_memory('UnloadMri', BstMriFile);
end

function SurfaceFile = SaveCalciumSurface(FileName, volDims, sSubject, iSubject)
    % Build new surface
    sSurf = db_template('surfacemat');
    sSurf.Comment  = 'Calcium surface';
    
    % Build Vertices
    [X,Y] = ndgrid(1:volDims(1), 1:volDims(2));
    sSurf.Vertices = zeros(prod(volDims), 3);
    sSurf.Vertices(:,1) = X(:);
    sSurf.Vertices(:,2) = Y(:);
    sSurf.Vertices(:,3) = 2;
    sSurf.Vertices = sSurf.Vertices / 1000;
    sSurf.VertNormals = zeros(prod(volDims), 3);
    sSurf.VertNormals(:,3) = 1;
    sSurf.SulciMap = zeros(prod(volDims), 1);
    
    % Add volume atlas for ROIs
    sSurf.Atlas(2) = db_template('atlas');
    sSurf.Atlas(2).Name = ['Volume ' num2str(prod(volDims))];
    sSurf.iAtlas = 2;
    
    % Build Faces
    sSurf.Faces = zeros(2 * prod(volDims - 1), 3);
    iFace = 1;
    iVert = 1;
    for x = 1:volDims(1)-1
        for y = 1:volDims(2)-1
            sSurf.Faces(iFace, :) = [iVert, iVert + 1, iVert + volDims(2)];
            sSurf.Faces(iFace + 1, :) = [iVert + 1, iVert + volDims(2), iVert + volDims(2) + 1];
            iVert = iVert + 1;
            iFace = iFace + 2;
        end
    end
    
    % Build interpolation matrix
    nVertices = prod(volDims);
    sSurf.tess2mri_interp = [speye(nVertices); speye(nVertices)];
    
    % Make sure name in database is unique
    iSurface = length(sSubject.Surface);
    if iSurface > 0
        allComments = {sSubject.Surface.Comment};
        SurfComment = sSurf.Comment;
        iSuffix = 2;
        while ismember(SurfComment, allComments)
            SurfComment = [sSurf.Comment ' (' num2str(iSuffix) ')'];
            iSuffix = iSuffix + 1;
        end
    end

    % === SAVE NEW FILE ===
    ProtocolInfo  = bst_get('ProtocolInfo');
    subjectSubDir = bst_fileparts(sSubject.FileName);
    
    % Output filename
    [tmp__, importedBaseName] = bst_fileparts(FileName);
    SurfaceFile = bst_fullfile(subjectSubDir, ['tess_cortex_calcium_' importedBaseName '.mat']);
    NewTessFile = bst_fullfile(ProtocolInfo.SUBJECTS, SurfaceFile);
    NewTessFile = file_unique(NewTessFile);
    % Save file back
    bst_save(NewTessFile, sSurf, 'v7');
    % Register this file in Brainstorm database
    db_add_surface(iSubject, NewTessFile, sSurf.Comment);
end

function [OutputFile, iStudy, GridLoc] = SaveCalciumSource(rawFileName, comment, sSubject, dataMatrix, volDims, sRate, SurfaceFile)
    [nSources, nSamples] = size(dataMatrix);

    % Output filename
    [tmp, importedBaseName] = bst_fileparts(rawFileName);
    [sStudies, iStudies] = bst_get('StudyWithSubject', sSubject.FileName);
    iStudy = find(strcmp(importedBaseName, {sStudies.Name}));
    % Create output study if it does not exist
    if isempty(iStudy)
        iStudy = db_add_condition(sSubject.FileName, importedBaseName, 0);
        sStudy = bst_get('Study', iStudy);
    else
        sStudy = sStudies(iStudy);
        iStudy = iStudies(iStudy);
    end
    ResultFile = bst_process('GetNewFilename', bst_fileparts(sStudy.FileName), ['results_', importedBaseName]);
    
    % Build GridLoc
    [X,Y] = ndgrid(1:volDims(1), 1:volDims(2));
    GridLoc = zeros(nSources, 3);
    GridLoc(:,1) = X(:);
    GridLoc(:,2) = Y(:);
    GridLoc(:,3) = 2;
    GridLoc = GridLoc / 1000;
    
    % Build time samples
    if nSamples > 1
        Time = linspace(0, nSamples / sRate, nSamples);
    else
        Time = [0, 1e-3];
    end

    % ===== CREATE FILE STRUCTURE =====
    ResultsMat = db_template('resultsmat');
    ResultsMat.ImageGridAmp  = dataMatrix;
    ResultsMat.Comment       = comment;
    ResultsMat.Time          = Time;
    ResultsMat.HeadModelType = 'volume';
    ResultsMat.SurfaceFile   = SurfaceFile;
    ResultsMat.GridLoc       = GridLoc;
    ResultsMat.nAvg          = 1;
    % History
    ResultsMat = bst_history('add', ResultsMat, 'import', ['Import calcium image: ' rawFileName]);
    % Make sure name in database is unique
    allComments = {sStudy.Result.Comment};
    ResultComment = ResultsMat.Comment;
    iSuffix = 2;
    while ismember(ResultComment, allComments)
        ResultComment = [ResultsMat.Comment ' (' num2str(iSuffix) ')'];
        iSuffix = iSuffix + 1;
    end
    ResultsMat.Comment = ResultComment;
    % Save new file structure
    bst_save(ResultFile, ResultsMat, 'v6');

    % ===== REGISTER NEW FILE =====
    % Create new results structure
    newResult = db_template('results');
    newResult.Comment       = ResultsMat.Comment;
    newResult.FileName      = file_short(ResultFile);
    newResult.isLink        = 0;
    newResult.HeadModelType = 'volume';
    % Add new entry to the database
    iResult = length(sStudy.Result) + 1;
    sStudy.Result(iResult) = newResult;
    % Update Brainstorm database
    bst_set('Study', iStudy, sStudy);
    panel_protocols('UpdateNode', 'Study', iStudy);

    OutputFile = newResult.FileName;
end

function SaveProcessedMatrix(FileName, imgInfo, iStudy, srate)
    sStudy = bst_get('Study', iStudy);

    % Create empty matrix file structure
    FileMat = db_template('matrixmat');
    FileMat.Value       = imgInfo.F(logical(imgInfo.iscell(:,1)),:);
    FileMat.Time        = (1:size(imgInfo.F,2)) / srate;
    FileMat.Comment     = 'Suite2P Processed data';
    
    % Populate list of ROI names
    numRegions = size(imgInfo.iscell, 1);
    numCells   = sum(imgInfo.iscell(:, 1));
    labelSize  = length(num2str(numCells));
    FileMat.Description = cell(numCells,1);
    iCell = 1;
    for iRegion = 1:numRegions
        if imgInfo.iscell(iRegion, 1)
            label = num2str(iCell);
            while length(label) < labelSize
                label = ['0' label];
            end
            FileMat.Description{iCell} = label;
            iCell = iCell + 1;
        end
    end
    
    % ===== SAVE FILE =====
    % Output filename
    [tmp, importedBaseName] = bst_fileparts(FileName);
    MatrixFile = bst_process('GetNewFilename', bst_fileparts(sStudy.FileName), ['matrix_calcium_', bst_fileparts(importedBaseName)]);
    % Save file
    bst_save(MatrixFile, FileMat, 'v6');
    % Register in database
    db_add_data(iStudy, MatrixFile, FileMat);
end

