function [] = OSpan(subjID)
%% Operation Span from Complex Span Test (Foster et al., 2014)
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
    
    fileID = fopen([logpath 'OSpan_' subjID '.txt'], 'w');
    fileIDtext = fopen([logpath 'OSpan_' subjID 'Text.txt'], 'w');


%% PTB Screen Preparation
  
    % Get the screen numbers
    screens = Screen('Screens');
    
    % Draw to the external screen if avaliable
    screenNumber = max(screens);
    % screenNumber = 1; % to test on Laptop!
    
    % Define colors
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    grey = 0.5;
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
    % Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
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
    
    % Duration of stimulus presentation in Memory Task
    memDuration = 1;  % 1000 ms
    
    % Duration of stimulus presentations or pauses (taken from E-prime script)
    
    % in block1 (memory practice):
    clearInstrB1 = 1;       % pause between last instruction page and first memory stimulus
    durMemoryB1 = 1;        % duration of a memory stimulus
    gapMemoryB1 = 0.25;     % pause between two memory stimuli
    clearForRecallB1 = 1;   % pause between last memory stimulus and recall screen
    durFeedbackB1 = 2;      % feedback duration; original was 1.5 s
    clearAfterSetB1 = 1;    % pause between feedback and new set / first instruction of next block
        
    % in block2 (processing practice):
    clearInstrB2 = 1;       % pause between last instruction page and first processing stimulus
    clearForTrialB2 = 0.5;  % pause before each processing stimulus / trial
    clearForRatingB2 = 0.2; % pause between processing stimulus and rating screen
    durFeedbackB2 = 1;    % feedback duration; original was 0.5 s
    
    % in block3/4 (both tasks):
    clearInstrB3 = 1;       % pause between last instruction page and first stimulus
    clearAfterRatingB3 = 0.2; % pause between (skipped) rating screen and next memory stimulus
    durMemoryB3 = 1;        % duration of a memory stimulus
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
    
    for i = 1:11
        % create a M x N x 3 matrix of the color image with integers between 0 and 255
        instr = imread(['Stimuli\OSpan_Stimuli\ospanInstruktion_S',num2str(i),'.jpg']);
        
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
    memoryPool = Shuffle(1:12);
    prac1MemorySet{1} = memoryPool(1:2);
    memoryPool = Shuffle(1:12);
    prac1MemorySet{2} = memoryPool(1:2);
    memoryPool = Shuffle(1:12);
    prac1MemorySet{3} = memoryPool(1:3);
    memoryPool = Shuffle(1:12);
    prac1MemorySet{4} = memoryPool(1:3);
    
    % create 3 sets of practice trials for block3  (3x2-set)
    memoryPool = Shuffle(1:12);
    prac2MemorySet{1} = memoryPool(1:2);
    memoryPool = Shuffle(1:12);
    prac2MemorySet{2} = memoryPool(1:2);
    memoryPool = Shuffle(1:12);
    prac2MemorySet{3} = memoryPool(1:2);
    
    % create 3 blocks of trials with one of each set sizes (3-7) randomly sampled within each block
    for i = 0:2  % for 3 blocks
        
        for setSize = 3:7
            memoryPool = Shuffle(1:12);
            memorySet{setSize} = memoryPool(1:setSize);
        end
        
        blockAdd = i*5;
        setPool = Shuffle(3:7);
        setPool = Shuffle(setPool);
        expMemorySet{1+blockAdd} = memorySet{setPool(1)};
        expMemorySet{2+blockAdd} = memorySet{setPool(2)};
        expMemorySet{3+blockAdd} = memorySet{setPool(3)};
        expMemorySet{4+blockAdd} = memorySet{setPool(4)};
        expMemorySet{5+blockAdd} = memorySet{setPool(5)};
        
    end
    
    
    %% Memory Task: Load Letter Images
    
    % get all memory images
    for memImg = 1:13
        
        % create a M x N x 3 matrix of the color image with integers between 0 and 255
        memImage = imread(['Stimuli\OSpan_Stimuli\Letter_',num2str(memImg),'.jpg']);
        
        % convert color matrix to floating point numbers between 0 and 1
        memImageMatrix{memImg} = double(memImage)/255;
        
        % transform image matrices into textures
        memImageTexture{memImg} = Screen('MakeTexture', window, memImageMatrix{memImg});
    end
    
    % set size and position for image display
    memImageRect = [0,0,60,60];
    memImagePosition = CenterRectOnPoint(memImageRect,xC,yC);

      
    %% Memory Task: Define Drawing Parameters (Squares & Buttons)
    
    % Size of small squares (100 x 100 pixels)
    RectX = screenYpixels*0.08;
    RectY = screenYpixels*0.07;
    baseRect = [0 0 RectX RectY];
    
    % Screen X/Y positions of small squares
    squareYpos = sort(repmat([screenYpixels*0.21 screenYpixels*0.35 screenYpixels*0.49 screenYpixels*0.63],[1 3]));
    squareXpos = repmat([screenXpixels*0.25 screenXpixels*0.5 screenXpixels*0.75],[1 4]);
    numSquares = length(squareXpos);
    
    % Center the rectangle on the centre of the screen
    allRects = nan(4, numSquares);
    for i = 1:numSquares
        allRects(:,i) = CenterRectOnPointd(baseRect, squareXpos(i), squareYpos(i));
    end
    allRects(:,13) = [-100 -100 -100 -100]; % for click on blank button
    
    % Define letter positions right to the squares
    allLetterRects = nan(4, numSquares);
    for i = 1:numSquares
        allLetterRects(:,i) = CenterRectOnPointd(memImageRect, squareXpos(i)+RectX, squareYpos(i));
    end
    
    % Define letter positions of selected letters below the squares
    widthLetters = memImageRect(3)/screenXpixels;
    loginXpos = [0.5-widthLetters*3 0.5-widthLetters*2 0.5-widthLetters*1 0.5 0.5+widthLetters*1 0.5+widthLetters*2 0.5+widthLetters*3];
    loginRects = nan(4, length(loginXpos));
    for i = 1:length(loginXpos)
        loginRects(:,i) = CenterRectOnPointd(memImageRect, screenXpixels*loginXpos(i), screenYpixels*0.85);
    end
    
    % Header
    headerSize = [0 0 screenXpixels*0.9 screenYpixels*0.16];
    headerRect = CenterRectOnPointd(headerSize, xC, screenYpixels*0.08);
    
    % Buttons
    buttonSizeBlank = [0 0 screenYpixels*0.18 RectY];
    buttonSizeClear = [0 0 screenYpixels*0.26 RectY];
    buttonTextSize = 28;
    Screen('TextSize', window, buttonTextSize);
    Screen('TextStyle', window, 1);
    
    blankRectXmid = xC;  % Blank button
    blankRectYmid = screenYpixels*0.76;
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

    
    %% Operation Task: Trial Parameter
    
    % get maths operations for practice (block 2)
    pracOperations = importdata('Stimuli\OSpan_Stimuli\pracOperations.mat');
        
    % get maths operations for experiment (block 3+4)
    opPart1 = importdata('Stimuli\OSpan_Stimuli\operationsPart1.mat');
    opPart2 = importdata('Stimuli\OSpan_Stimuli\operationsPart2.mat');
    
    % create vector for pseudorandomized correctness level of maths operations (block 3+4)
    correctnessLevels = Shuffle([zeros(40,1); ones(41,1)]);  % 1-6 for block3; 7-81 for block 4 (75 trials)
    
        
    %% Operation Task: Define Drawing Parameters (Buttons & Texts)
    
    % define screen position of maths operation
    opTextSize1 = 34;
    opTextStyle1 = 1;
    Screen('TextSize', window, opTextSize1);
    Screen('TextStyle', window, opTextStyle1);
    opTextXmid = xC;
    opTextYmid = yC;
    opTextRect = Screen('TextBounds', window, pracOperations{1});
    opTextX = opTextXmid - 0.5*opTextRect(3);
    opTextY = opTextYmid - 0.5*opTextRect(4);
    
    % define screen position of maths operation click instruction in block2
    opTextSize2 = 28;
    opTextStyle2 = 0;
    Screen('TextSize', window, opTextSize2);
    Screen('TextStyle', window, opTextStyle2);
    opText2a = 'Wenn Sie die Aufgabe gelöst haben,';
    opText2b = 'klicken Sie die Maus zum Fortfahren.';
    opText2Xmid = xC;
    opText2Ymid = screenYpixels*0.75;
    opText2aRect = Screen('TextBounds', window, opText2a);
    opText2bRect = Screen('TextBounds', window, opText2b);
    opText2aX = opText2Xmid - 0.5*opText2aRect(3);  % line 1
    opText2aY = opText2Ymid - 0.5*opText2aRect(4);
    opText2bX = opText2Xmid - 0.5*opText2bRect(3);  % line 2
    opText2bY = opText2Ymid + 0.75*opText2aRect(4);
    
