function varargout = panel_trial_annot(varargin)
% PANEL_TRIAL_ANNOT: Create a panel to edit trial annotations.

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

eval(macro_method);
end



%% ===== CREATE PANEL =====
% USAGE: CreatePanel(ChannelFile)           : Edit ChannelFile
%        CreatePanel(ChannelFile, DataFile) : Edit ChannelFile and ChannelFlag of DataFile
function bstPanelNew = CreatePanel(TrialFile) %#ok<DEFNU>
    panelName = 'TrialAnnot';
    % Java initializations
    import java.awt.*;
    import javax.swing.*;
    import javax.swing.table.*;
    import java.util.ArrayList;
    
    columns = {'Trial', 'Annot1', 'Annot2'};
    data = ["1", "val1.1", "val1.2"; ...
            "2", "val2.1", "val2.2"];
    defaultTableModel = DefaultTableModel(data, columns);
    table = JTable(defaultTableModel);
    tableColumnModel = table.getColumnModel();
    
    table.setFont(bst_get('Font'));
    table.setRowHeight(22);
    table.setPreferredScrollableViewportSize(table.getPreferredSize()); 
    
    table.setColumnSelectionAllowed(true);
    table.setRowSelectionAllowed(false);
	
    color = UIManager.getColor("Table.gridColor");
    border = javax.swing.border.MatteBorder(1, 1, 0, 0, color);
    table.setBorder(border);
    
    scrollPane = JScrollPane(table);
    scrollPane.setBorder(BorderFactory.createEmptyBorder());
    
    addButton = JButton("Add");
    addButton.setAlignmentX(JComponent.CENTER_ALIGNMENT);
    addButton.setAlignmentY(JComponent.CENTER_ALIGNMENT);
    deleteButton = JButton("Delete");
    deleteButton.setAlignmentX(JComponent.CENTER_ALIGNMENT);
    deleteButton.setAlignmentY(JComponent.CENTER_ALIGNMENT);
       
    jPanelNew = JPanel();
    jPanelNew.setBorder(javax.swing.border.EmptyBorder(10, 10, 10, 10));
    borderLayout = BorderLayout();
    borderLayout.setHgap(10);
    jPanelNew.setLayout(borderLayout);
    panelButton1 = JPanel();
    panelButton1.setLayout(BoxLayout(panelButton1, BoxLayout.Y_AXIS));  
    panelButton1.add(addButton);
    panelButton1.add(deleteButton);
    
    panelButton2 = JPanel();
    importButton = JButton('Import from file');
    java_setcb(importButton, 'ActionPerformedCallback', @(h,e)ImportAnnot());
    panelButton2.add(importButton);
    panelButton2.add(JButton("Save"));

    jPanelNew.add(scrollPane, java.awt.BorderLayout.CENTER);
    jPanelNew.add(panelButton1, java.awt.BorderLayout.EAST);
    jPanelNew.add(panelButton2, java.awt.BorderLayout.SOUTH);

    % Create the BstPanel object that is returned by the function
    % => constructor BstPanel(jHandle, panelName, sControls)
    bstPanelNew = BstPanel(panelName, ...
                           jPanelNew, ...
                           struct());
           
                       
    function ImportAnnot()
        LastUsedDirs = bst_get('LastUsedDirs');
        [AnnotFile, FileFormat] = java_getfile('open', ...
            'Import annotation file...', ...    % Window title
            LastUsedDirs.ImportData, ...        % Last used directory
            'single', 'files_and_dirs', ...     % Selection mode
            {{'.csv', '.txt'}, 'ASCII: CSV (.txt, .csv)', 'ASCII_CSV'}, ... % File filters
            'ASCII_CSV');                       % Default ASCII CSV
        
        java_dialog('warning', ['Annotations for trial #2 are missing.' ...
            10 'All other trials annotations were imported.'], ...
            'Import annotations');
    end
end
                   
