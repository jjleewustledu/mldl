function hpc_DT20191114135400(fileIdx, cohortFold)
if ischar(fileIdx)
    fileIdx = str2double(fileIdx);
end
assert(isnumeric(fileIdx))
assert(ischar(cohortFold))
path0 = fullfile('/scratch/jjlee/DeepNetFCProject/HPC');
assert(isfolder(path0))
assert(isfolder(fullfile(path0, cohortFold)))
cd(path0)
%addpath(genpath([path0,'/addall']));
%addpath(genpath([path0,'/Tumor']));
d = dir(fullfile(path0, cohortFold, ''));

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
    generate(image',newd2,path0); 
    fprintf('finished generate()\n')
    [~,p,imds,scores] = build(newd2,path0);
    fprintf('finished build()\n')
    if ~isempty(getenv('DEBUG'))
        save(['hpc_DT20191114135400_' datestr(now, 30) '.mat'], 'scores')
    end
    prob = smoothScores(scores,newd2,path0);
    getSmoothProb(prob,newd)
    img = zeros(147456,1);
    for i = 1:147456
        if(sum(prob(i,:))>0)
            [~,m] = max(prob(i,:));
            img(i,1) = m;
        end
    end
    img = reshape(img,[48,64,48]);
    img = smooth333(img);
    mat = make_nii(single(flip(shift(img),1)),[3,3,3],[73.5, -87, -84]);
    save_nii(mat, [newd,'/networks']);
    delete([newd2,'/*.mat'])
end
end

function getSmoothProb(scores,path)
if(~exist([path,'/smoothprobability'],'dir'))
    mkdir([path,'/smoothprobability'])
end
Nx = 48;
Ny = 64;
Nz = 48;
for j = 1:11   
    img3d = flip(reshape(scores(:,j), [Nx Ny Nz]),1);
    if(j==1)
        mat = make_nii(single(img3d),[3,3,3],[73.5, -87, -84]);
        save_nii(mat, [path,'/smoothprobability/vfn']);
    end
    if(j==2)
        mat = make_nii(single(img3d),[3,3,3],[73.5, -87, -84]);
        save_nii(mat, [path,'/smoothprobability/dmn']);
    end
    if(j==3)
        mat = make_nii(single(img3d),[3,3,3],[73.5, -87, -84]);
        save_nii(mat, [path,'/smoothprobability/oth']);
    end
    if(j==4)
        mat = make_nii(single(img3d),[3,3,3],[73.5, -87, -84]);
        save_nii(mat, [path,'/smoothprobability/vpn']);
    end
    if(j==5)
        mat = make_nii(single(img3d),[3,3,3],[73.5, -87, -84]);
        save_nii(mat, [path,'/smoothprobability/dan']);
    end
    if(j==6)
        mat = make_nii(single(img3d),[3,3,3],[73.5, -87, -84]);
        save_nii(mat, [path,'/smoothprobability/smn']);
    end
    if(j==7)
        mat = make_nii(single(img3d),[3,3,3],[73.5, -87, -84]);
        save_nii(mat, [path,'/smoothprobability/aud']);
    end
    if(j==8)
        mat = make_nii(single(img3d),[3,3,3],[73.5, -87, -84]);
        save_nii(mat, [path,'/smoothprobability/co']);
    end
    if(j==9)
        mat = make_nii(single(img3d),[3,3,3],[73.5, -87, -84]);
        save_nii(mat, [path,'/smoothprobability/van']);
    end
    if(j==10)
        mat = make_nii(single(img3d),[3,3,3],[73.5, -87, -84]);
        save_nii(mat, [path,'/smoothprobability/lan']);
    end
    if(j==11)
        mat = make_nii(single(img3d),[3,3,3],[73.5, -87, -84]);
        save_nii(mat, [path,'/smoothprobability/fpn']);
    end   
end
end

function tmp = shift(img)
for i = 1:48
    for j = 1:64
        for k = 1:48
            if(img(i,j,k)==0)
                tmp(i,j,k) = 0;                
            end
            if(img(i,j,k)==1)
                tmp(i,j,k) = 1;                
            end
            if(img(i,j,k)==2)
                tmp(i,j,k) = 10;                
            end
            if(img(i,j,k)==3)
                tmp(i,j,k) = 11;                
            end
            if(img(i,j,k)==4)
                tmp(i,j,k) = 2;                
            end
            if(img(i,j,k)==5)
                tmp(i,j,k) = 3;                
            end
            if(img(i,j,k)==6)
                tmp(i,j,k) = 4;                
            end
            if(img(i,j,k)==7)
                tmp(i,j,k) = 5;                
            end
            if(img(i,j,k)==8)
                tmp(i,j,k) = 6;                
            end
            if(img(i,j,k)==9)
                tmp(i,j,k) = 7;                
            end
            if(img(i,j,k)==10)
                tmp(i,j,k) = 8;                
            end
            if(img(i,j,k)==11)
                tmp(i,j,k) = 9;                
            end
        end
    end
end
end

function [img3d,p,imds,scores] = build(path,path0)
Nx = 48;
Ny = 64;
Nz = 48;
N3D = Nx*Ny*Nz;
net = load(fullfile(path0, 'addall', 'net11.mat'));
net = net.trainedNet;
dat = zeros(147456,1);
imds = imageDatastore(path,'FileExtensions','.mat', 'ReadFcn',@(x) matRead(x));
[p,scores] = classify(net,imds,'MiniBatchSize',32);
a = imds.Files;
for i = 1:length(p)
    a1 = strsplit(a{i},'/');
    a1 = strsplit(a1{1,length(a1)},'.');
    a1 = double(string(a1{1,1}));     
    dat(a1,1) = p(i,1);    
end
img3d = reshape(dat, [Nx Ny Nz]);
end

function generate(imgbold,path,path0)
NUM_CORES = 8;
DEBUG = ~isempty(getenv('DEBUG'));
DEBUG_PAR_LENGTH = 512; % required:  D_P_L > 15
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
if DEBUG
    fprintf('generate DEBUG->true, DEBUG_PAR_LENGTH->%i\n', DEBUG_PAR_LENGTH)
    parLength = DEBUG_PAR_LENGTH;
else
    parLength = length(f);
end
tic
fprintf('generate is using parfor with NUM_CORES->%i\n', NUM_CORES)
parfor (i = 1:parLength, NUM_CORES)
    % parallel speed-up ~ 679 sec / 136 sec \approx 5.0 for parLength==512
    %for i = 1:parLength
    idx = f(i);
    str = [path,'/',char(string(idx)),'.mat'];
    %if(exist(str,'file'))
    %    load(str, 'dat')
    %end
    if(~exist(str,'file'))
        ROIccmap = zeros(1,147456);
        x = imgbold(:,idx);
        for k = 1:length(f)
            idx2 = f(k);
            y = imgbold(:,idx2);
            R = corrcoef(x, y);
            ROIccmap(1,idx2) = R(1,2);
        end
        img = reshape(ROIccmap(1,:), [48 64 48]);
        img(isnan(img))=0;
        finish(str,img)
    end
end
fprintf('generate(imgbold, %s) timings:\n', path)
toc
end

function finish(str,dat)
save(str,'dat');
end

function img3d = smooth333(img)
count = 0;
img3d = img;
for m = 1:2   
    newImage = ones(48,64,48)*(-1);
    stride = 1;    
    for i = 1+m:stride:48-m
        for j = 1+m:stride:64-m
            for k = 1+m:stride:48-m
                tmp = img3d(i-m:i+m,j-m:j+m,k-m:k+m);
                tmp = tmp(:);
                mo = mode(tmp);
                if(length(mo==1))
                    p = sum(tmp==mo)/length(tmp);
                    if(p >= .92 && m == 1 && mo~=0)
                        newImage(i-m:i+m,j-m:j+m,k-m:k+m) = ones(3,3,3)*mo;
                        count = count + 1;
                    end
                    if(p >= .95 && m == 2 && mo~=0)
                        newImage(i-m:i+m,j-m:j+m,k-m:k+m) = ones(5,5,5)*mo;
                        count = count + 1;
                    end
                end
            end
        end
    end   
    for i = 1:48
        for j = 1:64
            for k = 1:48
                if(newImage(i,j,k)==-1)
                    newImage(i,j,k) = img3d(i,j,k);
                end
            end
        end
    end   
    for i = 10:40
        for j = 10:54
            for k = 10:40                
                tmp = newImage(i-1:i+1,j-1:j+1,k-1:k+1);
                if(newImage(i,j,k)==0)                    
                    if(sum(tmp(:)==0)==1)
                        newImage(i,j,k) = mode(tmp(:));
                    end                    
                end                
            end
        end
    end    
    img3d = newImage;    
end
end

function dat = smoothScores(scores,path,path0)
GM_name = fullfile(path0, 'addall', 'CCR_Test', strcat('N21_aparc+aseg_GMctx_on_711-2V_333_avg.4dfp.img'));
fid = fopen(GM_name,'r');
gm_mask = fread(fid, [1 147456], 'float', 'l');
fclose(fid);
gm_mask = imboxfilt3(makeSymetric(reshape(gm_mask,[48,64,48])));
gm_mask = gm_mask > 0.1;
gm_mask = reshape(gm_mask,[1,147456]);
imds = imageDatastore(path,'FileExtensions','.mat', 'ReadFcn',@(x) matRead(x));
dat = zeros(147456,11);
a = imds.Files;
for j = 1:11   
    for i = 1:length(scores)
        a1 = strsplit(a{i},'/');
        a1 = strsplit(a1{1,length(a1)},'.');
        a1 = double(string(a1{1,1}));        
        dat(a1,j) = scores(i,j);
    end
    tmp = reshape(dat(:,j),[48,64,48]);
    tmp = imboxfilt3(tmp);
    dat(:,j) = reshape(tmp,[147456,1]);    
end
dat(gm_mask'~=1,:)=0;
dat(dat<0)=0;
dat = (dat'./sum(dat'))';
dat(isnan(dat))=0;
dat = round(dat,3);
dat(dat<0)=0;
end

function dat = makeSymetric(dat)
for i = 1:48    
    a = dat(1:24,:,i);    
    b = flip(squeeze(dat(25:48,:,i)),1);
    a = (a+b)/2;
    dat(1:24,:,i) = a;
    dat(25:48,:,i) = flip(a,1);
end
end

