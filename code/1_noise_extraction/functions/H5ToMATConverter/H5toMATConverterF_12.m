function H5toMATConverterF_12(path, ID_map, type_episode)

% INPUTS
% - path: path where files .h5 and .hd5 are located
% - ID_map: empty if you want to convert all maps of the session. If only 1 map want to be converted, number of this map.
% - type_episode:
%    - 0: Generate complete episode
%    - 1: Generate signals and maps data file, and geometries file appart
%    - 2: Generate geometries file only
%
%
% Created: app created by Marta Martinez
% Modified: function created by Inés Llorente (05/08/2024)

cd(path)

% addpath(genpath('C:\Users\marta\Documents\Corify\UPV\itacacor - Martínez, Marta\03_Codigo\H5ToMATConverter12_20241212'))

filesTable_h5 = dir('*.h5'); filesNames_h5 = {filesTable_h5.name}; 
filesTable_hd5 = dir('*.hd5'); filesNames_hd5 = {filesTable_hd5.name}; 
filesNames = [filesNames_h5, filesNames_hd5];

fileName = filesNames{1};
get_index = strsplit(fileName, '_');
session_name = [get_index{1}, '_', get_index{2}];

% n=1;
% 
% while isempty(get_index)
% 
% get_index = regexp(filesNames{n}, '_get', 'once');
% session_name = fileName(1:get_index-1); 
% n=n+1;
% 
% end

switch type_episode
    
    case 0 % Generate complete episode

        if ~isempty(ID_map)
        
            episode = generateCompleteEpisodeF(path, session_name, ID_map); 
        
            filename = fullfile(path, [session_name, '_episode_',num2str(ID_map), '.mat']);
            try
                save(filename, 'episode');
                disp(['Archivo guardado correctamente en: ', filename]);
            catch ME
                disp(['Error al guardar el archivo: ', ME.message]);
            end
        
        elseif isempty(ID_map)
            % Expresión regular para buscar el número N en el nombre de archivo
            pattern = '_\d+\.h';  % Busca un número seguido de .h (.h5 y .hd5) al final del nombre
        
            % Iterar sobre cada nombre de archivo
            n = 1;
            for i = 1:numel(filesNames)
                % Buscar el patrón en el nombre de archivo actual
                match = regexp(filesNames{i}, pattern, 'match');
            
                % Si se encontró un patrón válido, extraer el número y convertirlo a número
                if ~isempty(match)
                    % Extraer el número quitando el '_','.h' y convertirlo a número
                    mapID(n) = str2double(match{1}(2:end-2)); 
                    n = n+1;
                end
            end
            
            % Ordenar y mostrar los IDs de mapa únicos
            mapIDs = unique(mapID);

            % computar las geometrias que van a servir para todos los episodes
            geometries = generateGeometriesFile(path, session_name); 
                
            for i = 1:length(mapIDs)

                % generar las señales de cada episode
                signals = generateSignalsAndMapsDataFile(path, session_name, mapIDs(i)); 

                % crear episode
                episode.geometries = geometries.geometries;
                episode.globalVariables = signals.globalVariables;
                episode.metada = signals.metadata;
                episode.segment = signals.segment;
        
                filename = fullfile(path, [session_name, '_episode_',num2str(mapIDs(i)), '.mat']);
                try
                    save(filename, 'episode');
                    disp(['Archivo guardado correctamente en: ', filename]);
                    clearvars episode
                catch ME
                    disp(['Error al guardar el archivo: ', ME.message]);
                end
            end 
        
        end 

    case 1 % Generate signals and maps data file, and geometries file appart

        if ~isempty(ID_map)

            episode = generateSignalsAndMapsDataFile(path, session_name, ID_map);  
            geometries = generateGeometriesFile(path, session_name); 
            geometries = geometries.geometries;

            mapfilename = fullfile(path, [session_name, '_map_',num2str(ID_map), '.mat']);
            geomfilename = fullfile(path, [session_name, '_geom.mat']);

            try
                save(mapfilename, 'episode');
                save(geomfilename, 'geometries');
                disp(['Archivos guardados correctamente en: ', path]);
            catch ME
                disp(['Error al guardar el archivo: ', ME.message]);
            end

        elseif isempty(ID_map)
            % Expresión regular para buscar el número N en el nombre de archivo
            pattern = '_\d+\.h';  % Busca un número seguido de .h (.h5 y .hd5) al final del nombre
        
            % Iterar sobre cada nombre de archivo
            n = 1;
            for i = 1:numel(filesNames)
                % Buscar el patrón en el nombre de archivo actual
                match = regexp(filesNames{i}, pattern, 'match');
            
                % Si se encontró un patrón válido, extraer el número y convertirlo a número
                if ~isempty(match)
                    % Extraer el número quitando el '_','.h' y convertirlo a número
                    mapID(n) = str2double(match{1}(2:end-2)); 
                    n = n+1;
                end
            end
            
            % Ordenar y mostrar los IDs de mapa únicos
            mapIDs = unique(mapID);

            for i = 1:length(mapIDs)
                episode = generateSignalsAndMapsDataFile(path, session_name, mapIDs(i));  

                mapfilename = fullfile(path, [session_name, '_map_',num2str(mapIDs(i)), '.mat']);
                try
                    save(mapfilename, 'episode');
                    disp(['Archivos guardados correctamente en: ', mapfilename]);
                catch ME
                    disp(['Error al guardar el archivo: ', ME.message]);
                end
            end 

            geometries = generateGeometriesFile(path, session_name); 
            geometries = geometries.geometries;
            geomfilename = fullfile(path, [session_name, '_geom.mat']);
            try
                save(geomfilename, 'geometries');
                disp(['Archivo guardado correctamente en: ', geomfilename]);
            catch ME
                disp(['Error al guardar el archivo: ', ME.message]);
            end

        end 

    case 2 % Generate geometries file only

        geometries = generateGeometriesFile(path, session_name); 
        geometries = geometries.geometries;
        geomfilename = fullfile(path, [session_name, '_geom.mat']);
         try
            save(geomfilename, 'geometries');
            disp(['Archivo guardado correctamente en: ', geomfilename]);
        catch ME
            disp(['Error al guardar el archivo: ', ME.message]);
        end

end
