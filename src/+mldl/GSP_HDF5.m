classdef GSP_HDF5 < mldl.HDF5
	%% GSP_HDF5 specifies the structure of the GSP BOLD after preprocessing by 4dfp.

	%  $Revision$
 	%  was created 17-Apr-2020 20:50:47 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
    properties (Constant)
        gspLocation = '/data/nil-bluearc/shimony/jjlee/GSP'
        h5Location = '/data/shimony/shimony2/jjlee/GSP_h5'
        suffix = '_faln_dbnd_xr3d_atl.4dfp.hdr';
    end
    
    methods (Static)
        function createFromGspLocation(varargin)
            fqh5 = fullfile(mldl.GSP_HDF5.h5Location, 'GSP.h5');
            deleteExisting(fqh5)
            this = mldl.GSP_HDF5('filename', fqh5);
            this.h5create()
            this.h5write_gsp()
        end
        function createFromGspLocationZ24(varargin)
            fqh5 = fullfile(mldl.GSP_HDF5.h5Location, 'GSP_z24.h5');
            deleteExisting(fqh5)
            this = mldl.GSP_HDF5('filename', fqh5, ...
                                 'maxsize', [48 64 124 Inf], ...
                                 'chunk', [48 64 1 1]);
            this.h5create()
            this.h5write_gsp('zcoords', 24)
        end
    end
    
	methods 
        function h5write_gsp(this, varargin)
            %% INST_H5WRITE_GSP uses instance data for performant calls to h5write().
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
                        this.gspLocation, ...
                        sprintf('Sub%04d_Ses%i', isub, ipr.ses), ...
                        sprintf('bold%i', ibold), ...
                        sprintf('Sub%04d_Ses%i_b%i%s', isub, ipr.ses, ibold, this.suffix));
                    if isfile(bold_filename)
                        tic
                        try
                            this.h5write_4dfp(this.filename, bold_filename, start, 'zcoords', ipr.zcoords)
                            start(end) = start(end) + 1;
                        catch ME
                            handwarning(ME)
                        end
                        toc
                    end
                end
            end
        end
        function h5write_4dfp(this, filename, filename4dfp, start, varargin)
            %% rescales img to [0 1]
            %  @param required filename of h5 storage.
            %  @param required filename4dfp of 4dfp image to store.
            %  @param required start location within storage at which to start writing.  
            %  @param zcoords is numeric, specifying zcoords to select for HDF5.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'filename', @isfile)
            addRequired(ip, 'filename4dfp', @isfile)
            addRequired(ip, 'start', @isnumeric)
            addParameter(ip, 'zcoords', [], @isnumeric)
            parse(ip, filename, filename4dfp, start, varargin{:})
            ipr = ip.Results;
            
            ifc = mlfourd.ImagingFormatContext(ipr.filename4dfp);
            if ~isempty(ipr.zcoords)
                img = squeeze(ifc.img(:,:,ipr.zcoords,:));
            else
                img = ifc.img;
            end
            img = flip(img, 2);
            img = img - dipmin(img);
            img = img / dipmax(img);
            szi = size(img);
            if ~isempty(this.Nt)
                assert(this.Nt == szi(end), 'mldl:ValueError', 'HDF5.h5write_4dfp.szi(end)->', szi(end))
            end
            if ~all(szi == this.maxsize(1:ndims(img)))
                error('mldl:ValueError', 'HDF5.h5write_4dfp.sz -> %g', szi)
            end

            count = [szi 1];
            this.h5write(ipr.filename, this.datasetname, img, start, count)
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

