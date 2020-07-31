classdef GSP_HDF5 < mldl.HDF5
	%% GSP_HDF5 specifies the structure of the GSP BOLD after preprocessing by 4dfp.

	%  $Revision$
 	%  was created 17-Apr-2020 20:50:47 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
    properties (Constant)
    end
    
    methods (Static)
        function createFromGspLocation(varargin)
            fqh5 = fullfile('/data/shimony/shimony2/jjlee/GSP_h5', 'GSP_bpss.h5');
            deleteExisting(fqh5)
            this = mldl.GSP_HDF5('filename', fqh5, ...
                                 'h5Location', '/data/shimony/shimony2/jjlee/GSP_h5', ...
                                 'srcLocation', '/data/nil-bluearc/shimony/jjlee/GSP');
            this.h5create()
            this.h5writez('sub', 1:1570, 'ses', 1, 'bold', 1:2)
        end
        function createFromGspLocationZ24(varargin)
            fqh5 = fullfile('/data/shimony/shimony2/jjlee/GSP_h5', 'GSP_bpss_z24.h5');
            deleteExisting(fqh5)
            this = mldl.GSP_HDF5('filename', fqh5, ...
                                 'maxsize', [48 64 124 Inf], ...
                                 'chunk', [48 64 1 1], ...
                                 'h5Location', '/data/shimony/shimony2/jjlee/GSP_h5', ...
                                 'srcLocation', '/data/nil-bluearc/shimony/jjlee/GSP');
            this.h5create()
            this.h5writez('sub', 1:1570, 'ses', 1, 'bold', 1:2, 'zcoords', 24)
        end
    end
    
	methods 
        function h5writez(this, varargin)
            %% H5WRITEZ uses instance data for performant calls to h5write().
            %  @param sub.
            %  @param sese.
            %  @param bold.
            %  @param suf.
            %  @param zcoords.
            
            ip = inputParser;
            addParameter(ip, 'sub', 1:1570, @isnumeric)
            addParameter(ip, 'ses', 1, @isnumeric)
            addParameter(ip, 'bold', 1:2, @isnumeric)
            addParameter(ip, 'suf', this.suffix, @ischar)
            addParameter(ip, 'zcoords', [], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            info = h5info(this.filename);
            Size = info.Datasets.Dataspace.Size;
            start = ones(size(Size));
            for isub = ipr.sub
                for ibold = ipr.bold
                    bold_filename = fullfile( ...
                        this.srcLocation, ...
                        sprintf('Sub%04d_Ses%i', isub, ipr.ses), ...
                        sprintf('bold%i', ibold), ...
                        sprintf('Sub%04d_Ses%i_b%i%s', isub, ipr.ses, ibold, this.suffix));
                    if isfile(bold_filename)
                        tic
                        try
                            this.h5write_format(this.filename, bold_filename, start, 'zcoords', ipr.zcoords)
                            start(end) = start(end) + 1;
                        catch ME
                            handwarning(ME)
                        end
                        toc
                    end
                end
            end
        end
        
 		function this = GSP_HDF5(varargin)
 			%% GSP_HDF5
            %  @param filename, e.g., 'GSP.h5'.

 			this = this@mldl.HDF5(varargin{:});            
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'maxsize', [48 64 48 124 Inf], @isnumeric)
            addParameter(ip, 'chunk', [48 64 48 1 1], @isnumeric)
            addParameter(ip, 'Nt', 124, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;            
            
            this.maxsize = ipr.maxsize; % supercedes 
            this.chunk = ipr.chunk;
            this.Nt = ipr.Nt;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

