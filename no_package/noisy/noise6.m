



% gmmask = load('gm_mask.mat').gm_mask;
% gmmask = reshape(gmmask, [48 64 48]);
gmmask = load('imgmask.mat').imgmask;

d = dir('/data/ances/patrick/BOLDDATA/Controls');
count = 1;
for i = 3:length(d)
    d1 = dir([d(i).folder,'/',d(i).name,'/*.mat']);
    for j = 1:length(d1)
        name = [d1(j).folder,'/',d1(j).name];
        if(contains(name,'_HIV_') || contains(name,'_DIAN_') || contains(name,'_ADRC_') || contains(name,'_GSP_'))
            names{count} = name;
            count = count+1;
        end
    end
end


tslength = 180;

% for jj = 1:1%height(demogs)
parfor (jj = 1:length(names),10)
    try
        jj
        imgbold = (load(names{jj}).img);
        if(min(size(imgbold))>=tslength)
            imgbold = imgbold(:,1:tslength);
            
            imgbold = imgbold(randperm(size(imgbold, 1)), :);
            
            imgbold = scale(imgbold, gmmask);
            imgbold = reshape(imgbold,[48,64,48,tslength]);
            mask = ones([48,64,48]);
            imgbold = clearMask(imgbold, gmmask, tslength);
            id = rand();
            finish(strcat('/data/ances2/NoiseID/bold/',string(jj),'_',string(id),'_NAA','.mat'),single(round(imgbold,4)));
            finish(strcat('/data/ances2/NoiseID/mask/',string(jj),'_',string(id),'_NAA','.mat'),single(mask));
        end
    catch ME
        ME
    end
end



function img = process(img, mask, idx, noise)
count = 1;
for i = idx(1,1)-5:idx(1,1)+5
    for j = idx(1,2)-5:idx(1,2)+5
        for k = idx(1,3)-5:idx(1,3)+5
            if(mask(i,j,k) == 1)               
                img(i,j,k,:) = noise(count,:);                
                count = count + 1;               
            end
        end
    end
end
end

function img = scale(img,mask)
for i = 1:147456
    img(i,:) = rescale(img(i,:),-1,1);
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
