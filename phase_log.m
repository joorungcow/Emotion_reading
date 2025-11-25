function phase_log(when, name, varargin)
% when: 'BEGIN' or 'END'
% name : phase name (e.g., 'LEFT_DWELL','RIGHT_DWELL','PROMPT_WAIT')
% varargin: key,val,key,val... 형태(옵션)

    try
        extra = '';
        if ~isempty(varargin)
            try
                pairs = strings(1, numel(varargin)/2);
                p = 1;
                for k = 1:2:numel(varargin)
                    key = string(varargin{k});
                    val = "";
                    if k+1 <= numel(varargin)
                        v = varargin{k+1};
                        if isnumeric(v), val = num2str(v);
                        elseif isstring(v) || ischar(v), val = char(v);
                        else, val = '<obj>';
                        end
                    end
                    pairs(p) = key + "=" + val; p = p + 1;
                end
                extra = " | " + strjoin(pairs, ', ');
            catch
                kv = strings(1, numel(varargin));
                for i=1:numel(varargin), kv(i) = string(varargin{i}); end
                extra = " | " + strjoin(kv, ', ');
            end
        end
        fprintf('[PHASE] %s %s%s @%.3f\n', upper(when), string(name), extra, GetSecs);

        try
            if Eyelink('IsConnected') == 1
                msg = sprintf('PHASE_%s %s%s', upper(when), string(name), strrep(extra, ' | ', ' '));
                Eyelink('Message', msg);
            end
        catch
        end
    catch
        % 로깅 실패해도 실험은 계속 진행
    end
end
