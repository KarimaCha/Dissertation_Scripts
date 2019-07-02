function WM_GUI_Start 
%% GUI script for Working Memory Testing
%% (code written by Karima Chakroun, version: 10.02.2016)


close all; % set figures back to 1

% seed the random number generator
rand('seed', sum(100 * clock));  %rng('shuffle')

GUIsize = get(0,'screensize')*1;  % get screen size
h.fig = figure( 'Visible', 'on',...
                'Position', GUIsize, ... % make figure/GUI with full screen size
                'Units', 'pixels', ...
                'Resize','off', ...
                'Toolbar', 'none',...
                'Menu', 'none',...
                'Name', 'Aufgaben zu Entscheidung & Gedächtnis', ...
                'NumberTitle','off'); 
movegui(h.fig,'center');
GUIcolor = get(h.fig, 'Color');


%% Task variables

% fixed order: 1) RotSpan, 2) OSpan, 3) DD, 4) ListeningSpan, 5) DigitSpan, 6) PD

subjID = inputdlg('Enter subject-ID:');
h.PC = listdlg('PromptString','Choose PC number:',...
    'SelectionMode','single', ...
    'ListString',{'1','2','3','4'},...
    'ListSize', [150 100]);

h.subjID = subjID{1};

h.logpath = ['logs' filesep h.subjID filesep];
    
% create folder if it not exists
if ~exist(h.logpath, 'dir')
    mkdir(h.logpath);
end


%% GUI Buttons

buttonSizeX = 125;
buttonSizeY = 100;
buttonFirstX = 0.15;  % center of first (leftmost) button iin % screenwidth
for i = 1:6
    buttonPositionsX(i) = buttonFirstX + (i-1)*(1-2*buttonFirstX)/5;
end
buttonCenterX = GUIsize(3)*buttonPositionsX;    % button centers in pixels
buttonCenterY1 = GUIsize(4)*0.45;  
buttonCenterY2 = GUIsize(4)*0.25;
buttonPosX = buttonCenterX - buttonSizeX*0.5;   % button corners in pixels
buttonPosY1 = buttonCenterY1 - buttonSizeY*0.5;   % buttons top row
buttonPosY2 = buttonCenterY2 - buttonSizeY*0.5;   % buttons lower row

% get button background image (blue color gradient)
h.buttonBG = imread('Stimuli/GUI_Stimuli/buttonBG.jpg');
h.buttonBGklein = imread('Stimuli/GUI_Stimuli/buttonBGklein.jpg');

h.buttonEyeBlink = uicontrol('Style', 'pushbutton', ...
    'String', 'Eye Start', ...
    'Enable', 'on', ...
    'Position', [buttonPosX(1) buttonPosY2 buttonSizeX buttonSizeY], ... % bezogen auf das GUI/figure selbst
    'FontSize', buttonSizeX/10, ...
    'FontWeight', 'bold', ...
    'CData', h.buttonBG, ...
    'Callback', {@buttonEyeBlink_Callback, h});

h.button1 = uicontrol('Style', 'pushbutton', ...
    'String', 'Aufgabe 1', ...
    'Enable', 'off', ...
    'Position', [buttonPosX(1) buttonPosY1 buttonSizeX buttonSizeY], ... % bezogen auf das GUI/figure selbst
    'FontSize', buttonSizeX/10, ...
    'FontWeight', 'bold', ... % 'BackgroundColor', 'green', ...
    'ForegroundColor', [0.2 0.2 0.2], ...
    'Callback', {@button1_Callback, h});

h.button2 = uicontrol('Style', 'pushbutton', ...
    'String', 'Aufgabe 2', ... % 'BackgroundColor', [0.8 0.8 0.8], ...
    'Enable', 'off', ...
    'Position', [buttonPosX(2) buttonPosY1 buttonSizeX buttonSizeY], ... % bezogen auf das GUI/figure selbst
    'FontSize', buttonSizeX/10, ...
    'FontWeight', 'bold', ...
    'Callback', {@button2_Callback, h});

h.button3 = uicontrol('Style', 'pushbutton', ...
    'String', 'Aufgabe 3', ...
    'Enable', 'off', ...
    'Position', [buttonPosX(3) buttonPosY1 buttonSizeX buttonSizeY], ... % bezogen auf das GUI/figure selbst
    'FontSize', buttonSizeX/10, ...
    'FontWeight', 'bold', ...
    'Callback', {@button3_Callback, h});

