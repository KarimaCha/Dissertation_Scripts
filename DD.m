function [] = DD(subjID)
%% Delay Discounting Task
% (code written by Karima Chakroun, version: 21.01.2016, deutsch)


try
    %% Cleaning up
    % clear all;  % clear workspace
    % close all;  % close open figures
    % sca;        % short for Screen('CloseAll')
    
    
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
    
    fileID = fopen([logpath 'DD_' subjID '.txt'], 'w');
    fprintf(fileID,'trial\tval_basic\tdelay\tval_prc\tresponse\tRT\trespSide\tsideNOW\n');
    
    %% PTB Screen Preparation
    
    % Get the screen numbers
    screens = Screen('Screens');
    
    % Draw to the external screen if avaliable
    screenNumber = max(screens);
    % screenNumber = 0; % to show on laptop screen
    
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
    
    % Set the blend funciton for the screen (allows transparency)
    % Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    % prevents keys you pressed during the experiment to show up in Matlab
    ListenChar(2);
    
    % hide the mouse cursor
    HideCursor;
    
    
    %% Timing Information
    
    % Query  frame duration (minimum possible time for drawing to the screen)
    ifi = Screen('GetFlipInterval', window);
    slack = ifi/2; % can be used later for more acurate timing
        
    % Present waiting screen until all images are loaded (see code below)
    Screen('TextSize', window, 40);
    Screen('TextStyle', window, 1);
    DrawFormattedText(window, 'Bitte warten...','center', 'center', white);
    tStartExp = Screen('Flip', window);
    
    % Set maximum and minimum for inter trial interval (iti)
    iti_min = 0.5;  % in sec
    iti_max = 1.0;  % in sec
 
    
    %% Key / Response information
    
    % Define the keyboard keys that are used in this experiment
    % KbName('KeyNames') > shows all keynames
    leftKey = KbName('LeftArrow');      % choice left side
    rightKey = KbName('RightArrow');    % choice right side
    escapeKey = KbName('ESCAPE');       % exit experiment
    %pauseKey = KbName('p');             % pause experiment
    spaceKey = KbName('space');         % start experiment
    
    
    %% Load Instruction Images
    
    for i = 1:1
        % create a M x N x 3 matrix of the color image with integers between 0 and 255
        instr = imread(['Stimuli\DD_Stimuli\DD_Instruktion_S',num2str(i),'.jpg']);
        
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
    
    % Set the text size
    textRect = [0 0 800 800];  % for text position of both options
    if smallScreen==1
        frameRect = [0 0 425 275]; % for framing the chosen option %! Laptop
        textSizeOpt = 40;
    else
        frameRect = [0 0 600 400]; % for framing the chosen option
        textSizeOpt = 50;
    end
    
    % Screen X positions of the two choice rectangles
    squareXpos = [windowRect(3) * 0.275, windowRect(3) * 0.725];
    
    % Calculate rectangle coordinates
    RectL = CenterRectOnPointd(textRect, squareXpos(1), yC);
    RectR = CenterRectOnPointd(textRect, squareXpos(2), yC);
    frameRectL = CenterRectOnPointd(frameRect, squareXpos(1), yC);
    frameRectR = CenterRectOnPointd(frameRect, squareXpos(2), yC);
    
    % Pen width for the frames
    penWidthPixels = 5;
    
    
    %% Trial Parameter
    
    % Define conditions, their levels and number of repeats and create
    % a condition-Matrix (without repeats) and a trial-Matrix (with repeats) ouf of this
    delays = [1 3 5 8 14 30 60]; % delays in days
    Ndelays = numel(delays);
    
    val_prc = [1.01 1.02 1.05 1.1 1.2 1.5 1.8 2 2.5 3 4 5 7 10 13]; % values in percent of basic value
    Nval_prc = numel(val_prc);
    
    val_basic = 20;   % basic values
    Nval_basic = numel(val_basic);
    
    numRepeats = 1;         % repeats per condition
    numCond = Ndelays*Nval_prc*Nval_basic;  % calculate the number of conditions
    numTrials = numCond*numRepeats;         % calculate the number of trials
    pause1 = 53;    % trial index for short break(s) in the experiment [paused BEFORE this trial]
    pause2 = -1;  % put negative value if no second break is needed [paused BEFORE this trial]
    
    val_basic_ = sort(repmat(val_basic,1,Ndelays*Nval_prc))';
    delays_ = repmat(sort(repmat(delays,1,Nval_prc)),1,Nval_basic)';
    val_prc_ = repmat(val_prc,1,Nval_basic*Ndelays)';
    
    condMatrix = [val_basic_ , delays_ , val_prc_ ];
    trialMatrix=repmat(condMatrix, numRepeats, 1);
    
    % randomize trial indices
    indexShuffle=Shuffle(1:numTrials);
    
    % pseudorandomized side vector (NOW-option displayed on which side)
    sidesNOW = [ones(round(numTrials/2),1); ones(numTrials-round(numTrials/2),1)*2];
    sidesNOW = Shuffle(sidesNOW); % sides of SA: 1 = left; 2 = right
    
    % Make a matrix to record the response for each trial
    RespMatrix = nan(numTrials,8);
    % columns:  (1) trial, (2-4) currentCond, (5) response, (6) RT, (7)
    % response side, (8) side NOW option

 
    %% Instruction Screen
    
    while KbCheck; end % wait for key to be released
    
    Screen('DrawTexture', window, instrTexture{1}, [], instrImagePosition);
    Screen('Flip',window);
    
    while 1
        [keyisdown, secs, keyCode] = KbCheck;
        
        if keyCode(spaceKey)
            break
        elseif keyCode(escapeKey)
            error('Abbruch des Experiments mit Escape');
        end
        
    end
    
    
    %% Experimental loop |1| Fixation cross and iti
    
    % Trial loop: we loop for the total number of trials
    for trial = 1:numTrials
        
        while KbCheck; end  % wait for key to be released
        
        % Get the condition for this trial
        currentCond = trialMatrix(indexShuffle(trial),:);
        
        % Small break after a certain number of trials
        if trial==pause1 || trial==pause2
            Screen('TextSize', window, 40);
            Screen('TextStyle', window, 0);
            DrawFormattedText(window, 'Kurze Pause.\n\n\nWeiter mit der Leertaste.', 'center', 'center', white);
            Screen('Flip', window);
            
            while 1; [keyisdown, secs, keyCode] = KbCheck;
                if keyCode(spaceKey)
                    break
                elseif keyCode(escapeKey)
                    error('Abbruch des Experiments mit Escape');
                end
            end
        end
        
        % set random inter trial interval (iti) in seconds
        iti_time = rand * (iti_max - iti_min) + iti_min; % iti_time between iti_max and iti_min
        
        % display fixation cross on screen
        Screen('TextSize', window, 70);
        Screen('TextStyle', window, 0);
        DrawFormattedText(window, '+', 'center', 'center', white);
        tFixOn = Screen('Flip',window);
        tFixOff = Screen('Flip', window, tFixOn + iti_time - slack);
        
        
        %% Experimental loop |2| Present choice options
        
        % create the two choice options for this condition and randomize
        % side of display
        if currentCond(2)==1
            tag = ' Tag';
        elseif currentCond(2)~=1
            tag = ' Tage';
        end
        
