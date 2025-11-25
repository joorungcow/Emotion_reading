function kb = init_keyboard(config)
% Setup universal Mac/PC keyboard and keynames to OSX naming scheme
%INIT_KEYBOARD  PTB 키보드 초기화(메인 스크립트 호환)
% - 기본: KbCheck(폴링) 사용, 관심 키만 제한(원복 핸들 포함)
% - 옵션: KbQueue* 사용 가능 (config.useKbQueueCheck = true)
%
% 필드: escKey, spaceKey, aKey, lKey, recalKey
% 메서드 핸들: kb.check(), kb.flush(), kb.release()

% ---- 입력 가드 & 기본값 ----
if nargin<1 || ~isstruct(config), config = struct; end
if ~isfield(config,'useKbQueueCheck'), config.useKbQueueCheck = false; end
if ~isfield(config,'deviceIndex'),     config.deviceIndex     = [];    end
if ~isfield(config,'restrict'),        config.restrict        = true;  end

KbName('UnifyKeyNames');

% --- 5키 고정 매핑 ---
kb.escKey    = KbName('ESCAPE');
kb.spaceKey  = KbName('space');
kb.aKey      = KbName('a');
kb.lKey      = KbName('l');
kb.recalKey  = KbName('r');

% === Initialize Keyboards (classic style) ===
keys = [kb.escKey, kb.spaceKey, kb.aKey, kb.lKey, kb.recalKey];

if ~config.useKbQueueCheck
    % ---- 폴링 모드 ----
    [kb.keyIsDown, kb.secs, kb.keyCode] = KbCheck(-1); %#ok<ASGLU>
    if config.restrict
        kb.oldEnable = RestrictKeysForKbCheck(keys);   % 제한 걸기
        kb.release   = @() RestrictKeysForKbCheck([]); % 제한 해제 함수
    else
        kb.oldEnable = [];
        kb.release   = @() [];
    end
    kb.check = @() KbCheck(-1);
    kb.flush = @() [];
else
    % ---- 큐 모드 ----
    kb.devices = PsychHID('Devices'); %#ok<NASGU>

    [~, ~, kc0] = KbCheck(-1);
    % FIX: keyFlags는 double, 길이는 KbMaxNumberOfKeys
    names = KbName('KeyNames');      % cellstr of all key names for this OS
    nKeys = numel(names);            % 총 키 개수(큐 플래그 벡터 길이)
    keyFlags = zeros(1, nKeys);
    keyIdx   = [kb.escKey, kb.spaceKey, kb.aKey, kb.lKey, kb.recalKey];
    keyIdx   = keyIdx(keyIdx>=1 & keyIdx<=nKeys);   % 안전 가드
    keyFlags(keyIdx) = 1;

    if isempty(config.deviceIndex), deviceNumber = -1; else, deviceNumber = config.deviceIndex; end

    % ===== 여기부터 "열렸는지 로그" 추가 =====
    try
        % 선택된 장치 정보(이름/usage) 한 줄 출력
        try
            devs = PsychHID('Devices');
            if deviceNumber >= 0
                di = devs([devs.index] == deviceNumber);
                if ~isempty(di)
                    fprintf('[KBQUEUE] device=%d | usage=%d(%s) | %s %s\n', ...
                        deviceNumber, di.usage, string(di.usageName), string(di.manufacturer), string(di.product));
                else
                    fprintf('[KBQUEUE] device=%d (목록에서 못 찾음)\n', deviceNumber);
                end
            else
                fprintf('[KBQUEUE] device=-1 (모든 키보드 장치)\n');
            end
        catch
            fprintf('[KBQUEUE] 장치 메타정보 조회 실패(무시)\n');
        end

        % 큐 생성/시작/플러시 + 상태 로그
        KbQueueCreate(deviceNumber, keyFlags);
        KbQueueStart(deviceNumber);
        KbQueueFlush(deviceNumber);
        fprintf('[KBQUEUE] START OK | dev=%d | flagsLen=%d | keys=%s\n', ...
            deviceNumber, numel(keyFlags), mat2str(find(keyFlags)));

        % 100ms 동안 이벤트가 오나 즉석 점검
        t0 = GetSecs;
        seen = false;
        while GetSecs - t0 < 0.1
            [pressed, firstPress] = KbQueueCheck(deviceNumber);
            if pressed && any(firstPress)
                fprintf('[KBQUEUE] TEST EVENT SEEN at %.4f (sec)\n', GetSecs - t0);
                seen = true; break;
            end
            WaitSecs(0.01);
        end
        if ~seen
            fprintf('[KBQUEUE] TEST EVENT none in 100 ms (정상일 수 있음)\n');
        end

    catch ME
        warning('[KBQUEUE] FAIL dev=%d → %s', deviceNumber, ME.message);
    end

    kb.check   = @() KbQueueCheck(deviceNumber);
    kb.flush   = @() KbQueueFlush(deviceNumber);
    kb.release = @() KbQueueRelease(deviceNumber);
