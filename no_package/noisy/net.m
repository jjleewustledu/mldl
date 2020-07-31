
% parfor i = 1:64330
%     i
%     a = ['/data/ances2/NoiseID/mask/',imdsTrain.Files{i}(27:end)];
%     b = ['/data/ances2/NoiseID/bold/',imdsTrain.Files{i}(27:end)];
%     if(~exist(a,'file'))
%         delete(b);
%     end
% end
% return

% gm_mask = load('/scratch/luckettp/gm_mask.mat').gm_mask';
% gm_mask = load('gm_mask.mat').gm_mask';

% d = dir('/scratch/jjlee/luckettp/NoiseIDV/bold/*.mat');
% d = dir('/data/ances2/NoiseIDV/bold/*.mat');
% parfor i = 1:length(d)
%     i
%     dat = load([d(i).folder,'/',d(i).name]).dat;
%     dat = reshape(dat,[147456, 180]);
%     dat(~gm_mask,:) = dat(~gm_mask,:)*0;
%     dat = reshape(dat,[48,64,48, 180]);
%     finish([d(i).folder,'/',d(i).name], dat);    
% end
% return
% d = dir('/scratch/jjlee/luckettp/NoiseID/bold/*.mat');
% d = dir('/data/ances2/NoiseID/bold/*.mat');
% parfor (i = 10001:length(d), 18)%length(d)
%     i
%     dat = load([d(i).folder,'/',d(i).name]).dat;
%     dat = reshape(dat,[147456, 180]);
%     dat(~gm_mask,:) = dat(~gm_mask,:)*0;
%     dat = reshape(dat,[48,64,48, 180]);
%     finish([d(i).folder,'/',d(i).name], dat);    
% end
% 
% 
% return

% imdsTrain = imageDatastore('/data/ances2/NoiseID/bold','FileExtensions','.mat', 'ReadFcn',@(x) matReadepi(x));
% pxds = pixelLabelDatastore('/data/ances2/NoiseID/mask',["zero","one"],[0,1],'FileExtensions','.mat', 'ReadFcn',@(x) matReadmask(x));
% pximds = pixelLabelImageDatastore(imdsTrain,pxds);
% pxval = pixelLabelImageDatastore(imdsTrain,pxds);
% lgraph_1 = getGraph();
% miniBatchSize = 8;
% valFrequency = floor((numel(imdsTrain.Files)/(miniBatchSize)));
% options = trainingOptions('adam', ...
%     'MiniBatchSize',miniBatchSize, ...
%     'MaxEpochs',1, ...
%     'InitialLearnRate',.001, ...
%     'Shuffle', 'every-epoch', ...
%     'Verbose',true, ...
%     'LearnRateSchedule','piecewise', ...
%     'LearnRateDropFactor',0.1, ...
%     'LearnRateDropPeriod',1, ...
%     'CheckpointPath',pwd);
% trainedNet = trainNetwork(pximds,lgraph_1,options);

% d = dir(['/data/ances2/NoiseID/mask/*.mat']);
% tmp = load([d(1).folder,'/',d(1).name]).dat;
% for i = 2:length(d)   
%     i
%     tmp = tmp + load([d(i).folder,'/',d(i).name]).dat;   
% end
% 
% return
imdsTrain = imageDatastore('/data/ances2/NoiseID/bold','FileExtensions','.mat', 'ReadFcn',@(x) matReadepi(x));
pxds = imageDatastore('/data/ances2/NoiseID/mask','FileExtensions','.mat', 'ReadFcn',@(x) matReadmask(x));
pximds = combine(imdsTrain,pxds);

% imdsTrain = imageDatastore('/data/ances2/NoiseID/bold','FileExtensions','.mat', 'ReadFcn',@(x) matReadepi(x));
% pxds = pixelLabelDatastore('/data/ances2/NoiseID/mask',["zero","one"],[0,1],'FileExtensions','.mat', 'ReadFcn',@(x) matReadmask(x));
% pximds = pixelLabelImageDatastore(imdsTrain,pxds);
% return
% imdsVal = imageDatastore('/data/ances2/NoiseIDV/bold','FileExtensions','.mat', 'ReadFcn',@(x) matReadepi(x));
% pxdsv = pixelLabelDatastore('/data/ances2/NoiseIDV/mask',["zero","one"],[0,1],'FileExtensions','.mat', 'ReadFcn',@(x) matReadmask(x));
% pxval = pixelLabelImageDatastore(imdsVal,pxdsv);
lgraph_1 = getGraph();
miniBatchSize = 8;
valFrequency = floor((numel(imdsTrain.Files)/(miniBatchSize)));

