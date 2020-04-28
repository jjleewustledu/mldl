classdef GSP_HDF5 < mldl.HDF5
	%% GSP_HDF5 specifies the structure of the GSP BOLD after preprocessing by 4dfp.

	%  $Revision$
 	%  was created 17-Apr-2020 20:50:47 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
    properties
        home
        suffix = '_faln_dbnd_xr3d_atl.4dfp.hdr';
    end
    
	methods 
        function h5write_gsp(this, varargin)
            %% INST_H5WRITE_GSP uses instance data for performant calls to h5write().
            %  @param sub.
            %  @param bold.
            %  @param suf.
            
            ip = inputParser;
            addParameter(ip, 'sub', 1:1570, @isnumeric)
            addParameter(ip, 'ses', 1, @isnumeric)
            addParameter(ip, 'bold', 1:2, @isnumeric)
            addParameter(ip, 'suf', this.suffix, @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            info = h5info(this.filename);
            Size = info.Datasets.Dataspace.Size;
            start = ones(size(Size));
            for isub = ipr.sub
                for ibold = ipr.bold
                    bold_filename = fullfile( ...
                        this.home, ...
                        sprintf('Sub%i_Ses%i', isub, ipr.ses), ...
                        sprintf('bold%i', ibold), ...
                        sprintf('Sub%i_Ses%i_b%i%s', isub, ipr.ses, ibold, this.suffix));
                    this.h5write_4dfp(this.filename, bold_filename, start)
                    start(end-1) = start(end-1) + 1;
                end
                start(end) = start(end) + 1;
            end
        end
		  
 		function this = GSP_HDF5(varargin)
 			%% GSP_HDF5

 			this = this@mldl.HDF5(varargin{:});            
            
            ip = inputParser;
            addParameter(ip, 'maxsize', [48 64 48 124 2 Inf], @isnumeric)
            addParameter(ip, 'chunk', [48 64 48 1 1 1], @isnumeric)
            addParameter(ip, 'Nt', 124, @isnumeric)
            addParameter(ip, 'home', '/scratch/jjlee/GSP', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;            
            
            this.maxsize = ipr.maxsize; % supercedes 
            this.chunk = ipr.chunk;
            this.Nt = ipr.Nt;
            this.home = ipr.home;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

