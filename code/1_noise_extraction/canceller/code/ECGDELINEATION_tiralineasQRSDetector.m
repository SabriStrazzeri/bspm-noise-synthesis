function QRS = ECGDELINEATION_tiralineasQRSDetector(ECG, fs)

% These variables will be converted in constants in the future ------------
maxIterations = 200;
maxSlope = 100;
minQRSdistance = 0.2; %Mínima distancia entre QRS de 200 ms
threshold = 0.1;
fpb = 20;
[B,A] = butter(10, fpb/(fs/2));  
% -------------------------------------------------------------------------

%% Pre-processing
% Low-pass filtering
ECG = filtfilt(B, A, ECG')';

% The amplitude of each lead is normalized
maxAmplitude = max(abs(ECG), [], 2);
ECG = ECG./repmat(maxAmplitude, 1, size(ECG, 2));

% Normalized mean lead
Y = nanmean(abs(ECG), 1);
Y = Y./max(Y);

%% QRS candidates detection
% Detect QRS candidates based on polyline splitting
detectedPoints = ECGDELINEATION_tiralineas(Y, maxIterations, threshold);

% Compute the slope of the detected points
slope = fs.*diff(Y(detectedPoints))./diff(detectedPoints);

% Points whose slope is larger than a threshold, and points close to them,
% are discarded
largeSlope = find(abs(slope) > maxSlope);
close2LargeSlope = [];
searchWindow = fs.*0.01; % Search window around a point with large slope    

for i=1:length(largeSlope)            
    auxClose2LargeSlope = find((detectedPoints > (detectedPoints(largeSlope(i)) - searchWindow)) & (detectedPoints < (detectedPoints(largeSlope(i)) + searchWindow)));
    close2LargeSlope = [close2LargeSlope auxClose2LargeSlope];
end
   
points2Remove = unique([largeSlope close2LargeSlope]);


%% QRS candidates are reduced to those points which are local maxima and
%% which present a large slope variation

% Locate points with large slope variation
slopeVariation = diff(slope);
pointsNotRemoved = setdiff(1:length(slopeVariation), points2Remove-1);
slopeVariationThreshold = -(mean(abs(slopeVariation(pointsNotRemoved))));
candidatesIndex1 = find(slopeVariation < slopeVariationThreshold) + 1;
candidates1 = setdiff(detectedPoints(candidatesIndex1), detectedPoints(points2Remove));

% Locate local maxima
candidatesIndex2 = find((slope(1:end-1) > 0) & (slope(2:end) < 0)) + 1;
candidates2 = setdiff(detectedPoints(candidatesIndex2), detectedPoints(points2Remove));
candidates2(Y(candidates2) < (prctile(Y(candidates2), 90) * 0.4)) = [];

% QRS candidates
candidates = intersect(candidates1,candidates2);

%% Remove QRS candidates which are very close

candidatesDistance = diff(candidates);
minQRSdistance = minQRSdistance*fs;

points2Check = find(candidatesDistance < minQRSdistance);
points2Remove = [];

while ~isempty(points2Check)
    
    for i = 1:length(points2Check)
       % From two close QRS candidates, remove the one with larger slope variation
       if slopeVariation(i) > slopeVariation(i+1)
           points2Remove = [points2Remove points2Check(i)];
       else
           points2Remove = [points2Remove points2Check(i)+1];
       end
    end
    
    % Remove the selected points and repeat again
    candidates(points2Remove) = [];
    candidatesDistance = diff(candidates);
    points2Check = find(candidatesDistance < minQRSdistance);
    points2Remove = [];
    
end

%% Refine detection
% Detection is refined by template matching, to discard events whose 
% morphology does not correspond to a QRS complex. In case that a
% missdetection is detected, a search for QRS complexed in that interval is
% conducted
QRS = ECGDELINEATION_refineDetections(Y, candidates, fs);
QRS = unique(QRS);

end