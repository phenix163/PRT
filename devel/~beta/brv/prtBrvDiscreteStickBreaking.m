classdef prtBrvDiscreteStickBreaking < prtBrvDiscrete
    
    properties (SetAccess = private)
        name = 'Discrete Stick Breaking Bayesian Random Variable';
        nameAbbreviation = 'BRVSB';
    end
    
    properties (SetAccess = protected)
        isSupervised = false;
        isCrossValidateValid = true;
    end
    
    properties
        model = prtBrvDiscreteStickBreakingHierarchy;
    end
    
    methods
        function obj = prtBrvDiscreteStickBreaking(varargin)
            if nargin < 1
                return
            end
            obj.model = prtBrvDiscreteStickBreakingHierarchy(varargin{1});
        end
        
        function y = conjugateVariationalAverageLogLikelihood(obj, x)
            y = sum(bsxfun(@times,x,psi(obj.model.lambda)-psi(sum(obj.model.lambda))),2);
        end
        
        function val = expectedLogMean(obj)
            val = psi(obj.model.lambda) - psi(sum(obj.model.lambda));
        end
        
        function [phiMat, priorObjs] = mixtureInitialize(objs, priorObjs, x)
            
            nStates = length(objs);
            
            minFrames = nStates*10;
            minFrameLength = 10;
            frameLength = floor(mean([floor(size(x,1)./minFrames),minFrameLength]));
            frameInds = buffer((1:size(x,1))',frameLength);
            
            nFrames = size(frameInds,2);
            frameClusteringX = zeros(nFrames,length(priorObjs(1).model.lambda));
            for iFrame = 1:nFrames
                cFrameInds = frameInds(frameInds(:,iFrame)>0,iFrame);
                frameClusteringX(iFrame,:) =  mean(x(cFrameInds,:),1);
            end
            
            prune = any(isnan(frameClusteringX),2);
            frameClusteringX(prune,:) = repmat(mean(frameClusteringX(~prune,:)),sum(prune),1);
            
            [classMeans, Yout] = prtUtilKmeans(frameClusteringX,nStates,'handleEmptyClusters','random'); %#ok<ASGLU>
            
            [unwanted, sortedInds] = sort(hist(Yout,1:nStates),'descend'); %#ok<ASGLU>
            dsMat = bsxfun(@eq,Yout,sortedInds);
            
            phiMat = kron(dsMat,ones(frameLength,1));
            phiMat = phiMat(1:size(x,1),:);

        end
        
        function obj = weightedConjugateUpdate(obj, priorObj, x, weights)
            if isempty(weights)
                weights = ones(size(x,1),1);
            end
            obj.model.lambda = priorObj.model.lambda + sum(bsxfun(@times,x,weights),1);
        end
        
        function kld = conjugateKld(obj, priorObj)
            kld = prtRvUtilDirichletKld(obj.model.lambda,priorObj.model.lambda);
        end
        
        function x = posteriorMeanDraw(obj, n, varargin)
            if nargin < 2
                n = 1;
            end
            
            probs = obj.model.lambda./sum(obj.model.lambda);
            x = prtRvUtilRandomSample(probs, n);
        end
        
        function s = posteriorMeanStruct(obj)
            s.probabilities = obj.model.lambda./sum(obj.model.lambda);
        end
        
        function model = modelDraw(obj)
            model.probabilities = prtRvUtilDirichletRnd(obj.model.lambda);
        end
        
        function plot(objs, colors)
            
            nComponents = length(objs);
            
            if nargin < 2
                cMap = jet(128);
                colors = cMap(gray2ind(mat2gray(1:nComponents),size(cMap,1))+1,:);
            end
            
            nDimensions = length(objs(1).model.lambda);
            
            lambdaMat = zeros([nComponents, nDimensions]);
            for s = 1:nComponents
                lambdaMat(s,:) = objs(s).model.lambda;
            end
                
            probMat = bsxfun(@rdivide,lambdaMat,sum(lambdaMat,2));
            for iSource = 1:size(probMat,1)
                for jSym = 1:size(probMat,2)
                    cSize = sqrt(probMat(iSource,jSym));
                    if cSize > 0
                        rectangle('Position',[jSym-cSize/2, iSource-cSize/2, cSize, cSize],'Curvature',[1 1],'FaceColor',colors(iSource,:),'EdgeColor',colors(iSource,:));
                    end
                end
            end
            set(gca,'YDir','Rev');
            title('Observations Prob.')
            xlabel('Observations')
            ylabel('Component')
            xlim([0 size(probMat,2)+1])
            ylim([0 size(probMat,1)+1])

        end
        
        function [obj, training] = vbOnlineWeightedUpdate(obj, priorObj, x, weights, lambda, D, prevObj) %#ok<INUSL>
            S = size(x,1);
            
            obj.model.lambda = prevObj.model.lambda*(1-lambda) + (D/S*sum(x,1) + priorObj.model.lambda)*lambda;
            
            training = struct([]);
        end
    end
end