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
        GM
        LH
        NS
        NSb
        NSw
        NSo
        pwd0
        RH
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
        function test_GM(this)
            obj = mldl.ROC('test', 'DNN', 'label', this.NS); 
            obj.GM.fsleyes
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
            this.LH.fsleyes(this.NS.fqfilename)
        end
        function test_stageNIfTIAuxiliary(this)
            w = globFoldersT(fullfile(this.workpath, 'DNN_100frames', 'RS033*', '')); % large L frontal glioma
            p0 = pushd(w{1});
            mldl.ROC.stageNIfTIAuxiliary(w{1})
            popd(p0)
        end
        function test_DNN(this)
            %dnn = mlfourd.ImagingFormatContext(fullfile(this.workpath, 'RS003', 'lan.nii.gz'));
            obj = mldl.ROC('test', 'DNN', 'label', this.NS);   
            obj.averageTestGM.fsleyes
            %obj.fsleyesWithLabel()
        end
        function test_DNN_100frames(this)
            %dnn = mlfourd.ImagingFormatContext(fullfile(this.workpath, 'DNN_100frames', 'RS003_frames1to100', 'lan.nii.gz'));
            obj = mldl.ROC('test', 'DNN_100frames', 'label', this.NS);            
            obj.averageTestGM.fsleyes
            %obj.fsleyesWithLabel()
        end
        function test_task(this)
            obj = mldl.ROC('test', 'task', 'label', this.NS);
            obj.averageTest.save
            %obj.fsleyesWithLabel()
        end
        function test_orientations(this)
            w = fullfile(this.workpath, 'RS033'); % large L frontal glioma
            p0 = pushd(w);
            mlbash('fsleyes mpr_333.nii.gz networks.nii.gz lan.nii.gz')
            popd(p0)
        end
        function test_perfcurveAveragesCI(this)
            import mlfourd.ImagingFormatContext
            
            REG = 'Broca''s area'; % 'Wernicke''s area'; % 'language areas';  
            TEST = 'DNN_100frames';
            switch REG
                case 'language areas'
                    roc_dnn    = mldl.ROC('test', TEST, 'label', this.NS);
                case 'Broca''s area'
                    roc_dnn    = mldl.ROC('test', TEST, 'label', this.NSb);
                case 'Wernicke''s area'
                    roc_dnn    = mldl.ROC('test', TEST, 'label', this.NSw);
            end          
            
            [X,Y,~,auc] = perfcurveAverages(roc_dnn, 'NBoot', 1000, 'XVals', [0:0.01:1]);
            figure;
            errorbar(X, Y(:,1), Y(:,1)-Y(:,2), Y(:,3)-Y(:,1));
            xlim([-0.02,1.02]); ylim([-0.02,1.02]);
            pbaspect([1 1 1])
            set(gca, 'FontSize', 12)
            legend(sprintf('DNN (100 frames) AUC = %6.4g [%6.4g %6.4g]', auc(1), auc(2), auc(3)))
            set(legend, 'Location', 'SouthEast')
            set(legend, 'FontSize', 14)
            legend('boxoff')
            xlabel('False positive rate', 'FontSize', 16); 
            ylabel('True positive rate', 'FontSize', 16);
            title( ...
                {sprintf('ROC for classification of %s from Neurosynth', REG); ' '}, ...
                'FontSize', 14) 
            
        end
        function test_perfcurveAverages(this)
            import mlfourd.ImagingFormatContext
            
            REG = 'all language areas'; % 'Broca''s area'; % 'Wernicke''s area'; % 'other language areas'; 
            switch REG
                case 'Broca''s area'
                    roc_dnn    = mldl.ROC('test', 'DNN',           'label', this.NSb, 'mask', this.GM);
                    roc_dnn100 = mldl.ROC('test', 'DNN_100frames', 'label', this.NSb, 'mask', this.GM);
                    roc_tsk    = mldl.ROC('test', 'task',          'label', this.NSb, 'mask', this.GM);
                case 'Wernicke''s area'
                    roc_dnn    = mldl.ROC('test', 'DNN',           'label', this.NSw, 'mask', this.GM);
                    roc_dnn100 = mldl.ROC('test', 'DNN_100frames', 'label', this.NSw, 'mask', this.GM);
                    roc_tsk    = mldl.ROC('test', 'task',          'label', this.NSw, 'mask', this.GM);
                case 'other language areas'
                    roc_dnn    = mldl.ROC('test', 'DNN',           'label', this.NSo, 'mask', this.RH);
                    roc_dnn100 = mldl.ROC('test', 'DNN_100frames', 'label', this.NSo, 'mask', this.RH);
                    roc_tsk    = mldl.ROC('test', 'task',          'label', this.NSo, 'mask', this.RH);
                case 'all language areas'
                    roc_dnn    = mldl.ROC('test', 'DNN',           'label', this.NS,  'mask', this.GM);
                    roc_dnn100 = mldl.ROC('test', 'DNN_100frames', 'label', this.NS,  'mask', this.GM);
                    roc_tsk    = mldl.ROC('test', 'task',          'label', this.NS,  'mask', this.GM);
            end
            
            [x_dnn,y_dnn,~,auc_dnn] = perfcurveAverages(roc_dnn);
            [x_dnn100,y_dnn100,~,auc_dnn100] = perfcurveAverages(roc_dnn100);
            [x_tsk,y_tsk,~,auc_tsk] = perfcurveAverages(roc_tsk);
            figure;
            p1 = plot(x_dnn, y_dnn, '-', 'LineWidth', 3);
            hold on
            p2 = plot(x_dnn100, y_dnn100, '-', 'LineWidth', 3);
            p3 = plot(x_tsk, y_tsk, '-', 'LineWidth', 3);
            rline = refline(1, 0);
            rline.Color = 0.5*[1 1 1];
            hold off
            pbaspect([1 1 1])
            set(gca, 'FontSize', 12)
            legend([p1 p2 p3], ...
                   sprintf('DNN (320 frames) AUC = %6.4f', auc_dnn), ...
                   sprintf('DNN (100 frames) AUC = %6.4f', auc_dnn100), ...
                   sprintf('Task (100 frames) AUC = %6.4f', auc_tsk))
            set(legend, 'Location', 'SouthEast')
            set(legend, 'FontSize', 14)
            legend('boxoff')
            xlabel('False positive rate', 'FontSize', 16); 
            ylabel('True positive rate', 'FontSize', 16);
            title( ...
                {sprintf('ROC for classification of %s from Neurosynth', REG); ' '}, ...
                'FontSize', 14)            
        end
	end

 	methods (TestClassSetup)
		function setupROC(this)
 			import mldl.*;
            import mlfourd.ImagingFormatContext
            
            this.GM     = ImagingFormatContext(fullfile(this.workpath, 'gm3d.nii.gz'));
            this.LH     = ImagingFormatContext(fullfile(this.workpath, 'LHemis.nii.gz'));
            this.NS     = ImagingFormatContext(fullfile(this.workpath, 'Neurosynth', 'lan_association_tanh_333_b30_thr0p5_binarized.nii'));
            this.NSb    = ImagingFormatContext(fullfile(this.workpath, 'Neurosynth', 'ns_broca_333_binarized.nii.gz'));
            this.NSw    = ImagingFormatContext(fullfile(this.workpath, 'Neurosynth', 'ns_wernicke_333_binarized.nii.gz'));
            this.NSo    = ImagingFormatContext(fullfile(this.workpath, 'Neurosynth', 'ns_rlan_333_binarized_binarized.nii.gz'));
            this.RH     = ImagingFormatContext(fullfile(this.workpath, 'RHemis.nii.gz'));
            this.Sanai  = ImagingFormatContext(fullfile(this.workpath, 'Sanai', 'sanai_lan_imdilate3x.nii.gz'));
            this.Sanaib = ImagingFormatContext(fullfile(this.workpath, 'Sanai', 'sanai_broca_imdilate3x.nii.gz'));
            this.Sanaiw = ImagingFormatContext(fullfile(this.workpath, 'Sanai', 'sanai_wernicke_imdilate3x.nii.gz'));            
 			%this.testObj_ = mldl.ROC('label', this.NS);
 		end
	end

 	methods (TestMethodSetup)
		function setupROCTest(this)            
            this.pwd0 = pushd(this.workpath);
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
            popd(this.pwd0)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

