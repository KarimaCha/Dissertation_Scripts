function [] = RotSpan(subjID)
%% Rotation Span from Complex Span Test (Foster et al., 2014)
% (code written by Karima Chakroun, version: 21.01.2016, deutsch)
% [see bottom lines for task description]


%% Decide which task(s) to run:

block1 =  1;  % practice of Memory Task alone
block2 =  1;  % practice of Maths Task alone
block3 =  1;  % practice of both tasks
block4 =  1;  % experimental block of both tasks

try
%% Prepare computer for PTB usage

% call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% seed the random number generator
rand('seed', sum(100 * clock));  %rng('shuffle')

% skip SyncTests to avoid error messages due to non-optimal timing
sca;  % close all open screens (short for Screen('CloseAll'))
Screen('Preference', 'SkipSyncTests', 1);

        
%% Enter Subject ID and create logfiles

    if nargin < 1   % enter Subject ID
        
        subjID = [];
        while isempty(subjID)
            subjID = inputdlg('Bitte die Subject ID eingeben:');
            subjID = subjID{1};
        end
        
    end

    logpath = ['logs' filesep subjID filesep];
    
    % create folder if it not exists
    if ~exist(logpath, 'dir')
        mkdir(logpath);
    end
    
    fileID = fopen([logpath 'RotSpan_' subjID '.txt'], 'w');
    fileIDtext = fopen([logpath 'RotSpan_' subjID 'Text.txt'], 'w');


