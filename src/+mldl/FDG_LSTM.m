classdef FDG_LSTM < mldl.LSTM
	%% FDG_LSTM  

	%  $Revision$
 	%  was created 28-Feb-2020 22:54:40 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties 		
 	end

	methods 
        function a = aifs(this, varargin)
            %  @returns a := [aif_1(t_1) aif_1(t_2) ... aif_1(t_n); ...
            %                 aif_2(t_1) aif_2(t_2) ... aif_2(t_n); ...
            %                 ...
            %                 aif_m(t_1) aif_m(t_2) ... aif_m(t_n)]
            a = this.output_;
        end
        function t = tacs(this, varargin)
            %  @returns a := [tac_1(t_1) tac_1(t_2) ... tac_1(t_n); ...
            %                 tac_2(t_1) tac_2(t_2) ... tac_2(t_n); ...
            %                 ...
            %                 tac_m(t_1) tac_m(t_2) ... tac_m(t_n)]
            t = this.input_;
        end
		  
 		function this = FDG_LSTM(varargin)
 			%% FDG_LSTM
 			%  @param optional tac is numeric.
            %  @param optional aif is numeric.
            %  @param lstm is an nnet.cnn.LayerGraph.

 			this = this@mldl.LSTM(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

