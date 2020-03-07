classdef VAE 
	%% VAE  

	%  $Revision$
 	%  was created 15-Dec-2019 23:37:14 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1247435 (R2019b) Update 2 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties
 		XTrain
        XTest
        YTest
        
        latent_dim = 20
    end
    
    properties (Dependent)
        numTrainImages
    end

	methods 
        
        %% GET
        
        function g = get.numTrainImages(this)
            g = size(this.XTrain,4);
        end
        
        %%
        
        function this = defineModelGradientsFunction(this)
        end
        function this = trainModel(this)
        end
        function this = visualizeResults(this)
        end
		  
 		function this = VAE(varargin)
 			%% VAE
 			%  @param .

 			
 		end
    end 
    
    %% PROTECTED
    
    methods (Access = protected)
        function this = constructNetwork(this)
        end
        function this = specifyTrainingOptions(this)
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

