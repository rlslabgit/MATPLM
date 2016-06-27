function out = validate2(plms_results)
%% This gets 2 NREM and 2 REM from each subject (except 0 rows)

N = 4; % get 2 samples from each subject
epoch = 180*500; % 3 minute epochs
num_subs = size(plms_results,2);

starts = []; ends = [];
MATPLM_PLMS = [];
TECH_PLMS = [];
ids = {}; REM_NREM = {};


for id = 1:num_subs
    name = plms_results(id).Subject;
    MATPLM = plms_results(id).PLM5S;
    TECH = plms_results(id).techPLMS;
    epochstage = plms_results(id).epochstage;
    
    % only night 1 has apnea data!
    if strcmp(name(end),'1'), MATPLM = MATPLM(MATPLM(:,11) == 0, :); end
    
    nonrem = 0;
    while nonrem < N
        ep = randi(size(epochstage,1)-7,1);
        MATPLMi = []; TECHi = [];
        
        looooping = 0;
        
        % we want NREM sleep
        while sum(epochstage(ep:ep+5) ~= 2 & epochstage(ep:ep+5) ~= 0) < 6 ...
                && looooping < 1000
            ep = randi(size(epochstage,1)-7,1);
            looooping = looooping + 1;
        end
        if looooping >= 1000, nonrem = 9999;
        else
            start_time = (ep-1)*30*500 + 1; end_time = start_time + epoch;
            % select PLM during the specified period
            if isempty(MATPLM), MATPLM_PLMS = [MATPLM_PLMS ; 0];
            else
                MATPLMi = MATPLM(MATPLM(:,1) >= start_time & MATPLM(:,2) <= end_time,:);
                MATPLM_PLMS = [MATPLM_PLMS ; size(MATPLMi,1)];
            end
            if isempty(TECH), TECH_PLMS = [TECH_PLMS ; 0];
            else
                TECHi = TECH(TECH(:,1) >= start_time & TECH(:,2) <= end_time,:);
                % TECH = rOV2(TECH,500); % not gonna do this, just exclude
                TECH_PLMS = [TECH_PLMS ; size(TECHi,1)];
            end
            nonrem = nonrem + 1;
            starts = [starts ; start_time]; ends = [ends ; end_time];
            ids = [ids ; name]; REM_NREM = [REM_NREM ; 'NREM'];              
        end
    end % end NREM acquisition
    
    rem = 0;
    while rem < N
        ep = randi(size(epochstage,1)-7,1);
        MATPLMi = []; TECHi = [];
        
        looooping = 0;
        
        % we want NREM sleep
        while sum(epochstage(ep:ep+5) ~= 2 & epochstage(ep:ep+5) ~= 0) < 6 ...
                && looooping < 1000
            ep = randi(size(epochstage,1)-7,1);
            looooping = looooping + 1;
        end
        
        if looooping >= 1000, rem = 9999;
        else
            % we want REM sleep
            while sum(epochstage(ep:ep+5) == 5) < 6
                ep = randi(size(epochstage,1)-7,1);
            end
            start_time = (ep-1)*30*500 + 1; end_time = start_time + epoch;
            % select PLM during the specified period
            if isempty(MATPLM), MATPLM_PLMS = [MATPLM_PLMS ; 0];
            else
                MATPLMi = MATPLM(MATPLM(:,1) >= start_time & MATPLM(:,2) <= end_time,:);
                MATPLM_PLMS = [MATPLM_PLMS ; size(MATPLMi,1)];
            end
            if isempty(TECH), TECH_PLMS = [TECH_PLMS ; 0];
            else
                TECHi = TECH(TECH(:,1) >= start_time & TECH(:,2) <= end_time,:);
                % TECH = rOV2(TECH,500); % not gonna do this, just exclude
                TECH_PLMS = [TECH_PLMS ; size(TECHi,1)];
            end
            rem = rem + 1;
            starts = [starts ; start_time]; ends = [ends ; end_time];
            ids = [ids ; name]; REM_NREM = [REM_NREM ; 'REM'];
        end
    end % end NREM acquisition
    
    
end


out = table(ids,starts,ends,REM_NREM,MATPLM_PLMS,TECH_PLMS);
out = out(out{:,5} > 0 | out{:,6} > 0,:); % I only want to see these


end

