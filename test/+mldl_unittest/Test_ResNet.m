classdef Test_ResNet < matlab.unittest.TestCase
	%% TEST_RESNET 

	%  Usage:  >> results = run(mldl_unittest.Test_ResNet)
 	%          >> result  = run(mldl_unittest.Test_ResNet, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 11-Sep-2019 13:32:13 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/test/+mldl_unittest.
 	%% It was developed on Matlab 9.6.0.1135713 (R2019a) Update 3 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties
 		registry
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mldl.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
 		end
	end

 	methods (TestClassSetup)
		function setupResNet(this)
 			import mldl.*;
 			this.testObj_ = ResNet;
 		end
	end

 	methods (TestMethodSetup)
		function setupResNetTest(this)
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

