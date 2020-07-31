

count = 1;
% gmmask = load('gm_mask.mat').gm_mask;
% gmmask = reshape(gmmask, [48 64 48]);
gmmask = load('imgmask.mat').imgmask;
% dat = dat(:,1:180);
% dat = reshape(dat,[48,64,48,180]);
% bold = clearMask(dat, gmmask, 180);

idx = [];
for i = 8:40
    for j = 8:56
        for k = 8:40
            tmp = single(gmmask(i-7:i+7,j-7:j+7,k-7:k+7));
            tmp = sum(tmp(:));
            if(tmp>=3000)
                idx(count,:) = [i,j,k];
                count = count + 1;
            end
        end
    end
end

d = dir('/data/ances/patrick/BOLDDATA/Controls');
count = 1;
for i = 3:15
    d1 = dir([d(i).folder,'/',d(i).name,'/*.mat']);
    for j = 1:length(d1)
        name = [d1(j).folder,'/',d1(j).name];
        if(contains(name,'_HIV_') || contains(name,'_ADRC_') || contains(name,'_GSP_'))
            names{count} = name;
            count = count+1;
        end
    end
end
models = {'normal', 'Levy', 'Brownian', 'power', 'uniform'};
tslength = 180;

% For training data
% for jj = 1:length(names)
parfor (jj = 1:length(names),18)
    try
        jj
        imgbold = (load(names{jj}).img);
        if(min(size(imgbold))>=tslength+20)
            imgbold = scale(imgbold, gmmask);
            for i = 1:length(models)
                for r = 1:7:20
                    imgbold2 = imgbold(:,r:tslength+r-1);
                    imgbold2 = reshape(imgbold2,[48,64,48,tslength]);
                    x = randi(6)+1;
                    y = randi(6)+1;
                    z = randi(6)+1;
                    mask = zeros([48,64,48]);
                    rid = randi(length(idx));
                    mask(idx(rid,1)-x:idx(rid,1)+x, idx(rid,2)-y:idx(rid,2)+y, idx(rid,3)-z:idx(rid,3)+z) = 1;
                    m = (randi(190)+10)/1000;
                    bold = process(imgbold2, mask, string(models{i}), idx(rid,:), m);
                    for k = i+1:length(models)
                        bold = process(bold, mask, string(models{k}), idx(rid,:), m);
                    end
                    bold = clearMask(bold, gmmask, tslength);
                    id = rand();
                    finish(strcat('/data/ances2/NoiseID/bold/',string(jj),'_',string(id),'_',string(models{i}),'_low.mat'),single(round(bold,4)));
                    finish(strcat('/data/ances2/NoiseID/mask/',string(jj),'_',string(id),'_',string(models{i}),'_low.mat'),single(mask));
                end
            end
        end
    catch ME
        ME
    end
end


% For testing data
parfor (jj = 1:length(names),18)
    try
        jj
        imgbold = (load(names{jj}).img);
        if(min(size(imgbold))>=tslength)
            imgbold = imgbold(:,1:tslength);
            imgbold = scale(imgbold, gmmask);
            imgbold = reshape(imgbold,[48,64,48,tslength]);
            x = randi(6)+1;
            y = randi(6)+1;
            z = randi(6)+1;
            mask = zeros([48,64,48]);
            rid = randi(length(idx));
            mask(idx(rid,1)-x:idx(rid,1)+x, idx(rid,2)-y:idx(rid,2)+y, idx(rid,3)-z:idx(rid,3)+z) = 1;
            m = round((randi(70)+10)/100,1);
            i = mod(jj,5)+1;
            bold = process(imgbold, mask, string(models{i}), idx(rid,:), m);
            bold = clearMask(bold, gmmask, tslength);
            id = rand();
            finish(strcat('/data/ances2/NoiseIDV/bold/',string(jj),'_',string(id),'_',string(models{i}),'.mat'),single(round(bold,4)));
            finish(strcat('/data/ances2/NoiseIDV/mask/',string(jj),'_',string(id),'_',string(models{i}),'.mat'),single(mask));
        end
    catch ME
        ME
    end
end