h.button4 = uicontrol('Style', 'pushbutton', ...
    'String', 'Aufgabe 4', ...
    'Enable', 'off', ...
    'Position', [buttonPosX(4) buttonPosY2 buttonSizeX buttonSizeY], ... % bezogen auf das GUI/figure selbst
    'FontSize', buttonSizeX/10, ...
    'FontWeight', 'bold', ...
    'Callback', {@button4_Callback, h});

h.button5 = uicontrol('Style', 'pushbutton', ...
    'String', 'Aufgabe 5', ...
    'Enable', 'off', ...
    'Position', [buttonPosX(5) buttonPosY2 buttonSizeX buttonSizeY], ... % bezogen auf das GUI/figure selbst
    'FontSize', buttonSizeX/10, ...
    'FontWeight', 'bold', ...
    'Callback', {@button5_Callback, h});

h.button6 = uicontrol('Style', 'pushbutton', ...
    'String', 'Aufgabe 6', ...
    'Enable', 'off', ...
    'Position', [buttonPosX(6) buttonPosY2 buttonSizeX buttonSizeY], ... % bezogen auf das GUI/figure selbst
    'FontSize', buttonSizeX/10, ...
    'FontWeight', 'bold', ...
    'Callback', {@button6_Callback, h});


%% GUI Texts

textSizeX = GUIsize(3)*0.8;
textSizeY = GUIsize(4)*0.4;
textSizeY2 = textSizeY*0.2;
textPosX = GUIsize(3)/2 - textSizeX/2;
textPosY = GUIsize(4)*0.5;
textPosY2 = textPosY + textSizeY*0.8;

h.text0 = uicontrol('Style', 'text', ...
    'String', {'Willkommen zu Phase 2 der Studie!', '','Bitte passen Sie zunächst die Lautstärke an:'}, ...
    'Units', 'pixels', ...
    'Position', [textPosX textPosY textSizeX textSizeY], ... % bezogen auf das GUI/figure selbst
    'FontSize', buttonSizeX/5, ...
    'Visible', 'on', ...
    'BackgroundColor', GUIcolor);
uistack(h.text0, 'bottom');

h.text1 = uicontrol('Style', 'text', ...
    'String', {'','Nun starten wir mit den Aufgaben.', '', 'Drücken Sie den blauen Knopf,', 'um mit der ersten Aufgabe zu beginnen.'}, ...
    'Units', 'pixels', ...
    'Position', [textPosX textPosY textSizeX textSizeY], ... % bezogen auf das GUI/figure selbst
    'FontSize', buttonSizeX/5, ...
    'Visible', 'off', ...
    'BackgroundColor', GUIcolor);
uistack(h.text1, 'bottom');

h.text2 = uicontrol('Style', 'text', ...
    'String', {'Kurze Pause.', '', 'Drücken Sie den blauen Knopf,', 'um mit der nächsten Aufgabe fortzufahren'}, ...
    'Units', 'pixels', ...
    'Position', [textPosX textPosY textSizeX textSizeY], ... % bezogen auf das GUI/figure selbst
    'FontSize', buttonSizeX/5, ...
    'Visible', 'off', ...
    'BackgroundColor', GUIcolor);
uistack(h.text2, 'bottom');

h.text3 = uicontrol('Style', 'text', ...
    'String', '! 5-10 Minuten Pause !', ...
    'Units', 'pixels', ...
    'Position', [textPosX textPosY2 textSizeX textSizeY2], ... % bezogen auf das GUI/figure selbst
    'FontSize', buttonSizeX/5, ...
    'Visible', 'off', ...
    'BackgroundColor', GUIcolor, ...
    'ForegroundColor', [1 0 0], ...
    'FontWeight', 'bold');
uistack(h.text3, 'top');

h.text4 = uicontrol('Style', 'text', ...
    'String', {'', '', 'Phase 2 der Studie ist nun beendet.','','Bitte wenden Sie sich mit Handzeichen an den Testleiter.'}, ...
    'Units', 'pixels', ...
    'Position', [textPosX textPosY textSizeX textSizeY], ... % bezogen auf das GUI/figure selbst
    'FontSize', buttonSizeX/5, ...
    'Visible', 'off', ...
    'BackgroundColor', GUIcolor);
uistack(h.text4, 'bottom');


%% GUI volume slider

h.audio = wavread(['Stimuli/GUI_Stimuli/TestAudio.wav']);
h.Fs = 44100;
h.volume = 5; % starting value for volume adjustment

