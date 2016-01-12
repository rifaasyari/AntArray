clear

if verLessThan('matlab','8.2')
    matlabpool open
else
    poolobj = parpool;
end;

% Uniform
% Init
sizes = 60;
arr = AntArray(zeros(sizes), 60500, [], 0.84);
arr = arr.setName(['fullx' mat2str(sizes)]);
arr = arr.setMax('XY', 30);
arr = arr.setMax('YZ', 30);
arr = arr.setMax('E', 25);
arr = arr.setMin('XY', -60);
arr = arr.setMin('YZ', -60);
arr = arr.setMin('E', -15);

% Create elements' pattern
arr = arr.adaptArray(ones(sizes), 90000, 0, 0);

arr = arr.setComments(sprintf('Elements spacing: 0.84$\\lambda$'));

% Plots
arr.plotAntArray();
for ang=0:pi/12:pi/2
    fprintf(['Current angle: ' rats(ang/pi) '$\\pi$']);
    arr = arr.genPattern(11000, 3000, 'theta', 30, ang);
    arr = arr.genPattern([], [], 'theta-BW', [], ang);
end;


% Triangles
for rem_els=9
    % Init
    arr = AntArray(zeros(60), 60500, [], 0.84);
    arr = arr.setName(['tr' num2str(rem_els)]);
    arr = arr.setMax('XY', 30);
    arr = arr.setMax('YZ', 30);
    arr = arr.setMax('E', 25);
    arr = arr.setMin('XY', -60);
    arr = arr.setMin('YZ', -60);
    arr = arr.setMin('E', -15);

    % Create elements' pattern
    tmp = zeros(60);
    len = size(arr.M,1)/4;
    d_ratio = abs(1-tan(pi/3))/sqrt((tan(pi/3))^2-1);
    k_max = 30 - round(rem_els/d_ratio);
    k_lim = round(k_max*d_ratio);
    for k=1:k_max
        i_max = size(arr.M,1)-len+2-k;
        if k <= k_lim
            tmp(len-1+k, 3+round(k/tan(pi/3)):end-2-round(k/tan(pi/3)))=1;
        end;
        for i=min(k,max(k_lim - 1,1)):i_max
           tmp(len-1+i, 3+round((i+k-1)/tan(pi/3)))=1; 
        end
    end;

    tmp(tmp(end:-1:1,:)==1)=1;
    tmp(tmp(:,end:-1:1)==1)=1;

    arr = arr.adaptArray(tmp, 90000, 0, 0);
    
    el_ratio = num2str(length(find(tmp~=0))/numel(tmp)*100,3);
    
    arr = arr.setComments(sprintf('Elements spacing: 0.84$\\lambda$'));

    % Plots
    arr.plotAntArray();
    for ang=0:pi/12:pi/2
        fprintf(['Current angle: ' rats(ang/pi) '$\\pi$']);
        arr = arr.genPattern(11000, 3000, 'theta', 30, ang);
        arr = arr.genPattern([], [], 'theta-BW', [], ang);
    end;
end;

if verLessThan('matlab','8.2')
    matlabpool close
else
   delete(poolobj);
end;