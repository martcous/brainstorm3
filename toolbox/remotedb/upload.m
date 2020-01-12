function [counter] = upload(filelocation)
% Upload: Upload different files

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
% Authors: Zeyu Chen, Chaoyi Liu 2019

%uploadid = "4deb53de-b4c0-4d1b-9f9d-3b448bb158ba";


blocksize = 1000000; % 1MB per request
counter = 1;
fileID = fopen(filelocation,'r');
url=strcat(string(bst_get('UrlAdr')),"/file/upload/", uploadid, "/");
while ~feof(fileID)
    blockcontent = fread(fileID,blocksize,'*uint8');
    counter = counter + 1;
    [response,status] = bst_call(@HTTP_request,'POST','Stream',blockcontent,url+"false");
    if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
        java_dialog('warning',status);
        return;
    end
end

[response,status] = bst_call(@HTTP_request,'POST','Stream',blockcontent,url+"true");
if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
    java_dialog('warning',status);
    return;
end
fclose(fileID);
disp(counter);





end

