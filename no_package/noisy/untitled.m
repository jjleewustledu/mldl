











% files = dir('/data/ances/patrick/BOLDDATA/**/*.mat');
% count = 1;
% tmp = [];
% for i = length(files):-1:1
%     str = files(i).name;
%     if(contains(str, '_ADRC_'))
%         a = string(files(i).name(end-5:end-4));
%         tmp(count,1) = double(a);
%        count = count + 1;
%     end
% end
% return




addpath(genpath('/data/ances/patrick/NIfTI_20140122'));
% gmmask = load('gm_mask.mat').gm_mask;
% gmmask = reshape(gmmask, [48 64 48]);
gmmask = load('imgmask.mat').imgmask;
files = dir('/data/ances/patrick/ShimonyProject/Epilepsy/**/*.mat');
for i = 1:length(files)
%     try
        c = zeros([48,64,48]);
        if(contains(files(i).name,'PT'))
            if(contains(files(i).name,'_BOLD.mat'))
                i
                dat = load([files(i).folder,'/',files(i).name]).dat;   
                dat = clearMask(dat, gmmask); 
                count = 0;
                for j = 1:90:size(dat,4)-200
                    count = count + 1;
                    data = dat(:,:,:,j:j+179);
                    data = clearMask(data,gmmask);
                    %C = single((semanticseg(data, trainedNet)))-1;
                    C = activations(trainedNet,data,'reg');
                    C(isnan(C))=0;
                    C(C<0)=0;
                    C(C>1)=1;   
                    C2=C;
                    C = imboxfilt3(C,[5,5,5]); 
                    [~,~,C] = histcounts(C,'BinMethod','fd');
                    C = C-floor(max(C(:))/4);
                    C(C<=0)=0;
                    C = C./max(C(:));                                          
                    C = C*max(C2(:));
                    c = c+C;
                end  
                c = imboxfilt3(c,[3,3,3]);
                c(~gmmask) = 0;
                [~,~,c] = histcounts(c,'BinMethod','fd'); 
                c = imboxfilt3(c,[3,3,3]);
                c = c-floor(max(c(:))/5);
                c(c<=0)=0;
                [~,~,c] = histcounts(c,'BinMethod','fd');                
                datt = c;
                datt(~gmmask) = 0;
                save(['/data/ances/patrick/ShimonyProject/Epilepsy/results/M_',files(i).name],'datt');
                mat = make_nii(datt,[3,3,3],[73.5, -87, -84]);
                save_nii(mat, ['/data/ances/patrick/ShimonyProject/Epilepsy/results/',files(i).name,'.nii']);
            end
        end   
end


% C = c.img;
% mat = make_nii(C,[3,3,3],[73.5, -87, -84]);
% save_nii(mat, [pwd,'/img3.nii']);

return

% data = load('/data/ances2/NoiseIDV/mask/984_0.6056_uniform.mat').dat;
% mat = make_nii(C,[3,3,3],[73.5, -87, -84]);
% save_nii(mat, [pwd,'/epitest']);




function img = scale(img,mask)
parfor i = 1:147456
    img(i,:) = rescale(img(i,:),-1,1);
end
img(isnan(img))=0;
end

function bold = clearMask(img,mask)
if(length(size(img))~=2)
    img = reshape(img,[147456 , size(img,4)]);
end
bold = img;
mask = reshape(mask,[147456 , 1]);
bold(mask==0,:) = bold(mask==0,:).*0;
bold = scale(bold,mask);
bold(isnan(bold))=0;
bold = reshape(bold,[48, 64, 48, size(bold,2)]);
end














