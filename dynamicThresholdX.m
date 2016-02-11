function [ndsEMG,threshes,minT,badEps] = dynamicThresholdX(dsEMG,fs)
%% Normalize dsEMG signal to a common baseline
% [dsEMG,threshes] = dynamicThreshold2(dsEMG,fs);
%
% dynamicThreshold2 is an attempt at normalizing the dsEMG vector to a
% baseline noise level of 2 \mu v. It loops through epochs of size
% bigWindow and finds all points that are below 5 standard deviations above
% the mean of the surrounding littleWindow # of points. The threshold for
% which the most values lie below that value is regarded as the baseline,
% and the bigWindow is normalized using the factor minT/baseline.
%
% Inputs: 
%   dsEMG - filtered and rectified EMG signal
%   fs - sampling rate
%
% Outputs:
%   dsEMG - normalized dsEMG signal
%   threshes - thresholds calculated at each bigWindow
%   minT - value the signal is normalized to. 


bigWindow = 15*fs; littleWindow = (0.1)*fs+1; 

threshes = zeros(floor(size(dsEMG,1)/bigWindow),1);
badEps = []; % epoch numbers (in bigWindow epochs) of noisey signal
ndsEMG = dsEMG * 0;


% Calculate our max allowable value: 5 standard deviations above the mean
% of the central 1/2 second long window
s = movingstd(dsEMG,littleWindow,'central')*5;
dsEMG(:,2) = smooth(dsEMG(:,1),littleWindow) + s;
clear s; 

% Let's try rounding this for now, it's easier than binning.
% dsEMG(:,2) = round(dsEMG(:,2));

% Set the minimum threshold to the baseline of the first epoch

% minT = scanning3(dsEMG(1:20*fs,:),2);


% Loop through bigWindows
for n = 0:(floor(size(dsEMG,1)/bigWindow)-1)        
    % Calculate baseline of this bigWindow and save for later adjustment
    % The hard-coded 2 means don't set a baseline less than 2
    threshes(n+1) = scanning3(dsEMG(n*bigWindow+1:(n+1)*bigWindow,:),2); 
end

% Instead of first epoch, try the mode?
minT = mode(threshes);
threshes(threshes < minT) = minT;


% Apply scaling factor to each section of the dsEMG

for i = 1:size(threshes,1)-1
    % NEW STANDARDS (if > 16 above noise, ignore)
    if threshes(i) > (minT + 16)
        ndsEMG(bigWindow*(i-1)+1:bigWindow*i,1) = ...
            ones(size(bigWindow*(i-1)+1:bigWindow*i,2),1) * minT;
        threshes(i) = -1; % mark this a bad epoch
        badEps = [badEps ; i]; %#ok<AGROW>
    else
        ndsEMG(bigWindow*(i-1)+1:bigWindow*i)...
            = dsEMG(bigWindow*(i-1)+1:bigWindow*i) * minT / threshes(i);
    end
end

ndsEMG(size(threshes,1)*bigWindow:end)...
        = dsEMG(size(threshes,1)*bigWindow:end,1) * minT / threshes(end);
        

end


% Find the baseline of a bigWindow epoch
function baseline = scanning3(dsEMG,minT)

% h = dsEMG(dsEMG(:,2) > dsEMG(:,1),2);

% The ol' histogram try
% g = histc(h,0:2:300);
% [~,b] = max(g);
% 
% if b > minT
%     baseline = mode(h);
%     baseline = b;
% else
%     baseline = minT;
% end

% Rounded mode
% baseline = mode(h);

% Longest run
tol = 2;
ds = abs(diff(dsEMG(:,2)));
ds = ds < tol;

A = findseq(+ds);
if isempty(A) %|| max(A(:,4),1) == 0 % seen when device unplugged. Ignore this section
    baseline = minT + 100;
else
    indx = find(A(:,4) == max(A(:,4)));
    baseline = floor(median(dsEMG(A(indx,2)+1:A(indx,3),2)));
    if baseline < minT
        baseline = minT;
    end
    % baseline = A(find(A(:,4) == max(A(:,4)),1));
end

end
   

function varargout = findseq(A,dim)

% FINDSEQ Find sequences of repeated (adjacent/consecutive) numeric values
%
%   FINDSEQ(A) Find sequences of repeated numeric values in A along the
%              first non-singleton dimension. A should be numeric.
%
%   FINDSEQ(...,DIM) Look for sequences along the dimension specified by the 
%                    positive integer scalar DIM.
%
%   OUT = findseq(...)
%       OUT is a "m by 4" numeric matrix where m is the number of sequences found.
%       
%       Each sequence has 4 columns where:
%           - 1st col.:  the value being repeated
%           - 2nd col.:  the position of the first value of the sequence
%           - 3rd col.:  the position of the last value of the sequence
%           - 4th col.:  the length of the sequence
%       
%   [VALUES, INPOS, FIPOS, LEN] = findseq(...)
%       Get OUT as separate outputs. 
%
%       If no sequences are found no value is returned.
%       To convert positions into subs/coordinates use IND2SUB
%
% 
% Examples:
%
%     % There are sequences of 20s, 1s and NaNs (column-wise)
%     A   =  [  20,  19,   3,   2, NaN, NaN
%               20,  23,   1,   1,   1, NaN
%               20,   7,   7, NaN,   1, NaN]
%
%     OUT = findseq(A)
%     OUT =  
%            20        1          3        3
%             1       14         15        2
%           NaN       16         18        3
%     
%     % 3D sequences: NaN, 6 and 0
%     A        = [  1, 4
%                 NaN, 5
%                   3, 6];
%     A(:,:,2) = [  0, 0
%                 NaN, 0
%                   0, 6];
%     A(:,:,3) = [  1, 0
%                   2, 5
%                   3, 6];
%     
%     OUT = findseq(A,3)
%     OUT = 
%             6     6    18     3
%             0    10    16     2
%           NaN     2     8     2
%
% Additional features:
% - <a href="matlab: web('http://www.mathworks.com/matlabcentral/fileexchange/28113','-browser')">FEX findseq page</a>
% - <a href="matlab: web('http://www.mathworks.com/matlabcentral/fileexchange/6436','-browser')">FEX rude by us page</a>
%
% See also: DIFF, FIND, SUB2IND, IND2SUB

