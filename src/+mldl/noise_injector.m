function bold = noise_injector(varargin)
    %% NOISE_INJECTOR accepts BOLD time-series data and returns that data injected with modelled noise.
    %  The size of the BOLD data is preserved.   noise_injector may be applied repeatedly.
    %
    %  @param bold is numeric, size(bold) ~ [48 64 48 Nt]; its internal representation is double.
    %  @param model is char:  'default', 'affine', 'Brownian', 'flip', 'normal', 'points', 'shuffle' or
    %               is cell of model specifications.
    %  @param focus_radius is numeric:  default 8.
    %  @param mix is in [0, 1] and determines variability in focus voxels.
    %
    %  E.g., bold = noise_injector(bold, 'normal')
    %  E.g., bold = noise_injector(bold, {'Brownian' 'affine'})
    
    setenv('MLPDIR', '~jjlee/MATLAB-Drive/mlperceptron/data')
    NI = mldl.NoiseInjector(varargin{:});
    NI = NI.inject_noise_model();
    bold = NI.bold_;
end
   