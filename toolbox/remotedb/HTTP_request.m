function [response, status] = HTTP_request(url, method, data, header, checkSession)
% HTTP_REQUEST: POST,GET request to construct interaction between front end
% and back end.

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

import matlab.net.*;
import matlab.net.http.*;

if nargin < 5 || isempty(checkSession)
    checkSession = 0;
end
if nargin < 4 || isempty(header)
    header = 'Default';
end
if nargin < 3 || isempty(data)
    data = struct();
end

RemoteDbConfig = bst_get('RemoteDbConfig');
contentTypeField = matlab.net.http.field.ContentTypeField('application/json');
type1 = matlab.net.http.MediaType('text/*');
type2 = matlab.net.http.MediaType('application/json','q','.5');
acceptField = matlab.net.http.field.AcceptField([type1 type2]);
sessionheader = HeaderField('sessionid', RemoteDbConfig.SessionId);
deviceheader = HeaderField('deviceid', RemoteDbConfig.DeviceId);
protocolheader = HeaderField('protocolid', RemoteDbConfig.ProtocolId);
switch (header)
    case 'None'
        headerObj = [acceptField,contentTypeField];
        body=MessageBody(data);
    case 'Default'
        jsonheader = HeaderField('Content-Type','application/json');
        headerObj = [acceptField,jsonheader,sessionheader,deviceheader,protocolheader];
        body=MessageBody(data);
    case 'Stream'
        streamheader = HeaderField('Content-Type','application/octet-stream');
        headerObj = [streamheader,sessionheader,deviceheader,protocolheader];
        body=data;
end

if ~strcmp(header, 'None') && isempty(RemoteDbConfig.SessionId)
    sessionFailed = 1;
elseif checkSession
    url = bst_fullfile(RemoteDbConfig.Url, 'user/checksession');
    data = struct('deviceid', RemoteDbConfig.DeviceId, ...
        'sessionid', RemoteDbConfig.SessionId ...
    );
    [response,status] = HTTP_request(url, 'POST', data);
    sessionFailed = ~strcmp(status,'200') && ~strcmp(status,'OK');
else
    sessionFailed = 0;
end

if sessionFailed
     response = [];
     status = 'Session unavailable. Please log in first!';
     return;
end

switch method
    case 'POST'
        method = RequestMethod.POST;   
        r = RequestMessage(method,headerObj,body);
        
    case 'GET'
        method = RequestMethod.GET;
        r = RequestMessage(method,headerObj);
    
    otherwise
        error('Unsupported HTTP method.');
end

uri = URI(bst_fullfile(RemoteDbConfig.Url, url)); 
try
    response = send(r,uri);
    status = char(response.StatusCode);
catch
    response = [];
    status = 'Failed to connect to server.';
end
    
