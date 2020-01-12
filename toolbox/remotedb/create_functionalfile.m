function [uploadid] = create_functionalfile(filetype)
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

url = strcat(string(bst_get('UrlAdr')),"/FunctionalFile/");
switch(filetype)
    case 'channel'
        url = strcat(url,"createChannel");
        %todo: body
        body = struct();
        [response,status] = bst_call(@HTTP_request,'POST','Default',body,url,1);
    case 'timefreq'
        disp("todo");
    case 'stat'
        disp("todo");
    case 'headmodel'
        disp("todo");
    case 'result'
        disp("todo");
    case 'recording'
        disp("todo");
    case 'matrix'
        disp("todo");
    case 'dipole'
        disp("todo");
    case 'covariance'
        disp("todo");
    case 'image'
        disp("todo");
end

if strcmp(status,'OK')~=1
    java_dialog('warning',status);
    return;
end
uploadid = jsondecode(response.Body.Data);
uploadid = uploadid.result;

end