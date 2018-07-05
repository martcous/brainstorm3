function F = in_fread_intan(sFile, SamplesBounds, selectedChannels)
% IN_FREAD_INTAN Read a block of recordings from Intan files
%
% USAGE:  F = in_fread_intan(sFile, SamplesBounds=[], iChannels=[])

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
% Authors: Konstantinos Nasiotis 2018


% Parse inputs
if (nargin < 3) || isempty(selectedChannels)
    selectedChannels = 1:sFile.header.ChannelCount;
end
if (nargin < 2) || isempty(SamplesBounds)
    SamplesBounds = sFile.prop.samples;
end

nChannels = length(selectedChannels);
nSamples = SamplesBounds(2) - SamplesBounds(1) + 1;

if sFile.header.chan_headers.AcqType==1
    % Read the corresponding recordings
    data_and_headers = read_Intan_RHD2000_file(sFile.header.DataFile,1,0,SamplesBounds(1) + 1,nSamples); % This loads all the channels. 
    %newHeader = read_Intan_RHD2000_file(filename,loadData,loadEvents,iSamplesStart,nSamplesToLoad)
end
    
F = zeros(nChannels, nSamples);

ii = 0;
for iChannel = selectedChannels
    ii = ii + 1;
    if sFile.header.chan_headers.AcqType==2
        fid = fopen(fullfile(sFile.filename, sFile.header.chan_files(iChannel).name), 'r');
        fseek(fid, SamplesBounds(1)*2, 'bof'); % int16 precision: 1 sample = 2 bytes
        data_channel = fread(fid, nSamples, 'int16');
        F(ii,:) = data_channel * 0.195; % Convert to microvolts
        fclose(fid);
    else
        F(ii,:) = data_and_headers.amplifier_channels(iChannel).amplifier_data;
    end
end
