function index = ECGDELINEATION_zerocross(x)
% Returns the index of the input vector in which the first zero crossing is located.

m = x(2 : end) .* x(1 : end - 1);
index = find(m <= 0, 1, 'first');

if abs(x(index)) > abs(x(index + 1))
  index = index + 1;
end

end


