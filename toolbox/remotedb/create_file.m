function [uploadid] = create_file(fileName)
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

filetype=file_gettype( fileName );
url = strcat(string(bst_get('UrlAdr')),"/");
[sStudy, studyID, iItem, DataType, sItem] = bst_get('AnyFile', fileName);
MD5=GetMD5(fileName,'File');
ChannelFile=bst_get('ChannelForStudy',studyID);
fileName=string(fileName);
studyID=string(num2str(studyID));
switch(filetype)
    case 'channel'
        url = strcat(url,"createChannel");
        body = struct('nbChannels',empty2zero(findattribute(sItem,"nbChannels")),'transfMegLabels',empty2string(findattribute(sItem,"transfMegLabels")),...
          'transfEegLabels',empty2string(findattribute(sItem,"transfEegLabels")),'id',studyID,...
          'comment', empty2string(findattribute(sItem,"Comment")),'fileName', fileName,...
          'fileType',1,'histories', [struct('timeStamp', datestr(datevec(now),'yyyy-mm-ddTHH:MM:SS.FFFZ'),...
              'historyEvent',"None")],...
          'md5', string(MD5),'studyID', studyID);
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    case 'timefreq'
        url = strcat(url,"createTimeFreq");
        body = struct("measure", empty2string(findattribute(sItem,"measure")),"method", empty2string(findattribute(sItem,"method")),...
          "nAvg", 0,"colormapType", empty2string(findattribute(sItem,"colormapType")),...
          "displayUnits", empty2string(findattribute(sItem,"displayUnits")),"id",studyID,...
          "comment", empty2string(findattribute(sItem,"Comment")),"fileName", fileName,...
          "fileType", 1,"histories", [struct('timeStamp', datestr(datevec(now),'yyyy-mm-ddTHH:MM:SS.FFFZ'),...
              'historyEvent',"None")],...
          "md5", string(MD5),"studyID", studyID);
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);        
    case 'stat'
        url = strcat(url,"createStat");
        body = struct("df",0,"correction",true,...
            "type", filetype,"id",empty2string(findattribute(sItem,"id")),...
            "comment", empty2string(findattribute(sItem,"Comment")),"fileName", fileName,...
            "fileType", 1,"histories", [struct('timeStamp', datestr(datevec(now),'yyyy-mm-ddTHH:MM:SS.FFFZ'),...
              'historyEvent',"None")],...
            "md5", string(MD5),"studyID", studyID);
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    case 'headmodel'
        url = strcat(url,"createHeadModel");
        body = struct("type", empty2string(findattribute(sItem,"type")),"megMethod", empty2string(findattribute(sItem,"megMethod")),...
            "eegMethod", empty2string(findattribute(sItem,"eegMethod")),"ecogMethod", empty2string(findattribute(sItem,"ecogMethod")),...
            "seegMethod", empty2string(findattribute(sItem,"seegMethod")),"id",empty2string(findattribute(sItem,"id")),...
            "comment", empty2string(findattribute(sItem,"Comment")),"fileName", fileName,...
            "fileType", 1,"histories", [struct('timeStamp', datestr(datevec(now),'yyyy-mm-ddTHH:MM:SS.FFFZ'),...
              'historyEvent',"None")],...
            "md5", string(MD5),"studyID", studyID);
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    case 'result'
        url = strcat(url,"createResult");
        body = struct("isLink", true,"nComponents", empty2zero(findattribute(sItem,"nComponents")),...
            "function", empty2string(findattribute(sItem,"function")),"nAvg", empty2zero(findattribute(sItem,"nAvg")),...
            "colormapType", empty2string(findattribute(sItem,"colormapType")),"displayUnits", empty2string(findattribute(sItem,"displayUnits")),"id",findattribute(sItem,"id"),...
            "comment", empty2string(findattribute(sItem,"Comment")),"fileName", fileName,...
            "fileType", 1,"histories", [struct('timeStamp', datestr(datevec(now),'yyyy-mm-ddTHH:MM:SS.FFFZ'),...
              'historyEvent',"None")],...
            "md5", string(MD5),"studyID", studyID);
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    case 'recording'
        url = strcat(url,"createRecording");
        %todo: body
        body = struct();
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    case 'matrix'
        url = strcat(url,"createMatrix");
        %todo: body
        body = struct("nAvg", 0,"displayUnits", empty2string(findattribute(sItem,"displayUnits")),...
            "id",empty2string(findattribute(sItem,"id")),"comment",empty2string(findattribute(sItem,"Comment")),"fileName", fileName,...
            "fileType", 1,"histories", [struct('timeStamp', datestr(datevec(now),'yyyy-mm-ddTHH:MM:SS.FFFZ'),...
              'historyEvent',"None")],...
            "md5", string(MD5),"studyID", studyID);
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    case 'dipole'
        %backend missing
        url = strcat(url,"createChannel");
        %todo: body
        body = struct();
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    case 'covariance'
        %backend missing
        url = strcat(url,"createChannel");
        %todo: body
        body = struct();
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    case 'image'
        %backend missing
        url = strcat(url,"createChannel");
        %todo: body
        body = struct();
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
end

if strcmp(status,'OK')~=1
    java_dialog('warning',status);
    return;
end
uploadid = jsondecode(response.Body.Data);
uploadid = uploadid.result;

end


function [attribute]=findattribute(sItem,attribute)
    if isfield(sItem,attribute)==1
        attribute=getfield(sItem,attribute);
        disp(attribute);
    else
        attribute=[];
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


