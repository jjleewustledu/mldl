

fid = fopen('gm3d.img', 'r');
gmmask = single(fread(fid,'float'));
fclose(fid);
gmmask = reshape(gmmask, [48 64 48]);
% gmmask = flip(gmmask, 2);

% imgmask = load('imgmask.mat').imgmask;
% gm = load('gm.mat').gm;
% gm_mask = load('gm_mask.mat').gm_mask;
% other_mask = load('other_mask.mat').other_mask;
% bb300_img = load('bb300_img.mat').bb300_img;
% inds_sal2co = load('inds_sal2co.mat').inds_sal2co;

mat = make_nii(single((gmmask)),[3,3,3],[73.5, -87, -84]);
save_nii(mat, [pwd,'/networksSmooth']);
return
d = dir('/data/ances/patrick/BOLDDATA/Controls');
count = 1;
for i = 3:length(d)
    d1 = dir([d(i).folder,'/',d(i).name,'/*.mat']);
    for j = 1:length(d1)
        name = [d1(j).folder,'/',d1(j).name];
        if(contains(name,'_HIV_') || contains(name,'_ADRC_') || contains(name,'_GSP_'))
            names{count} = name;
            count = count+1;
        end
    end
end
models = {'affine', 'Brownian', 'flip', 'Levy', 'normal', 'points', 'power', 'shuffle'};
tslength = 180;

% mask = zeros(48,64,48);
% parfor jj = 1:length(names)
%     jj
%     imgbold = (load(names{jj}).img);
%     if(min(size(imgbold))>=tslength)
%         imgbold = imgbold(:,1:tslength);
%         imgbold = scale(imgbold, gmmask);
%         imgbold = reshape(imgbold,[48,64,48,tslength]);
%         bold = clearMask(imgbold, gmmask, tslength);
%         id = rand();
%         finish(strcat('/data/ances2/NoiseID/bold/',string(jj),'_',string(id),'_NA.mat'),single(round(bold,4)));
%         finish(strcat('/data/ances2/NoiseID/mask/',string(jj),'_',string(id),'_NA.mat'),single(mask));
%     end
% end
% return

% For training data
for jj = 1:length(names)
    % parfor jj = 1:length(names)
    Nx = 48;
    Ny = 64;
    Nz = 48;
    N3D = Nx*Ny*Nz;
    try
        jj
        imgbold = (load(names{jj}).img);
        return
        tslength = size(imgbold,2);
        imgbold = scale(imgbold, gmmask);
        imgbold = reshape(imgbold,[48,64,48,tslength]);
        for i = 1:length(models)
            ROIccmap = zeros(1, N3D); % store correlation map
            ROIccmap2 = zeros(1, N3D);
            m = round((randi(40)+10)/100,1);
            mp = round((randi(50)+40)/100,1);
            [bold,mask] = noiseinjector(imgbold, 'model', models{i}, 'mix', m, 'mix_process', mp);
            bold = clearMask(bold, gmmask, tslength);
            mask = sum(mask,4);
            mask = single(mask>0);
            mask(isnan(mask))=0;
            mask = reshape(mask,[147456,1]);
            imgbold = reshape(bold,[147456,tslength]);
            tmp = imgbold(mask>0,:);
            x = tmp(27,:);
            for k = 16000:144000
                if gm_mask(k)>0
                    y = imgbold(:,k);
                    R = corrcoef(x, y);
                    ROIccmap(1,k) = R(1,2);
                    R = pdist2(x, y', 'euclidean');
                    ROIccmap2(1,k) = R;
                    return
                end
            end
            ROIccmap = rescale(ROIccmap,0,1);
            ROIccmap2 = 1-rescale(ROIccmap2,0,1);            
            img3d = cat(3,reshape(ROIccmap(1,:), [Nx Ny Nz]),reshape(ROIccmap2(1,:), [Nx Ny Nz]));
            img3d(isnan(img3d))=0;
            img3d(~gm) = 0;
            
            id = rand();
            finish(strcat('/data/ances2/Patrick_Shimony2/17/',string(jj),'_',string(id),'_',string(models{i}),'.mat'),single(round(bold,4)));
        end
    catch ME
        ME
    end
end




function img = scale(img,mask)
mask = find(reshape(mask,[147456 , 1]));
for i = 1:length(mask)
    img(mask(i),:) = rescale(img(mask(i),:),-1,1);
end
img(isnan(img))=0;
end

function bold = clearMask(img,mask,len)
bold = reshape(img,[147456 , len]);
mask = reshape(mask,[147456 , 1]);
bold(mask==0,:) = bold(mask==0,:).*0; 
bold(isnan(bold))=0;
bold = reshape(bold,[48, 64, 48, len]);
end

function finish(str,dat)
save(str,'dat');
end


function [bold,mask] = noiseinjector(bold, varargin)
    %% NOISE_INJECTOR accepts BOLD time-series data and returns that data injected with modelled noise.
    %  The size of the BOLD data is preserved.   noise_injector may be applied repeatedly.
    %
    %  @param bold is numeric, size(bold) ~ [48 64 48 Nt]; its internal representation is double.
    %  @param model is char:  'default', 'affine', 'Brownian', 'flip', 'Levy', 'normal', 'points', 'power', 'shuffle' or
    %               is cell of char model specifications.  Default is NoiseInjector.DEFAULT_MODEL.
    %  @param focus_radius is numeric:  default 8.
    %  @param mix is in [0, 1] and determines variability amongst focus voxels.
    %  @param mix_process is in [0, 1] and determines mix of normal and stochastic process.
    %  @return bold has noise injected
    %  @return mask has the randomly defined focus/ball of voxels to be perturbed.
    %
    %  E.g., bold = noise_injector(bold)
    %  E.g., bold = noise_injector(bold, 'normal')
    %  E.g., bold = noise_injector(bold, {'Brownian' 'affine'}, 'mix', 0.5)
    
    NI = NoiseInjector(bold, varargin{:});
    NI = NI.inject_noise_model();
    bold = NI.bold_;
    mask = single(NI.focus_);
end
   
