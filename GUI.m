function varargout = GUI(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @GUI_OpeningFcn, ...
    'gui_OutputFcn',  @GUI_OutputFcn, ...
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


% --- Executes just before GUI is made visible.
function GUI_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for GUI
handles.output = hObject;
handles.subject = 'empty';
handles.fs = 500;
handles.winsize = handles.fs * 30;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_OutputFcn(hObject, eventdata, handles)

varargout{1} = handles.output;


% Loads a subject's data
function pushbutton1_Callback(hObject, eventdata, handles)

% Reset handle and figures
cla
handles.ldsEMG = []; handles.rdsEMG = [];
handles.currentdata = [];
handles.start = 1; handles.stop = handles.start + handles.winsize;

% Get a new file
[fName,PathName] = uigetfile( 'Y:\' );
set(handles.pushbutton1,'String','Loading structure...');
drawnow

X = load([PathName fName],fName(1:11));
handles.subject = X.(fName(1:11));

set(handles.text1,'String',fName(1:11),'ForegroundColor','red');
set(handles.pushbutton1,'String','Load Patient');

guidata(hObject,handles);


% --- Run the program
function pushbutton4_Callback(hObject, eventdata, handles)

if ~strcmp(handles.subject,'empty')
    set(handles.pushbutton4,'String','Running MATPLM...');
    drawnow
    [handles.ldsEMG,handles.rdsEMG] = GUIfullRun(handles.subject);
    %[handles.ldsEMG,handles.rdsEMG] = GUIfullRun2(handles.subject);
end

handles.start = 1; handles.stop = handles.winsize; % 30 sec epoch (fs = 500)
handles.currentdata = handles.ldsEMG;

set(handles.pushbutton4,'String','Run MATPLM');
guidata(hObject,handles);

%assignin('base','ldsEMG',handles.ldsEMG); assignin('base','rdsEMG',handles.rdsEMG);
plotSect(hObject,eventdata,handles);



function plotSect(hObject,eventdata,handles)
addpath('date ticks');

s = handles.start; st = handles.stop;

t = (s:st)/handles.fs/24/3600;
x = handles.currentdata(s:st,:);


plot(handles.axes1,t,x(:,1));

datetick(handles.axes1,'x','HH:MM:SS');
zoomAdaptiveDateTicks('on')

set(gca,'XLim',[t(1) t(end)],'YLim',[0 50]);
% axis([t(1) t(end) 1 20]); 

hold on;

% First, all movements are plotted in red. Then, only those movements
% that pass the median test are overlayed with a green mark. So green = good,
% red = bad

l = plot(handles.axes1,t,x(:,2),'r-','LineWidth',5);
%p = plot(handles.axes1,t,x(:,3),'g-','LineWidth',5);

% PLOT MEDIAN REMOVED TO COMPARE
p = plot(handles.axes1,t,x(:,4),'g-','LineWidth',5);

hold off;

drawnow


%legend([l,p],'LM','mLM')


% Page forward
function page_forward(hObject, eventdata, handles)

if handles.stop < size(handles.currentdata,1) - handles.winsize
    handles.start = handles.start + handles.winsize;
    handles.stop = handles.start + handles.winsize;
end

guidata(hObject,handles);
plotSect(hObject,eventdata,handles);


% Page backward
function page_back(hObject, eventdata, handles)

if handles.start > handles.winsize
    handles.start = handles.start - handles.winsize;
    handles.stop = handles.start + handles.winsize;
end

guidata(hObject,handles);
plotSect(hObject,eventdata,handles);


% --- Executes on selection change in popupmenu1.
function popup_leg_switch(hObject, eventdata, handles)

% Determine the selected data set.
str = get(hObject, 'String');
val = get(hObject,'Value');

switch str{val}
    case 'Left Leg'
        handles.currentdata = handles.ldsEMG;
    case 'Right Leg'
        handles.currentdata = handles.rdsEMG;
end

guidata(hObject,handles)

plotSect(hObject,eventdata,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function change_epoch(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double

newsize = str2double(get(hObject,'String'));

if newsize > 0
    handles.winsize = newsize * handles.fs;
    handles.stop = handles.start + handles.winsize;
end

guidata(hObject,handles)
plotSect(hObject,eventdata,handles);




% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Go to a time in the night (Time is only in hours of sleep right now, not
% actual ToN)
function seek_time(hObject, eventdata, handles)

sottime = get(hObject,'String');

[~,~,~,H,Mn,S] = datevec(sottime);
sottime = (H*3600+Mn*60+S)*handles.fs + 1;

handles.start = sottime; handles.stop = handles.start + handles.winsize;

guidata(hObject,handles)
plotSect(hObject,eventdata,handles);


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