h.buttonLauter = uicontrol('Style', 'pushbutton', ...
    'String', {'Lauter'}, ...
    'Enable', 'on', ...
    'Position', [buttonPosX(4) GUIsize(4)*0.67 buttonSizeX buttonSizeY/3], ... % bezogen auf das GUI/figure selbst
    'FontSize', buttonSizeX/10, ...
    'FontWeight', 'bold', ... 
    'CData', h.buttonBGklein, ...
    'Callback', {@buttonLauter_Callback, h});

h.buttonLeiser = uicontrol('Style', 'pushbutton', ...
    'String', {'Leiser'}, ...
    'Enable', 'on', ...
    'Position', [buttonPosX(3) GUIsize(4)*0.67 buttonSizeX buttonSizeY/3], ... % bezogen auf das GUI/figure selbst
    'FontSize', buttonSizeX/10, ...
    'FontWeight', 'bold', ... 
    'CData', h.buttonBGklein, ...
    'Callback', {@buttonLeiser_Callback, h});

h.buttonFertig = uicontrol('Style', 'pushbutton', ...
    'String', 'Fertig!', ...
    'Enable', 'on', ...
    'Position', [(buttonPosX(3)+buttonPosX(4))/2 GUIsize(4)*0.6 buttonSizeX buttonSizeY/3], ... % bezogen auf das GUI/figure selbst
    'FontSize', buttonSizeX/10, ...
    'FontWeight', 'bold', ...
    'Callback', {@buttonFertig_Callback, h});


%% GUI Arrows

arrowSizeX = 25;
arrowSizeY = 50;
for i = 1:5
    arrowPosX(i) = sum(buttonCenterX(i:i+1))/2 - arrowSizeX*0.5;
end
arrowPosY1 = buttonCenterY1 - arrowSizeY*0.5;  % top row
arrowPosY2 = buttonCenterY2 - arrowSizeY*0.5;  % lower row

h.arrow1 = uicontrol('Style', 'text', ...
    'String', '>', ...
    'Units', 'pixels', ...
    'Position', [arrowPosX(1) arrowPosY1 arrowSizeX arrowSizeY], ... 
    'FontSize', buttonSizeX/4, ...
    'FontWeight', 'bold', ... 
    'ForegroundColor', [0.2 0.2 0.2], ...
    'BackgroundColor', GUIcolor);
uistack(h.arrow1, 'bottom'); 

h.arrow2 = uicontrol('Style', 'text', ...
    'String', '>', ...
    'Position', [arrowPosX(2) arrowPosY1 arrowSizeX arrowSizeY], ... 
    'FontSize', buttonSizeX/4, ...
    'FontWeight', 'bold', ... 
    'ForegroundColor', [0.2 0.2 0.2], ...
    'BackgroundColor', GUIcolor);
uistack(h.arrow2, 'bottom'); 

h.arrow3 = uicontrol('Style', 'text', ...
    'String', '>', ...
    'Position', [arrowPosX(4) arrowPosY2 arrowSizeX arrowSizeY], ... 
    'FontSize', buttonSizeX/4, ...
    'FontWeight', 'bold', ... 
    'ForegroundColor', [0.2 0.2 0.2], ...
    'BackgroundColor', GUIcolor);
uistack(h.arrow3, 'bottom');     

h.arrow4 = uicontrol('Style', 'text', ...
    'String', '>', ...
    'Position', [arrowPosX(5) arrowPosY2 arrowSizeX arrowSizeY], ... 
    'FontSize', buttonSizeX/4, ...
    'FontWeight', 'bold', ... 
    'ForegroundColor', [0.2 0.2 0.2], ...
    'BackgroundColor', GUIcolor);
uistack(h.arrow4, 'bottom');  
        
% ============== GUI starts ================          
set(h.fig, 'Visible','on')  
guidata(h.fig, h);   % update handles structure


%% Callbacks

% --- Executes on button press
function buttonLeiser_Callback(hObject, eventdata, h)
% hObject    handle to button6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject, 'Enable', 'off');
h = guidata(hObject);
if h.volume <= 30
    h.volume = h.volume + 1;
end
%disp(h.volume);
sound(h.audio/h.volume, h.Fs);
%clear sound;
WaitSecs(length(h.audio)/h.Fs);
set(hObject, 'Enable', 'on');
guidata(hObject, h);

function buttonLauter_Callback(hObject, eventdata, h)
% hObject    handle to button6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject, 'Enable', 'off');
h = guidata(hObject);
if h.volume > 1
    h.volume = h.volume - 1;
end
%disp(h.volume);
sound(h.audio/h.volume, h.Fs);
WaitSecs(length(h.audio)/h.Fs);
set(hObject, 'Enable', 'on');
guidata(hObject, h);

