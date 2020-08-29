classdef Correlations 
	%% CORRELATIONS  

	%  $Revision$
 	%  was created 20-Aug-2020 18:43:08 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.8.0.1417392 (R2020a) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
 		
    end
    
    methods (Static)
        function buildAll()
            import mlfourd.ImagingContext2
            import mldl.Correlations.buildAvgXcorr
            import mldl.Correlations.buildXcorr
            
            work = '/Users/jjlee/Google Drive/FocalEpilepsy';
            cd(work)
            jjl = ImagingContext2(fullfile('JJL_segmentation_333_z23to25.nii.gz'));
            jjlr = ImagingContext2(fullfile('JJL_segmentation_333_z23to25_flip1.nii.gz'));
            pt36_bpss = ImagingContext2(fullfile('PT36', 'PT36_faln_dbnd_xr3d_atl_g7_bpss.nii.gz'));
            msc01_bpss = ImagingContext2(fullfile('msc01_bpss.nii.gz'));            
            
            buildAvgXcorr(pt36_bpss,  jjl,  'fsleyes', true)
            buildAvgXcorr(pt36_bpss,  jjlr, 'fsleyes', true, 'filenameTag', '_flip1')
            buildAvgXcorr(msc01_bpss, jjl,  'fsleyes', true)
            buildAvgXcorr(msc01_bpss, jjlr, 'fsleyes', true, 'filenameTag', '_flip1')
        end
        function cc = buildCorrcoef(bold, seeds)
            %  @param required bold is understood by mlfourd.ImagingContext2.
            %  @param required seeds is "; it is a mask.
            %  @return ImagingContext2 sized [size(seeds) size(find(seeds))].
            
            import mlfourd.ImagingContext2 
            
            bold = ImagingContext2(bold);
            S_bold = size(bold);
            N_bold = prod(S_bold(1:3));
            bold = reshape(bold, [N_bold S_bold(4)]);
            
            seeds = ImagingContext2(seeds);
            S_seeds = size(seeds);
            assert(all(S_seeds == S_bold(1:3))) 
            seeds = reshape(seeds, [prod(S_seeds) 1]);
            seeds = seeds.binarized();
            seeds_found = find(seeds.nifti.img); % length ~ 200
            N_seeds = length(seeds_found);

            % building
            cc_ = zeros([N_bold N_seeds], 'single');
            bold_ = bold.nifti.img';
            for i_found = 1:N_seeds          
                x = bold_(:, seeds_found(i_found));
                for i_bold = 1:N_bold
                    y = bold_(:, i_bold);
                    mat = corrcoef(x, y); % symmetric 2 x 2
                    cc_(i_bold, i_found) = mat(1, 2);
                end
            end
            cc = copy(bold.nifti);
            cc.img = reshape(cc_, [S_bold(1:3) N_seeds]);
            cc.fileprefix = [bold.fileprefix '_corrcoef'];
            cc = mlfourd.ImagingContext2(cc);
        end
        function cc = buildAvgCorrcoef(bold, seeds)
            %  @param required bold is understood by mlfourd.ImagingContext2.
            %  @param required seeds is "; it is a mask.
            %  @return ImagingContext2 sized size(seeds).
            cc = mldl.Correlations.buildCorrcoef(bold, seeds);
            cc = cc.timeAveraged();
            cc.fileprefix = [bold.fileprefix '_avgCorrcoef'];
        end
        function cc = buildCorrcoefWithAvgSeed(bold, seeds)
            %  @param required bold is understood by mlfourd.ImagingContext2.
            %  @param required seeds is "; it is a mask.
            %  @return ImagingContext2 sized size(seeds).
            
            import mlfourd.ImagingContext2            
            
            bold = ImagingContext2(bold);
            S_bold = size(bold);
            N_bold = prod(S_bold(1:3));
            bold = reshape(bold, [N_bold S_bold(4)]);
            
            seeds = ImagingContext2(seeds);
            S_seeds = size(seeds);
            assert(all(S_seeds == S_bold(1:3))) 
            seeds = reshape(seeds, [prod(S_seeds) 1]);
            seeds = seeds.binarized();
            seeds_found = logical(seeds.nifti.img); % length ~ 200

            % building
            cc_ = zeros([N_bold 1], 'single');
            bold_ = bold.nifti.img';            
            x = mean(bold_(:, seeds_found), 2); % average over seeds
            for i_bold = 1:N_bold
                y = bold_(:, i_bold);
                mat = corrcoef(x, y); % symmetric 2 x 2
                cc_(i_bold) = mat(1, 2);
            end            
            cc = copy(bold.nifti);
            cc.img = reshape(cc_, S_bold(1:3));
            cc.fileprefix = [bold.fileprefix '_corrcoefWithAvgSeed'];
            cc = mlfourd.ImagingContext2(cc);
        end    
        function [xcs,lags] = buildXcorr(bold, seeds, varargin)
            %  @param required bold is understood by mlfourd.ImagingContext2.
            %  @param required seeds is "; it is a mask.
            %  @param maxlag <= size(bold,4) - 1.
            %  @param doaverage is logical.
            %  @param dosave is logical.
            %  @param fsleyes is logical.
            %  @param filenameTag is char.
            %  @return ImagingContext2 sized[size(seeds) N_lags],  
            %          N_lags := 2*maxlag + 1, if averageSeeds.
            %  @return cell of ImagingContext2 sized N_lags \otimes [size(seeds) size(find(seeds))],  
            %          N_lags := 2*maxlag + 1, if ~averageSeeds.
            %  @return lags
            
            import mlfourd.ImagingContext2  
            
            ip = inputParser;
            addParameter(ip, 'maxlag', 20, @isnumeric)
            addParameter(ip, 'doaverage', false, @islogical)
            addParameter(ip, 'dosave', true, @islogical)
            addParameter(ip, 'fsleyes', false, @islogical)
            addParameter(ip, 'filenameTag', '', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            bold = ImagingContext2(bold);
            S_bold = size(bold);
            N_bold = prod(S_bold(1:3));
            bold = reshape(bold, [N_bold S_bold(4)]);
            
            seeds = ImagingContext2(seeds);
            S_seeds = size(seeds);
            assert(all(S_seeds == S_bold(1:3))) 
            seeds = reshape(seeds, [prod(S_seeds) 1]);
            seeds = seeds.binarized();
            seeds_found = find(seeds.nifti.img); % length ~ 200
            N_seeds = length(seeds_found);
            
            ipr.maxlag = min(N_bold, ipr.maxlag);
            N_lags = 2*ipr.maxlag + 1;
            lags = [-ipr.maxlag:0 1:ipr.maxlag]; % =: 1 x N_lags
            
            % building
            img_ = zeros(N_lags, N_bold, N_seeds, 'single');
            bold_ = bold.nifti.img';
            for i_found = 1:N_seeds          
                x = bold_(:, seeds_found(i_found));
                tic
                for i_bold = 1:N_bold
                    y = bold_(:, i_bold);
                    r = xcorr(x, y, ipr.maxlag); % N_lags x 1, 1 x N_lags
                    img_(:, i_bold, i_found) = r;
                end
                fprintf('i_found->%i ', i_found)
                toc
                fprintf('\n')
            end

            % load('img_80-120.mat', 'img_') % DEBUGGING
            
            % average xcorr of seeds, save, fsleyes
            if ipr.doaverage                
                xc = copy(bold.nifti);
                xc.img = zeros([S_bold(1:3) N_lags], 'single');
                for i_lag = 1:N_lags
                    img__ = reshape(img_(i_lag,:,:), [S_bold(1:3) N_seeds]);
                    xc.img(:,:,:,i_lag) = mean(img__, 4);
                end
                xc.fileprefix = sprintf('%s_xcorr%s', bold.fileprefix, ipr.filenameTag);
                xcs = mlfourd.ImagingContext2(xc);
                if ipr.dosave
                    xcs.save()
                end
                if ipr.fsleyes
                    xcs.fsleyes()
                end
                return
            end
            
            % retain seeds, save, fsleyes
            xcs = cell(1, N_lags);
            for i_lag = 1:N_lags
                xc = copy(bold.nifti);
                xc.img = reshape(img_(i_lag,:,:), [S_bold(1:3) N_seeds]);
                xc.fileprefix = sprintf('%s_xcorr%i%s', bold.fileprefix, lags(i_lag), ipr.filenameTag);
                xcs{i_lag} = mlfourd.ImagingContext2(xc);
                if ipr.dosave
                    xcs{i_lag}.save()
                end
                if ipr.fsleyes
                    xcs{i_lag}.fsleyes()
                end
            end
        end    
        function [xc,lags] = buildAvgXcorr(bold, seeds, varargin)
            %  @param required bold is understood by mlfourd.ImagingContext2.
            %  @param required seeds is "; it is a mask.
            %  @param maxlag <= size(bold,4) - 1.
            %  @param dosave is logical.
            %  @param fsleyes is logical.
            %  @return ImagingContext2 sized[size(seeds) N_lags],  
            %          N_lags := 2*maxlag + 1, if averageSeeds.
            %  @return cell of ImagingContext2 sized N_lags \otimes [size(seeds) size(find(seeds))],  
            %          N_lags := 2*maxlag + 1, if ~averageSeeds.
            %  @return lags
            
            [xc,lags] = mldl.Correlations.buildXcorr(bold, seeds, varargin{:}, 'doaverage', true);
        end
    end

	methods 
		  
 		function this = Correlations(varargin)
 			%% CORRELATIONS
 			%  @param .

 			
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

