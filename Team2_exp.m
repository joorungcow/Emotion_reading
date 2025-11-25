clear all;
close all;
clc;

dp.dist = 50;  
dp.width = 30;
dp.skipChecks = 0; %mac = 1, window = 0
dp.screenNum = 0; 
dp.bkColor = [128, 128, 128]; 
dp.stereoMode = 0; 

% 키보드 설정
kb = init_keyboard;

% 랜덤 시드 설정
rng('shuffle'); 
params.randSeed = rng; 

%%
% 조건 설정
nConds = 2; % 큐가 좌/우에 나오는 조건
nTrialType = 2; % 일치/불일치 조건
gapType = 2; % gap0과 gap200 조건

nReps = 40; % 각 조건당 반복 횟수

nTrials = nConds * nTrialType * gapType * nReps; 

% 일치/불일치 확률 설정
per_invalid = 0.25; % 불일치 조건 확률
per_valid = 1 - per_invalid; % 일치 조건 확률

% 조건 벡터 생성
temp1 = [zeros(nTrials/nConds, 1); ones(nTrials/nConds, 1)];

num_invalid = round(nTrials * per_invalid);
num_valid = nTrials - num_invalid;
real_per_invalid = (( num_invalid / nTrials  ) * 100 );
temp2 = [zeros(num_invalid, 1); ones(num_valid, 1)];
temp2 = temp2(randperm(length(temp2))); 

temp3 = [zeros(nTrials/(nConds * gapType), 1); ones(nTrials/(nConds * gapType), 1)];
temp3 = repmat(temp3, nConds, 1); % cue 및 trial type 조건 반복

% 조건 매트릭스 결합
cMatrix = [temp1 temp2 temp3];

% 트라이얼 순서를 랜덤하게 섞기
randTrial = Shuffle(1:nTrials);

% 조건 매트릭스 섞기
cMatrix = cMatrix(randTrial, :);

% 고정점(fixation) 파라미터 설정
fixSize = 20; % 고정점 크기
color = [255 255 255]; % 고정점 색 (흰색)
lineWidth = 3; % 선 두께

%% Face

currentDir = pwd;
faceDir = fullfile(currentDir,'FACE');

cd(faceDir)
d = dir('*.png');
randNumber = randperm(length(d));
faces = cell(1, 16); 
for i = 1:16
    faces{i} = imread(fullfile(faceDir, d(randNumber(i)).name));
end

cd(currentDir)                          

% 조건 벡터 생성
fMatrix = repmat(1:16, 1, nTrials / 16);
fMatrix = Shuffle(fMatrix);

%%
% 학번 입력 및 실험 종류 선택
studentID = input('학번을 입력해주세요: ', 's');

validGender = false;
while ~validGender
    gender = input('성별을 입력해주세요 (M/F): ', 's');
    if strcmpi(gender, 'M') || strcmpi(gender, 'F')
        validGender = true;
    else
        disp('Invalid input. Please enter M for Male or F for Female.');
    end
end

age = input('만나이를 입력해주세요: ');

validHand = false;
while ~validHand
    hand = input('주로 사용하는 손은 무엇인가요? (R/L): ', 's');
    if strcmpi(hand, 'R') || strcmpi(hand, 'L')
        validHand = true;
    else
        disp('Invalid input. Please enter R for Right hand or L for Left hand.');
    end
end

validcolor = false;
while  ~validcolor
    color = input('시력이상 또는 색약이 없으신가요?(Y/N): ','s');
    if strcmpi(color,'Y') || strcmpi(color,'N')
        validcolor = true;
    else
        disp('Invalid input. Please enter Y for normal or N.')
    end
end

% 결과 저장 파일명 설정
saveFileName = ['results_Exp2_' studentID '.mat'];

% 결과 초기화
result.responseTimes = NaN(1, nTrials);
result.response = cell(1, nTrials);
result.intensity = NaN(nTrials, 4); % [cue_direction, trial_type, gap_type]
result.responseCorrect = NaN(1, nTrials);
result.info = struct('gender', gender, 'age', age, 'hand', hand, 'color', color); % gender와 age와 hand를 하나의 필드로 저장

% Psychtoolbox 초기화
Screen('Preference', 'SkipSyncTests', dp.skipChecks);
Screen('Preference', 'TextEncodingLocale', 'UTF-8');
Screen('Preference', 'DefaultFontName', 'Arial');
Screen('Preference', 'DefaultFontSize', 36);
[dp.wPtr, dp.rect] = Screen('OpenWindow', dp.screenNum, dp.bkColor);
Screen('TextFont', dp.wPtr, 'Arial');
dp.ifi = Screen('GetFlipInterval', dp.wPtr);
dp.resolution = dp.rect(3:4);
[dp.cx, dp.cy] = RectCenter(dp.rect);
dp.ppd = dp.resolution(1) / ((2 * atan(dp.width / 2 / dp.dist)) * 180 / pi);

