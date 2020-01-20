function [outputArg1,outputArg2] = download_file(studyID)

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
% Authors: Zeyu Chen 2020



url=strcat(string(bst_get('UrlAdr')),"/study/get/",studyID);
[response,status] = bst_call(@HTTP_request,'GET','Default',struct(),url,1);


if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
    java_dialog('warning',status);
    return;
else
     data = jsondecode(response.Body.Data);
     
     filepath=data.filename;
     channels=data.channels;
     timeFreqs=data.timeFreqs;
     stats=data.stats;
     headModels.data.headModels;
     results=data.results;
     matrixs=data.matrixs;
     
     filetype=[filepath,channels,timeFreqs,stats,headModels,results,matrixs];
     for i=1:length(filetype)
         for j=1:length(filetype(i))
             ftype=filetype(i);
             fileID=ftype(j).id;
             fileName=ftype(j).fileName;
             url2=strcat(string(bst_get('UrlAdr')),"/file/download/",studyID);
             url2=strcat(url2,"/",fileID);
             [response2,status2] = bst_call(@HTTP_request,'POST','Default',struct(),url2,1);
             if strcmp(status2,'200')~=1 && strcmp(status2,'OK')~=1
                java_dialog('warning',status);
                return;
             else
                 filesize = double(response2.Body.Data);
                 start = 0;
                 fileID = fopen(strcat(filepath,fileName),'w');
                 bst_progress('start', 'downloading', 'downloading file',0,filesize);
                 while(start < filesize)
                     [response2,status2] = bst_call(@HTTP_request,'POST','Default',struct(),strcat(url2,"/", num2str(start),"/",num2str(blocksize)));
                     if strcmp(status2,'200')~=1 && strcmp(status2,'OK')~=1
                         java_dialog('warning',status2);
                         return;
                     end
                     bst_progress('set', start);
                     start = start + blocksize;
                     filestream = response2.Body.Data;
                     fwrite(fileID,filestream,'uint8');
                 end
                 bst_progress('stop');
                 fclose(fileID);
                 disp("finish download!");
             end
         end
     end
     
     
end


%{
filename = "300mb.zip";
blocksize = 10000000; %10mb
url=strcat(string(bst_get('UrlAdr')),"/file/download/",filename);
[response,status] = bst_call(@HTTP_request,'GET','Default',struct(),url,1);

if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
    java_dialog('warning',status);
    return;
end
filesize = double(response.Body.Data);
start = 0;
fileID = fopen(strcat('/Users/chaoyiliu/Desktop/data/',filename),'w');
bst_progress('start', 'downloading', 'downloading file',0,filesize);
while(start < filesize)
    [response,status] = bst_call(@HTTP_request,'GET','Default',struct(),strcat(url,"/", num2str(start),"/",num2str(blocksize)));
    if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
        java_dialog('warning',status);
        return;
    end
    bst_progress('set', start);
    start = start + blocksize;
    filestream = response.Body.Data;
    fwrite(fileID,filestream,'uint8');
end
bst_progress('stop');
fclose(fileID);
disp("finish download!");
%}

end

