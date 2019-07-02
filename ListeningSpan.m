function [] = ListeningSpan(subjID, volume)
%% Listening Span Test, adapted from van den Noort et al., 2008.
% (code written by Karima Chakroun, version: 21.01.2016, deutsch)
% [see bottom lines for task description]


try
    if nargin < 2
        volume=1;   % default = maximum volume; values >1 reduce volume
    end
    
    if nargin < 1   % enter Subject ID
        
        subjID = [];
        while isempty(subjID)
            subjID = inputdlg('Bitte die Subject ID eingeben:');
            subjID = subjID{1};
        end
        
    end
    
%% Prepare computer for PTB usage

% call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% seed the random number generator
rand('seed', sum(100 * clock));  %rng('shuffle')

% skip SyncTests to avoid error messages due to non-optimal timing
sca;  % close all open screens (short for Screen('CloseAll'))
Screen('Preference', 'SkipSyncTests', 1);


%% Load audio stimuli

% load audio files
[y, Fs] = wavread('Stimuli/ListeningSpan_Stimuli/audio/1.wav'); % to get Fs
nStimuli = 105;

for aud = 1:nStimuli
	audio{aud} = wavread(['Stimuli/ListeningSpan_Stimuli/audio/' num2str(aud) '.wav']);
end

Noort_temp = importdata('Stimuli/ListeningSpan_Stimuli/Noort_Matrix_series.mat'); 
Noort_Matrix.series = Noort_temp(:,1);
Noort_Matrix.series_i = Noort_temp(:,2); 
Noort_Matrix.set = Noort_temp(:,3); 
Noort_Matrix.set_i = Noort_temp(:,4); 
Noort_Matrix.audio = audio';
Noort_Matrix.sentence = importdata('Stimuli/ListeningSpan_Stimuli/Noort_Matrix_sentences.mat');
Noort_Matrix.word = importdata('Stimuli/ListeningSpan_Stimuli/Noort_Matrix_words.mat'); % truncated words (to word stems)

% to get last words from sentences (not word stems)
for i = 1:length(Noort_Matrix.sentence)
    Satz = Noort_Matrix.sentence{i};
    Leer = strfind(Satz,' '); Leer = Leer(numel(Leer));
    Punkt = strfind(Satz, '.');
    Noort_Matrix.wordsraw{i,1} = lower(Satz(Leer+1:Punkt-1));
end

% get duration of the audio sentences and total duration of all audios
for i = 1:nStimuli
    Noort_Matrix.duration{i} = length(Noort_Matrix.audio{i})/Fs;
end
Noort_Matrix.duration = Noort_Matrix.duration';
totalDurationAudio = sum(cell2mat(Noort_Matrix.duration));
 

