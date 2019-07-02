function [p] = bandit_22(VP, session, comment)
% bandit_21('SUBJECT_ID', SESSION, 'COMMENT')
% Function to run the bandit task by Daw (2006) in PsychToolBox.
% Random walks will be assigned randomly to the sessions. If you want to
% control the walk chosen, use "special" sessions:
% session 11 chooses random walk 1
% session 22 chooses random walk 2
% session 33 chooses random walk 3
% written by Anica Baening, Karima Chakroun and Antonius Wiehler in 2015.




% ------------
% GLOBAL OPTIONS
% ------------

p.debug = 0; % Use this to have a transparent screen and a limit of 3 trials
p.mri.on = 1; % If on, waits for MRI pulses



% ------------
% INPUT
% ------------

if exist('comment', 'var') == 0
    comment = 'no comment';
end

% if no VP given, ask for VP
if exist('VP', 'var') == 0
    VP = inputdlg('Bitte das VP-Kuerzel eingeben:');
    VP = VP{1};
end

% if no session given, ask for session
if exist('session', 'var') == 0
    session = inputdlg('Bitte die Session eingeben:');
    session = str2double(session{1});
end



% ------------
% SETUP
% ------------

clear mex global functions; clc; % clear everything
close all; % close open figures
sca; % close all open PTB Screens


% start PTB timing
GetSecs;
WaitSecs(0.001);


% Set experimental parameters
SetParameters;


% load walks for experiment
LoadRandomWalks;


% set PTB parameters
SetPTB;




% ------------
% RUN EXPERIMENT
% ------------

putLog(GetSecs, 'Experiment Start'); % start event logfile

ShowInstructionExp; %show instructions for experiment


% Wait for Dummy Scans
firstScannerPulseTime = WaitForDummyScans(p.mri.dummyScan);
p.log.mriExpStartTime = firstScannerPulseTime;
putLog(firstScannerPulseTime, 'FirstMRPulse_ExpStart');

% run the Experiment
runBanditExperiment;

%Show Session End
ShowEndSessionText;


% Clean up PTB
cleanup;













% ------------
% FUNCTIONS
% ------------

% Set all parameters relevant for the whole experiment
    function SetParameters
        
        % MRI
        p.mri.dummyScan = 5;
        p.mri.tr = 2.47; % wie lange braucht der Scanner fuer ein Volume
        p.comment = comment;
        
        
        % PC
        [~, hostname] = system('hostname');
        p.hostname = deblank(hostname);
        p.hostaddress = java.net.InetAddress.getLocalHost;
        p.hostIPaddress = char(p.hostaddress.getHostAddress);
        
        if strcmp(p.hostname, 'triostim1')
            p.path.experiment = 'C:\USER\chakroun\02_dabandit\02a_bandit\';
            p.debug = 0; % do not p.debug on stimulus PC
            
        elseif strcmp(p.hostname, 'gursky')
            p.path.experiment = '/transfer/06_pgbandit/04_bandit';
            
        else
            p.path.experiment = fullfile(pwd);
        end
        
        p.version = mfilename('fullpath');  % adds filename of the bandit function
        
        
        p.subID = VP;
        p.session = session;
        p.timestamp = datestr(now, 30); % date and clock at start of experiment
        
        p.path.subject = [p.path.experiment filesep 'logs' filesep p.subID filesep];
        
        % create folder if it not exists
        if ~exist(p.path.subject, 'dir')
            mkdir(p.path.subject);
        end
        
        p.path.save = [p.path.subject p.subID '_bandit_session_' num2str(session) '_' p.timestamp];
        
        
        
        
        % shuffle random number generator
        rng('shuffle');
        
        
        
        
        % EXPERIMENT
        
        p.exp.backgroundcolor = 0.5; % set background as grey
        
        % bandit colors (color positions randomly assigned to the 4 bandits)
        colors = {[255 40 0] ./ 255; [255 131 0] ./ 255; [2 131 174] ./ 255; [0 197 67] ./ 255};
        randCol = Shuffle(1:4);
        
        p.exp.FrameColor.a = colors{randCol(1)};
        p.exp.FrameColor.b = colors{randCol(2)};
        p.exp.FrameColor.c = colors{randCol(3)};
        p.exp.FrameColor.d = colors{randCol(4)};
        
        % stimuli size
        p.exp.framesize = [220 220]; % colored frame of bandit
        p.exp.fillsize = [180 180]; % white center of bandit
        p.exp.cframesize = [235 235]; %black frame for chosen bandit
        
        p.exp.distance_factor = 4.4; % p.ptb.height / p.exp.distance_factor = distance of stimuli from screen center
        
        
        
        % trial timing (from Daw et al, 2006)
        p.exp.tResponseWindow = 1.5;
        p.exp.tHighlightChoice = 3;
        p.exp.tRewardDuration = 1;
        p.exp.tCrossDuration = 4.2;
        
        % how many trials do want to have in the experiment?
        if p.debug
            p.exp.nTrials = 3;
        else
            p.exp.nTrials = 300;
        end
        
        
        % calculate ITI
        p.ITI_lambda = 2; % trial ends 6s after trial onset + variable iti (using a poisson distribution with a lambda of 2 sec)
        
        for i_t = 1 : p.exp.nTrials
            p.ITI(i_t) = poissrnd(p.ITI_lambda); % compute ITI for the trial
        end
        
        
        
        % create log structure
        p.log.mriExpStartTime = 0; % Initialize as zero
        p.log.events = {{},{},{},{}};
        p.log.eventCount = 0;
        p.log.RespMatrix = nan(p.exp.nTrials, 10); % save responses in response matrix
        
        
        
        
        
        % Now we define some keys that will be used during the experiment.
        
        KbName('UnifyKeyNames'); % keys have different internal names, depending on the operating system. This command unifies the names
        
        if strcmp(p.hostname,'triostim1')
            p.keys.a = KbName('3#'); %key option a
            p.keys.b = KbName('4$'); %key option b
            p.keys.c = KbName('2@'); % key option c
            p.keys.d = KbName('1!'); % key option d
            p.keys.trigger = KbName('5%'); % MRI trigger
            p.keys.escapeKey = KbName('q');
            p.keys.spaceKey = KbName('space');
            p.keys.interruptMeasurement = 1; % we will use the p.keys.escapeKey to exit the experiment at any time. This will be done by changing the variable p-interruptMeasurement to 1.
            
        else
            p.keys.a = KbName('i'); %key option a
            p.keys.b = KbName('o'); %key option b
            p.keys.c = KbName('k'); % key option c
            p.keys.d = KbName('l'); % key option d
            p.keys.trigger = KbName('5');
            p.keys.escapeKey = KbName('q');
            p.keys.spaceKey = KbName('space');
            p.keys.interruptMeasurement = 1; % we will use the p.keys.escapeKey to exit the experiment at any time. This will be done by changing the variable p-interruptMeasurement to 1.
        end
        
        
        save(p.path.save ,'p');
        
    end

