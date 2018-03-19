function sFiles = in_spikesorting_rawelectrodes( varargin )
% IN_SPIKESORTING_RAWELECTRODES: Loads and creates if needed separate raw
% electrode files for spike sorting purposes.
%
% USAGE: OutputFiles = process_spikesorting_unsupervised('Run', sProcess, sInputs)

% @=============================================================================
% This function is part of the Brainstorm software:
% http://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2018 University of Southern California & McGill University
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
% Authors: Konstantinos Nasiotis, 2018; Martin Cousineau, 2018

sInput = varargin{1};
if nargin < 2
    ram = 1e9; % 1 GB
else
    ram = varargin{2};
end

protocol = bst_get('ProtocolInfo');
parentPath = bst_fullfile(bst_get('BrainstormTmpDir'), ...
                       'Unsupervised_Spike_Sorting', ...
                       protocol.Comment, ...
                       sInput.FileName);

% Make sure the temporary directory exist, otherwise create it
if ~exist(parentPath, 'dir')
    mkdir(parentPath);
end

% Check whether the electrode files already exist
ChannelMat = in_bst_channel(sInput.ChannelFile);
numChannels = length(ChannelMat.Channel);
missingFile = 0;
sFiles = {};
for iChannel = 1:numChannels
    chanFile = bst_fullfile(parentPath, ['raw_elec' num2str(iChannel) '.mat']);
    if ~exist(chanFile, 'file')
        missingFile = 1;
    else
        sFiles{end+1} = chanFile;
    end
end
if ~missingFile
    return;
else
    % Clear any remaining intermediate file
    for iFile = 1:length(sFiles)
        delete(sFiles{iFile});
    end
end

% Otherwise, generate all of them again.
DataMat = in_bst_data(sInput.FileName, 'F');
sFile = DataMat.F;
sr = sFile.prop.sfreq;
sFiles = {};
samples = [0,0];
max_samples = ram / 8 / numChannels;
total_samples = sFile.prop.samples(2);
num_segments = ceil(total_samples / max_samples);
num_samples_per_segment = ceil(total_samples / num_segments);
bst_progress('start', 'Spike-sorting', 'Demultiplexing raw file...', 0, num_segments + numChannels);

% Read data in segments
for iSegment = 1:num_segments
    samples(1) = (iSegment - 1) * num_samples_per_segment;
    if iSegment < num_segments
        samples(2) = iSegment * num_samples_per_segment - 1;
    else
        samples(2) = total_samples;
    end
    
    F = in_fread(sFile, ChannelMat, [], samples);

    % Append segment to individual channel file
    for iChannel = 1:numChannels
        chanFile = bst_fullfile(parentPath, ['raw_elec' num2str(iChannel)]);
        electrode_data = F(iChannel,:);
        fid = fopen([chanFile '.bin'], 'a');
        fwrite(fid, electrode_data, 'double');
        fclose(fid);
    end
    bst_progress('inc', 1);
end

% Convert channel files to Matlab
for iChannel = 1:numChannels
    chanFile = bst_fullfile(parentPath, ['raw_elec' num2str(iChannel)]);
    fid = fopen([chanFile '.bin'], 'rb');
    data = fread(fid, 'double');
    fclose(fid);
    save([chanFile '.mat'], 'data', 'sr');
    file_delete([chanFile '.bin'], 1 ,3);
    sFiles{end+1} = [chanFile '.mat'];
    bst_progress('inc', 1);
end
