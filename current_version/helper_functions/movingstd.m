function s = movingstd(x,k,windowmode)
% movingstd: efficient windowed standard deviation of a time series
% usage: s = movingstd(x,k,windowmode)
%
% Movingstd uses filter to compute the standard deviation, using
% the trick of std = sqrt((sum(x.^2) - n*xbar.^2)/(n-1)).
% Beware that this formula can suffer from numerical problems for
% data which is large in magnitude. Your data is automatically
% centered and scaled to alleviate these problems.
%
% At the ends of the series, when filter would generate spurious
% results otherwise, the standard deviations are corrected by
% the use of shorter window lengths.
%
% arguments: (input)
%  x   - vector containing time series data
%
%  k   - size of the moving window to use (see windowmode)
%        All windowmodes adjust the window width near the ends of
%        the series as necessary.
%
%        k must be an integer, at least 1 for a 'central' window,
%        and at least 2 for 'forward' or 'backward'
%
%  windowmode - (OPTIONAL) flag, denotes the type of moving window used
%        DEFAULT: 'central'
%
%        windowmode = 'central' --> use a sliding window centered on
%            each point in the series. The window will have total width
%            of 2*k+1 points, thus k points on each side.
%        
%        windowmode = 'backward' --> use a sliding window that uses the
%            current point and looks back over a total of k points.
%        
%        windowmode = 'forward' --> use a sliding window that uses the
%            current point and looks forward over a total of k points.
%
%        Any simple contraction of the above options is valid, even
%        as short as a single character 'c', 'b', or 'f'. Case is
%        ignored.
%
% arguments: (output)
%  s   - vector containing the windowed standard deviation.
%        length(s) == length(x)

% check for a windowmode
if (nargin<3) || isempty(windowmode)
  % supply the default:
  windowmode = 'central';
elseif ~ischar(windowmode)
  error 'If supplied, windowmode must be a character flag.'
end
% check for a valid shortening.
valid = {'central' 'forward' 'backward'};
ind = find(strncmpi(windowmode,valid,length(windowmode)));
if isempty(ind)
  error 'Windowmode must be a character flag, matching the allowed modes: ''c'', ''b'', or ''f''.'
else
  windowmode = valid{ind};
end

% length of the time series
n = length(x);

% check for valid k
if (nargin<2) || isempty(k) || (rem(k,1)~=0)
  error 'k was not provided or not an integer.'
end
switch windowmode
  case 'central'
    if k<1
      error 'k must be at least 1 for windowmode = ''central''.'
    end
    if n<(2*k+1)
      error 'k is too large for this short of a series and this windowmode.'
    end
  otherwise
    if k<2
      error 'k must be at least 2 for windowmode = ''forward'' or ''backward''.'
    end
    if (n<k)
      error 'k is too large for this short of a series.'
    end
end

% Improve the numerical analysis by subtracting off the series mean
% this has no effect on the standard deviation.
x = x - mean(x);
% scale the data to have unit variance too. will put that
% scale factor back into the result at the end
xstd = std(x);
x = x./xstd;

% we will need the squared elements 
x2 = x.^2;

% split into the three windowmode cases for simplicity
A = 1;
switch windowmode
  case 'central'
    B = ones(1,2*k+1);
    s = sqrt((filter(B,A,x2) - (filter(B,A,x).^2)*(1/(2*k+1)))/(2*k));
    s(k:(n-k)) = s((2*k):end);
  case 'forward'
    B = ones(1,k);
    s = sqrt((filter(B,A,x2) - (filter(B,A,x).^2)*(1/k))/(k-1));
    s(1:(n-k+1)) = s(k:end);
  case 'backward'
    B = ones(1,k);
    s = sqrt((filter(B,A,x2) - (filter(B,A,x).^2)*(1/k))/(k-1));
end

% special case the ends as appropriate
switch windowmode
  case 'central'
    % repairs are needed at both ends
    for i = 1:k
      s(i) = std(x(1:(k+i)));
      s(n-k+i) = std(x((n-2*k+i):n));
    end
  case 'forward'
    % the last k elements must be repaired
    for i = (k-1):-1:1
      s(n-i+1) = std(x((n-i+1):n));
    end
  case 'backward'
    % the first k elements must be repaired
    for i = 1:(k-1)
      s(i) = std(x(1:i));
    end
end

% catch any complex std elements due to numerical precision issues.
% anything that came out with a non-zero imaginary part is
% indistinguishable from zero, so make it so.
s(imag(s) ~= 0) = 0;

% restore the scale factor that was used before to normalize the data
s = s.*xstd;


% Copyright (c) 2014, John D'Errico
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

