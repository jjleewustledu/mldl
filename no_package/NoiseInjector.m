classdef NoiseInjector
	%% NOISEINJECTOR  

	%  $Revision$
 	%  was created 06-Jan-2020 19:20:36 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mldl/src/+mldl.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64. 
 	
    methods (Static)   
        
        %% NOISE-GENERATING TRANSFORMATIONS, INSPIRED BY COMMON GENETIC MUTATIONS
        
        function b = affine1D(b, randn_)
            %% for 1D b, pulls back b(t) := f^\ast b(t) = b(f(t)) using affine f, changing temporal scales

            b0 = b;
            try
                N = length(b);
                t = 0:(N - 1); % row
                r = 4*abs(randn_);
                u = r*t;
                if r < 1               
                    b = makima(t, b, u);
                end
                if r > 1
                    N1 = ceil(r*N);
                    t1 = 0:(N1 - 1);
                    b1 = repmat(b, [1 ceil(r)]);
                    b = makima(t1, b1(1:N1), u);
                end
                b = rand()*b/max(abs(b));
            catch ME
                disp(ME)
                struct2str(ME.stack)
                warning('mldl:RuntimeWarning', 'NoiseInjector.affine1D.b -> %s', mat2str(b))
                b = b0;
            end
        end     
        function b = circshift(b, adim, randn_)
            %% for 1D-4D b, circshift along dimension adim

            b = circshift(b, round(randn_*size(b, adim)), adim);
        end 
        function b = flip1D(b)
            b = flip(b);
        end
        function b = insert1D(b, c, t0)
            %% is deterministic for use with select1D()
            
            tf = min(length(b), t0 - 1 + length(c));
            b(t0:tf) = c;
        end
        function b = points1D(b, rand_)
            %% mutates a random subset of points

            N = length(b);
            N1 = ceil(rand_*N);
            indices = ceil(rand(1, N1)*N);
            b(indices) = (-1).^randi(2, 1, N1).*rand(1, N1);
        end
        function [b1,t0,Nt] = select1D(b, rand0_, rand1_, rand2_)
            %% For 1D b, returns a subset of b, the index of the first subset element and the length of the subset;
            %  use with insert1D().  Return b unchanged with prob ~ 0.5.

            if rand0_ > 0.5
                b1 = b;
                t0 = 1;
                Nt = length(b);
                return
            end
            N = length(b);
            tf = min(ceil((0.5 + rand1_)*N), N);
            t0 = ceil(rand2_*tf);
            b1 = b(t0:tf);
            Nt = tf - t0 + 1;
        end
        function b = shuffle1D(b, rand_)
            %% randomly selects an index, then swaps the order of 1:index and index+1:end

            N = length(b);
            idx = ceil(rand_*N);
            b_ = zeros(size(b));
            b_(1:idx) = b(N-idx+1:N);
            b_(idx+1:N) = b(1:N-idx);
            b = b_;
        end
        
        %% DISTRIBUTIONS, WALKS & FLIGHTS
        
        function b  = normal1D(b0, mix)
            %% samples the normal distribution
           
            Nt = length(b0);
            b = randn(1, Nt);
            b = rand()*b/max(abs(b));
            b = (1 - mix)*b0 + mix*b;
        end
        function b  = power1D(b0, mix, rand_)
            %% samples a power law
            %  https://math.stackexchange.com/questions/52869/numerical-approximation-of-levy-flight
            
            Nt = length(b0);
            alpha_ = 1 + 2*rand_;
            xmin = 1e-3;
            b = xmin*(randn(1, Nt)).^(-1/alpha_);
            b = (-1).^randi(2, 1, Nt).*b;
            b = rand()*real(b)/max(abs(b));            
            b = (1 - mix)*b0 + mix*b;
        end
        function b  = Brownian_walk1D(b0, mix)
            Nt = length(b0);
            b = cumsum(randn(1, Nt));
            b = rand()*b/max(abs(b));         
            b = (1 - mix)*b0 + mix*b;
        end
        function b  = Levy_flight1D(b0, mix, rand_)
            %% https://math.stackexchange.com/questions/52869/numerical-approximation-of-levy-flight
            
            Nt = length(b0);
            alpha_ = 1 + 2*rand_;
            xmin = 1e-3;
            b = xmin*(rand(1, Nt)).^(-1/alpha_);
            b = (-1).^randi(2, 1, Nt).*b;
            b = cumsum(b);
            b = rand()*real(b)/max(abs(b));         
            b = (1 - mix)*b0 + mix*b;
        end
        
        %% UTILITIES         
        
        function pth = mask2mask_path(msk)
            pth = zeros(size(msk));
            p = 0;
            for k = 1:size(msk,3)
                for j = 1:size(msk,2)
                    for i = 1:size(msk,1)
                        if msk(i, j, k) > 0
                            p = p + 1;
                            pth(i, j, k) = p;
                        end
                    end
                end
            end
        end
        function coords = path_length2coords(msk, pth_len)
            p = 0;
            for k = 1:size(msk,3)
                for j = 1:size(msk,2)
                    for i = 1:size(msk,1)
                        if msk(i, j, k) > 0
                            p = p + 1;
                            if p == pth_len
                                coords = [i j k];
                                return
                            end
                        end
                    end
                end
            end            
        end
        function img = read_aparc_aseg_mask()
            %% returns single array, reshaped to [48 64 48] with NIfTI orderings
            
            %pth = fullfile(getenv('MLPDIR'), 'Reference_Images', '');
            %fqfn = fullfile(pth, 'N21_aparc+aseg_GMctx_on_711-2V_333_avg_zlt0.5_gAAmask_v1.4dfp.img');                        
            fqfn = NoiseInjector.APARC_ASEG_MASK;
            fid = fopen(fqfn, 'r');
            img = single(fread(fid,'float'));
            fclose(fid);
            
            img = reshape(img, [48 64 48]);
            img = flip(img, 2);
        end 
        function b = saturate_signal(b)
            b(b >  1) =  1;
            b(b < -1) = -1;
        end
    end
    
	methods		  
 		function this = NoiseInjector(bold, varargin)
 			%% NOISEINJECTOR
            %  @param bold is numeric, size(bold) ~ [48 64 48 Nt]; its internal representation is double.
            %  @param model is char:  'affine', 'Brownian', 'flip', 'Levy', 'normal', 'points', 'power', 'shuffle' or
            %               is cell of char.  Default is this.DEFAULT_MODEL.
            %  @param focus_radius is numeric:  default 8.
            %  @param mix is in [0, 1] and determines variability amongst focus voxels.
            %  @param mix_process is in [0, 1] and determines mix of normal and stochastic process.

            ip = inputParser;
            addRequired( ip, 'bold', @(x) size(x,1) == 48 && size(x,2) == 64 && size(x,3) == 48)
            addParameter(ip, 'model', this.DEFAULT_MODEL, @(x) ischar(x) || iscell(x))
            addParameter(ip, 'focus_radius', 8, @isnumeric)
            addParameter(ip, 'mix', 0.2, @(x) isnumeric(x) && x < 1)
            addParameter(ip, 'mix_process', 0.2, @(x) isnumeric(x) && x < 1)
            parse(ip, bold, varargin{:})
            ipr = ip.Results;
    
            this.bold_ = double(ipr.bold);
            this.model_ = ipr.model;
            this.focus_radius_ = ipr.focus_radius;
            this.mix_ = ipr.mix;
            this.mix_process_ = ipr.mix_process;
            this.size_ = size(this.bold_);
            this.Nt_ = this.size_(4);
            [this.focus_,this.Nfocus_] = this.select_focus(); % 4D
        end
        
        function this = inject_noise_model(this, varargin)
            ip = inputParser;
            addOptional(ip, 'model', this.model_, @(x) ischar(x) || iscell(x))
            parse(ip, varargin{:})
            model = ip.Results.model;
            
            import NoiseInjector.* 
            b = this.bold_(this.focus_); % Nfocus*Nt x 1
            b = reshape(b, [this.Nfocus_, this.Nt_]); % Nfocus x Nt 
            if iscell(model)
                if size(model, 1) > size(model, 2)
                    model = model';
                end
                for m = model % row
                    this = this.inject_noise_model(m{1});
                end
                return
            end
            r1 = rand();
            r2 = rand();
            switch model
                case 'affine'
                    r = randn();
                    for vxl = 1:size(b,1)
                        r0 = rand();
                        r1 = this.mix_rand_(r1);
                        r2 = this.mix_rand_(r2);
                        [b1,t0] = this.select1D(b(vxl,:), r0, r1, r2); % 1 x Nt <= 1 x Nt
                        r = this.mix_randn_(r);
                        b1 = this.affine1D(b1, r);
                        b(vxl,:) = this.insert1D(b(vxl,:), b1, t0);
                    end
                case 'Brownian'
                    for vxl = 1:size(b,1)
                        r0 = rand();
                        r1 = this.mix_rand_(r1);
                        r2 = this.mix_rand_(r2);
                        [b1,t0] = this.select1D(b(vxl,:), r0, r1, r2); % 1 x Nt <= 1 x Nt
                        b1 = this.Brownian_walk1D(b1, this.mix_process_);
                        b(vxl,:) = this.insert1D(b(vxl,:), b1, t0);
                    end
                case 'flip'
                    for vxl = 1:size(b,1)
                        r0 = rand();
                        r1 = this.mix_rand_(r1);
                        r2 = this.mix_rand_(r2);
                        [b1,t0] = this.select1D(b(vxl,:), r0, r1, r2); % 1 x Nt <= 1 x Nt
                        b1 = this.flip1D(b1);
                        b(vxl,:) = this.insert1D(b(vxl,:), b1, t0);
                    end
                case 'Levy'
                    r = rand();
                    for vxl = 1:size(b,1)
                        r0 = rand();
                        r1 = this.mix_rand_(r1);
                        r2 = this.mix_rand_(r2);
                        [b1,t0] = this.select1D(b(vxl,:), r0, r1, r2); % 1 x Nt <= 1 x Nt                        
                        r = this.mix_rand_(r);
                        b1 = this.Levy_flight1D(b1, this.mix_process_, r);
                        b(vxl,:) = this.insert1D(b(vxl,:), b1, t0);
                    end
                case 'normal'
                    for vxl = 1:size(b,1)
                        r0 = rand();
                        r1 = this.mix_rand_(r1);
                        r2 = this.mix_rand_(r2);
                        [b1,t0] = this.select1D(b(vxl,:), r0, r1, r2); % 1 x Nt <= 1 x Nt
                        b1 = this.normal1D(b1, this.mix_process_);
                        b(vxl,:) = this.insert1D(b(vxl,:), b1, t0);
                    end
                case 'points'
                    r = rand();
                    for vxl = 1:size(b,1)
                        r0 = rand();
                        r1 = this.mix_rand_(r1);
                        r2 = this.mix_rand_(r2);
                        [b1,t0] = this.select1D(b(vxl,:), r0, r1, r2); % 1 x Nt <= 1 x Nt
                        r = this.mix_rand_(r);
                        b1 = this.points1D(b1, r);
                        b(vxl,:) = this.insert1D(b(vxl,:), b1, t0);
                    end
                case 'power'
                    r = rand();
                    for vxl = 1:size(b,1)
                        r0 = rand();
                        r1 = this.mix_rand_(r1);
                        r2 = this.mix_rand_(r2);
                        [b1,t0] = this.select1D(b(vxl,:), r0, r1, r2); % 1 x Nt <= 1 x Nt                        
                        r = this.mix_rand_(r);
                        b1 = this.power1D(b1, this.mix_process_, r);
                        b(vxl,:) = this.insert1D(b(vxl,:), b1, t0);
                    end
                case 'shuffle'
                    r = rand();
                    for vxl = 1:size(b,1)
                        r0 = rand();
                        r1 = this.mix_rand_(r1);
                        r2 = this.mix_rand_(r2);
                        [b1,t0] = this.select1D(b(vxl,:), r0, r1, r2); % 1 x Nt <= 1 x Nt
                        r = this.mix_rand_(r);
                        b1 = this.shuffle1D(b1, r);
                        b(vxl,:) = this.insert1D(b(vxl,:), b1, t0);
                    end
                otherwise
                    error('mldl:ValueError', 'this.model_->%s is not supported', this.model_)
            end
            this.bold_(this.focus_) = reshape(b, [this.Nfocus_*this.Nt_ 1]);
        end
        function r = mix_rand_(this, r)
            m = this.mix_;
            r = (1 - m + m*rand())*r;
        end
        function r = mix_randn_(this, r)
            m = this.mix_;
            r = (1 - m + m*randn())*r;
        end        
        function [focus,Nf] = select_focus(this)
            %% Select focus point randomly in 3D, then dilate with random radius < this.focus_radius_.
            %  @param this.bold_ must have mod(numel, 48*64*48) ~ 0.
            %  @return focus as logical image with focus voxels := true.
            %  @return Nf is the number of focus voxels per time frame.
            
            this.aparc_aseg_mask_ = this.read_aparc_aseg_mask();
            msk = this.aparc_aseg_mask_;
            pth_len = ceil(sum(sum(sum(msk)))*rand());
            focus = double(this.mask2mask_path(msk) == pth_len);
            rad = max(ceil(this.focus_radius_*(1 + 0.2*randn())), 0.5*this.focus_radius_);
            se = strel('sphere', rad);
            focus = imdilate(focus, se);
            z = zeros(this.size_);
            for t = 1:this.size_(4)
                z(:,:,:,t) = focus .* msk;
            end
            Nf = sum(sum(sum(z(:,:,:,1))));
            focus = logical(z);
        end        
    end
    
    properties (Constant)
        DEFAULT_MODEL = 'Levy'
        MODELS = {'affine', 'Brownian', 'flip', 'Levy', 'normal', 'points', 'power', 'shuffle'}
        APARC_ASEG_MASK = '/Users/jjlee/MATLAB-Drive/mldl/no_package/N21_aparc+aseg_GMctx_on_711-2V_333_avg_zlt0.5_gAAmask_v1.4dfp.img'
    end
    
	properties
        aparc_aseg_mask_
 		bold_
        focus_
        focus_radius_
        mix_
        mix_process_
        model_
        Nfocus_
        Nt_
        size_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end
