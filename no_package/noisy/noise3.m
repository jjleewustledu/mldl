

other_mask = load('other_mask.mat').other_mask;
gmmask = load('gm_mask.mat').gm_mask;
gmmask = reshape(gmmask, [48 64 48]);

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

idx = [];
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

tslength = 180;

% for jj = 1:1%height(demogs)
% parfor (jj = 1:length(names),18)
%     try
%         jj
%         imgbold = (load(names{jj}).img);
%         if(min(size(imgbold))>=tslength)
%             imgbold = imgbold(:,1:tslength);
%             imgbold = scale(imgbold, gmmask);
%             imgbold = reshape(imgbold,[48,64,48,tslength]);
%             mask = zeros([48,64,48]);
%             imgbold = clearMask(imgbold, gmmask, tslength);
%             id = rand();
%             finish(strcat('/data/ances2/NoiseID/bold/',string(jj),'_',string(id),'_NA','.mat'),single(round(imgbold,4)));
%             finish(strcat('/data/ances2/NoiseID/mask/',string(jj),'_',string(id),'_NA','.mat'),single(mask));
%         end
%     catch ME
%         ME
%     end
% end
% 
% parfor (jj = 1:length(names),18)
%     try
%         jj
%         imgbold = (load(names{jj}).img);
%         imgbold = imgbold(:,5:end);
%         if(min(size(imgbold))>=tslength)
%             imgbold = imgbold(:,1:tslength);
%             imgbold = scale(imgbold, gmmask);
%             imgbold = reshape(imgbold,[48,64,48,tslength]);
%             mask = zeros([48,64,48]);
%             imgbold = clearMask(imgbold, gmmask, tslength);
%             id = rand();
%             finish(strcat('/data/ances2/NoiseIDV/bold/',string(jj),'_',string(id),'_NA','.mat'),single(round(imgbold,4)));
%             finish(strcat('/data/ances2/NoiseIDV/mask/',string(jj),'_',string(id),'_NA','.mat'),single(mask));
%         end
%     catch ME
%         ME
%     end
% end
% 
% return

% for jj = 1:1%height(demogs)
parfor (jj = 1:length(names),18)
    try
        jj
       imgbold = (load(names{jj}).img);
        if(min(size(imgbold))>=tslength)             
            imgbold = imgbold(:,1:tslength);
            imgbold = scale(imgbold, gmmask);
            noiz = imgbold(other_mask==1,:);
            imgbold = reshape(imgbold,[48,64,48,tslength]);
            x = randi(4)+1;
            y = randi(4)+1;
            z = randi(4)+1;
            s = (x*2+1)*(y*2+1)*(z*2+1);
            noiz = datasample(noiz,s,1,'Replace',false);
            mask = zeros([48,64,48]);
            rid = randi(length(idx));
            mask(idx(rid,1)-x:idx(rid,1)+x, idx(rid,2)-y:idx(rid,2)+y, idx(rid,3)-z:idx(rid,3)+z) = 1;
            bold = process(imgbold, mask, idx(rid,:), noiz);
            bold = clearMask(bold, gmmask, tslength);
            id = rand();
            finish(strcat('/data/ances2/NoiseID/bold/',string(jj),'_',string(id),'_','.mat'),single(round(bold,4)));
            finish(strcat('/data/ances2/NoiseID/mask/',string(jj),'_',string(id),'_','.mat'),single(mask));
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



