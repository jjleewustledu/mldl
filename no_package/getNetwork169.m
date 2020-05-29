%% Received from Patrick Luckett in Oct 2019.

Nx = 48;
Ny = 64;
Nz = 48;
N3D = Nx*Ny*Nz;

% Read the brain mask
mask_name = strcat('glm_atlas_mask_333.4dfp.img');
%     fprintf('NOTE: if array values are bad, check endian\n');
fid = fopen(mask_name,'r');
if fid < 0; fprintf('Error: file not found %s\n',mask_name); end
imgmask = fread(fid, [1 N3D], 'float', 'b');
fclose(fid);

% Read the GM mask
GM_name = strcat('N21_aparc+aseg_GMctx_on_711-2V_333_avg.4dfp.img');
%     fprintf('NOTE: if array values are bad, check endian\n');
fid = fopen(GM_name,'r');
if fid < 0; fprintf('Error: file not found %s\n',GM_name); end
gm_mask = fread(fid, [1 N3D], 'float', 'l');
fclose(fid);
gm_mask = gm_mask > 0;

% Create the other mask of WM and CSF areas
other_mask = imgmask .* (1 - (gm_mask>0));
img3d = reshape(other_mask(1,:), [Nx Ny Nz]);
% erase the cerebellum from this mask
for i = 1:20
    img3d(:,:,i) = zeros(Nx,Ny);
end
img3d = binerode3d(img3d, 5);
other_mask = reshape(img3d, [1 N3D]);
npix_other = sum(other_mask > 0);


% 169 ROI data set
npix_169 = zeros(1,169);
ROImask169 = zeros([169, N3D], 'single'); % ROI mask set
ROIname169 = strcat('ROI_169z.4dfp.img'); % little endian
fid = fopen(ROIname169,'r');
if fid < 0; fprintf('Error: file not found %s\n',ROIname169); end
for i = 1:169
    ROImask169(i,:) = fread(fid, [1 N3D], 'float', 'l');
    npix_169(i) = sum(ROImask169(i,:));
    nsum = sum((ROImask169(i,:).*gm_mask)>0);
    navg = sum(ROImask169(i,:).*gm_mask)/npix_169(i);
end
fclose(fid);

% Calculate characteristic bolds of each RSN and the other/noise group
% 169set: VFN(1:12),VPN(13:29),DAN(30:53),SMN(54:78),AUD(79:93),
% CON(94:99),VAN(100:113),LAN(114:126),FPN(127:138),DMN(139:169)
rsn_names = cell(1,10);
rsn_names{1} = 'VFN';
rsn_names{2} = 'VPN';
rsn_names{3} = 'DAN';
rsn_names{4} = 'SMN';
rsn_names{5} = 'AUD';
rsn_names{6} = 'CON';
rsn_names{7} = 'VAN';
rsn_names{8} = 'LAN';
rsn_names{9} = 'FPN';
rsn_names{10}= 'DMN';
rsn_names{11}= 'OTH';
indlo = [1, 13, 30, 54, 79, 94, 100, 114, 127, 139, 170];
indhi = [12,29, 53, 78, 93, 99, 113, 126, 138, 169, 170];


RSNmasks = zeros([10, N3D], 'single');
RSNbolds = zeros(10, nbtot);
for i = 1:10
    for j = indlo(i):indhi(i)
        RSNmasks(i,:) = RSNmasks(i,:) + ROImask169(j,:);
    end
    RSNbolds(i,:) = roi_bold(imgbold, RSNmasks(i,:));
end

% do the same for the other/noise group
RSNbolds(11,:) = roi_bold(imgbold, other_mask);

                