function res = demosaic(raw, pattern, parallel)
%FPI.DEMOSAIC Demosaic a multi-layer Bayer filter mosaic
% rgb = FPI.DEMOSAIC(raw, pattern) demosaics the array raw assuming the 
% given Bayer pattern. Returns 
%
% If no filter pattern is given, assumes 'rggb' pattern.

if nargin > 2
    pattern = 'rggb';
end

nLayers = size(raw, 3);
res 

parfor k = 1:nLayers
    rgb = demosaic(raw(:,:,k),pattern);
    
end
    
    