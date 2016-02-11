% Currently a first attempt at EKG removal

function [EKGless] = removeEKG(dsEMG,dsEKG,fs)
%% Steps in EKG Removal:


EKGless = dsEMG(:,1);
r_point = 400; % attempt at finding r wave

% Mark where EKG passes above some threshold (want to avoid s wave)
r_edges = (dsEKG(:,1) > r_point);

% Copy all points above r_point. Mark breakpoints, i.e. points separated by
% more than one point (nonconsecutive -> different waves)
beats = find(r_edges > 0);
beats(2:end,2) = abs(beats(1:end-1,1)-beats(2:end,1)) > 1;
beats(1,2) = 1;

% Transform into an array with start and stop times for each beat
a = find(beats(:,2) == 1);
a(:,2) = beats(a(:,1),1);
a(1:end-1,3) = beats(a(2:end,1)-1,1);

% Introduce some padding around the beat, since it tends to be stretched
% out when seen as interference in the EMG channel
a(:,2) = a(:,2) - fs/5;
a(:,3) = a(:,3) + fs/5;

for i = 1:size(a,1)
    s = a(i,2); st = a(i,3);
    d = st - s + 1;
    
    new_sig = [EKGless(s-floor(d/2):s-1,1); EKGless(st+1:(st+d-floor(d/2)),1)];
    
    EKGless(s:st,1) = new_sig;
    EKGless(s:st,2) = 20;
end

end