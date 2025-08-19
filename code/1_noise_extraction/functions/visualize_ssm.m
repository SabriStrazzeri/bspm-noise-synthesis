function visualize_ssm(ECG, processedECG, dataName, dir)
%visualize_ssm: represents the original and cancelled ECG signals.
%
%Inputs:
% - ECG: nL (number of valid leads) x D (duration of ECG) matrix 
% corresponding to the ECG signal.
% - processedECG: nL (number of valid leads) x D (duration of ECG) matrix 
% corresponding to the cancelled ECG signal.
% - dataName: name of data file.
% - dir: folder directory where the figures will be saved.
%
%Last edited: 11/04/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------


figure('Visible', 'off');
set(gcf, 'color', 'w', 'Position', [392 330 1110 492]);

% Plotting ECG signal
subplot(2,1,1);
plot(ECG);
title('Señal original');
xlim([0, length(ECG)])
ylimMin = min(ECG(:)); ylimMax = max(ECG(:));
ylim([ylimMin, ylimMax]);
hold on;

% Plotting cancelled ECG signal
subplot(2,1,2);
plot(processedECG);
title('Señal ruidosa');
xlim([0, length(processedECG)])
ylim([ylimMin, ylimMax]);
hold on;

% Save figure as PNG file
cd(dir)
dataName = replace(dataName, '.mat', '');
name = string(dataName) + '.png';
saveas(gcf, name);

% Save figure as FIG file
cd('C:\Users\ITACA_2025_1\Documents\TFM\Proyecto\AnalisisDatos\Cancelador\FiguresNorm\Fig')
name = replace(name, '.png', '.fig');
savefig(gcf, name);
cd('C:\Users\ITACA_2025_1\Documents\TFM\Proyecto\AnalisisDatos')

end