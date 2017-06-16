classdef FPI
    methods (Static)
        % Read and calculate radiance data from a VTT FPI camera file
        % given the Bayer filter pattern
        [cube] = read(filename, pattern)

        % Parse a VTT FPI camera header file
        [header, layer_info] = parse_hdt(filename);
    end
end