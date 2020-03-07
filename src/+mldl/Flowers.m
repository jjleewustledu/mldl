classdef Flowers < mldl.GAN
	%% FLOWERS  

	%  $Revision$
 	%  was created 06-Mar-2020 16:00:45 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
 		
    end

	methods 
 		function this = Flowers(varargin)
 			%% FLOWERS
 			%  @param .

 			this = this@mldl.GAN(varargin{:});
            this.datasetFolder = fullfile(getenv('HOME'), 'Downloads', 'flower_photos', 'sunflowers', '');
            this.imds = imageDatastore(this.datasetFolder, ...
                'IncludeSubfolders',true, ...
                'LabelSource','foldernames');
 		end
        
        function aids = augmentedImageDatastore(this)
            augmenter = imageDataAugmenter( ...
                'RandXReflection',true, ...
                'RandScale',[1 2]);
            aids = augmentedImageDatastore([64 64],this.imds,'DataAugmentation',augmenter);
        end
		  
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

