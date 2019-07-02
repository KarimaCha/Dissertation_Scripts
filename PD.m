function [] = PD(subjID)
%% Probability Discounting Task
% (code written by Karima Chakroun, version: 21.01.2016, deutsch)



try
    %% Cleaning up
    
    % close all;
    % clear all;
    % sca;
    
    %% Prepare computer for PTB usage
    
    % call some default settings for setting up Psychtoolbox
    PsychDefaultSetup(2);
    
    % seed the random number generator
    rand('seed', sum(100 * clock));  %rng('shuffle')
    
    % skip SyncTests to avoid error messages due to non-optimal timing
    sca;  % close all open screens (short for Screen('CloseAll'))
    Screen('Preference', 'SkipSyncTests', 1);
    
    
    %% Enter Subject ID and session and create logfile
    
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
    
    fileID = fopen([logpath 'PD_' subjID '.txt'], 'w');
    fprintf(fileID, 'block\tblockProbab\tTrial\tUB\tLB\tSA\tresponse\tRT\trespSide\tsideSA\n');
    
    
    %% PTB Screen Preparation
    
    % Get the screen numbers
    screens = Screen('Screens');
    
    % Draw to the external screen if avaliable
    screenNumber = max(screens);
    % screenNumber = 0; % to test on Laptop!
    
    % Define colors
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    
    % Open an on screen window
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
    
    % Get the centre coordinate of the window
    [xC, yC] = RectCenter(windowRect);
    
    % Get the size of the on screen window in pixels
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    if screenXpixels > 1500
        smallScreen = 0;
    elseif screenXpixels <= 1500
        smallScreen = 1;  % to adjust some layout parameters
    end
    
    % Set the blend funciton for the screen
    % Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    % prevents keys you pressed during the experiment to show up in Matlab
    ListenChar(2);
    
    % hide the mouse cursor
    HideCursor;
    
    
    %% Timing Information
    
    % Query  frame duration (minimum possible time for drawing to the screen)
    ifi = Screen('GetFlipInterval', window);
    slack = ifi/2; % can be used later for more accurate timing
    
    % Present waiting screen until all images are loaded (see code below)
    Screen('TextSize', window, 40);
    Screen('TextStyle', window, 1);
    DrawFormattedText(window, 'Bitte warten...','center', 'center', white);
    tStartExp = Screen('Flip', window);
    
    % Set maximum and minimum for inter trial interval (iti)
    iti_min = 0.5;  % in sec
    iti_max = 1.5;  % in sec

    
    %% Key / Response information
    
    % Define the keyboard keys that are listened for. We will be using the left
    % and right arrow keys as response keys for the task, the space key to start/resume experiment and the escape key as
    % an exit/reset key
    % KbName('KeyNames') > shows all keynames
    spaceKey = KbName('space');
    escapeKey = KbName('ESCAPE');
    leftKey = KbName('LeftArrow');
    rightKey = KbName('RightArrow');
    
    
    %% Load Instruction Images
    
    for i = 1:1
        % create a M x N x 3 matrix of the color image with integers between 0 and 255
        instr = imread(['Stimuli\PD_Stimuli\PD_Instruktion_S',num2str(i),'.jpg']);
        
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
    
    
    %%  Text Position & Squares
    
    % Make rectangles for the 2 options (text and response frames) and set text size
    textRect = [0 0 700 600];  % for text position of both options
    if smallScreen==1
        frameRect = [0 0 425 275]; % for framing the chosen option %! Laptop
        textSizeOpt = 40;
    else
        frameRect = [0 0 550 350]; % for framing the chosen option
        textSizeOpt = 50;
    end
    
    % Screen X positions of text rectangles
    squareXpos = [windowRect(3) * 0.275, windowRect(3) * 0.725];
    
    % Calculate rectangle coordinates
    RectL = CenterRectOnPointd(textRect, squareXpos(1), yC);
    RectR = CenterRectOnPointd(textRect, squareXpos(2), yC);
    frameRectL = CenterRectOnPointd(frameRect, squareXpos(1), yC);
    frameRectR = CenterRectOnPointd(frameRect, squareXpos(2), yC);
    
    % Pen width for the frames
    penWidthPixels = 5;
    
    
    %%  Trial Parameter
    
    % Define conditions, their levels and number of repeats and create
    % a condition-Matrix (without repeats) and a trial-Matrix (with repeats) out of this
    probab = [0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95];  % probabilities
    numTrials = 6;              % number of trials per block of binary search
    numBlocks = numel(probab);  % number of blocks (probabilities)
    
    % randomize block indices
    blockShuffle = Shuffle(1:numBlocks);
    
    % pseudorandomized side vector (sure amount displayed on which side)
    sidesSA = [ones(numTrials*numBlocks/2,1); ones(numTrials*numBlocks/2,1)*2];
    sidesSA = Shuffle(sidesSA); % sides of SA: 1 = left; 2 = right
    
    % Trial index for short break (before this trial starts)
    pause = -10; % set to negative value if no pause is needed
    
    % Make a matrix to record the response for each trial
    % RespMatrix = nan(5,numTrials);
    RespMatrix = nan(numTrials*numBlocks,10);
    
    
    %% Instruction Screen
    
    while KbCheck; end % wait for key to be released
    
    Screen('DrawTexture', window, instrTexture{1}, [], instrImagePosition);
    Screen('Flip',window);
    
    while 1
        [keyisdown, tPress, keyCode] = KbCheck;
        
        if keyCode(spaceKey)
            break
        elseif keyCode(escapeKey)
            error('Abbruch des Experiments mit Escape');
        end
        
    end
    
    
    %% Experimental loop
    
    % Block loop: we loop for the total number of blocks
    for block = 1:numBlocks
        
        % (Re)set the initial upper and lower bounds for the sure amount (SA)
        % and the gamble amount (GA) at the beginning of each block:
        LB = 0;  % Lower Bound of SA in Euros
        UB = 20; % Upper Bound of SA in Euros
        GA = 20; % Gamble Amount (GA) in Euros
        
        % Get the probability for this block from the shuffled probabilities
        blockProbab = probab(blockShuffle(block));
        
        % Trial loop: we loop for the total number of trials
        for trial = 1:numTrials
            
            % set counter for this trial
            counter = trial + (block-1)*numTrials;
            
            % Pause screen 
            if counter==pause
                
                Screen('TextSize', window, 40);
                Screen('TextStyle', window, 0);
                DrawFormattedText(window, 'Kurze Pause.\n\n\nWeiter mit der Leertaste.', 'center', 'center', white);
                Screen('Flip', window);
                
                while 1; [keyisdown, tPress, keyCode] = KbCheck;
                    if keyCode(spaceKey)
                        break
                    elseif keyCode(escapeKey)
                        error('Abbruch des Experiments mit Escape');
                    end
                end

            end
            
            % set random inter trial interval (iti) in seconds
            iti_time = rand * (iti_max - iti_min) + iti_min;
            
            % display fixation cross on screen
            Screen('TextSize', window, 70);
            Screen('TextStyle', window, 0);
            DrawFormattedText(window, '+', 'center', 'center', white);
            tFixOn = Screen('Flip',window);
            tFixOff = Screen('Flip', window, tFixOn + iti_time - slack);
            
            % Option 1 = set the SA (sure amount) for this trial 
            SA = LB + (UB-LB)/2;
            
            if mod(SA,1) < 0.001  % integer (dont say ==0 because of Matlab issues)
                sureOpt = [num2str(SA) ' Euro\n\n100%'];  % show without decimal places
            elseif mod (SA,1)~=0  % not integer > show 2 decimal places
                %sureOpt = [num2str(round(SA*100)/100) ' Euro\n\n100 %']; % round to 2 decimal places
                sureOpt = [num2str(SA,'%0.2f') ' Euro\n\n100%']; % round to 2 decimal places
            end
            
            % Option 2 = GA (gambling amount) for this trial
            riskyOpt = [num2str(GA) ' Euro\n\n' ...  %,'%0.2f'
                num2str(blockProbab*100) '%'];
            
            Options = {sureOpt; riskyOpt};
            sideSA = sidesSA(counter); % current side of SA: 1 = left; 2 = right
            
            % Now we draw the choice options on screen
            Screen('TextSize', window, textSizeOpt);
            Screen('TextStyle', window, 0);
            DrawFormattedText(window, Options{sideSA},'center','center',...
                white,[],[],[],1.1,[],RectL);
            DrawFormattedText(window, Options{3-sideSA},'center','center',...  % 3-1=2; 3-2=1;
                white,[],[],[],1.1,[],RectR);
            
            % start here to count RT for this trial and don't clear screen for next flip (frames highlight chosen option)
            tChoiceOn = Screen('Flip', window, [], 1);
            
            % Now we wait for a keyboard button signaling the observers response.
            respToBeMade = true;
            
            while KbCheck; end % wait for key to be released
            
            while respToBeMade  % wait for response
                [keyIsDown, tPress, keyCode] = KbCheck;
                
                if keyCode(leftKey)
                    
                    if sideSA==1            % Option 1 (sure) on left side
                        response = 0;       % 0 = sure amount
                    elseif sideSA==2        % Option 2 (gamble) on left side
                        response = 1;       % 1 = gamble
                    end
                    respSide = 1;           % 1=left
                    respToBeMade = false;
                    
                elseif keyCode(rightKey)
                    
                    if sideSA==1            % Option 2 (gamble) on right side
                        response = 1;       % 1 = gamble
                    elseif sideSA==2        % Option 1 (sure) on right side
                        response = 0;       % 0 = sure amount
                    end
                    respSide = 2;           % 2=right
                    respToBeMade = false;
                    
                elseif keyCode(escapeKey)
                    error('Abbruch des Experiments mit Escape');
                end
                
            end
            
            % Flip to the screen with a rectangle highlighting the chosen option
            if keyCode(leftKey)
                Screen('FrameRect', window, white, frameRectL', penWidthPixels);
            elseif keyCode(rightKey)
                Screen('FrameRect', window, white, frameRectR', penWidthPixels);
            end
            Screen('Flip', window);
            WaitSecs(1 - slack);
            
            % Store trial parameter in response matrix and logfile
            RT = tPress-tChoiceOn;
            RespMatrix(trial+numTrials*(block-1),:) = [block,blockProbab,trial,UB,LB,SA,response,RT,respSide,sideSA];
            
            fprintf(fileID, '%d\t %1.2f\t %d\t %1.4f\t %1.4f\t %1.4f\t %d\t %1.4f\t %d\t %d\n',  RespMatrix(trial+numTrials*(block-1),:)');
            
            % set new SA (sure amount) for next trial depending on choice in this trial
            if response == 0
                UB = SA;
            elseif response == 1
                LB = SA;
            end
            
        end % trial loop
        
    end % block loop
    
    
    %% End of experiment
    
    % End screen
    Screen('TextSize', window, 40);
    Screen('TextStyle', window, 0);
    DrawFormattedText(window, 'Ende der Aufgabe.\n\n\nWeiter mit der Leertaste.', 'center', 'center', white);
    Screen('Flip', window);
    KbStrokeWait;
    
    % Exit the PTB environment
    ListenChar(0); % listen to the keyboard again
    ShowCursor; % show the cursor
    sca; % close all screens, i.e. show the desktop again
    return;
    
catch lasterror % if something goes wrong between TRY and CATCH then the responsible error message is saved as lasterror
    
    % if an error occured between TRY and CATCH
    ListenChar(0); % listen to the keyboard again
    ShowCursor;    % show the cursor
    sca; % close all screens, i.e. show the desktop/GUI again
    % rethrow(lasterror) % tell us what caused the error > do not use in GUI
    return;
    
end


%% Task Description
