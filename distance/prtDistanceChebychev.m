function D = prtDistanceChebychev(varargin)
% CHEBYCHEV      Calculate the distance from all of the points in P1 to all
%   of the points in P2 usuing the chebychev distance measure. The
%   chebychev distance is the maximum absolute distance between any 
%   dimension of P1 and the corresponding of P2.
%
% Syntax: D = chebychev(varargin)
%
% Inputs: 
%   varargin{1} - double Mat - NxM matrix of locations. N is the number of 
%       points and M is the dimensionality.
%   varargin{2} - double Mat - DxM matrix of locations. D is the number of 
%       points and M is the dimensionality.
%
% Outputs
%   D - NxD matrix of distances.
%
% Example:
%   X = [0 0; 1 1];
%   Y = [1 0; 2 2; 3 3;];
%   D = prtDistanceChebychev(X,Y)
%   
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: distance.m cityblock.m euclidean.m lnorm.m mahalanobis.m
%   squaredist.m

% Author: Kenneth D. Morton Jr.
% Duke University, Department of Electrical and Computer Engineering
% Email Address: collinslab@gmail.com
% Created: 17-December-2005
% Last revision: 5-January-2006

D = prtDistanceCustom(varargin{1},varargin{2},@(x1,x2)max(abs(x1-x2)));