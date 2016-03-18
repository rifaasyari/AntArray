function patrn = genCrossoverPattern(side_lg, quant)
% Generate pattern for crossover
%
% INPUT:
%   side_lg:    side length of the 2D chromosome
%   quant:      (optional) is the chromosome quantized?
%

if nargin < 2
    quant = 1;
end;

if mod(side_lg, 2) ~= 0
    error 'side_lg is not an even number';
elseif side_lg < 4
    error 'side_lg must be greater than 4';
end;

% Theoretical size of matrix (effective elements generated)
if quant
    step = 2;
else
    step = 1;
end;

th_side = side_lg/step;
mat = zeros(th_side);
max_lgt = th_side;

% Generate theoretical pattern
prev_off = randi([2 th_side]);
prev_lgt = th_side - prev_off + 1;
mat(end, prev_off:end) = 1;
for i=1:th_side-2       
    lgt = randi(max_lgt-1);             % Length
    
    max_off = prev_off + prev_lgt - 1;  % Max offset for contiguous pattern
    max_off = min(max_lgt-lgt+1, max_off);
    
    min_off = prev_off - lgt + 1;       % Min offset for contiguous pattern
    min_off = max(min_off, 2);

    off = randi([min_off max_off]);     % Offset
    
    mat(end-i, off:off+lgt-1) = 1;
    
    prev_off = off;
    prev_lgt = lgt;
    
    % If there is a blank on both sides of the line, reduce max length
    if max_lgt == th_side && off+lgt-1 < th_side
        max_lgt = max_lgt - 1;
    end;
end;

% Quantize
if quant
    patrn = zeros(side_lg);
    mat = reshape(mat, 1, numel(mat));
    mat = repmat(mat, 2, 1);
    mat = reshape(mat, side_lg, side_lg/step);
    patrn(:, 1:2:end) = mat;
    patrn(:, 2:2:end) = mat;
else
    patrn = mat;
end;   

end