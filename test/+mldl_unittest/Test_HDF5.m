classdef Test_HDF5 < matlab.unittest.TestCase
	%% TEST_HDF5 

	%  Usage:  >> results = run(mldl_unittest.Test_HDF5)
 	%          >> result  = run(mldl_unittest.Test_HDF5, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 18-Apr-2020 12:09:54 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/test/+mldl_unittest.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        home = '/Users/jjlee/Downloads/GSP'
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
        function test_ctor(this)
            o = this.testObj;
            this.verifyEqual(o.filename, 'Test_HDF5.h5')
            this.verifyEqual(o.maxsize, [48 64 48 Inf])
            this.verifyEqual(o.datatype, 'single')
            this.verifyEqual(o.chunk, [4 4 4 1984])
            this.verifyEqual(o.deflate, 9)
            this.verifyEqual(o.datasetname, '/images')
            disp(o)
        end
        function test_h5create(this)
            deleteExisting('test_h5create.h5')
            this.testObj.h5create('test_h5create.h5')
            info = h5info('test_h5create.h5');
            this.verifyEqual(info.Filename, fullfile(pwd, 'test_h5create.h5'))
            this.verifyEqual(info.Datasets.Name, 'images')
            this.verifyEqual(info.Datasets.Datatype.Type, 'H5T_IEEE_F32LE')
            this.verifyEqual(info.Datasets.Dataspace.Size, [48 64 48 0])
            this.verifyEqual(info.Datasets.Dataspace.MaxSize, [48 64 48 Inf])
            this.verifyEqual(info.Datasets.ChunkSize, [4 4 4 1984])
        end
        function test_h5create_noclobber(this)
            if ~isfile('test_h5create.h5')
                mlbash('touch test_h5create.h5')
            end
            this.verifyError(@testhandle, 'MATLAB:InputParser:ArgumentFailedValidation')
            
            function testhandle()
                this.testObj.h5create('test_h5create.h5')
            end
        end
        function test_h5write(this)
            img = ones(48, 64, 48, 2);
            start = [1 1 1 1];
            tic
            this.testObj.h5write('Test_HDF5.h5', 'images', img, start, size(img))
            toc
            img2 = 2*ones(48, 64, 48, 2);
            start2 = [1 1 1 3];
            tic
            this.testObj.h5write('Test_HDF5.h5', 'images', img2, start2, size(img2))
            toc
            info = h5info('Test_HDF5.h5');
            this.verifyEqual(info.Filename, fullfile(pwd, 'Test_HDF5.h5'))
            this.verifyEqual(info.Datasets.Name, 'images')
            this.verifyEqual(info.Datasets.Datatype.Type, 'H5T_IEEE_F32LE')
            this.verifyEqual(info.Datasets.Dataspace.Size, [48 64 48 4])
            this.verifyEqual(info.Datasets.Dataspace.MaxSize, [48 64 48 Inf])
            this.verifyEqual(info.Datasets.ChunkSize, [4 4 4 1984])
        end
        function test_h5write_4dfp(this)
            hdr = 'Sub1570_Ses1_b1_faln_dbnd_xr3d_atl.4dfp.hdr';
            start = [1 1 1 1];
            tic
            this.testObj.h5write_4dfp('Test_HDF5.h5', hdr, start);
            toc
            hdr2 = 'Sub1570_Ses1_b1_faln_dbnd_xr3d_atl.4dfp.hdr';
            start2 = [1 1 1 125];
            tic
            this.testObj.h5write_4dfp('Test_HDF5.h5', hdr2, start2)
            toc
            info = h5info('Test_HDF5.h5');
            this.verifyEqual(info.Filename, fullfile(pwd, 'Test_HDF5.h5'))
            this.verifyEqual(info.Datasets.Name, 'images')
            this.verifyEqual(info.Datasets.Datatype.Type, 'H5T_IEEE_F32LE')
            this.verifyEqual(info.Datasets.Dataspace.Size, [48 64 48 248])
            this.verifyEqual(info.Datasets.Dataspace.MaxSize, [48 64 48 Inf])
            this.verifyEqual(info.Datasets.ChunkSize, [4 4 4 1984])
        end
        function test_h5write_gsp(this)
            this.testObj = mldl.GSP_HDF5('filename', 'test_h5write_gsp.h5');
            deleteExisting('test_h5write_gsp.h5')
            tic
            this.testObj.h5create()
            toc
            tic
            this.testObj.h5write_gsp('sub', 1570)            
            toc
            info = h5info('test_h5write_gsp.h5');
            this.verifyEqual(info.Filename, fullfile(pwd, 'test_h5write_gsp.h5'))
            this.verifyEqual(info.Datasets.Name, 'images')
            this.verifyEqual(info.Datasets.Datatype.Type, 'H5T_IEEE_F32LE')
            this.verifyEqual(info.Datasets.Dataspace.Size, [48 64 48 124 2 1])
            this.verifyEqual(info.Datasets.Dataspace.MaxSize, [48 64 48 124 2 Inf])
            this.verifyEqual(info.Datasets.ChunkSize, [48 64 48 1 1 1])
            
            % runtests('mldl_unittest.Test_HDF5','ProcedureName','test_h5write_gsp')
            % Running mldl_unittest.Test_HDF5
            % Elapsed time is 0.008753 seconds.
            % Elapsed time is 6.287397 seconds.
            % .
            % Done mldl_unittest.Test_HDF5
            % __________
            % 
            % 
            % ans = 
            % 
            %   TestResult with properties:
            % 
            %           Name: 'mldl_unittest.Test_HDF5/test_h5write_gsp'
            %         Passed: 1
            %         Failed: 0
            %     Incomplete: 0
            %       Duration: 6.342182073000000
            %        Details: [1×1 struct]
            % 
            % Totals:
            %    1 Passed, 0 Failed, 0 Incomplete.
            %    6.3422 seconds testing time.           
        end
	end

 	methods (TestClassSetup)
		function setupHDF5(this)
 			import mldl.*;
 			this.testObj_ = HDF5('filename', 'Test_HDF5.h5');
 		end
	end

 	methods (TestMethodSetup)
		function setupHDF5Test(this)
 			this.testObj = this.testObj_;
            cd(this.home)
            deleteExisting('Test_HDF5.h5')
            this.testObj.h5create('Test_HDF5.h5');
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

