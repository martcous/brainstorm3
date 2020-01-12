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

create_protocol();
protocol_id = bst_get('ProtocolId');
local_subjects = bst_get('ProtocolSubjects');
create_subject(protocol_id,local_subjects.DefaultSubject,0);
subjects = local_subjects.Subject;
for i = 1:size(subjects,2)
    create_subject(protocol_id,subjects(i),i);
end

local_studies =  bst_get('ProtocolStudies');
create_study(protocol_id, local_studies.DefaultStudy, -3);
create_study(protocol_id, local_studies.AnalysisStudy, -2);
studies = local_studies.Study;
for i = 1:size(studies,2)
    create_study(protocol_id,studies(i),i);
end   

end

function [sStudy] = create_study(protocol_id,sStudy, iStudy)
% if missing RemoteID, create new study on remote
if(~isfield(sStudy,'RemoteID') || isempty(sStudy.RemoteID))
    url=strcat(string(bst_get('UrlAdr')),"/study/create");
    %find its subject
    [sSubject] = bst_get('Subject', sStudy.BrainStormSubject);
    body = struct("filename",sStudy.FileName, "name",sStudy.Name, "condition",empty2string(sStudy.Condition),...
        "dateOfStudy", sStudy.DateOfStudy, "iChannel", empty2zero(sStudy.iChannel),...
        "iHeadModel",empty2zero(sStudy.iHeadModel), "protocolId",protocol_id,...
        "subjectId",sSubject.RemoteID);
    [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
        java_dialog('warning',status);
        return;
    end
    data = jsondecode(response.Body.Data);
    sStudy.RemoteID = data.id;
    %save study id in local db
    bst_set('RemoteStudy', iStudy, data.id);
else
    disp("study " + sStudy.FileName + " already on cloud");
end
end 

function [sSubject] = create_subject(protocol_id,sSubject,iSubject)
% if missing RemoteID, create new subject on remote
if(~isfield(sSubject,'RemoteID') || isempty(sSubject.RemoteID))
    url=strcat(string(bst_get('UrlAdr')),"/subject/create");
    body=struct("comment",sSubject.Comments, "filename", sSubject.FileName,...
        "name",sSubject.Name, "useDefaultAnat",num2bool(sSubject.UseDefaultAnat),...
        "useDefaultChannel",num2bool(sSubject.UseDefaultChannel),...
        "iAnatomy",empty2zero(sSubject.iAnatomy), "iScalp",empty2zero(sSubject.iScalp),...
        "iCortex",empty2zero(sSubject.iCortex), "iInnerSkull",empty2zero(sSubject.iInnerSkull),...
        "iOuterSkull",empty2zero(sSubject.iOuterSkull), "iOther",empty2zero(sSubject.iOther),...
        "protocolId",protocol_id);
    [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
        java_dialog('warning',status);
        return;
    end
    data = jsondecode(response.Body.Data);
    sSubject.RemoteID = data.id;
    %save subject id in local db
    bst_set('RemoteSubject', iSubject, data.id);
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
