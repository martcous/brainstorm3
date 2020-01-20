function upload_protocol_files()
% Create: create a functional file in remote database

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

% set overwrite = 0 if the local protocol's remoteID matches remote database
% otherwise set overwrite = 1
% In production phase always set overwrite = 0;
overwrite = 1;
create_protocol();
protocol_id = bst_get('ProtocolId');
local_subjects = bst_get('ProtocolSubjects');
create_subject(protocol_id,local_subjects.DefaultSubject,0,overwrite);
subjects = local_subjects.Subject;
for i = 1:size(subjects,2)
    create_subject(protocol_id,subjects(i),i,overwrite);
end

local_studies =  bst_get('ProtocolStudies');
create_study(protocol_id, local_studies.DefaultStudy, -3,overwrite);
create_study(protocol_id, local_studies.AnalysisStudy, -2,overwrite);
studies = local_studies.Study;
for i = 1:size(studies,2)
    create_study(protocol_id,studies(i),i,overwrite);
end   

protocolname = bst_get('ProtocolInfo');
protocolname = protocolname.Comment;
functional_file_folder = strcat(string(bst_get('BrainstormDbDir')),"/",protocolname,"/data/");
filelist = dir(fullfile(functional_file_folder, '**/*.*'));
for i= 1:size(filelist)
    if(filelist(i).isdir == 0)
        filename = char(strcat(filelist(i).folder,"/",filelist(i).name));
        type = file_gettype(filename);
        if(strcmp(type, 'unknown') == 1 || strcmp(type, 'brainstormstudy') == 1)
            continue;
        end
        disp("===========     "+type+"    ===============");
        disp(filename);
        [MD5,filesize]=getChecksum(filename);
        [uploadid,status] = create_file(filename,type,MD5,overwrite);
        if(strcmp(status,"success")==0)
            java_dialog('warning',status + " Upload abort.");
            return;
        end
        if(isempty(uploadid))
            continue;
        end
        upload_file(filename,uploadid,filesize,filelist(i).name);
    end
end

java_dialog('msgbox',"Protocol files uploaded!");

end

function [sStudy] = create_study(protocol_id,sStudy, iStudy,overwrite)
% if missing RemoteID, create new study on remote
if(~isfield(sStudy,'RemoteID') || isempty(sStudy.RemoteID) || overwrite == 1)
    url=strcat(string(bst_get('UrlAdr')),"/study/create");
    %find its subject
    [sSubject] = bst_get('Subject', sStudy.BrainStormSubject);
    [md5,filesize] = getChecksum(file_fullpath(sStudy.FileName));
    body = struct("filename",sStudy.FileName, "name",sStudy.Name, "condition",empty2string(sStudy.Condition),...
        "dateOfStudy", sStudy.DateOfStudy, "iChannel", empty2zero(sStudy.iChannel),...
        "iHeadModel",empty2zero(sStudy.iHeadModel), "protocolId",protocol_id,...
        "subjectId",sSubject.RemoteID, 'md5',md5);
    [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,0);
    if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
        java_dialog('warning',status);
        return;
    end
    data = jsondecode(response.Body.Data);
    sStudy.RemoteID = data.fid;
    %save study id in local db
    bst_set('RemoteStudy', iStudy, data.fid);
    upload_file(file_fullpath(sStudy.FileName),data.uploadid,filesize,sStudy.FileName);
else
    disp("study " + sStudy.FileName + " already on cloud");
end
end 

function [sSubject] = create_subject(protocol_id,sSubject,iSubject,overwrite)
% if missing RemoteID, create new subject on remote
if(~isfield(sSubject,'RemoteID') || isempty(sSubject.RemoteID) || overwrite == 1)
    url=strcat(string(bst_get('UrlAdr')),"/subject/create");
    [md5,filesize] = getChecksum(file_fullpath(sSubject.FileName));
    body=struct("comment",sSubject.Comments, "filename", sSubject.FileName,...
        "name",sSubject.Name, "useDefaultAnat",num2bool(sSubject.UseDefaultAnat),...
        "useDefaultChannel",num2bool(sSubject.UseDefaultChannel),...
        "iAnatomy",empty2zero(sSubject.iAnatomy), "iScalp",empty2zero(sSubject.iScalp),...
        "iCortex",empty2zero(sSubject.iCortex), "iInnerSkull",empty2zero(sSubject.iInnerSkull),...
        "iOuterSkull",empty2zero(sSubject.iOuterSkull), "iOther",empty2zero(sSubject.iOther),...
        "protocolId",protocol_id,'md5', md5);
    [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,0);
    if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
        java_dialog('warning',status);
        return;
    end
    data = jsondecode(response.Body.Data);
    sSubject.RemoteID = data.fid;
    %save subject id in local db
    bst_set('RemoteSubject', iSubject, data.fid);
    upload_file(file_fullpath(sSubject.FileName),data.uploadid,filesize,sSubject.FileName);
else 
    disp("subject " + sSubject.FileName + " already on cloud");
end
end

function [result] = num2bool(number)
    if(number == 1)
        result = true;
    else 
        result = false;
    end    
end


function [result] = empty2zero(val)
    if(isempty(val))
        result = 0;
    else 
        result = val;
    end    
end

function [result] = empty2string(val)
    if(isempty(val))
        result = "";
    else 
        result = val;
    end    
end

function [md5,filesize] = getChecksum(filename)
    fileID = fopen(filename,'r');
    content = fread(fileID,'*uint8');
    md5 = DataHash(content);
    filesize = size(content);
    filesize = filesize(1);
end

