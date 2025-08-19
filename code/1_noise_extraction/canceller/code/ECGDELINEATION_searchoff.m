function offset = ECGDELINEATION_searchoff(picoffset, sig, K)
% Look for the offset of a wave using the derivative method. Sig's first 
% sample must be picoffset.
%
% Inputs:
%
%   - picoffset: position of the last relevant modulus maximum in the wavelet 
%   - sig: wavelet signal (one scale)
%   - K: threshold factor
%
% Outputs:
%
%  - offset: wave offset

if isempty(picoffset) || isempty(sig)
   offset = [];
   return;
end

maxderoff = abs(sig(1));  % maximum derivative
ind1 = find(abs(sig(2 : end)) < maxderoff/K, 1, 'first');
ind2 = ECGDELINEATION_buscamin(sig(2 : end));

if isempty(ind1) && isempty(ind2)
   offset = picoffset + length(sig) - 1;
elseif isempty(ind1)
   offset = picoffset + ind2;
elseif isempty(ind2)
   offset = picoffset + ind1;
else
   offset = picoffset + min(ind1, ind2);
end

end