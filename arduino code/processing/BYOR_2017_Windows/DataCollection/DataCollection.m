function varargout = DataCollection(varargin)
%DATACOLLECTION M-file for DataCollection.fig
%      DATACOLLECTION, by itself, creates a new DATACOLLECTION or raises the existing
%      singleton*.
%
%      H = DATACOLLECTION returns the handle to a new DATACOLLECTION or the handle to
%      the existing singleton*.
%
%      DATACOLLECTION('Property','Value',...) creates a new DATACOLLECTION using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to DataCollection_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      DATACOLLECTION('CALLBACK') and DATACOLLECTION('CALLBACK',hObject,...) call the
%      local function named CALLBACK in DATACOLLECTION.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DataCollection

% Last Modified by GUIDE v2.5 05-Oct-2016 16:29:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DataCollection_OpeningFcn, ...
                   'gui_OutputFcn',  @DataCollection_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


% --- Executes just before DataCollection is made visible.
function DataCollection_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for DataCollection
handles.output = hObject;


handles.COM_p = get(handles.popupmenu3,'Value');
handles.filename = get(handles.text3,'String');

handles.iData=1;
handles.bufferSize=960*2; % 960 samples per pulse*2 bytes per sample=1920 -> how many bytes per pulse, Arduino sends 8 bit data  
handles.numPulses=1;
% handles.BINdata=zeros(handles.numPulses,1); % array to store data


set(handles.togglebutton2,'String','Start Data Collection','FontSize',18); 
set(handles.pushbutton3,'CData',double(imread('SaveFileIcon.png'))/255);

set(handles.popupmenu3,'String',{'COM port','COM1','COM2','COM3','COM4',...
    'COM5','COM6','COM7','COM8','COM9','COM10','COM11','COM12','COM13',...
    'COM14','COM15','COM16','COM17','COM18','COM19','COM20'});


    % Update handles structure
guidata(hObject, handles);


% UIWAIT makes DataCollection wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = DataCollection_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file,path] = uiputfile(handles.filename,'Save file name');

if (file == 0) % user pressed cancel
    file='Test.mat';
    path=horzcat(pwd,'\');
    set(handles.text3,'String',file);
else
set(handles.text3,'String',file);
end

handles.filename=horzcat(path,file);
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function pushbutton3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

 
% --- Executes during object creation, after setting all properties.
function text3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called





% --- Executes on button press in togglebutton2.
function togglebutton2_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(get(hObject,'String'),'Start Data Collection')  % serial port currently disconnected
    handles.COM_p = get(handles.popupmenu3,'Value');
    guidata(hObject,handles);
    if handles.COM_p ==1
        errordlg('Select valid COM port.');
    else
        s = serial(horzcat('COM',num2str(handles.COM_p-1)),'DataBits',8,'StopBits',1,'Parity','none','BaudRate',500000);  % change the COM Port number as needed
        set(s,'InputBufferSize',handles.bufferSize+100);  % configure buffer to store 1 pulse worth of data and padding buffer by 100
        
        try
            fopen(s);
            handles.serialConn = s;
            set(handles.togglebutton2,'String','Stop Data Collection','FontSize',18);
            guidata(hObject,handles);
            pulseCount =1;
            pause(0.01);
                            
            while(get(handles.togglebutton2,'Value'))
            BINdata(pulseCount,:)=fread(s,handles.bufferSize);
            pulseCount=pulseCount+1;
            drawnow
            end
            
iData=1; % index for single-row interleaved data
iBin=1; % index for number of samples (columns) of binary data

[rows,cols]=size(BINdata);

for g=1:pulseCount-1 %reconstruct Binary data into 12-bit ASCII
    
    while(iBin<cols-1)
        temp=BINdata(g,iBin);
        num_temp=(temp*256+BINdata(g,iBin+1));
        if num_temp < 5001
            data(iData)=num_temp;
            iBin=iBin+2;
            iData=iData+1;
        else
            iBin=iBin+1;
        end
        
    end
    iBin=1;
    
end
save(handles.filename,'pulseCount','BINdata','data');
figure();
plot(data)
xlabel('Sample');
ylabel('Digital Data (12-bit)');
title('Raw Data'); 
        fclose(handles.serialConn);
        delete(handles.serialConn);
            
        catch err
            errordlg(err.message);
            delete(instrfind);
            handles.COM_p = set(handles.popupmenu3,'Value',1); %%
            set(handles.togglebutton2,'String','Start Data Collection','FontSize',18);
            set(handles.togglebutton2,'Value',0)
            guidata(hObject,handles);
        end
       
    end

else
    set(handles.togglebutton2,'String','Start Data Collection','FontSize',18);
    guidata(hObject, handles);
end

  
    

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbutton1.
function togglebutton2_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.togglebutton2,'Value',1)
guidata(hObject,handles)
pause(1)

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbutton1.
function togglebutton2_ButtonUpFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.togglebutton2,'Value',0)
guidata(hObject,handles)



% --- Executes on selection change in popupmenu3.
function popupmenu3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3
handles.COM_p=get(handles.popupmenu3,'Value');
guidata(hObject,handles); 


% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
