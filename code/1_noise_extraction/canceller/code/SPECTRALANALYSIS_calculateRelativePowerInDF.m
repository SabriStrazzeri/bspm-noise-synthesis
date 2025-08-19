function CE = SPECTRALANALYSIS_calculateRelativePowerInDF(Pxx, Fxx, DF, nHarmonics, lowerFreqLimit, upperFreqLimit)
%SPECTRALANALYSIS_calculateRelativePowerInDF: Computes the percentage of 
%spectral power contained in the DF harmonic components.
% 
%Inputs:
%
% - Pxx: power spectral density.
% - Fxx: frequency components (in Hz) in which Pxx is estimated.
% - DF: Dominant Frequency in each atria vertex (in Hz).
% - nHarmonics: number of harmonic components to be considered.
% - lowerFreqLimit: lower limit for DF search (Hz). Default value is 4 Hz.
% - upperFreqLimit: upper limit for DF search (Hz). Default value is 12 Hz.
%
%Outputs:
%
% - CE: percentage of spectral power contained in DF and its harmonics.
%
%Last edited: 09/09/2020, Javier Milagro (javier.milagro@corify.es) 
% -------------------------------------------------------------------------

if (nargin < 4) || isempty(nHarmonics)
    nHarmonics = 3; 
end

if (nargin < 5) || (isempty(lowerFreqLimit))
    lowerFreqLimit = 4;
end

if (nargin < 6) || (isempty(upperFreqLimit))
    upperFreqLimit = 12;
end

rango = [lowerFreqLimit upperFreqLimit];
CE = zeros(length(DF),1);

for i = 1:length(DF)
    
    pospico = find(Fxx==DF(i));
    picomasarmonicos = pospico.*(1:nHarmonics); 
    resfreq = Fxx(2)-Fxx(1);
    ventana = round(0.25/resfreq);
    total = sum(Pxx(rango,i));
    
    for k = 1:length(picomasarmonicos)
        p1 = picomasarmonicos(k)-ventana;
        p2 = picomasarmonicos(k)+ventana;
        if p1(1)>1
            CE(i) = CE(i) + sum(Pxx(p1:p2,i));
        else
            CE(i) = 0;
        end
    end
    
CE(i) = CE(i)./total;

end
end