% 실험 패러다임
try
    HideCursor; % 커서 숨기기
    ListenChar(2); % MATLAB 명령 창으로의 키 입력 억제

    % 지시문과 고정점을 표시하고 스페이스바를 기다림
    while true
        % 지시문 표시
        drawText(dp, [dp.cx, dp.cy - 250], 'Look at the fixed point', [255, 255, 255]);
        drawText(dp, [dp.cx, dp.cy - 200], 'Press Right Arrow if the dot is on the right.', [255, 255, 255]);
        drawText(dp, [dp.cx, dp.cy - 150], 'Press Left Arrow if the dot is on the left.', [255, 255, 255]);
        drawText(dp, [dp.cx, dp.cy - 100], 'Press spacebar Key to Begin.', [255, 255, 255]);
        drawText(dp, [dp.cx, dp.cy - 50], 'Press P key to Practice trial', [255, 255, 255]);
        drawText(dp, [dp.cx, dp.cy + 50], 'If the answer is correct, the feedback will be Green.', [255, 255, 255]);
        drawText(dp, [dp.cx, dp.cy + 100], 'If the answer is incorrect, the feedback will be Red.', [255, 255, 255]);

        % 고정점 표시
        make_fixation(dp, 10, [255, 255, 255], 2);
        Screen('Flip', dp.wPtr);

        % 키 입력 대기
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && keyCode(KbName('space'))
            break;
        elseif keyIsDown && keyCode(KbName('P'))
            practice_trials(dp, fixSize, color, lineWidth, nConds, nTrialType, gapType, per_invalid, faces, fMatrix, faceDir, randNumber, d);
        end
    end

    % 메인 실험 루프
    for trial = 1:nTrials
        [result.responseTimes(trial), result.response{trial}, result.intensity(trial, :), result.responseCorrect(trial)] = ...
            show_stimulus_endogenous(dp, cMatrix(trial, :), fixSize, color, lineWidth, faces, fMatrix, trial, faceDir, randNumber, d);

        % 쉬는 시간 삽입
        if mod(trial, round(nTrials/3)) == 0 && trial ~= nTrials
            drawText(dp, [dp.cx, dp.cy], 'Rest time. Please take a 30-second break and press the spacebar to continue.', [255, 255, 255]);
            Screen('Flip', dp.wPtr);
            WaitSecs(30); % 30초 휴식 
            while true
                [keyIsDown, ~, keyCode] = KbCheck;
                if keyIsDown && keyCode(KbName('space'))
                    break;
                end
            end
        end

        % 실험 종료 플래그 확인
        if strcmp(result.response{trial}, 'ESCAPE')
            break;
        end

        % 다음 실험 전 짧은 일시정지
        WaitSecs(0.5);
    end

    % 실험 종료 메시지
    drawText(dp, [dp.cx, dp.cy], 'The experiment is over. Thank you!', [255, 255, 255]);
    Screen('Flip', dp.wPtr);
    WaitSecs(2);

catch ME
    Screen('CloseAll');
    ListenChar(0); % 키 입력 재허용
    rethrow(ME);
end

% 모든 화면 닫기 및 키 입력 재허용
Screen('CloseAll');
ListenChar(0);

% 결과 저장
result.all = [result.intensity, (result.responseTimes)', (result.responseCorrect)'];
save(saveFileName, 'result', 'studentID', 'gender', 'age', 'hand', 'color', 'dp');


% 결과 매트릭스 열 이름 지정 
resultTable = array2table(result.all, 'VariableNames', {'CondType', 'ValidType', 'GapType', 'FaceType', 'RT', 'responseCorrect'});
writetable(resultTable, [saveFileName, '.csv']);


