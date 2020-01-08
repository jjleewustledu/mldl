classdef Test_FDG < matlab.unittest.TestCase
	%% TEST_FDG 

	%  Usage:  >> results = run(mldl_unittest.Test_FDG)
 	%          >> result  = run(mldl_unittest.Test_FDG, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 03-Jan-2020 16:32:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/test/+mldl_unittest.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        folders = 'CCIR_00559/ses-E03056/FDG_DT20190523132832.000000-Converted-AC'
 		registry
 		testObj
        xlsxfile = '~/Documents/private/CCIRRadMeasurements 2019may23.xlsx'
 	end

	methods (Test)
		function test_afun(this)
 			import mldl.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_radData(this)
            disp(this.testObj.radData)
        end
        function test_simulannealBrain(this)
            results = this.testObj.simulannealBrain();
            disp(results)
        end
        function test_simulannealSurfer(this)
        end
        function test_simulannealVoxels(this)
        end
	end

 	methods (TestClassSetup)
		function setupFDG(this)
 			import mldl.*;
            setenv('SINGULARITY_HOME', '/Users/jjlee/Singularity')
            setenv('PROJECTS_DIR', getenv('SINGULARITY_HOME'))
            setenv('SUBJECTS_DIR', fullfile(getenv('PROJECTS_DIR'), 'subjects', ''))
            sessd = mlraichle.SessionData.create(this.folders);
            radData = mlraichle.CCIRRadMeasurements.createBySession(sessd);
            cbv = mlfourd.ImagingContext2(0.04*ones(172,172,127));
 			this.testObj_ = FDG('sessionData', sessd, 'radData', radData, 'cbv', cbv);
 		end
	end

 	methods (TestMethodSetup)
		function setupFDGTest(this)
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

