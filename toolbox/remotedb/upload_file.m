function [counter] = upload_file(filelocation,uploadid,filesize,filename)
% Upload: Upload file function

% @=============================================================================
% This function is part of the Brainstorm software:
% https://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2019 University of Southern California & McGill University
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
% Authors: Chaoyi Liu 2020

blocksize = 10000000; % 10MB per request
counter = 1;
fileID = fopen(filelocation,'r');
pointer = 0;
bst_progress('start', 'uploading', char(filename), 0, filesize);
while ~feof(fileID)
    blockcontent = fread(fileID,blocksize,'*uint8');
    counter = counter + 1;
    [response,status] = HTTP_request(['file/upload/' uploadid '/false'], 'POST', blockcontent, 'Stream');
    if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
        java_dialog('warning',status);
        return;
    end
    pointer = pointer + blocksize;
    bst_progress('set', pointer);
end

[response,status] = HTTP_request(['file/upload/' uploadid '/true'], 'POST', blockcontent, 'Stream');
if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
    java_dialog('warning',status);
    return;
end
bst_progress('stop');
fclose(fileID);

end

