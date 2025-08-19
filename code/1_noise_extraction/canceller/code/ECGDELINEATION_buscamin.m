function ind = ECGDELINEATION_buscamin(x)
% Find the first minimum of the modulus of x.

x = abs(x);
localmin = (x(2 : end - 1)<= x(1 : end - 2)) & (x(2 : end - 1) <= x(3 : end));

ind = find(localmin, 1, 'first');

end