%         if mod(SA,1)==0  % integer
%             sureOpt = [num2str(SA) ' Euro\n\n100 %'];  % show without decimal places
%         elseif mod (SA,1)~=0  % not integer
%             sureOpt = [num2str(round(SA*100)/100) ' Euro\n\n100 %']; % round to 2 decimal places
%         end
        
        OptNow = [num2str(currentCond(1)) ' Euro\n\njetzt'];    
        if mod(currentCond(1)*currentCond(3),1) < 0.001     % integer (dont say ==0 because of Matlab issues)           
            OptLater = [num2str(currentCond(1)*currentCond(3)) ' Euro\n\n' ...
                num2str(currentCond(2)) tag];
        else                                                % not integer > show 2 decimal places
            OptLater = [num2str(currentCond(1)*currentCond(3),'%0.2f') ' Euro\n\n' ...
                num2str(currentCond(2)) tag];
        end
        
        Options = {OptNow; OptLater};
        sideNOW = sidesNOW(trial); % current side of NOW-option: 1 = left; 2 = right
        
        % Draw the choice options
        Screen('TextSize', window, textSizeOpt);
        Screen('TextStyle', window, 0);
        DrawFormattedText(window, Options{sideNOW},'center','center',...
            white,[],[],[],1.1,[],RectL);
        DrawFormattedText(window, Options{3-sideNOW},'center','center',...
            white,[],[],[],1.1,[],RectR); % 3-1=2; 3-2=1;
        
        % Flip to the screen
        tChoiceOn = Screen('Flip', window, [], 1); % don't clear with next flip (to draw border)
        
        
        %% Experimental loop |3| Get response
        
        while 1
            
            % Check the keyboard for key presses
            [keyIsDown, tPress, keyCode] = KbCheck;
            
            if keyCode(leftKey)
                
                if sideNOW==1        % Option 1 (now) on left side
                    response = 0;    % 0 = now
                elseif sideNOW==2    % Option 2 (delayed) on left side
                    response = 1;    % 1 = later
                end
                
                respSide = 1;        % 1=left
                break
                
            elseif keyCode(rightKey)
                
                if sideNOW==1        % Option 2 (delayed) on right side
                    response = 1;    % 1 = later
                elseif sideNOW==2    % Option 1 (now) on right side
                    response = 0;    % 0 = now
                end
                
                respSide = 2;        % 2=right
                break
                
            elseif keyCode(escapeKey)
                error('Abbruch des Experiments mit Escape');
                
%             elseif keyCode(pauseKey) % pause experiment
%                 
%                 % Present a break screen until subject presses key to move on
%                 DrawFormattedText(window, 'Experiment unterbrochen...\n\nWeiter per Knopfdruck!','center', 'center', white);
%                 Screen('Flip', window);
%                 
%                 while KbCheck; end % wait for key to be released
%                 KbStrokeWait;  % resume with any key
%                 break; % abort current trial after pause
                
            end
            
        end
        
        % Show the chosen option with border around it for 1 sec
        if keyCode(leftKey)
            Screen('FrameRect', window, white, frameRectL', penWidthPixels);
        elseif keyCode(rightKey)
            Screen('FrameRect', window, white, frameRectR', penWidthPixels);
        end
        
        Screen('Flip', window);
        WaitSecs(1 - slack);
        
        
        %% Save response parameter to txt-file at the end of each trial
        
        % Record the response and save current trial parameters to logfile
        RT = tPress - tChoiceOn;
        RespMatrix(trial,:) = [trial,currentCond,response,RT,respSide,sideNOW];
        fprintf(fileID, '%d\t %d\t %d\t %1.2f\t %d\t %1.4f\t %d\t %d\n', RespMatrix(trial,:)');
        
        
    end % trial loop
    
    
    %% End of experiment
    
    % End screen:
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