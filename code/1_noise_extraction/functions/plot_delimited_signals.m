function [name, figList] = plot_delimited_signals(selectedECG, selectedAtrialActivity, start, stop, dataName, figList, dir)
%plot_delimited_signals: represents original and cancelled ECG signal with
%boxes delimiting  PQRST wave. 
%
%Inputs:
% - selectedECG: nL (number of valid leads) x D (duration of ECG) matrix corresponding to
% the ECG signal.
% - selectedAtrialActivity: nL (number of valid leads) x D (duration of ECG) matrix corresponding to
% the cancelled ECG signal.
% - start: array with the beginning of every PQRST wave in the ECG signal.
% - stop: array with the end of every PQRST wave in the ECG signal.
% - dataName: name of the data file.
% - figList: list of generated figures.
% - dir: folder directory where the figures will be saved.
%
%Outputs:
% - name: name of the data file without file extensions.
% - figList: figure list.
%
%Last edited: 11/04/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------

%figure;
figure('Visible', 'off');
set(gcf, 'color', 'w', 'Position', [392 330 1110 492]);
colors = lines(length(start));

% Plotting ECG signal
subplot(2,1,1); 
plot(selectedECG);
title('Original ECG signal');
xlim([0, length(selectedECG)])
hold on;
for i = 1:length(start)  
    ymin_ECG = min(selectedECG(:));
    ymax_ECG = max(selectedECG(:));
    rectangle('Position', [start(i), ymin_ECG, stop(i) - start(i), ymax_ECG - ymin_ECG], ...
              'EdgeColor', colors(mod(i, size(colors, 1)) + 1, :), 'LineWidth', 2, 'LineStyle', '-');
end
hold off;

% Plotting cancelled ECG signal
subplot(2,1,2);
plot(selectedAtrialActivity);
title('Cancelled ECG signal');
xlim([0, length(selectedECG)])
hold on;
for i = 1:length(start)
    ymin_AA = min(selectedAtrialActivity(:));
    ymax_AA = max(selectedAtrialActivity(:));
    rectangle('Position', [start(i), ymin_AA, stop(i) - start(i), ymax_AA - ymin_AA], ...
              'EdgeColor', colors(mod(i, size(colors, 1)) + 1, :), 'LineWidth', 2, 'LineStyle', '-');
end
hold off;

% Save figure as PNG file
cd(dir)
dataName = replace(dataName, '.mat', '');
name = string(dataName) + '.png';
saveas(gcf, name);

% Save figure as FIG file
name = replace(name, '.png', '');
figList{end+1} = name;


end