% load randoim walks for experiment
    function LoadRandomWalks
        
        % load random walks by Daw
        outcomes = load('stimuli-gaussian.mat');
        outcomes.payoffs{1} = outcomes.payoffs1;
        outcomes.payoffs{2} = outcomes.payoffs2;
        outcomes.payoffs{3} = outcomes.payoffs3;
        
        outcomes.noise{1} = outcomes.noise1;
        outcomes.noise{2} = outcomes.noise2;
        outcomes.noise{3} = outcomes.noise3;
        
        walks_avial = [1 2 3]; % default: all 3 random walks are avialable
        
        
        % remove used walks from session 1
        if (session == 2) || (session == 3)
            
            % search for already used walks in session 1
            flist = dir(fullfile(p.path.subject, [VP '_bandit_session_1*.mat']));
            
            if size(flist, 1) == 0
                cleanup;
                error('No session 1 found');
            end
            
            if size(flist, 1) > 1
                cleanup;
                error('More than one session 1 file found');
            end
            
            previous{1} = load(fullfile(p.path.subject, flist(1).name)); % load previous session
            used_walk = previous{1}.p.exp.walk; % which walk was used before?
            walks_avial(walks_avial == used_walk) = []; % remove used walks from avialable walks
            
            
        end
        
        % remove used walks from session 2
        if session == 3
            
            % search for already used walks in session 2
            flist = dir(fullfile(p.path.subject, [VP '_bandit_session_2*.mat']));
            
            if size(flist, 1) == 0
                cleanup;
                error('No session 2 found');
            end
            
            if size(flist, 1) > 1
                cleanup;
                error('More than one session 2 file found');
            end
            
            previous{2} = load(fullfile(p.path.subject, flist(1).name)); % load previous session
            used_walk = previous{2}.p.exp.walk; % which walk was used before?
            walks_avial(walks_avial == used_walk) = []; % remove used walks from avialable walks
        end
        
        
        n_walks_avial = length(walks_avial); % n of avialable walks
        i_walk = unidrnd(n_walks_avial); % select random walk
        p.exp.walk = walks_avial(i_walk); % save random walk selection
        
        
        % manually select walk by session number
        if session == 11
            p.exp.walk = 1;
        elseif session == 22
            p.exp.walk = 2;
        elseif session == 33
            p.exp.walk = 3;
        end
        
        
        
        p.exp.payoffs = outcomes.payoffs{p.exp.walk}; % copy payoffs of selected walk
        p.exp.noise = outcomes.noise{p.exp.walk}; % copy noise
        
        
        %shuffle payoffs
        p.exp.orderpayoffs = [1,2,3,4];
        p.exp.orderpayoffs = Shuffle(p.exp.orderpayoffs);
        
        
        %add noise to payoffs
        p.exp.outcomelist.a = p.exp.payoffs(:, p.exp.orderpayoffs(1)) + p.exp.noise;
        p.exp.outcomelist.b = p.exp.payoffs(:, p.exp.orderpayoffs(2)) + p.exp.noise;
        p.exp.outcomelist.c = p.exp.payoffs(:, p.exp.orderpayoffs(3)) + p.exp.noise;
        p.exp.outcomelist.d = p.exp.payoffs(:, p.exp.orderpayoffs(4)) + p.exp.noise;
        
        
        %save points won in p.exp
        p.exp.points = [];
        
        
    end

