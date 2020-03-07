classdef TumorSegmentation 
	%% TUMORSEGMENTATION
    %  4D images must be ordered as {T1, Gd-enhanced T1, T2, FLAIR}.

	%  $Revision$
 	%  was created 28-Oct-2019 17:27:42 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1216025 (R2019b) Update 1 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties 		
        archive
        preprocessDataLoc
        preprocessDataset
        source
        sourceDataLoc
    end
    
    properties (Dependent)
        archiveSubDirs
        subDirs
    end
    
    methods (Static)
        function writeLst(fn, carray)
            mlparallel.Torque.writeLst(fn, carray);
        end
        function writePbs(fn)
            mlparallel.Torque.writePbs(fn, 'FreeSurfer')
        end
    end

	methods 
        
        %% GET, SET
        
        function g = get.archiveSubDirs(this)
            g = globT(fullfile(this.archive, 'RT*'));
        end
        function g = get.subDirs(this)
            g = cellfun(@(x) fullfile(this.source, mybasename(x)), this.archiveSubDirs, 'UniformOutput', false);
        end
        
        %%
        
        function this = buildSourceDirs(this)
            for arch_subdirs = this.archiveSubDirs
                subfold = mybasename(arch_subdirs{1});
                subdir = fullfile(this.source, subfold);
                
                if ~isfolder(subdir)
                    mkdir(subdir)
                end
                
                for suff = {'_MR_Pre/' '_MR_Post/'}
                    for arch_mrdirs = globT(fullfile(arch_subdirs{1}, [subfold suff{1}]))
                        mrfold = mybasename(arch_mrdirs{1});
                        mrdir = fullfile(subdir, mrfold);
                        if isfolder(arch_mrdirs{1}) && ~isfolder(mrdir)
                            mkdir(mrdir)
                            copyfile(fullfile(arch_mrdirs{1}, 'SCANS'), mrdir)
                            mlfourdfp.SCANS(mrdir);
                        end
                    end
                end
            end
        end
        function this = pullFreeSurfer(this)
        end
        function this = pushFreeSurfer(this)
            %% rsyncs data to CHPC
            %  writes pbs file for Torque at CHPC
            %  recon-all \
            %  -i  <one slice in the anatomical dicom series> \
            %  -s  <subject id that you make up> \
            %  -sd <directory to put the subject folder in> \
            %  -all

            subdirs = this.subDirs;
            mprIndices = cell(1, length(subdirs));
            for isub = 1:length(subdirs)
                subfold = mybasename(subdirs{isub});
                mrdir = fullfile(subdirs{isub}, [subfold '_MR_Pre']);
                scansTbl = mlfoudfp.SCANS(mrdir);
                idxcell = strfind(lower(scansTbl.description), 'sagt1mpr');
                for idx = 1:length(idxcell)
                    if ~isempty(idxcell{idx})
                        series = scansTbl.series(idx);
                        system(sprintf( ...
                            'rsync -ra %s/SCANS/%i/ dtn01.chpc.wustl.edu:/scratch/jjlee/%s/%s/SCANS/%i/', ...
                            subdirs{isub}, series, mybasename(this.source), subfold, series))
                        mprIndices{isub} = idx;
                    end
                end
            end
            this.writeLst(fullfile(fileparts(subdirs{1}), 'mldl_TumorSegmentation_pushFreeSurfer.lst'), mprIndices)
            this.writePbs(fullfile(fileparts(subdirs{1}), 'mldl_TumorSegmentation_pushFreeSurfer.pbs'))
        end
        function this = doSegmentation(this)
            
            volLocTest = fullfile(this.preprocessDataLoc,'imagesTest');
            lblLocTest = fullfile(this.preprocessDataLoc,'labelsTest');
            
            volReader = @(x) matRead(x);
            voldsTest = imageDatastore(volLocTest, ...
                'FileExtensions','.mat','ReadFcn',volReader);
            pxdsTest = pixelLabelDatastore(lblLocTest,classNames,pixelLabelID, ...
                'FileExtensions','.mat','ReadFcn',volReader);
            
            id = 1;
            while hasdata(voldsTest)
                disp(['Processing test volume ' num2str(id)]);

                tempGroundTruth = read(pxdsTest);
                groundTruthLabels{id} = tempGroundTruth{1};
                vol{id} = read(voldsTest);

                % Use reflection padding for the test image. 
                % Avoid padding of different modalities.
                volSize = size(vol{id},(1:3));
                padSizePre  = (inputPatchSize(1:3)-outPatchSize(1:3))/2;
                padSizePost = (inputPatchSize(1:3)-outPatchSize(1:3))/2 + (outPatchSize(1:3)-mod(volSize,outPatchSize(1:3)));
                volPaddedPre = padarray(vol{id},padSizePre,'symmetric','pre');
                volPadded = padarray(volPaddedPre,padSizePost,'symmetric','post');
                [heightPad,widthPad,depthPad,~] = size(volPadded);
                [height,width,depth,~] = size(vol{id});

                tempSeg = categorical(zeros([height,width,depth],'uint8'),[0;1],classNames);

                % Overlap-tile strategy for segmentation of volumes.
                for k = 1:outPatchSize(3):depthPad-inputPatchSize(3)+1
                    for j = 1:outPatchSize(2):widthPad-inputPatchSize(2)+1
                        for i = 1:outPatchSize(1):heightPad-inputPatchSize(1)+1
                            patch = volPadded( i:i+inputPatchSize(1)-1,...
                                j:j+inputPatchSize(2)-1,...
                                k:k+inputPatchSize(3)-1,:);
                            patchSeg = semanticseg(patch,net);
                            tempSeg(i:i+outPatchSize(1)-1, ...
                                j:j+outPatchSize(2)-1, ...
                                k:k+outPatchSize(3)-1) = patchSeg;
                        end
                    end
                end

                % Crop out the extra padded region.
                tempSeg = tempSeg(1:height,1:width,1:depth);

                % Save the predicted volume result.
                predictedLabels{id} = tempSeg;
                id=id+1;
            end
        end
        function this = preprocessFourdfp(this, destination)
            %% Crops the data set to a region containing primarily the brain and tumor.
            %  Then, normalizes each modality of the 4-D volumetric series independently
            %  by subtracting the mean and dividing by the standard deviation of the
            %  cropped brain region.            
            
            %% Load data
            volLoc = [this.source filesep 'imagesTest'];
            lblLoc = [this.source filesep 'labelsTest']; % for bounding box
            
            % If the directory for preprocessed data does not exist, or only a partial
            % set of the data files have been processed, process the data.
            if ~exist(destination,'dir') || this.proceedWithPreprocessing(destination)
                
                mkdir(fullfile(destination,'imagesTest'));

                labelReader = @(x) (niftiread(x) > 0);
                volReader = @(x) niftiread(x);
                volds = imageDatastore(volLoc, ...
                    'FileExtensions','.gz','ReadFcn',volReader);
                classNames = ["background","tumor"];
                pixelLabelID = [0 1];
                pxds = pixelLabelDatastore(lblLoc, classNames, pixelLabelID, ...
                    'FileExtensions','.gz','ReadFcn',labelReader);
                reset(volds);
                reset(pxds);

                %% Crop relevant region
                id = 1;
                while hasdata(volds)
                    outL = readNumeric(pxds);
                    outV = read(volds);
                    temp = outL>0;
                    sz = size(outL);
                    reg = regionprops3(temp,'BoundingBox');
                    tol = 132;
                    ROI = ceil(reg.BoundingBox(1,:));
                    ROIst = ROI(1:3) - tol;
                    ROIend = ROI(1:3) + ROI(4:6) + tol;

                    ROIst(ROIst<1)=1;
                    ROIend(ROIend>sz)=sz(ROIend>sz);          

                    tumorRows = ROIst(2):ROIend(2);
                    tumorCols = ROIst(1):ROIend(1);
                    tumorPlanes = ROIst(3):ROIend(3);

                    tcropVol = outV(tumorRows,tumorCols, tumorPlanes,:);

                    % Data set with a valid size for 3-D U-Net (multiple of 8).
                    ind = floor(size(tcropVol)/8)*8;
                    incropVol = tcropVol(1:ind(1),1:ind(2),1:ind(3),:);
                    mask = incropVol == 0;
                    cropVol = this.channelWisePreProcess(incropVol);

                    % Set the nonbrain region to 0.
                    cropVol(mask) = 0;

                    imDir    = fullfile(destination,'imagesTest','rsfMRITumor');
                    save([imDir num2str(id,'%.3d') '.mat'],'cropVol');
                    id=id+1;       
               end
            end
        end
		  
 		function this = TumorSegmentation(varargin)
 			%% TUMORSEGMENTATION
 			%  @param .
            
            ip = inputParser;
            addParameter(ip, 'archive', '/data/nil-bluearc/shimony/jjlee/rsfMRITumor', @isfolder)
            addParameter(ip, 'source', '/data/nil-bluearc/shimony/jjlee/rsfMRITumor_Unet', @isfolder)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.archive = ipr.archive;
            this.source = ipr.source;
            
            imageDir = fullfile(tempdir,'BraTS');
 			this.sourceDataLoc = [imageDir filesep 'Task01_BrainTumour'];
            this.preprocessDataLoc = fullfile(tempdir,'BraTS','preprocessedDataset');
            this.preprocessDataset(preprocessDataLoc,sourceDataLoc);
 		end
    end
    
    methods (Access = private)
        function out = channelWisePreProcess(~, in)
            % As input has 4 channels (modalities), remove the mean and divide by the
            % standard deviation of each modality independently.
            chn_Mean = mean(in,[1 2 3]);
            chn_Std = std(in,0,[1 2 3]);
            out = (in - chn_Mean)./chn_Std;
            
            rangeMin = -5;
            rangeMax = 5;
            
            out(out > rangeMax) = rangeMax;
            out(out < rangeMin) = rangeMin;
            
            % Rescale the data to the range [0, 1].
            out = (out - rangeMin) / (rangeMax - rangeMin);
        end
        function out = proceedWithPreprocessing(~, destination)
            totalNumFiles = 116;
            numFiles = 0;
            if exist(fullfile(destination,'imagesTest'),'dir')
                tmp1 = dir(fullfile(destination,'imagesTest'));
                numFiles = numFiles + sum(~vertcat(tmp1.isfolder));
            end

            % If total number of preprocessed files is not equal to the number of
            % files in the dataset, perform preprocessing. Otherwise, preprocessing has
            % already been completed and can be skipped.
            out = (numFiles ~= totalNumFiles);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

