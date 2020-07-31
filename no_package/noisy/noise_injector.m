


count = 1;
gmmask = load('gm_mask.mat').gm_mask;
gmmask = reshape(gmmask, [48 64 48]);

for i = 6:42
    for j = 6:58
        for k = 6:42            
            tmp = single(gmmask(i-5:i+5,j-5:j+5,k-5:k+5));
            tmp = sum(tmp(:));
            if(tmp>=1100)
                idx(count,:) = [i,j,k];
                count = count + 1;
            end
        end
    end
end


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
models = {'Levy', 'affine', 'Brownian', 'flip', 'normal', 'points', 'power', 'shuffle'};
tslength = 180;

% For training data
% for jj = 1:length(names)
parfor jj = 1:length(names)
    try
        jj
        imgbold = (load(names{jj}).img);
        if(min(size(imgbold))>=tslength)
            imgbold = imgbold(:,1:tslength);
            imgbold = scale(imgbold, gmmask);
            imgbold = reshape(imgbold,[48,64,48,tslength]);
            for i = 1:length(models)
                m = round((randi(70)+10)/100,1);
                mp = round((randi(70)+10)/100,1);
                fr = double(randi(7))+3;
                [bold,mask] = noiseinjector(imgbold, 'model', models{i}, 'mix', m, 'mix_process', mp, 'focus_radius', fr);
                bold = clearMask(bold, gmmask, tslength);
                mask = sum(mask,4);
                mask = single(mask>0);
                mask(isnan(mask))=0;
                id = rand();
                finish(strcat('/data/ances2/NoiseID/bold/',string(jj),'_',string(id),'_',string(models{i}),'.mat'),single(round(bold,4)));
                finish(strcat('/data/ances2/NoiseID/mask/',string(jj),'_',string(id),'_',string(models{i}),'.mat'),single(mask));
            end
        end
    catch ME
        ME
    end
end


% For testing data
% parfor (jj = 1:length(names),6)
%     try
%         jj
%         imgbold = (load(names{jj}).img);
%         if(min(size(imgbold))>=tslength)
%             imgbold = imgbold(:,1:tslength);
%             imgbold = scale(imgbold, gmmask);
%             imgbold = reshape(imgbold,[48,64,48,tslength]);
%             i = mod(jj,8)+1;
%             m = round((randi(40)+10)/100,1);
%             mp = round((randi(40)+10)/100,1);
%             fr = double(randi(8))+4;
%             [bold,mask] = noiseinjector(imgbold, 'model', models{i}, 'mix', m, 'mix_process', mp, 'focus_radius', fr);
%             bold = clearMask(bold, gmmask, tslength);
%             mask = sum(mask,4);
%             mask = single(mask>0);
%             mask(isnan(mask))=0;
%             id = rand();
%             finish(strcat('/data/ances2/NoiseIDV/bold/',string(jj),'_',string(id),'_',string(models{i}),'.mat'),single(round(bold,4)));
%             finish(strcat('/data/ances2/NoiseIDV/mask/',string(jj),'_',string(id),'_',string(models{i}),'.mat'),single(mask));
%         end
%     catch ME
%         ME
%     end
% end

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
   
