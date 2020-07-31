% imds = imageDatastore('/data/ances2/Patrick_Shimony2/','IncludeSubfolders',true,'LabelSource','foldernames','FileExtensions','.mat', 'ReadFcn',@(x) matRead300(x));
% auimds = augmentedImageDatastore([48, 64, 96],imds,'DataAugmentation',augmenter)
% imds2 = transform(imds,@classificationAugmentationPipeline);
% dsTrain = transform(imds,@classificationAugmentationPipeline,'IncludeInfo',true);
% imdsCombined = combine(imds,dsTrain)
% imds = imageDatastore({imds,dsTrain},'IncludeSubfolders',true,'LabelSource','foldernames','FileExtensions','.mat', 'ReadFcn',@(x) matRead300(x));
% [imdsTrain,imdsValidation] = splitEachLabel(imdsCombined,0.8,.2,'randomized');
% return

cd /data/nil-bluearc/shimony/jjlee/FocalEpilepsy/Patrick/epilepsy

imds = imageDatastore('/scratch/jjlee/NoiseID/','IncludeSubfolders',true,'LabelSource','foldernames','FileExtensions','.mat', 'ReadFcn',@(x) matReadepi(x));
[imdsTrain,imdsValidation] = splitEachLabel(imds,0.8,.2,'randomized');

% classWeights = 1./countcats(imdsTrain.Labels);
% classWeights = classWeights'/mean(classWeights);

lgraph_1 = getNet();
% lgraph_1 = (load('/data/nil-bluearc/shimony/jjlee/FocalEpilepsy/Patrick/epilepsy/epinet2.mat').epinet);

miniBatchSize = 4;
valFrequency = floor((numel(imdsTrain.Labels)/(miniBatchSize)));

options = trainingOptions('adam', ...
    'MiniBatchSize',miniBatchSize, ...
    'MaxEpochs',2, ...
    'InitialLearnRate',.0001, ...
    'Shuffle','every-epoch', ...
    'ValidationData',imdsValidation, ...
    'ValidationFrequency',valFrequency, ...
    'ValidationPatience',3, ...
    'Verbose',true, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropFactor',0.5, ...
    'LearnRateDropPeriod',1, ...
    'CheckpointPath',pwd, ...
    'Plots','training-progress');  
trainedNet = trainNetwork(imdsTrain,lgraph_1,options);


function stop = stopIfAccuracyNotImproving(info,N)
stop = false;
persistent bestValAccuracy
persistent valLag
if info.State == "start"
    bestValAccuracy = 0;
    valLag = 0;    
elseif ~isempty(info.ValidationLoss)
    if info.ValidationAccuracy > bestValAccuracy
        valLag = 0;
        bestValAccuracy = info.ValidationAccuracy;
    else
        valLag = valLag + 1;
    end
    if valLag >= N
        stop = true;
    end    
end
end


function [dataOut,info] = classificationAugmentationPipeline(dataIn,info)

dataOut = cell([size(dataIn,1),2]);

for idx = 1:size(dataIn,1)
    temp = dataIn{idx};    
%     % Randomized Gaussian blur
%     temp = imgaussfilt(temp,1.5*rand);    
%     % Add salt and pepper noise
%     temp = imnoise(temp,'salt & pepper');
    
    tform = randomAffine3d('Rotation',[-10,10], ...
    'XTranslation',[-5 5], ...
    'Scale',[.8 1.2], ...
    'Shear',[-5 5], ...
    'ZTranslation',[-5 5],...
    'YTranslation',[-5 5]);
    % Add randomized rotation and scale
    outputView = affineOutputView(size(temp),tform);
    temp = imwarp(temp,tform,'OutputView',outputView);
    
    % Form second column expected by trainNetwork which is expected response,
    % the categorical label in this case
    dataOut(idx,:) = {temp,info.Label(idx)};
end

end

