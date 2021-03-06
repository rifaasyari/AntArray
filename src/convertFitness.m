function convertFitness(inname, dist, inmode, evth)
    %CONVERTFITNESS convert the fitness metric
    %
    % Convert the fitness metric from Vm to m� and inversely.
    %
    % [ ] = CONVERTFITNESS(infile, dist, inmode, evth)
    %
    % INPUT
    %   inname: input fitness file name
    %   dist:   distance from the array where to compute the fitness [mm]
    %   inmode: input fitness mode (0 for volume, 1 for surface)
    %   evth:   (optional) convert only max (0) or everything (1)
    %           [default = 0]
    %
    % See also FITNESS ANTARRAY GA_2D LOCAL_OPT

    % Copyright 2016, Antoine JUCKLER. All rights reserved.
    
    if nargin < 4 || isempty(evth)
        evth = 0;
    else
        evth = evth > 0;
    end;
    inmode = inmode > 0;
    
    % Check that files exist
    if length(inname) > 4 ...
            && (strcmp(inname(end-3:end), '.pdf') ...
            || strcmp(inname(end-3:end), '.fig'))
        inname = inname(1:end-3);
    end;
    i = 0;
    maxsearch = 30;
    for i=0:maxsearch
        str = datestr(addtodate(now, -i, 'day'), 'yyyymmdd');
        if exist([str '/fig/fitness_' inname '.fig'], 'file')
            infile = [str '/fig/fitness_' inname '.fig'];
            break;
        elseif i == maxsearch
            error 'Could not find specified file';
        end;
    end;

    for j=0:maxsearch
        str = datestr(addtodate(now, -i-j, 'day'), 'yyyymmdd');
        if exist([str '/' inname], 'dir')
            break;
        elseif j == maxsearch
            error 'Could not find GA files';
        end;
    end;
    
    GA_fold = [str '/' inname];
    
    % Check for config file availability
    kmax = i+j;
    k = max(0, i-1);
    for j=k:kmax
        str = datestr(addtodate(now, -j, 'day'), 'yyyymmdd');
        if exist([str '/cfg/' inname '.cfg'], 'file')
            break;
        elseif j == kmax
            error 'Could not find config file';
        end;
    end;

    cfg_path = [str '/cfg/' inname '.cfg'];
    
    % Check whether fitness data were saved
    if evth
        kk = 0;
        while exist([GA_fold '/' num2str(kk) '/fitness.dat'], 'file')
            kk = kk + 1;
        end;
        kk= kk-1;
        while kk >= 0
            if ~exist([GA_fold '/' num2str(kk) '/fitness_conv.dat'], 'file')
                break;
            else
                kk = kk-1;
            end;
        end;
    end;
    
    % Save folder name
    dirname = [inname '_conv'];
    
    if evth && kk == -1
        dirprefix = datestr(now, 'yyyymmdd');
        dirname = [dirprefix '/' dirname];
        if ~exist(dirname, 'dir')
            mkdir(dirname);
        end;
        newdata = convertFromFile(GA_fold, cfg_path, dirname);
    else
        % Open files
        % ----------
        fig = openfig(infile, 'new', 'invisible');
        kids = get(get(fig, 'CurrentAxes'), 'Children');

        if length(kids) ~= 2
            error 'Wrong format of fitness plot';
        end;

        % Find number of files
        % --------------------
        num_els = 1;
        if evth
            while exist([GA_fold '/1/arrangement_' num2str(num_els) '.dat'], 'file')
                num_els = num_els + 1;
            end;
            num_els = num_els - 1;
            newdata = zeros(3, length(get(kids(1), 'YData')));
        else
            newdata = zeros(1, length(get(kids(1), 'YData')));
        end;    
        clearvars kids
        close(fig);

        parallel_pool('start');
        if ~evth
            parfor i=1:length(newdata)
                currfile = [GA_fold '/' num2str(i) '/arrangement_1.dat'];
                if ~exist(currfile, 'file')
                    error(['File not found at iteration ' num2str(i)]);
                end;
                ant = AntArray(currfile, [], [], [], cfg_path, 0);
                newdata(i) = fitness(ant, dist, ~inmode);
            end;
        else
            try
                dial = WaitDialog();
                dial.setMainString('Starting...');

                % Find if previously started
                for i=0:maxsearch
                    dirprefix = datestr(addtodate(now, -i, 'day'), 'yyyymmdd');
                    if exist([dirprefix '/' dirname], 'dir')
                        dirname = [dirprefix '/' dirname];
                        j = 1;
                        while exist([dirname '/' num2str(j)], 'dir')
                            j = j+1;
                        end;
                        startit = j;
                        dial.setMainString('Previous generation data found');
                        dial.setSubString(['Starting from iteration ' num2str(j)]);
                        pause(0.5);


                        ii = 0;
                        dirpref = datestr(addtodate(now, -i+ii, 'day'), ...
                            'yyyymmdd');
                        fitname = [dirpref '/fig/fitness_' inname '_' ...
                                num2str(~inmode) '_evth.fig'];
                        while ii < 2 && ~exist(fitname, 'file')
                            dirpref = datestr(addtodate(now, -i+ii, 'day'), ...
                                'yyyymmdd');
                            fitname = [dirpref '/fig/fitness_' inname '_' ...
                                num2str(~inmode) '_evth.fig'];
                            ii = ii + 1;
                        end;
                        if ~exist(fitname, 'file')
                            error 'Unable to find last run fig file';
                        end;
                        fig = openfig(fitname, 'new', 'invisible');
                        kids = get(get(fig, 'CurrentAxes'), 'Children');

                        if length(kids) ~= 3
                            error 'Wrong format of fitness plot';
                        end;

                        for j=1:3
                            plotdata = get(kids(j), 'YData');
                            newdata(4-j, 1:startit-1) = plotdata(1:startit-1);
                        end;
                        close(fig);

                        break;
                    elseif i == maxsearch
                        dirprefix = datestr(now, 'yyyymmdd');
                        dirname = [dirprefix '/' dirname];
                        mkdir(dirname);
                        startit = 1;
                    end;
                end;
                dial.terminate();

                maxi = length(newdata);
                for i=startit:maxi
                    dial.setMainString(['Working on population ' ...
                            num2str(i) ' of ' num2str(maxi) '...']);
                    dial.terminate();
                    vals = zeros(1, maxi);
                    parfor j=1:num_els
                        currfile = [GA_fold '/' num2str(i) ...
                            '/arrangement_' num2str(j) '.dat'];
                        if ~exist(currfile, 'file')
                            error(['File ' num2str(j) ...
                                ' not found at iteration ' num2str(i)]);
                        end;
                        ant = AntArray(currfile, [], [], [], cfg_path, 0);
                        vals(j) = fitness(ant, dist, ~inmode);
                    end;
                    newdata(1, i) = vals(1);
                    newdata(2, i) = sum(sum(vals))/numel(vals);
                    [newdata(3, i), pos] = max(vals);

                    % Save max
                    subdir = [dirname '/' num2str(i) '/'];
                    mkdir(subdir);
                    arrgt1 = AntArray([GA_fold '/' num2str(i) ...
                        '/arrangement_1.dat'], [], [], [], cfg_path, 0).M;
                    arrgt2 = AntArray([GA_fold '/' num2str(i) ...
                        '/arrangement_' num2str(pos) '.dat'], ...
                        [], [], [], cfg_path, 0).M;
                    save([subdir 'arrangement_1.dat'], 'arrgt1', '-ASCII');
                    save([subdir 'arrangement_' num2str(pos) '.dat'], ...
                        'arrgt2', '-ASCII');

                    dial.terminate();
                end;
                delete(dial);
            catch ME
                switch ME.identifier
                    case 'MyERR:Terminated'
                        warning 'Operation terminated by user';
                    otherwise
                        rethrow(ME);
                end;
            end;
        end;
    end;
    
    fig_end = figure();
    plot(1:length(newdata), newdata(1, :), '-b', 'LineWidth', 2, ...
        'DisplayName', 'Converted max');
    hold on
    
    if evth
        plot(1:length(newdata), newdata(2, :), '-r', 'LineWidth', 2, ...
            'DisplayName', 'Converted mean');
        plot(1:length(newdata), newdata(3, :), '-g', 'LineWidth', 2, ...
            'DisplayName', 'New max');
    end;  

    xlabel('Iteration', 'Interpreter', 'latex', 'FontSize', 22);
    if ~inmode == 0
        label = 'Fitness [Vm]';
    else
        label = 'Fitness [$m^2$]';
    end;
    ylabel(label, 'Interpreter', 'latex', 'FontSize', 22);
    
    if evth
        L = legend('Location', 'southeast');
        set(L, 'Interpreter', 'latex', 'FontSize', 20);
    end;
    xlim([1 length(newdata)]);
    
    set(get(fig_end, 'CurrentAxes'), 'FontSize', 16);
    hold off;
    
    if evth
        savname = ['fitness_' inname '_' num2str(~inmode) '_evth'];
    else
        savname = ['fitness_' inname '_' num2str(~inmode)];
    end;
    print_plots(fig_end, savname);
    close all
    
    parallel_pool('stop');
