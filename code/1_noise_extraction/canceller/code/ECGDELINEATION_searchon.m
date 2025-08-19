function onset = ECGDELINEATION_searchon(piconset, sig, K)
% Look for the onset of a wave using the derivative method. Sig's last 
% sample must be piconset.
%
% Inputs:
%
%   - piconset: position of the first relevant modulus maximum in the wavelet 
%   - sig: wavelet signal (one scale)
%   - K: threshold factor
%
% Outputs:
%
%  - onset: wave onset

if isempty(piconset) || isempty(sig)
   onset = [];
   return;
end

maxderon = abs(sig(end));  % maximum derivative
ind1 = find(abs(flipud(sig(1 : end - 1))) < maxderon/K, 1, 'first');
ind2 = ECGDELINEATION_buscamin(flipud(sig(1 : end - 1)));

if isempty(ind1) && isempty(ind2)
   onset = piconset - length(sig) + 1;
elseif isempty(ind1)
   onset = piconset - ind2;
elseif isempty(ind2)
   onset = piconset - ind1;
else
   onset = piconset - min(ind1, ind2);
end

end

