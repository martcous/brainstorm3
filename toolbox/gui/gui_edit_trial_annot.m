function jFrame = gui_edit_trial_annot( TrialFile )
% GUI_EDIT_TRIAL_ANNOT: Edit trial annotations
%
% USAGE: gui_edit_trial_annot( TrialFile )

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
% Authors: Martin Cousineau, 2021

global GlobalData;

% Check if a "Channel Editor" panel already exists
panel = bst_get('Panel', 'TrialAnnot');
% If panel exists
if ~isempty(panel)
    % Close it
    gui_hide(panel);
end
% Create new panel
bstPanel = panel_trial_annot('CreatePanel', TrialFile);
if isempty(bstPanel)
    return;
end
% Show panel in a Java window
bstContainer = gui_show(bstPanel, 'JavaWindow', ['Trial annotations editor: ' TrialFile]);
if isempty(bstContainer)
    return;
end

