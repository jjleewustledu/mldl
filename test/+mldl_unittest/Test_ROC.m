classdef Test_ROC < matlab.unittest.TestCase
	%% TEST_ROC 

	%  Usage:  >> results = run(mldl_unittest.Test_ROC)
 	%          >> result  = run(mldl_unittest.Test_ROC, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 20-Jan-2020 14:36:17 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/test/+mldl_unittest.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        LH
        NS
        NSb
        NSw
        Sanai
        Sanaib
        Sanaiw
 		registry
 		testObj
        workpath = '/Users/jjlee/Box/DeepNetFCProject/Donnas_Tumors'
 	end

	methods (Test)
		function test_afun(this)
 			import mldl.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_imdilate(this)
            import mldl.* mlfourd.*
            pwd0 = pushd(this.workpath);
            sb = ImagingContext2(ROC.imdilate(fullfile('Sanai', 'sanai_broca.nii.gz')));
            sw = ImagingContext2(ROC.imdilate(fullfile('Sanai', 'sanai_wernicke.nii.gz')));
            sl = sb + sw;
            sl.fileprefix = 'sanai_lan_imdilate1';
            sl.save
            popd(pwd0)
        end
        function test_imdilatex(this)
            import mldl.* mlfourd.*
            pwd0 = pushd(this.workpath);
            sb = ImagingContext2(ROC.imdilatex(fullfile('Sanai', 'sanai_broca.nii.gz')));
            sw = ImagingContext2(ROC.imdilatex(fullfile('Sanai', 'sanai_wernicke.nii.gz')));
            sl = sb + sw;
            sl.fileprefix = 'sanai_lan_imdilate3x';
            sl.save
            popd(pwd0)
        end
        function test_labels(this)
            this.LH.fsleyes(this.NS.fqfilename, this.Sanai.fqfilename)
        end
        function test_perfcurve(this)
            import mlfourd.ImagingFormatContext
            
            pwd0 = pushd(this.workpath);
            
            REG = 'Wernicke''s areas'; % 'Broca''s areas'; % 'language areas'; 
            switch REG
                case 'language areas'
                    ns  = mldl.ROC('label', this.NS);
                    sa  = mldl.ROC('label', this.Sanai);
                case 'Broca''s areas'
                    ns = mldl.ROC('label', this.NSb);
                    sa = mldl.ROC('label', this.Sanaib);
                case 'Wernicke''s areas'
                    ns = mldl.ROC('label', this.NSw);
                    sa = mldl.ROC('label', this.Sanaiw);  
            end          
            
            [x_ns,y_ns,~,auc_ns] = perfcurveAverages(ns);
            [x_sa,y_sa,~,auc_sa] = perfcurveAverages(sa);
            figure;
            p1 = plot(x_ns, y_ns, '-o');
            hold on
            p2 = plot(x_sa, y_sa, '-o');
            rline = refline(1, 0);
            rline.Color = 0.05*[1 1 1];
            hold off
            pbaspect([1 1 1])
            set(gca, 'FontSize', 12)
            legend([p1 p2], ...
                   sprintf('AUC for Neurosynth %g', auc_ns), ...
                   sprintf('AUC for Sanai (2008) %g', auc_sa))
            set(legend, 'Location', 'SouthEast')
            set(legend, 'FontSize', 14)
            legend('boxoff')
            xlabel('False positive rate', 'FontSize', 16); 
            ylabel('True positive rate', 'FontSize', 16);
            title( ...
                {sprintf('ROC for DNN classification of %s from Neurosynth', REG); ' '}, ...
                'FontSize', 14)
            
            popd(pwd0)
        end
	end

 	methods (TestClassSetup)
		function setupROC(this)
 			import mldl.*;
            import mlfourd.ImagingFormatContext
            
 			this.testObj_ = [];
            this.LH     = ImagingFormatContext(fullfile(this.workpath, 'LHemis.nii.gz'));
            this.NS     = ImagingFormatContext(fullfile(this.workpath, 'Neurosynth', 'ns_lan_thr0p05.nii.gz'));
            this.NSb    = ImagingFormatContext(fullfile(this.workpath, 'Neurosynth', 'ns_broca_thr0p05.nii.gz'));
            this.NSw    = ImagingFormatContext(fullfile(this.workpath, 'Neurosynth', 'ns_wernicke_thr0p05.nii.gz'));
            this.Sanai  = ImagingFormatContext(fullfile(this.workpath, 'Sanai', 'sanai_lan_imdilate3x.nii.gz'));
            this.Sanaib = ImagingFormatContext(fullfile(this.workpath, 'Sanai', 'sanai_broca_imdilate3x.nii.gz'));
            this.Sanaiw = ImagingFormatContext(fullfile(this.workpath, 'Sanai', 'sanai_wernicke_imdilate3x.nii.gz'));
 		end
	end

 	methods (TestMethodSetup)
		function setupROCTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