%% PTB Screen Preparation

    % Get the screen numbers
    screens = Screen('Screens');
    
    % Draw to the external screen if avaliable
    screenNumber = max(screens);
    % screenNumber = 1; % to test on laptop
    
    % Define black, white and grey
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    grey = 0.7;
    
    % Open an on screen window
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, white);
    [xC, yC] = RectCenter(windowRect);
    
    % Get the size of the on screen window in pixels
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    smallScreen = 0;
    if screenXpixels < 1500  % eg. laptop
        smallScreen = 1; % to adjust some layout parameters
        textSize = 30;
    else
        textSize = 40;
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
    slack = ifi/2; % can be used later for more acurate timing
    
    % Present waiting screen until all images are loaded (see code below)
    Screen('TextSize', window, 40);
    Screen('TextStyle', window, 1);
    DrawFormattedText(window, 'Bitte warten...','center', 'center', black);
    
    
    %% Key / Response information
    
    % Define the keyboard keys that are listened for. We will be using the
    % space keys as response key and the escape key as an exit/reset key
    % KbName('KeyNames') > shows all keynames
    spaceKey = KbName('space');
    escapeKey = KbName('ESCAPE');
    escapeExperiment = 0;  % checks if escape was pressed
    
    
    %% Trials, Blocks and Conditions
    
    numSeries = 5; % 5 series in total with 20 sentences each
    numSets = 5;   % 5 sets per series (with 2, 3, 4, 5 or 6 sentences)
    
    % define order of sets in sentence series (not random, pre-defined by Noort et al, 2008)
    serieP = [repmat(0,2,1),[2;3]];
    serie1 = [repmat(1,5,1),[2; 4; 3; 5; 6]];
    serie2 = [repmat(2,5,1),[5; 2; 4; 6; 3]];
    serie3 = [repmat(3,5,1),[6; 3; 5; 4; 2]];
    serie4 = [repmat(4,5,1),[4; 6; 2; 3; 5]];
    serie5 = [repmat(5,5,1),[3; 5; 6; 2; 4]];
    
    serieAll = [serieP;serie1;serie2;serie3;serie4;serie5];
    
    % Make a matrix to record the reading time for each sentence
    RespMatrix = {numSeries*5,5};
    zeile=1;   % first line to write data in response matrix
    
    % open txt-files to store responses
    logpath = ['logs' filesep subjID filesep];
    
    % create folder if it not exists
    if ~exist(logpath, 'dir')
        mkdir(logpath);
    end
    
    fileID = fopen([logpath 'ListeningSpan_' subjID '.txt'], 'w');
    fprintf(fileID, 'Block\tSetSize\tSetScore\n');
    
    fileIDtext = fopen([logpath 'ListeningSpan_' subjID 'Text.txt'], 'w');
    fprintf(fileIDtext, 'Block\tSetSize\tSetScore\tAnswer\tcorrectAnswer\n');
    
    
    %% Import Instruction Images
    
    % get all instruction images
    for i = 1:2

        % create a M x N x 3 matrix of the color image with integers between 0 and 255
        instr = imread(['Stimuli/ListeningSpan_Stimuli/Instruktion_LST_S',num2str(i),'.jpg']);
        
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
        
    
    %% Practice Block
    
    for p = 1:2       % loop over 2 practice sets
        
        currentSeries = serieAll(serieAll(:,1)==0,:);
        currentSetSize = currentSeries(p,2);
        
        for sentence = 1:currentSetSize   % loop over sentences in practise sets
            
            % get audio version of next sentence from Noort_Matrix
            currentAudio =  Noort_Matrix.audio{Noort_Matrix.series == 0 & ...
                Noort_Matrix.set == currentSetSize & Noort_Matrix.set_i == sentence};
            currentWords{sentence} = Noort_Matrix.word{Noort_Matrix.series == 0 & ...
                Noort_Matrix.set == currentSetSize & Noort_Matrix.set_i == sentence};
            
            % display fixation cross
            Screen('TextSize', window, 70);
            Screen('TextStyle', window, 0);
            DrawFormattedText(window, '+', 'center', 'center', black);
            tTextOn = Screen('Flip',window);
            
            % play sound
            sound(currentAudio/volume, Fs);
            audioSecs = length(currentAudio)/Fs;
            
            if KbCheck == 1
                while KbCheck; end  % wait for key to be released
            end
            
            while GetSecs < tTextOn + audioSecs + 1 % allow escape key to abort 
                
                % Check the keyboard for key presses
                [keyIsDown, tPress, keyCode] = KbCheck;
                
                if keyCode(escapeKey)
                    error('Abbruch des Experiments mit Escape');
                end
                
            end
            
        end
        
        % remember final words at the end of each set
        Screen('TextSize', window, textSize);
        Screen('TextStyle', window, 0);
        DrawFormattedText(window, 'Erinnern:', 'center', screenYpixels*0.38, black);
        Screen('FillRect', window, grey, [screenXpixels*0.07, screenYpixels*0.48, screenXpixels*0.93, screenYpixels*0.56]);
        Screen('TextSize', window, 25);
        Screen('TextStyle', window, 1);
        currentAnswer = GetEchoStringMod(window, '>', screenXpixels*0.1, yC, black, grey);
        currentAnswer = lower(currentAnswer);   % put to lower case letters for comparision
        currentAnswer = strrep(currentAnswer, 'ß', 'ss');   % exchange ß to ss for comparison
        Screen('Flip', window);
        % WaitSecs(6); % wait 6 seconds (like in E-Prime version from Noort et al, 2008)
        % KbStrokeWait; % not in E-Prime version from Noort et al, 2008
        
        % Compute Score for this set and present as feedback
        currentSetScore = 0;
        
        if ~isempty(currentAnswer)
            for sentence = 1:currentSetSize % check score for each last word in the current set
                currentRecall = strfind(currentAnswer, currentWords{sentence});
                if ~isempty(currentRecall)
                    currentSetScore = currentSetScore + 1;
                end
            end
        end
        
        % Feedback screen
        FBtext = ['Sie haben ',num2str(currentSetScore),' von ',num2str(currentSetSize),' Wörtern richtig erinnert!'];
        if smallScreen==1
            Screen('TextSize', window, 25); %Laptop!
        else
            Screen('TextSize', window, 30);
        end
        Screen('TextStyle', window, 1);  % bold
        DrawFormattedText(window, FBtext,'center','center',black);
        tFbOn = Screen('Flip', window);
        Screen('TextStyle', window, 0);  % unbold
        WaitSecs(1.5 - slack);  % show feedback for 1.5 sec
        
        FbOff = Screen('Flip',window);
        WaitSecs(1 - slack);  % blank screen for 1 sec before next set
            
    end  % end practice
    
    % Instruction Screen 2:
    while KbCheck; end % wait for key to be released
    
    Screen('DrawTexture', window, instrTexture{2}, [], instrImagePosition);
    Screen('Flip',window);
    
    while 1
        [keyisdown, secs, keyCode] = KbCheck;
        
        if keyCode(spaceKey)
            break
        elseif keyCode(escapeKey)
            error('Abbruch des Experiments mit Escape');
        end
        
    end
    
    
    %% Experimental Blocks
    
    for block = 1:numSeries   % loop over 5 experimental blocks
        
        currentSeries = serieAll(serieAll(:,1)==block,:);
        
        for set = 1:numSets       % loop over 5 experimental sets in each block
            
            currentSetSize = currentSeries(set,2);
            
            for sentence = 1:currentSetSize   % loop over sentences in each set
                
                % get audio version of next sentence from Noort_Matrix
                currentAudio =  Noort_Matrix.audio{Noort_Matrix.series == block & ...
                    Noort_Matrix.set == currentSetSize & Noort_Matrix.set_i == sentence};
                currentWords{sentence} = Noort_Matrix.word{Noort_Matrix.series == block & ...
                    Noort_Matrix.set == currentSetSize & Noort_Matrix.set_i == sentence};
                
                % display fixation cross on screen
                Screen('TextSize', window, 70);
                Screen('TextStyle', window, 0);
                DrawFormattedText(window, '+', 'center', 'center', black);
                tTextOn = Screen('Flip',window);
                
                % play sound
                sound(currentAudio/volume, Fs);
                audioSecs = length(currentAudio)/Fs;
                
                if KbCheck == 1
                    while KbCheck; end  % wait for key to be released
                end
                
                while GetSecs < tTextOn + audioSecs + 1 % allow escape key to abort 
                    
                    % Check the keyboard for key presses
                    [keyIsDown, tPress, keyCode] = KbCheck;
                    
                    if keyCode(escapeKey)
                        error('Abbruch des Experiments mit Escape');
                    end
                    
                end
                
            end
            
            % remember final words at the end of each set
            Screen('TextSize', window, textSize);
            Screen('TextStyle', window, 0);
            DrawFormattedText(window, 'Erinnern:', 'center', screenYpixels*0.38, black);
            Screen('FillRect', window, grey, [screenXpixels*0.07, screenYpixels*0.48, screenXpixels*0.93, screenYpixels*0.56]);
            Screen('TextSize', window, 25);
            Screen('TextStyle', window, 1);
            currentAnswer = GetEchoStringMod(window, '>', screenXpixels*0.1, yC, black, grey);
            currentAnswer = lower(currentAnswer);   % put to lower case letters for comparision
            currentAnswer = strrep(currentAnswer, 'ß', 'ss');   % exchange ß to ss for comparison
            Screen('Flip', window);
            % WaitSecs(6); % (like in E-Prime version from Noort et al, 2008)
            % KbStrokeWait; % not in E-Prime version from Noort et al, 2008
            
            % Compute Score for this set and save to logfile
            currentSetScore = 0;
            
            if ~isempty(currentAnswer)
                for sentence = 1:currentSetSize % check score for each last word in the current set
                    if sentence==1
                        correctAnswer = currentWords{sentence};
                    else
                        correctAnswer = [correctAnswer ', ' currentWords{sentence}];
                    end
                    currentRecall = strfind(currentAnswer, currentWords{sentence});
                    if ~isempty(currentRecall)
                        currentSetScore = currentSetScore + 1;
                    end
                end
            else
                for sentence = 1:currentSetSize % check score for each last word in the current set
                    if sentence==1
                        correctAnswer = currentWords{sentence};
                    else
                        correctAnswer = [correctAnswer ', ' currentWords{sentence}];
                    end
                end
            end

            % save  parameter for this set in response
            RespMatrix{zeile,1} = block;    
            RespMatrix{zeile,2} = currentSetSize;   
            RespMatrix{zeile,3} = currentSetScore;  
            RespMatrix{zeile,4} = currentAnswer;
            RespMatrix{zeile,5} = correctAnswer;
            
            % 1) save response matrix as cell array
            save(['Logfiles/ListeningSpan_', subjID],'RespMatrix');  
            
            % 2) save only number scores in txt-file
            temp1 = cell2mat(RespMatrix(zeile,1:3));
            fprintf(fileID, '%d\t %d\t %d\n', temp1');
            
            % 3) save number scores and word recalls in txt-file
            fprintf(fileIDtext, '%d\t %d\t %d\t', temp1');
            fprintf(fileIDtext, '%s\t', currentAnswer);
            fprintf(fileIDtext, '%s\n', correctAnswer);

            zeile=zeile+1;
            
        end % set loop
        
    end % block loop

    
    %% End of experiment
    
    % End screen:
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, 'Ende der Aufgabe.\n\n\nWeiter mit der Leertaste.', 'center', 'center', black);
    Screen('Flip', window);
    KbStrokeWait;
    
    % Exit the PTB environment
    ListenChar(0); % listen to the keyboard again
    ShowCursor; % show the cursor
    sca % close all screens, i.e. show the desktop/GUI again
    return;
        
catch lasterror % if something goes wrong between TRY and CATCH then the responsible error message is saved as lasterror
    
    % if an error occured between TRY and CATCH
    clear sound;   % if aborted in the middle of a sentence
    ListenChar(0); % listen to the keyboard again
    ShowCursor;    % show the cursor
    sca % close all screens, i.e. show the desktop/GUI again
    %rethrow(lasterror) % tell us what caused the error > do not use in GUI
    return;
    
end

%% Task Description [task adapted from ReadingSpan by Noort et al, 2008]

% In this task, subjects are presented with a series of sentences which are
% read aloud to them. At the end of each set, subjects are asked to recall
% the final word of each sentence in a free order by typing these words on
% the keyboard. Sentence sets vary in length from 2 to 6 sentences in
% random order. The function code checks the amount of remembered words for
% each set and saves the scores to a logfile. The total number of
% remembered words is determined as the final score for each subject in
% this task.