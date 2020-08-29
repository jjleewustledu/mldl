classdef Epilepsy 
	%% EPILEPSY  

	%  $Revision$
 	%  was created 20-Aug-2020 16:06:31 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.8.0.1417392 (R2020a) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Constant)
        homeEpilepsy = '/data/shimony/shimony/jjlee/FocalEpilepsy/PT36'
        homeGsp = '/data/shimony/shimony/jjlee/GSP'
        homeMsc = '/data/shimony/shimony/jjlee/MSC_JJL/MSC01'
        seedMask = '/data/shimony/shimony/jjlee/FocalEpilepsy/PT36/JJL_segmentation_333_z23to25.nii.gz'
    end
    
    methods (Static)
        function createBpss()
            cd('/Users/jjlee/Google Drive/FocalEpilepsy/PT36')
            pt36 = mlfourd.ImagingFormatContext('bold1/PT36_b1_faln_dbnd_xr3d_atl_g7_bpss.nii.gz'); 
            pt36.img = reshape(pt36.img, [48*64*48 200]);
            for ib = 2:7
                ifc = mlfourd.ImagingFormatContext( ...
                    sprintf('bold%i/PT36_b%i_faln_dbnd_xr3d_atl_g7_bpss.nii.gz', ib, ib));
                pt36.img = [pt36.img reshape(ifc.img, [48*64*48 200])]; 
            end
            pt36.img = reshape(pt36.img, [48 64 48 1400]);
            pt36.filepath = pwd;
            pt36.fileprefix = 'PT36_faln_dbnd_xr3d_atl_g7_bpss';
            pt36.save            
        end
        function createH5()
            %% creates data for dcgan on colab.  All images are from BOLD bpss z-coords 23-25.  Images contain 
            %  similarity measures (corrcoef, Curto's corr., etc.) generated from time series between seeds and
            %  remaining voxels.  Seeds are sampled using binary mask Epilepsy.seedMask.
            %  mldl_Epilepsy_gsp.h5:  2D images are similarity measures of seeds with BOLD times-series drawn exclusively from GSP.
            %  mldl_Epilepsy_pt36.h5:  ... from focal epilepsy patient PT36.
            %  mldl_Epilepsy_msc01.h5:  ... from MSC subject 01.
            %  @return *.h5 are written to Epilepsy.homeEpilepsy.
            
            import mldl.Epilepsy.*
            pwd0 = pushd(Epilepsy.homeEpilepsy);  
            Epilepsy.createGspH5()
            Epilepsy.createEpilepsyH5()
            Epilepsy.createMscH5()
            popd(pwd0)
        end
        function createGspH5()
            import mldl.Epilepsy.*          
            fqh5 = fullfile(Epilepsy.homeEpilepsy, 'mldl_Epilepsy_gsp.h5');
            deleteExisting(fqh5)
            thisGsp = mldl.GSP_HDF5('filename', fqh5, ...
                                 'maxsize', [48 64 124 Inf], ...
                                 'chunk', [48 64 1 1], ...
                                 'Nt', 124, ...
                                 'srcLocation', Epilepsy.homeGsp, ...
                                 'suffix', '_faln_dbnd_xr3d_atl_g7_bpss.4dfp.hdr');
            thisGsp.h5create()
            thisGsp.h5writez('sub', 1:1570, 'ses', 1, 'bold', 1:2, 'zcoords', 23:25)
        end
        function createEpilepsyH5(varargin)
            import mldl.Epilepsy.* 
            fqh5 = fullfile(Epilepsy.homeEpilepsy, 'mldl_Epilepsy_pt36.h5');
            deleteExisting(fqh5)
            thisHdf5 = mldl.HDF5('filename', fqh5, ...
                'maxsize', [48 64 200 Inf], ...
                'chunk', [48 64 1 1], ...
                'Nt', 200, ...
                'srcLocation', fileparts(Epilepsy.homeEpilepsy), ...
                'suffix', '_faln_dbnd_xr3d_atl_g7_bpss.4dfp.hdr');
            thisHdf5.h5create()
            thisHdf5.h5writez('sub', {'PT36'}, 'bold', 1:7, 'zcoords', 23:25)
        end
        function createMscH5(varargin)
            import mldl.Epilepsy.* 
            fqh5 = fullfile(Epilepsy.homeEpilepsy, 'mldl_Epilepsy_msc01.h5');
            deleteExisting(fqh5)
            thisHdf5 = mldl.HDF5('filename', fqh5, ...
                'maxsize', [48 64 818 Inf], ...
                'chunk', [48 64 1 1], ...
                'Nt', 818, ...
                'srcLocation', Epilepsy.homeMsc, ...
                'suffix', '_faln_dbnd_xr3d_atl_g7_bpss.4dfp.hdr');
            thisHdf5.h5create()
            pwd1 = pushd(thisHdf5.srcLocation);
            globbed = globFoldersT('vc*');
            popd(pwd1)
            thisHdf5.h5writez('sub', globbed, 'bold', 1, 'zcoords', 23:25)
        end
    end

	methods 
		  
 		function this = Epilepsy(varargin)
 			%% EPILEPSY
 			%  @param .

 			
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end
