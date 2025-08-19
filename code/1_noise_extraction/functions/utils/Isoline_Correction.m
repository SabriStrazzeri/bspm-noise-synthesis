function [corrected_signal, dc_offset, histogram_counts, histogram_bins] = Isoline_Correction(input_signal, varargin)
% ISOLINE_CORRECTION Estima y elimina el offset DC de la línea isoeléctrica de un ECG
%
% Esta función estima la línea isoeléctrica (línea base) mediante el cálculo de la 
% amplitud más frecuente en la distribución de amplitudes de la señal ECG y la elimina.
%
% Entradas:
%   input_signal  - Señal ECG multicanal o monocanal. Cada canal debe ser una
%                   columna de esta matriz.
%   varargin      - Entrada opcional que especifica el número de bins utilizados
%                   para crear el histograma en la estimación de la moda.
%                   El valor predeterminado es 2^10 = 1024.
%
% Salidas:
%   corrected_signal - Señal filtrada donde se ha compensado el offset DC en cada canal.
%                      La línea isoeléctrica debería estar ahora alrededor de cero.
%   dc_offset        - Vector o escalar que contiene el offset estimado (amplitud más
%                      frecuente) de cada canal de la señal ECG.
%   histogram_counts - Matriz cuyas columnas contienen los conteos de frecuencia
%                      usados para el histograma de cada canal de ECG.
%   histogram_bins   - Matriz cuyas columnas contienen los valores de amplitud
%                      usados para el histograma de cada canal de ECG.
%
% Ejemplo de uso:
%   [corrected_signal, dc_offset, histogram_counts, histogram_bins] = Isoline_Correction(signal)

    % Preasignar memoria para la señal filtrada
    corrected_signal = zeros(size(input_signal));
    
    % Obtener el número de canales en el ECG
    num_channels = size(input_signal, 2);
    
    % Comprobar entrada opcional para el número de bins
    if isempty(varargin)
        % Número predeterminado de bins para histograma (mínimo entre 2^10 y el número de muestras)
        num_bins = min(2^10, size(input_signal, 1));
    else
        % Usar el número de bins proporcionado
        num_bins = varargin{1};
    end
    
    % Preasignar matrices para los resultados del histograma
    histogram_counts = zeros(num_bins, num_channels);
    histogram_bins = zeros(num_bins, num_channels);
    
    % Preasignar vector para los valores de offset
    dc_offset = zeros(num_channels, 1);
    
    % Proceso de eliminación del offset DC para cada canal
    for channel = 1:num_channels
        % Crear histograma de valores de amplitud para este canal
        [histogram_counts(:, channel), histogram_bins(:, channel)] = hist(input_signal(:, channel), num_bins);
        
        % Encontrar el máximo del histograma (la amplitud más frecuente)
        [~, max_index] = max(histogram_counts(:, channel));
        
        % La amplitud más frecuente es una buena estimación de la línea isoeléctrica
        dc_offset(channel) = histogram_bins(max_index, channel);
        
        % Eliminar el offset restando este valor de la señal original
        corrected_signal(:, channel) = input_signal(:, channel) - dc_offset(channel);
    end

end