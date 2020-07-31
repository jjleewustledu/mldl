
count = 1;
% gmmask = load('gm_mask.mat').gm_mask;
% gmmask = reshape(gmmask, [48 64 48]);
gmmask = load('imgmask.mat').imgmask;

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

load('demographicsf.mat')
demogs2 = demogs;
tslength = 180;
% return
% for jj = 1:1%height(demogs)
parfor (jj = 1:height(demogs),18)
    try
        jj
        imgbold = [];
        imgbold2 = [];
        if(demogs2{jj,1}== 1)
            [imgbold,imgbold2] = getHIVBOLDS(char(demogs2{jj,2}));
        elseif(demogs2{jj,1}== 2)
            [imgbold,imgbold2] = getADRCBOLD(char(demogs2{jj,2}));
        else
            img = -9999;
        end
        imgbold = imgbold(:,1:end);
        imgbold2 = imgbold2(:,1:end);
        if(min(size(imgbold))>=tslength)
            imgbold = imgbold(:,1:tslength);
            imgbold2 = imgbold2(:,1:tslength);
            imgbold = scale(imgbold, gmmask);
            imgbold2 = scale(imgbold2, gmmask);
            x = randi(4)+1;
            y = randi(4)+1;
            z = randi(4)+1;
            mask = zeros([48,64,48]);
            rid = randi(length(idx));
            mask(idx(rid,1)-x:idx(rid,1)+x, idx(rid,2)-y:idx(rid,2)+y, idx(rid,3)-z:idx(rid,3)+z) = 1;
            mask = reshape(mask,[147456,1]);
            imgbold(mask==1,:) = imgbold2(mask==1,:);
            imgbold = reshape(imgbold,[48,64,48,tslength]);
            mask = reshape(mask,[48,64,48]);
            imgbold = clearMask(imgbold, gmmask, tslength);
            id = rand();
            finish(strcat('/data/ances2/NoiseID/bold/',string(jj),'_',string(id),'_XXX','.mat'),single(round(imgbold,4)));
            finish(strcat('/data/ances2/NoiseID/mask/',string(jj),'_',string(id),'_XXX','.mat'),single(mask));
        end
    catch ME
        ME
    end
end


function [imgbold,imgbold2] = getHIVBOLDS(s)
fMRIfilename = ['/data/ances2/HIV/BOLD_12_31_2017/' s '/FCmaps_uwrp/' s '_faln_dbnd_xr3d_uwrp_atl_DVAR2p5std_FD40_bpss_resid_g7_on_fn_711-2B_3mm.conc'];
fMRIfilename2 =  ['/data/ances2/HIV/BOLD_12_31_2017/' s '/FCmaps_uwrp/' s '_faln_dbnd_xr3d_uwrp_atl_DVAR2p5std_FD40.conc'];
if(~exist(fMRIfilename,'file'))
    fMRIfilename = ['/data/ances2/HIV/BOLD_12_31_2017/' s '/FCmaps_uwrp/' s '_faln_dbnd_xr3d_uwrp_atl_DVAR2p5std_FD30_bpss_resid_g7_on_fn_711-2B_3mm.conc'];
    fMRIfilename2 =  ['/data/ances2/HIV/BOLD_12_31_2017/' s '/FCmaps_uwrp/' s '_faln_dbnd_xr3d_uwrp_atl_DVAR2p5std_FD30.conc'];
end
if (exist(fMRIfilename,'file') && exist(fMRIfilename2,'file'))    
    imgbold = Load_4dfp_conc(fMRIfilename, 2, 0);
    imgbold =  imgbold.voxel_data;       
    imgbold2 = Load_4dfp_conc(fMRIfilename2, 2, 0);
    imgbold2 =  imgbold2.voxel_data;    
else
    imgbold = -9999;
    imgbold2 = -9999;
end
end



function [imgbold,imgbold2] = getADRCBOLD(s)
fMRIfilename = ['/data/nil-bluearc/ances/AD/AD_BOLD_04_07_2017/' s '/FCmaps_uwrp/' s '_faln_dbnd_xr3d_uwrp_atl_DVAR2p5std_FD40_bpss_resid_g7_on_fn_711-2B_3mm.conc'];
fMRIfilename2 =  ['/data/nil-bluearc/ances/AD/AD_BOLD_04_07_2017/' s '/FCmaps_uwrp/' s '_faln_dbnd_xr3d_uwrp_atl_DVAR2p5std_FD40.conc'];
if(~exist(fMRIfilename,'file'))
    fMRIfilename = ['/data/nil-bluearc/ances/AD/AD_BOLD_04_07_2017/' s '/FCmaps_uwrp/' s '_faln_dbnd_xr3d_uwrp_atl_DVAR2p5std_FD30_bpss_resid_g7_on_fn_711-2B_3mm.conc'];
    fMRIfilename2 =  ['/data/nil-bluearc/ances/AD/AD_BOLD_04_07_2017/' s '/FCmaps_uwrp/' s '_faln_dbnd_xr3d_uwrp_atl_DVAR2p5std_FD30.conc'];
end
if (exist(fMRIfilename,'file') && exist(fMRIfilename2,'file'))    
    imgbold = Load_4dfp_conc(fMRIfilename, 2, 0);
    imgbold =  imgbold.voxel_data;       
    imgbold2 = Load_4dfp_conc(fMRIfilename2, 2, 0);
    imgbold2 =  imgbold2.voxel_data;    
else
    imgbold = -9999;
    imgbold2 = -9999;
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










