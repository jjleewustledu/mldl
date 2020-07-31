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
        doflipy = true
        Nt
        
        srcLocation
        h5Location
        suffix
    end
    
    methods (Static)
        function createFromRS003LocationZ24(varargin)
            fqh5 = '/Users/jjlee/Google Drive/mkrs/RS003_bpss_z24.h5';
            deleteExisting(fqh5)
            this = mldl.HDF5('filename', fqh5, ...
                'maxsize', [48 64 160 Inf], ...
                'chunk', [48 64 1 1], ...
                'Nt', 160, ...
                'h5Location', '/Users/jjlee/Google Drive/mkrs', ...
                'srcLocation', '/Users/jjlee/Google Drive/mkrs', ...
                'suffix', '_faln_dbnd_xr3d_atl_g7_bpss.nii.gz');
            this.h5create()
            this.h5writez_mkrs('sub', {'RS_003'}, ...
                'tag', '_MR_20140103_resttask', ...
                'bold', 1:2, ...
                'zcoords', 24)
        end
        function createFromPT36LocationZ24(varargin)
            fqh5 = '/Users/jjlee/Google Drive/FocalEpilepsy/PT36_bpss_z24.h5';
            deleteExisting(fqh5)
            this = mldl.HDF5('filename', fqh5, ...
                'maxsize', [48 64 200 Inf], ...
                'chunk', [48 64 1 1], ...
                'Nt', 200, ...
                'h5Location', '/Users/jjlee/Google Drive/FocalEpilepsy', ...
                'srcLocation', '/Users/jjlee/Google Drive/FocalEpilepsy', ...
                'suffix', '_faln_dbnd_xr3d_atl_g7_bpss.nii.gz');
            this.h5create()
            this.h5writez('sub', {'PT36'}, ...
                'bold', 1:7, ...
                'zcoords', 24)
        end
        function createFromMSC01LocationZ24(varargin)
            fqh5 = '/Users/jjlee/Google Drive/MSC/MSC01_bpss_z24.h5';
            deleteExisting(fqh5)
            this = mldl.HDF5('filename', fqh5, ...
                'maxsize', [48 64 818 Inf], ...
                'chunk', [48 64 1 1], ...
                'Nt', 818, ...
                'h5Location', '/Users/jjlee/Google Drive/MSC', ...
                'srcLocation', '/Users/jjlee/Google Drive/MSC/MSC01', ...
                'suffix', '_faln_dbnd_xr3d_atl_g7_bpss.nii.gz');
            this.h5create()
            pwd1 = pushd(this.srcLocation);
            globbed = globFoldersT('vc*');
            popd(pwd1)
            this.h5writez('sub', globbed, ...
                'bold', 1, ...
                'zcoords', 24)
        end
    end
    
    methods
        
        %%
        
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
        function h5write_format(this, filename, filename_format, start, varargin)
            %% rescales img to [0 1]
            %  @param required filename of h5 storage.
            %  @param required filename_format of 4dfp/Analyze/NIfTI image to store.
            %  @param required start location within storage at which to start writing.  
            %  @param zcoords is numeric, specifying zcoords to select for HDF5.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'filename', @isfile)
            addRequired(ip, 'filename_format', @isfile)
            addRequired(ip, 'start', @isnumeric)
            addParameter(ip, 'zcoords', [], @isnumeric)
            parse(ip, filename, filename_format, start, varargin{:})
            ipr = ip.Results;
            
            ifc = mlfourd.ImagingFormatContext(ipr.filename_format);
            if ~isempty(ipr.zcoords)
                img = squeeze(ifc.img(:,:,ipr.zcoords,:));
            else
                img = ifc.img;
            end
            if this.doflipy                
                img = flip(img, 2);
            end
            img = img - dipmin(img);
            img = img / dipmax(img);
            szi = size(img);
            if ~isempty(this.Nt)
                assert(this.Nt == szi(end), 'mldl:ValueError', 'HDF5.h5write_format.szi(end)->', szi(end))
            end
            if ~all(szi == this.maxsize(1:ndims(img)))
                error('mldl:ValueError', 'HDF5.h5write_format.sz -> %g', szi)
            end

            count = [szi 1];
            this.h5write(ipr.filename, this.datasetname, img, start, count)
        end
        function h5writez(this, varargin)
            %% H5WRITEZ uses instance data for performant calls to h5write().
            %  @param sub.
            %  @param sese.
            %  @param bold.
            %  @param suf.
            %  @param zcoords.
            
            ip = inputParser;
            addParameter(ip, 'sub', {''}, @iscell)
            addParameter(ip, 'ses', '', @ischar)
            addParameter(ip, 'bold', 1:2, @isnumeric)
            addParameter(ip, 'suf', this.suffix, @ischar)
            addParameter(ip, 'zcoords', [], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            info = h5info(this.filename);
            Size = info.Datasets.Dataspace.Size;
            start = ones(size(Size));
            for asub = ipr.sub
                for ibold = ipr.bold
                    bold_filename = fullfile( ...
                        this.srcLocation, ...
                        sprintf('%s%s', asub{1}, ipr.ses), ...
                        sprintf('bold%i', ibold), ...
                        sprintf('%s%s_b%i%s', asub{1}, ipr.ses, ibold, this.suffix));
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
        function h5writez_mkrs(this, varargin)
            %% H5WRITEZ uses instance data for performant calls to h5write().
            %  @param sub.
            %  @param sese.
            %  @param bold.
            %  @param suf.
            %  @param zcoords.
            
            ip = inputParser;
            addParameter(ip, 'sub', {''}, @iscell)
            addParameter(ip, 'ses', '', @ischar)
            addParameter(ip, 'tag', '', @ischar)
            addParameter(ip, 'bold', 1:2, @isnumeric)
            addParameter(ip, 'suf', this.suffix, @ischar)
            addParameter(ip, 'zcoords', [], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            info = h5info(this.filename);
            Size = info.Datasets.Dataspace.Size;
            start = ones(size(Size));
            for asub = ipr.sub
                for ibold = ipr.bold
                    bold_filename = fullfile( ...
                        this.srcLocation, ...
                        sprintf('%s%s', asub{1}, ipr.ses), ...
                        sprintf('boldrs%i', ibold), ...
                        sprintf('%s%s%s_brs%i%s', asub{1}, ipr.ses, ipr.tag, ibold, this.suffix));
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
    end

	methods		  
 		function this = HDF5(varargin)
 			%% HDF5
            %  @param filename is char.
 			%  @param maxsize is numeric.
            %  @param datatype is char.
            %  @param chunk is numeric.
            %  @param deflate is numeric.
            %  @param datasetname is char..
            %  @param h5Location is folder.
            %  @param srcLocation is folder.
            %  @param suffix is char.

            ip = inputParser;
            addParameter(ip, 'filename', this.filename, @(x) ischar(x))
            addParameter(ip, 'maxsize', this.maxsize, @isnumeric)
            addParameter(ip, 'datatype', this.datatype, @ischar)
            addParameter(ip, 'chunk', this.chunk, @isnumeric)
            addParameter(ip, 'deflate', this.deflate, @isnumeric)
            addParameter(ip, 'datasetname', this.datasetname, @ischar)
            addParameter(ip, 'Nt', [], @isnumeric)
            addParameter(ip, 'h5Location', '', @isfolder)
            addParameter(ip, 'srcLocation', '', @isfolder)
            addParameter(ip, 'suffix', '_faln_dbnd_xr3d_atl_g7_bpss.4dfp.hdr', @ischar)  % '_faln_dbnd_xr3d_atl.4dfp.hdr'
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.filename = ipr.filename;
            this.maxsize = ipr.maxsize;
            this.datatype = ipr.datatype;
            this.chunk = ipr.chunk;
            this.deflate = ipr.deflate;
            this.datasetname = ipr.datasetname;
            this.Nt = ipr.Nt;
            this.h5Location = ipr.h5Location;
            this.srcLocation = ipr.srcLocation;
            this.suffix = ipr.suffix;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

