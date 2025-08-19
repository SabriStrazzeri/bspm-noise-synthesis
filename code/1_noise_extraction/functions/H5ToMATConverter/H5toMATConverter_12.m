classdef H5toMATConverter_12 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        IDselectionifonly1maptoconvertEditField  matlab.ui.control.NumericEditField
        IDselectionifonly1maptoconvertEditFieldLabel  matlab.ui.control.Label
        ConvertButton                  matlab.ui.control.Button
        SelectthefilestogenerateButtonGroup  matlab.ui.container.ButtonGroup
        GeomOnlyButton  matlab.ui.control.RadioButton
        GeomFileAppartButton  matlab.ui.control.RadioButton
        CompleteEpisodeButton  matlab.ui.control.RadioButton
        H5tomatconverterLabel          matlab.ui.control.Label
        SelectFolderButton             matlab.ui.control.Button
        SelectFolderLabel                  matlab.ui.control.Label
    end

    properties (Access = private)
        SelectedFolder       % Property to store the selected folder path
    end 

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 716 414];
            app.UIFigure.Name = 'MATLAB App';

            % Create SelectFolderButton
            app.SelectFolderButton = uibutton(app.UIFigure, 'push');
            app.SelectFolderButton.Position = [47 287 127 34];
            app.SelectFolderButton.Text = 'Select Folder';
            app.SelectFolderButton.ButtonPushedFcn = createCallbackFcn(app, @SelectFolderButtonPushed, true);

            % Create H5tomatconverterLabel
            app.H5tomatconverterLabel = uilabel(app.UIFigure);
            app.H5tomatconverterLabel.FontSize = 18;
            app.H5tomatconverterLabel.FontWeight = 'bold';
            app.H5tomatconverterLabel.Position = [47 336 435 44];
            app.H5tomatconverterLabel.Text = 'H5 to mat converter';

            % Create SelectthefilestogenerateButtonGroup
            app.SelectthefilestogenerateButtonGroup = uibuttongroup(app.UIFigure);
            app.SelectthefilestogenerateButtonGroup.Title = 'Select the files to generate';
            app.SelectthefilestogenerateButtonGroup.Position = [65 108 632 100];

            % Create CompleteEpisodeButton
            app.CompleteEpisodeButton = uiradiobutton(app.SelectthefilestogenerateButtonGroup);
            app.CompleteEpisodeButton.Text = 'Generate complete episode';
            app.CompleteEpisodeButton.Position = [11 45 169 22];
            app.CompleteEpisodeButton.Value = true;

            % Create GeomFileAppartButton
            app.GeomFileAppartButton = uiradiobutton(app.SelectthefilestogenerateButtonGroup);
            app.GeomFileAppartButton.Text = 'Generate signals and maps data file, and geometries file appart';
            app.GeomFileAppartButton.Position = [11 24 369 22];

            % Create GeomOnlyButton
            app.GeomOnlyButton = uiradiobutton(app.SelectthefilestogenerateButtonGroup);
            app.GeomOnlyButton.Text = 'Generate geometries file only';
            app.GeomOnlyButton.Position = [11 1 179 22];

            % Create PathnameLabel
            app.SelectFolderLabel = uilabel(app.UIFigure);
            app.SelectFolderLabel.Position = [186 287 361 33];
            app.SelectFolderLabel.Text = '';

            % Create IDselectionifonly1maptoconvertEditFieldLabel
            app.IDselectionifonly1maptoconvertEditFieldLabel = uilabel(app.UIFigure);
            app.IDselectionifonly1maptoconvertEditFieldLabel.HorizontalAlignment = 'right';
            app.IDselectionifonly1maptoconvertEditFieldLabel.Position = [76 236 197 22];
            app.IDselectionifonly1maptoconvertEditFieldLabel.Text = 'ID selection if only 1 map to convert';

            % Create IDselectionifonly1maptoconvertEditField
            app.IDselectionifonly1maptoconvertEditField = uieditfield(app.UIFigure, 'numeric');
            app.IDselectionifonly1maptoconvertEditField.Position = [288 236 34 22];
            app.IDselectionifonly1maptoconvertEditField.AllowEmpty = "on";
            app.IDselectionifonly1maptoconvertEditField.Value = [];

            % Create ConvertButton
            app.ConvertButton = uibutton(app.UIFigure, 'push');
            app.ConvertButton.Position = [47 43 127 34];
            app.ConvertButton.Text = 'Convert';
            app.ConvertButton.ButtonPushedFcn = createCallbackFcn(app, @ConvertButtonPushed, true);

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: SelectFolderButton
        %--------------------------------------------
        function SelectFolderButtonPushed(app, event)
            folder = uigetdir;
            if folder ~= 0
                app.SelectedFolder = folder;
                app.SelectFolderLabel.Text = app.SelectedFolder;
                disp(['Selected Folder: ', app.SelectedFolder]);
            else
                disp('Folder selection canceled.');
            end
        end

        % Button pushed function: ConvertButton
        % Generate complete episode
        %---------------------------------------
        function ConvertButtonPushed(app, event)
            if app.CompleteEpisodeButton.Value
                % Aquí debes implementar la lógica para guardar el archivo .mat
                path = app.SelectedFolder;

                cd(path)

                filesTable_h5 = dir('*.h5'); filesNames_h5 = {filesTable_h5.name}; 
                filesTable_hd5 = dir('*.hd5'); filesNames_hd5 = {filesTable_hd5.name}; 
                filesNames = [filesNames_h5, filesNames_hd5];
                fileName = filesNames{1}; 
                
                get_index = strsplit(fileName, '_');
                session_name = [get_index{1}, '_', get_index{2}];
                
                ID_map = app.IDselectionifonly1maptoconvertEditField.Value; 

                % Supuesto 1 mapa para exportar con estructura de episode completa
                if ~isempty(ID_map)

                    episode = generateCompleteEpisodeF(path, session_name, ID_map); 

                    filename = fullfile(app.SelectedFolder, [session_name, '_episode_',num2str(ID_map), '.mat']);
                    try
                        save(filename, 'episode');
                        disp(['Archivo guardado correctamente en: ', filename]);
                    catch ME
                        disp(['Error al guardar el archivo: ', ME.message]);
                    end

                elseif isempty(ID_map)
                    % Expresión regular para buscar el número N en el nombre de archivo
                    pattern = '_\d+\.h';  % Busca un número seguido de .h5 al final del nombre

                    % Iterar sobre cada nombre de archivo
                    n=1;
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

                    fw = waitbar(0,'Please wait...');

                    for i = 1:length(mapIDs)
                        episode = generateCompleteEpisodeF(path, session_name, mapIDs(i)); 

                        filename = fullfile(app.SelectedFolder, [session_name, '_episode_',num2str(mapIDs(i)), '.mat']);
                        try
                            save(filename, 'episode');
                            disp(['Archivo guardado correctamente en: ', filename]);
                        catch ME
                            disp(['Error al guardar el archivo: ', ME.message]);
                        end
                        waitbar(i/length(mapIDs),fw);
                    end 

                end 

            elseif app.GeomFileAppartButton.Value
                path = app.SelectedFolder;

                cd(path)

                filesTable_h5 = dir('*.h5'); filesNames_h5 = {filesTable_h5.name}; 
                filesTable_hd5 = dir('*.hd5'); filesNames_hd5 = {filesTable_hd5.name}; 
                filesNames = [filesNames_h5, filesNames_hd5];
                fileName = filesNames{1}; 
                
                get_index = strsplit(fileName, '_');
                session_name = [get_index{1}, '_', get_index{2}];
                
                ID_map = app.IDselectionifonly1maptoconvertEditField.Value; 

                % Supuesto 1 mapa para exportar mapas y señales en un archivo, y geometrías en otro
                if ~isempty(ID_map)

                    episode = generateSignalsAndMapsDataFile(path, session_name, ID_map);  
                    geometries = generateGeometriesFile(path, session_name); 
                    geometries = geometries.geometries;

                    mapfilename = fullfile(app.SelectedFolder, [session_name, '_map_',num2str(ID_map), '.mat']);
                    geomfilename = fullfile(app.SelectedFolder, [session_name, '_geom.mat']);

                    try
                        save(mapfilename, 'episode');
                        save(geomfilename, 'geometries');
                        disp(['Archivos guardados correctamente en: ', path]);
                    catch ME
                        disp(['Error al guardar el archivo: ', ME.message]);
                    end

                elseif isempty(ID_map)
                    % Expresión regular para buscar el número N en el nombre de archivo
                    pattern = '_\d+\.h';  % Busca un número seguido de .h5 al final del nombre

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

                    fw = waitbar(0,'Please wait...');

                    for i = 1:length(mapIDs)
                        episode = generateSignalsAndMapsDataFile(path, session_name, mapIDs(i));  

                        mapfilename = fullfile(app.SelectedFolder, [session_name, '_map_',num2str(mapIDs(i)), '.mat']);
                        try
                            save(mapfilename, 'episode');
                            disp(['Archivos guardados correctamente en: ', mapfilename]);
                        catch ME
                            disp(['Error al guardar el archivo: ', ME.message]);
                        end
                        waitbar(i/length(mapIDs),fw);
                    end 

                    geometries = generateGeometriesFile(path, session_name); 
                    geometries = geometries.geometries;
                    geomfilename = fullfile(app.SelectedFolder, [session_name, '_geom.mat']);
                    try
                        save(geomfilename, 'geometries');
                        disp(['Archivo guardado correctamente en: ', geomfilename]);
                    catch ME
                        disp(['Error al guardar el archivo: ', ME.message]);
                    end

                end 
               
            elseif app.GeomOnlyButton.Value
                path = app.SelectedFolder;

                cd(path)

                try
                    filesTable_h5 = dir('*.h5'); filesNames_h5 = {filesTable_h5.name}; 
                    filesTable_hd5 = dir('*.hd5'); filesNames_hd5 = {filesTable_hd5.name}; 
                    filesNames = [filesNames_h5, filesNames_hd5];
                    fileName = filesNames{1}; 
                    get_index = strsplit(fileName, '_');
                    session_name = [get_index{1}, '_', get_index{2}];
                catch
                    session_name = 'session'; 
                end 

                geometries = generateGeometriesFile(path, session_name); 
                geometries = geometries.geometries;
                geomfilename = fullfile(app.SelectedFolder, [session_name, '_geom.mat']);
                 try
                    save(geomfilename, 'geometries');
                    disp(['Archivo guardado correctamente en: ', geomfilename]);
                catch ME
                    disp(['Error al guardar el archivo: ', ME.message]);
                end
            end
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = H5toMATConverter

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