% trainedNet = layerGraph(load('net_checkpoint__22298__2020_02_09__08_19_50.mat').net);

options = trainingOptions('adam', ...
    'MiniBatchSize',miniBatchSize, ...
    'MaxEpochs',3, ...
    'InitialLearnRate',.0001, ...
    'Shuffle', 'every-epoch', ...
    'Verbose',true, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropFactor',0.1, ...
    'LearnRateDropPeriod',1, ...
    'CheckpointPath',pwd, ...
    'Plots', 'training-progress');
trainedNet = trainNetwork(pximds,lgraph_1,options);
% save('/scratch/luckettp/Epi/trainedNet.mat','trainedNet');

function finish(str,dat)
save(str,'dat');
end

function lgraph = getGraph()
lgraph = layerGraph();
tempLayers = [
    image3dInputLayer([48 64 48 180],"Name","image3dinput","Normalization","none")
    convolution3dLayer([7 7 7],64,"Name","conv3d_1","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    batchNormalizationLayer("Name","batchnorm_1")
    leakyReluLayer(0.01,"Name","leakyrelu_1")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = maxPooling3dLayer([2 2 2],"Name","maxpool3d_1","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = averagePooling3dLayer([2 2 2],"Name","avgpool3d_1","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    concatenationLayer(4,2,"Name","concat_2")
    convolution3dLayer([3 3 3],64,"Name","conv3d_2","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    batchNormalizationLayer("Name","batchnorm_2")
    leakyReluLayer(0.01,"Name","leakyrelu_2")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = maxPooling3dLayer([2 2 2],"Name","maxpool3d_2","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = averagePooling3dLayer([2 2 2],"Name","avgpool3d_2","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    concatenationLayer(4,2,"Name","concat_4")
    convolution3dLayer([3 3 3],64,"Name","conv3d_3","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    batchNormalizationLayer("Name","batchnorm_3")
    leakyReluLayer(0.01,"Name","leakyrelu_3")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = averagePooling3dLayer([2 2 2],"Name","avgpool3d_3","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = maxPooling3dLayer([2 2 2],"Name","maxpool3d_3","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    concatenationLayer(4,2,"Name","concat_5")
    convolution3dLayer([3 3 3],64,"Name","conv3d_4","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    batchNormalizationLayer("Name","batchnorm_4")
    leakyReluLayer(0.01,"Name","leakyrelu_4")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = dropoutLayer(0.1,"Name","dropout_1");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = averagePooling3dLayer([2 2 2],"Name","avgpool3d_4","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = maxPooling3dLayer([2 2 2],"Name","maxpool3d_4","Stride",[2 2 2]);
lgraph = addLayers(lgraph,tempLayers);
tempLayers = concatenationLayer(4,2,"Name","concat_8");
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    convolution3dLayer([3 3 3],128,"Name","conv3d_5","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    batchNormalizationLayer("Name","batchnorm_5")
    leakyReluLayer(0.01,"Name","leakyrelu_5")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    convolution3dLayer([1 1 1],128,"Name","conv3d_11","BiasL2Factor",1,"Padding","same")
    batchNormalizationLayer("Name","batchnorm_10")
    leakyReluLayer(0.01,"Name","leakyrelu_14")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    concatenationLayer(4,2,"Name","concat_9")
    dropoutLayer(0.1,"Name","dropout_2")
    transposedConv3dLayer([2 2 2],128,"Name","transposed-conv3d_1","BiasL2Factor",1,"Stride",[2 2 2],"WeightsInitializer","he")
    leakyReluLayer(0.01,"Name","leakyrelu_6")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    concatenationLayer(4,2,"Name","concat_7")
    convolution3dLayer([3 3 3],128,"Name","conv3d_6","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    batchNormalizationLayer("Name","batchnorm_6")
    leakyReluLayer(0.01,"Name","leakyrelu_7")
    transposedConv3dLayer([2 2 2],128,"Name","transposed-conv3d_2","BiasL2Factor",1,"Stride",[2 2 2],"WeightsInitializer","he")
    leakyReluLayer(0.01,"Name","leakyrelu_8")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    concatenationLayer(4,2,"Name","concat_6")
    convolution3dLayer([3 3 3],64,"Name","conv3d_7","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    batchNormalizationLayer("Name","batchnorm_7")
    leakyReluLayer(0.01,"Name","leakyrelu_9")
    transposedConv3dLayer([2 2 2],64,"Name","transposed-conv3d_3","BiasL2Factor",1,"Stride",[2 2 2],"WeightsInitializer","he")
    leakyReluLayer(0.01,"Name","leakyrelu_10")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    concatenationLayer(4,2,"Name","concat_3")
    convolution3dLayer([3 3 3],64,"Name","conv3d_8","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    batchNormalizationLayer("Name","batchnorm_8")
    leakyReluLayer(0.01,"Name","leakyrelu_11")
    transposedConv3dLayer([3 3 3],64,"Name","transposed-conv3d_4","BiasL2Factor",1,"Cropping",[1 1 1;0 0 0],"Stride",[2 2 2],"WeightsInitializer","he")
    leakyReluLayer(0.01,"Name","leakyrelu_12")];
lgraph = addLayers(lgraph,tempLayers);
tempLayers = [
    concatenationLayer(4,2,"Name","concat_1")
    convolution3dLayer([3 3 3],64,"Name","conv3d_9","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    batchNormalizationLayer("Name","batchnorm_9")
    leakyReluLayer(0.01,"Name","leakyrelu_13")
    convolution3dLayer([1 1 1],1,"Name","conv3d_10","BiasL2Factor",1,"Padding","same","WeightsInitializer","he")
    
%     fullyConnectedLayer([48,64,48],"Name","fc")
%     softmaxLayer("Name","Softmax-Layer")
    regressionLayer("Name","reg");]%tverskyPixelClassificationLayer('tversky',0.3,0.7)];%dicePixelClassificationLayer("Name","Segmentation-Layer")];
lgraph = addLayers(lgraph,tempLayers);
lgraph = connectLayers(lgraph,"leakyrelu_1","maxpool3d_1");
lgraph = connectLayers(lgraph,"leakyrelu_1","avgpool3d_1");
lgraph = connectLayers(lgraph,"leakyrelu_1","concat_1/in1");
lgraph = connectLayers(lgraph,"maxpool3d_1","concat_2/in2");
lgraph = connectLayers(lgraph,"avgpool3d_1","concat_2/in1");
lgraph = connectLayers(lgraph,"leakyrelu_2","maxpool3d_2");
lgraph = connectLayers(lgraph,"leakyrelu_2","avgpool3d_2");
lgraph = connectLayers(lgraph,"leakyrelu_2","concat_3/in1");
lgraph = connectLayers(lgraph,"maxpool3d_2","concat_4/in1");
lgraph = connectLayers(lgraph,"avgpool3d_2","concat_4/in2");
lgraph = connectLayers(lgraph,"leakyrelu_3","avgpool3d_3");
lgraph = connectLayers(lgraph,"leakyrelu_3","maxpool3d_3");
lgraph = connectLayers(lgraph,"leakyrelu_3","concat_6/in1");
lgraph = connectLayers(lgraph,"avgpool3d_3","concat_5/in1");
lgraph = connectLayers(lgraph,"maxpool3d_3","concat_5/in2");
lgraph = connectLayers(lgraph,"leakyrelu_4","dropout_1");
lgraph = connectLayers(lgraph,"leakyrelu_4","concat_7/in1");
lgraph = connectLayers(lgraph,"dropout_1","avgpool3d_4");
lgraph = connectLayers(lgraph,"dropout_1","maxpool3d_4");
lgraph = connectLayers(lgraph,"avgpool3d_4","concat_8/in2");
lgraph = connectLayers(lgraph,"maxpool3d_4","concat_8/in1");
lgraph = connectLayers(lgraph,"concat_8","conv3d_5");
lgraph = connectLayers(lgraph,"concat_8","conv3d_11");
lgraph = connectLayers(lgraph,"leakyrelu_5","concat_9/in2");
lgraph = connectLayers(lgraph,"leakyrelu_14","concat_9/in1");
lgraph = connectLayers(lgraph,"leakyrelu_6","concat_7/in2");
lgraph = connectLayers(lgraph,"leakyrelu_8","concat_6/in2");
lgraph = connectLayers(lgraph,"leakyrelu_10","concat_3/in2");
lgraph = connectLayers(lgraph,"leakyrelu_12","concat_1/in2");
end