% Set Up the PTB with parameters and initialize drivers
    function SetPTB
        
        PsychJavaTrouble();  % fix problem with Java path
        
        PsychDefaultSetup(2); %Here we call some default settings for setting up Psychtoolbox
        screens = Screen('Screens'); % Find the number of the screen to be opened
        p.ptb.screenNumber = max(screens); % Use the maximum, which is often the second monitor
        
        if p.debug
            commandwindow;
            PsychDebugWindowConfiguration; % Make everything transparent for p.debugging purposes.
        end
        
        
        % Define black and white
        p.ptb.white = WhiteIndex(p.ptb.screenNumber);
        p.ptb.black = BlackIndex(p.ptb.screenNumber);
        p.ptb.grey = 0.5;
        p.ptb.inc = p.ptb.white - p.ptb.grey;
        p.ptb.red = [1 0 0];
        
        %Default parameters
        Screen('Preference', 'ConserveVRAM', 256);
        Screen('Preference', 'DefaultFontName', 'Arial');
        Screen('Preference', 'TextAntiAliasing', 2); % Enable textantialiasing high quality
        Screen('Preference', 'VisualDebuglevel', 0);
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'SuppressAllWarnings', 1);
        
        if p.debug == 0;
            HideCursor(p.ptb.screenNumber); % Hide the cursor
        end
        
        %Open a graphics window using PTB
        [p.ptb.w, p.ptb.wRect] = PsychImaging('OpenWindow', p.ptb.screenNumber, p.ptb.grey);
        [p.ptb.screenXpixels, p.ptb.screenYpixels] = Screen('WindowSize', p.ptb.w);
        [p.ptb.xCenter, p.ptb.yCenter] = RectCenter(p.ptb.wRect);
        p.ptb.ifi = Screen('GetFlipInterval', p.ptb.w);
        p.ptb.slack = p.ptb.ifi ./ 2; % can be used later for more acurate timing
        
        
        ListenChar(2); % catch keyboard presses
        
        
        %  Screen('BlendFunction', p.ptb.w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        
        % Deal with the bad beamer resolution and
        % put it 80pixels higher
        %if p.mri.on
        %p.ptb.yCenter = p.ptb.yCenter-80;
        %end
        
        
        
        
        
        
        % PREPARE STIMULI GRAPHICS
        % ------------
        
        
        % First, we create a rect for our stimuli, putting it in the top left
        % corner of the screen
        p.ptb.frameRect = [0, 0, p.exp.framesize(1), p.exp.framesize(2)];
        p.ptb.fillRect = [0, 0, p.exp.fillsize(1), p.exp.fillsize(2)];
        p.ptb.cframeRect = [0, 0, p.exp.cframesize(1),p.exp.cframesize(2)];
        
        % Find positions for our Stimuli
        
        p.ptb.BanditCenter.a(1) = p.ptb.xCenter - p.ptb.screenYpixels/p.exp.distance_factor;
        p.ptb.BanditCenter.a(2) = p.ptb.yCenter - p.ptb.screenYpixels/p.exp.distance_factor; % two times screenYpixels is correct for symmetry
        p.ptb.BanditCenter.b(1) = p.ptb.xCenter + p.ptb.screenYpixels/p.exp.distance_factor;
        p.ptb.BanditCenter.b(2) = p.ptb.yCenter - p.ptb.screenYpixels/p.exp.distance_factor; % two times screenYpixels is correct for symmetry
        p.ptb.BanditCenter.c(1) = p.ptb.xCenter - p.ptb.screenYpixels/p.exp.distance_factor;
        p.ptb.BanditCenter.c(2) = p.ptb.yCenter + p.ptb.screenYpixels/p.exp.distance_factor; % two times screenYpixels is correct for symmetry
        p.ptb.BanditCenter.d(1) = p.ptb.xCenter + p.ptb.screenYpixels/p.exp.distance_factor;
        p.ptb.BanditCenter.d(2) = p.ptb.yCenter + p.ptb.screenYpixels/p.exp.distance_factor; % two times screenYpixels is correct for symmetry
        
        
        p.ptb.FramePosition.a = CenterRectOnPoint(p.ptb.frameRect, p.ptb.BanditCenter.a(1), p.ptb.BanditCenter.a(2));
        p.ptb.FramePosition.b = CenterRectOnPoint(p.ptb.frameRect, p.ptb.BanditCenter.b(1), p.ptb.BanditCenter.b(2));
        p.ptb.FramePosition.c = CenterRectOnPoint(p.ptb.frameRect, p.ptb.BanditCenter.c(1), p.ptb.BanditCenter.c(2));
        p.ptb.FramePosition.d = CenterRectOnPoint(p.ptb.frameRect, p.ptb.BanditCenter.d(1), p.ptb.BanditCenter.d(2));
        
        p.ptb.FillPosition.a = CenterRectOnPoint(p.ptb.fillRect, p.ptb.BanditCenter.a(1), p.ptb.BanditCenter.a(2));
        p.ptb.FillPosition.b = CenterRectOnPoint(p.ptb.fillRect, p.ptb.BanditCenter.b(1), p.ptb.BanditCenter.b(2));
        p.ptb.FillPosition.c = CenterRectOnPoint(p.ptb.fillRect, p.ptb.BanditCenter.c(1), p.ptb.BanditCenter.c(2));
        p.ptb.FillPosition.d = CenterRectOnPoint(p.ptb.fillRect, p.ptb.BanditCenter.d(1), p.ptb.BanditCenter.d(2));
        
        p.ptb.cFramePosition.a = CenterRectOnPoint(p.ptb.cframeRect, p.ptb.BanditCenter.a(1), p.ptb.BanditCenter.a(2));
        p.ptb.cFramePosition.b = CenterRectOnPoint(p.ptb.cframeRect, p.ptb.BanditCenter.b(1), p.ptb.BanditCenter.b(2));
        p.ptb.cFramePosition.c = CenterRectOnPoint(p.ptb.cframeRect, p.ptb.BanditCenter.c(1), p.ptb.BanditCenter.c(2));
        p.ptb.cFramePosition.d = CenterRectOnPoint(p.ptb.cframeRect, p.ptb.BanditCenter.d(1), p.ptb.BanditCenter.d(2));
        
        
    end


% Show Instructions for actual experiment
    function ShowInstructionExp
        
        if p.mri.on
            
            while KbCheck; end % wait for key to be released
            
            Screen('FillRect', p.ptb.w, p.exp.backgroundcolor); % we start with a filled rectangle as a background
            
            Screen('TextSize', p.ptb.w, 30);
            Screen('TextColor', p.ptb.w, p.ptb.black);
            Screen('TextStyle', p.ptb.w, 0);
            DrawFormattedText(p.ptb.w, 'Achtung, das Experiment startet gleich!', 'center', 'center');
            StartInstructionsExp = Screen('Flip',p.ptb.w);
            putLog(StartInstructionsExp,'Instructions Experiment');
            
            fprintf('Press "space" to start run\n');
            while 1
                [~, ~, keyCode] = KbCheck;
                
                if keyCode(p.keys.spaceKey)
                    fprintf('New run started - Ask MTA to turn scanner on\n');
                    break
                elseif keyCode(p.keys.escapeKey)
                    putLog(keyCode(p.keys.escapeKey),'Stop Experiment');
                    cleanup;
                    error('Stop experiment with escape');
                end
                
            end
            
            
            
            
            
        else
            
            while KbCheck; end % wait for key to be released
            
            Screen('FillRect', p.ptb.w, p.exp.backgroundcolor); % we start with a filled rectangle as a background
            
            Screen('TextSize', p.ptb.w, 30);
            Screen('TextColor', p.ptb.w, p.ptb.black);
            Screen('TextStyle', p.ptb.w, 0);
            DrawFormattedText(p.ptb.w, 'Tasten I, O, K und L\n\n\nExperiment startet mit der Leertaste', 'center', 'center');
            StartInstructionsExp = Screen('Flip',p.ptb.w);
            putLog(StartInstructionsExp,'Instructions Experiment');
            
            while 1
                [~, ~, keyCode] = KbCheck;
                
                if keyCode(p.keys.spaceKey)
                    break
                elseif keyCode(p.keys.escapeKey)
                    putLog(keyCode(p.keys.escapeKey),'Stop Experiment');
                    cleanup;
                    error('Stop experiment with escape');
                end
                
            end
        end
    end

    function runBanditExperiment
        % Bandit experiment
        
        
        save(p.path.save,'p'); % save p before the very first trial
        
        % LOOP TRIALS
        
        for i_t = 1 : p.exp.nTrials;
            
            
            % ------------
            % PAUSE AFTER 75, 150 AND 225 TRIALS
            % ------------
            
            if i_t == 76 || i_t == 151 || i_t == 226
                %WaitSecs(14);
                DrawFormattedText(p.ptb.w, 'Pause', 'center', 'center');
                WaitScreen = Screen('Flip', p.ptb.w);
                putLog(WaitScreen, 'Run_End');
                save(p.path.save, 'p'); % Save current status of logfile
                fprintf('After Scanner stopped hit "space" \n'); % Stop Scanner (This is due to the fact, that we do not know how many scans we need!
                
                while 1
                    [keyIsDown, ~, keyCode] = KbCheck(-1);
                    if keyIsDown
                        if find(keyCode) == p.keys.spaceKey;
                            WaitSecs(0.1);
                            keyIsDown = [];
                            keyCode = [];
                            fprintf('Stopped.\n');
                            break;
                        end
                    end
                end
                
                
                
                WaitSecs(0.5);  % wait between key presses
                
                fprintf('Press "space" to start run\n');
                
                
                while 1
                    [keyIsDown, ~, keyCode] = KbCheck(-1);
                    if keyIsDown
                        if find(keyCode) == p.keys.spaceKey;
                            WaitSecs(0.1);
                            keyIsDown = [];
                            keyCode = [];
                            fprintf('New run started - Ask MTA to turn scanner on\n');
                            break;
                        end
                    end
                end
                
                newSession = WaitForDummyScans(p.mri.dummyScan);
                putLog(newSession, 'FirstMRPulse_RunStart');
                
            end
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            % ------------
            % DRAW 4 BANDITS
            % ------------
            
            Screen('FillRect', p.ptb.w, p.exp.backgroundcolor); % we start with a filled rectangle as a background
            
            Screen('FillRect', p.ptb.w, p.exp.FrameColor.a, p.ptb.FramePosition.a);
            Screen('FillRect', p.ptb.w, p.exp.FrameColor.b, p.ptb.FramePosition.b);
            Screen('FillRect', p.ptb.w, p.exp.FrameColor.c, p.ptb.FramePosition.c);
            Screen('FillRect', p.ptb.w, p.exp.FrameColor.d, p.ptb.FramePosition.d);
            
            Screen('FillRect', p.ptb.w, p.ptb.white, p.ptb.FillPosition.a);
            Screen('FillRect', p.ptb.w, p.ptb.white, p.ptb.FillPosition.b);
            Screen('FillRect', p.ptb.w, p.ptb.white, p.ptb.FillPosition.c);
            Screen('FillRect', p.ptb.w, p.ptb.white, p.ptb.FillPosition.d);
            
            DrawFixationCross;
            
            tBanditOnset = Screen('Flip', p.ptb.w, [] , 1); % The flip command can yield an exact time stamp of when the stimulus appeared. We will use this
            putLog(tBanditOnset, sprintf('BanditOnset_%03i', i_t)); % add trial number to onset of bandits
            
            
            % ------------
            % RECORD CHOICE
            % ------------
            
            selection.a = 0;
            selection.b = 0;
            selection.c = 0;
            selection.d = 0;
            
            pressedInTime = 0; % don't go to rating if RT > symRTmax
            
            while GetSecs - tBanditOnset <= p.exp.tResponseWindow % response window
                
                [ keyIsDown, tKeyPress, keyCode ] = KbCheck; % this checks the keyboard very, very briefly.
                
                if keyIsDown % only if a key was pressed we check which key it was
                    if keyCode(p.keys.a)
                        putLog(tKeyPress, 'choice bandit A');
                        selection.a = 1;
                        pressedInTime = 1;
                        chosenBanditCenter = p.ptb.BanditCenter.a;
                        WaitTextRect = p.ptb.FramePosition.a;
                        WaitTextRect_fill = p.ptb.FillPosition.a;
                        WaitTextRect_c = p.ptb.cFramePosition.a; %add frame to chosen bandit
                        WaitTextRect_color = p.exp.FrameColor.a;
                        outcome_text = ['+ ' num2str(round(p.exp.outcomelist.a(i_t))) ' Punkte'];
                        p.exp.points(i_t) = p.exp.outcomelist.a(i_t);
                        break
                    end
                    
                    if keyCode(p.keys.b)
                        putLog(tKeyPress, 'choice bandit B');
                        selection.b = 1;
                        pressedInTime = 1;
                        chosenBanditCenter = p.ptb.BanditCenter.b;
                        WaitTextRect = p.ptb.FramePosition.b;
                        WaitTextRect_fill = p.ptb.FillPosition.b;
                        WaitTextRect_c = p.ptb.cFramePosition.b;
                        WaitTextRect_color = p.exp.FrameColor.b;
                        outcome_text = ['+ ' num2str(round(p.exp.outcomelist.b(i_t))) ' Punkte'];
                        p.exp.points(i_t) = p.exp.outcomelist.b(i_t);
                        break
                    end
                    
                    if keyCode(p.keys.c)
                        putLog(tKeyPress, 'choice bandit C');
                        selection.c = 1;
                        pressedInTime = 1;
                        chosenBanditCenter = p.ptb.BanditCenter.c;
                        WaitTextRect = p.ptb.FramePosition.c;
                        WaitTextRect_fill = p.ptb.FillPosition.c;
                        WaitTextRect_c = p.ptb.cFramePosition.c;
                        WaitTextRect_color = p.exp.FrameColor.c;
                        outcome_text = ['+ ' num2str(round(p.exp.outcomelist.c(i_t))) ' Punkte'];
                        p.exp.points(i_t) = p.exp.outcomelist.c(i_t);
                        break
                    end
                    
                    if keyCode(p.keys.d)
                        putLog(tKeyPress, 'choice bandit D');
                        selection.d = 1;
                        pressedInTime = 1;
                        chosenBanditCenter = p.ptb.BanditCenter.d;
                        WaitTextRect = p.ptb.FramePosition.d;
                        WaitTextRect_fill = p.ptb.FillPosition.d;
                        WaitTextRect_c = p.ptb.cFramePosition.d;
                        WaitTextRect_color = p.exp.FrameColor.d;
                        outcome_text = ['+ ' num2str(round(p.exp.outcomelist.d(i_t))) ' Punkte'];
                        p.exp.points(i_t) = p.exp.outcomelist.d(i_t);
                        break
                    end
                    
                    
                    if keyCode(p.keys.escapeKey)
                        putLog(tKeyPress,'Stop Experiment');
                        Screen('Close', p.ptb.w);
                        cleanup;
                        error('Stop experiment with escape');
                    end
                    
                    if keyCode(p.keys.trigger)
                        putLog(tKeyPress, 'mriTrigger');
                        keyIsDown = [];
                        keyCode = [];
                        % but do not break while loop!
                    end
                    
                end
                
                
            end
            
            
            
            
            
            % calculate RT for this trial
            if pressedInTime
                RT = tKeyPress - tBanditOnset;
            else
                RT = nan;
            end
            
            
            
            
            
            
            
            % ------------
            % SHOW SELECTED BANDIT "SPINNING"
            % ------------
            
            if pressedInTime
                
                
                Screen('FillRect', p.ptb.w, p.ptb.black, WaitTextRect_c);
                Screen('FillRect', p.ptb.w, WaitTextRect_color, WaitTextRect);
                Screen('FillRect', p.ptb.w, p.ptb.white, WaitTextRect_fill);
                
                
                Screen('TextSize', p.ptb.w, 30);
                Screen('TextStyle', p.ptb.w, 1);
                
                text = '  .'; % maximum text to determine TextBounds
                
                % estimate text bounds
                currentTextRect = Screen('TextBounds', p.ptb.w, text);
                
                
                
                % ------------
                % 1 DOT
                % ------------
                
                text = '.';
                
                % draw text in text bounds
                Screen('DrawText', p.ptb.w, text, chosenBanditCenter(1) - 0.5 .* currentTextRect(3), chosenBanditCenter(2) - 0.5 .* currentTextRect(4), p.ptb.black);
                
                
                Spinning = Screen('Flip', p.ptb.w, [], 1);
                
                putLog(Spinning,'BanditSpinning');
                
                while GetSecs - Spinning <= (p.exp.tHighlightChoice / 3) % show . for x second
                    [ keyIsDown, tKeyPress, keyCode ] = KbCheck; % this checks the keyboard very, very briefly.
                    
                    if keyIsDown && keyCode(p.keys.trigger)
                        putLog(tKeyPress, 'mriTrigger');
                        keyIsDown = [];
                        keyCode = [];
                        % but do not break while loop!
                    end
                end
                
                
                % ------------
                % 2 DOTS
                % ------------
                
                text = ' .';
                
                % draw text in text bounds
                Screen('DrawText', p.ptb.w, text, chosenBanditCenter(1) - 0.5 .* currentTextRect(3), chosenBanditCenter(2) - 0.5 .* currentTextRect(4), p.ptb.black);
                
                Spinning = Screen('Flip', p.ptb.w, [], 1);
                
                while GetSecs - Spinning <= (p.exp.tHighlightChoice / 3) % show .. for x second
                    [ keyIsDown, tKeyPress, keyCode ] = KbCheck; % this checks the keyboard very, very briefly.
                    
                    if keyIsDown && keyCode(p.keys.trigger)
                        putLog(tKeyPress, 'mriTrigger');
                        keyIsDown = [];
                        keyCode = [];
                        % but do not break while loop!
                    end
                end
                
                
                
                % ------------
                % 3 DOTS
                % ------------
                
                text = '  .';
                
                
                % draw text in text bounds
                Screen('DrawText', p.ptb.w, text, chosenBanditCenter(1) - 0.5 .* currentTextRect(3), chosenBanditCenter(2) - 0.5 .* currentTextRect(4), p.ptb.black);
                
                Spinning = Screen('Flip', p.ptb.w, [], 1);
                
                while GetSecs - Spinning <= (p.exp.tHighlightChoice / 3) % show ... for x second
                    [ keyIsDown, tKeyPress, keyCode ] = KbCheck; % this checks the keyboard very, very briefly.
                    
                    if keyIsDown && keyCode(p.keys.trigger)
                        putLog(tKeyPress, 'mriTrigger');
                        keyIsDown = [];
                        keyCode = [];
                        % but do not break while loop!
                    end
                end
                
                
                
                
                % ------------
                % SHOW OUTCOME
                % ------------
                
                
                Screen('FillRect', p.ptb.w, p.exp.FrameColor.a, p.ptb.FramePosition.a);
                Screen('FillRect', p.ptb.w, p.exp.FrameColor.b, p.ptb.FramePosition.b);
                Screen('FillRect', p.ptb.w, p.exp.FrameColor.c, p.ptb.FramePosition.c);
                Screen('FillRect', p.ptb.w, p.exp.FrameColor.d, p.ptb.FramePosition.d);
                
                Screen('FillRect', p.ptb.w, p.ptb.white, p.ptb.FillPosition.a);
                Screen('FillRect', p.ptb.w, p.ptb.white, p.ptb.FillPosition.b);
                Screen('FillRect', p.ptb.w, p.ptb.white, p.ptb.FillPosition.c);
                Screen('FillRect', p.ptb.w, p.ptb.white, p.ptb.FillPosition.d);
                
                DrawFixationCross;
                
                
                % set text size and style for outcome text
                Screen('TextSize', p.ptb.w, 20);
                Screen('TextStyle', p.ptb.w, 1);
                
                
                % estimate text bounds
                currentTextRect = Screen('TextBounds', p.ptb.w, outcome_text);
                
                % draw outcome text
                Screen('DrawText', p.ptb.w, outcome_text, chosenBanditCenter(1) - 0.5 .* currentTextRect(3), chosenBanditCenter(2) - 0.5 .* currentTextRect(4), p.ptb.black);
                
                tRewardOnset = Screen('Flip', p.ptb.w); % The flip command can yield an exact time stamp of when the stimulus appeared. We will use this
                putLog(tRewardOnset, 'Reward');
                
                
                while (GetSecs - tRewardOnset) <= (p.exp.tRewardDuration - p.ptb.slack) % show outcome for 1 second
                    [ keyIsDown, tKeyPress, keyCode ] = KbCheck; % this checks the keyboard very, very briefly.
                    
                    if keyIsDown && keyCode(p.keys.trigger)
                        putLog(tKeyPress, 'mriTrigger');
                        keyIsDown = [];
                        keyCode = [];
                        % but do not break while loop!
                    end
                end
                
                
                
                
                
                % ------------
                % SHOW RED X FOR TOO SLOW
                % ------------
                
            else  % if not pressed in time
                
                Screen('Flip', p.ptb.w); % clear screen
                Screen('TextSize', p.ptb.w, 80);
                Screen('TextStyle', p.ptb.w, 1);
                
                text = 'X';
                currentTextRect = Screen('TextBounds', p.ptb.w, text);
                
                Screen('DrawText', p.ptb.w, text, p.ptb.xCenter - 0.5 .* currentTextRect(3), p.ptb.yCenter - 0.5 .* currentTextRect(4), p.ptb.red);
                
                tCrossOnset = Screen('Flip', p.ptb.w); % The flip command can yield an exact time stamp of when the stimulus appeared. We will use this
                putLog(tCrossOnset,'RT too slow');
                
                while (GetSecs - tCrossOnset) <= (p.exp.tCrossDuration - p.ptb.slack)
                    [ keyIsDown, tKeyPress, keyCode ] = KbCheck;
                    
                    if keyIsDown && keyCode(p.keys.trigger)
                        putLog(tKeyPress, 'mriTrigger');
                        keyIsDown = [];
                        keyCode = [];
                        % but do not break while loop!
                    end
                end
            end
            
            
            % ------------
            % ITI
            % ------------
            
            Screen('FillRect', p.ptb.w, p.exp.backgroundcolor); % we start with a filled rectangle. We don't specify any coordinates.
            DrawFixationCross;
            
            OnsetFixationCross = Screen('Flip', p.ptb.w); % The flip command can yield an exact time stamp of when the stimulus appeared. We will use this
            putLog(OnsetFixationCross,'Fixationcross');
            
            
            while (GetSecs - tBanditOnset) <= 6 + p.ITI(i_t) % end Trial 6 + ITI seconds after onset
                
                [ keyIsDown, tKeyPress, keyCode ] = KbCheck; % this checks the keyboard very, very briefly.
                
                if keyIsDown && keyCode(p.keys.escapeKey)
                    putLog(tKeyPress, 'Stop Experiment');
                    cleanup;
                    error('Stop experiment with escape');
                end
                
                if keyIsDown && keyCode(p.keys.trigger)
                    putLog(tKeyPress, 'mriTrigger');
                    keyIsDown = [];
                    keyCode = [];
                    % but do not break while loop!
                end
                
            end
            
            % ------------
            % SAVE RESULTS OF THIS TRIAL
            % ------------
            
            
            p.log.RespMatrix(i_t, 1) = i_t; % trial number
            p.log.RespMatrix(i_t, 2) = selection.a; % chosen bandit A?
            p.log.RespMatrix(i_t, 3) = selection.b; % chosen bandit B?
            p.log.RespMatrix(i_t, 4) = selection.c; % chosen bandit C?
            p.log.RespMatrix(i_t, 5) = selection.d; % chosen bandit D?
            p.log.RespMatrix(i_t, 6) = p.exp.outcomelist.a(i_t); % value bandit A
            p.log.RespMatrix(i_t, 7) = p.exp.outcomelist.b(i_t); % value bandit B
            p.log.RespMatrix(i_t, 8) = p.exp.outcomelist.c(i_t); % value bandit C
            p.log.RespMatrix(i_t, 9) = p.exp.outcomelist.d(i_t); % value bandit D
            p.log.RespMatrix(i_t, 10) = RT; % response time
            
            save(p.path.save, 'p'); %saves p file after each trial
            
            % display information to console
            fprintf('Trial %d of %d\tChoice: %d %d %d %d\tOutcomes: %2.0f %2.0f %2.0f %2.0f\tRT: %2.4fs\n', i_t, ...
                p.exp.nTrials, selection.a, selection.b, selection.c, selection.d, ...
                p.exp.outcomelist.a(i_t), p.exp.outcomelist.b(i_t), p.exp.outcomelist.c(i_t), p.exp.outcomelist.d(i_t), ...
                RT);
            
            
        end % end i_t trial
        
        
        
    end

    function DrawFixationCross
        Screen('TextSize', p.ptb.w, 40);
        Screen('TextStyle', p.ptb.w, 0);
        fix_text = '+';
        currentTextRect = Screen('TextBounds', p.ptb.w, fix_text);
        Screen('DrawText', p.ptb.w, fix_text, p.ptb.xCenter - 0.5 .* currentTextRect(3), p.ptb.yCenter - 0.5 .* currentTextRect(4), p.ptb.white);
    end

%Show Session End
    function ShowEndSessionText
        save(p.path.save, 'p');
        while KbCheck; end % wait for key to be released
        
        Screen('FillRect', p.ptb.w, p.exp.backgroundcolor); % we start with a filled rectangle as a background
        Screen('TextSize', p.ptb.w, 30);
        Screen('TextColor', p.ptb.w, p.ptb.black);
        Screen('TextStyle', p.ptb.w, 0);
        
        totalpoints = sum(p.exp.points); %calculate total number of points won
        p.exp.totalpoints = totalpoints; % save number of total points to p.exp.file
        fprintf('points total: %2.2f\n', round(totalpoints)); %show total number of points in console
        totalmoney = totalpoints*0.05; % calculate total number of money won
        p.exp.totalmoney = round(totalmoney) / 100; % save number of total money (in Euro) won to p.exp.file
        fprintf('money total: %2.2f Euro\n', round(totalmoney) / 100); %show total number of money (in Euro) won in console
        
        outcome_text_vp = ['Ende des Experiments\n\n\n' 'Punkte insgesamt: ' num2str(round(p.exp.totalpoints)) '\n\n\nGewinn: ' num2str(p.exp.totalmoney) ' Euro' '\n\n\nVielen Dank fuer die Teilnahme!'];
        DrawFormattedText(p.ptb.w, outcome_text_vp, 'center', 'center');
        ShowEndExp=Screen('Flip',p.ptb.w);
        putLog(ShowEndExp,'End Session');
        
        WaitSecs(10);
        
        
    end


% If p_mrt_on == 1, wait for n dummyscans before actual experiment starts and print out time for starting pulse
    function [t] = WaitForDummyScans(n)
        if p.mri.on == 1
            
            fprintf('Waiting for %d dummy scans...\n', n);
            
            pulse = 0;
            
            while pulse <= n
                [keyIsDown, t, keyCode] = KbCheck(-1);
                if keyIsDown
                    if find(keyCode) == p.keys.trigger;
                        WaitSecs(0.5);
                        keyIsDown = [];
                        keyCode = [];
                        
                        % show countdown for participant
                        DrawFormattedText(p.ptb.w, num2str(n - pulse), 'center', 'center');
                        CountdownScreen = Screen('Flip', p.ptb.w);
                        
                        pulse = pulse + 1;
                        
                        fprintf('This was scanner pulse number: %d \n', pulse);               
                    end
                end
            end
        else
            t = GetSecs;
        end
    end

% function create logfile
    function putLog(ptb_time, event_info)
        % Function to log all events
        % only if event is different to last event or > 1/2 TR
        if ~strcmp(p.log.events(end,4), event_info) || ptb_time - p.log.events{p.log.eventCount,2} > p.mri.tr/2
            p.log.eventCount = p.log.eventCount + 1;
            p.log.events(p.log.eventCount,1) = {p.log.eventCount};
            p.log.events(p.log.eventCount,2) = {ptb_time};
            p.log.events(p.log.eventCount,3) = {ptb_time-p.log.mriExpStartTime};
            p.log.events(p.log.eventCount,4) = {event_info};
        end
    end




%After experiment is over clean and close drivers
    function cleanup
        sca;
        commandwindow;
        ListenChar(0);
        save(p.path.save, 'p');
    end



end
