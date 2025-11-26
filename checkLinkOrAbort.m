function checkLinkOrAbort(stage, trialTag, dirname, edfFile, dummymode, w, bgColor, pickedFont, pickedRenderer)
    if dummymode ~= 0
        return;  % 더미 모드는 그냥 통과
    end

    % 1차: 현재 링크 상태 확인
    try
        isConn = Eyelink('IsConnected');
    catch
        isConn = 0;
    end

    if isConn == 1
        return;  % 아직 연결 살아 있으면 그냥 진행
    end

    fprintf('[EL] Link LOST at %s (%s). Trying to reconnect...\n', stage, trialTag);

    % 재연결 시도 (기존 세션 위에 다시 init)
    ok = EyelinkInit(0);
    pause(0.2);
    try
        isConn2 = Eyelink('IsConnected');
    catch
        isConn2 = 0;
    end

    if ok && isConn2 == 1
        % 재연결은 됐지만, 데이터 일관성 위해 여기서도 종료하는 쪽이 안전
        fprintf('[EL] Reconnected at %s (%s), but aborting for data safety.\n', stage, trialTag);
        humanMsg = sprintf(['실험 도중 EyeLink 연결이 잠시 끊겼다가 다시 연결되었습니다.\n' ...
                            '데이터 안정성을 위해 이 세션은 여기서 종료합니다.\n' ...
                            '실험자를 불러주시고, 필요하면 처음부터 다시 시작해주세요.\n\n' ...
                            '(단계: %s, trial: %s)'], stage, trialTag);
        abortDueToEyelink('RECONNECTED_ABORT', humanMsg, dirname, edfFile, dummymode, w, bgColor, pickedFont, pickedRenderer);
    else
        % 재연결도 실패 → 즉시 종료
        fprintf('[EL] Reconnect FAILED at %s (%s). Aborting.\n', stage, trialTag);
        humanMsg = sprintf(['EyeLink와의 연결이 중간에 끊어졌고,\n' ...
                            '재연결에도 실패했습니다.\n' ...
                            '지금까지의 데이터는 가능한 범위에서 저장하고 실험을 종료합니다.\n\n' ...
                            '(단계: %s, trial: %s)'], stage, trialTag);
        abortDueToEyelink('LINK_LOST_ABORT', humanMsg, dirname, edfFile, dummymode, w, bgColor, pickedFont, pickedRenderer);
    end
end
