function status = download_file(studyID,subjectID)
% Download function take studyID or subjectID as input
% Output the status of downloading, "ok" for success, other for failure
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
% Authors: Zeyu Chen, Chaoyi Liu 2020

if ~isempty(studyID)
%handle study ffile
    [response,status] = HTTP_request(['study/get/' studyID], 'GET');
    if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
        %java_dialog('warning',status);
        return ;
    else
        data = jsondecode(response.Body.Data);
        filetype=["channels","timeFreqs","stats","headModels","results","matrixs","others"];
        bst_progress('start', 'Download', char(data.name), 0, 7);
        for i=1:7
            %if ~isempty(data.(filetype(i)))
                %bst_progress('start', 'download', char(filetype(i)), 0, length(data.(filetype(i))));
            %else
               % bst_progress('start', 'download', char(filetype(i)), 1, 1);
            %end
            for j=1:length(data.(filetype(i)))
                ftype=data.(filetype(i));
                fileID=ftype(j).id;
                fileName=ftype(j).fileName;
                
                [response2,status2] = HTTP_request(['file/download/ffile/' studyID '/' fileID], 'POST');
                if strcmp(status2,'200')~=1 && strcmp(status2,'OK')~=1
                    %java_dialog('warning',status);
                    bst_progress('stop');
                    return;
                else
                    protocolname = "DownloadProtocol";
                    filepath = strcat(string(bst_get('BrainstormDbDir')),"/",protocolname,"/data/");
                    filefullname=strcat(filepath,fileName);
                    %{
                     %check whether file exists
                     if exist(filefullname, 'file')
                        delete filefullname;
                     end
                    %}
                    filefullname = char(filefullname);
                    delim_pos = find(filefullname == '/', 1, 'last');
                    newfolder = filefullname(1:delim_pos-1);
                    if ~exist(newfolder, 'dir')
                        mkdir(newfolder);
                    end
                    fileID = fopen(filefullname,'w');
                    filestream = response2.Body.Data;
                    fwrite(fileID,filestream,'uint8');
                    fclose(fileID);
                    disp("finish download! "+fileName);
                end
                %bst_progress('set', j+1);
            end
            bst_progress('set', i+1);
            %bst_progress('stop');
        end
        bst_progress('stop');
    end

else
% handle subject afiles
    [response,status] = HTTP_request(['subject/get/' subjectID], 'GET');
    if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
        %java_dialog('warning',status);
        return;
    else
        data = jsondecode(response.Body.Data);
        studies=data.studies;
        filetype=["channels","timeFreqs","stats","headModels","results","matrixs","others"];
        for id=1:length(studies)
            study=studies(id);
            bst_progress('start', 'Download', char(study.name), 0, 7);
            for i=1:7
                %{
                if ~isempty(study.(filetype(i)))
                    bst_progress('start', 'Download', char(filetype(i)), 0, length(study.(filetype(i))));
                else
                    bst_progress('start', 'Download', char(filetype(i)), 1, 1);
                end
                %}
                for j=1:length(study.(filetype(i)))
                    ftype=study.(filetype(i));
                    fileID=ftype(j).id;
                    fileName=ftype(j).fileName;
                    [response2,status2] = HTTP_request(['file/download/afile/' subjectID '/' fileID], 'POST');
                    if strcmp(status2,'200')~=1 && strcmp(status2,'OK')~=1
                        %java_dialog('warning',status);
                        bst_progress('stop');
                        return;
                    else
                        protocolname = "DownloadProtocol";
                        filepath = strcat(string(bst_get('BrainstormDbDir')),"/",protocolname,"/anat/");
                        filefullname=strcat(filepath,fileName);
                        %{
                         %check whether file exists
                         if exist(filefullname, 'file')
                            delete filefullname;
                         end
                        %}
                        filefullname = char(filefullname);
                        delim_pos = find(filefullname == '/', 1, 'last');
                        newfolder = filefullname(1:delim_pos-1);
                        if ~exist(newfolder, 'dir')
                            mkdir(newfolder);
                        end
                        fileID = fopen(filefullname,'w');
                        filestream = response2.Body.Data;
                        fwrite(fileID,filestream,'uint8');
                        fclose(fileID);
                        disp("finish download! "+fileName);
                    end
                    %bst_progress('set', j+1);
                end
                bst_progress('set', i+1);
                %bst_progress('stop');
            end
            bst_progress('stop');
        end
    end
end

end

