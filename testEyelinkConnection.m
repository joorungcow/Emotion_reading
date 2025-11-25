function testEyelinkConnection_sane()
    % ---- 기본 설정 ----
    AssertOpenGL;
    ListenChar(0);
    sca; clear mex;

    % PTB 로그/싱크 설정 (필요시 조절)
    Screen('Preference','SkipSyncTests', 0);   % 0=정상 체크, 1/2=우회
    Screen('Preference','Verbosity', 3);

    % ---- Eyelink 초기화 ----
    elOk = EyelinkInit(false, 1);              % dummy=false, verbose=1
    assert(elOk==1, 'EyelinkInit failed');
    Eyelink('Openfile','test.edf');

    % ---- 화면 오픈 ----
    PsychDefaultSetup(2);
    scr = max(Screen('Screens'));
    [win, rect] = PsychImaging('OpenWindow', scr, 0); %#ok<ASGLU>
    ifi = Screen('GetFlipInterval', win);
    Priority(MaxPriority(win));
    HideCursor(win);

    % ---- 워밍업 플립 ----
    vbl = Screen('Flip', win);
    nWarm = round(1.5/ifi);
    for i=1:nWarm
        vbl = Screen('Flip', win, vbl + 0.7*ifi);
    end

    % ---- 드로잉 루프 (3초) ----
    tEnd = GetSecs + 3;

    % 사각형을 화면 중앙에 배치
    baseRect = [0 0 200 200];
    [cx, cy] = RectCenter(rect);                         % << 중요: 두 출력값 받기
    dstRect  = CenterRectOnPointd(baseRect, cx, cy);

    try
        while GetSecs < tEnd
            Screen('FillRect', win, 255, dstRect);
            vbl = Screen('Flip', win, vbl + 0.7*ifi);
        end
    catch ME
        % 에러 시에도 정리 보장
        Eyelink('CloseFile'); Eyelink('Shutdown');
        Priority(0); sca; ShowCursor;
        rethrow(ME);
    end

    % ---- 정리 ----
    Eyelink('CloseFile');
    Eyelink('Shutdown');
    Priority(0);
    sca;
    ShowCursor;
end
