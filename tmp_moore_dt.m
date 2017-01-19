function t = tmp_moore_dt(x)
%%
% based off of Moore's variable amplitude thresholding
fs = 500; U = 8; L = 2;


% first, define the noise floor as the original sample smoothed with a
% central 20 sec window
eta = smooth(x,20*fs);

tmp = log(eta + 1);

alpha = eta .* tmp + U; clear tmp;
alpha(eta > 50) = inf;

beta = U/L * alpha;

phi = (alpha + beta)/2;

rms = sqrt(smooth(x.^2,0.15*fs));


t = table(rms, eta, alpha, beta, phi);

end