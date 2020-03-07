classdef (Abstract) IPracticalMethodology 
	%% IPRACTICALMETHODOLOGY presents an interface for best practices enumerated in 
    %  Goodfellow, Bengio, Courville.  Deep Learning.  (2016) ch. 11., pp. 409ff.

	%  $Revision$
 	%  was created 14-Dec-2019 16:34:05 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1247435 (R2019b) Update 2 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties (Abstract)
        errorTarget % <= 0.05
        aucTarget % >= 0.8
        prcTarget % See also:  bboxPrecisionRecall, evaluateDetectionPrecision   		
        
        algorithms
        regularizationHyperparameters        
 	end

	methods (Abstract)
        doInstrumenting(this)
        gatherData(this)
        adjustHyperparameters(this)
        estimateError(this)
        estimateAuc(this)
        estimatePrc(this)
        detectionConfidence(this)
        coverage(this)
        doTraining(this)
        doValidation(this)
        doTesting(this)
        fitDatum(this)
        fitTinyData(this)
        compareBackPropToNumericalDifferentiation(this)
        histogramActivations(this)
        histogramGradients(this)
        visualizeModelActions(this)
        visualizeMistakes(this)
  	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

