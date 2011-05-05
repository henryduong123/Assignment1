%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = Properties(varargin)
% PROPERTIES M-file for Properties.fig
%      PROPERTIES, by itself, creates a new PROPERTIES or raises the existing
%      singleton*.
%
%      H = PROPERTIES returns the handle to a new PROPERTIES or the handle to
%      the existing singleton*.
%
%      PROPERTIES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PROPERTIES.M with the given input arguments.
%
%      PROPERTIES('Property','Value',...) creates a new PROPERTIES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Properties_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Properties_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Properties

% Last Modified by GUIDE v2.5 18-Feb-2011 01:22:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Properties_OpeningFcn, ...
                   'gui_OutputFcn',  @Properties_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Properties is made visible.
function Properties_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Properties (see VARARGIN)

% Choose default command line output for Properties
handles.output = hObject;

set(handles.panelLbl,'Title',['Current time: ' num2str(varargin{1}.time)]);
set(handles.cellLabelTb,'String',num2str(varargin{1}.trackID));
set(handles.hullIDTb,'String',num2str(varargin{1}.hullID));
set(handles.familyIDTb,'String',num2str(varargin{1}.familyID));
set(handles.firstFrameTb,'String',num2str(varargin{1}.startTime));
if(~isempty(varargin{1}.parentTrack))
    set(handles.parentTb,'String',num2str(varargin{1}.parentTrack));
    set(handles.siblingTb,'String',num2str(varargin{1}.siblingTrack));
else
    set(handles.parentTb,'String','None');
    set(handles.siblingTb,'String','None');
end
if(~isempty(varargin{1}.childrenTracks))
    set(handles.childrenTb,'String',[num2str(varargin{1}.childrenTracks(1)) ', ' num2str(varargin{1}.childrenTracks(2))],'Style','text');
    set(handles.mitosisFrameTb,'String',num2str(varargin{1}.endTime));
else
    set(handles.mitosisFrameLbl,'String','Last Frame');
    set(handles.mitosisFrameTb,'String',num2str(varargin{1}.endTime));
    if(isempty(varargin{1}.timeOfDeath))
        set(handles.childrenTb,'String','None','Style','text');
    else
        set(handles.childrenLbl,'String','Time of Death');
        set(handles.childrenTb,'String',num2str(varargin{1}.timeOfDeath),'Style','pushbutton');
    end
end

set(handles.figure1,'UserData',varargin{1});
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Properties wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Properties_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in closeBtn.
function closeBtn_Callback(hObject, eventdata, handles)
% hObject    handle to closeBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1);


% --- Executes on button press in mitosisFrameTb.
function mitosisFrameTb_Callback(hObject, eventdata, handles)
% hObject    handle to mitosisFrameTb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Figures
TimeChange(str2double(get(handles.mitosisFrameTb,'String')));
close(handles.figure1);


% --- Executes on button press in firstFrameTb.
function firstFrameTb_Callback(hObject, eventdata, handles)
% hObject    handle to firstFrameTb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Figures
TimeChange(str2double(get(handles.firstFrameTb,'String')));
close(handles.figure1);

% --- Executes on button press in firstFrameTb.
function childrenTb_Callback(hObject, eventdata, handles)
% hObject    handle to firstFrameTb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
TimeChange(str2double(get(handles.childrenTb,'String')));
close(handles.figure1);

