classdef Test_LSTM < matlab.unittest.TestCase
	%% TEST_LSTM 

	%  Usage:  >> results = run(mldl_unittest.Test_LSTM)
 	%          >> result  = run(mldl_unittest.Test_LSTM, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 05-Nov-2019 13:53:56 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/test/+mldl_unittest.
 	%% It was developed on Matlab 9.7.0.1216025 (R2019b) Update 1 for MACI64.  Copyright 2019 John Joowon Lee.
 	
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
        function test_lstm(this)
            % See also:  web(fullfile(docroot, 'deeplearning/ref/dlarray.lstm.html'))
            
            numFeatures = 10;
            numObservations = 32;
            sequenceLength = 64;
            
            X = randn(numFeatures,numObservations,sequenceLength);
            dlX = dlarray(X,'CBT');
            
            numHiddenUnits = 3;
            H0 = zeros(numHiddenUnits,1);
            C0 = zeros(numHiddenUnits,1);
            
            weights = dlarray(randn(4*numHiddenUnits,numFeatures),'CU');
            recurrentWeights = dlarray(randn(4*numHiddenUnits,numHiddenUnits),'CU');
            bias = dlarray(randn(4*numHiddenUnits,1),'C');
            
            [dlY,hiddenState,cellState] = lstm(dlX,H0,C0,weights,recurrentWeights,bias);
            disp(dlY)
            
        end
        function test_FDG_LSTM(this)
            %  See also:  mlkinetics.F18DeoxyGlucoseLaif, mlkinetics.Huang1980, mlpet.PLaif, 
            obj = mldl.FDG_LSTM();
        end
	end

 	methods (TestClassSetup)
		function setupLSTM(this)
 			import mldl.*;
 			this.testObj_ = LSTM;
 		end
	end

 	methods (TestMethodSetup)
		function setupLSTMTest(this)
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