end

%% Function to directly get the data from previous simulations (if available)
function newdata = convertFromFile(GA_fold, cfg_path, dirname)
    %CONVERTFROMFILE get all the data from previous simulations, provided
    %they are available
    %
    % newdata = CONVERTFROMFILE(GA_folg, cfg_path, dirname)
    %
    % INPUT
    %   GA_fold:    folder containing GA results
    %   cfg_path:   path to cfg-file
    %   dirname:    save folder name
    % OUTPUT
    %   newdata:    results using the other fitness function
    
    it = 0;
    while exist([GA_fold '/' num2str(it) '/fitness_conv.dat'], 'file')
        it = it+1;
    end;
    newdata = zeros(3, it);
    for i=1:it
        fit = dlmread([GA_fold '/' num2str(i-1) '/fitness_conv.dat']);
        newdata(:, i) = [fit(2,2) sum(fit(:,2))/length(fit) max(fit(:,2))];
        
        subdir = [dirname '/' num2str(i) '/'];
        if ~exist(subdir, 'dir')
            mkdir(subdir);
        end;
        arrgt1 = AntArray([GA_fold '/' num2str(i-1) ...
            '/arrangement_1.dat'], [], [], [], cfg_path, 0).M;
        arrgt2 = AntArray([GA_fold '/' num2str(i-1) ...
            '/arrangement_' num2str(fit(1,1)) '.dat'], ...
            [], [], [], cfg_path, 0).M;
        save([subdir 'arrangement_1.dat'], 'arrgt1', '-ASCII');
        save([subdir 'arrangement_' num2str(fit(1,1)) '.dat'], ...
            'arrgt2', '-ASCII');
    end;
end