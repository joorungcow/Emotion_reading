function dp = OpenWindow(dp)
%dp = OpenWindow([dp])
%
%Calls the psychtoolbox command "Screen('OpenWindow') using the 'display'
%structure convention.
%
%Inputs:
%   dp             A structure containing display information with fields:
%       screenNum       Screen Number (default is 0)
%       bkColor         Background color (default is black: [0,0,0])
%       skipChecks      Flag for skpping screen synchronization (default is 0, or don't check)
%                       When set to 1, vbl sync check will be skipped,
%                       along with the text and annoying visual (!) warning
%
%Outputs:
%   dp             Same structure, but with additional fields filled in:
%       wPtr       Pointer to window, as returned by 'Screen'
%       frameRate       Frame rate in Hz, as determined by Screen('GetFlipInterval')
%       resolution      [width,height] of screen in pixels
%
%Note: for full functionality, the additional fields of 'display' should be
%filled in:
%
%       dist             distance of viewer from screen (cm)
%       width            width of screen (cm)

% To diplay Korean
Screen('Preference','TextEncodingLocale','UTF-8');
Screen('Preference', 'TextRenderer', 0);

% feature level 2: Normalized 0-1 color range and unified key mapping.
% This allows to specify all color or intensity values in a normalized
% range between 0.0 (for 0% output intensity) and 1.0 (for 100% output
% intensity).
PsychDefaultSetup(2);

if ~exist('dp','var')
    dp.screenNum = 0;
end

if ~isfield(dp,'screenNum')
    dp.screenNum = 0;
end

if ~isfield(dp,'bkColor')
    dp.bkColor = [128 128 128]; 
end

if ~isfield(dp,'width')
    temp = Screen('Resolution', dp.screenNum);
    dp.width = temp.width;
end

if ~isfield(dp,'dist')
    dp.dist = 98; %black
end

if ~isfield(dp,'skipChecks')
    dp.skipChecks = 0;
end

if ~isfield(dp,'stereoMode')
    dp.stereoMode = 0;
end

%Add CompressedMode
if dp.stereoMode == 102
    PsychImaging('PrepareConfiguration')
    PsychImaging('AddTask', 'General', 'SideBySideCompressedStereo');
end

if dp.skipChecks  
    Screen('Preference', 'Verbosity', 0);
    Screen('Preference', 'SkipSyncTests',1);
    Screen('Preference', 'VisualDebugLevel',0);
end

%Open the window
[dp.wPtr, dp.wRect] = PsychImaging('OpenWindow', dp.screenNum, dp.bkColor,[],[],[],dp.stereoMode);

% alpha-blending!!
[sourceFactorOld, destinationFactorOld]=Screen('BlendFunction', dp.wPtr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

%Set the display parameters 'frameRate' and 'resolution'
dp.ifi = Screen('GetFlipInterval',dp.wPtr);
dp.frameRate = round(1/dp.ifi); %Hz
dp.resolution = dp.wRect([3,4]);
[dp.cx dp.cy] = RectCenter(dp.wRect);

dp.ppd = dp.resolution(1)/((2*atan(dp.width/2/dp.dist))*180/pi);