function img = process(img, mask, type, idx, mix)
for i = idx(1,1)-5:idx(1,1)+5
    for j = idx(1,2)-5:idx(1,2)+5
        for k = idx(1,3)-5:idx(1,3)+5
            if(mask(i,j,k) == 1)
                if(type=="power")
                    img(i,j,k,:) = power1D(squeeze(img(i,j,k,:))', mix);
                elseif(type=="normal")
                    img(i,j,k,:) = normal1D(squeeze(img(i,j,k,:))', mix);
                elseif(type=="uniform")
                    img(i,j,k,:) = uniform1D(squeeze(img(i,j,k,:))', mix);
                elseif(type=="Brownian")
                    img(i,j,k,:) = Brownian_walk1D(squeeze(img(i,j,k,:))', mix);
                elseif(type=="Levy")
                    img(i,j,k,:) = Levy_flight1D(squeeze(img(i,j,k,:))', mix);
                else
                    img = 0;
                end
            end
        end
    end
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
bold = scale(bold,mask);
bold(isnan(bold))=0;
bold = reshape(bold,[48, 64, 48, len]);
end

function finish(str,dat)
save(str,'dat');
end


function b  = uniform1D(b0, mix)
% samples the normal distribution
Nt = length(b0);
b = rand(1, Nt);
b = rescale(rand()*b/max(abs(b)),-1,1);
b = (1 - mix)*b0 + mix*b;
end


function b  = normal1D(b0, mix)
% samples the normal distribution
Nt = length(b0);
b = randn(1, Nt);
b = rescale(rand()*b/max(abs(b)),-1,1);
b = (1 - mix)*b0 + mix*b;
end

function b  = power1D(b0, mix)
% samples a power law
%  https://math.stackexchange.com/questions/52869/numerical-approximation-of-levy-flight
rand_ = rand();
Nt = length(b0);
alpha_ = 1 + 2*rand_;
xmin = 1e-3;
b = xmin*(randn(1, Nt)).^(-1/alpha_);
b = (-1).^randi(2, 1, Nt).*b;
b = rescale(rand()*real(b)/max(abs(b)),-1,1);
b = (1 - mix)*b0 + mix*b;
end

function b  = Brownian_walk1D(b0, mix)
Nt = length(b0);
b = cumsum(randn(1, Nt));
b = rescale(rand()*b/max(abs(b)),-1,1);
b = (1 - mix)*b0 + mix*b;
end

function b  = Levy_flight1D(b0, mix)
% https://math.stackexchange.com/questions/52869/numerical-approximation-of-levy-flight
rand_ = rand();
Nt = length(b0);
alpha_ = 1 + 2*rand_;
xmin = 1e-3;
b = xmin*(rand(1, Nt)).^(-1/alpha_);
b = (-1).^randi(2, 1, Nt).*b;
b = cumsum(b);
b = rescale(rand()*real(b)/max(abs(b)),-1,1);
b = (1 - mix)*b0 + mix*b;
end

function [bold,mask] = noiseinjector(bold, varargin)
% NOISE_INJECTOR accepts BOLD time-series data and returns that data injected with modelled noise.
%  The size of the BOLD data is preserved.   noise_injector may be applied repeatedly.    %
%  @param bold is numeric, size(bold) ~ [48 64 48 Nt]; its internal representation is double.
%  @param model is char:  'default', 'affine', 'Brownian', 'flip', 'Levy', 'normal', 'points', 'power', 'shuffle' or
%               is cell of char model specifications.  Default is NoiseInjector.DEFAULT_MODEL.
%  @param focus_radius is numeric:  default 8.
%  @param mix is in [0, 1] and determines variability amongst focus voxels.
%  @param mix_process is in [0, 1] and determines mix of normal and stochastic process.
%  @return bold has noise injected
%  @return mask has the randomly defined focus/ball of voxels to be perturbed.    %
%  E.g., bold = noise_injector(bold)
%  E.g., bold = noise_injector(bold, 'normal')
%  E.g., bold = noise_injector(bold, {'Brownian' 'affine'}, 'mix', 0.5)

NI = NoiseInjector(bold, varargin{:});
NI = NI.inject_noise_model();
bold = NI.bold_;
mask = single(NI.focus_);
end
