function [uploadid] = create_file(filetype,fileName)
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

url = strcat(string(bst_get('UrlAdr')),"/");
studyID=bst_get("Study");
ChannelFile=bst_get('ChannelForStudy',studyID);
[sStudy, iStudy, iItem, DataType, sItem] = bst_get('AnyFile', fileName);
switch(filetype)
    case 'channel'
        url = strcat(url,"createChannel");
        body = struct("nbChannels",sItem.nbChannels,"transfMegLabels", sItem.transfMegLabels,...
          "transfEegLabels","string","id","",...
          "comment", "string","fileName", fileName,...
          "fileType", filetype,"histories", [{...
              "timeStamp": datestr(datevec(now),'yyyy-mm-ddTHH:MM:SS.FFFZ'),...
              "historyEvent":"None"...
            }],...
          "md5", md5(fileName),"studyID", studyID);

        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    case 'timefreq'
        url = strcat(url,"createTimeFreq");
        body = struct("measure", "string","method", "string",...
          "nAvg", 0,"colormapType", "string",...
          "displayUnits", "string","id","",...
          "comment", sItem.Comment,"fileName", fileName,...
          "fileType", filetype,"histories", [{...
              "timeStamp": datestr(datevec(now),'yyyy-mm-ddTHH:MM:SS.FFFZ'),...
              "historyEvent": "None"...
            }],...
          "md5", md5(fileName),"studyID", studyID);
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);        
    case 'stat'
        url = strcat(url,"createStat");
        body = struct("df",0,"correction",true,...
            "type", filetype,"id","",...
            "comment", "string","fileName", fileName,...
            "fileType", 1,"histories", [{...
               "timeStamp": datestr(datevec(now),'yyyy-mm-ddTHH:MM:SS.FFFZ'),...
               "historyEvent": "None"...
             }],...
            "md5", md5(fileName),"studyID", studyID);
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    case 'headmodel'
        url = strcat(url,"createHeadModel");
        body = struct("type", "string","megMethod", "string",...
            "eegMethod", "string","ecogMethod", "string",...
            "seegMethod", "string","id","",...
            "comment", "string","fileName", fileName,...
            "fileType", filetype,"histories", [{...
               "timeStamp": datestr(datevec(now),'yyyy-mm-ddTHH:MM:SS.FFFZ'),...
               "historyEvent": "None"...
             }],...
            "md5", md5(fileName),"studyID", studyID);
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    case 'result'
        url = strcat(url,"createResult");
        body = struct("type", "string","megMethod", "string",...
            "eegMethod", "string","ecogMethod", "string",...
            "seegMethod", "string","id","",...
            "comment", "string","fileName", fileName,...
            "fileType", filetype,"histories", [{...
               "timeStamp": datestr(datevec(now),'yyyy-mm-ddTHH:MM:SS.FFFZ'),...
               "historyEvent": "None"...
             }],...
            "md5", md5(fileName),"studyID", studyID);
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    case 'recording'
        url = strcat(url,"createRecording");
        %todo: body
        body = struct();
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    case 'matrix'
        url = strcat(url,"createMatrix");
        %todo: body
        body = struct();
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