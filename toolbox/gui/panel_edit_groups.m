function varargout = panel_edit_groups(varargin)
% PANEL_EDIT_GROUPS:  Edit user group memberships.
% USAGE:  [bstPanelNew, panelName] = panel_edit_groups('CreatePanel')
% Function UpdateGroupsList() call function LoadGroups() to show latest Grouplist 
% Function UpdateMembersList() call function LoadMembers(group) with specific group to show
% latest MembersList 
% 
% Function AddMember(group, member) to add a member to a group 


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
% Authors: Martin Cousineau, Zeyu Chen, Chaoyi Liu, 2019

eval(macro_method);
end


%% ===== CREATE PANEL =====
function [bstPanelNew, panelName] = CreatePanel() %#ok<DEFNU>
    % Java initializations
    import java.awt.*;
    import javax.swing.*;
    import org.brainstorm.list.*;
    import matlab.net.*;
    import matlab.net.http.*;
    
    global GlobalData;
    % Constants
    panelName = 'EditGroups';
    
    % Create main panel
    jPanelNew = gui_river([0 0], [0 0 0 0], 'Groups');
    
    % Create Group
    jPanelCreate = gui_river([5 0], [0 2 0 2]);
    jTextGroup=gui_component('Text',  jPanelCreate, 'br hfill', '', [], [], []);
    gui_component('Button', jPanelCreate, [], 'Create Group', [], [], @ButtonCreateGroup_Callback);
    jPanelNew.add('br hfill', jPanelCreate);
    
    % Main panel
    jPanelMain = gui_river([5 0], [0 2 0 2]);
    jPanelNew.add('br hfill', jPanelMain);
    
    % Font size for the lists
    fontSize = round(10 * bst_get('InterfaceScaling') / 100);
    
    % List of groups
    jListGroups = JList();
    jListGroups.setCellRenderer(BstStringListRenderer(fontSize));
    jListGroups.setPreferredSize(java_scaled('dimension', 100, 250));
    java_setcb(jListGroups, 'ValueChangedCallback', @GroupListValueChanged_Callback);
    jPanelGroupsScrollList = JScrollPane();
    jPanelGroupsScrollList.getLayout.getViewport.setView(jListGroups);
    jPanelMain.add('hfill', jPanelGroupsScrollList);

    % List of members
    jPanelMembers = gui_river([5 0], [0 2 0 2], 'Members');
    jListMembers = JList();
    jListMembers.setCellRenderer(BstStringListRenderer(fontSize));
    jPanelMembersScrollList = JScrollPane();
    jPanelMembersScrollList.getLayout.getViewport.setView(jListMembers);
    jPanelMembers.add('hfill', jPanelMembersScrollList);
    jPanelMain.add('hfill', jPanelMembers);

    % Buttons
    jPanelButtons = gui_river([5 0], [0 2 0 2]);
    gui_component('Button', jPanelButtons, [], 'Add', [], [], @ButtonAddMember_Callback);
    gui_component('Button', jPanelButtons, 'hfill', 'Edit permissions', [], [], @ButtonEditMember_Callback);
    gui_component('Button', jPanelButtons, [], 'Remove', [], [], @ButtonRemoveMember_Callback);
    jPanelNew.add('br hfill', jPanelButtons);

    % ===== LOAD DATA =====
    UpdateGroupsList();        
    UpdateMembersList();
    
    % ===== CREATE PANEL =====   
    bstPanelNew = BstPanel(panelName, ...
                           jPanelNew, ...
                           struct('jListGroups',  jListGroups, ...
                                  'jListMembers', jListMembers));

    %% ===== UPDATE GROUPS LIST =====
    function UpdateGroupsList()
        % Load groups
        groups = LoadGroups();
        % Remove JList callback
        bakCallback = java_getcb(jListGroups, 'ValueChangedCallback');
        java_setcb(jListGroups, 'ValueChangedCallback', []);

        % Create a new empty list
        listModel = java_create('javax.swing.DefaultListModel');
        % Add an item in list for each group
        for i = 1:length(groups)
            listModel.addElement(groups{i});
        end
        % Update list model
        jListGroups.setModel(listModel);

        % Restore callback
        drawnow
        java_setcb(jListGroups, 'ValueChangedCallback', bakCallback);
    end

    %% ===== UPDATE MEMBERS LIST =====
    function UpdateMembersList()
        % Load members
       
        group = jListGroups.getSelectedValue();
        
        
        [members, permissions] = LoadMembers(group);
        if isempty(group) || isempty(members)
            return
        end
        % Remove JList callback
        bakCallback = java_getcb(jListMembers, 'ValueChangedCallback');
        java_setcb(jListMembers, 'ValueChangedCallback', []);

        % Create a new empty list
        listModel = java_create('javax.swing.DefaultListModel');
        % Add an item in list for each group
        for i = 1:length(members)
            element=strcat(members{i},'  [')
            element=strcat(element,permissions{i});
            element=strcat(element, ']');
            listModel.addElement(element);            
        end
        % Update list model
        jListMembers.setModel(listModel);

        % Restore callback
        drawnow
        java_setcb(jListMembers, 'ValueChangedCallback', bakCallback);
    end


    %% =================================================================================
    %  === CONTROLS CALLBACKS  =========================================================
    %  =================================================================================

    function GroupListValueChanged_Callback(h, ev)
        UpdateMembersList();
    end

    %% ===== BUTTON: CREATE GROUP =====
    function ButtonCreateGroup_Callback(varargin)
        
        groupname=jTextGroup.getText();
        if strcmp(groupname,'')~=1
            data=struct('Name',char(groupname));
            [response,status] = HTTP_request('group/create', 'POST', data, 'Default', 1);
            if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
                java_dialog('warning',status);
            elseif strcmp(status,'500')==1 ||strcmp(status,'InternalServerError')==1
                java_dialog('warning', 'Group already exist, change another name!');    
            else
                content=response.Body;                      
                show(content);
                java_dialog('msgbox', 'Create group successfully!');
                UpdateGroupsList();
            end
        else
            java_dialog('warning', 'Groupname cannot be empty!');
        end
        
    end

    %% ===== BUTTON: ADD MEMBER =====
    function ButtonAddMember_Callback(varargin)
        group = jListGroups.getSelectedValue();
        if isempty(group)
            return
        end

        [res, isCancel] = java_dialog('input', 'What is the name or email of the person you would like to add?', 'Add member', jPanelNew);
        if ~isCancel && ~isempty(res)
            [permission, isCancel2] = java_dialog('combo', 'What permissions would you like to give this member?', 'Edit permissions', [], {'Member', 'Manager'});
            respass={res,permission};
            disp(respass);
            if ~isCancel2
                [res, error] = AddMember(group, respass);
                if res
                    UpdateMembersList();
                else
                    java_dialog('error', error, 'Add member');
                end
            end
        end
    end

    %% ===== BUTTON: EDIT PERMISSIONS =====
    function ButtonEditMember_Callback(varargin)
        group = jListGroups.getSelectedValue();
        member = ExtractMemberName(jListMembers.getSelectedValue());
        if isempty(group) || isempty(member)
            return
        end

        [res, isCancel] = java_dialog('combo', 'What permissions would you like to give this member?', 'Edit permissions', [], {'Member', 'Manager'});
        if ~isCancel
            
            if strcmp(res,'Manager')==1
                permission = 1;
            else
                permission = 2;
            end
            data = struct('GroupName', group, ...
                'UserEmail', member, ...
                'Role', permission);
            [resp, status] = HTTP_request('group/changerole', 'POST', data);
            if strcmp(status,'200')==1 ||strcmp(status,'OK')==1
                java_dialog('msgbox', 'Changed role successfully!');
                UpdateMembersList();
            elseif strcmp(status,'401')==1 || strcmp(status,'Unauthorized')==1
                java_dialog('warning', 'Sorry. You do not have permission!');
            else
                java_dialog('error', status);
            end
        end
    end

    %% ===== BUTTON: REMOVE MEMBER =====
    function ButtonRemoveMember_Callback(varargin)
        member = ExtractMemberName(jListMembers.getSelectedValue());
        group = jListGroups.getSelectedValue();
        if isempty(member)
            return
        end

        data = struct('GroupName', group, 'UserEmail', member);        
        [resp, status] = HTTP_request('group/removeuser', 'POST', data);
        
        if strcmp(status,'200')==1 ||strcmp(status,'OK')==1
            java_dialog('msgbox', 'Removed group member successfully!');
            UpdateMembersList();
        elseif strcmp(status,'401')==1 || strcmp(status,'Unauthorized')==1
            java_dialog('warning', 'Sorry. You do not have permission!');
        else
            java_dialog('error', status);
        end
    end

    %% ===== LOAD GROUPS =====
    function groups = LoadGroups()
        groups = cell(0);
        data = struct('start',0,'count',100, 'order', 0);
        gui_hide('Preferences');
        [response,status] = HTTP_request('user/listgroups', 'POST', data, 'Default', 1);
        if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
            java_dialog('warning',status);
            if strcmp(status,'Session unavailable')==1
                gui_show('panel_options', 'JavaWindow', 'Brainstorm preferences', [], 1, 0, 0);
            end
        else
            content=response.Body;                      
            show(content);
            responseData = jsondecode(content.Data);
            if(size(responseData) > 0)
                groups = cell(size(responseData));
                for i = 1 : size(responseData)
                    groups{i} = responseData(i).name;
                end
            end
            disp('Load user groups successfully!');
        end
    end
    %% ===== LOAD MEMBERS =====
    function [members, permissions] = LoadMembers(group)
        if isempty(group)
            members = [];
            permissions = [];
            return
        end
        
        data = struct('name',group);
        gui_hide('Preferences');
        [response,status] = HTTP_request('/group/detail', 'POST', data, 'Default', 1);
        if strcmp(status,'200')~=1 && strcmp(status,'OK')~=1
            java_dialog('warning',status);
        elseif strcmp(status,'Session unavailable')==1
            gui_show('Preferences')
        else
            content=response.Body;
            responseData = bst_jsondecode(char(content.Data));
            if(size(responseData) > 0)
                members = cell(size(responseData(1).users));
                permissions = cell(size(responseData(1).users));
                for i = 1 : size(responseData(1).users)
                    firstname = responseData(1).users(i).firstname;
                    lastname = responseData(1).users(i).lastname;
                    email=responseData(1).users(i).email;
                    privilege = responseData(1).users(i).privilege;
                    name=strcat(firstname,' ');
                    name=strcat(name,lastname);
                    name=strcat(name,' (');
                    name=strcat(name,email);
                    name=strcat(name,')');
                    members{i} = string(name);
                    disp(members{i});
                    if privilege==1
                        permissions{i}='manager';
                    else
                        permissions{i}='member';
                    end
                end
            end
            disp('Loaded user groups successfully!');
        end

    end
    %% ===== ADD MEMBER TO GROUP =====
    function [res, error] = AddMember(group, member)
        error = [];
        res=1;
        
        if strcmp(member(2),'Manager')==1
            permission = 1;
        else
            permission = 2;
        end
        data = struct('GroupName', group, ...
            'UserEmail', member(1), ...
            'Privilege', permission);
        
        [resp, status] = HTTP_request('group/adduser', 'POST', data);
        if strcmp(status,'200')==1 ||strcmp(status,'OK')==1
            java_dialog('msgbox', 'Added group member successfully!');
        else
            java_dialog('error', txt);
        end
    end
end

% Extract member name if permission present in brackets
function member = ExtractMemberName(member)
    iPermission = strfind(member, ')');
    disp(iPermission);
    iEmail=strfind(member, ' (');
    disp(iEmail)
    
    if ~isempty(iEmail) && iPermission > 2 && ~isempty(iPermission)
        member = member(iEmail(end)+2:iPermission(end)-1);
    end
end


