classdef FDG 
	%% FDG  

	%  $Revision$
 	%  was created 03-Jan-2020 16:32:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
    properties (Constant)
        HOME = '/Users/jjlee/Singularity/subjects_freesurfer/sub-S00000/resampling_restricted'
    end
    
    properties
        artery = [15.7231339417783 40.0670951423858 32.7896589986613 60.9033324985914 115.390827456407 20247.5870083001 138101.363561975 247624.893301051 219962.735811158 123800.355195601 84547.8333286971 74641.7780423665 61033.7705200579 51488.086840046 48137.398517549 45853.6272536275 43105.9076185098 40588.4399463862 39532.0074392734 37376.951543845 38029.7572601973 36896.5536596196 35837.3996944633 35239.9976922434 33563.3578174873 31172.6742405234 31661.2958727327 31726.6836574803 31190.0410893731 29736.9838758955 29345.5491772129 28612.6204028212 28087.9993320967 12488.6629201451 8478.08886746032 5324.32339588189 3353.30521211569 945.745212317361 665.76566052086]
        arteryTimesSampled = [0 3 7 10 14 18 22 25 30 35 39 44 48 52 55 58 63 67 70 74 78 81 84 90 93 95 98 103 106 109 113 117 120 417 597 897 1197 2997 3597]
        brainBinarized
        fdgfp = 'fdgdt20190523132832'
        fdgTausSampled = [10 13 14 16 17 19 20 22 23 25 26 28 29 31 32 34 35 37 38 40 41 43 44 46 47 49 50 52 53 56 57 59 60 62 63 65 66 68 69 71 72 74 76 78 79 81 82 84 85 87 88 91 92 94 95 97 98 100 101 104 105 108]
        map
    end
    
	properties (Dependent)
        radData
 		sessionData
    end
    
    methods (Static)
        function [gm,gwj,wm,bg,thal,bs,csf,vasc,orred] = loadICSegregated()
            import mlfourd.ImagingContext2
            
            pwd0 = pushd(mldl.FDG.HOME);
            gm   = ImagingContext2('gm.nii.gz');
            gwj  = ImagingContext2('gwjunction.nii.gz');
            wm   = ImagingContext2('wm.nii.gz');
            bg   = ImagingContext2('bg.nii.gz');
            thal = ImagingContext2('thalamus.nii.gz');
            bs   = ImagingContext2('brainstem.nii.gz');
            csf  = ImagingContext2('csf.nii.gz');
            vasc = ImagingContext2('vascular.nii.gz');
            gm.nifti
            gwj.nifti
            wm.nifti
            bg.nifti
            thal.nifti
            bs.nifti
            csf.nifti
            vasc.nifti
            
            orred = gm + gwj + wm + bg + thal + bs + csf + vasc;
            orred.fileprefix = 'brainForFdg';
            if ~isfile(orred.filename)
                orred.save()
            end
            orred.fsleyes()
            popd(pwd0)            
        end
        function mat = nifti2patricksMat(obj)
            ic = mlfourd.ImagingContext2(obj);
            img = ic.nifti.img;
            sz = size(img);
            if length(sz) > 3
                mat = reshape(flip(ic.nifti.img, 2), [prod(sz(1:3)) sz(4)]);
            else
                mat = reshape(flip(ic.nifti.img, 2), [prod(sz(1:3)) 1]);
            end
            ss = strsplit(ic.fileprefix, '_rand');
            save([ss{1} '.mat'], 'mat')
        end
        function segregateHistology()
            
            ifc = mlfourd.ImagingFormatContext('wmparc.nii.gz');
            
            cereb = copy(ifc); cereb.fileprefix = 'cereb';
            neo = copy(ifc); neo.fileprefix = 'neo';
            gm = copy(ifc); gm.fileprefix = 'gm';
            gwj = copy(ifc); gwj.fileprefix = 'gwjunction';
            wm = copy(ifc); wm.fileprefix = 'wm';
            bg = copy(ifc); bg.fileprefix = 'bg';
            thal = copy(ifc); thal.fileprefix = 'thalamus';
            bs = copy(ifc); bs.fileprefix = 'brainstem';
            csf = copy(ifc); csf.fileprefix = 'csf';
            vasc = copy(ifc); vasc.fileprefix = 'vascular';
            
            cereb.img(ifc.img == 8 | ifc.img == 47) = 1; % cerebellar gray            
            cereb.img(ifc.img == 7 | ifc.img == 46) = 1; % cerebellar white
            finalize(cereb)
            
            neo.img(1000 <= ifc.img & ifc.img < 3000) = 1;
            neo.img(ifc.img == 17 | ifc.img == 53) = 1; % hippocampus
            neo.img(ifc.img == 18 | ifc.img == 54) = 1; % amygdala
            finalize(neo)
            
            wm.img(5001 <= ifc.img) = 1;
            wm.img(77 <= ifc.img & ifc.img <= 255) = 1;
            wm.img(ifc.img == 7 | ifc.img == 46) = 1; % cerebellar white
            finalize(wm)
            
            bg.img(ifc.img == 26 | ifc.img == 58) = 1; % accumbens
            bg.img(ifc.img == 11 | ifc.img == 50) = 1; % caudate
            bg.img(ifc.img == 12 | ifc.img == 51) = 1; % putamen
            bg.img(ifc.img == 13 | ifc.img == 52) = 1; % pallidum
            finalize(bg)
            
            thal.img(ifc.img == 10 | ifc.img == 49) = 1;
            finalize(thal)
            
            bs.img(ifc.img == 16) = 1;
            bs.img(ifc.img == 28 | ifc.img == 60) = 1; % ventral diencephalon
            finalize(bs)
            
            csf.img(ifc.img == 4 | ifc.img == 43) = 1; % lateral ventr
            csf.img(ifc.img == 5 | ifc.img == 44) = 1; % inf lateral ventr
            csf.img(ifc.img == 14) = 1; % 3rd
            csf.img(ifc.img == 15) = 1; % 4th
            csf.img(ifc.img == 24) = 1; % csf
            csf.img(ifc.img == 31 | ifc.img == 63) = 1; % choroid plexus
            finalize(csf)
            
            vasc.img(ifc.img == 30 | ifc.img == 62) = 1;
            finalize(vasc)
            
            gm.img(1000 <= ifc.img & ifc.img < 3000) = 1;
            gm.img(ifc.img == 8 | ifc.img == 47) = 1; % cerebellar gray
            gm.img(ifc.img == 17 | ifc.img == 53) = 1; % hippocampus
            gm.img(ifc.img == 18 | ifc.img == 54) = 1; % amygdala
            finalize(gm)
            
            gwj.img(3000 <= ifc.img & ifc.img < 5000) = 1;
            finalize(gwj)
            
            function finalize(obj)
                obj.img(obj.img ~= 1) = 0;
                assert(isempty(obj.img(obj.img > 1)))
                obj.fsleyes()
                obj.save
            end
            
        end
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

