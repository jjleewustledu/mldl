classdef SimFDG 
	%% SIMFDG  

	%  $Revision$
 	%  was created 23-Apr-2020 18:52:11 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
    properties (Constant)
        HOME = '/Users/jjlee/Singularity/subjects_freesurfer/sub-S00000/resampling_restricted'
        mgdL_to_mmol = 0.05551
        pointspread = 4.3
    end
    
	properties
        activityArtery = [15.7231339417783 40.0670951423858 32.7896589986613 60.9033324985914 115.390827456407 20247.5870083001 138101.363561975 247624.893301051 219962.735811158 123800.355195601 84547.8333286971 74641.7780423665 61033.7705200579 51488.086840046 48137.398517549 45853.6272536275 43105.9076185098 40588.4399463862 39532.0074392734 37376.951543845 38029.7572601973 36896.5536596196 35837.3996944633 35239.9976922434 33563.3578174873 31172.6742405234 31661.2958727327 31726.6836574803 31190.0410893731 29736.9838758955 29345.5491772129 28612.6204028212 28087.9993320967 12488.6629201451 8478.08886746032 5324.32339588189 3353.30521211569 945.745212317361 665.76566052086]
        timesArtery = [0 3 7 10 14 18 22 25 30 35 39 44 48 52 55 58 63 67 70 74 78 81 84 90 93 95 98 103 106 109 113 117 120 417 597 897 1197 2997 3597]
        tausFdg = [10 13 14 16 17 19 20 22 23 25 26 28 29 31 32 34 35 37 38 40 41 43 44 46 47 49 50 52 53 56 57 59 60 62 63 65 66 68 69 71 72 74 76 78 79 81 82 84 85 87 88 91 92 94 95 97 98 100 101 104 105 108]

        huangValues
        normalValues
        powersValues
        parcMask
 		regionalMasks
        T1
        useHalos = false
        v1
    end
    
    properties (Dependent)
        glc
        uniformlySampledArtery
        LC
        timesFdg
    end
    
    methods (Static)
        function ic = createImagingLike(exemplar, img, fp)
            %  @param exemplar is understood by mlfourd.ImagingContext2().
            %  @param img is numeric.
            %  @param fp is char.
            
            if ~isa(exemplar, 'mlfourd.ImagingContext2')
                exemplar = mlfourd.ImagingContext2(exemplar);
            end            
            ifc = copy(exemplar.nifti);
            ifc.img = single(img);
            ifc.fileprefix = fp;
            ic = mlfourd.ImagingContext2(ifc);
        end
    end

	methods		
        
        %% GET

        function g = get.glc(this)
            g = this.normalValues('glc').init;
        end
        function g = get.uniformlySampledArtery(this)
            g = pchip(this.timesArtery, this.activityArtery, 0:this.timesFdg(end));
        end
        function g = get.LC(this)
            g = 0.81;
        end
        function g = get.timesFdg(this)
            g = cumsum(this.tausFdg);
            g = g - this.tausFdg/2;
        end
        
        %%
        
 		function this = SimFDG(varargin)
 			%% SIMFDG
 			%  @param .

            import mlfourd.ImagingContext2
            
            ip = inputParser;
            addParameter(ip, 'unitTesting', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            pwd0 = pushd(this.HOME);
            this.T1 = ImagingContext2('T1.nii.gz');
            this.parcMask = ImagingContext2('wmparc.nii.gz');
            this.regionalMasks = struct();
            this.regionalMasks.gwj  = ImagingContext2('gwjunction.nii.gz');
            if ~ipr.unitTesting
                this.regionalMasks.pial = ImagingContext2('pial.nii.gz');
                this.regionalMasks.gm   = ImagingContext2('gm.nii.gz');
                this.regionalMasks.wm   = ImagingContext2('wm.nii.gz');
                this.regionalMasks.bg   = ImagingContext2('bg.nii.gz');
                this.regionalMasks.thal = ImagingContext2('thalamus.nii.gz');
                this.regionalMasks.bs   = ImagingContext2('brainstem.nii.gz');
                this.regionalMasks.vasc = ImagingContext2('vascular.nii.gz');
            end
            %this.regionalMasks.csf  = ImagingContext2('csf.nii.gz');
            this.v1 = ImagingContext2('v1_on_T1.nii.gz');
            popd(pwd0)
            
            this.normalValues = containers.Map;
            this.normalValues('glc') = struct('min',  2,      'max', 17,     'init',  4.7,    'sigma', 1); % mmol
            this.normalValues('hct') = struct('min', 35.5,    'max', 48.6,   'init', 42,      'sigma', 3); % percent
            this.normalValues('v1')  = struct('min',  0.01,   'max',  1,     'init',  0.038,  'sigma', 0.007); % Ito, fraction
            
            this.normalValues('k1')  = struct('min',  0.001,  'max',  0.5,    'init',  0.03,   'sigma', 0.02);
            this.normalValues('k2')  = struct('min',  eps,    'max',  0.5,    'init',  0.003,  'sigma', 0.01);
            this.normalValues('k3')  = struct('min',  1e-4,   'max',  0.05,   'init',  0.003,  'sigma', 0.002);
            this.normalValues('k4')  = struct('min',  1e-5,   'max',  0.001,  'init',  0.0003, 'sigma', 0.0001);
            this.normalValues('cmr') = struct('min',  0.001,  'max',  0.06,   'init',  0.03,   'sigma', 0.005);
            
            this.huangValues = containers.Map;
            this.huangValues('k1')   = struct('min',  5e-3,   'max',  0.01,   'init',  0.002,  'sigma', 0.0005);
            this.huangValues('k2')   = struct('min',  eps,    'max',  0.01,   'init',  0.002,  'sigma', 0.001);
            this.huangValues('k3')   = struct('min',  1e-4,   'max',  0.005 , 'init',  0.001,  'sigma', 0.0003);
            this.huangValues('k4')   = struct('min',  1e-5,   'max',  0.0005, 'init',  0.0001, 'sigma', 0.00003);
            this.huangValues('cmr')  = struct('min',  0.001,  'max',  0.06,   'init',  0.03,   'sigma', 0.005); % Huang 1980, mmol/hg/min
            
            this.powersValues = containers.Map;
            this.powersValues('k1')  = struct('min',  0.001,  'max',  0.5,    'init',  0.03,   'sigma', 0.02); % Powers xlsx "Final Normals WB PET PVC & ETS", 1/sec
            this.powersValues('k2')  = struct('min',  0.001,  'max',  0.5,    'init',  0.003,  'sigma', 0.01);
            this.powersValues('k3')  = struct('min',  0.001,  'max',  0.05,   'init',  0.003,  'sigma', 0.002);
            this.powersValues('k4')  = struct('min',  0.0001, 'max',  0.001,  'init',  0.0003, 'sigma', 0.0001);
            this.powersValues('cmr') = struct('min',  0.001,  'max',  0.05,   'init',  0.026,  'sigma', 0.005); % Powers PNAS 2007, mmol/hg/min
        end                
        
        function c = chi(~, ks)
            %  @return scalar, 1/s -> 1/min
            
            k1 = ks(1);
            k2 = ks(2);
            k3 = ks(3);
            c = k1*k3/(k2 + k3);
            c = 60*c; 
        end
        function cmr = estimatedCMRglc(this, ks, v1)
            %  @param ks is numeric 4-vec.
            %  @param v1 is scalar.
            %  @return scalar mmol/hg/min.
            
            cmr = this.glc*v1*this.chi(ks)/this.LC;
            cmr = 0.1 * cmr / mloxygen.Martin1987.PLASMA_DENSITY; % mmol/L -> mmol/dL, mL plasma -> g plasma
        end
        function [cmr,ks] = estimatedKs(this, N, v1_, nvcmr, nvk1, nvk2, nvk3, nvk4)
            %  @param nvcmr is struct with:  nvcmr.min, nvcmr.max, nnvcmr.init, vcmr.sigma.
            %  @param nvk1 ...
            %  @param nvk2 ...
            %  @param nvk3 ...
            %  @param nvk4 ...
            %  @return numeric voxels, voxels (X) 4.
            
            cmr = -Inf(N, 1);
            ks = zeros(N, 4);
            for vxl = 1:N
                ks(vxl, 1) = min(max(nvk1.init + nvk1.sigma*randn(), nvk1.min), nvk1.max);
                ks(vxl, 2) = min(max(nvk2.init + nvk2.sigma*randn(), nvk2.min), nvk2.max);
                ks(vxl, 3) = min(max(nvk3.init + nvk3.sigma*randn(), nvk3.min), nvk3.max);
                ks(vxl, 4) = min(max(nvk4.init + nvk4.sigma*randn(), nvk4.min), nvk4.max);
                cmr(vxl) = this.estimatedCMRglc(ks, v1_(vxl));
                a = 0;
                while cmr(vxl) < nvcmr.min && a < 20
                    ks(vxl, 1) = min(max(2^a*nvk1.init + nvk1.sigma*randn(), nvk1.min), nvk1.max);
                    a = a + 1;
                end
                b = 0;
                while nvcmr.max < cmr(vxl) && b < 20
                    ks(vxl, 2) = min(max(nvk2.init/2^b + nvk2.sigma*randn(), nvk2.min), nvk2.max);
                    b = b + 1;
                end
            end
        end
        function fdg = huang1980Model(this, N, ks, v1_)
            %  @param N is scalar
            %  @param ks is numeric voxels (X) 4
            %  @param v1_ is numeric voxels
            %  @return numeric voxels (X) times.
            
            import mlglucose.Huang1980Model
            Nt = length(this.tausFdg);
            fdg = zeros(N, Nt);
            for vxl = 1:N
                fdg(vxl,:) = Huang1980Model.sampled(ks(vxl,:), v1_(vxl), this.uniformlySampledArtery, this.timesFdg);
            end
        end
        function [fdg,cmr,ks] = simulatedFdg(this)
            %  @return fdg,cmr,ks as mlfourd.ImagingContext2
            
            import mldl.SimFDG.createImagingLike
            
            fdgImg = zeros([size(this.T1) length(this.timesFdg)]);
            cmrImg = zeros( size(this.T1));
            ksImg  = zeros([size(this.T1) 4]);
            for fld = asrow(fields(this.regionalMasks))
                mskIC = this.regionalMasks.(fld{1});
                [fdgImg1,cmrImg1,ksImg1] = this.simulatedMaskedFdg(mskIC);
                fdgImg = fdgImg + fdgImg1;
                cmrImg = cmrImg + cmrImg1;
                ksImg  = ksImg  + ksImg1;
            end
            fdg = createImagingLike(mskIC, fdgImg, 'fdg');
            fdg.save()
            cmr = createImagingLike(mskIC, cmrImg, 'cmrglc');
            cmr.save()
            ks  = createImagingLike(mskIC,  ksImg, 'ks');
            ks.save()
        end
        function [fdg,cmr,ks] = simulatedMaskedFdg(this, mskIC)
            %  @param mask as mlfourd.ImagingContext2.
            %  @return fdg, cmr, ks as numeric.
            
            nvcmr = this.adjustedNormalValues('cmr', 'init', mskIC);
            nvk1  = this.adjustedNormalValues('k1', 'init', mskIC);
            nvk2  = this.adjustedNormalValues('k2', 'init', mskIC);
            nvk3  = this.adjustedNormalValues('k3', 'init', mskIC);
            nvk4  = this.adjustedNormalValues('k4', 'init', mskIC);
            v1_ = this.v1.nifti.img(logical(mskIC));
            fdg = zeros([size(mskIC) length(this.timesFdg)]);
            cmr = zeros( size(mskIC));
            ks  = zeros([size(mskIC) 4]);
            select = logical(mskIC);
            N = dipsum(select);
            
            [cmrVec,ksVec] = this.estimatedKs(N, v1_, nvcmr, nvk1, nvk2, nvk3, nvk4);
            fdgVec = this.huang1980Model(N, ksVec, v1_);
            for t = 1:size(fdg,4)
                vol = fdg(:,:,:,t);
                vol(select) = fdgVec(:,t);
                fdg(:,:,:,t) = vol;
            end
            cmr(select) = cmrVec;
            for k = 1:size(ks,4)
                vol = ks(:,:,:,k);
                vol(select) = ksVec(:,k);
                ks(:,:,:,k) = vol;
            end
        end        
        function v1 = simulatedV1(this)
            %  @return ImagingContext2
            
            img = zeros(size(this.T1));
            for fld = asrow(fields(this.regionalMasks))
                mskIC = this.regionalMasks.(fld{1});
                img = img + this.simulatedMaskedV1(mskIC);
            end
            v1 = copy(mskIC.nifti);
            v1.img = single(img);
            v1.fileprefix = 'v1';
            v1.save()
        end
        function v1 = simulatedMaskedV1(this, mskIC)
            %  @param mask as ImagingContext2
            %  @return numeric
            
            N = dipsum(logical(mskIC));
            v1str = this.adjustedNormalValues('v1', 'init', mskIC);
            mu_ = v1str.init;
            sigma_ = v1str.sigma; 
            min_ = v1str.min;
            v1 = zeros(size(mskIC));
            v1(logical(mskIC)) = max(mu_ + sigma_*randn([N 1]), min_);
            
            fprintf('simulatedMaskedV1: for %s, mu = %g, sigma = %g\n', ...
                mskIC.fileprefix, mu_, sigma_)
            
            if this.useHalos && lstrfind(mskIC.fileprefix, {'pial' 'gm'})
                haloIC = this.haloOf(mskIC);
                weight = haloIC.nifti.img(logical(haloIC));
                values = zeros(size(weight));
                for i = 1:length(values)
                    if rand() < weight(i) 
                        values(i) = max(mu_ + sigma_*randn(), min_);
                    end
                end
                w1 = zeros(size(haloIC));
                w1(logical(haloIC)) = values;
                
                v1 = v1 + w1;
            end
        end
        
        %% UTILITIES
        
        function keystr = adjustedNormalValues(this, key, fld, imaging)
            keystr = this.normalValues(key);            
            switch imaging.fileprefix
                case {'pial' 'vascular' }
                case 'gm'
                case {'gwjunction' 'bg' 'thalamus'}
                    switch key
                        case 'k1'
                            keystr.(fld) = 0.77*keystr.(fld);
                        case 'k2'
                            keystr.(fld) = 0.54*keystr.(fld);
                        case 'k3'
                            keystr.(fld) = 0.88*keystr.(fld);
                        case 'k4'
                            keystr.(fld) = 0.93*keystr.(fld);
                        case 'cmr'
                            keystr.(fld) = 0.73*keystr.(fld);
                    end
                case {'wm' 'brainstem'}
                    % Huang 1980 Table 1
                    switch key
                        case 'k1'
                            keystr.(fld) = 0.54*keystr.(fld);
                        case 'k2'
                            keystr.(fld) = 0.085*keystr.(fld);
                        case 'k3'
                            keystr.(fld) = 0.75*keystr.(fld);
                        case 'k4'
                            keystr.(fld) = 0.86*keystr.(fld);
                        case 'cmr'
                            keystr.(fld) = 0.45*keystr.(fld);
                    end 
                otherwise
                    error('mldl:ValueError', 'SimFDG.adjustedNormalValues.imaging.fileprefix was %s', imaging.fileprefix)
            end
        end
        function ic = haloOf(this, ic0)
            blurred = ic0.blurred(this.pointspread);            
            nii = blurred.nifti;
            nii.img(ic0.nifti.img > 0) = 0;
            nii.img = nii.img/dipmax(nii.img);
            ic = mlfourd.ImagingContext2(nii);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

