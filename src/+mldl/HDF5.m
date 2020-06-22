classdef HDF5 
	%% HDF5  

	%  $Revision$
 	%  was created 07-Apr-2020 13:25:09 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        filename = 'HDF5.h5'
        maxsize = [48 64 48 Inf]
        datatype = 'single'
        chunk = [4 4 4 1984]
        deflate = 9
        datasetname = '/images'
        Nt
    end
    
    methods
        function h5create(this, varargin)
            %  @param filename of new h5 storage.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addOptional(ip, 'filename', this.filename, @(x) ischar(x) && ~isfile(x))
            addOptional(ip, 'datasetname',this.datasetname, @ischar)
            addOptional(ip, 'maxsize', this.maxsize, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if ~strcmp(ipr.datasetname(1), filesep)
                ipr.datasetname = [filesep ipr.datasetname];
            end            
            h5create(ipr.filename, ipr.datasetname, ipr.maxsize, ...
                'Datatype', this.datatype, 'ChunkSize', this.chunk, 'Deflate', this.deflate)
        end
        function h5write(this, filename, datasetname, data, varargin)
            %% H5WRITE preserves the interface of Matlab's native h5write() and adds supporting features.
            %  @param filename.
            %  @param datasetname.
            %  @param data.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'filename', @isfile)
            addRequired(ip, 'datasetname', @ischar)
            addRequired(ip, 'data', @isnumeric)
            parse(ip, filename, datasetname, data)
            ipr = ip.Results;
            
            if ~strcmp(ipr.datasetname(1), filesep)
                ipr.datasetname = [filesep ipr.datasetname];
            end
            if ~isa(ipr.data, this.datatype)
                ipr.data = eval(sprintf('%s(ipr.data)', this.datatype));
            end            
            h5write(ipr.filename, ipr.datasetname, ipr.data, varargin{:})
        end
        function h5write_4dfp(this, filename, filename4dfp, start, varargin)
            %% rescales img to [0 1]
            %  @param filename of h5 storage.
            %  @param filename4dfp of 4dfp image to store.
            %  @param start location within storage at which to start writing.  
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'filename', @isfile)
            addRequired(ip, 'filename4dfp', @isfile)
            addRequired(ip, 'start', @isnumeric)
            parse(ip, filename, filename4dfp, start, varargin{:})
            ipr = ip.Results;
            
            ifc = mlfourd.ImagingFormatContext(ipr.filename4dfp);
            img = flip(ifc.img, 2);
            img = img - dipmin(img);
            img = img / dipmax(img);
            szi = size(img);
            if ~isempty(this.Nt)
                assert(this.Nt == szi(4), 'mldl:ValueError', 'HDF5.h5write_4dfp.szi(4)->', szi(4))
            end
            if ~all(szi == this.maxsize(1:ndims(img)))
                error('mldl:ValueError', 'HDF5.h5write_4dfp.sz -> %g', szi)
            end

            count = [szi 1];
            this.h5write(ipr.filename, this.datasetname, img, start, count)
        end
    end

	methods		  
 		function this = HDF5(varargin)
 			%% HDF5
 			%  @param maxsize.
            %  @param datatype.
            %  @param chunk.
            %  @param deflate.
            %  @param datasetname.

            ip = inputParser;
            addParameter(ip, 'filename', this.filename, @(x) ischar(x))
            addParameter(ip, 'maxsize', this.maxsize, @isnumeric)
            addParameter(ip, 'datatype', this.datatype, @ischar)
            addParameter(ip, 'chunk', this.chunk, @isnumeric)
            addParameter(ip, 'deflate', this.deflate, @isnumeric)
            addParameter(ip, 'datasetname', this.datasetname, @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.filename = ipr.filename;
            this.maxsize = ipr.maxsize;
            this.datatype = ipr.datatype;
            this.chunk = ipr.chunk;
            this.deflate = ipr.deflate;
            this.datasetname = ipr.datasetname;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