% 내인성 실험 자극 표시 함수 정의
function [RT, response, intensity, responseCorrect] = show_stimulus_endogenous(dp, condition, fixSize, color, lineWidth, faces, fMatrix, trial, faceDir, randNumber, d)
    % 1. 고정점 표시 (0.3초)
    make_fixation(dp, fixSize, [255, 255, 255], lineWidth);
    Screen('Flip', dp.wPtr);
    WaitSecs(0.3); % 300ms

    % 2. Dot 표시 (0.8초)
    dotRect = CenterRectOnPoint([0 0 fixSize fixSize], dp.cx, dp.cy);
    Screen('FillOval', dp.wPtr, [255, 255, 255], dotRect);
    Screen('Flip', dp.wPtr);
    WaitSecs(0.8); % 800ms

    % 3. 내인성 큐 표시 (0.3초)
    arrowPosY = dp.cy - dp.ppd * 0.7  ; % 화살표 위치(화면 정중앙 기준 0.7도 위)
    arrowLength = dp.ppd * 0.40; % 화살표의 길이 (0.40도 정도)
    arrowWidth = 4; % 화살표의 굵기

    if condition(1) == 0 % 왼쪽 화살표
        Screen('DrawLine', dp.wPtr, [255, 255, 255], dp.cx - arrowLength, arrowPosY, dp.cx + arrowLength, arrowPosY, arrowWidth);
        Screen('DrawLine', dp.wPtr, [255, 255, 255], dp.cx - arrowLength, arrowPosY, dp.cx - arrowLength + 10, arrowPosY - 10, arrowWidth);
        Screen('DrawLine', dp.wPtr, [255, 255, 255], dp.cx - arrowLength, arrowPosY, dp.cx - arrowLength + 10, arrowPosY + 10, arrowWidth);
    else % 오른쪽 화살표
        Screen('DrawLine', dp.wPtr, [255, 255, 255], dp.cx - arrowLength, arrowPosY, dp.cx + arrowLength, arrowPosY, arrowWidth);
        Screen('DrawLine', dp.wPtr, [255, 255, 255], dp.cx + arrowLength, arrowPosY, dp.cx + arrowLength - 10, arrowPosY - 10, arrowWidth);
        Screen('DrawLine', dp.wPtr, [255, 255, 255], dp.cx + arrowLength, arrowPosY, dp.cx + arrowLength - 10, arrowPosY + 10, arrowWidth);
    end

    dotRect = CenterRectOnPoint([0 0 fixSize fixSize], dp.cx, dp.cy); % 추가
    Screen('FillOval', dp.wPtr, [255, 255, 255], dotRect);

    Screen('Flip', dp.wPtr);
    WaitSecs(0.5); % 500ms


    % 4. Dot만 표시 (0.2초)
    Screen('FillOval', dp.wPtr, [255, 255, 255], dotRect);
    Screen('Flip', dp.wPtr);
    WaitSecs(0.2); % 200ms

    % 5. Dot 재정향 단서 제시 (0.3초)
    face_img_file = d(randNumber(fMatrix(trial))).name; % Get the file name
    [imgData, ~, alpha] = imread(fullfile(faceDir, face_img_file)); % Load image with alpha channel

    % Convert white background to gray
    whiteBackground = imgData == 255; % Find white background
    grayBackground = repmat(reshape([128, 128, 128], 1, 1, 3), size(imgData, 1), size(imgData, 2)); % Gray background
    imgData(repmat(whiteBackground(:,:,1), [1, 1, 3])) = grayBackground(repmat(whiteBackground(:,:,1), [1, 1, 3])); % Replace white with gray
    imgData(:, :, 4) = alpha; % Add alpha channel

    faceTexture = Screen('MakeTexture', dp.wPtr, imgData);

    % image size
    imgWidth = 150; % 너비(pixel)
    imgHeight = 150; % 높이(pixel)
    faceRect = CenterRectOnPoint([0 0 imgWidth imgHeight], dp.cx, dp.cy);

    % Fill the screen with the background color to ensure transparency works
    Screen('FillRect', dp.wPtr, [128, 128, 128]);

    % Correctly draw the texture with transparency
    Screen('DrawTexture', dp.wPtr, faceTexture, [], faceRect);
    Screen('FillOval', dp.wPtr, [255, 255, 255], dotRect);
    Screen('Flip', dp.wPtr);
    WaitSecs(0.3); % 300ms

     % Extract face type information #수정 분석시 참고
    if contains(face_img_file, 'FaceF_F')
        faceType = 2; % 00
    elseif contains(face_img_file, 'FaceF_A')
        faceType = 0; % 01
    elseif contains(face_img_file, 'FaceM_F')
        faceType = 3; % 10
    elseif contains(face_img_file, 'FaceM_A')
        faceType = 1; % 11
    end

    % 6. gap 조건에 따른 Dot 표시
    if condition(3) == 0 % gap0 조건
        Screen('FillOval', dp.wPtr, [255, 255, 255], dotRect);
        Screen('Flip', dp.wPtr);
        WaitSecs(0.16); % 160ms
        Screen('Flip', dp.wPtr); % Dot 사라짐
        WaitSecs(0.2); % 200ms 빈 화면
    else % gap200 조건
        Screen('FillOval', dp.wPtr, [255, 255, 255], dotRect);
        Screen('Flip', dp.wPtr);
        WaitSecs(0.36); % 360ms
    end

    % 7. 일치/불일치 조건에 따른 타겟 Dot 표시
    targetPos = dp.cx + ((condition(2) * 2 - 1) * 7 * dp.ppd) * (condition(1) * 2 - 1); % 좌/우 타겟 위치 (큐와 타겟 방향 일치 여부에 따라)
    targetRect = CenterRectOnPoint([0 0 fixSize fixSize], targetPos, dp.cy);
    Screen('FillOval', dp.wPtr, [255, 255, 255], targetRect);
    Screen('Flip', dp.wPtr);
    startTime = GetSecs; % 타겟 Dot 표시 시간 기록

    % 반응 시간 측정
    [response, RT] = get_response(startTime);

    % 반응이 정반응인지 오반응인지 확인
    if ~isempty(response)
        if (condition(1) == 1 && condition(2) == 1 && strcmp(response, 'RightArrow')) || ...
           (condition(1) == 1 && condition(2) == 0 && strcmp(response, 'LeftArrow')) || ...
           (condition(1) == 0 && condition(2) == 1 && strcmp(response, 'LeftArrow')) || ...
           (condition(1) == 0 && condition(2) == 0 && strcmp(response, 'RightArrow'))
            responseCorrect = 1; % 정반응
        else
            responseCorrect = 0; % 오반응
        end
    else
        responseCorrect = 0; % 무반응을 오반응으로 처리
    end

    % 8. 피드백 표시
    if responseCorrect == 1 % 정답은 초록색 피드백
        make_fixation(dp, fixSize, [0, 255, 0], lineWidth);
    else % 틀리거나, 무반응은 빨간색 피드백
        make_fixation(dp, fixSize, [255, 0, 0], lineWidth);
    end
    Screen('Flip', dp.wPtr);
    WaitSecs(0.5); % 500ms 피드백 표시

    % 결과 저장
    intensity = [condition faceType]; % [cue_direction, trial_type, gap_type, facetype]
