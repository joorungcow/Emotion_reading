function abortDueToEyelink(reasonTag, humanMsg, dirname, edfFile, dummymode, w, bgColor, pickedFont, pickedRenderer)
    % 1) 안내 문구 화면에 띄우기
    try
        if exist('w','var') && ~isempty(w) && Screen('WindowKind', w) > 0
            Screen('Preference','TextEncodingLocale','UTF-8');
            Screen('Preference','TextRenderer', pickedRenderer);
            Screen('TextFont',  w, pickedFont);
            Screen('TextSize',  w, 40);
            Screen('TextStyle', w, 0);

            u8 = @(s) uint8(unicode2native(s,'UTF-8'));
            Screen('FillRect', w, bgColor);
            DrawFormattedText(w, u8(humanMsg), 'center','center', [0 0 0], 60, [], [], 1.4);
            Screen('Flip', w);
            WaitSecs(3.0);
        end
    catch
        % 화면 관련 에러는 무시하고 계속 진행
    end

    % 2) EDF 닫고 받기 (실모드에서만)
    if exist('dummymode','var') && dummymode == 0
        try Eyelink('Message', reasonTag); end
        try
            Eyelink('SetOfflineMode'); WaitSecs(0.3);
        end
        try
            Eyelink('CloseFile');
        end
        try
            filetransfer(dirname, edfFile, dummymode);
        catch
            % EDF 받기 실패해도 여기서 크래시 나지 않게
        end
    end

    % 3) 강제 종료 (위쪽 try-catch로 올라가게)
    error('[EL-ABORT] %s', reasonTag);
end
