function [Pxx, Fxx] = SPECTRALANALYSIS_computeSpectra(ECG, fs)
%SPECTRALANALYSIS_computeSpectra: Compute spectrum of an ECG signal using 
%the Welch's periodogram method
%
%Inputs:
%
% - ECG: ECG signals [nS x nL], where nL: number of leads; nS: number of samples
% - fs: sampling frequency in Hz
%
%Outputs:
%
% - Pxx: power spectral density of the input signals obtained using the
%        Welch's periodogram methos
% - Fxx: vector of the frequencies (in Hz) at which Pxx is estimated
%
%Last edited: 10/09/2020, Javier Milagro (javier.milagro@corify.es) 
%-------------------------------------------------------------------------

switch fs
    case 500
        NFFT = 2^12;
    case 1000
        NFFT = 2^13;       
    otherwise
        if fs > 1000
            NFFT = 2^14;
        elseif fs < 500
            NFFT = 2^10;
        else
            NFFT = 2^12;
        end
end

[Pxx, Fxx] = pwelch(ECG, hamming(round(NFFT/2)), round(NFFT/4), NFFT, fs);

end