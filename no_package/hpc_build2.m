function hpc_build2(fileIdx, cohortFold)
if ischar(fileIdx)
    fileIdx = str2double(fileIdx);
end
assert(isnumeric(fileIdx))
assert(ischar(cohortFold))
path0 = fullfile('/data/nil-bluearc/shimony/jjlee/DeepNetFCProject', 'HPC', '');
assert(isfolder(path0))

if ~isfolder(cohortFold)
    % working around HPC Singularity volume problem
    cohortFold = fullfile('/data/nil-bluearc/shimony/mkrs/DNN_100frames', basename(cohortFold));
end
%assert(isfolder(cohortFold), 'cohortFold->%s', cohortFold)

cd(path0)
%addpath(genpath([path0,'/addall']));
%addpath(genpath([path0,'/Tumor']));
d = dir(cohortFold);
system(['chmod -R 777 ' cohortFold])

file = fileIdx + 2;
newd = [d(file).folder,'/',d(file).name,'/DeepNet',d(file).name];
if(~exist([newd,'/networks.mat'],'file'))
    assert(logical(exist(newd,'dir')))
    newd2 = [newd,'/tmp'];
    assert(logical(exist(newd2,'dir')))
    
    tic
    [~,p,imds,scores] = build(newd2,path0);
    fprintf('finished build()\n')
    fprintf('build(%s, %s) timings:\n', newd2, path0)
    fprintf('cohortFold->%s\n', cohortFold)
    save([newd filesep mfilename '_scores_' datestr(now, 30) '.mat'], 'scores')
    toc
        
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

