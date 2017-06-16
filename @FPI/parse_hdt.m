function [header, layers] = parse_hdt(file_name)


F = fopen(file_name, 'r');
header = parse_block(F, 'Header');

i = 0;
while ~feof(F)
    image = parse_block(F, sprintf('Image%d', i));
    if i==0
        layers = image;
    else
        layers(i+1) = image;
    end
    i = i+1;
end

fclose(F);


function S = parse_block(F, block_name)
S = struct;

if feof(F)
    return
end

s = fgetl(F);
s = strtrim(s);
m = regexp(s, [ '^\[(' block_name ')\]$'], 'tokens');
if isempty(m)
    error('block name in file does not match %s\nInput line: %s\n', block_name, s);
end
S = setfield(S, 'block_name', block_name);

while ~feof(F)
    s = fgetl(F);
    s = strtrim(s);
    if isempty(s)
        break
    end
    m = regexp(s, '^([^=]+) = (.*)$', 'tokens');
    if isempty(m)
        error('block name in file does not match %s\nInput line: %s\n', block_name, s);
    end
    name = m{1}{1};
    name = regexprep(name, '[^a-zA-Z0-9]', '_');
    name = regexprep(name, '_+', '_');
    name = regexprep(name, '_$', '');
    value = conv(m{1}{2});
    S = setfield(S, name, value);
end


function y = conv(s)
if isempty(s)
    y = s;
    return
end
if s(1) == '"' && s(end) == '"'
    y = sscanf(s(2:end-1), '%f');
    y = y(:)';
else
    y = sscanf(s, '%f');
    y = y(:)';
end
if isempty(y)
    y = s;
end
