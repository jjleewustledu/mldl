function hpc_generate(fileIdx, cohortFold)
if ischar(fileIdx)
    fileIdx = str2double(fileIdx);
end
assert(isnumeric(fileIdx))
assert(ischar(cohortFold))
path0 = fullfile('/DeepNetFCProject', 'HPC', '');
assert(isfolder(path0))

if ~isfolder(cohortFold)
    % working around HPC Singularity volume problem
    cohortFold = fullfile('/scratch/jjlee/DeepNetFCProject/HPC', basename(cohortFold));
end
%assert(isfolder(cohortFold), 'cohortFold->%s', cohortFold)

cd(path0)
d = dir(cohortFold);

file = fileIdx + 2;
newd = [d(file).folder,'/',d(file).name,'/DeepNet',d(file).name];
if(~exist([newd,'/networks.mat'],'file'))
    if(~exist(newd,'dir'))
        mkdir(newd);
    end
    newd2 = [newd,'/tmp'];
    if(~exist(newd2,'dir'))
        mkdir(newd2);
    end
    image = load([d(file).folder,'/',d(file).name,'/',d(file).name,'_BOLD']);
    if(isfield(image, 'img'))
        image = image.img;
    end
    if(isfield(image, 'dat'))
        image = image.dat;
    end
    for i = 1:147456
        if(length(unique(image(i,:)))>1)
            image(i,:) = rescale(zscore(image(i,:)),-1,1);
        end
    end
    
    tic
    generate(image',newd2,path0);
    fprintf('finished generate()\n')
    fprintf('generate(imgbold, %s) timings:\n', path0)
    fprintf('cohortFold->%s\n', cohortFold)
    toc
end
end


function generate(imgbold,path,path0)
DEBUG = ~isempty(getenv('DEBUG'));
NUM_CORES = 16;
Nx = 48;
Ny = 64;
Nz = 48;
N3D = Nx*Ny*Nz;
mask_name = fullfile(path0, 'addall', 'CCR_Test', strcat('glm_atlas_mask_333.4dfp.img'));
fprintf('generate will attempt to open %s\n', mask_name)
fid = fopen(mask_name,'r');
imgmask = fread(fid, [1 N3D], 'float', 'b');
fclose(fid);
f = find(imgmask);
parfor (i = 1:length(f), NUM_CORES)
    try
        % parallel speed-up ~ 679 sec / 136 sec \approx 5.0 for length(f)==512
        % and for NUM_CORES = 8
        idx = f(i);
        str = [path,'/',char(string(idx)),'.mat'];
        if(~exist(str,'file'))
            ROIccmap = zeros(1,147456);
            if ~DEBUG % exclude (x = ... end) to create maps with zeros for testing
                x = imgbold(:,idx); %#ok<PFBNS>
                for k = 1:length(f)
                    idx2 = f(k);
                    y = imgbold(:,idx2);
                    R = corrcoef(x, y);
                    ROIccmap(1,idx2) = R(1,2);
                end
            end
            img = reshape(ROIccmap(1,:), [48 64 48]);
            img(isnan(img))=0;
            finish(str,img)
        end
    catch ME
        disp(ME)
    end
end
end


function finish(str,dat)
save(str,'dat');
end