end

% 응답 시간 측정 함수 정의
function [response, RT] = get_response(startTime)
    response = '';
    RT = NaN;
    while isempty(response) && GetSecs - startTime < 1.5
        [keyIsDown, endTime, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(KbName('LeftArrow')) || keyCode(KbName('RightArrow')) || keyCode(KbName('ESCAPE'))
                RT = endTime - startTime;
                response = KbName(find(keyCode));
                break;
            end
        end
    end
end

% 함수 drawText
function drawText(dp, position, str, col)
    if nargin < 4
        col = [0 0 0]; % Default color
    end
    Screen('TextSize', dp.wPtr, 28);
    Screen('TextFont', dp.wPtr, 'Arial');
    DrawFormattedText(dp.wPtr, str, 'center', position(2), col);
end

% 함수 make_fixation
function make_fixation(dp, fixSize, color, lineWidth)
    center = [dp.cx, dp.cy];
    Screen('DrawLine', dp.wPtr, color, center(1)-fixSize, center(2), center(1)+fixSize, center(2), lineWidth);
    Screen('DrawLine', dp.wPtr, color, center(1), center(2)-fixSize, center(1), center(2)+fixSize, lineWidth);
end

% practice_trials 함수 정의
function practice_trials(dp, fixSize, color, lineWidth, nConds, nTrialType, gapType, per_invalid, faces, fMatrix, faceDir, randNumber, d)
    practice_nReps = 2; % 연습 반복 횟수
    practice_nTrials = nConds * nTrialType * gapType * practice_nReps; % 연습 트라이얼 수

    % 조건 벡터 생성
    temp1 = [zeros(practice_nTrials/nConds, 1); ones(practice_nTrials/nConds, 1)];

    num_invalid = round(practice_nTrials * per_invalid);
    num_valid = practice_nTrials - num_invalid;
    temp2 = [zeros(num_invalid, 1); ones(num_valid, 1)];
    temp2 = temp2(randperm(length(temp2))); % 무작위 섞기

    temp3 = [zeros(practice_nTrials/(nConds * gapType), 1); ones(practice_nTrials/(nConds * gapType), 1)];
    temp3 = repmat(temp3, nConds, 1); % cue 및 trial type 조건 반복

    % 조건 매트릭스 결합
    practice_cMatrix = [temp1 temp2 temp3];

    % 트라이얼 순서를 랜덤하게 섞기
    practice_randTrial = Shuffle(1:practice_nTrials);

    % 조건 매트릭스 섞기
    practice_cMatrix = practice_cMatrix(practice_randTrial, :);

    % 연습 트라이얼 루프
    for trial = 1:practice_nTrials
        show_stimulus_endogenous(dp, practice_cMatrix(trial, :), fixSize, color, lineWidth, faces, fMatrix, trial, faceDir, randNumber, d);

        % 다음 실험 전 짧은 일시정지
        WaitSecs(0.5);
    end
end
