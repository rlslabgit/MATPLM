function [qrspeaks, locs] = bullshit_EKGpeaks(ecgsig,fs)

ecg_sig = downsample(ecg_sig, fs/50); % downsample to 50 hz
thresh = prctile(ecg_sig, 98);
ecg_sig = ecg_sig/thresh;
ecg_sig = ecg_sig.^2; % hopfully this will attenuate s wave

ecg_sig(:,2) = nan;
ecg_sig(ecg_sig


end