function lgraph = getNet()
lgraph = layerGraph();
tempLayers = image3dInputLayer([48 64 48 180],"Name","image3dinput","Normalization","none");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    convolution3dLayer([3 3 3],40,"Name","conv3d_2","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    batchNormalizationLayer("Name","batchnorm_2")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    convolution3dLayer([7 7 7],40,"Name","conv3d_1","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    batchNormalizationLayer("Name","batchnorm_1")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = concatenationLayer(4,2,"Name","concat_12");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = globalAveragePooling3dLayer("Name","gapool3d_4");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = leakyReluLayer(0.01,"Name","leakyrelu_1_1");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = maxPooling3dLayer([2 2 2],"Name","maxpool3d_1_1","Padding","same","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = averagePooling3dLayer([2 2 2],"Name","avgpool3d_4","Padding","same","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = concatenationLayer(4,2,"Name","concat_7");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    batchNormalizationLayer("Name","batchnorm_3")
    leakyReluLayer(0.01,"Name","leakyrelu_1")
    convolution3dLayer([1 1 1],96,"Name","conv3d_3","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = concatenationLayer(4,2,"Name","concat_1");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    batchNormalizationLayer("Name","batchnorm_4")
    leakyReluLayer(0.01,"Name","leakyrelu_2")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    convolution3dLayer([5 5 5],64,"Name","conv3d_5","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    batchNormalizationLayer("Name","batchnorm_6")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    convolution3dLayer([3 3 3],64,"Name","conv3d_4","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    batchNormalizationLayer("Name","batchnorm_5")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = concatenationLayer(4,3,"Name","concat_2");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    leakyReluLayer(0.01,"Name","leakyrelu_5")
    convolution3dLayer([1 1 1],128,"Name","conv3d_6","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = globalAveragePooling3dLayer("Name","gapool3d_1");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = maxPooling3dLayer([2 2 2],"Name","maxpool3d_1","Padding","same","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = averagePooling3dLayer([2 2 2],"Name","avgpool3d_1","Padding","same","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = concatenationLayer(4,2,"Name","concat_8");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    batchNormalizationLayer("Name","batchnorm_7")
    leakyReluLayer(0.01,"Name","leakyrelu_7")
    convolution3dLayer([1 1 1],128,"Name","conv3d_7","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = concatenationLayer(4,2,"Name","concat_4");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    batchNormalizationLayer("Name","batchnorm_8")
    leakyReluLayer(0.01,"Name","leakyrelu_9")
    convolution3dLayer([3 3 3],64,"Name","conv3d_8","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    batchNormalizationLayer("Name","batchnorm_9")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = concatenationLayer(4,2,"Name","concat_5");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    leakyReluLayer(0.01,"Name","leakyrelu_11")
    convolution3dLayer([1 1 1],128,"Name","conv3d_9","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = averagePooling3dLayer([2 2 2],"Name","avgpool3d_2","Padding","same","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = maxPooling3dLayer([2 2 2],"Name","maxpool3d_2","Padding","same","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = concatenationLayer(4,2,"Name","concat_9");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    batchNormalizationLayer("Name","batchnorm_10")
    leakyReluLayer(0.01,"Name","leakyrelu_3")
    convolution3dLayer([1 1 1],128,"Name","conv3d_10","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = concatenationLayer(4,2,"Name","concat_3");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    batchNormalizationLayer("Name","batchnorm_12")
    leakyReluLayer(0.01,"Name","leakyrelu_4")
    convolution3dLayer([3 3 3],64,"Name","conv3d_11","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    batchNormalizationLayer("Name","batchnorm_11")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = globalAveragePooling3dLayer("Name","gapool3d_2");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    concatenationLayer(4,2,"Name","concat_6")
    leakyReluLayer(0.01,"Name","leakyrelu_12")
    convolution3dLayer([3 3 3],256,"Name","conv3d_12","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = maxPooling3dLayer([2 2 2],"Name","maxpool3d","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = averagePooling3dLayer([2 2 2],"Name","avgpool3d_5","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    concatenationLayer(4,2,"Name","concat_11")
    batchNormalizationLayer("Name","batchnorm_13")
    leakyReluLayer(0.01,"Name","leakyrelu")
    convolution3dLayer([3 3 3],256,"Name","conv3d_13","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = maxPooling3dLayer([2 2 2],"Name","maxpool3d_3");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = averagePooling3dLayer([2 2 2],"Name","avgpool3d_3");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    concatenationLayer(4,2,"Name","concat_10")
    batchNormalizationLayer("Name","batchnorm_14")
    globalAveragePooling3dLayer("Name","gapool3d_3")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    concatenationLayer(4,4,"Name","concat")
    dropoutLayer(0.1,"Name","dropout")
    fullyConnectedLayer(2,"Name","fc","BiasL2Factor",1)
    softmaxLayer("Name","softmax")
    classificationLayer("Name","classoutput")];
lgraph = addLayers(lgraph,tempLayers);
lgraph = connectLayers(lgraph,"image3dinput","conv3d_2");
lgraph = connectLayers(lgraph,"image3dinput","conv3d_1");
lgraph = connectLayers(lgraph,"batchnorm_2","concat_12/in2");
lgraph = connectLayers(lgraph,"batchnorm_1","concat_12/in1");
lgraph = connectLayers(lgraph,"concat_12","gapool3d_4");
lgraph = connectLayers(lgraph,"concat_12","leakyrelu_1_1");
lgraph = connectLayers(lgraph,"gapool3d_4","concat/in4");
lgraph = connectLayers(lgraph,"leakyrelu_1_1","maxpool3d_1_1");
lgraph = connectLayers(lgraph,"leakyrelu_1_1","avgpool3d_4");
lgraph = connectLayers(lgraph,"maxpool3d_1_1","concat_7/in2");
lgraph = connectLayers(lgraph,"avgpool3d_4","concat_7/in1");
lgraph = connectLayers(lgraph,"concat_7","batchnorm_3");
lgraph = connectLayers(lgraph,"concat_7","concat_1/in1");
lgraph = connectLayers(lgraph,"conv3d_3","concat_1/in2");
lgraph = connectLayers(lgraph,"concat_1","batchnorm_4");
lgraph = connectLayers(lgraph,"concat_1","concat_2/in1");
lgraph = connectLayers(lgraph,"leakyrelu_2","conv3d_5");
lgraph = connectLayers(lgraph,"leakyrelu_2","conv3d_4");
lgraph = connectLayers(lgraph,"batchnorm_6","concat_2/in3");
lgraph = connectLayers(lgraph,"batchnorm_5","concat_2/in2");
lgraph = connectLayers(lgraph,"concat_2","leakyrelu_5");
lgraph = connectLayers(lgraph,"concat_2","gapool3d_1");
lgraph = connectLayers(lgraph,"gapool3d_1","concat/in1");
lgraph = connectLayers(lgraph,"conv3d_6","maxpool3d_1");
lgraph = connectLayers(lgraph,"conv3d_6","avgpool3d_1");
lgraph = connectLayers(lgraph,"maxpool3d_1","concat_8/in1");
lgraph = connectLayers(lgraph,"avgpool3d_1","concat_8/in2");
lgraph = connectLayers(lgraph,"concat_8","batchnorm_7");
lgraph = connectLayers(lgraph,"concat_8","concat_4/in2");
lgraph = connectLayers(lgraph,"conv3d_7","concat_4/in1");
lgraph = connectLayers(lgraph,"concat_4","batchnorm_8");
lgraph = connectLayers(lgraph,"concat_4","concat_5/in2");
lgraph = connectLayers(lgraph,"batchnorm_9","concat_5/in1");
lgraph = connectLayers(lgraph,"concat_5","leakyrelu_11");
lgraph = connectLayers(lgraph,"concat_5","gapool3d_2");
lgraph = connectLayers(lgraph,"conv3d_9","avgpool3d_2");
lgraph = connectLayers(lgraph,"conv3d_9","maxpool3d_2");
lgraph = connectLayers(lgraph,"avgpool3d_2","concat_9/in2");
lgraph = connectLayers(lgraph,"maxpool3d_2","concat_9/in1");
lgraph = connectLayers(lgraph,"concat_9","batchnorm_10");
lgraph = connectLayers(lgraph,"concat_9","concat_3/in2");
lgraph = connectLayers(lgraph,"conv3d_10","concat_3/in1");
lgraph = connectLayers(lgraph,"concat_3","batchnorm_12");
lgraph = connectLayers(lgraph,"concat_3","concat_6/in1");
lgraph = connectLayers(lgraph,"gapool3d_2","concat/in2");
lgraph = connectLayers(lgraph,"batchnorm_11","concat_6/in2");
lgraph = connectLayers(lgraph,"conv3d_12","maxpool3d");
lgraph = connectLayers(lgraph,"conv3d_12","avgpool3d_5");
lgraph = connectLayers(lgraph,"maxpool3d","concat_11/in2");
lgraph = connectLayers(lgraph,"avgpool3d_5","concat_11/in1");
lgraph = connectLayers(lgraph,"conv3d_13","maxpool3d_3");
lgraph = connectLayers(lgraph,"conv3d_13","avgpool3d_3");
lgraph = connectLayers(lgraph,"maxpool3d_3","concat_10/in2");
lgraph = connectLayers(lgraph,"avgpool3d_3","concat_10/in1");
lgraph = connectLayers(lgraph,"gapool3d_3","concat/in3");
end