end

% ---- (추가) 유틸 함수 핸들: 대기/제한 ----
kb.wait = @(names,timeout) local_wait(names,timeout,config.useKbQueueCheck,config.deviceIndex);
kb.only = @(names)         local_only(names,config.useKbQueueCheck,config.deviceIndex);
kb.clear= @()              local_clear(config.useKbQueueCheck,config.deviceIndex);
kb.debounce = @() local_debounce();

% Initialize Sound
InitializePsychSound;
end

% ================== 로컬 유틸 ==================
function [name,t,keyCode] = local_wait(names,timeout,useQueue,dev)
if nargin<2 || isempty(timeout), timeout = inf; end
tgt = cellstr(string(names)); tgtCodes = KbName(tgt);
if isempty(dev), dev = -1; end

if useQueue
    KbQueueFlush(dev);
    t0 = GetSecs;
    while GetSecs - t0 < timeout
        [pressed, firstPress] = KbQueueCheck(dev);
        if pressed
            fp = firstPress(tgtCodes);
            if any(fp>0)
                hit = find(fp>0,1,'first');
                name = string(tgt{hit}); t = fp(hit); keyCode = firstPress>0; return
            end
        end
        WaitSecs(0.005);
    end
else
    t0 = GetSecs;
    while GetSecs - t0 < timeout
        [down,tNow,kc] = KbCheck(-1);
        if down && any(kc(tgtCodes))
            hit = find(kc(tgtCodes),1,'first');
            name = string(tgt{hit}); t = tNow; keyCode = kc; return
        end
        WaitSecs(0.005);
    end
end
name = ""; t = NaN; keyCode = [];
end

function local_only(names,useQueue,dev)
tgt = cellstr(string(names));
tgtCodes = KbName(tgt);
if isempty(dev), dev = -1; end

if useQueue
    try KbQueueRelease(dev); catch, end

    [~, ~, kc0] = KbCheck(-1);
    nKeys = numel(kc0);

     % double 벡터로 key flags 구성
    flags = zeros(1, nKeys);                       % double
    tgtCodes = tgtCodes(tgtCodes>=1 & tgtCodes<=nKeys);
    tgtCodes = unique(tgtCodes);
    flags(tgtCodes) = 1;

    KbQueueCreate(dev, flags);
    KbQueueStart(dev);
    KbQueueFlush(dev);
else
    RestrictKeysForKbCheck(tgtCodes);
end
end

function local_clear(useQueue,dev)
if isempty(dev), dev = -1; end
if useQueue, KbQueueFlush(dev); else, RestrictKeysForKbCheck([]); end
end

function local_debounce()
% Debounce just our target keys, robust to user-abort, with a time cap.
% 대상 키: ESCAPE, space, a, l, r

    KbName('UnifyKeyNames');
    tgtCodes = unique(KbName({'ESCAPE','space','a','l','r'}));  % 5-key only

    dev    = -1;     % all devices
    quiet  = 0.12;   % need 120 ms of no target-key activity
    settle = 0.03;   % short post-stabilization
    cap    = 0.8;    % hard cap: never wait > 0.8 s

    tQuietStart = NaN;
    t0 = GetSecs;

    while true
        % --- KbCheck with abort-robustness ---
        try
            [~, ~, kc] = KbCheck(dev);
        catch ME
            if contains(ME.message,'Aborted','IgnoreCase',true) || ...
               contains(ME.message,'terminated by user','IgnoreCase',true)
                % brief backoff then continue
                WaitSecs(0.05);
                tQuietStart = NaN;  % reset quiet timer
                t0 = GetSecs;
                continue;
            else
                rethrow(ME);
            end
        end

        % target 키들만 관심: 나머지 눌림은 무시
        if any(kc(tgtCodes))
            tQuietStart = NaN;  % 키 눌림 → 타이머 리셋
        else
            if isnan(tQuietStart), tQuietStart = GetSecs; end
            if (GetSecs - tQuietStart) >= quiet
                break;          % 충분히 조용했다 → 통과
            end
        end

        % 안전장치: 최대 cap 시간 지나면 그냥 통과
        if (GetSecs - t0) > cap
            break;
        end

        % 짧은 휴식
        WaitSecs(0.01);
    end

    % 최종 안정화
    WaitSecs(settle);
end
