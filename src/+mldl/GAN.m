classdef GAN 
	%% GAN stylistically modifies
    %  web(fullfile(docroot, 'deeplearning/examples/train-generative-adversarial-network.html')) .

	%  $Revision$
 	%  was created 15-Dec-2019 23:37:19 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1247435 (R2019b) Update 2 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties
        datasetFolder
 		dlnetDiscriminator
        dlnetGenerator
        imds
        lgraphGenerator
        lgraphDiscriminator
        numLatentInputs = 100
    end

	methods		  
 		function this = GAN(varargin)
        end
        
        function aids = augmentedImageDatastore(~)
            aids = [];
        end
        function this = defineNetworks(this)
            
            filterSize = [4 4];
            numFilters = 64;

            layersGenerator = [
                imageInputLayer([1 1 this.numLatentInputs],'Normalization','none','Name','in')
                transposedConv2dLayer(filterSize,8*numFilters,'Name','tconv1')
                batchNormalizationLayer('Name','bn1')
                reluLayer('Name','relu1')
                transposedConv2dLayer(filterSize,4*numFilters,'Stride',2,'Cropping',1,'Name','tconv2')
                batchNormalizationLayer('Name','bn2')
                reluLayer('Name','relu2')
                transposedConv2dLayer(filterSize,2*numFilters,'Stride',2,'Cropping',1,'Name','tconv3')
                batchNormalizationLayer('Name','bn3')
                reluLayer('Name','relu3')
                transposedConv2dLayer(filterSize,numFilters,'Stride',2,'Cropping',1,'Name','tconv4')
                batchNormalizationLayer('Name','bn4')
                reluLayer('Name','relu4')
                transposedConv2dLayer(filterSize,3,'Stride',2,'Cropping',1,'Name','tconv5')
                tanhLayer('Name','tanh')];
            this.lgraphGenerator = layerGraph(layersGenerator);
            this.dlnetGenerator = dlnetwork(this.lgraphGenerator);
            
            scale = 0.2;

            layersDiscriminator = [
                imageInputLayer([64 64 3],'Normalization','none','Name','in')
                convolution2dLayer(filterSize,numFilters,'Stride',2,'Padding',1,'Name','conv1')
                leakyReluLayer(scale,'Name','lrelu1')
                convolution2dLayer(filterSize,2*numFilters,'Stride',2,'Padding',1,'Name','conv2')
                batchNormalizationLayer('Name','bn2')
                leakyReluLayer(scale,'Name','lrelu2')
                convolution2dLayer(filterSize,4*numFilters,'Stride',2,'Padding',1,'Name','conv3')
                batchNormalizationLayer('Name','bn3')
                leakyReluLayer(scale,'Name','lrelu3')
                convolution2dLayer(filterSize,8*numFilters,'Stride',2,'Padding',1,'Name','conv4')
                batchNormalizationLayer('Name','bn4')
                leakyReluLayer(scale,'Name','lrelu4')
                convolution2dLayer(filterSize,1,'Name','conv5')];
            this.lgraphDiscriminator = layerGraph(layersDiscriminator);            
            this.dlnetDiscriminator = dlnetwork(this.lgraphDiscriminator);
        end
        function plot(this)
            figure
            subplot(1,2,1)
            plot(this.lgraphGenerator)
            title("Generator")            
            subplot(1,2,2)
            plot(this.lgraphDiscriminator)
            title("Discriminator")
        end
        function this = trainModel(this)
            
            % Train with a minibatch size of 128 for 1000 epochs. For larger datasets, you might not need to train for
            % as many epochs. Set the read size of the augmented image datastore to the mini-batch size.
            
            numEpochs = 1000;
            miniBatchSize = 128;
            augimds = this.augmentedImageDatastore();
            augimds.MiniBatchSize = miniBatchSize;
            
            % Specify the options for ADAM optimization.
            
            learnRateGenerator = 0.0002;
            learnRateDiscriminator = 0.0001;

            trailingAvgGenerator = [];
            trailingAvgSqGenerator = [];
            trailingAvgDiscriminator = [];
            trailingAvgSqDiscriminator = [];

            gradientDecayFactor = 0.5;
            squaredGradientDecayFactor = 0.999;
            
            executionEnvironment = "auto";

            % Train the model using a custom training loop. Loop over the training data and update the network
            % parameters at each iteration. To monitor the training progress, display a batch of generated images using
            % a held-out array of random values to input into the generator.
            
            % To monitor training progress, create a held-out batch of fixed 64 1-by-1-by-100 arrays of random values to
            % input into the generator. Specify the dimension labels 'SSCB' (spatial, spatial, channel, batch). For GPU
            % training, convert the data to gpuArray.
            
            ZValidation = randn(1,1,this.numLatentInputs,64,'single');
            dlZValidation = dlarray(ZValidation,'SSCB');

            if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
                dlZValidation = gpuArray(dlZValidation);
            end
            
            % Train the GAN. This can take some time to run.
            
            figure
            iteration = 0;
            start = tic;

            % Loop over epochs.
            for i = 1:numEpochs

                % Reset and shuffle datastore.
                reset(augimds);
                augimds = shuffle(augimds);

                % Loop over mini-batches.
                while hasdata(augimds)
                    iteration = iteration + 1;

                    % Read mini-batch of data.
                    data = read(augimds);

                    % Ignore last partial mini-batch of epoch.
                    if size(data,1) < miniBatchSize
                        continue
                    end

                    % Concatenate mini-batch of data and generate latent inputs for the
                    % generator network.
                    X = cat(4,data{:,1}{:});
                    Z = randn(1,1,this.numLatentInputs,size(X,4),'single');

                    % Normalize the images
                    X = (single(X)/255)*2 - 1;

                    % Convert mini-batch of data to dlarray specify the dimension labels
                    % 'SSCB' (spatial, spatial, channel, batch).
                    dlX = dlarray(X, 'SSCB');
                    dlZ = dlarray(Z, 'SSCB');

                    % If training on a GPU, then convert data to gpuArray.
                    if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
                        dlX = gpuArray(dlX);
                        dlZ = gpuArray(dlZ);
                    end

                    % Evaluate the model gradients and the generator state using
                    % dlfeval and the modelGradients function listed at the end of the
                    % example.
                    [gradientsGenerator, gradientsDiscriminator, stateGenerator] = ...
                        dlfeval(@mldl.GAN.modelGradients, this.dlnetGenerator, this.dlnetDiscriminator, dlX, dlZ);
                    this.dlnetGenerator.State = stateGenerator;

                    % Update the discriminator network parameters.
                    [this.dlnetDiscriminator.Learnables,trailingAvgDiscriminator,trailingAvgSqDiscriminator] = ...
                        adamupdate(this.dlnetDiscriminator.Learnables, gradientsDiscriminator, ...
                        trailingAvgDiscriminator, trailingAvgSqDiscriminator, iteration, ...
                        learnRateDiscriminator, gradientDecayFactor, squaredGradientDecayFactor);

                    % Update the generator network parameters.
                    [this.dlnetGenerator.Learnables,trailingAvgGenerator,trailingAvgSqGenerator] = ...
                        adamupdate(this.dlnetGenerator.Learnables, gradientsGenerator, ...
                        trailingAvgGenerator, trailingAvgSqGenerator, iteration, ...
                        learnRateGenerator, gradientDecayFactor, squaredGradientDecayFactor);

                    % Every 100 iterations, display batch of generated images using the
                    % held-out generator input.
                    if mod(iteration,100) == 0 || iteration == 1

                        % Generate images using the held-out generator input.
                        dlXGeneratedValidation = predict(this.dlnetGenerator,dlZValidation);

                        % Rescale the images in the range [0 1] and display the images.
                        I = imtile(extractdata(dlXGeneratedValidation));
                        I = rescale(I);
                        image(I)

                        % Update the title with training progress information.
                        D = duration(0,0,toc(start),'Format','hh:mm:ss');
                        title(...
                            "Epoch: " + i + ", " + ...
                            "Iteration: " + iteration + ", " + ...
                            "Elapsed: " + string(D))

                        drawnow
                    end
                end
            end
        end
        function this = generateNewImages(this)
            
            % To generate new images, use the predict function on the generator with a dlarray object containing a batch
            % of 1-by-1-by-100 arrays of random values. To display the images together, use the imtile function and
            % rescale the images using the rescale function.
            
            ZNew = randn(1,1,this.numLatentInputs,16,'single');
            dlZNew = dlarray(ZNew,'SSCB');
            
            if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
                dlZNew = gpuArray(dlZNew);
            end
            
            dlXGeneratedNew = predict(this.dlnetGenerator,dlZNew);
            
            I = imtile(extractdata(dlXGeneratedNew));
            I = rescale(I);
            image(I)
            title("Generated Images")
        end        
    end 
    
    %% PROTECTED
    
    methods (Static, Access = protected)
        function [lossGenerator, lossDiscriminator] = ganLoss(dlYPred,dlYPredGenerated)

            % Calculate losses for the discriminator network.
            lossGenerated = -mean(log(1-sigmoid(dlYPredGenerated)));
            lossReal = -mean(log(sigmoid(dlYPred)));

            % Combine the losses for the discriminator network.
            lossDiscriminator = lossReal + lossGenerated;

            % Calculate the loss for the generator network.
            lossGenerator = -mean(log(sigmoid(dlYPredGenerated)));
        end
        function [gradientsGenerator, gradientsDiscriminator, stateGenerator] = ...
            modelGradients(dlnetGenerator, dlnetDiscriminator, dlX, dlZ)

            % Calculate the predictions for real data with the discriminator network.
            dlYPred = forward(dlnetDiscriminator, dlX);

            % Calculate the predictions for generated data with the discriminator network.
            [dlXGenerated,stateGenerator] = forward(dlnetGenerator,dlZ);
            dlYPredGenerated = forward(dlnetDiscriminator, dlXGenerated);

            % Calculate the GAN loss
            [lossGenerator, lossDiscriminator] = mldl.GAN.ganLoss(dlYPred,dlYPredGenerated);

            % For each network, calculate the gradients with respect to the loss.
            gradientsGenerator = dlgradient(lossGenerator, dlnetGenerator.Learnables,'RetainData',true);
            gradientsDiscriminator = dlgradient(lossDiscriminator, dlnetDiscriminator.Learnables);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