function buttonFertig_Callback(hObject, eventdata, h)
% hObject    handle to button6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

h = guidata(hObject);
set(h.buttonLeiser, 'Visible', 'off');
set(h.buttonLauter, 'Visible', 'off');
set(hObject, 'Visible', 'off');
set(h.text0, 'Visible', 'off');
set(h.text1, 'Visible', 'on');
set(h.button1, 'Enable', 'on', 'CData', h.buttonBG);

fID3 = fopen([h.logpath 'Volume_' h.subjID '.txt'], 'w');
fprintf(fID3, '%d', h.volume);
fclose(fID3);

guidata(hObject, h);

% --- Executes on button1 press in button1.
function button1_Callback(hObject, eventdata, h)
% hObject    handle to button1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject, 'Enable', 'off', 'CData', []);  % to prevent second click from impatient subjects
h = guidata(hObject);

RotSpan(h.subjID);

fclose('all');
set(h.button2, 'Enable', 'on', 'CData', h.buttonBG);
set(h.text1, 'Visible', 'off');
set(h.text2, 'Visible', 'on', ...
    'String', {'Kurze Pause.','', '', 'Drücken Sie den blauen Knopf,', 'sobald Sie für die nächste Aufgabe bereit sind.'});

guidata(hObject, h); 
figure(h.fig); 

% --- Executes on button1 press in button2.
function button2_Callback(hObject, eventdata, h)
% hObject    handle to button2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject, 'Enable', 'off', 'CData', []);  % to prevent second click from impatient subjects
h = guidata(hObject);

OSpan(h.subjID);

fclose('all');
set(h.button3, 'Enable', 'on', 'CData', h.buttonBG);
set(h.text2, ...
    'String', {'Kurze Pause.','', '', 'Drücken Sie den blauen Knopf,', 'sobald Sie für die nächste Aufgabe bereit sind.'});

guidata(hObject, h); 
figure(h.fig); 

% --- Executes on button press in button3B.
function button3_Callback(hObject, eventdata, h)
% hObject    handle to button6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject, 'Enable', 'off', 'CData', []);  % to prevent second click from impatient subjects
h = guidata(hObject);

DD(h.subjID);

fclose('all');
set(h.button4, 'Enable', 'on', 'CData', h.buttonBG);
set(h.text3, 'Visible', 'on');
set(h.text2, ...
    'String', {'','','', 'Drücken Sie den blauen Knopf,', 'sobald Sie für die nächste Aufgabe bereit sind.'});

guidata(hObject, h); 
figure(h.fig); 

% --- Executes on button1 press in button4.
function button4_Callback(hObject, eventdata, h)
% hObject    handle to button4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject, 'Enable', 'off', 'CData', []);  % to prevent second click from impatient subjects
h = guidata(hObject);
set(h.text3, 'Visible', 'off');

ListeningSpan(h.subjID, h.volume);

fclose('all');
set(h.button5, 'Enable', 'on', 'CData', h.buttonBG);
set(h.text2, ...
    'String', {'Kurze Pause.','', '', 'Drücken Sie den blauen Knopf,', 'sobald Sie für die nächste Aufgabe bereit sind.'});

guidata(hObject, h); 
figure(h.fig); 

% --- Executes on button1 press in button5.
function button5_Callback(hObject, eventdata, h)
% hObject    handle to button5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject, 'Enable', 'off', 'CData', []);  % to prevent second click from impatient subjects
h = guidata(hObject);

DigitSpan(h.subjID, h.volume);

fclose('all');
set(h.button6, 'Enable', 'on', 'CData', h.buttonBG);
set(h.text2, ...
    'String', {'Kurze Pause.','','', 'Drücken Sie den blauen Knopf,', 'sobald Sie für die nächste Aufgabe bereit sind.'});

guidata(hObject, h); 
figure(h.fig); 

% --- Executes on button press in button3B.
function button6_Callback(hObject, eventdata, h)
% hObject    handle to button6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject, 'Enable', 'off', 'CData', []);  % to prevent second click from impatient subjects
h = guidata(hObject);

PD(h.subjID);

fclose('all');
set(h.text2, 'Visible', 'off');
set(h.text4, 'Visible', 'on');

guidata(hObject, h);
figure(h.fig);

% --- Executes on button press in button3B.
function buttonEyeBlink_Callback(hObject, eventdata, h)
% hObject    handle to button6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject, 'Visible', 'off', 'CData', []);  % to prevent second click from impatient subjects
h = guidata(hObject);
Blinkrate(h.PC);

fclose('all');
guidata(hObject, h);
figure(h.fig);