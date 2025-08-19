function [indexes, max_mod] = ECGDELINEATION_modmax(x, first_samp, threshold, signo, t_restriction, n_greater)
% Find the maximum of the modulus of a signal
%
% Inputs:
%
%  - x: signal to evaluate
%  - first_samp: analyze signal from first_samp sample
%  - threshold: amplitude threshold to consider maxima
%  - signo: sign of the maxima to be considered. If signo is +1 or -1, only
%           modulus maxima for positive or negative samples are considered.
%           If modulus is 0, all the maxima are considered.
%  - t_restriction: time restriction between adjacent maximums
%  - n_greater: return only the n_greater maxima
%
% Outputs:
%
%  - indexes: indexes of the modulus maxima
%  - max_mod: values of the modulus maxima


lx = size(x, 1);
indexes = [];
max_mod = [];

if (nargin < 2) || isempty(first_samp)
    first_samp = [2 lx];
else
    if length(first_samp) < 2
        first_samp = [max(2, first_samp) lx];
    else
        first_samp(1) = max(2, first_samp(1));
        first_samp(2) = min(lx, first_samp(2));
    end
end

if (nargin < 3) || isempty(threshold)
    threshold = 0;
end

if (nargin < 4) || isempty(signo)
    signo = 0;
end

if (lx > first_samp(1))

    s = sign(x);
    x = abs(x);

    sample_curr_idx = first_samp(1) : first_samp(2) - 1;
    sample_prev_idx = (first_samp(1) - 1) : first_samp(2) - 2;
    sample_next_idx = (first_samp(1) + 1) : first_samp(2);
    scuind= x(sample_curr_idx, :);
    localmax = (scuind  >= x(sample_prev_idx,:)) ...
             & (scuind  >  x(sample_next_idx,:) ...
             &  scuind  >= threshold) ...
             & (s(sample_curr_idx, :)*signo >= 0);   % if 0, it doesnt matter

    iAux = false(size(x));
    iAux(sample_curr_idx,:) = localmax;
    indexes = find(iAux);
    max_mod = x(indexes) .* s(indexes);

else
    return
end

if( nargin < 5 || isempty(t_restriction) )
    t_restriction = 0;
end

if (t_restriction > 0)
    
    ii = 1;

    lindexes = length(indexes);
    [~, aux_sorted_mod_idx] = sort(x(indexes), 'descend');

    while (ii < lindexes)
    
        if (~isnan(indexes(aux_sorted_mod_idx(ii))))

            indexes_inside_idx = find(indexes >= (indexes(aux_sorted_mod_idx(ii)) - t_restriction) & indexes <= (indexes(aux_sorted_mod_idx(ii)) + t_restriction));
            indexes_inside_idx(indexes_inside_idx == aux_sorted_mod_idx(ii)) = [];

            if( ~isempty(indexes_inside_idx) )
                indexes(indexes_inside_idx) = nan;
            end
        end

        ii = ii + 1;
    
    end

    indexes(isnan(indexes)) = [];     
    max_mod = x(indexes) .* s(indexes);
    
end

lindexes = length(indexes);

if (nargin < 6) || isempty(n_greater)
    n_greater = lindexes;
end

if (n_greater < lindexes)
    
    [~, aux_idx] = sort(abs(max_mod), 'descend');
    
    indexes = indexes(aux_idx(1 : n_greater));
    max_mod = max_mod(aux_idx(1 : n_greater));

    [indexes, aux_idx] = sort(indexes);
    max_mod = max_mod(aux_idx);
    
end

end