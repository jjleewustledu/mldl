
addpath(genpath('/data/ances/patrick/NIfTI_20140122'));
addpath(genpath('/data/ances/patrick/CCR_Test'));
msk = load('epilepsy_333.mat').dat;
msk = reshape(msk,[48,64,48]);
gmmask  = load('gm_mask.mat').gm_mask;
gmmask = reshape(gmmask,[48,64,48]);
models = {'normal', 'Levy', 'Brownian', 'power', 'uniform','samp'};
d = dir('/data/ances/patrick/BOLDDATA/Controls');
load('demographicsf.mat');
demogs2 = demogs;
tslength = 180;
count = 1;
parfor i = 4:9
    for mi = 1:length(models)
        d1 = dir([d(i).folder,'/',d(i).name,'/*.mat']);
        for j = 1:length(d1)
            try
                name = [d1(j).folder,'/',d1(j).name];
                if(contains(name,'_HIV_') || contains(name,'_DIAN_') || contains(name,'_GSP_'))
                    count = count+1;
                    imgbold = (load(name).img);
                    if(size(imgbold,2)>=180)
                        imgbold = imgbold(:,1:180);
                        imgbold = scale(imgbold);
                        imgbold = reshape(imgbold,[48,64,48,tslength]);
                        imgbold = clearMask(imgbold,gmmask);
                        xwindow = randi(2);
                        ywindow = randi(2);
                        zwindow = randi(2);
                        coordinates = getCoordinates(msk, xwindow, ywindow, zwindow);
                        mask2 = zeros(48,64,48);
                        mask2(coordinates(1)-xwindow:coordinates(1)+xwindow,...
                            coordinates(2)-ywindow:coordinates(2)+ywindow,...
                            coordinates(3)-zwindow:coordinates(3)+zwindow)=mask2(coordinates(1)-xwindow:coordinates(1)+xwindow,...
                            coordinates(2)-ywindow:coordinates(2)+ywindow,...
                            coordinates(3)-zwindow:coordinates(3)+zwindow)+1;
                        noise1(models(mi), imgbold, mask2, coordinates);
                    end
                end
            catch ME
                ME
            end
        end
    end
end


% parfor i = 1:height(demogs)
%     i
%     for mi = 1:length(models)
%         imgbold = [];
%         if(demogs2{i,1}== 1 && demogs2{i,3}<= 45)
%             imgbold = getHIVBOLDS(char(demogs2{i,2}));
%             if(size(imgbold,2)>=180)
%                 try
%                     imgbold = imgbold(:,1:180);
%                     imgbold = scale(imgbold);
%                     imgbold = reshape(imgbold,[48,64,48,tslength]);
%                     imgbold = clearMask(imgbold,gmmask);
%                     xwindow = randi(2);
%                     ywindow = randi(2);
%                     zwindow = randi(2);
%                     coordinates = getCoordinates(msk, xwindow, ywindow, zwindow);
%                     mask2 = zeros(48,64,48);
%                     mask2(coordinates(1)-xwindow:coordinates(1)+xwindow,...
%                         coordinates(2)-ywindow:coordinates(2)+ywindow,...
%                         coordinates(3)-zwindow:coordinates(3)+zwindow)=mask2(coordinates(1)-xwindow:coordinates(1)+xwindow,...
%                         coordinates(2)-ywindow:coordinates(2)+ywindow,...
%                         coordinates(3)-zwindow:coordinates(3)+zwindow)+1;
%                     noise1(models(mi), imgbold, mask2, coordinates);
%                 catch ME
%                     ME
%                 end
%             end
%             
%         end
%     end
% end


function imgbold = clearMask(imgbold,mask)
for i = 1:size(mask,1)
    for j = 1:size(mask,2)
        for k = 1:size(mask,3)
            if(~mask(i,j,k))
                imgbold(i,j,k,:) = imgbold(i,j,k,:).*0;
            end
        end
    end
end
end

function noise1(models, imgbold, mask, coordinates)
% try
    for i = 1:length(models)
        m = (randi(90)+10)/200;
        bold = process(imgbold, mask, string(models{i}),m);
        id = rand();
        if(coordinates(1)<=24)
            finish(strcat('/data/ances2/NoiseID/L/N1_',string(id),'_',string(models{i}),'_low.mat'),single(round(bold,4)));
            finish(strcat('/data/ances2/NoiseID/R/N1_F_',string(id),'_',string(models{i}),'_low.mat'),flip(single(round(bold,4)),1));
        else
            finish(strcat('/data/ances2/NoiseID/R/N1_',string(id),'_',string(models{i}),'_low.mat'),single(round(bold,4)));
            finish(strcat('/data/ances2/NoiseID/L/N1_F_',string(id),'_',string(models{i}),'_low.mat'),flip(single(round(bold,4)),1));
        end
    end
% catch ME
%     ME
% end
end

function img = process(img, mask, type, mix)
for i = 2:47
    for j = 2:63
        for k = 2:47
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
                elseif(type=="samp")
                    img(i,j,k,:) = datasample(img(:),180);
                else
                    img = 0;
                end
            end
        end
    end
end
end

function img = scale(img)
for i = 1:length(img)
    img(i,:) = rescale(zscore(img(i,:)),-1,1);
end
img(isnan(img))=0;
end


function finish(str,dat)
save(str,'dat');
end


function coordinates = getCoordinates(msk, xwindow, ywindow, zwindow)
while(1==1)
    coordinates(1) = 4+randi(42);
    coordinates(2) = 4+randi(58);
    coordinates(3) = 4+randi(42);
    tmp = msk(coordinates(1)-xwindow:coordinates(1)+xwindow,coordinates(2)-ywindow:coordinates(2)+ywindow,coordinates(3)-zwindow:coordinates(3)+zwindow);
    tmp = mean(tmp(:));
    if(tmp>=.2)
        break;
    end
end
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


function [imgbold,imgbold2] = getHIVBOLDS(s)
fMRIfilename =  ['/data/ances2/HIV/BOLD_12_31_2017/' s '/FCmaps_uwrp/' s '_faln_dbnd_xr3d_uwrp_atl_DVAR2p5std_FD40.conc'];
if(~exist(fMRIfilename,'file'))
    fMRIfilename =  ['/data/ances2/HIV/BOLD_12_31_2017/' s '/FCmaps_uwrp/' s '_faln_dbnd_xr3d_uwrp_atl_DVAR2p5std_FD30.conc'];
end
if (exist(fMRIfilename,'file'))
    imgbold = Load_4dfp_conc(fMRIfilename, 2, 0);
    imgbold =  imgbold.voxel_data;
else
    imgbold = -9999;
    imgbold2 = -9999;
end
end
