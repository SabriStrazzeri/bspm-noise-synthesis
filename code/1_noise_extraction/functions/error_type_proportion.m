function [error_counts, error_proportions, total_cases,error_types] = error_type_proportion(nonValid)
%error_type_proportion: calculates the proportion of each error type in the nonValid array.
%padding.
%
%Inputs:
% - nonValid: array with the invalid cases.
%Outputs:
% - error_counts: counts of each error type.
% - error_proportions: proportions of each error type.
% - total_cases: total number of discarded cases.
% - error_types: unique error types.
%
%Last edited: 11/04/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------

% Extract the third column (error types)
error_types = nonValid(:, 3);

% Get unique error types
unique_errors = unique(error_types);

% Initialize counts
error_counts = zeros(length(unique_errors), 1);

% Count occurrences of each error type
for i = 1:length(unique_errors)
    error_counts(i) = sum(strcmp(error_types, unique_errors{i}));
end

% Calculate the total number of discarded cases
total_cases = length(nonValid);

% Calculate the proportion of each error type
error_proportions = error_counts / total_cases * 100;

% Display the results
disp('------------------------')
disp('Error counts:');
disp('------------------------')
for i = 1:length(unique_errors)
    fprintf('%s: %d\n', unique_errors{i}, error_counts(i));
end

disp('------------------------')
disp('Error proportions:');
disp('------------------------')
for i = 1:length(unique_errors)
    fprintf('%s: %.4f\n', unique_errors{i}, error_proportions(i));
end


end