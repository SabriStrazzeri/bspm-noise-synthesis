function pa = ECGDELINEATION_picant(sig, time)
% Detect the first peak of signal sig nearest to its end

sig = flipud(sig);
der = diff(sig);
zero = find((der(1 : end - 1) .* der(2 : end) <= 0), 1, 'first');
pa = time - zero;  

end
