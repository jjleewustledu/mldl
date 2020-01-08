classdef Test_NoiseInjector < matlab.unittest.TestCase
	%% TEST_NOISEINJECTOR 

	%  Usage:  >> results = run(mldl_unittest.Test_NoiseInjector)
 	%          >> result  = run(mldl_unittest.Test_NoiseInjector, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 06-Jan-2020 19:20:37 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/test/+mldl_unittest.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
 		registry
 		testObj
        sinusoidal % 1 x 100
        sinusoidal_GM % 48 x 64 x 48 x 100
 	end

	methods (Test)
		function test_afun(this)
 			import mldl.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_noise_injector(this)
            bold = mldl.noise_injector('bold', this.sinusoidal_GM, 'model', {'normal' 'flip' 'shuffle' 'affine'});            
            ic2 = mlfourd.ImagingContext2(bold);
            ic2.fsleyes
        end
        function test_inject_noise_model(this)
            this.testObj = this.testObj.inject_noise_model();
            ic2 = mlfourd.ImagingContext2(this.testObj.bold_);
            ic2.fsleyes
        end
        function test_inject_noise_model_cell(this)
            this.testObj = this.testObj.inject_noise_model({'Levy' 'flip' 'shuffle' 'affine'});
            ic2 = mlfourd.ImagingContext2(this.testObj.bold_);
            ic2.fsleyes
        end
        function test_inject_noise_model_shuffle(this)
            this.testObj = this.testObj.inject_noise_model('shuffle');
            ic2 = mlfourd.ImagingContext2(this.testObj.bold_);
            ic2.fsleyes
        end
        function test_inject_noise_model_power(this)
            this.testObj = this.testObj.inject_noise_model('power');
            ic2 = mlfourd.ImagingContext2(this.testObj.bold_);
            ic2.fsleyes
        end
        function test_inject_noise_model_points(this)
            this.testObj = this.testObj.inject_noise_model('points');
            ic2 = mlfourd.ImagingContext2(this.testObj.bold_);
            ic2.fsleyes
        end
        function test_inject_noise_model_normal(this)
            this.testObj = this.testObj.inject_noise_model('normal');
            ic2 = mlfourd.ImagingContext2(this.testObj.bold_);
            ic2.fsleyes
        end
        function test_inject_noise_model_Levy(this)
            this.testObj = this.testObj.inject_noise_model('Levy');
            ic2 = mlfourd.ImagingContext2(this.testObj.bold_);
            ic2.fsleyes
        end
        function test_inject_noise_model_flip(this)
            this.testObj = this.testObj.inject_noise_model('flip');
            ic2 = mlfourd.ImagingContext2(this.testObj.bold_);
            ic2.fsleyes
        end        
        function test_inject_noise_model_Brownian(this)
            this.testObj = this.testObj.inject_noise_model('Brownian');
            ic2 = mlfourd.ImagingContext2(this.testObj.bold_);
            ic2.fsleyes
        end
        function test_inject_noise_model_affine(this)
            this.testObj = this.testObj.inject_noise_model('affine');
            ic2 = mlfourd.ImagingContext2(this.testObj.bold_);
            ic2.fsleyes
        end
        function test_affine1D(this)
            plot(this.testObj.affine1D(this.sinusoidal));
        end
        function test_circshift(this)
            plot(this.testObj.circshift(this.sinusoidal, 2));
        end
        function test_insert1D(this)
            plot(this.testObj.insert1D(this.sinusoidal, this.sinusoidal(1:25), 51));
        end
        function test_points1D(this)
            plot(this.testObj.points1D(this.sinusoidal));
        end
        function test_select1D(this)
            [b1,t0,Nt] = this.testObj.select1D(this.sinusoidal);
            plot(b1)
            fprintf('t0->%g\n', t0)
            fprintf('Nt->%g\n', Nt)
        end
        function test_shuffle1D(this)
            plot(this.testObj.shuffle1D(this.sinusoidal));
        end
        function test_normal1D(this)
            b = this.testObj.normal1D(300);
            plot(b)
            title('test\_normal1D')
        end
        function test_power1D(this)
            b = this.testObj.power1D(300);
            plot(b)
            title('test\_normal1D')
        end
        function test_Brownian_walk1D(this)
            b = this.testObj.Brownian_walk1D(300);
            plot(b)
            title('test\_Brownian\_walk1D')
        end
        function test_Levy_flight1D(this)
            b = this.testObj.Levy_flight1D(300);
            plot(b)
            title('test\_Levy\_flight1D')
        end
        function test_saturate_signal(this)
            this.assertEqual(this.testObj.saturate_signal([-10.1 -1.1 -1 0 1 1.1 10.1]), ...
                [-1 -1 -1 0 1 1 1])
        end
        function test_select_focus(this)
            img = this.testObj.select_focus();
            ic2 = mlfourd.ImagingContext2(single(img));
            ic2.fsleyes
        end
	end

 	methods (TestClassSetup)
		function setupNoiseInjector(this)
 			import mldl.*;
            msk = NoiseInjector.read_aparc_aseg_mask();            
            this.sinusoidal = sin(pi*(0:99)/10);
            this.sinusoidal_GM = zeros(48,64,48,100);
            for t = 0:99
                this.sinusoidal_GM(:,:,:,t+1) = msk*sin(pi*t/10);
            end
 			this.testObj_ = NoiseInjector('bold', this.sinusoidal_GM);
 		end
	end

 	methods (TestMethodSetup)
		function setupNoiseInjectorTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanTestMethod);
            %rng default
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

