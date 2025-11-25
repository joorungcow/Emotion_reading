% ================== PTB 안전 동기화 프리앰블 ==================
function sync = ptb_sync_safety_preamble()
    % 호출 위치: 실험 스크립트 최상단에서
    % 사용 예:  sync = ptb_sync_safety_preamble();

    % 깔끔 시작
    ListenChar(0);
    try sca; end
    try clear mex; end
    KbName('UnifyKeyNames');

    % 기본 로그/정책
    Screen('Preference','Verbosity', 3);
    Screen('Preference','SkipSyncTests', 0);     % 기본은 정확 모드
    Screen('Preference','VBLTimestampingMode', 0); % 보수적: beamposition 미사용
    % 필요시: 텍스트/렌더러 등은 실험 코드에서 설정

    % 진단 파라미터
    sync = struct();
    sync.trials     = 180;     % 짧은 워밍업 플립 횟수(~1.5초 @120Hz)
    sync.waitFactor = 0.7;     % when 인자 여유
    sync.maxStdMs   = 0.25;    % ifi 표준편차 허용 한계(보수적)
    sync.maxMiss    = 8;       % 미스 허용 개수
    sync.pass       = false;
    sync.modeTried  = [];

    % 내부 헬퍼: 한 번 열어 검사
    function R = one_pass(vblMode)
        Screen('Preference','VBLTimestampingMode', vblMode);
        R = struct('ok',false,'ifi',NaN,'std',NaN,'miss',NaN,'hz',NaN);
        try
            scr = max(Screen('Screens'));
            % 풀스크린(진짜 세션은 곧 닫을 것)
            [w, ~] = PsychImaging('OpenWindow', scr, 0);
            HideCursor(w);
            Priority(MaxPriority(w));

            ifi = Screen('GetFlipInterval', w);
            vbl = Screen('Flip', w);
            miss = 0; ts = zeros(sync.trials,1);

            for k = 1:sync.trials
                vbl = Screen('Flip', w, vbl + sync.waitFactor*ifi);
                ts(k) = vbl;
                % 간단 미스 추정: 목표시간 대비 지연
                if k>1
                    laten = (ts(k) - ts(k-1)) - ifi;
                    if laten > 0.5*ifi, miss = miss + 1; end
                end
            end

            % 통계
            d = diff(ts);
            R.ifi  = mean(d);
            R.std  = std(d)*1000;    % ms
            R.hz   = 1/R.ifi;
            R.miss = miss;
            R.ok   = (R.std <= sync.maxStdMs) && (miss <= sync.maxMiss);

            % 정리
            Priority(0); ShowCursor;
            sca;
        catch ME
            try, Priority(0); ShowCursor; sca; end
            fprintf('[SYNC] one_pass(%d) error: %s\n', vblMode, ME.message);
            R.ok = false;
        end
    end

    % 1차: 모드 0(보수)
    R0 = one_pass(0); sync.modeTried(end+1) = 0; %#ok<AGROW>
    fprintf('[SYNC] Mode=0 | ifi=%.6f s (%.3f Hz) | std=%.3f ms | miss=%d\n', ...
        R0.ifi, R0.hz, R0.std, R0.miss);

    if R0.ok
        sync.pass   = true;
        sync.vblMode= 0;
    else
        % 2차: 모드 1(드라이버 타임스탬프)
        R1 = one_pass(1); sync.modeTried(end+1) = 1; %#ok<AGROW>
        fprintf('[SYNC] Mode=1 | ifi=%.6f s (%.3f Hz) | std=%.3f ms | miss=%d\n', ...
            R1.ifi, R1.hz, R1.std, R1.miss);
        if R1.ok
            sync.pass   = true;
            sync.vblMode= 1;
        else
            % 최후 폴백: SkipSyncTests=1 (굵은 경고)
            Screen('Preference','SkipSyncTests', 1);
            sync.pass   = false;
            sync.vblMode= -1;
            fprintf('\n=============================================================\n');
            fprintf(' [WARNING] Stable VBL sync could not be verified (Mode 0/1)\n');
            fprintf(' → Forcing Screen(''Preference'',''SkipSyncTests'',1).\n');
            fprintf(' → 타임스탬프 신뢰도는 낮아집니다. 환경(게임모드/VRR/HAGS/오버레이) 점검 권장.\n');
            fprintf('=============================================================\n\n');
        end
    end

    % 최종 적용(실험 본문에 영향)
    if sync.vblMode >= 0
        Screen('Preference','VBLTimestampingMode', sync.vblMode);
    end
    % 실험 시작 전 다시 보장
    Screen('Preference','SkipSyncTests', double(~sync.pass));
end
% ================== /프리앰블 끝 ==================
