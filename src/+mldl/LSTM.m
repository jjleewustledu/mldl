classdef LSTM 
	%% LSTM  

	%  $Revision$
 	%  was created 05-Nov-2019 13:53:56 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
    
 	%% It was developed on Matlab 9.7.0.1216025 (R2019b) Update 1 for MACI64.  
    %  Copyright 2019 Patrick Luckett, John Joowon Lee.
 	
	properties (Dependent)
 		net
    end
    
    methods (Static)
        function net = createPatricksLstm3(input, output)
            assert(isnumeric(input))
            assert(isnumeric(output))
            this = mldl.LSTM(input, output);
            net = this.trainNet(input, output, this.lgraph_);
        end
    end

	methods
        
        %% GET
        
        function g = get.net(this)
            g = this.net_;
        end
        
        %% From Patrick Luckett
        
        function this = trainNet(this, input, output)
            %% Will need to set up your training data here, can be tricky with regression. 
            %  Matlab has some decent examples where they use cell arrays
            
            assert(size(output,1) > 1850)
            options = trainingOptions('adam', ...
                'MaxEpochs',5000, ...
                'GradientThreshold',1, ...
                'InitialLearnRate',0.001, ...
                'LearnRateSchedule','piecewise', ...
                'ValidationFrequency',10, ...
                'ValidationPatience',5, ...
                'ValidationData',{input(:,:)',output(1850:end,:)'}, ...
                'LearnRateDropPeriod',25, ...
                'LearnRateDropFactor',0.9, ...
                'plots','training-progress');
            this.net_ = trainNetwork(input,outout,this.lgraph_,options);
            
        end        
        function lgraph = lstm3(~, Nnodes)
            lgraph = layerGraph();
            tempLayers = sequenceInputLayer(1,"Name","sequence","Normalization","zerocenter");
            lgraph = addLayers(lgraph,tempLayers);
            tempLayers = bilstmLayer(Nnodes,"Name","bilstm_1","BiasL2Factor",1);
            lgraph = addLayers(lgraph,tempLayers);
            tempLayers = bilstmLayer(Nnodes,"Name","bilstm_2","BiasL2Factor",1);
            lgraph = addLayers(lgraph,tempLayers);
            tempLayers = bilstmLayer(Nnodes,"Name","bilstm_3","BiasL2Factor",1);
            lgraph = addLayers(lgraph,tempLayers);
            tempLayers = [
                concatenationLayer(1,4,"Name","concat")
                fullyConnectedLayer(1,"Name","fc","BiasL2Factor",1)
                regressionLayer("Name","regressionoutput")];
            lgraph = addLayers(lgraph,tempLayers);
            lgraph = connectLayers(lgraph,"sequence","bilstm_1");
            lgraph = connectLayers(lgraph,"sequence","concat/in4");
            lgraph = connectLayers(lgraph,"bilstm_1","bilstm_2");
            lgraph = connectLayers(lgraph,"bilstm_1","concat/in3");
            lgraph = connectLayers(lgraph,"bilstm_2","bilstm_3");
            lgraph = connectLayers(lgraph,"bilstm_2","concat/in2");
            lgraph = connectLayers(lgraph,"bilstm_3","concat/in1");
        end        
        function lgraph = denselstm2(~, Nnodes)
            lgraph = layerGraph();
            tempLayers = sequenceInputLayer(1,"Name","sequence","Normalization","zerocenter");
            lgraph = addLayers(lgraph,tempLayers);
            tempLayers = bilstmLayer(Nnodes,"Name","bilstm_1","BiasL2Factor",1);
            lgraph = addLayers(lgraph,tempLayers);
            tempLayers = concatenationLayer(1,2,"Name","concat_1");
            lgraph = addLayers(lgraph,tempLayers);
            tempLayers = bilstmLayer(Nnodes,"Name","bilstm_2","BiasL2Factor",1);
            lgraph = addLayers(lgraph,tempLayers);
            tempLayers = [
                concatenationLayer(1,2,"Name","concat_2")
                fullyConnectedLayer(1,"Name","fc","BiasL2Factor",1)
                regressionLayer("Name","regressionoutput")];
            lgraph = addLayers(lgraph,tempLayers);
            lgraph = connectLayers(lgraph,"sequence","bilstm_1");
            lgraph = connectLayers(lgraph,"sequence","concat_1/in1");
            lgraph = connectLayers(lgraph,"bilstm_1","concat_1/in2");
            lgraph = connectLayers(lgraph,"concat_1","bilstm_2");
            lgraph = connectLayers(lgraph,"concat_1","concat_2/in1");
            lgraph = connectLayers(lgraph,"bilstm_2","concat_2/in2");
        end        
        function lgraph = denselstm3(~, Nnodes)
            lgraph = layerGraph();
            tempLayers = sequenceInputLayer(1,"Name","sequence","Normalization","zerocenter");
            lgraph = addLayers(lgraph,tempLayers);
            tempLayers = bilstmLayer(Nnodes,"Name","bilstm_1","BiasL2Factor",1);
            lgraph = addLayers(lgraph,tempLayers);
            tempLayers = concatenationLayer(1,2,"Name","concat_1");
            lgraph = addLayers(lgraph,tempLayers);
            tempLayers = bilstmLayer(Nnodes,"Name","bilstm_2","BiasL2Factor",1);
            lgraph = addLayers(lgraph,tempLayers);
            tempLayers = concatenationLayer(1,2,"Name","concat_2");
            lgraph = addLayers(lgraph,tempLayers);
            tempLayers = bilstmLayer(Nnodes,"Name","bilstm_3","BiasL2Factor",1);
            lgraph = addLayers(lgraph,tempLayers);
            tempLayers = [
                concatenationLayer(1,2,"Name","concat_3")
                fullyConnectedLayer(1,"Name","fc","BiasL2Factor",1)
                regressionLayer("Name","regressionoutput")];
            lgraph = addLayers(lgraph,tempLayers);
            lgraph = connectLayers(lgraph,"sequence","bilstm_1");
            lgraph = connectLayers(lgraph,"sequence","concat_1/in1");
            lgraph = connectLayers(lgraph,"bilstm_1","concat_1/in2");
            lgraph = connectLayers(lgraph,"concat_1","bilstm_2");
            lgraph = connectLayers(lgraph,"concat_1","concat_2/in1");
            lgraph = connectLayers(lgraph,"bilstm_2","concat_2/in2");
            lgraph = connectLayers(lgraph,"concat_2","bilstm_3");
            lgraph = connectLayers(lgraph,"concat_2","concat_3/in1");
            lgraph = connectLayers(lgraph,"bilstm_3","concat_3/in2");
        end
		  
        %%
        
 		function this = LSTM(varargin)
 			%% LSTM
 			%  @param optional input is numeric.
            %  @param optional output is numeric.
            %  @param lstm is an nnet.cnn.LayerGraph, e.g., this.lstem3(32), this.denselstm2(32), this.denselstm3(32).
 			
            ip = inputParser;
            addOptional( ip, 'input', [], @isnumeric)
            addOptional( ip, 'output', [], @isnumeric)
            addParameter(ip, 'lstm', [])
            parse(ip, varargin{:})
            ipr = ip.Results;            
            this.input_ = ipr.input;
            this.output_ = ipr.output;
            this.lgraph_ = ipr.lstm;
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        input_
        output_
        lgraph_
        net_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

