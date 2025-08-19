function process_longer_signals(ECG)
%process_longer_signals: processes longer ECG signals by segmenting them into smaller parts.
%
%Inputs:
% - ECG: nL (number of leads) x D (duration of ECG) matrix corresponding to
% the ECG signal.
%
%Outputs:
% None. The function saves the processed segments in a specified folder.
%
%Last edited: 24/04/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------

%% Variables initialization and calculation of number of segments

% Define segment length
segment_length = 10000;

% Calculate the number of segments
num_segments = floor(length(ECG)/segment_length);


%% Segmentation of the ECG signal

if num_segments > 1

    % Initialize variables
    segments = cell(1, num_segments);

    % Extract segments
    for j = 1:num_segments
        segments{j} = ECG(:, (j-1)*segment_length + 1:j*segment_length);
    end

    % Save new data in specified folder
    for k=1:length(segments)
        cd('C:\Users\ITACA_2025_1\Documents\TFM\Proyecto\BBDD\Raw')
        selected_segment = segments{1,k};
        if singleBeat
            episode.episode.segment.bspm.singleBeatAnalysis.voltage = selected_segment;
        elseif avgBeat
            episode.episode.segment.bspm.averageBeatAnalysis.voltage = selected_segment;
        end
        aux = replace(string(dataName), '.mat', '');
        filename = string(aux) + '_' + string(k) + '.mat';
        save(filename, 'episode')
        disp('Segment ' + string(k) + ' from case ' + string(dataName) + ' has been saved.')
    end

else % Length is equal to specified segment length

    cd('C:\Users\ITACA_2025_1\Documents\TFM\Proyecto\BBDD\Raw')
    ECG = ECG(:, 1:10000);
    if singleBeat
        episode.episode.segment.bspm.singleBeatAnalysis.voltage = ECG;
    elseif avgBeat
        episode.episode.segment.bspm.averageBeatAnalysis.voltage = ECG;
    end
    
    % Save original data to specified folder
    filename = string(dataName);
    save(filename, 'episode')
    disp('Case ' + string(dataName) + ' does not have more segments, and has been saved.')

end


end