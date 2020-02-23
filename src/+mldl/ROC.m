classdef ROC < handle
	%% ROC  

	%  $Revision$
 	%  was created 20-Jan-2020 14:36:17 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
    properties (Constant)
        N_SUBJ = 35;
    end
    
	properties (Dependent)
        averageTestGM
        averageTestLH
        label
        labelSampleGM
        labelSampleLH
        labelSamplesGM
        labelSamplesLH
        GM
 		LH
        NS
        NSb
        NSw
        RH
        test
        testSamplesGM
        testSamplesLH
    end
    
    properties
        nspath = '/Users/jjlee/Box/DeepNetFCProject/Donnas_Tumors/Neurosynth'
        toppath = '/Users/jjlee/Box/DeepNetFCProject/Donnas_Tumors'
        workpath 
    end
    
    methods (Static)
        function spth = auxpath2subjpath(apth)
            auxfld = basename(apth); % RS003_frames1to100
            kindpth = fileparts(apth); % */Donnas_Tumors/DNN_100frames
            toppth  = fileparts(kindpth); % */Donnas_Tumors
            
            ss = strsplit(auxfld, '_frames'); % { 'RS003', ... }
            spth = fullfile(toppth, ss{1});
        end
        function ifc = imdilate(filename, varargin)
            ip = inputParser;
            addParameter(ip, 'radius', 1, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            ifc = mlfourd.ImagingFormatContext(filename);
            sph = strel('sphere', ipr.radius);
            ifc.img = imdilate(ifc.img, sph);
            ifc.fileprefix = sprintf('%s_imdilate%s', ifc.fileprefix, strrep(num2str(ipr.radius), '.', 'p'));
            ifc.save
        end
        function ifc = imdilatex(filename, varargin)
            ip = inputParser;
            addParameter(ip, 'radius', 3, @isnumeric)
            addParameter(ip, 'shift', -1, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            ifc = mlfourd.ImagingFormatContext(filename);
            sph = strel('line', ipr.radius, 90);
            ifc.img = imdilate(ifc.img, sph);
            ifc.img = circshift(ifc.img, ipr.shift, 1);
            ifc.fileprefix = sprintf('%s_imdilate%sx', ifc.fileprefix, strrep(num2str(ipr.radius), '.', 'p'));
            ifc.save
        end
        function stage_all_mpr_on_atl()
            
            mkrs = '/data/nil-bluearc/shimony/mkrs';
            rs_list = readtable(fullfile( ...
                mkrs, 'Resting', 'Donnas_list_of_preferred_tfMRI_cases.txt'), 'Format', '%s', 'Delimiter', '\n');
            rs_list1 = rs_list.Folder;
            rs_list1 = rs_list1(2:end);
            
            % glob and copy MPR from Resting/ to DNN/
            for r = rs_list1'
                
                % r{1} ~ "RS_047_MR_20141126_resttask_blan1_faln_dbnd_xr3d_atl_actmap_g7"
                % target ~ "RS_003_MR_20140103_resttask_mpr_n1_111_t88.4dfp.img"
                
                re = regexp(r{1}, '(?<rs>RS_\d{3})_(?<mr>MR_\d{8}_resttask)_\S+', 'names');
                mpr_to_glob = fullfile( ...
                    mkrs, 'Resting', ...
                    sprintf('%s/%s_%s/atlas/%s_%s_*mpr_n*_*_t88.4dfp.*', re.rs, re.rs, re.mr, re.rs, re.mr));
                dnn_rs = strrep(re.rs, '_', '');
                for g = globT(mpr_to_glob)
                    copyfile(g{1}, fullfile(mkrs, 'DNN', dnn_rs))
                end
            end
        end
        function [nets,lan,mpr333] = stageNIfTIPrimary(subjpth)
            
            import mlfourd.ImagingContext2
            
            g = globT(fullfile(subjpth, 'RS_*_MR_*_resttask_*mpr_n*_333_t88.4dfp.hdr'));
            mpr333 = ImagingContext2(g{1});
            mpr333.nifti;
            mpr333.filename = fullfile(subjpth, 'mpr_333.nii.gz');
            mpr333.save;
            
            g = globT(fullfile(subjpth, 'DeepNetRS*', 'networks.img'));
            nets = ImagingContext2.fread(g{1});
            nets.fqfilename = fullfile(subjpth, 'networks.nii.gz');
            nets.save;
            
            g = globT(fullfile(subjpth, 'DeepNetRS*', 'smoothprobability', 'lan.img'));
            lan = ImagingContext2.fread(g{1});
            lan.fqfilename = fullfile(subjpth, 'lan.nii.gz');
            lan.save;
            
            mlbash(sprintf('fsleyes %s %s -cm %s -a 17 %s -cm %s -a 33', ...
                fullfile(subjpth, 'mpr_333.nii.gz'), ...
                fullfile(subjpth, 'lan.nii.gz'), 'hot', ...
                fullfile(subjpth, 'networks.nii.gz'), 'hsv'));
        end
        function stageNIfTIAuxiliary(auxpth)
            
            import mldl.ROC
            
            subjpth = ROC.auxpath2subjpath(auxpth);
            g = globT(fullfile(subjpth, 'networks.nii.gz'));
            copyfile(g{1}, auxpth)
            
            g = globT(fullfile(auxpth, 'DeepNetRS*', 'smoothprobability', 'lan.img'));
            lan = mlfourd.ImagingContext2.fread(g{1});
            lan.fqfilename = fullfile(auxpth, 'lan.nii.gz');
            lan.save;
            
            mlbash(sprintf('fsleyes %s %s -cm %s -a 17 %s -cm %s -a 33', ...
                fullfile(subjpth, 'mpr_333.nii.gz'), ...
                fullfile(auxpth, 'lan.nii.gz'), 'hot', ...
                fullfile(auxpth, 'networks.nii.gz'), 'hsv'));
        end
    end
    
	methods 
        
        %% GET
        
        function g = get.averageTestGM(this)
            if ~isempty(this.averageTestGM_)
                g = this.averageTestGM_;
                return
            end
            this.averageTestGM_ = this.createAverageTestGM();
            g = this.averageTestGM_;
        end
        function g = get.averageTestLH(this)
            if ~isempty(this.averageTestLH_)
                g = this.averageTestLH_;
                return
            end
            this.averageTestLH_ = this.createAverageTestLH();
            g = this.averageTestLH_;
        end
        function g = get.label(this)
            g = this.label_;            
        end
        function g = get.labelSampleGM(this)
            g = this.label.img(this.GM.img ~= 0);
        end
        function g = get.labelSampleLH(this)
            g = this.label.img(this.LH.img ~= 0);
        end
        function g = get.labelSamplesGM(this)
            g = repmat(this.labelSampleGM', [1 this.N_SUBJ]);
            g = reshape(g, [size(this.labelSampleGM') this.N_SUBJ]);
            g = this.reshape2vec(g);
            this.assert0to1(g);
        end
        function g = get.labelSamplesLH(this)
            g = repmat(this.labelSampleLH', [1 this.N_SUBJ]);
            g = reshape(g, [size(this.labelSampleLH') this.N_SUBJ]);
            g = this.reshape2vec(g);
            this.assert0to1(g);
        end
        function g = get.GM(this)
            if ~isempty(this.GM_)
                g = this.GM_;
                return
            end            
            this.GM_ = mlfourd.ImagingFormatContext(fullfile(this.toppath, 'gm3d.nii.gz'));
            g = this.GM_;
        end
        function g = get.LH(this)
            if ~isempty(this.LH_)
                g = this.LH_;
                return
            end            
            this.LH_ = mlfourd.ImagingFormatContext(fullfile(this.toppath, 'LHemis.nii.gz'));
            g = this.LH_;
        end
        function g = get.NS(this)
            if ~isempty(this.NS_)
                g = this.NS_;
                return
            end
            this.NS_ = mlfourd.ImagingFormatContext(fullfile(this.nspath, 'ns_lan.nii.gz'));
            g = this.NS_;
        end
        function g = get.NSb(this)
            if ~isempty(this.NSb_)
                g = this.NSb_;
                return
            end
            this.NSb_ = mlfourd.ImagingFormatContext(fullfile(this.nspath, 'ns_broca.nii.gz'));
        end
        function g = get.NSw(this)
            if ~isempty(this.NSw_)
                g = this.NSw_;
                return
            end
            this.NSw_ = mlfourd.ImagingFormatContext(fullfile(this.nspath, 'ns_wernicke.nii.gz'));
        end
        function g = get.RH(this)
            if ~isempty(this.RH_)
                g = this.RH_;
                return
            end
            this.RH_ = mlfourd.ImagingFormatContext(fullfile(this.toppath, 'RHemis.nii.gz'));
            g = this.RH_;
        end
        function g = get.test(this)
            g = this.test_;
        end
        function g = get.testSamplesGM(this)
            Ngm = dipsum(this.GM.img(this.GM.img ~= 0));
            g = zeros(Ngm, this.N_SUBJ);
            for s = 1:this.N_SUBJ
                img = this.test.img(:,:,:,s);
                img = img(this.GM.img ~= 0);
                g(:, s) = img;
            end
            g = this.reshape2vec(g);
            this.assert0to1(g);
        end
        function g = get.testSamplesLH(this)
            Nlh = dipsum(this.LH.img(this.LH.img ~= 0));
            g = zeros(Nlh, this.N_SUBJ);
            for s = 1:this.N_SUBJ
                img = this.test.img(:,:,:,s);
                img = img(this.LH.img ~= 0);
                g(:, s) = img;
            end
            g = this.reshape2vec(g);
            this.assert0to1(g);
        end
        
        %%
        
        function fsleyesWithLabel(this)
            %if ~isfile(this.label.fqfilename) && ~isempty(this.label.img)
            %    this.label.save
            %end
            this.test.fsleyes(this.label.fqfilename)
        end
        function [x,y,t,auc] = perfcurve(this, varargin)
            [x,y,t,auc] = perfcurve( ...
            this.labelSamplesGM' > 0, ...
            this.testSamplesGM, ...
            true, varargin{:});
        end
        function [x,y,t,auc] = perfcurveAverages(this, varargin)
            N = dipsum(this.GM);
            labelSmpl = this.labelSamplesGM(1:N);
            testSmpl = this.averageTestGM.img(this.GM.img ~= 0);
            [x,y,t,auc] = perfcurve( ...
                labelSmpl' > 0, ...
                testSmpl, ...
                true, varargin{:});
        end
		  
 		function this = ROC(varargin)
 			%% ROC
 			%  @param test is an mlfourd.ImagingFormatContext or 'DNN' or 'DNN_100frames' or 'task'
 			
            import mlfourd.ImagingFormatContext
            ip = inputParser;
            addParameter(ip, 'test',  'DNN',   @(x) isa(x, 'mlfourd.ImagingFormatContext') || ischar(x))
            addParameter(ip, 'label', this.NS, @(x) isa(x, 'mlfourd.ImagingFormatContext'))
            addParameter(ip, 'workpath', this.toppath, @isfolder)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.test_ = ipr.test;            
            this.label_ = ipr.label;
            this.workpath = ipr.workpath;

            if isa(this.test_, 'mlfourd.ImagingFormatContext')
                this.testType_ = this.test_.fileprefix;
            end
            if ischar(this.test_)
                this.testType_ = this.test_;
                switch this.test_
                    case 'DNN'
                        pwd0 = pushd(fullfile(this.toppath));
                        img = zeros(size(this.LH));
                        ig = 0;
                        for g = globFoldersT('RS0*')
                            ig = ig + 1;
                            ifc = ImagingFormatContext(fullfile(g{1}, 'lan.nii.gz'));
                            img(:,:,:,ig) = ifc.img;
                        end
                        this.test_ = ImagingFormatContext( ...
                            img, ...
                            'fqfilename', fullfile(this.workpath, 'lan_x35_DNN.nii.gz'), ...
                            'mmppix', [3 3 3], ...
                            'originator', [72 96 72]);
                        popd(pwd0)
                    case {'DNN_100frames' 'DNN100'}
                        pwd0 = pushd(fullfile(this.toppath, 'DNN_100frames'));
                        img = zeros(size(this.LH));
                        ig = 0;
                        for g = globFoldersT('RS0*')
                            ig = ig + 1;
                            ifc = ImagingFormatContext(fullfile(g{1}, 'lan.nii.gz'));
                            img(:,:,:,ig) = ifc.img;
                        end
                        this.test_ = ImagingFormatContext( ...
                            img, ...
                            'fqfilename', fullfile(this.workpath, 'lan_x35_DNN_100frames.nii.gz'), ...                            
                            'mmppix', [3 3 3], ...
                            'originator', [72 96 72]);
                        popd(pwd0)
                    case 'task'
                        this.test_ = ImagingFormatContext( ...
                            fullfile(this.toppath, 'Park_Proj_Language', 'Data', 'LNtask_MAP.nii.gz'), ...
                            'mmppix', [3 3 3], ...
                            'originator', [72 96 72]);
                end
            end
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        averageTestGM_
        averageTestLH_
        label_
        GM_
        LH_
        NS_
        NSb_
        NSw_
        RH_
        test_
        testType_
    end
    
    methods (Access = protected)
        function assert0to1(~, img)
            assert(dipmin(img) == 0);
            assert(dipmax(img) <= 1);
        end
        function averTest = createAverageTestGM(this)
            Ngm = dipsum(this.GM);
            testarr = reshape(this.testSamplesGM, [Ngm this.N_SUBJ]);
            testarr = mean(testarr, 2)';
            img = zeros(48,64,48);
            img(this.GM.img ~= 0) = testarr;
            averTest = copy(this.GM);
            averTest.img = img;
            averTest.filepath = this.toppath;
            averTest.filename = sprintf('average%s%sGM.nii.gz', upper(this.testType_(1)), this.testType_(2:end));
            averTest.save
        end
        function averTest = createAverageTestLH(this)
            Nlh = dipsum(this.LH);
            testarr = reshape(this.testSamplesLH, [Nlh this.N_SUBJ]);
            testarr = mean(testarr, 2)';
            img = zeros(48,64,48);
            img(this.LH.img ~= 0) = testarr;
            averTest = copy(this.LH);
            averTest.img = img;
            averTest.filepath = this.toppath;
            averTest.filename = sprintf('average%s%sLH.nii.gz', upper(this.testType_(1)), this.testType_(2:end));
            averTest.save
        end
        function v = reshape2vec(~, img)
            v = reshape(img, [1 numel(img)]);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

