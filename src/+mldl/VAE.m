classdef VAE 
	%% VAE  

	%  $Revision$
 	%  was created 15-Dec-2019 23:37:14 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1247435 (R2019b) Update 2 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties
 		XTrain
        XTest
        YTest
        
        latentDim = 20
        imageSize = [28 28 1];
        
        encoderNet
        decoderNet
    end
    
    properties (Dependent)
        numTrainImages
    end
    
    methods (Static)
        function X = processImages(filename)
            % The MNIST processing functions extract the data from the downloaded IDX
            % files into MATLAB arrays. The processImagesMNIST function performs these
            % operations: Check if the file can be opened correctly. Obtain the magic
            % number by reading the first four bytes. The magic number is 2051 for
            % image data, and 2049 for label data. Read the next 3 sets of 4 bytes,
            % which return the number of images, the number of rows, and the number of
            % columns. Read the image data. Reshape the array and swaps the first two
            % dimensions due to the fact that the data was being read in column major
            % format. Ensure the pixel values are in the range  [0,1] by dividing them
            % all by 255, and converts the 3-D array to a 4-D dlarray object. Close the
            % file.
            
            [fileID,errmsg] = fopen(filename,'r','b');
            if fileID < 0
                error(errmsg);
            end
            
            magicNum = fread(fileID,1,'int32',0,'b');
            if magicNum == 2051
                fprintf('\nRead MNIST image data...\n')
            end
            
            numImages = fread(fileID,1,'int32',0,'b');
            fprintf('Number of images in the dataset: %6d ...\n',numImages);
            numRows = fread(fileID,1,'int32',0,'b');
            numCols = fread(fileID,1,'int32',0,'b');
            
            X = fread(fileID,inf,'unsigned char');
            
            X = reshape(X,numCols,numRows,numImages);
            X = permute(X,[2 1 3]);
            X = X./255;
            X = reshape(X, [28,28,1,size(X,3)]);
            X = dlarray(X, 'SSCB');
            
            fclose(fileID);
        end
        function Y = processLabels(filename)
            % The processLabelsMNIST function operates similarly to the
            % processImagesMNIST function. After opening the file and reading the magic
            % number, it reads the labels and returns a categorical array containing
            % their values.
            
            [fileID,errmsg] = fopen(filename,'r','b');
            
            if fileID < 0
                error(errmsg);
            end
            
            magicNum = fread(fileID,1,'int32',0,'b');
            if magicNum == 2049
                fprintf('\nRead MNIST label data...\n')
            end
            
            numItems = fread(fileID,1,'int32',0,'b');
            fprintf('Number of labels in the dataset: %6d ...\n',numItems);
            
            Y = fread(fileID,inf,'unsigned char');
            
            Y = categorical(Y);
            
            fclose(fileID);
        end
        
        %% Sampling and Loss Functions
        
        function [zSampled, zMean, zLogvar] = sampling(encoderNet, x)
            compressed = forward(encoderNet, x);
            d = size(compressed,1)/2;
            zMean = compressed(1:d,:);
            zLogvar = compressed(1+d:end,:);
            
            sz = size(zMean);
            epsilon = randn(sz);
            sigma = exp(.5 * zLogvar);
            z = epsilon .* sigma + zMean;
            z = reshape(z, [1,1,sz]);
            zSampled = dlarray(z, 'SSCB');
        end        
        function elbo = ELBOloss(x, xPred, zMean, zLogvar)
            squares = 0.5*(xPred-x).^2;
            reconstructionLoss  = sum(squares, [1,2,3]);
            
            KL = -.5 * sum(1 + zLogvar - zMean.^2 - exp(zLogvar), 1);
            
            elbo = mean(reconstructionLoss + KL);
        end
        
        
        %% Model Gradients Function
        
        function [infGrad, genGrad] = modelGradients(encoderNet, decoderNet, x)
            import mldl.VAE.sampling
            import mldl.VAE.ELBOloss
            
            [z, zMean, zLogvar] = sampling(encoderNet, x);
            xPred = sigmoid(forward(decoderNet, z));
            loss = ELBOloss(x, xPred, zMean, zLogvar);
            [genGrad, infGrad] = dlgradient(loss, decoderNet.Learnables, ...
                encoderNet.Learnables);
        end
    end

	methods 
        
        %% GET
        
        function g = get.numTrainImages(this)
            g = size(this.XTrain,4);
        end
        
        %%
        
        function this = constructNetwork(this)
            encoderLG = layerGraph([
                imageInputLayer(this.imageSize,'Name','input_encoder','Normalization','none')
                convolution2dLayer(3, 32, 'Padding','same', 'Stride', 2, 'Name', 'conv1')
                reluLayer('Name','relu1')
                convolution2dLayer(3, 64, 'Padding','same', 'Stride', 2, 'Name', 'conv2')
                reluLayer('Name','relu2')
                fullyConnectedLayer(2 * this.latentDim, 'Name', 'fc_encoder')
                ]);            
            decoderLG = layerGraph([
                imageInputLayer([1 1 this.latentDim],'Name','i','Normalization','none')
                transposedConv2dLayer(7, 64, 'Cropping', 'same', 'Stride', 7, 'Name', 'transpose1')
                reluLayer('Name','relu1')
                transposedConv2dLayer(3, 64, 'Cropping', 'same', 'Stride', 2, 'Name', 'transpose2')
                reluLayer('Name','relu2')
                transposedConv2dLayer(3, 32, 'Cropping', 'same', 'Stride', 2, 'Name', 'transpose3')
                reluLayer('Name','relu3')
                transposedConv2dLayer(3, 1, 'Cropping', 'same', 'Name', 'transpose4')
                ]);
            this.encoderNet = dlnetwork(encoderLG);
            this.decoderNet = dlnetwork(decoderLG);
        end        
        function this = trainModel(this)
            import mldl.VAE.modelGradients
            
            executionEnvironment = 'auto';
            numEpochs = 50;
            miniBatchSize = 512;
            lr = 1e-3;
            numIterations = floor(this.numTrainImages/miniBatchSize);
            iteration = 0;

            avgGradientsEncoder = [];
            avgGradientsSquaredEncoder = [];
            avgGradientsDecoder = [];
            avgGradientsSquaredDecoder = [];
            
            for epoch = 1:numEpochs
                tic;
                for i = 1:numIterations
                    iteration = iteration + 1;
                    idx = (i-1)*miniBatchSize+1:i*miniBatchSize;
                    XBatch = this.XTrain(:,:,:,idx);
                    XBatch = dlarray(single(XBatch), 'SSCB');
                    
                    if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
                        XBatch = gpuArray(XBatch);
                    end
                    
                    [infGrad, genGrad] = dlfeval(...
                        @modelGradients, this.encoderNet, this.decoderNet, XBatch);
                    
                    [this.decoderNet.Learnables, avgGradientsDecoder, avgGradientsSquaredDecoder] = ...
                        adamupdate(this.decoderNet.Learnables, ...
                        genGrad, avgGradientsDecoder, avgGradientsSquaredDecoder, iteration, lr);
                    [this.encoderNet.Learnables, avgGradientsEncoder, avgGradientsSquaredEncoder] = ...
                        adamupdate(this.encoderNet.Learnables, ...
                        infGrad, avgGradientsEncoder, avgGradientsSquaredEncoder, iteration, lr);
                end
                elapsedTime = toc;
                
                [z, zMean, zLogvar] = this.sampling(this.encoderNet, this.XTest);
                xPred = sigmoid(forward(this.decoderNet, z));
                elbo = this.ELBOloss(this.XTest, xPred, zMean, zLogvar);
                disp("Epoch : "+epoch+" Test ELBO loss = "+gather(extractdata(elbo))+...
                    ". Time taken for epoch = "+ elapsedTime + "s")
            end
        end
        function this = visualizeResults(this)
            this.visualizeReconstruction;
            this.visualizeLatentSpace;
            this.generate()
        end
		  
 		function this = VAE(varargin)
 			%% VAE
 			%  @param trainImagesFile.
 			%  @param testImagesFile.
 			%  @param testLabelsFile.
            
            ip = inputParser;
            addParameter(ip, 'trainImagesFile', 'train-images.idx3-ubyte', @isfile)
            addParameter(ip, 'testImagesFile',  't10k-images.idx3-ubyte',  @isfile)
            addParameter(ip, 'testLabelsFile',  't10k-labels.idx1-ubyte',  @isfile)
            parse(ip, varargin{:})
            ipr = ip.Results;

 			this.XTrain = this.processImages(ipr.trainImagesFile);
            this.XTest  = this.processImages(ipr.testImagesFile);
            this.YTest  = this.processLabels(ipr.testLabelsFile);
            
            this = this.constructNetwork();
 		end
    end 
    
    %% PROTECTED
    
    methods (Access = protected)
        
        %% Visualization Functions
        
        function visualizeReconstruction(this)
            f = figure;
            figure(f)
            title("Example ground truth image vs. reconstructed image")
            for i = 1:2
                for c=0:9
                    idx = this.iRandomIdxOfClass(this.YTest,c);
                    X = this.XTest(:,:,:,idx);
                    
                    [z, ~, ~] = this.sampling(this.encoderNet, X);
                    XPred = sigmoid(forward(this.decoderNet, z));
                    
                    X = gather(extractdata(X));
                    XPred = gather(extractdata(XPred));
                    
                    comparison = [X, ones(size(X,1),1), XPred];
                    subplot(4,5,(i-1)*10+c+1), imshow(comparison,[]),
                end
            end
        end        
        function idx = iRandomIdxOfClass(~, T,c)
            idx = T == categorical(c);
            idx = find(idx);
            idx = idx(randi(numel(idx),1));
        end
        function visualizeLatentSpace(this, XTest, YTest, encoderNet)
            [~, zMean, zLogvar] = this.sampling(encoderNet, XTest);
            
            zMean = stripdims(zMean)';
            zMean = gather(extractdata(zMean));
            
            zLogvar = stripdims(zLogvar)';
            zLogvar = gather(extractdata(zLogvar));
            
            [~,scoreMean] = pca(zMean);
            [~,scoreLogvar] = pca(zLogvar);
            
            c = parula(10);
            f1 = figure;
            figure(f1)
            title("Latent space")
            
            ah = subplot(1,2,1);
            scatter(scoreMean(:,2),scoreMean(:,1),[],c(double(YTest),:));
            ah.YDir = 'reverse';
            axis equal
            xlabel("Z_m_u(2)")
            ylabel("Z_m_u(1)")
            cb = colorbar; cb.Ticks = 0:(1/9):1; cb.TickLabels = string(0:9);
            
            ah = subplot(1,2,2);
            scatter(scoreLogvar(:,2),scoreLogvar(:,1),[],c(double(YTest),:));
            ah.YDir = 'reverse';
            xlabel("Z_v_a_r(2)")
            ylabel("Z_v_a_r(1)")
            cb = colorbar;  cb.Ticks = 0:(1/9):1; cb.TickLabels = string(0:9);
            axis equal
        end
        function generate(this)
            randomNoise = dlarray(randn(1,1,this.latentDim,25),'SSCB');
            generatedImage = sigmoid(predict(this.decoderNet, randomNoise));
            generatedImage = extractdata(generatedImage);
            
            f3 = figure;
            figure(f3)
            imshow(imtile(generatedImage, "ThumbnailSize", [100,100]))
            title("Generated samples of digits")
            drawnow
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

