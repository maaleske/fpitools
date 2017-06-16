function [res] = read(filename)
%FPI.READ_RAW Read and calculate radiance data from a raw FPI camera file
% cube = FPI.READ(filename, pattern) reads the raw data from filename and
% attempts to demosaic and calculate radiances for each layer using VTT 
% header (.hdt) information.
%
% Authors:
% Original: 2017 Technology Research Centre of Finland, VTT
% Cube class modification: 2017 Matti A. Eskelinen, University of Jyväskylä
%
% See LICENSE for licensing information.

raw = ENVI.read(filename, 'Raw');
[header,layer_info] = FPI.parse_hdt(regexprep(filename, '\.dat$', '.hdt', 'ignorecase'));

% Extra metadata:
% - VTT header uses nm (nanometer) as the wavelength unit by default
% - Calibration information is for radiance 
wlu = 'nm';
qty = 'Radiance';

% If the header indicates a dark reference frame, extract and substract it 
% before continuing
hasDark = strcmp(header.Dark_Layer_included,'TRUE');
if hasDark
    raw = raw.bands(2:raw.nBands) - raw.bands(ones(1,raw.nBands-1));
end

nLayers = raw.nBands;

% Calculate total number of recoverable wavelengths
tot_peaks = 0;
for j=1:nLayers
    for k=1:layer_info(j).Npeaks
        wl = layer_info(j).Wavelengths(k);
        if wl > 0
            tot_peaks = tot_peaks + 1;
        end
    end
end

% Initialize the result arrays
cube = nan(raw.Height, raw.Width, tot_peaks);
wls = zeros(tot_peaks,1);
fwhms = zeros(tot_peaks,1);

% Demosaic each layer that corresponds to peaks and calculate the
% corresponding reflectances.
ii = 1;
for j=1:nLayers
    assert(isequal(layer_info(j).block_name, sprintf('Image%d', j-1)),...
        'Non-image layer encountered at layer %d', j);
    if layer_info(j).Npeaks == 0
        continue
    end
    
    % Determine the Bayer filter pattern
    switch layer_info(j).Bayer_Pattern
        case 0
            pattern = 'gbrg';
        case 1
            pattern = 'grbg';
        case 2 
            pattern = 'bggr';
        case 3
            pattern = 'rggb';
        otherwise
            error('Bayer filter pattern not specified for layer %d', j);
    end
    
    % Cast to double is needed for multiplication
    rgb = double(demosaic(squeeze(raw.bands(j).Data), pattern));
    
    for k=1:layer_info(j).Npeaks
        wl = layer_info(j).Wavelengths(k);
        fwhms(ii) = layer_info(j).FWHMs(k);
        Si = layer_info(j).Sinvs(3*(k-1)+1 : 3*k);
        c = Si(1) * rgb(:,:,1) + Si(2) * rgb(:,:,2) + Si(3) * rgb(:,:,3);
        wls(ii) = wl;
        cube(:,:,ii) = c;
        ii = ii+1;
    end
end

% Sort the layers and metadata in ascending order by wavelength
[~,idx] = sort(wls);
wls = wls(idx);
fwhms = fwhms(idx);
cube = cube(:,:,idx);

% Return a Cube object with the calculated data
res = Cube(cube, 'quantity', qty, 'wlu', wlu, 'wl', wls, 'fwhm', fwhms);

end