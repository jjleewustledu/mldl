classdef Test_GAN < matlab.unittest.TestCase
	%% TEST_GAN 

	%  Usage:  >> results = run(mldl_unittest.Test_GAN)
 	%          >> result  = run(mldl_unittest.Test_GAN, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 06-Mar-2020 15:51:00 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/test/+mldl_unittest.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
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
        function test_flowers(this)
            cd(fullfile(this.registry.srcroot, 'mldl', 'test', '+mldl_unittest', ''))
            obj = mldl.Flowers();
            obj = obj.defineNetworks();
            obj.plot
            obj = obj.trainModel();
            save('test_flowers.mat', 'obj')
            
            obj.generateNewImages()
        end
        function test_GSP(this)
        end
	end

 	methods (TestClassSetup)
		function setupGAN(this)
 			import mldl.*;
 			this.testObj_ = [];
            this.registry = MatlabRegistry.instance();
 		end
	end

 	methods (TestMethodSetup)
		function setupGANTest(this)
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