%     % define screen position of maths operation click instruction in block3/4
%     opText3 = 'Klicken Sie die Maus zum Fortfahren.';
%     opText3Xmid = xC;
%     opText3Ymid = screenYpixels*0.75;
%     opText3Rect = Screen('TextBounds', window, opText3);
%     opText3X = opText3Xmid - 0.5*opText3Rect(3);
%     opText3Y = opText3Ymid - 0.5*opText3Rect(4);
    
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
        
        for instr = 1:3
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
            clicked=[];     % stores indices of clicked squares (1-12, rowwise; blank = 13)
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
                    if buttons(1)==1 && ~outside && ~ismember(ind(1),clicked)  && length(clicked)<length(currentMemorySet)
                        clicked(count) = ind(1);
                        count=count+1;
                    end
                    
                    % check if blank button was clicked
                    if buttons(1)==1 && blankB  && length(clicked)<length(currentMemorySet)
                        clicked(count) = 13;
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
                    
                    % Show click index where mouse click occured and show
                    % selected letter below the squares
                    if ~isempty(clicked)
                        % Screen('FillRect', window, red ,allRects(:,clicked));
                        Screen('TextSize', window, opTextSize1);
                        Screen('TextStyle', window, opTextStyle1);
                        for c = 1:count-1
                            temp = allRects(:,clicked(c));
                            tempX = temp(1)+(temp(3)-temp(1))/2;
                            tempY = temp(2)+(temp(4)-temp(2))/2;
                            currentTextRect = Screen('TextBounds', window, num2str(c));
                            Screen('DrawText', window, num2str(c) ,tempX-0.5*currentTextRect(3), tempY-0.5*currentTextRect(4), black);
                            if c <= length(loginXpos)
                                Screen('DrawTexture', window, memImageTexture{clicked(c)}, [], loginRects(:,c));
                            end
                        end
                    end
                    
                    % Draw rest of the squares on screen
                    Screen('FrameRect', window, blue ,allRects, 2);
                    
                    % Draw letters besides the squares on screen
                    for k=1:numSquares
                        Screen('DrawTexture',window, memImageTexture{k}, [], allLetterRects(:,k));
                    end
                    
                    % Draw buttons on screen
                    Screen('TextSize', window, buttonTextSize);
                    % Screen('TextStyle', window, 1); % bold text
                    
                    Screen('FrameRect', window, blue ,blankRect, 2);
                    Screen('DrawText', window, 'Blank' , blankTextX, blankTextY, black);
                    
                    Screen('FrameRect', window, black ,clearRect, 2);
                    Screen('DrawText', window, 'Clear' , clearTextX, clearTextY, black);
                    
                    Screen('FrameRect', window, black ,enterRect, 2);
                    Screen('DrawText', window, 'Enter' , enterTextX, enterTextY, black);
                    
                    % Draw header on screen
                    if smallScreen==1
                        Screen('TextSize', window, 20); %Laptop!
                    else
                        Screen('TextSize', window, 25);
                    end
                    Screen('TextStyle', window, 1);
                    DrawFormattedText(window, 'Wählen Sie die Buchstaben in der präsentierten Reihenfolge aus.\nBenutzen Sie den BLANK Knopf, um vergessene Buchstaben einzufügen.',...
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
            FBtext = ['Sie haben ',num2str(memScore),' von ',num2str(maxScore),' Buchstaben richtig erinnert!'];
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
        for instr = 4:7

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
        
        
        %% 2b | Operation Task: Practice
        
        ShowCursor('Arrow',screenNumber);
        
        % Maximum priority level
        topPriorityLevel = MaxPriority(window);
        Priority(topPriorityLevel);
        
        % Create matrix to score RT for operation practice
        nTrialsBlock2 = length(pracOperations);
        RTblock2 = nan(nTrialsBlock2,2);  % column1 = RT; column2 = correct answer?
        
        % Loop over practice trials
        for op = 1:nTrialsBlock2
            
            while any(buttons) % if already down, wait for release
                [~,~,buttons] = GetMouse;
            end
            
            HideCursor; % hide mouse cursor during operation stimulus presentation
            
            % show white screen before each processing stimulus / trial (like in E-prime)
            Screen('Flip',window);
            WaitSecs(clearForTrialB2 - slack); 
            
            % show processing stimulus
            currentPracOperation = pracOperations{op};
            Screen('TextSize', window, opTextSize1);
            Screen('TextStyle', window, opTextStyle1);
            Screen('DrawText', window, currentPracOperation, opTextX, opTextY, black);
            Screen('TextSize', window, opTextSize2);
            Screen('TextStyle', window, opTextStyle2);
            Screen('DrawText', window, opText2a, opText2aX, opText2aY, black);
            Screen('DrawText', window, opText2b, opText2bX, opText2bY, black);
            tOperationOn = Screen('Flip',window);
            
            while ~buttons(1) % wait for press
                
                [~,~,buttons] = GetMouse;
                
                [keyIsDown, tKeyPress, keyCode] = KbCheck;
                if keyIsDown && keyCode(escapeKey)
                    error('Abbruch des Experiments mit Escape');
                end
            end
            
            % Store RT for this trial
            RTblock2(op, 1) = GetSecs - tOperationOn; 
            
            while buttons(1); [~,~,buttons] = GetMouse; end % wait for release
            
            Screen('FillRect',window,white)
            tOperationOff = Screen('Flip',window);
            WaitSecs(clearForRatingB2 - slack);
            
            % rate maths operation of previous image
            
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
                    opAnswer=1;
                    break
                elseif buttons(1)==1 && noClick
                    opAnswer=0;
                    break
                end
                
                % check if esc key was pressed and abort experiment
                [keyIsDown, tKeyPress, keyCode] = KbCheck;
                if keyIsDown && keyCode(escapeKey)
                    error('Abbruch des Experiments mit Escape');
                end
                
                % Draw qestions and buttons on screen
                Screen('TextSize', window, opTextSize1);
                Screen('TextStyle', window, opTextStyle1);
                
                currentSolutionOffer = num2str(pracOperations{op,2});
                DrawFormattedText(window, currentSolutionOffer,...
                    'center',screenYpixels*0.33,black);
                
                Screen('TextSize', window, buttonTextSizeYN);
                Screen('TextStyle', window, 1);
                
                Screen('FrameRect', window, black ,yesRect, 4);
                Screen('DrawText', window, 'Richtig' ,yesTextX, yesTextY, black);
                
                Screen('FrameRect', window, black ,noRect, 4);
                Screen('DrawText', window, 'Falsch' ,noTextX, noTextY, black);
                
                % Flip to the screen
                tRatingOn = Screen('Flip', window,[],1); % don't clear for next flip (Feedback)
                
            end
            
            % get correctness level of current operation (1=correct; 0=incorrect)
            currentCorrectnessLevel = pracOperations{op,3};
            
            % present feedback in practice block on same screen
            if opAnswer == currentCorrectnessLevel
                opFeedback = 'Richtig';
                FBcolor = blue;
                RTblock2(op, 2) = 1;
            elseif opAnswer ~= currentCorrectnessLevel
                opFeedback = 'Falsch';
                FBcolor = red;
                RTblock2(op, 2) = 0;
            end
            
            DrawFormattedText(window, opFeedback,'center',yC*1.4,FBcolor);
            tFbOn = Screen('Flip',window); % not cleared before flip
            WaitSecs(durFeedbackB2 - slack);
            
            Screen('FillRect',window, white);
            Screen('Flip',window); % to get rid of 'don't clear' command from before
            
        end % operationTask trials
        
        % meanRT + 2.5 SD in this block (only from correctly answered trials)
        meanRTblock2 = mean(RTblock2(RTblock2(:,2)==1,1));
        sdRTblock2 = std(RTblock2(RTblock2(:,2)==1,1));
        opRTmax = meanRTblock2 + 2.5*sdRTblock2;
        if opRTmax < 1.5   % taken from E-prime script
            opRTmax = 1.5;
        end
    
        % Save data of block2 to logfile
        fprintf(fileIDtext, 'RTs for practice of maths operation task:\n');
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
            for instr = 8:10

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
            instr=11;
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
            WaitSecs(1 - slack);
            
        end
        
        
        %% 3/4b | Both Tasks: Stimulus Presentation
        
        % set maximal RT for operation judgments to RT+2.5SD from block2
        if exist('opRTmax')==0  % if no RT measured in block2
            opRTmax = 4.5;
        end
        
        if block3==1
            
            IsPractice = 1; % do not store responses
            
            % set memory trial parameters to practice trials
            MemorySet = prac2MemorySet;
            msMax = 3;
            
            % set operation trial parameters to practice trials
            nOpTrials = 6;
            opTrialCounter = 1;
            currentOpScore = 0; % set to zero before each block
            
        end
        
        if block4==1 && block3==0
            
            IsPractice = 0; % store responses
                    
            % save maximal RT for operation task in block3/4 to logfile
            fprintf(fileIDtext, ['\n\nMaximal RT for operation task: ', num2str(opRTmax)]);
            
            % set memory trial parameters to experimental trials
            MemorySet = expMemorySet;
            msMax = 15;
            
            % set operation trial parameters to experimental trials
            nOpTrials = 75;
            opTrialCounter = 7;
            currentOpScore = 0; % set to zero before each block
            
            % create response matrix to save trial parameters of block4
            RespMatrix = nan(nOpTrials,7);
            zeile=0; % current line of response matrix
            
            % columns: (1) set, (2) trial, (3) OpCorrect, (4) OpRT, (5)
            % OpAccuracy, (6) MemoryScore, (7) SetCorrect?

            % print header for response data of block4 in logfile
            fprintf(fileIDtext,'\n\nset\ttrial\tOpCorrect\tOpRT\tOpAccuracy\tMemoryScore\tSetCorrect\n');
        
        end
        
        % present memory and operation trials in alternation
        
        for ms = 1:msMax
   
            % get memory parameters for this trial
            currentMemorySet = MemorySet{ms};
                
            % set initial sum of operation errors in this set to 0
            opErrorsSet = 0;
            
            for mat = 1:length(currentMemorySet)
                
                HideCursor; % hide mouse cursor during memory stimulus presentation
                
                if IsPractice==0
                    zeile=zeile+1; % go to next line in response matrix
                end
                
                % create current maths operation and solution offer for this trial
                p1 = randi([1 48]);
                p2 = randi([1 18]);
                currentSumPart1 = opPart1{p1,2};
                currentSumPart2 = opPart2{p2,3};
                currentSolution = currentSumPart1 + currentSumPart2;
                
                % check that the sum is greater than 0, if it isn't keep adding 3 until
                % it is (adapted from E-prime script of OSpan)
                while currentSolution < 0
                    currentSumPart2 = currentSumPart2 + 3;
                    currentSolution = currentSumPart1 + currentSumPart2;
                end
                
                % set operator (+/-) for the current operation
                if currentSumPart2 < 0
                    currentOperator = '-';
                elseif currentSumPart2 >= 0
                    currentOperator = '+';
                end
                
                % create string version of current operation
                joinOperation = {opPart1{p1,1}, currentOperator, num2str(abs(currentSumPart2)), '= ?'};
                %currentOperationText = strjoin(joinOperation);
                currentOperationText = [opPart1{p1,1} ' ' currentOperator ' ' num2str(abs(currentSumPart2)) ' = ?'];
                
                % if the current correctness level is 0, present an incorrect answer by
                % adding a andom number, either positive or negative, and check that it
                % is greater 0 (adapted from E-prime script of OSpan)
                
                currentCorrectnessLevel = correctnessLevels(opTrialCounter);  % 0=incorrect solution offer; 1=correct solution offer
                if currentCorrectnessLevel==0
                    randFactor = randi([-9 9]);
                    while currentSolution+randFactor<0 || currentSolution+randFactor==currentSolution
                        randFactor = randFactor + 2;
                    end
                    currentSolutionOffer = num2str(currentSolution+randFactor);
                elseif currentCorrectnessLevel==1
                    currentSolutionOffer = num2str(currentSolution);
                end
            
                while any(buttons) % if already down, wait for release
                    [~,~,buttons] = GetMouse;
                end
                
                Screen('TextSize', window, opTextSize1);
                Screen('TextStyle', window, opTextStyle1);
                Screen('DrawText', window, currentOperationText, opTextX, opTextY, black);
                Screen('TextSize', window, opTextSize2);
                Screen('TextStyle', window, opTextStyle2);
                Screen('DrawText', window, opText2a, opText2aX, opText2aY, black);
                Screen('DrawText', window, opText2b, opText2bX, opText2bY, black);
                %Screen('DrawText', window, opText3, opText3X, opText3Y, black);
                tOperationOn = Screen('Flip',window);
                
                doOpRating = 0;  % don't go to rating if RT > opRTmax
                
                while GetSecs - tOperationOn <= opRTmax % individual response window

                    % Check for mouse clicks
                    [~,~,buttons] = GetMouse; 
                    if buttons(1)==1
                        doOpRating = 1;
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
                    opRTblock4 = GetSecs - tOperationOn;
                end
                
                while buttons(1); [~,~,buttons] = GetMouse; end % wait for release
                
                Screen('FillRect',window,white)
                tOperationOff = Screen('Flip',window);
                
                % rate correctness of previous operation
                
                % Set initial position of the mouse to be in the centre of the screen
                SetMouse(xC, yC, window); %!! does  not work for second screen!
                ShowCursor('Arrow',screenNumber); % show mouse cursor for rating
                
                % Maximum priority level
                topPriorityLevel = MaxPriority(window);
                Priority(topPriorityLevel);                
                
                if doOpRating==0
                    
                    opAnswer = 9; % no operation rating > counts as an error
                    
                elseif doOpRating==1
                    
                    [x,y,buttons] = GetMouse(window);
                    
                    while any(buttons) % if already down, wait for release
                        [x,y,buttons] = GetMouse;
                    end
                    
                    while 1 % while no key is pressed, loop does not break
                        
                        % Get the current position of the mouse
                        [x,y,buttons] = GetMouse(window);
                        
                        % Check on which button the mouse cursor is
                        yesClick = IsInRect(x,y, yesRect);
                        noB = IsInRect(x,y, noRect);
                        
                        % check which button was clicked
                        if buttons(1)==1 && yesClick
                            opAnswer=1;
                            break
                        elseif buttons(1)==1 && noB
                            opAnswer=0;
                            break
                        end
                        
                        % check if esc key was pressed and abort experiment
                        [keyIsDown, tKeyPress, keyCode] = KbCheck;
                        if keyIsDown && keyCode(escapeKey)
                            error('Abbruch des Experiments mit Escape');
                        end
                        
                        % Draw qestions and buttons on screen
                        Screen('TextSize', window, opTextSize1);
                        Screen('TextStyle', window, opTextStyle1);                        
                        
                        DrawFormattedText(window, currentSolutionOffer,...
                            'center',screenYpixels*0.33,black);
                        
                        Screen('TextSize', window, buttonTextSizeYN);
                        Screen('TextStyle', window, 1);

                        Screen('FrameRect', window, black ,yesRect, 4);
                        Screen('DrawText', window, 'Richtig' ,yesTextX, yesTextY, black);
                        
                        Screen('FrameRect', window, black ,noRect, 4);
                        Screen('DrawText', window, 'Falsch' ,noTextX, noTextY, black);
                        
                        % Flip to the screen
                        tRatingOn = Screen('Flip', window);
                        
                    end
                    
                end % symmRating
                
                HideCursor; % hide mouse cursor during memory stimulus presentation

                tRatingOff = Screen('Flip',window);
                WaitSecs(clearAfterRatingB3 - slack);
                
                % present current red square of this set
                Screen('DrawTexture',window, memImageTexture{currentMemorySet(mat)}, [], memImagePosition);
                tMemoryOn = Screen('Flip',window);
                
                Screen('FillRect',window,white)
                tMemoryOff = Screen('Flip',window, tMemoryOn + durMemoryB3 - slack);
                WaitSecs(clearMemoryB3 - slack);  
                
                %! get correctness level of current operation (1=correct; 0=incorrect)
                
                % get correctness score to present feedback after the
                % memory set (after the Recall Screen)
                if opAnswer == currentCorrectnessLevel
                    opTrialCorrect = 1;    % correct answer
                    currentOpScore = currentOpScore+1;
                elseif opAnswer ~= currentCorrectnessLevel
                    if opAnswer ~= 9
                        opTrialCorrect = 0; % accuracy error
                    elseif opAnswer == 9   
                        opTrialCorrect = 9; % speed error
                    end
                    currentOpScore = currentOpScore+0;
                    opErrorsSet = opErrorsSet + 1;
                end                
                
                % calculate overall accuracy for operation trials of this block
                
                if IsPractice==1
                    opAccuracy = currentOpScore/opTrialCounter*100;
                elseif IsPractice==0
                    opAccuracy = currentOpScore/(opTrialCounter-6)*100;
                end
                opTrialCounter = opTrialCounter + 1;  % increase by 1 for next trial (!think of practice trials - start counter here with 7)
            
                % save parameters of this trial in response matrix
                if IsPractice==0
                    RespMatrix(zeile,1) = ms;
                    RespMatrix(zeile,2) = mat;
                    RespMatrix(zeile,3) = opTrialCorrect;
                    RespMatrix(zeile,4) = opRTblock4;
                    
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
            clicked=[];     % stores indices of clicked squares (1-12, rowwise; blank = 13)
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
                    if buttons(1)==1 && ~outside && ~ismember(ind(1),clicked)  && length(clicked)<length(currentMemorySet)
                        clicked(count) = ind(1);
                        count=count+1;
                    end
                    
                    % check if blank button was clicked
                    if buttons(1)==1 && blankB  && length(clicked)<length(currentMemorySet)
                        clicked(count) = 13;
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
                    
                    % Show click index where mouse click occured and show
                    % selected letter below the squares
                    if ~isempty(clicked)
                        % Screen('FillRect', window, red ,allRects(:,clicked));
                        Screen('TextSize', window, opTextSize1);
                        Screen('TextStyle', window, opTextStyle1);
                        for c = 1:count-1
                            temp = allRects(:,clicked(c));
                            tempX = temp(1)+(temp(3)-temp(1))/2;
                            tempY = temp(2)+(temp(4)-temp(2))/2;
                            currentTextRect = Screen('TextBounds', window, num2str(c));
                            Screen('DrawText', window, num2str(c) ,tempX-0.5*currentTextRect(3), tempY-0.5*currentTextRect(4), black);
                            if c <= length(loginXpos)
                                Screen('DrawTexture', window, memImageTexture{clicked(c)}, [], loginRects(:,c));
                            end
                        end
                    end
                    
                    % Draw rest of the squares on screen
                    Screen('FrameRect', window, blue ,allRects, 2);
                    
                    % Draw letters besides the squares on screen
                    for k=1:numSquares
                        Screen('DrawTexture',window, memImageTexture{k}, [], allLetterRects(:,k));
                    end
                    
                    % Draw buttons on screen
                    Screen('TextSize', window, buttonTextSize);
                    Screen('TextStyle', window, 1); % bold text
                    
                    Screen('FrameRect', window, blue ,blankRect, 2);
                    Screen('DrawText', window, 'Blank' , blankTextX, blankTextY, black);
                    
                    Screen('FrameRect', window, black ,clearRect, 2);
                    Screen('DrawText', window, 'Clear' , clearTextX, clearTextY, black);
                    
                    Screen('FrameRect', window, black ,enterRect, 2);
                    Screen('DrawText', window, 'Enter' , enterTextX, enterTextY, black);
                    
                    % Draw header on screen
                    if smallScreen==1
                        Screen('TextSize', window, 20); %Laptop!
                    else
                        Screen('TextSize', window, 25);
                    end
                    Screen('TextStyle', window, 1);
                    DrawFormattedText(window, 'Benutzen Sie den BLANK Knopf, um vergessene Buchstaben zu überspringen.',...
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
            opAccuracyStr = [num2str(sprintf('%.0f', opAccuracy)),' %'];
            FBtext = ['Sie haben ',num2str(memScore),' von ',num2str(maxScore),' Buchstaben richtig erinnert!',...
                '\n\n\n\nSie haben ', num2str(opErrorsSet), ' Rechen-Fehler in diesem Durchgang gemacht.'];
            if smallScreen==1
                Screen('TextSize', window, 22); %Laptop!
            else
                Screen('TextSize', window, 30);
            end
            Screen('TextStyle', window, 1);
            DrawFormattedText(window, FBtext,'center','center',black);
            Screen('DrawText', window, opAccuracyStr, screenXpixels*0.9, screenYpixels*0.05, red);

            tFbOn = Screen('Flip', window);
            WaitSecs(durFeedbackB3 - slack);  
            
            FbOff = Screen('Flip',window);
            WaitSecs(clearAfterSetB3 - slack);
       
            % save parameters of this set in response matrix
            if IsPractice==0
                RespMatrix(zeile,5) = opAccuracy;
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
       rotAccErrors = sum(RespMatrix(:,3)==0); % total accuracy errors in operation task
       rotSpeedErrors = sum(RespMatrix(:,3)==9); % total speed errors in operation task
       rotTotalErrors = rotAccErrors + rotSpeedErrors; % total errors in operation task
       
       fprintf(fileIDtext, ['\n\nFinal accuracy level (%%) in operation task: ', opAccuracyStr]);
       fprintf(fileIDtext, ['\nTotal processing errors in operation task: ', num2str(rotTotalErrors)]);
       fprintf(fileIDtext, ['\n\t- Total accuracy errors: ', num2str(rotAccErrors)]);
       fprintf(fileIDtext, ['\n\t- Total speed errors: ', num2str(rotSpeedErrors)]);
       
       RespMatrix(isnan(RespMatrix(:,6)),6) = 0;
       RespMatrix(isnan(RespMatrix(:,7)),7) = 0;
       absMemScore = sum(RespMatrix(:,6));
       partMemScore = sum(RespMatrix(:,6).*RespMatrix(:,7));
       
       fprintf(fileIDtext, ['\n\nAbsolute score (all correct trials) in memory task: ', num2str(absMemScore)]);
       fprintf(fileIDtext, ['\nPartial score (trials in correct sets) in memory task: ', num2str(partMemScore)]);
       
       % save correctness levels of operation solution offers (just in case)
       fprintf(fileIDtext, '\n\nCorrectness of operation solution offers for block 3 (1-6) and block 4 (7-81):\n[0:incorrect; 1=correct]\n');
       fprintf(fileIDtext, '%d\n', correctnessLevels);
       
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
    %rethrow(lasterror) % tell us what caused the error > do not use in GUI
    return;
    
end


%% Task Description [adapted from Unsworth et al, 2009; Redick et al, 2012]

% Complex Span Tests (CSTs) measure a dynamic working memory system that
% involves both the storage and processing of information, in contrast to
% simple span tasks, which measure a short-term memory capacity that
% involves storage only (like Digit Span and Corsi Blocks).
%
% In the Operation Span Task participants are required to solve a series of
% maths operations while trying to remember a set of unrelated letters (F,
% H, J, K, L, N, P, Q, R, S, T, Y). Before beginning the real trials,
% participants perform three practice sections. The first practice is
% simple letter span. A letter appeares on the screen and participants are
% required to recall the letters in the same order as they were presented.
% In all experimental conditions, letters remain on-screen for 1000 ms. At
% recall, participants see a 4x3 matrix of letters. Recall consists of
% clicking the box next to the appropriate letters (no verbal response is
% required) in the correct order. Participants have as much time as needed
% to recall the letters. After recall, the computer provides feedback about
% the number of letters correctly recalled in current set. 
% Next, participants performe the maths portion of the task alone.
% Participants first see a math operation [e.g. (1*2)1 =?]. Participants
% are instructed to solve the operation as quickly as possible and then
% click the mouse to advance to the next screen. On the next screen a digit
% (e.g., ‘‘3’’) is presented and the participant is required to click
% either a ‘‘True’’ or ‘‘False’’ box to indicate the answer. After each
% operation participants are given accuracy feedback. The math practice
% serves to familiarise participants with the maths portion of the task as
% well as to calculate how long it takes that person to solve the maths
% operations. Thus, the maths practice attempts to account for individual
% differences in the time required to solve maths operations without an
% additional storage requirement. After the maths alone section, the
% program calculates each individual’s mean time required to solve the
% equations. This time (plus 2.5 standard deviations) is then used as the
% maximum time allowed for the maths portion of the dual-task section for
% that individual.
% The final practice session has participants perform both the letter
% recall and maths portions together, just as they would do in the real
% block of trials. As before, participants first see the maths operation
% and then click to advance to the comparison (True/False) screen. After
% they clicked the mouse button indicating that the response, the TBR
% letter is shown. If a participant takes more time to solve the operations
% than their average time plus 2.5 SD, the program automatically moves on
% and counts that trial as an error. Participants complete three practice
% trials each of set-size two. After participants completed all of the
% practice sessions, the program progresses to the real trials. The real
% trials consist of three trials of each set-size, with the set-sizes
% ranging from three to seven. This makes for a total of 75 letters and 75
% maths problems.
% Note that the order of set-sizes is random for each participant. The
% score is the number of correct items recalled in the correct position.
