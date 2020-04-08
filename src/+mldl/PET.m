classdef PET 
	%% PET support FDG only for now.  Adjust AIF methods for more tracers.
    %  @requires packages mlfourd, mlfourdfp, mlpet.

	%  $Revision$
 	%  was created 16-Nov-2019 15:17:11 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1216025 (R2019b) Update 1 for MACI64.  Copyright 2019 John Joowon Lee.
 	
    properties (Constant)
        TRACER = 'HO'
        %TAUS_FDG = [10,13,14,16,17,19,20,22,23,25,26,28,29,31,32,34,35,37,38,40,41,43,44,46,47,49,50,52,53,56,57,59,60,62,63,65,66,68,69,71,72,74,76,78,79,81,82,84,85,87,88,91,92,94,95,97,98,100,101,104,105,108]
        %TAUS_OC  = [3,3,3,3,3,3,3,3,5,5,5,5,6,6,6,6,6,7,7,7,7,8,8,8,9,9,10,10,11,11,12,13,14,15,16,18,19,22,24,28,33,39,49,64,49]
        %TAUS_OO  = [2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6,6,7,7,7,7,8,8,8,9,9,10,10,15]
        %TAUS_HO  = [3,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6,6,6,7,7,7,7,8,8,8,9,9,10,10,11,11,12,13,14,15,16,18,20,22,25,29,34,41,51,52]
    end
    
	properties
        aif
        atlas = 'TRIO_Y_NDC'
        mask
        mmppix = '222'
        identifier
        label
        studyDate
        t1
        times
        tracer
        tracerToT1T4
 		workLoc
    end
    
    properties (Dependent)
        atlasFile
        atlas_MMM
        brainMaskFile
        t1ToAtlasT4
        tracerKind
        tracerToAtlasT4
        uniformTimes
    end

	methods (Static)
        function runSubjects()
            ids = [35 36]; % 22 23 30 34 42
            for i = 1:length(ids)
                sid = sprintf('HYGLY%i', ids(i));
                mldl.PET.runSubject(sid)
            end
        end
        function runSubject(sid)
            homeVall = fullfile(getenv('PPG'), 'jjlee2', sid, 'Vall', '');
            homeDL = fullfile(getenv('DEEP_NET_FC_PROJECT'), 'DeepNetFCData', 'PET', 'HO', '');
            TRACERTags = {'_V1_HO1' '_V1_HO2' '_V2_HO1' '_V2_HO2' '_V3_HO1' '_V3_HO2'};
            tracerTags = {'1v1' '2v1' '1v2' '2v2' '1v3' '2v3'};
            len = length(tracerTags);
            
            ids = cellfun(@(x) [sid x], TRACERTags, 'UniformOutput', false);            
            lfs = cellfun(@(x) fullfile(homeVall, ['cbf' x '_op_fdgv1r1.4dfp.hdr']), tracerTags, 'UniformOutput', false);
            tfs = cellfun(@(x) fullfile(homeVall, ['ho' x 'r1_on_fdg.4dfp.hdr']), tracerTags, 'UniformOutput', false);            
            t1 = fullfile(homeVall, 'T1001.4dfp.hdr');
            t4 = fullfile(homeVall, 'fdg_to_T1001_t4');
            
            ensuredir(fullfile(homeDL, sid, ''))
            pwd0 = pushd(fullfile(homeDL, sid, ''));
            tmat = load(fullfile(homeDL, 'times.mat'));
            for i = 1:len
                try
                    if isfile(lfs{i})
                        pet = mldl.PET( ...
                            'Identifier', ids{i}, ...
                            'TracerFile', tfs{i}, ...
                            'LabelFile', lfs{i}, ...
                            'T1File', t1, ...
                            'TracerToT1T4', t4, ...
                            'Times', tmat.times);
                        pet.createMatFile
                    end
                catch ME
                    handwarning(ME)
                end
            end
            dataDir = fullfile(homeDL, [sid 'Data']);
            ensuredir(dataDir)
            try
                movefile('*.4dfp.*', dataDir)
                movefile('*t4', dataDir)
                movefile('*.log', dataDir)
            catch ME
                handwarning(ME)
            end
            popd(pwd0)
        end
        function saveMatFile(img, times, mask, label, doc, fn)
            assert(ndims(img) == 4)
            img = single(img);
            %assert(length(aif) == size(img, 4))
            %aif = single(ascol(aif));
            assert(length(times) == size(img, 4))
            times = single(ascol(times));
            assert(all(size(mask) == size(squeeze(img(:,:,:,1)))));
            mask = single(mask);
            assert(all(size(mask) == size(label)))
            label = single(label);
            assert(ischar(doc))
            assert(ischar(fn))
            save(fn, 'img', 'times', 'mask', 'label', 'doc', '-v7.3')            
        end
    end
    
	methods	  
        
        %% GET
        
        function g = get.atlasFile(this)
            g = fullfile(getenv('REFDIR'), [this.atlas_MMM '.4dfp.hdr']);
            assert(isfile(g))
        end
        function g = get.atlas_MMM(this)
            g = [this.atlas '_' this.mmppix];
        end
        function g = get.brainMaskFile(this)
            g = fullfile(getenv('REFDIR'), [this.atlas_MMM '_brain_mask.4dfp.hdr']);
            assert(isfile(g))
        end
        function g = get.t1ToAtlasT4(this)
            g = fullfile(this.workLoc, [this.t1.fileprefix '_to_' this.atlas '_t4']);
        end
        function g = get.tracerKind(this)            
            fp = this.tracer.fileprefix;
            if lstrfind(lower(fp), 'oc')
                g = 'oc';
                return
            end
            if lstrfind(lower(fp), 'oo')
                g = 'oo';
                return
            end
            if lstrfind(lower(fp), 'ho')
                g = 'ho';
                return
            end
        end
        function g = get.tracerToAtlasT4(this)
            g = fullfile(this.workLoc, [this.tracer.fileprefix '_to_' this.atlas '_t4']);
        end
        function g = get.uniformTimes(this)
            switch lower(this.tracerKind)
                case {'oc' 'co' 'oo' 'ho'}
                    g = 0:3:297;
                case 'fdg'
                    g = 0:10:3590;
                otherwise
                    error('mldl:RuntimeError', 'PET.get.uniformTimes')
            end
        end
        
        %%        
        
        function        assertLabelValues(this, lbl)
            meanlbl = mean(lbl.fourdfp.img(this.mask.fourdfp.img > 0));
            if meanlbl > 200 || meanlbl < 20
                error('mldl:RuntimeError', 'PET.assertLabelValues.meanlbl -> %g', meanlbl)
            end
        end
        function this = createMatFile(this, varargin)
            %% 
            
            %this.aif = this.extractAif();
            %this.aif = this.interpolate(this.aif);
            this.label = this.spatiallyNormalize(this.label);
            this.assertLabelValues(this.label)
            this.tracer = this.spatiallyNormalize(this.tracer);
            this.tracer = this.interpolate(this.tracer);
            doc = [':img: is a 4D-single containing dynamic PET\n' ...
                   ':times: is a 1D-single marking both img and aif\n' ...
                   ':mask: is a 3D-single masking in relevant voxels\n' ...
                   ':label: is a 3D-single containing the physiologic metric on which to train\n'];
            %      ':aif: is a 1D-single containing the arterial input function\n' ...
            fn = [this.identifier '.mat'];
            
            this.saveMatFile( ...
                this.tracer.fourdfp.img, this.uniformTimes, this.mask.fourdfp.img, this.label.fourdfp.img, doc, fn)
        end
        
 		function this = PET(varargin)
 			%% PET
            %  @param Identifier is char; to be used by learning objects.
 			%  @param WorkLoc is the filesystem location used for assembly of products.
            %  @param TracerFile is the filename of the dynamic tracer data.
            %  @param LabelFile is the filename for the physiologic metric to be used as a label for time-series
            %  @param T1File is the filename for T1{.mgz,.nii,.4dfp.hdr} produced by FreeSurfer's recon-all.
            %  @param TracerToT1T4 is the t4-file for tracer -> T1.
            %  @param times is numeric for seconds from start of scanning; prefer one of this.TIMES_*.
            %  @param 
            %  learning.
            
            import mlfourd.ImagingContext2

            ip = inputParser;
            addParameter(ip, 'Identifier', ['mldl.PET_DT' datestr(now, 'yyyymmddHHMMSS')], @ischar)
            addParameter(ip, 'StudyDate', datetime(), @isdatetime)
            addParameter(ip, 'WorkLoc', pwd, @isfolder)
            addParameter(ip, 'TracerFile', '', @isfile)
            addParameter(ip, 'LabelFile', '', @isfile)
            addParameter(ip, 'T1File', '', @isfile)
            addParameter(ip, 'TracerToT1T4', '', @isfile)
            addParameter(ip, 'Times', [], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
 			
            this.identifier = ipr.Identifier;
            this.studyDate = ipr.StudyDate;
            this.workLoc = ipr.WorkLoc;
            this.tracer = ImagingContext2(ipr.TracerFile);
            this.label = ImagingContext2(ipr.LabelFile);
            this.t1 = ImagingContext2(ipr.T1File);
            this.tracerToT1T4 = ipr.TracerToT1T4;
            this.times = ipr.Times;
            assert(~isempty(this.times))
            
            filestems = strsplit(this.tracer.fileprefix, '_');
            this.tracer.fourdfp
            this.tracer.fqfileprefix = fullfile(this.workLoc, filestems{1});
            filestems = strsplit(this.label.fileprefix, '_');
            this.label.fourdfp
            this.label.fqfileprefix = fullfile(this.workLoc, filestems{1});
            this.t1.fourdfp
            this.t1.fqfileprefix = fullfile(this.workLoc, 'T1001');
            this.mask = ImagingContext2(this.brainMaskFile);
            this.mask.fourdfp
 		end
    end
    
    %% PROTECTED
    
    methods (Access = protected)
        function aif = extractAif(this)
            switch this.tracerKind
                case {'oc' 'oo' 'ho'}
                    aif = this.extractAifHO();
                case 'fdg'
                    aif = this.extractAifFDG();
                otherwise
                    error('mldl:RuntimeError', 'PET.extractAif')
            end
        end
        function aif = extractAifHO(this)
        end
        function aif = extractAifFDG(this)
            meas = mlraichle.CCIRRadMeasurements.createFromDate(this.studyDate);
            isfdg = strcmp(meas.countsFdg.TRACER, '[18F]DG');
            kdpm_g = meas.countsFdg.TRUEDECAY_APERTURECORRGe_68_Kdpm_G(isfdg);
            Bq_mL = kdpm_g * (1000/60) * 1.06;
            times_ = meas.countsFdg.TIMEDRAWN_Hh_mm_ss(isfdg);
            times_ = seconds(times_ - times_(1)); % double
            
            aif = pchip(times_, Bq_mL, this.times);
        end
        function ic = filter(~, ic)
            ffp = ic.fourdfp;
            img1 = ffp.img;
            neg = ffp.img < 0;
            img1(neg) = 0;
            nn = imboxfilt3(img1);
            ffp.img(neg) = nn(neg);            
            ic = mlfourd.ImagingContext2(ffp);
        end
        function obj = interpolate(this, obj)
            if isnumeric(obj)
                obj = mlfourd.ImagingFormatContext(obj);
            end
            if isa(obj, 'mlfourd.ImagingContext2')
                obj = obj.fourdfp;
            end
            assert(isa(obj, 'mlfourd.ImagingFormatContext'))
            obj.img = pchip(this.times(1:size(obj.img, 4)), obj.img, this.uniformTimes);
            obj = mlfourd.ImagingContext2(obj);
        end
        function tracerLike = spatiallyNormalize(this, tracerLike, varargin)
            %% 
            %  @param tracerLike is mlfourd.ImagingContext2
            %  @returns tracerLike
            
            ip = inputParser;
            addOptional(ip, 'filt', false, @islogical)
            parse(ip, varargin{:})
            
            fv = mlfourdfp.FourdfpVisitor();
            pwd0 = pushd(this.workLoc);
            if ~isfile(this.t1ToAtlasT4)
                this.t1.save()
                fv.mpr2atl_4dfp(this.t1.fileprefix, 'options', ['-T' fullfile(getenv('REFDIR'), this.atlas)], 'log', 'mpr2atl_4dfp.log');
                assert(isfile(this.t1ToAtlasT4))
            end
            if ~isfile(this.tracerToAtlasT4)
                fv.t4_mul(this.tracerToT1T4, this.t1ToAtlasT4, this.tracerToAtlasT4);
            end
            if ~isfile([this.tracer.fileprefix '_avgt.4dfp.hdr'])
                tracerAvgt = this.tracer.timeAveraged;
                tracerAvgt.save()
            end
            if ~isfile([tracerLike.fileprefix '_on_' this.atlas_MMM '.4dfp.hdr'])
                if ip.Results.filt
                    tracerLike = this.filter(tracerLike);
                end
                tracerLike.save()
                fv.t4img_4dfp(this.tracerToAtlasT4, tracerLike.fileprefix, ...
                    'out', [tracerLike.fileprefix '_on_' this.atlas_MMM], ...
                    'options', ['-O' this.mmppix])
            end
            tracerLike = mlfourd.ImagingContext2([tracerLike.fileprefix '_on_' this.atlas_MMM '.4dfp.hdr']);
            tracerLike.fourdfp
            popd(pwd0)
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