%% PTB Screen Preparation
    
    % Get the screen numbers
    screens = Screen('Screens');
    
    % Draw to the external screen if avaliable
    screenNumber = max(screens);
    % screenNumber = 1; % to test on Laptop!
    
    % Define colors
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    grey = 0.7;  % light grey
    red = [1 0 0];
    blue = [0 0 1];
    
    % Open an on screen window
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, white);
    
    % Get the centre coordinate of the window
    [xC, yC] = RectCenter(windowRect);
    
    % Get the size of the on screen window in pixels
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    smallScreen = 0;
    if screenXpixels < 1500
        smallScreen = 1; % to adjust some layout parameters
    end
    
    % Set the blend funciton for the screen
    %Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    % prevents keys you pressed during the experiment to show up in Matlab
    ListenChar(2);
    
    % show the mouse cursor (arrow) on active screen
    ShowCursor('Arrow', screenNumber);
    
    
    %% Timing Information
    
    % Query  frame duration (minimum possible time for drawing to the screen)
    ifi = Screen('GetFlipInterval', window);
    slack = ifi/2; % can be used later for more acurate timing
    
    % Present waiting screen until all images are loaded (see code below)
    Screen('TextSize', window, 40);
    Screen('TextStyle', window, 1);
    DrawFormattedText(window, 'Bitte warten...','center', 'center', black);
    tStartExp = Screen('Flip', window);
    
    % Duration of stimulus presentations or pauses (taken from E-prime script)
    
    % in block1 (memory practice):
    clearInstrB1 = 1;       % pause between last instruction page and first memory stimulus
    durMemoryB1 = 1;        % duration of a memory stimulus
    gapMemoryB1 = 0.5;      % pause between two memory stimuli
    clearForRecallB1 = 1;   % pause between last memory stimulus and recall screen
    durFeedbackB1 = 2;      % feedback duration; original was 1.5 s
    clearAfterSetB1 = 1;    % pause between feedback and new set / first instruction of next block
        
    % in block2 (processing practice):
    clearInstrB2 = 1;       % pause between last instruction page and first processing stimulus
    clearForTrialB2 = 0.5;  % pause before each processing stimulus / trial
    clearForRatingB2 = 0.2; % pause between processing stimulus and rating screen
    durFeedbackB2 = 1;      % feedback duration; original was 0.5 s
    
    % in block3/4 (both tasks):
    clearInstrB3 = 1;       % pause between last instruction page and first stimulus
    clearAfterRatingB3 = 0.2; % pause between (skipped) rating screen and next memory stimulus
    durMemoryB3 = 0.65;     % duration of a memory stimulus
    clearMemoryB3 = 0.25;   % pause between a memory stimulus and a processing stimulus
    clearForRecallB3 = 0.5; % pause between last memory stimulus and recall screen
    durFeedbackB3 = 3;      % feedback duration  original was 2.0 s >>  better 4s?!
    clearAfterSetB3 = 1;    % pause between feedback and new set

    
    %% Key / Response information
    
    % Define the keyboard keys that are listened for. We will be using the
    % space keys as response key and the escape key as an exit/reset key
    % KbName('KeyNames') > shows all keynames
    respKey = KbName('space');
    escapeKey = KbName('ESCAPE');
    
    
    %% Load Instruction Images
    
    for i = 1:18
        % create a M x N x 3 matrix of the color image with integers between 0 and 255
        instr = imread(['Stimuli\RotSpan_Stimuli\rotInstruktion_S',num2str(i),'.jpg']);
        
        % convert color matrix to floating point numbers between 0 and 1
        instrMatrix{i} = double(instr)/255;
        
        % convert image matrices to textures
        instrTexture{i} = Screen('MakeTexture', window, instrMatrix{i});
    end

    % set size and position for instruction image display
    instrDefaultImage = instrMatrix{1};
    instrImageRatio = size(instrDefaultImage,2)/size(instrDefaultImage,1);
    windowRatio = windowRect(3)/windowRect(4);
    if instrImageRatio <= windowRatio
        instrImageRect = [0,0,size(instrDefaultImage,2)*windowRect(4)/size(instrDefaultImage,1),windowRect(4)];
    elseif instrImageRatio > windowRatio
        instrImageRect = [0,0,windowRect(3),size(instrDefaultImage,1)*windowRect(3)/size(instrDefaultImage,2)];
    end
    instrImagePosition = CenterRectOnPoint(instrImageRect,xC,yC);
  
    
    %% Memory Task: Trial Parameter
    
    % create 4 sets of practice trials for block1 (2x2-set and 2x3-set)
    memoryPool = Shuffle(1:16);
    prac1MemorySet{1} = memoryPool(1:2);
    memoryPool = Shuffle(1:16);
    prac1MemorySet{2} = memoryPool(1:2);
    memoryPool = Shuffle(1:16);
    prac1MemorySet{3} = memoryPool(1:3);
    memoryPool = Shuffle(1:16);
    prac1MemorySet{4} = memoryPool(1:3);
    
    % create 3 sets of practice trials for block3  (3x2-set)
    memoryPool = Shuffle(1:16);
    prac2MemorySet{1} = memoryPool(1:2);
    memoryPool = Shuffle(1:16);
    prac2MemorySet{2} = memoryPool(1:2);
    memoryPool = Shuffle(1:16);
    prac2MemorySet{3} = memoryPool(1:2);
    
    % create 3 blocks of trials with one of each set sizes (2-5) randomly sampled within each block
    for i = 0:2  % for 3 blocks
        
        for setSize = 2:5
            memoryPool = Shuffle(1:16);
            memorySet{setSize} = memoryPool(1:setSize);
        end
        
        blockAdd = i*4;
        setPool = Shuffle(2:5);
        setPool = Shuffle(setPool);
        expMemorySet{1+blockAdd} = memorySet{setPool(1)};
        expMemorySet{2+blockAdd} = memorySet{setPool(2)};
        expMemorySet{3+blockAdd} = memorySet{setPool(3)};
        expMemorySet{4+blockAdd} = memorySet{setPool(4)};
        
    end
    
    
    %% Memory Task: Load Arrow Images
    
    % get all arrow images
    for memImg = 1:17  % image 17 = arrows for recall
        
        % create a M x N x 3 matrix of the color image with integers between 0 and 255
        memImage = imread(['Stimuli\RotSpan_Stimuli\arrow',num2str(memImg),'.bmp']);
        
        % convert color matrix to floating point numbers between 0 and 1
        memImageMatrix{memImg} = double(memImage)/255;
        
        % transform image matrices into textures
        memImageTexture{memImg} = Screen('MakeTexture', window, memImageMatrix{memImg});
    end
    
    % set size and position for single arrow image display
    memImageHeight = screenYpixels*0.7;
    memImageX = size(memImageMatrix{1},2);
    memImageY = size(memImageMatrix{1},1);
    memImageRect = [0,0,memImageHeight/memImageY*memImageX,memImageHeight];
    memImagePosition = CenterRectOnPoint(memImageRect,xC,yC);

      
    %% Memory Task: Define Drawing Parameters (Squares & Buttons)
    
    % Size of small squares (100 x 100 pixels)
    RectX = memImageHeight/10;
    RectY = memImageHeight/10;
    h = RectX/2;
    baseRect = [0 0 RectX RectX];
    
    % Screen X/Y positions of arrow heads
    yTop1 = memImagePosition(2) + h;
    yTop2 = memImagePosition(2) + memImageRect(4)*0.26 + h;
    yBottom1 = memImagePosition(4) - h;
    yBottom2 = memImagePosition(4) - memImageRect(4)*0.26 - h;
    xLeft1 = memImagePosition(1) + h;
    xLeft2 = memImagePosition(1) + memImageRect(4)*0.38 + h;
    xRight1 = memImagePosition(3) - h;
    xRight2 = memImagePosition(3) - memImageRect(4)*0.38 - h;
    squarePos = [xC yTop1;                  % arrow1     1-8 = big arrows
                xRight1-4*h yTop1+2*h;      % arrow2
                xRight1 yC;                 % arrow3
                xRight1-4*h yBottom1-2*h;   % arrow4
                xC yBottom1;                % arrow5
                xLeft1+4*h yBottom1-2*h;    % arrow6
                xLeft1 yC;                  % arrow7
                xLeft1+4*h yTop1+2*h;       % arrow8
                xC yTop2;                   % arrow9     9-16 = small arrows
                xRight2-h yTop2+h;          % arrow10
                xRight2 yC;                 % arrow11
                xRight2-h yBottom2-h;       % arrow12
                xC yBottom2;                % arrow13
                xLeft2+h yBottom2-h;        % arrow14
                xLeft2 yC;                  % arrow15
                xLeft2+h yTop2+h            % arrow16
                ];                   
    numSquares = length(squarePos);
    
    % Center the rectangle on the centre of the screen
    allRects = nan(4, numSquares);
    for i = 1:numSquares
        allRects(:,i) = CenterRectOnPointd(baseRect, squarePos(i,1), squarePos(i,2));
    end
    allRects(:,17) = [-100 -100 -100 -100]; % for click on blank button
    
    % Header
    headerSize = [0 0 screenXpixels*0.9 screenYpixels*0.16];
    headerRect = CenterRectOnPointd(headerSize, xC, screenYpixels*0.08);
    
    % Buttons
    buttonSizeBlank = [0 0 screenYpixels*0.20 RectY];
    buttonSizeClear = [0 0 screenYpixels*0.20 RectY];
    buttonTextSize = 28;
    Screen('TextSize', window, buttonTextSize);
    Screen('TextStyle', window, 1);
    
    blankRectXmid = xC;  % Blank button
    blankRectYmid = screenYpixels*0.92;
    blankRect = CenterRectOnPointd(buttonSizeBlank, blankRectXmid, blankRectYmid);
    blankTextRect = Screen('TextBounds', window, 'Blank');
    blankTextX = blankRectXmid - 0.5*blankTextRect(3);
    blankTextY = blankRectYmid - 0.5*blankTextRect(4);
    
    clearRectXmid = screenXpixels*0.25;  % Clear button
    clearRectYmid = screenYpixels*0.92;
    clearRect = CenterRectOnPointd(buttonSizeClear, clearRectXmid, clearRectYmid);
    clearTextRect = Screen('TextBounds', window, 'Clear');
    clearTextX = clearRectXmid - 0.5*clearTextRect(3);
    clearTextY = clearRectYmid - 0.5*clearTextRect(4);
    
    enterRectXmid = screenXpixels*0.75;  % Enter button
    enterRectYmid = screenYpixels*0.92;
    enterRect = CenterRectOnPointd(buttonSizeClear, enterRectXmid, enterRectYmid);
    enterTextRect = Screen('TextBounds', window, 'Enter');
    enterTextX = enterRectXmid - 0.5*enterTextRect(3);
    enterTextY = enterRectYmid - 0.5*enterTextRect(4);

    
    %% Rotation Task: Load Letter Stimuli
    
    % get rotation images
    letters = {'F' 'G' 'J' 'R'};
    angles = [0:7] * 45;
    i=1;
    for letter = 1:4
        currentLetter = letters{letter};
        
        for angle = 1:8
            currentAngle = angles(angle);
            
            rotImage = imread(['Stimuli\RotSpan_Stimuli\', currentLetter, num2str(currentAngle),'.bmp']);
            
            % convert color matrix to floating point numbers between 0 and 1
            rotMatrix{i} = double(rotImage); % odd number = normal orientation
            rotMatrix{i+1} = fliplr(double(rotImage)); % even number = mirrored orientation
            
            % convert image matrices to textures
            rotTexture{i} = Screen('MakeTexture', window, rotMatrix{i});
            rotTexture{i+1} = Screen('MakeTexture', window, rotMatrix{i+1});
            
            % store assignment of texture index to letter parameters
            rotIndices(i,:) = {i, currentLetter, currentAngle, 'normal'};
            rotIndices(i+1,:) = {i+1, currentLetter, currentAngle, 'mirrored'};
            
            i = i+2;
        end
        
    end
    
    % create vector of pseudorandomized rotation conditions for practice (block 2)
    pracRotations = Shuffle([1, 3, 7, 8, 12, 26, 29, 30, 33, 46, 50, 54, 55, 56, 57]);  % taken from E-prime script
    
    % create vector of pseudorandomized rotation conditions for experiment (block 3+4)
    expRotationsPool = Shuffle([1:49]);
    expRotations = expRotationsPool(1:48);  % 1-6 = block3; 7-48 = block4 (42 trials)

    
    %% Rotation Task: Define Drawing Parameters (Buttons & Texts)
    
    % define screen position of rotated letters
    rotLetterSize = [0 0 200 200];
    rotLetterRect = CenterRectOnPointd(rotLetterSize, xC, yC);
    
    % define screen position of rotation click instruction in block2
    rotTextSize = 28;
    rotTextStyle = 0;
    Screen('TextSize', window, rotTextSize);
    Screen('TextStyle', window, rotTextStyle);
    rotText2a = 'Wenn Sie sich entschieden haben,';
    rotText2b = 'klicken Sie die Maus zum Fortfahren.';
    rotText2Xmid = xC;
    rotText2Ymid = screenYpixels*0.75;
    rotText2aRect = Screen('TextBounds', window, rotText2a);
    rotText2bRect = Screen('TextBounds', window, rotText2b);
    rotText2aX = rotText2Xmid - 0.5*rotText2aRect(3);  % line 1
    rotText2aY = rotText2Ymid - 0.5*rotText2aRect(4);
    rotText2bX = rotText2Xmid - 0.5*rotText2bRect(3);  % line 2
    rotText2bY = rotText2Ymid + 0.75*rotText2aRect(4);
    
%     % define screen position of rotation click instruction in block3/4
%     rotText3 = 'Klicken Sie die Maus zum Fortfahren.';
%     rotText3Xmid = xC;
%     rotText3Ymid = screenYpixels*0.75;
%     rotText3Rect = Screen('TextBounds', window, rotText3);
%     rotText3X = rotText3Xmid - 0.5*rotText3Rect(3);
%     rotText3Y = rotText3Ymid - 0.5*rotText3Rect(4);
    
    % Buttons
    buttonSizeYN = [0 0 200 100];
    buttonTextSizeYN = 25;
    Screen('TextSize', window, buttonTextSizeYN);
    
    yesRectXmid = xC*0.6;  % 'Correct' button
    yesRectYmid = yC;
    yesRect = CenterRectOnPointd(buttonSizeYN, yesRectXmid, yesRectYmid); 
    yesTextRect = Screen('TextBounds', window, 'Richtig');
    yesTextX = yesRectXmid - 0.5*yesTextRect(3);
    yesTextY = yesRectYmid - 0.5*yesTextRect(4);
    
    noRectXmid = xC*1.4;   % 'Incorrect' button
    noRectYmid = yC;
    noRect = CenterRectOnPointd(buttonSizeYN, noRectXmid, noRectYmid); 
    noTextRect = Screen('TextBounds', window, 'Falsch');
    noTextX = noRectXmid - 0.5*noTextRect(3);
    noTextY = noRectYmid - 0.5*noTextRect(4);
    
    % Pen width for the frames
    penWidthPixels = 1;


    %% 1a | Memory Task: Instruction
    
    if block1 == 1
        
        [x,y,buttons] = GetMouse;
        while buttons(1); [x,y,buttons] = GetMouse; end % if already down, wait for release
        
        for instr = 1:8
            Screen('DrawTexture', window, instrTexture{instr}, [], instrImagePosition);
            Screen('Flip', window);
            
            while ~buttons(1) % wait for press
                [x,y,buttons] = GetMouse;
                [keyIsDown, tKeyPress, keyCode] = KbCheck;
                if keyIsDown && keyCode(escapeKey)
                    error('Abbruch des Experiments mit Escape');
                end
            end
            
            while buttons(1); [x,y,buttons] = GetMouse; end % wait for release
            
        end % instructions
        
        Screen('FillRect',window,white)
        Screen('Flip',window);
        WaitSecs(clearInstrB1 - slack);
        
        
        %% 1b | Memory Task: Practice - Stimulus Presentation
        
        % present letter images one after the other
        
        MemorySet = prac1MemorySet;
        msMax = 4;
        
        for ms = 1:msMax
            
            HideCursor; % hide mouse cursor during stimulus presentation
            currentMemorySet = MemorySet{ms};
                    
            for mat = 1:length(currentMemorySet)
                Screen('DrawTexture',window, memImageTexture{currentMemorySet(mat)}, [], memImagePosition);
                tMemoryOn = Screen('Flip',window);
                
                Screen('FillRect',window,white)
                tMemoryOff = Screen('Flip',window, tMemoryOn + durMemoryB1 - slack);
                WaitSecs(gapMemoryB1 - slack);
            end
            
            WaitSecs(clearForRecallB1 - slack);
            
            
            %% 1c | Memory Task: Practice - Recall Screen
            
            % Set initial position of the mouse to be in the centre of the screen
            SetMouse(xC, yC, window); %!! does  not work for second screen!
            ShowCursor('Arrow', screenNumber);
            
            % Maximum priority level
            topPriorityLevel = MaxPriority(window);
            Priority(topPriorityLevel);
            
            [x,y,buttons] = GetMouse(window);
            
            while any(buttons) % if already down, wait for release
                [x,y,buttons] = GetMouse;
            end
            
            % set initial values to store recall responses in Memory Task
            clicked=[];     % stores indices of clicked arrowheads (1-16; blank = 17)
            count= 1;       % counts the number of valid clicks
            stopTrial = 0;  % to stop trial as soon as enter-Button was pressed
            
            % Loop recall responses until enter button is pressed
            while ~stopTrial
                while ~buttons(1)  % while no right mouse click
                    
                    % Get the current position of the mouse
                    [x,y,buttons] = GetMouse(window);
                    
                    % Check in which square or on which button the mouse cursor is
                    for j = 1:numSquares
                        inside(j) = IsInRect(x, y, allRects(:,j));
                    end
                    ind = find(inside==1); % index of square with mouse pointer inside
                    outside = isempty(ind); % check is mouse was outside squares
                    blankB = IsInRect(x,y, blankRect);
                    clearB = IsInRect(x,y, clearRect);
                    enterB = IsInRect(x,y, enterRect);
                    
                    % check if click is valid (not outside square and not already clicked)
                    if buttons(1)==1 && ~outside && ~ismember(ind(1),clicked) && length(clicked)<length(currentMemorySet)
                        clicked(count) = ind(1);
                        count=count+1;
                    end
                    
                    % check if blank button was clicked
                    if buttons(1)==1 && blankB && length(clicked)<length(currentMemorySet)
                        clicked(count) = 17;
                        count=count+1;
                    end
                    
                    % check if clear button was clicked
                    if buttons(1)==1 && clearB
                        clicked=[];
                        count= 1;
                    end
                    
                    % check if enter button was clicked
                    if buttons(1)==1 && enterB
                        stopTrial = 1;  % trial is stopped
                        break
                    end
                    
                    % check if esc key was pressed and abort experiment
                    [keyIsDown, tKeyPress, keyCode] = KbCheck;
                    if keyIsDown && keyCode(escapeKey)
                        error('Abbruch des Experiments mit Escape');
                    end
                    
                    % Draw arrows to choose from as background image on screen
                    Screen('DrawTexture',window, memImageTexture{17}, [], memImagePosition);
                    
                    % Show click index where mouse click occured
                    if ~isempty(clicked)
                        Screen('FillRect', window, white ,allRects(:,clicked));
                        %! Screen('FrameRect', window, blue ,allRects(:,clicked));
                        Screen('TextSize', window, 30);
                        Screen('TextStyle', window, 1);
                        for c = 1:count-1
                            temp = allRects(:,clicked(c));
                            tempX = temp(1)+(temp(3)-temp(1))/2;
                            tempY = temp(2)+(temp(4)-temp(2))/2;
                            currentTextRect = Screen('TextBounds', window, num2str(c));
                            Screen('DrawText', window, num2str(c) ,tempX-0.5*currentTextRect(3), tempY-0.5*currentTextRect(4), red);
                        end
                    end
                    
                    % Draw rest of the squares on screen
                    % Screen('FrameRect', window, blue ,allRects, 2); %! to check clicke boxes 
                    
                    % Draw buttons on screen
                    Screen('TextSize', window, buttonTextSize);
                    % Screen('TextStyle', window, 1); % bold text
                    
                    Screen('FillRect', window, grey ,blankRect, 2);
                    Screen('FrameRect', window, black ,blankRect, 2);
                    Screen('DrawText', window, 'Blank' , blankTextX, blankTextY, black);
                    
                    Screen('FillRect', window, grey ,clearRect, 2);
                    Screen('FrameRect', window, black ,clearRect, 2);
                    Screen('DrawText', window, 'Clear' , clearTextX, clearTextY, black);
                    
                    Screen('FillRect', window, grey ,enterRect, 2);
                    Screen('FrameRect', window, black ,enterRect, 2);
                    Screen('DrawText', window, 'Enter' , enterTextX, enterTextY, black);
                    
                    % Draw header on screen
                    if smallScreen==1
                        Screen('TextSize', window, 20); %Laptop!
                    else
                        Screen('TextSize', window, 25);
                    end
                    Screen('TextStyle', window, 1);
                    DrawFormattedText(window, 'Wählen Sie die Pfeile in der präsentierten Reihenfolge aus.\nBenutzen Sie den BLANK Knopf, um vergessene Pfeile einzufügen.',...
                        'center','center',black,[],[],[],2,[],headerRect);
                    
                    % Flip to the screen
                    Screen('Flip', window);
                    
                end
                
                while any(buttons) % wait for release
                    [x,y,buttons] = GetMouse;
                end
            end
            
            
            %% 1d | Memory Task: Practice - Feedback
            
            % calculate score of last trial
            if ~isempty(clicked)
                if length(currentMemorySet) <= length(clicked)
                    memScore = sum(currentMemorySet == clicked(1:length(currentMemorySet)));
                elseif length(currentMemorySet) > length(clicked)
                    memScore = sum(currentMemorySet(1:length(clicked)) == clicked);
                end
            elseif isempty(clicked)
                memScore = 0;
            end
            
            maxScore = length(currentMemorySet);
            
            HideCursor; % for Feedback Screen
            
            % present score of last trial on screen
            FBtext = ['Sie haben ',num2str(memScore),' von ',num2str(maxScore),' Pfeilen richtig erinnert!'];
            if smallScreen==1
                Screen('TextSize', window, 22); %Laptop!
            else
                Screen('TextSize', window, 30);
            end
            Screen('TextStyle', window, 1);
            DrawFormattedText(window, FBtext,'center','center',black);
            tFbOn = Screen('Flip', window);
            WaitSecs(durFeedbackB1 - slack);
            
            FbOff = Screen('Flip',window);
            WaitSecs(clearAfterSetB1 - slack);
            
        end
        
    end % block1
    
    
    %% 2a | Operation Task: Instruction
    
    if block2 == 1
        
        [~,~,buttons] = GetMouse;
        while buttons(1); [~,~,buttons] = GetMouse; end % if already down, wait for release

        ShowCursor('Arrow', screenNumber); % during instruction pages
        % Maximum priority level
        topPriorityLevel = MaxPriority(window);
        Priority(topPriorityLevel);        
        
        % Instructions
        for instr = 9:14
        
            Screen('DrawTexture', window, instrTexture{instr}, [], instrImagePosition);
            Screen('Flip', window);
            
            while ~buttons(1) % wait for press
                [~,~,buttons] = GetMouse;
                [keyIsDown, tKeyPress, keyCode] = KbCheck;
                if keyIsDown && keyCode(escapeKey)
                    error('Abbruch des Experiments mit Escape');
                end
            end
            
            while buttons(1); [~,~,buttons] = GetMouse; end % wait for release
            
        end % instructions
        
        Screen('FillRect',window,white)
        Screen('Flip',window);
        WaitSecs(clearInstrB2 - slack);
        
        
        %% 2b | Operation Task: Trial
        
        ShowCursor('Arrow',screenNumber);
        
        % Maximum priority level
        topPriorityLevel = MaxPriority(window);
        Priority(topPriorityLevel);
        
        % Create matrix to score RT for rotation practice
        nTrialsBlock2 = length(pracRotations);
        RTblock2 = nan(nTrialsBlock2,2);  % column1 = RT; column2 = correct answer?
        
        % Loop over practice trials
        for rot = 1:nTrialsBlock2
            
            while any(buttons) % if already down, wait for release
                [~,~,buttons] = GetMouse;
            end
            
            HideCursor; % hide mouse cursor during rotation stimulus presentation
            
            % show white screen before each processing stimulus / trial (like in E-prime)
            Screen('Flip',window);
            WaitSecs(clearForTrialB2 - slack); 
            
            % show processing stimulus
            currentPracRotation = rotTexture{pracRotations(rot)};
            Screen('DrawTexture', window, currentPracRotation, [], rotLetterRect);
            Screen('TextSize', window, rotTextSize);
            Screen('TextStyle', window, rotTextStyle);            
            Screen('DrawText', window, rotText2a, rotText2aX, rotText2aY, black);
            Screen('DrawText', window, rotText2b, rotText2bX, rotText2bY, black);
            tRotationOn = Screen('Flip',window);
            
            while ~buttons(1) % wait for press
                
                [~,~,buttons] = GetMouse;
                
                [keyIsDown, tKeyPress, keyCode] = KbCheck;
                if keyIsDown && keyCode(escapeKey)
                    error('Abbruch des Experiments mit Escape');
                end
            end
            
            % Store RT for this trial
            RTblock2(rot, 1) = GetSecs - tRotationOn;
            
            while buttons(1); [~,~,buttons] = GetMouse; end % wait for release
            
            Screen('FillRect',window,white)
            tRotationOff = Screen('Flip',window);
            WaitSecs(clearForRatingB2 - slack);
            
            % rate rotation of previous image
            
            ShowCursor('Arrow',screenNumber); % show cursor for rating
            
            [x,y,buttons] = GetMouse(window);
            
            while any(buttons) % if already down, wait for release
                [x,y,buttons] = GetMouse;
            end
            
            SetMouse(xC, yC, window); %!! does  not work for second screen!
            
            while 1 % while no key is pressed, loop does not break
                
                % Get the current position of the mouse
                [x,y,buttons] = GetMouse(window);
                
                % Check on which button the mouse cursor is
                yesClick = IsInRect(x,y, yesRect);
                noClick = IsInRect(x,y, noRect);
                
                % check which button was clicked
                if buttons(1)==1 && yesClick
                    rotAnswer=1;
                    break
                elseif buttons(1)==1 && noClick
                    rotAnswer=0;
                    break
                end
                
                % check if esc key was pressed and abort experiment
                [keyIsDown, tKeyPress, keyCode] = KbCheck;
                if keyIsDown && keyCode(escapeKey)
                    error('Abbruch des Experiments mit Escape');
                end
                
                % Draw qestions and buttons on screen
                Screen('TextSize', window, buttonTextSizeYN);
                Screen('TextStyle', window, 1);
                
                DrawFormattedText(window, 'Dieser Buchstabe ist normal orientiert.',...
                    'center', screenYpixels*0.25, black);
                
                Screen('FrameRect', window, black ,yesRect, 4);
                Screen('DrawText', window, 'Richtig' ,yesTextX, yesTextY, black);
                
                Screen('FrameRect', window, black ,noRect, 4);
                Screen('DrawText', window, 'Falsch' ,noTextX, noTextY, black);
                
                % Flip to the screen
                tRatingOn = Screen('Flip', window,[],1); % don't clear for next flip (Feedback)
                
            end
            
            % get mirrored level of current rotated letter (0=normal; 1=mirrored)
            if mod(pracRotations(rot),2)==1  % odd number (normal letter)
                currentOrientation = 1;
            elseif mod(pracRotations(rot),2)==0 % even number (mirrored letter)
                currentOrientation = 0;
            end
            
            % present feedback in practice block on same screen
            if rotAnswer == currentOrientation
                rotFeedback = 'Richtig';
                FBcolor = blue;
                RTblock2(rot, 2) = 1;
            elseif rotAnswer ~= currentOrientation
                rotFeedback = 'Falsch';
                FBcolor = red;
                RTblock2(rot, 2) = 0;
            end
            
            DrawFormattedText(window, rotFeedback,'center',yC*1.4,FBcolor);
            tFbOn = Screen('Flip',window); % not cleared before flip
            WaitSecs(durFeedbackB2 - slack);
            
            Screen('FillRect',window, white);
            Screen('Flip',window); % to get rid of 'don't clear' command from before
            
        end % rotationTask trials
        
        % calculate maximal RT for processing task in block3/4 from the
        % meanRT + 2.5 SD in this block (only from correctly answered trials)
        meanRTblock2 = mean(RTblock2(RTblock2(:,2)==1,1));
        sdRTblock2 = std(RTblock2(RTblock2(:,2)==1,1));
        rotRTmax = meanRTblock2 + 2.5*sdRTblock2;
        if rotRTmax < 1.0   % taken from E-prime script
            rotRTmax = 1.0;
        end
    
        % Save data of block2 to logfile
        fprintf(fileIDtext, 'RTs for practice of rotation task:\n');
        fprintf(fileIDtext, 'RT\tCorrect?\n');
        fprintf(fileIDtext, '%1.4f\t %d\n', RTblock2');
        
        
    end % block2
    
    
    %% 3/4a | Both Tasks: Instruction
    
    if block3==1 || block4==1

        rounds = block3 + block4;

    for round = 1:rounds
        
        ShowCursor('Arrow', screenNumber); % during instruction pages
        % Maximum priority level
        topPriorityLevel = MaxPriority(window);
        Priority(topPriorityLevel);        
        
        if block3==1
            
            Screen('TextSize', window, 25);
            Screen('TextStyle', window, 1);
            
            [x,y,buttons] = GetMouse;
            while buttons(1); [x,y,buttons] = GetMouse; end % if already down, wait for release
            
            % Instructions for Block 3
            for instr = 15:17

                Screen('DrawTexture', window, instrTexture{instr}, [], instrImagePosition);
                Screen('Flip', window);
                
                while ~buttons(1) % wait for press
                    [x,y,buttons] = GetMouse;
                    [keyIsDown, tKeyPress, keyCode] = KbCheck;
                    if keyIsDown && keyCode(escapeKey)
                        error('Abbruch des Experiments mit Escape');
                    end
                end
                
                while buttons(1); [x,y,buttons] = GetMouse; end % wait for release
                
            end % instructions
            
            Screen('FillRect',window,white)
            Screen('Flip',window);
            WaitSecs(clearInstrB3 - slack);
        
        end
        
        if block4==1 && block3==0
            
            Screen('TextSize', window, 25);
            Screen('TextStyle', window, 1);
            
            [x,y,buttons] = GetMouse;
            while buttons(1); [x,y,buttons] = GetMouse; end % if already down, wait for release
            
            % Instructions for Block 4
            instr = 18;
            Screen('DrawTexture', window, instrTexture{instr}, [], instrImagePosition);
            Screen('Flip', window);
                
            while ~buttons(1) % wait for press
                [x,y,buttons] = GetMouse;
                [keyIsDown, tKeyPress, keyCode] = KbCheck;
                if keyIsDown && keyCode(escapeKey)
                    error('Abbruch des Experiments mit Escape');
                end
            end
            
            while buttons(1); [x,y,buttons] = GetMouse; end % wait for release
            
            Screen('FillRect',window,white)
            Screen('Flip',window);
            WaitSecs(1 - slack);   % like in E-Prime (Wait1000ms)
            
        end
        
        
        %% 3/4b | Both Tasks: Stimulus Presentation
        
        % set maximal RT for rotation judgments to RT+2.5SD from block2
        if exist('rotRTmax')==0  % if no RT measured in block2
            rotRTmax = 4.5;
        end
        
        if block3==1
            
            IsPractice = 1; % do not store responses
            
            % set memory trial parameters to practice trials
            MemorySet = prac2MemorySet;
            msMax = 3;
            
            % set rotation trial parameters to practice trials
            nRotTrials = 6;
            rotTrialCounter = 1;
            currentRotScore = 0; % set to zero before each block
            
        end
        
        if block4==1 && block3==0
            
            IsPractice = 0; % store responses
                    
            % save maximal RT for rotation task in block3/4 to logfile
            fprintf(fileIDtext, ['\n\nMaximal RT for rotation task: ', num2str(rotRTmax)]);
            
            % set memory trial parameters to experimental trials
            MemorySet = expMemorySet;
            msMax = 12;
            
            % set rotation trial parameters to experimental trials
            nRotTrials = 42;
            rotTrialCounter = 7;
            currentRotScore = 0; % set to zero before each block
            
            % create response matrix to save trial parameters of block4
            RespMatrix = nan(nRotTrials,7);
            zeile=0; % current line of response matrix
            
            % columns: (1) set, (2) trial, (3) RotCorrect, (4) RotRT, (5)
            % RotAccuracy, (6) MemoryScore, (7) SetCorrect?

            % print header for response data of block4 in logfile
            fprintf(fileIDtext,'\n\nset\ttrial\tRotCorrect\tRotRT\tRotAccuracy\tMemoryScore\tSetCorrect\n');
        
        end
        
        % present memory and rotation trials in alternation
        
        for ms = 1:msMax
   
            % get memory parameters for this trial
            currentMemorySet = MemorySet{ms};
                
            % set initial sum of rotation errors in this set to 0
            rotErrorsSet = 0;
            
            for mat = 1:length(currentMemorySet)
                
                HideCursor; % hide mouse cursor during memory stimulus presentation
                
                if IsPractice==0
                    zeile=zeile+1; % go to next line in response matrix
                end
                
                % present rotation problem for this trial
                currentExpRotation = rotTexture{expRotations(rotTrialCounter)};
            
                while any(buttons) % if already down, wait for release
                    [~,~,buttons] = GetMouse;
                end
                
                Screen('DrawTexture', window, currentExpRotation, [], rotLetterRect);
                Screen('TextSize', window, rotTextSize);
                Screen('TextStyle', window, rotTextStyle);
                Screen('DrawText', window, rotText2a, rotText2aX, rotText2aY, black);
                Screen('DrawText', window, rotText2b, rotText2bX, rotText2bY, black);
                %Screen('DrawText', window, rotText3, rotText3X, rotText3Y, black);
                tRotationOn = Screen('Flip',window);
                
                doRotRating = 0;  % don't go to rating if RT > rotRTmax
                
                while GetSecs - tRotationOn <= rotRTmax % individual response window

                    % Check for mouse clicks
                    [~,~,buttons] = GetMouse; 
                    if buttons(1)==1
                        doRotRating = 1;
                        break
                    end
                    
                    % Check for escape key press
                    [keyIsDown, tKeyPress, keyCode] = KbCheck;
                    if keyIsDown && keyCode(escapeKey)
                        error('Abbruch des Experiments mit Escape');
                    end
                    
                end
                
                % get RT for this trial (only in block4)
                if IsPractice==0
                    rotRTblock4 = GetSecs - tRotationOn;
                end
                
                while buttons(1); [~,~,buttons] = GetMouse; end % wait for release
                
                Screen('FillRect',window,white)
                tRotationOff = Screen('Flip',window);
                
                % rate orientation of previous rotated letter
                
                % Set initial position of the mouse to be in the centre of the screen
                SetMouse(xC, yC, window); %!! does  not work for second screen!
                ShowCursor('Arrow',screenNumber); % show mouse cursor for rating
                
                % Maximum priority level
                topPriorityLevel = MaxPriority(window);
                Priority(topPriorityLevel);
                
                if doRotRating==0
                    
                    rotAnswer = 9; % no rotation rating > counts as an (speed) error
                    
                elseif doRotRating==1
                    
                    [x,y,buttons] = GetMouse(window);
                    
                    while any(buttons) % if already down, wait for release
                        [x,y,buttons] = GetMouse;
                    end
                    
                    while 1 % while no key is pressed, loop does not break
                        
                        % Get the current position of the mouse
                        [x,y,buttons] = GetMouse(window);
                        
                        % Check on which button the mouse cursor is
                        yesClick = IsInRect(x,y, yesRect);
                        noClick = IsInRect(x,y, noRect);
                        
                        % check which button was clicked
                        if buttons(1)==1 && yesClick
                            rotAnswer = 1;  
                            break
                        elseif buttons(1)==1 && noClick
                            rotAnswer = 0;
                            break
                        end
                        
                        % check if esc key was pressed and abort experiment
                        [keyIsDown, tKeyPress, keyCode] = KbCheck;
                        if keyIsDown && keyCode(escapeKey)
                            error('Abbruch des Experiments mit Escape');
                        end
                        
                        % Draw qestions and buttons on screen
                        Screen('TextSize', window, buttonTextSizeYN);
                        Screen('TextStyle', window, 1);
                        
                        DrawFormattedText(window, 'Dieser Buchstabe ist normal orientiert.',...
                            'center', screenYpixels*0.25, black);
                        
                        Screen('FrameRect', window, black ,yesRect, 4);
                        Screen('DrawText', window, 'Richtig' ,yesTextX, yesTextY, black);
                        
                        Screen('FrameRect', window, black ,noRect, 4);
                        Screen('DrawText', window, 'Falsch' ,noTextX, noTextY, black);
                        
                        % Flip to the screen
                        tRatingOn = Screen('Flip', window);
                        
                    end
                    
                end % rotRating

                HideCursor; % hide mouse cursor during memory stimulus presentation
                
                tRatingOff = Screen('Flip',window);
                WaitSecs(clearAfterRatingB3 - slack);
                
                % present current memory stimulus (arrow) of this set
                Screen('DrawTexture',window, memImageTexture{currentMemorySet(mat)}, [], memImagePosition);
                tMemoryOn = Screen('Flip',window);
                
                Screen('FillRect',window,white)
                tMemoryOff = Screen('Flip',window, tMemoryOn + durMemoryB3 - slack);
                WaitSecs(clearMemoryB3 - slack);            
                
                % get mirrored level of current rotated letter (0=normal; 1=mirrored)
                if mod(expRotations(rotTrialCounter),2)==1  % odd number (normal letter)
                    currentOrientation = 1;
                elseif mod(expRotations(rotTrialCounter),2)==0 % even number (mirrored letter)
                    currentOrientation = 0;
                end
                
                % get correctness score to present feedback after the memory
                % set (after the Recall Screen)
                if rotAnswer == currentOrientation
                    rotTrialCorrect = 1;    % correct answer
                    currentRotScore = currentRotScore+1;
                elseif rotAnswer ~= currentOrientation
                    if rotAnswer ~= 9
                        rotTrialCorrect = 0; % accuracy error
                    elseif rotAnswer == 9   
                        rotTrialCorrect = 9; % speed error
                    end
                    currentRotScore = currentRotScore+0;
                    rotErrorsSet = rotErrorsSet + 1;
                end
                
                % calculate overall accuracy for rotation trials of this block
                
                if IsPractice==1
                    rotAccuracy = currentRotScore/rotTrialCounter*100;
                elseif IsPractice==0
                    rotAccuracy = currentRotScore/(rotTrialCounter-6)*100;
                end
                rotTrialCounter = rotTrialCounter + 1;  % increase by 1 for next trial (!think of practice trials - start counter here with 7)
            
                % save parameters of this trial in response matrix
                if IsPractice==0
                    RespMatrix(zeile,1) = ms;
                    RespMatrix(zeile,2) = mat;
                    RespMatrix(zeile,3) = rotTrialCorrect;
                    RespMatrix(zeile,4) = rotRTblock4;
                    
                    % write current trial parameters to logfile (column 1-4)
                    fprintf(fileIDtext, '\n %d\t %d\t %d\t %1.4f\t', RespMatrix(zeile,1:4)');
                
                end
                
            end  % memory set
            
            WaitSecs(clearForRecallB3 - slack);

            
            %% 3/4c | Both Tasks: Recall Screen
            
            % Set initial position of the mouse to be in the centre of the screen
            SetMouse(xC, yC, window); %!! does not work for second screen!
            ShowCursor('Arrow',screenNumber);
            
            % Maximum priority level
            topPriorityLevel = MaxPriority(window);
            Priority(topPriorityLevel);
            
            [x,y,buttons] = GetMouse(window);
            
            while any(buttons) % if already down, wait for release
                [x,y,buttons] = GetMouse;
            end
            
            % set initial values to store recall responses in Memory Task
            clicked=[];     % stores indices of clicked arrwoheads (1-16; blank = 17)
            count= 1;       % counts the number of valid clicks
            stopTrial = 0;  % to stop trial as soon as enter-Button was pressed
            
            % Loop recall responses until enter button is pressed
            while ~stopTrial
                while ~buttons(1)  % while no right mouse click
                    
                    % Get the current position of the mouse
                    [x,y,buttons] = GetMouse(window);
                    
                    % Check in which square or on which button the mouse cursor is
                    for j = 1:numSquares
                        inside(j) = IsInRect(x, y, allRects(:,j));
                    end
                    ind = find(inside==1); % index of square with mouse pointer inside
                    outside = isempty(ind); % check is mouse was outside squares
                    blankB = IsInRect(x,y, blankRect);
                    clearB = IsInRect(x,y, clearRect);
                    enterB = IsInRect(x,y, enterRect);
                    
                    % check if click is valid (not outside square and not already clicked)
                    if buttons(1)==1 && ~outside && ~ismember(ind(1),clicked) && length(clicked)<length(currentMemorySet)
                        clicked(count) = ind(1);
                        count=count+1;
                    end
                    
                    % check if blank button was clicked
                    if buttons(1)==1 && blankB && length(clicked)<length(currentMemorySet)
                        clicked(count) = 17;
                        count=count+1;
                    end
                    
                    % check if clear button was clicked
                    if buttons(1)==1 && clearB
                        clicked=[];
                        count= 1;
                    end
                    
                    % check if enter button was clicked
                    if buttons(1)==1 && enterB
                        stopTrial = 1;  % trial is stopped
                        break
                    end
                    
                    % check if esc key was pressed and abort experiment
                    [keyIsDown, tKeyPress, keyCode] = KbCheck;
                    if keyIsDown && keyCode(escapeKey)
                        error('Abbruch des Experiments mit Escape');
                    end

                    % Draw arrows to choose from as background image on screen
                    Screen('DrawTexture',window, memImageTexture{17}, [], memImagePosition);
                    
                    % Show click index where mouse click occured
                    if ~isempty(clicked)
                        Screen('FillRect', window, white ,allRects(:,clicked));
                        % Screen('FrameRect', window, blue ,allRects(:,clicked));
                        Screen('TextSize', window, 30);
                        Screen('TextStyle', window, 1);
                        for c = 1:count-1
                            temp = allRects(:,clicked(c));
                            tempX = temp(1)+(temp(3)-temp(1))/2;
                            tempY = temp(2)+(temp(4)-temp(2))/2;
                            currentTextRect = Screen('TextBounds', window, num2str(c));
                            Screen('DrawText', window, num2str(c) ,tempX-0.5*currentTextRect(3), tempY-0.5*currentTextRect(4), red);
                        end
                    end
                    
                    % Draw rest of the squares on screen
                    % Screen('FrameRect', window, blue ,allRects, 2); %! to check clicke boxes
                    
                    % Draw buttons on screen
                    Screen('TextSize', window, buttonTextSize);
                    Screen('TextStyle', window, 1); % bold text
                    
                    Screen('FillRect', window, grey ,blankRect, 2);
                    Screen('FrameRect', window, black ,blankRect, 2);
                    Screen('DrawText', window, 'Blank' , blankTextX, blankTextY, black);
                    
                    Screen('FillRect', window, grey ,clearRect, 2);
                    Screen('FrameRect', window, black ,clearRect, 2);
                    Screen('DrawText', window, 'Clear' , clearTextX, clearTextY, black);
                    
                    Screen('FillRect', window, grey ,enterRect, 2);
                    Screen('FrameRect', window, black ,enterRect, 2);
                    Screen('DrawText', window, 'Enter' , enterTextX, enterTextY, black);
                    
                    % Draw header on screen
                    if smallScreen==1
                        Screen('TextSize', window, 20); %Laptop!
                    else
                        Screen('TextSize', window, 25);
                    end
                    Screen('TextStyle', window, 1);
                    DrawFormattedText(window, 'Wählen Sie die Pfeile in der präsentierten Reihenfolge aus.\nBenutzen Sie den BLANK Knopf, um vergessene Pfeile einzufügen.',...
                        'center','center',black,[],[],[],2,[],headerRect);
                    
                    % Flip to the screen
                    Screen('Flip', window);
                    
                end
                
                while any(buttons) % wait for release
                    [x,y,buttons] = GetMouse;
                end
            end
            
            
            %% 3/4d | Both Tasks: Feedback

            % calculate score of last trial
            if ~isempty(clicked)
                if length(currentMemorySet) <= length(clicked)
                    memScore = sum(currentMemorySet == clicked(1:length(currentMemorySet)));
                elseif length(currentMemorySet) > length(clicked)
                    memScore = sum(currentMemorySet(1:length(clicked)) == clicked);
                end
            elseif isempty(clicked)
                memScore = 0;
            end
            maxScore = length(currentMemorySet);
            
            % check if entire set was correct
            if memScore == maxScore
                SetCorrect = 1; % entire set correct
            else
                SetCorrect = 0;  % not entire set correct
            end
            
            HideCursor; % for Feedback Screen
            
            % present score of last trial on screen
            rotAccuracyStr = [num2str(sprintf('%.0f', rotAccuracy)),' %'];
            FBtext = ['Sie haben ',num2str(memScore),' von ',num2str(maxScore),' Pfeilen richtig erinnert!',...
                '\n\n\n\nSie haben ', num2str(rotErrorsSet), ' Rotations-Fehler in diesem Durchgang gemacht.'];
            if smallScreen==1
                Screen('TextSize', window, 22); %Laptop!
            else
                Screen('TextSize', window, 30);
            end
            Screen('TextStyle', window, 1);
            DrawFormattedText(window, FBtext,'center','center',black);
            Screen('DrawText', window, rotAccuracyStr, screenXpixels*0.9, screenYpixels*0.05, red);
            
            tFbOn = Screen('Flip', window);
            WaitSecs(durFeedbackB3 - slack);  
            
            FbOff = Screen('Flip',window);
            WaitSecs(clearAfterSetB3 - slack);
       
            % save parameters of this set in response matrix
            if IsPractice==0
                RespMatrix(zeile,5) = rotAccuracy;
                RespMatrix(zeile,6) = memScore;
                RespMatrix(zeile,7) = SetCorrect;
                
                % write current trial parameters to logfile (column 5-7)
                fprintf(fileIDtext, '%1.2f\t %d\t %d\t', RespMatrix(zeile,5:7)');
                
            end

            
        end % memory sets
    
    block3 = 0;  % don't do block3 again; stop (if rounds=1) or do block 4 (if rounds=2)

    
    %% save final scores of block4 to logfile
    
    if IsPractice==0
        
        % first store raw RespMatrix in a first txt-file without any text:
        fprintf(fileID, '%d\t %d\t %d\t %1.4f\t %1.2f\t %d\t %d\n', RespMatrix(:,1:7)');

        % store final scores in the second txt-file with text:
        rotAccErrors = sum(RespMatrix(:,3)==0); % total accuracy errors in rotation task
        rotSpeedErrors = sum(RespMatrix(:,3)==9); % total speed errors in rotation task
        rotTotalErrors = rotAccErrors + rotSpeedErrors; % total errors in rotation task
        
        fprintf(fileIDtext, ['\n\nFinal accuracy level (%%) in rotation task: ', rotAccuracyStr]);
        fprintf(fileIDtext, ['\nTotal processing errors in rotation task: ', num2str(rotTotalErrors)]);
        fprintf(fileIDtext, ['\n\t- Total accuracy errors: ', num2str(rotAccErrors)]);
        fprintf(fileIDtext, ['\n\t- Total speed errors: ', num2str(rotSpeedErrors)]); 
        
        RespMatrix(isnan(RespMatrix(:,6)),6) = 0;
        RespMatrix(isnan(RespMatrix(:,7)),7) = 0;
        absMemScore = sum(RespMatrix(:,6));
        partMemScore = sum(RespMatrix(:,6).*RespMatrix(:,7));
        
        fprintf(fileIDtext, ['\n\nAbsolute score (all correct trials) in memory task: ', num2str(absMemScore)]);
        fprintf(fileIDtext, ['\nPartial score (trials in correct sets) in memory task: ', num2str(partMemScore)]);
       
    end
    
    end % rounds
    
end % block3/4

        
    %% End of experiment
    
    % End screen:
    Screen('TextSize', window, 30);
    Screen('TextStyle', window, 1);
    DrawFormattedText(window, 'Ende der Aufgabe.\n\n\nWeiter mit der Leertaste.', 'center', 'center', black);
    Screen('Flip', window);
    KbStrokeWait;
    
    % Exit the PTB environment
    ListenChar(0); % listen to the keyboard again
    ShowCursor; % show the cursor
    sca % close all screens, i.e. show the desktop again
    return;
    
catch lasterror % if something goes wrong between TRY and CATCH then the responsible error message is saved as lasterror
    
    % if an error occured between TRY and CATCH
    ListenChar(0); % listen to the keyboard again
    ShowCursor;    % show the cursor
    sca % close all screens, i.e. show the desktop/GUI again
    % rethrow(lasterror) % tell us what caused the error > do not use in GUI
    return;
    
end


%% Task Description [adapted from Kane et al, 2004; Foster et al, 2014]

% Complex Span Tests (CSTs) measure a dynamic working memory system that
% involves both the storage and processing of information, in contrast to
% simple span tasks, which measure a short-term memory capacity that
% involves storage only (like Digit Span and Corsi Blocks).
%
% In the Rotation Span Task,  modified from Shah and Miyake’s (1996) study,
% participants recall a sequence of short and long arrows radiating from
% the center of the screen pointing in one of eight different directions
% against a background letter-rotation task.
%
% Before beginning the real trials, participants perform three practice
% sections. The first practice is simple arrow span. Short and long arrows
% radiating from the center of the screen appear on the screen and
% participants are required to recall the arrows in the same order as they
% were presented. In all experimental conditions, arrows remain on-screen
% for 1s. At recall, participants see the 16 possible arrows that
% could have been presented. Recall consists of clicking the arrowhead of
% the arrows from the preceding displays, in the order they appeared (no
% verbal response is required). Participants have as much time as needed to
% recall the arrows. After recall, the computer provides feedback about the
% number of arrows correctly recalled in the current set.
%
% Next, participants performe the rotation portion of the task alone.
% Participants first see a normal or mirrorreversed G, F, or R
% (approximately 2 cm tall), rotated at 0°, 45°, 90°, 135°, 180°, 225°,
% 270°, or 315°. The task is to mentally rotate the letter, then indicate
% whether the letter is normal (“yes”) or mirror reversed (“no”); it is
% normal about half the time. The rotation practice serves to familiarise
% participants with the rotation portion of the task as well as to
% calculate how long it takes that person to solve the rotation operations.
% Thus, the rotation practice attempts to account for individual
% differences in the time required to solve rotations problems without an
% additional storage requirement. After the rotation alone section, the
% program calculates each individual’s mean time required to solve the
% rotation problems. This time (plus 2.5 standard deviations) is then used
% as the maximum time allowed for the rotation portion of the dual-task
% section for that individual.
%
% The final practice session has participants perform both the arrow recall
% and rotation portions together, just as they would do in the real block
% of trials. As before, participants first see the rotation problem and
% then click to advance to the normal or mirrorreversed judgment screen
% (yes/no). After they clicked the mouse button indicating their response,
% a blanked screen appears for 500 ms and then the TBR arrow is shown for
% 1s.  When the arrow disappeares, another letter or the recall cue appear.
% When presented with the recall cue, the participant recalls all of the
% arrows from the preceding displays, in the order they appeared. If a
% participant takes more time to solve the rotation problems than their
% average time plus 2.5 SD, the program automatically moves on and counts
% that trial as an error. Participants complete three practice trials each
% of set-size two. After participants completed all of the practice
% sessions, the program progresses to the real trials. The real trials
% consist of three trials of each set-size, with the set-sizes ranging from
% 2 to 5. This makes for a total of 42 arrows and 42 rotation problems.
% Note that the order of set-sizes is random for each participant. The
% score is the number of arrows correctly recalled in the correct position.
