function varargout = process_tree_channelflag( varargin )
% PROCESS_TREE_CHANNELFLAG: Process wrapper of tree_set_channelflag().

% @=============================================================================
% This function is part of the Brainstorm software:
% https://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2020 University of Southern California & McGill University
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
% Authors: Raymundo Cassani, 2021

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Set good / bad channels';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = {'Import', 'Channel file'};
    sProcess.Index       = 81;
    sProcess.Description = 'https://neuroimage.usc.edu/brainstorm/Tutorials/BadChannels';
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'raw'};
    sProcess.OutputTypes = {'data', 'raw'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Option: Value
    sProcess.options.flagmode.Comment = {'Mark some channels as bad...', ...
                                         'Mark some channels as good...', ...
                                         'Mark flat channels as bad', ...
                                         'Mark all channels as good'};
    sProcess.options.flagmode.Type    =  'radio';
    sProcess.options.flagmode.Value   =  1;
    % === Sensor types
    sProcess.options.sensortypes.Comment = 'Channel types or names: ';
    sProcess.options.sensortypes.Type    = 'text';
    sProcess.options.sensortypes.Value   = '';
    sProcess.options.sensortypes.InputTypes = {'data', 'raw'};
    % === Whether process is run interactively
    sProcess.options.isInteractive.Comment = 'Is interactive?';
    sProcess.options.isInteractive.Type    = 'checkbox';
    sProcess.options.isInteractive.Value   = 0;
    sProcess.options.isInteractive.Hidden  = 1;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    OutputFiles = {};
    % Get options
    switch sProcess.options.flagmode.Value
        case 1, Flagmode = 'AddBad';
        case 2, Flagmode = 'ClearBad';
        case 3, Flagmode = 'DetectFlat';
        case 4, Flagmode = 'ClearAllBad';           
    end   
    ChannelList = sProcess.options.sensortypes.Value;
    isInteractive = sProcess.options.isInteractive.Value;
    
    switch Flagmode
        case {'AddBad', 'ClearBad'}
            if isempty(ChannelList)
                if isInteractive
                    tree_set_channelflag({sInputs.FileName}, Flagmode);
                else
                    bst_report('Error', sProcess, [], 'Empty list of channels.');
                    return
                end
            else
                tree_set_channelflag({sInputs.FileName}, Flagmode, ChannelList);    
            end   
        
        case {'DetectFlat'}           
            tree_set_channelflag({sInputs.FileName}, Flagmode);
            
        case {'ClearAllBad'}
            if isInteractive
                tree_set_channelflag({sInputs.FileName}, Flagmode);
            else
                tree_set_channelflag({sInputs.FileName}, [Flagmode,'NoWarning']);
            end
    end 
    % Return all the files in input
    OutputFiles = {sInputs.FileName};
end