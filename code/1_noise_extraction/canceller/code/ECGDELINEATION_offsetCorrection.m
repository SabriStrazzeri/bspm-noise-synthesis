function offsetCorrection = ECGDELINEATION_offsetCorrection(beat, QRSpos, fs)

[B,A] = butter(10, 10/(fs/2));
beat = filtfilt(B,A,beat);

anchorPon = nanmean(beat(1:25));
if (QRSpos - 0.105*fs) < 1 
    offsetCorrection = zeros(size(beat));
else
    
    anchorPQ = nanmean(beat(QRSpos - 0.105*fs : QRSpos - 0.08*fs));
    anchorToff = nanmean(beat(end-24:end));
    anchorX = [13, QRSpos - 0.093*fs, length(beat) - 12];

    pol = polyfit(double(anchorX), [anchorPon, anchorPQ, anchorToff], 2);
    offsetCorrection = polyval(pol, 1:length(beat));
    offsetCorrection(1:anchorX(1)) = offsetCorrection(anchorX(1));
    offsetCorrection(anchorX(end):end) = offsetCorrection(anchorX(end));

end

if max(abs(offsetCorrection)) > 10*max(abs(beat))
    offsetCorrection = zeros(size(beat));
end

% figure
% subplot(1,2,1)
% plot(beat)
% hold on
% plot(anchorX, [anchorPon, anchorPQ, anchorToff], 'ro')
% plot(offsetCorrection, 'r')
% hold off
% subplot(1,2,2)
% plot(beat-offsetCorrection)

end
