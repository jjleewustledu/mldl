classdef ROC < handle
	%% ROC  

	%  $Revision$
 	%  was created 20-Jan-2020 14:36:17 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Dependent)
        averDnnLan
 		LH
    end
    
    properties
        labelSamples
        lanSamples
        workpath = '/Users/jjlee/Box/DeepNetFCProject/Donnas_Tumors'
    end
    
    methods (Static)
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
    end

	methods 
        
        %% GET
        
        function g = get.averDnnLan(this)
            if ~isempty(this.averDnnLan_)
                g = this.averDnnLan_;
                return
            end
            this.averDnnLan_ = this.createAverDeepLan();
            g = this.averDnnLan_;
        end
        function g = get.LH(this)
            if ~isempty(this.LH_)
                g = this.LH_;
                return
            end            
            this.LH_ = mlfourd.ImagingFormatContext(fullfile(this.workpath, 'LHemis.nii.gz'));
            g = this.LH_;
        end
        
        %%
        
        function [x,y,t,auc] = perfcurve(this)
            [x,y,t,auc] = perfcurve(this.labelSamples == 1, this.lanSamples, 'true');
        end
        function [x,y,t,auc] = perfcurveAverages(this)
            N = dipsum(this.LH);
            labelSample = this.labelSamples(1:N);            
            lanSample = this.averDnnLan.img(this.LH.img ~= 0);
            [x,y,t,auc] = perfcurve(labelSample == 1, lanSample, 'true');
        end
		  
 		function this = ROC(varargin)
 			%% ROC
 			%  @param .
 			
            import mlfourd.ImagingFormatContext
            ip = inputParser;
            addParameter(ip, 'label', [], @(x) isa(x, 'mlfourd.ImagingFormatContext'))
            parse(ip, varargin{:})
            ipr = ip.Results;            
            
            pwd0 = pushd(this.workpath);
            
            this.lanSamples  = zeros(dipsum(this.LH), 35);
            this.labelSamples = zeros(dipsum(this.LH), 35);
            ig = 0;
            for g = globFoldersT('RS0*')
                ig = ig + 1;
                lan = ImagingFormatContext(fullfile(g{1}, 'lan.nii.gz'));
                this.lanSamples(:,ig) = lan.img(this.LH.img ~= 0);
                this.labelSamples(:,ig) = ipr.label.img(this.LH.img ~= 0);
            end
            this.labelSamples = reshape(this.labelSamples, [1 numel(this.labelSamples)]);
            this.lanSamples   = reshape(this.lanSamples,   [1 numel(this.lanSamples)]);
            assert(min(this.labelSamples) == 0);
            assert(max(this.labelSamples) == 1);
            assert(min(this.lanSamples) == 0);
            assert(max(this.lanSamples) <= 1);
            
            popd(pwd0)
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        averDnnLan_
        LH_
    end
    
    methods (Access = protected)
        function averDnnLan = createAverDeepLan(this)
            N = dipsum(this.LH);
            lanAverage = reshape(this.lanSamples, [N 35]);
            lanAverage = mean(lanAverage, 2)';
            img = zeros(48,64,48);
            img(this.LH.img ~= 0) = lanAverage;
            averDnnLan = copy(this.LH);
            averDnnLan.img = img;
            averDnnLan.filepath = this.workpath;
            averDnnLan.filename = 'averDnnLan.nii.gz';
            averDnnLan.save
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

