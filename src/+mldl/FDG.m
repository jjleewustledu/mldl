classdef FDG 
	%% FDG  

	%  $Revision$
 	%  was created 03-Jan-2020 16:32:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Dependent)
        radData
 		sessionData
 	end

	methods 
        
        %% GET
        
        function g = get.radData(this)
            g = this.radData_;
        end
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        
        %% 
        
        function results = simulanneal(this)
            results = [];
        end
        
        function results = simulannealBrain(this)
%             hct = this.hctData();
%             aif = this.aifCaprac();
%             cbv = this.cbvBrain();
%             img = this.imgBrain();
            results = [];
        end
		  
 		function this = FDG(varargin)
 			%% FDG
 			%  @param sessionData
            %  @param manualData

 			ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'radData', [], @(x) isa(x, 'mlpet.RadMeasurements'))
            addParameter(ip, 'cbv', [], @(x) isa(x, 'mlfourd.ImagingContext2'));
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.sessionData_ = ipr.sessionData;
            this.radData_ = ipr.radData;
            this.cbv_ = ipr.cbv;
 		end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        cbv_
        radData_
        sessionData_
    end
    
    methods (Access = protected)
        function hct = hctData(this)
            hct = [];
        end
        function img = imgBrain(this)
            %% @return img is 1D numeric containing volume average over binarized wmparc.
            
            ic2 = mlfourd.ImagingContext2(this.sessionData.tracerResolvedFinal);
            brain = mlfourd.ImagingContext2(this.sessionData.wmparc('typ', '4dfp.hdr'));
            brain = brain.binarized;
            ic2 = ic2.blurred(4.3);
            ic2 = ic2.volumeAveraged(brain);
            img = ic2.fourdfp.img;
            img(img < 0.005) = 0.005;
        end
        function aif = aifCalibrated(this)
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

