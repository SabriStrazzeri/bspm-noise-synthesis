function pp = ECGDELINEATION_picpost(sig, time)
% Detect the first peak of signal sig

der = diff(sig);
zero = find((der(1 : end - 1) .* der(2 : end) <= 0), 1, 'first');
pp = time + zero;  

end

