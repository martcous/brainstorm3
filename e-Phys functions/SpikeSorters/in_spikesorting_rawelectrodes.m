function sFiles = in_spikesorting_rawelectrodes( sInput )
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

protocol = bst_get('ProtocolInfo');
parentPath = bst_fullfile(bst_get('BrainstormTmpDir'), ...
                       'Unsupervised_Spike_Sorting', ...
                       protocol.Comment, ...
                       sInput.FileName);

% Make sure the temporary directory exist, otherwise create it
if ~exist(parentPath, 'dir')
    mkdir(parentPath);
end

DataMat = in_bst_data(sInput.FileName, 'F');
ChannelMat = in_bst_channel(sInput.ChannelFile);
sFile = DataMat.F;
numChannels = length(ChannelMat.Channel);
sr = sFile.prop.sfreq;
sFiles = {};
bst_progress('start', 'Spike-sorting', 'Demultiplexing raw file...', 0, numChannels);

for iChannel = 1:numChannels
    chanFile = bst_fullfile(parentPath, ['raw_elec' num2str(sFile.header.ChannelID(iChannel)) '.mat']);
    
    % If the channel file doesn't exist, create on the fly
    if ~exist(chanFile, 'file')
        data = in_fread(sFile, ChannelMat, 1, [], iChannel);
        save(chanFile, 'data', 'sr');
    end
    
    sFiles{end+1} = chanFile;
    bst_progress('inc', 1);
end
