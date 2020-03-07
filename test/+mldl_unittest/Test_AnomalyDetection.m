classdef Test_AnomalyDetection < matlab.unittest.TestCase
	%% TEST_ANOMALYDETECTION 

	%  Usage:  >> results = run(mldl_unittest.Test_AnomalyDetection)
 	%          >> result  = run(mldl_unittest.Test_AnomalyDetection, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 13-Dec-2019 16:35:36 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/test/+mldl_unittest.
 	%% It was developed on Matlab 9.7.0.1247435 (R2019b) Update 2 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties
 		registry
 		testObj
 	end

	methods (Test)
		function test_VAE(this)
        end
        function test_GAN(this)
        end
        function test_UNet(this)
        end
	end

 	methods (TestClassSetup)
		function setupAnomalyDetection(this)
 			import mldl.*;
 			this.testObj_ = AnomalyDetection;
 		end
	end

 	methods (TestMethodSetup)
		function setupAnomalyDetectionTest(this)
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

