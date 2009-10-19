% Random Variable Object - GAMMA
%
% Syntax:
%   R = rv.gamma
%   R = rv.gamma(shape,inverseScale)

classdef gamma < rv.rv
    properties
        shape
        inverseScale
    end
    
    properties (Hidden = true, Dependent = true)
        nDimensions
        isPlottable
        isValid
        plotLimits
        mean
        variance
    end 

    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % The Constructor %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function R = gamma(varargin)
            switch nargin
                case 0
                    % Supply the default object
                case 2
                    % R = prt.rv.gamma(shape,inverseScale)
                    R.shape = varargin{1};
                    R.inverseScale = varargin{2};
                otherwise
                    error('Invalide Number of input arguments')
            end % switch nargin
        end % function prt.rv.gamma
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Set methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function R = set.shape(R,shapeNum)
            % Limit the options for the covariance structure
            if shapeNum <= 0
                error('shape property must be positive.');
            end
            R.shape = shapeNum;
        end % function set.covarianceStructure
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function R = set.inverseScale(R,invScaleNum)
            if invScaleNum <= 0
                error('inverseScale property must be positive.');
            end
            R.inverseScale = invScaleNum;
            
        end % function set.mean
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Actually useful methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function R = mle(R,X)
            if size(X,2) > 1
                error('Dimensionality must be equal to 1.')
            end
            
            % initialize
            mu = mean(X); %#ok
            muLog = mean(log(X)); %#ok
            a = 0.5/(log(mu) - muLog);

            % Iterate to find a see
            % http://research.microsoft.com/users/Cambridge/minka/papers/minka-gamma.pdf
            convergnceChangeThreshold = 0.001;
            maxIterations = 50;
            oldA = a;
            for iter = 1:maxIterations
                a = 1/(1/a + (muLog - log(mu) + log(a) - psi(a))/ (a^2*(1/a - psi(a))));
                if abs(a-oldA) < convergnceChangeThreshold
                    break
                else
                    oldA = a;
                end
            end
            
            R.shape = a;
            R.inverseScale = a/mu;
        end % function mle
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function vals = pdf(R,X)
            assert(R.isValid,'PDF cannot be evaluated because the prt.rv.gamma object is not yet valid.')
            assert(size(X,2) == R.nDimensions,'Incorrect dimensionality for prt.rv.gamma object.')
            
            vals = exp(logPdf(R,X));
        end % function pdf
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function vals = logPdf(R,X)
            assert(R.isValid,'LOGPDF cannot be evaluated be prt.rv.gamma object is not yet valid.')
            assert(size(X,2) == R.nDimensions,'Incorrect dimensionality for prt.rv.gamma object.')            
            %vals = prt.rv.mvnLogPdf(X,R.mean,R.covariance);
            
            vals = R.shape*log(R.inverseScale) + (R.shape-1)*log(X) - gammaln(R.shape) - X*R.inverseScale;
        end % function pdf
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function vals = cdf(R,X)
            assert(R.isValid,'CDF cannot be evaluated be prt.rv.mvn object is not yet valid.')
            assert(size(X,2) == R.nDimensions,'Incorrect dimensionality for prt.rv.mvt object.')            
            vals = gamcdf(X,R.shape,R.inverseScale);
        end % function cdf
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function vals = draw(R,N)
            vals = gamrnd(R.shape,1./R.inverseScale,N);
        end % function draw
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = kld(R1,R2)
            if isa(R2,'prt.rv.gamma')
                val = gammaKLD(1./R1.inverseScale,R1.shape,1./R2.inverseScale,R2.shape);
            else
                error('gamma:kld','Kullback Liebler divergence can only be calculated between similar prt.rv objects. This may be updated in a future relesase.')
            end
        end % function kld
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = get.isValid(R)
            val = ~isempty(R.inverseScale) && ~isempty(R.shape);
        end % function get.isValid
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = get.isPlottable(R)
            val = ~isempty(R.nDimensions) && R.nDimensions < 4 && R.isValid;
        end % function get.isPlottable
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = get.mean(R)
            val = R.shape/R.inverseScale;
        end % function get.mean
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = get.variance(R)
            val = R.shape/(R.inverseScale)^2;
        end % function get.mean
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = get.nDimensions(R)
            if ~isempty(R.inverseScale)
                val = 1;
            elseif ~isempty(R.shape)
                val = 1;
            else
                val = [];
            end
        end % function get.nDimensions
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = get.plotLimits(R)
            if R.isValid
                minX = max(min(R.mean, [], 1)' - 2*sqrt(diag(R.variance)),0);
                maxX = max(R.mean, [], 1)' + 2*sqrt(diag(R.variance));
                
                val = zeros(1,2*R.nDimensions);
                val(1:2:R.nDimensions*2-1) = minX;
                val(2:2:R.nDimensions*2) = maxX;
            else
                error('gamma:plotLimits','Plotting limits can no be determined for this rv.gamma because it is not yet valid.')
            end
        end % function plotLimits
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function varargout = ezPdfPlot(R,varargin)
            
            if length(varargin) < 1
                plotLimits = R.plotLimits;
            else
                plotLimits = varargin{1};
            end
            
            [varargout{1:nargout}] = ezPdfPlot@prt.rv.rv(R,plotLimits);
        end % function ezPdfPlot
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function varargout = ezCdfPlot(R,varargin)
            if length(varargin) < 1
                plotLimits = R.plotLimits;
            else
                plotLimits = varargin{1};
            end
            
            [varargout{1:nargout}] = ezCdfPlot@prt.rv.rv(R,plotLimits);
        end % function ezCdfPlot
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function display(R)
            if numel(R) == 1
                display(struct('shape',R.shape,'inverseScale',R.inverseScale))
            else
                display@rv.rv(R);
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end % methods
end % classdef
