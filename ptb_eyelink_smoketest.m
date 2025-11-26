function ptb_eyelink_smoketest

    ListenChar(0);
    try, KbQueueRelease(-1); end
    try, Eyelink('Shutdown'); end
    Screen('CloseAll'); ShowCursor; Priority(0);

    % --- 기본 PTB 윈도우 열기 ---
    AssertOpenGL;
    Screen('Preference', 'SkipSyncTests', 1);  % 테스트용
    [w, rect] = Screen('OpenWindow', max(Screen('Screens')), 127);
    HideCursor;

    % --- Eyelink 초기화 ---
    el = EyelinkInitDefaults(w);
    if ~EyelinkInit(0, 1)
        Eyelink('Shutdown');
        Screen('CloseAll');
        error('EyelinkInit failed');
    end

    Eyelink('OpenFile','TEST');
    EyelinkDoTrackerSetup(el);  % 캘리브레이션 화면

    % --- 드리프트 코렉션 한 번만 ---
    EyelinkDoDriftCorrection(el, rect(3)/2, rect(4)/2, 1, 1);

    % --- 기록 시작/정지 ---
    Eyelink('StartRecording');
    WaitSecs(1);
    Eyelink('Stoprecording');

    Eyelink('CloseFile');
    Eyelink('ReceiveFile','TEST');
    Eyelink('Shutdown');
    Screen('CloseAll');
    ShowCursor; Priority(0);
end
