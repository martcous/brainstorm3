function [output] = create_protocol()
% Create: create a protocol in remote database

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


if isempty(bst_get('ProtocolId'))
    pid = " ";
else
    pid = bst_get('ProtocolId');
    disp('ProtocolID exists on local! Still check on remote. ');
    disp(pid);
    %return;
end



sProtocol = bst_get('ProtocolInfo');
data = struct('Id',pid,'Name',sProtocol.Comment, 'Isprivate', false, ...
    'Comment',sProtocol.Comment, 'Istudy', size(sProtocol.iStudy,1), ...
    'Usedefaultanat',num2bool(sProtocol.UseDefaultAnat), 'Usedefaultchannel',...
    num2bool(sProtocol.UseDefaultChannel));

[response,status] = HTTP_request('protocol/share', 'POST', data, 'Default', 1);
if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
    if (~isempty(status) && strcmp(status,'404')) || (~isempty(response) && strcmp(response, 'NotFound'))
        error('Upload protocol failed!');
    else
        error(status);
    end
else
    respData = bst_jsondecode(char(response.Body.Data));
    newid = respData.id;
    disp(newid);
    sProtocol.RemoteID = newid;
    bst_set('ProtocolInfo',sProtocol);
    disp('Protocol created on remote!');
end
end

function [result] = num2bool(number)
    if(number == 1)
        result = true;
    else 
        result = false;
    end    
end