% Author: Oleg Komarov (oleg.komarov@hotmail.it) 
% Tested on R14SP3 (7.1) and on R2012a. In-between compatibility is assumed.
% 02 jul 2010 - Created
% 05 jul 2010 - Reorganized code and fixed bug when concatenating results
% 12 jul 2010 - Per Xiaohu's suggestion fixed bug in output dimensions when A is row vector
% 26 aug 2010 - Cast double on logical instead of single
% 28 aug 2010 - Per Zachary Danziger's suggestion reorganized check structure to avoid bug when concatenating results
% 22 mar 2012 - Per Herbert Gsenger's suggestion fixed bug in matching initial and final positions; minor change to distribution of OUT if multiple outputs; added 3D example 
% 08 nov 2013 - Fixed major bug in the sorting of Final position that relied on regularity conditions not always verified

% NINPUTS
error(nargchk(1,2,nargin));

% NOUTPUTS
error(nargoutchk(0,4,nargout));

% IN
if ~isnumeric(A)
    error('findseq:fmtA', 'A should be numeric')
elseif isempty(A) || isscalar(A)
    varargout{1} = [];
    return
elseif islogical(A)
    A = double(A);
end

% DIM
szA = size(A);
if nargin == 1 || isempty(dim)
    % First non singleton dimension
    dim = find(szA ~= 1,1,'first');
elseif ~(isnumeric(dim) && dim > 0 && rem(dim,1) == 0) || dim > numel(szA)
    error('findseq:fmtDim', 'DIM should be a scalar positive integer <= ndims(A)');
end

% Less than two elements along DIM
if szA(dim) == 1
    varargout{1} = [];
    return
end

% ISVECTOR
if nnz(szA ~= 1) == 1
    A = A(:);
    dim = 1;
    szA = size(A);
end

% Detect 0, NaN, Inf and -Inf
OtherValues    = cell(1,4);
OtherValues{1} = A ==    0;
OtherValues{2} = isnan(A) ;
OtherValues{3} = A ==  Inf;
OtherValues{4} = A == -Inf;
Values         = [0,NaN, Inf,-Inf];

% Remove zeros
A(OtherValues{1}) = NaN;                             

% Make the bread
bread = NaN([szA(1:dim-1),1,szA(dim+1:end)]);

% [1] Get chunks of "normal" values
Out = mainengine(A,bread,dim,szA);

% [2] Get chunks of 0, NaN, Inf and -Inf
for c = 1:4
    if nnz(OtherValues{c}) > 1
        % Logical to double and NaN padding
        OtherValues{c} = double(OtherValues{c});                        
        OtherValues{c}(~OtherValues{c}) = NaN;                          
        % Call mainengine and concatenate results
        tmp = mainengine(OtherValues{c}, bread,dim,szA);
        if ~isempty(tmp)
            Out = [Out; [repmat(Values(c),size(tmp,1),1) tmp(:,2:end)]];  %#ok
        end
    end
end

% Distribute output
if nargout < 2 
    varargout = {Out};
else
    varargout = num2cell(Out(:,1:nargout),1);
end

end

% MAINENGINE This functions uses run length encoding and retrieve positions 
function Out = mainengine(meat,bread,dim,szMeat)

% Make a sandwich  
sandwich    = cat(dim, bread, meat, bread);

% Find chunks (run length encoding engine)
IDX         = diff(diff(sandwich,[],dim) == 0,[],dim);

% Initial and final row/col subscripts
[rIn, cIn]  = find(IDX  ==  1);
[rFi, cFi]  = find(IDX  == -1);

% Make sure row/col subs correspond (relevant if dim > 1)
[In, idx]   = sortrows([rIn, cIn],1);
Fi          = [rFi, cFi];
Fi          = Fi(idx,:);

% Calculate length of blocks
if dim < 3
    Le = Fi(:,dim) - In(:,dim) + 1;
else
    md = prod(szMeat(2:dim-1));
    Le = (Fi(:,2) - In(:,2))/md + 1;
end

% Convert to linear index
InPos       = sub2ind(szMeat,In(:,1),In(:,2));
FiPos       = sub2ind(szMeat,Fi(:,1),Fi(:,2));

% Assign output
Out         = [meat(InPos),...    % Values
               InPos      ,...    % Initial positions 
               FiPos      ,...    % Final   positions
               Le         ];      % Length of the blocks
end

