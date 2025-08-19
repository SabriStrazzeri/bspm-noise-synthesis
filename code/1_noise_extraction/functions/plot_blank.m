function [figuresList] = plot_blank(dataName, figuresList)
%plot_blank: represents blank figure for discarded cases.
%
%Inputs:
% - dataName: name of the file with the saved data.
% - figuresList: array with the name of the figures.
%
%Outputs:
% - figuresList: updated array with the name of the figures.
%
%Last edited: 11/04/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------

% Represent a blank figure
figure('Visible', 'off');
name = string(replace(dataName, '.mat', '')) + '.png';

% Save figure as PNG file
cd('..\Figures\PNG')
saveas(gcf, name)

% Save figure as FIG file
cd('..\Figures\FIG')
name = replace(name, '.png', '.fig');
savefig(gcf, name)

% Update figure list
cd('..\Figures\List')
name = replace(name, '.fig', '');
figuresList{end+1} = name;

disp('An error occurred, a blank figure has been created.');


end
