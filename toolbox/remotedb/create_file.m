function [uploadid,status] = create_file(fileName, filetype, MD5,overwrite)
% Create: create a functional file in remote database
% Currently work on intial commit.

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
% Authors: Chaoyi Liu, Zeyu Chen 2020

uploadid = [];
[sStudy, iStudy, iItem, DataType, sItem] = bst_get('AnyFile', fileName);
if(isfield(sItem,'RemoteID') && ~isempty(sItem.RemoteID) && overwrite==0)
    status = "success";
    disp(sItem.FileName+" already on remote!");
    return;
end
studyID=sStudy.RemoteID;
switch(filetype)
    case 'channel'
        body = struct('nbChannels',empty2zero(findattribute(sItem,"nbChannels")),'transfMegLabels',empty2string(findattribute(sItem,"transfMegLabels")),...
          'transfEegLabels',empty2string(findattribute(sItem,"transfEegLabels")),...
          'comment', empty2string(findattribute(sItem,"Comment")),'fileName', sItem.FileName,...
          'fileType',1, 'md5', string(MD5),'studyID', studyID);
        [response,status] = HTTP_request('createChannel', 'POST', body);
    case 'timefreq'
        body = struct("measure", empty2string(findattribute(sItem,"measure")),"method", empty2string(findattribute(sItem,"method")),...
          "nAvg", 0,"colormapType", empty2string(findattribute(sItem,"colormapType")),...
          "displayUnits", empty2string(findattribute(sItem,"displayUnits")),...
          "comment", empty2string(findattribute(sItem,"Comment")),"fileName", sItem.FileName,...
          "fileType", 2, "md5", string(MD5),"studyID", studyID);
        [response,status] = HTTP_request('createTimeFreq', 'POST', body);
    case {'presults', 'pdata','ptimefreq','pmatrix'}
        body = struct("df",0,"correction",true,...
            "type", filetype,...
            "comment", empty2string(findattribute(sItem,"Comment")),"fileName", sItem.FileName,...
            "fileType", 3, "md5", string(MD5),"studyID", studyID);
        [response,status] = HTTP_request('createStat', 'POST', body);
    case 'headmodel'
        body = struct("type", empty2string(findattribute(sItem,"type")),"megMethod", empty2string(findattribute(sItem,"megMethod")),...
            "eegMethod", empty2string(findattribute(sItem,"eegMethod")),"ecogMethod", empty2string(findattribute(sItem,"ecogMethod")),...
            "seegMethod", empty2string(findattribute(sItem,"seegMethod")),...
            "comment", empty2string(findattribute(sItem,"Comment")),"fileName", sItem.FileName,...
            "fileType", 4, "md5", string(MD5),"studyID", studyID);
        [response,status] = HTTP_request('createHeadModel', 'POST', body);
    case 'results'
        body = struct("isLink", true,"nComponents", empty2zero(findattribute(sItem,"nComponents")),...
            "function", empty2string(findattribute(sItem,"function")),"nAvg", empty2zero(findattribute(sItem,"nAvg")),...
            "colormapType", empty2string(findattribute(sItem,"colormapType")),"displayUnits", empty2string(findattribute(sItem,"displayUnits")),...
            "comment", empty2string(findattribute(sItem,"Comment")),"fileName", sItem.FileName,...
            "fileType", 5, "md5", string(MD5),"studyID", studyID);
        [response,status] = HTTP_request('createResult', 'POST', body);
    case 'matrix'
        body = struct("nAvg", 0,"displayUnits", empty2string(findattribute(sItem,"displayUnits")),...
            "comment",empty2string(findattribute(sItem,"Comment")),"fileName", sItem.FileName,...
            "fileType", 6, "md5", string(MD5),"studyID", studyID);
        [response,status] = HTTP_request('createMatrix', 'POST', body);
    otherwise
        body = struct("comment",empty2string(findattribute(sItem,"Comment")),"fileName", sItem.FileName,...
            "fileType", 7, "md5", string(MD5),"studyID", studyID);
        [response,status] = HTTP_request('createOther', 'POST', body);
end
if strcmp(status,'OK')~=1
    %java_dialog('warning',status);
    return;
end
data = jsondecode(response.Body.Data);
uploadid = data.uploadid;
bst_set('RemoteFileID', sItem.FileName, iStudy, data.fid)
status = "success";
disp("studyID GUID: "+studyID);
end


function [attribute]=findattribute(sItem,attribute)
    if isfield(sItem,attribute)
        attribute= sItem.(attribute);
        %disp(attribute);
    else
        attribute=[];
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


