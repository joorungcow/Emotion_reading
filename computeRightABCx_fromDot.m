function rightX = computeRightABCx_fromDot(w, sentence, textLeftX, dp, cmOffset, outerDeg)
% sentence: string/char/uint8(UTF-8) 아무거나 허용
% cmOffset: 온점 뒤 오프셋(cm) — 예: 3
% outerDeg: ABC 바깥원 지름(도) — 예: 0.84

    % 0) 입력 정규화 → UTF-8 바이트
    if isa(sentence, 'uint8')
        sUTF8 = sentence;
        sStr  = char(native2unicode(sentence,'UTF-8'));
    else
        sStr  = char(sentence);
        sUTF8 = uint8(unicode2native(sStr,'UTF-8'));
    end

    % 1) 픽셀-변환계수
    ppcX   = dp.resolution(1) / dp.width;      % px/cm  (가로)
    padPx  = round((outerDeg * dp.ppd) / 2);   % ABC 반지름(px)
    margin = 5;                                % 우측 안전 여백(px)

    % 2) 온점 위치 찾기(마지막 '.'을 기준)
    idxDot = find(sStr=='.', 1, 'last');

    % 3) 텍스트 폭 측정
    if isempty(idxDot)
        % 온점이 없으면 전체 문장 오른쪽 끝을 기준
        tbAll = Screen('TextBounds', w, sUTF8);
        xDot  = textLeftX + (tbAll(3) - tbAll(1));
    else
        subsU8 = uint8(unicode2native(sStr(1:idxDot), 'UTF-8'));
        tbDot  = Screen('TextBounds', w, subsU8);
        xDot   = textLeftX + (tbDot(3) - tbDot(1));
    end

    % 4) 3cm 오프셋 + 경계 클램프
    xRaw     = xDot + round(cmOffset * ppcX);
    rightMax = dp.resolution(1) - (padPx + margin);
    rightMin = 1 + padPx + margin;
    rightX   = min(max(rightMin, xRaw), rightMax);
end
