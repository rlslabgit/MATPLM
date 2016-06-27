function out = validate(plms_results)
%% This just gets 1000 random samples (minus 0 epochs)

N = 1000;

starts = zeros(N,1); ends = zeros(N,1); MATPLM_PLMS = zeros(N,1); 
TECH_PLMS = zeros(N,1); ids = cell(N,1);


for i_ = 1:N
    % choose a random subject
    %id = randi(size(plms_results,2),1);
    id = 122; % just 82828_V1N2
    
    name = plms_results(id).Subject;
    MATPLM = plms_results(id).PLM5S;
    TECH = plms_results(id).techPLMS;
    
    

    epochstage = plms_results(id).epochstage;
    
    % choose a random epoch to analyze, we'll look at 3 min windows
    ep = randi(size(epochstage,1)-7,1);
    
    while sum(epochstage(ep:ep+5) > 0) < 6
        ep = randi(size(epochstage,1)-7,1);
    end
    
    start_time = (ep-1)*30*500 + 1; end_time = start_time + 3*60*500;            
    
    % select only movements in this period
    if isempty(MATPLM), MATPLM_PLMS(i_) = 0;
    else
        MATPLM = MATPLM(MATPLM(:,11) == 0,:); % ignore apnea I guess?
        MATPLM = MATPLM(MATPLM(:,1) >= start_time & MATPLM(:,2) <= end_time,:);
        MATPLM_PLMS(i_) = size(MATPLM,1);
    end
    
    if isempty(TECH), TECH_PLMS(i_) = 0;
    else
        TECH = TECH(TECH(:,1) >= start_time & TECH(:,2) <= end_time,:);
        TECH = rOV2(TECH,500);
        TECH_PLMS(i_) = size(TECH,1);
    end  

    starts(i_) = start_time; ends(i_) = end_time;        
    ids{i_} = name;
end

out = table(ids,starts,ends,MATPLM_PLMS,TECH_PLMS);
out = out(out{:,4} > 0 | out{:,5} > 0,:); % I only want to see these
%writetable(out, 'test.csv');

end



function [CLM] = rOV2(combLM,fs)
% Combine bilateral movements if they are separated by < 0.5 seconds
% distance to next movement
CLM = combLM;
i = 1;

while i < size(CLM,1)
    % make sure to check if this is correct logic for the half second
    % overlap period...
    if isempty(intersect(CLM(i,1):CLM(i,2),(CLM(i+1,1)-fs/2):CLM(i+1,2)))
        i = i+1;
    else
        CLM(i,2) = max(CLM(i,2),CLM(i+1,2));
        CLM(i+1,:) = [];
    end
end

end