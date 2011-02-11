classdef prtClassBagging < prtClass
    % prtClassBagging  Bagging (Bootstrap Aggregating) classifier
    %
    %    CLASSIFIER = prtClassBagging returns a bagging classifier
    %
    %    CLASSIFIER = prtClassBagging(PROPERTY1, VALUE1, ...) constructs a
    %    prtClassBagging object CLASSIFIER with properties as specified by
    %    PROPERTY/VALUE pairs.
    %
    %    A prtClassBagging object inherits all properties from the abstract
    %    class prtClass. In addition is has the following properties:
    %
    %    baseClassifier  - The classifier to be used 
    %    nBags           - The number of bagging sampes to use
    % 
    %    Bagging classifiers are meta-classifiers that attempt to develop
    %    more robust decision boundaries by aggregating outputs over
    %    multiple bootstrapped samples of the original data.  For more
    %    information on bagging classifiers, see:
    %
    %    http://en.wikipedia.org/wiki/Bootstrap_aggregating
    %
    %    A prtClassBagging  object inherits the TRAIN, RUN, 
    %    CROSSVALIDATE and KFOLDS methods from prtAction. It also inherits 
    %    the PLOT method from prtClass.
    %
    %    Example:
    %
    %     TestDataSet = prtDataGenUnimodal;       % Create some test and
    %     TrainingDataSet = prtDataGenUniModal;   % training data
    %     classifier = prtClassBagging;           % Create a classifier
    %     classifier.baseClassifier = prtClassMap; % Set the classifier to
    %                                              % a prtClassMap
    %     classifier = classifier.train(TrainingDataSet);    % Train
    %     classified = run(classifier, TestDataSet);         % Test
    %     subplot(2,1,1);
    %     classifier.plot;
    %     subplot(2,1,2);
    %     [pf,pd] = prtScoreRoc(classified,TestDataSet);
    %     h = plot(pf,pd,'linewidth',3);
    %     title('ROC'); xlabel('Pf'); ylabel('Pd');
    %
    

    properties (SetAccess=private)
        % Required by prtAction
        name = 'Bagging Classifier'   %  Bagging Classifier
        nameAbbreviation = 'Bagging'  %  Bagging
        isNativeMary = false;         % False
    end
    
    properties
        baseClassifier = prtClassFld;  % The classifier to be bagged
        nBags = 100;                  % The number of bags
    end
    properties (SetAccess=protected, Hidden = true)
        Classifiers
    end
    
    methods
        
        function Obj = prtClassBagging(varargin)
            Obj = prtUtilAssignStringValuePairs(Obj,varargin{:});
        end
        
        function Obj = set.nBags(Obj,val)
            if ~prtUtilIsPositiveScalarInteger(val)
               error('prt:prtClassBagging:nBags','nBags must be a positive scalar integer'); 
            end
            Obj.nBags = val;
        end
        
        function Obj = set.baseClassifier(Obj,classifier)
            if ~isa(classifier,'prtClass')
                error('prt:prtClassBagging','baseClassifier must be a subclass of prtClass, but classifier provided was a %s',class(classifier));
            end
            Obj.baseClassifier = classifier;
        end
    end
    
    methods (Access=protected, Hidden = true)
        
        function Obj = trainAction(Obj,DataSet)

            Obj.nameAbbreviation = sprintf('Bagging_{%s}',Obj.baseClassifier.nameAbbreviation);
            for i = 1:Obj.nBags
                if i == 1
                    Obj.Classifiers = train(Obj.baseClassifier,DataSet.bootstrap(DataSet.nObservations));
                else
                    Obj.Classifiers(i) = train(Obj.baseClassifier,DataSet.bootstrap(DataSet.nObservations));
                end
            end
        end
        
        function yOut = runAction(Obj,DataSet)
            yOut = DataSet;
            for i = 1:Obj.nBags
                Results = run(Obj.Classifiers(i),DataSet);
                if i == 1
                    yOut = yOut.setObservations(Results.getObservations);
                else
                    yOut = yOut.setObservations(yOut.getObservations + Results.getObservations);
                end
            end
            yOut = yOut.setObservations(yOut.getObservations./Obj.nBags);
        end
        
    end
    
end