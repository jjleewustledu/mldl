classdef GSP 
	%% GSP 

	%  $Revision$
 	%  was created 05-May-2020 16:45:09 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.8.0.1359463 (R2020a) Update 1 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Constant)
        gspLocation = '/data/nil-bluearc/shimony/jjlee/GSP'
        matLocation = '/data/nil-bluearc/shimony/jjlee/GSP_mat'
        niiLocation = '/data/shimony/shimony2/jjlee/GSP_nii'
 		selectedDenoisingTag = '_faln_dbnd_xr3d_atl'
    end
    
    properties
        itsImageDatastore
    end
    
    methods (Static)            
        function fp = boldFileprefix(folds)
            import mldl.GSP
            
            assert(ischar(folds))
            ss = split(folds, filesep);
            idx = ss{2};
            idx = str2double(idx(5));
            fp = sprintf('%s_b%i%s', ss{1}, idx, GSP.selectedDenoisingTag);
        end
        function this = createImageDatastoreFromMatLocation(varargin)
            ip = inputParser;
            addParameter(ip, 'location', mldl.GSP.matLocation, @isfolder)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            fs = matlab.io.datastore.DsFileSet(ipr.location, 'FileExtensions', '.mat');
            imds = imageDatastore(fs);
            this = mldl.GSP('anImageDatastore', imds);
        end
        function fourdfp2nii(varargin)
            %% creates NIfTI in targetFolder
            
            import mldl.GSP.boldFileprefix
            
            ip = inputParser;
            addOptional(ip, 'targetFolder', mldl.GSP.niiLocation, @(x) isfolder(x) || ischar(x))
            addParameter(ip, 'framesToDrop', 3, @isnumeric)
            addParameter(ip, 'zscore', true, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;            
            if ipr.zscore && ~lstrfind(lower(ipr.targetFolder), 'zscore')
                ipr.targetFolder = [ipr.targetFolder '_zscore'];
            end
            if ~isfolder(ipr.targetFolder)
                mkdir(ipr.targetFolder)
            end
            
            cd(mldl.GSP.gspLocation)            
            for fold = globFoldersT('Sub*_Ses*')
                for b = globFoldersT(fullfile(fold{1}, 'bold*'))
                    ifc = mlfourd.ImagingFormatContext( ...
                        fullfile(b{1}, sprintf('%s.4dfp.hdr', boldFileprefix(b{1}))));
                    assert(isfile(ifc.fqfilename))
                    assert(~isempty(ifc.img))
                    ifc.img = ifc.img(:,:,:,ipr.framesToDrop+1:end);
                    ifc.filepath = ipr.targetFolder;
                    ifc.filesuffix = '.nii.gz';
                    ic = mlfourd.ImagingContext2(ifc);
                    if ipr.zscore
                        ic = (ic - ic.timeAveraged()) ./ ic.std();
                        ic.fileprefix = [ic.fileprefix '_zscore'];
                    end
                    ic.save()
                    deleteExisting([ic.fqfileprefix '.log'])
                end
            end
        end
        function fourdfp2mat(varargin)
            %% creates mat-files, formatted by Patrick Luckett's conventions with object named 'dat', in targetFolder
                        
            import mldl.GSP.boldFileprefix
            
            ip = inputParser;
            addOptional(ip, 'targetFolder', mldl.GSP.matLocation, @(x) isfolder(x) || ischar(x))
            parse(ip, varargin{:})
            ipr = ip.Results;            
            if ~isfolder(ipr.targetFolder)
                mkdir(ipr.targetFolder)
            end
            
            cd(mldl.GSP.gspLocation)    
            for fold = globFoldersT('Sub*_Ses*')
                for b = globFoldersT(fullfile(fold{1}, 'bold*'))
                    ifc = mlfourd.ImagingFormatContext( ...
                        fullfile(b{1}, sprintf('%s.4dfp.hdr', boldFileprefix(b{1}))));
                    dat = ifc.img;
                    save(fullfile(targetFolder, [strrep(b{1}, filesep, '_') '.mat']), 'dat')
                end
            end
        end
    end
    
    %% PROTECTED

	methods (Access = protected)		  
 		function this = GSP(varargin)
 			%% GSP
 			%  @param anImageDatastore; default := [].

            ip = inputParser;
            addParameter(ip, 'anImageDatastore', [], @(x) isa(x, 'imageDatastore') || isempty(x))
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.itsImageDatastore = ipr.anImageDatastore;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

