function [validCase, nonValid, figuresList] = detect_delineation_error(counter, nonValid, figuresList, typeError, dataName)
%detect_delineation_error: indicates type of error in the delineation of the ECG signal.
%
%Inputs:
% - counter: number of the analyzed case.
% - nonValid: array with the invalid cases.
% - figuresList: list of figures.
% - typeError: type of error found during execution.
% - dataName: name of the data file.
%
%Outputs:
% - validCase: boolean indicating if the case is valid (true) or not (false).
% - nonValid: updated array with the invalid cases.
% - figuresList: updated list of figures.
%
%Last edited: 11/04/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------

% Indicates that the case is not valid
validCase = false;

% Plots a blank figure and updates the list of figures 
[figuresList] = plot_blank(dataName, figuresList);

% Indicates the type of error found
if strcmp(typeError, 'Delineation') % Error in the delineation of the PQRST wave
    nonValid = [nonValid; string(counter), string(dataName), 'Delineation'];
    disp('Delineation error.'); disp('Discarded case.');
elseif strcmp(typeError, 'Preprocess') % Error in the preprocessing of the signal
    nonValid = [nonValid; string(counter), string(dataName), 'Preprocessing'];
    disp('Signal preprocessing error.'); disp('Caso Discarded case.');
elseif strcmp(typeError, 'Overlap') % Overlapping segments of the PQRST wave
    nonValid = [nonValid; string(counter), string(dataName), 'Overlapping'];
    disp('Overlapping error.'); disp('Discarded case.');
end


end