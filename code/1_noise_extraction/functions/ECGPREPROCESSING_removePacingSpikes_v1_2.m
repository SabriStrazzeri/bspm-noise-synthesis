function [ECG_nospikes, spikes, spikesInterval, spikesSignal] = ECGPREPROCESSING_removePacingSpikes_v1_2(ECG, fs, leadStatus, spikes, spikeWidth1, spikeWidth2)
%ECGPREPROCESSING_removePacingSpikes: Remove pacing spikes from an ECG signal.
%
%Inputs:
%  - ECG: ECG signals [nL x nS], where nL: number of leads; nS: number of 
%       samples
%  - fs: sampling frequency in Hz.
%  - leadStatus: nL length array indicating lead status (1: good signal 
%             quality, 0: bad signal quality, -1: disconnected).
%  - spikes: position of the spikes to remove. If not indicated, spikes are
%           first located.
%  - spikeWidth1: number of samples from the spike's onseet to its peak.
%  - spikeWidth2: number of samples from the spike's peak to its offset.
%
%Outputs:
%  - ECG_nospikes: ECG signals clean of pacing spikes.
%  - spikes: position of the detected pacing spikes.
%  - spikesInterval: position of the detected pacing spikes.
%  - spikesSignal: amplitude of the detected pacing spikes.
%
%Last edited: 16/09/2020, Javier Milagro (javier.milagro@corify.es) 
%Last modified: 12/05/2022, Marta Martínez (marta.martinez@corify.es) 
%Last edited: 30/12/2022, Javier Milagro (javier.milagro@corify.es) 
%-------------------------------------------------------------------------

if nargin<4
    spikes = [];
end
if nargin<5
    spikeWidth1 = [];
end
if nargin<6
    spikeWidth2 = [];
end

if isempty(spikes)
    spikes = ECGPREPROCESSING_detectPacingSpikes_v1_2(ECG,fs,leadStatus, 150, 10, 8, 500); 
end

if isempty(spikeWidth1)
    spikeWidth1 = round(0.008*fs);
end

if isempty(spikeWidth2)
    spikeWidth2 = round(0.008*fs);
end

[nL, nS] = size(ECG);
% t=1:nS;
% t2=t;
% for spk = 1:length(spikes)
%     cutbefore = max(1,spikes(spk)-spikeWidth1);
%     cutafter = min(nS,spikes(spk)+spikeWidth2);
%     t2(cutbefore:cutafter) = 0;
% end
% t2=nonzeros(t2).';
% if t2(end)<t(end)
%     t2=[t2 t(end)];
% end
% if t2(1) > t(1)
%     t2 = [t(1) t2];
% end
% 
% for i = 1:nL
%     if leadStatus(i) > 0
%        ECG(i,:) = interp1(t2,ECG(i,t2),t,'linear') ;
%     end
% end

spikesSignal = zeros(size(ECG));
spikesInterval = [];

for i = 1:length(spikes)
    spikesInterval = [spikesInterval max(1, spikes(i)-spikeWidth1) : min(nS, spikes(i)+spikeWidth2)];
end

spikesSignal(:, spikesInterval) = ECG(:, spikesInterval);

% [ECG, spikes] = ECGPREPROCESSING_removePacingSpikes_v1_2(ECG, fs, leadStatus, spikes, spikeWidth1, spikeWidth2);

ECG_nospikes = ECG;
ECG_nospikes(:, spikesInterval) = [];
tS = 1:nS;
tS_nospikes = tS;
tS_nospikes(:, spikesInterval) = [];

if (nL == 1)||(nS == 1)
    ECG_nospikes = interp1(tS_nospikes, ECG_nospikes', tS);
else
    ECG_nospikes = interp1(tS_nospikes, ECG_nospikes', tS)';
end

ECG_nospikes = ECG_nospikes';

end
