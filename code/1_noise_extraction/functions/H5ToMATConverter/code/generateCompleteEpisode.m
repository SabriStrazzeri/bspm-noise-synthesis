function episode = generateCompleteEpisode(path, session_name, ID_map)

% Convert .h5/.hd5 map file to .mat 
try
    try % file from acorys converter
        try
            map_filename = [session_name, '_get_map_model_', num2str(ID_map), '.h5'];
        catch
            map_filename = [session_name, '_get_map_model_', num2str(ID_map), '.hd5'];
        end
    catch % file from HORTA
        map_filename = [session_name, '_MAP_', num2str(ID_map), '.h5'];
    end
   
    path_map = [path,'\', map_filename];
    map = h5loadmod(path_map);
    
    disp(['Map name: ', map.bbdindex.Name])

    fileMap = 1; 
catch
    fileMap = 0; 
end 

% Convert .h5/.hd5 signals file to .mat 
try
    try % file from acorys converter
        try
            signals_filename = [session_name, '_get_signals_from_mapID_', num2str(ID_map), '.h5']; 
        catch
            signals_filename = [session_name, '_get_signals_from_mapID_', num2str(ID_map), '.hd5']; 
        end
    catch % file from HORTA
        signals_filename = [session_name, '_SIGNALS_MAP_', num2str(ID_map), '.h5']; 
    end
    path_signals = [path, '\',signals_filename];
    signals = h5loadmod(path_signals);

    fileSignals = 1; 
catch
    fileSignals = 0; 
end 

% Convert .h5/.hd5 estimated geometry file to .mat 
try
    try % file from acorys converter
        try
            geomEstimated_filename = [session_name, '_get_session_geometries.h5']; 
        catch
            geomEstimated_filename = [session_name, '_get_session_geometries.hd5']; 
        end
    catch % file from HORTA
        geomEstimated_filename = [session_name, '_GEOMETRIES.h5']; 
    end
    path_geom = [path, '\', geomEstimated_filename];
    geometry_estimated = h5loadmod(path_geom); 

    fileGeomEstimated = 1; 
catch
    fileGeomEstimated = 0; 
end 

% Convert .hd5 personalized geometry file to .mat 
try
    geomPersonalized_filename = 'geometry.hd5'; 
    path_geom = [path, '\', geomPersonalized_filename];
    geometryH5_personalized = h5loadmod(path_geom); % read personalized geometry
    geometry_personalized   = parseAcorysBinGeom(geometryH5_personalized);   % parse personalized geometry

    fileGeomPersonalized = 1; 
catch
    fileGeomPersonalized = 0; 
end 

%% GEOMETRIES
%--------------------------------------------------------------------------

%% Personalized geometries
if fileGeomPersonalized == 1

    % Atria
    if fieldnames(geometry_personalized) == "atria"
        episode.geometries.heart.atria.personalizedGeometry = parsePersonalizedAtria(geometry_personalized);   
    else
        episode.geometries.heart.atria.personalizedGeometry = [];  
    end 
    
    % Ventricles 
    if fieldnames(geometry_personalized) == "ventricle"
        episode.geometries.heart.ventricles.personalizedGeometry = parsePersonalizedVentricle(geometry_personalized);
    else 
        episode.geometries.heart.ventricles.personalizedGeometry = []; 
    end 
    
else 
    episode.geometries.heart.atria.personalizedGeometry = [];
    episode.geometries.heart.ventricles.personalizedGeometry = []; 
end 
    
%% Shape model geometries

if fileGeomEstimated == 1
    
    % Atria
    episode.geometries.heart.atria.shapeModel = parseEstimatedAtria(geometry_estimated);  

    % Ventricles
    episode.geometries.heart.ventricles.shapeModel = parseEstimatedVentricles(geometry_estimated);  

    % Torso geometries 
    episode.geometries.torso = parseTorsoGeometry(geometry_estimated); 
    
    % Transfer matrix   
    episode.geometries.transferMatrix = parseTransferMatrix(geometry_estimated); 

else
    episode.geometries.heart.atria.shapeModel = [];
    episode.geometries.heart.ventricles.shapeModel = [];
    episode.geometries.torso= [];
    episode.geometries.transferMatrix = [];
end 


%% Global variables 
%----------------------------------------------------------------------
episode.globalVariables.fs = 1000; 

if fileMap == 1
    episode.globalVariables.leadStatus = double(map.mapmodel.Map1.LeadSelection); 
else 
    episode.globalVariables.leadStatus = []; 
end 

if fileSignals == 1
    episode.globalVariables.WCT3 = signals.ctws;
    episode.globalVariables.WCTall = find(episode.globalVariables.leadStatus == 1);
else 
    episode.globalVariables.WCT3 = []; 
    episode.globalVariables.WCTall = []; 
end 



%% Metadata
%----------------------------------------------------------------------
% Versions
episode.metadata.versions.ACSOFversion = 'ACSOF 1.1';              % (no lo devuelve ACORYS)
episode.metadata.versions.ACSENversion = 'ACSEN 0.9';               % (no lo devuelve ACORYS)
episode.metadata.versions.ACSCANversion = 'ACSCAN 0.9';             % (no lo devuelve ACORYS)
episode.metadata.versions.ACAMPversion = 'ACAMP 0.9';               % (no lo devuelve ACORYS)
episode.metadata.versions.FIRMWAREversion = 'Firmware 0.9';         % (no lo devuelve ACORYS)
episode.metadata.versions.SHAPEMODELversion = 'Shape Model 0.9';    % (no lo devuelve ACORYS)
episode.metadata.versions.ChannelMapping = [];                      % Esto diría que es un vector (no lo devuelve ACORYS)
episode.metadata.versions.ITACArelease = 'ITACA v1';                % (no lo devuelve ACORYS)

% Date 
if fileMap == 1
    episode.metadata.date.registerDate = [];  % (no lo devuelve ACORYS)
    episode.metadata.date.analysisDate = map.mapmodel.date; 
else 
    episode.metadata.date.registerDate = [];  
    episode.metadata.date.analysisDate = []; 
end 

% Patient data
episode.metadata.patientData.age = [];              % (no lo devuelve ACORYS)
episode.metadata.patientData.sex = [];             % (no lo devuelve ACORYS)
episode.metadata.patientData.clinicalData = [];      % (no lo devuelve ACORYS)
episode.metadata.patientData.patientID = session_name;    % (no lo devuelve ACORYS)


%% BSPM segment
%----------------------------------------------------------------------

if fileMap == 1
    % menuString = "\n\n" +...
    % "Type of analysis:\n"+ ...
    % "1:  Single beat analysis\n" +...
    % "2:  Average beat analysis\n" +...
    % "3:  Irregular rhythm analysis\n";
    % 
    % analysisType = displaymenuline(menuString, [1,2,3]);
    
    analysisType = map.mapmodel.Map1.mapType; 
    
    if isempty(map.mapmodel.Map1)
        mapAtria = 0; 
    else
        mapAtria = 1; 
    end 
    
    if isempty(map.mapmodel.Map2)
        mapVentricles = 0; 
    else
        mapVentricles = 1; 
    end 


    switch(analysisType)
        case 'MapSingleBeat'
            % BSPM Single beat 
            if mapAtria == 1
                episode.segment.bspm.singleBeatAnalysis.voltage = map.mapmodel.Map1.ECGData(1:128,:);                    % segmento de ECG filtrado de la señal de 1 min
                episode.segment.bspm.singleBeatAnalysis.idxVoltage = [typecast(single(map.mapmodel.Map1.ECGData(129,1)), 'uint32'), typecast(single(map.mapmodel.Map1.ECGData(129,end)), 'uint32')];          
                episode.segment.bspm.singleBeatAnalysis.idxPwave = [map.mapmodel.Map1.QRSon, map.mapmodel.Map1.QRSoff];
            else
                episode.segment.bspm.singleBeatAnalysis.voltage = []; 
                episode.segment.bspm.singleBeatAnalysis.idxVoltage = [];   
                episode.segment.bspm.singleBeatAnalysis.idxPwave = [];
            end 
    
            if mapVentricles == 1
                 episode.segment.bspm.singleBeatAnalysis.voltage = map.mapmodel.Map2.ECGData(1:128,:);                    % segmento de ECG filtrado de la señal de 1 min
                 episode.segment.bspm.singleBeatAnalysis.idxVoltage = [typecast(single(map.mapmodel.Map2.ECGData(129,1)), 'uint32'), typecast(single(map.mapmodel.Map2.ECGData(129,end)), 'uint32')]; 
                 episode.segment.bspm.singleBeatAnalysis.idxQRScomplex = [map.mapmodel.Map2.QRSon, map.mapmodel.Map2.QRSoff]; 
                 episode.segment.bspm.singleBeatAnalysis.idxTwave = [];  % no lo exporta ACORYS
            else 
                episode.segment.bspm.singleBeatAnalysis.idxQRScomplex = [];   
                episode.segment.bspm.singleBeatAnalysis.idxTwave = [];
            end 
    
            episode.segment.bspm.singleBeatAnalysis.idxEvent = map.mapmodel.BeatEventID; 
    
            episode.segment.bspm.averageBeatAnalysis = []; 
            episode.segment.bspm.irregularRhythmAnalysis = []; 
    
    
        case 'MapAverageBeat'
            % BSPM Average beat
            if mapAtria == 1
                episode.segment.bspm.averageBeatAnalysis.voltage = [];                                              % segmento de ECG filtrado de la señal de 1 min (no lo devuelve ACORYS)
                episode.segment.bspm.averageBeatAnalysis.idxVoltage = [];                                           % idx del segmento respecto de la señal raw (no lo devuelve ACORYS)          
                episode.segment.bspm.averageBeatAnalysis.voltageAverage = map.mapmodel.Map1.ECGData(1:128,:);            % ECG promediado (no tengo un ejemplo, pero recorto un latido a modo de promedio)
                episode.segment.bspm.averageBeatAnalysis.idxAverage = [1, length(map.mapmodel.Map1.ECGData(1:128,:))];   % idx del tramo del segmento de ECG para calcular el promedio  
                episode.segment.bspm.averageBeatAnalysis.idxPwave = [map.mapmodel.Map1.QRSon, map.mapmodel.Map1.QRSoff];
            else
                episode.segment.bspm.averageBeatAnalysis.voltage = []; 
                episode.segment.bspm.averageBeatAnalysis.idxVoltage = [];   
                episode.segment.bspm.averageBeatAnalysis.idxPwave = [];
            end 
    
            if mapVentricles == 1
                episode.segment.bspm.averageBeatAnalysis.voltage = [];                                              % segmento de ECG filtrado de la señal de 1 min (no lo devuelve ACORYS)
                episode.segment.bspm.averageBeatAnalysis.idxVoltage = [];                                           % idx del segmento respecto de la señal raw (no lo devuelve ACORYS)          
                episode.segment.bspm.averageBeatAnalysis.voltageAverage = map.mapmodel.Map2.ECGData(1:128,:);            % ECG promediado (no tengo un ejemplo, pero recorto un latido a modo de promedio)
                episode.segment.bspm.averageBeatAnalysis.idxAverage = [];                                           % idx del tramo del segmento de ECG para calcular el promedio  
                episode.segment.bspm.averageBeatAnalysis.idxQRScomplex = [map.mapmodel.Map2.QRSon, map.mapmodel.Map2.QRSoff]; 
                episode.segment.bspm.averageBeatAnalysis.idxTwave = [];                                             % no lo devuelve ACORYS
            else
                episode.segment.bspm.averageBeatAnalysis.idxQRScomplex = []; 
                episode.segment.bspm.averageBeatAnalysis.idxTwave = [];
            end 
    
            episode.segment.bspm.averageBeatAnalysis.idxEvent = map.mapmodel.BeatEventID; 
    
            episode.segment.bspm.singleBeatAnalysis = []; 
            episode.segment.bspm.irregularRhythmAnalysis = []; 
    
        case 'MapIrregular'
            % BSPM Irregular rhythm
            episode.segment.bspm.irregularRhythmAnalyis.voltage = map.mapmodel.Map1.ECGData(1:128,:);          
            episode.segment.bspm.irregularRhythmAnalyis.idxVoltage = [typecast(single(map.mapmodel.Map1.ECGData(129,1)), 'uint32'), typecast(single(map.mapmodel.Map1.ECGData(129,end)), 'uint32')]; 
            episode.segment.bspm.irregularRhythmAnalyis.voltageAtrialActivity = [];                             % no lo devuelve ACORYS
            episode.segment.bspm.irregularRhythmAnalyis.idxAtrialActivity = [];                                 % no lo devuelve ACORYS
            episode.segment.bspm.irregularRhythmAnalyis.idxEvent = map.mapmodel.BeatEventID; 
    
            episode.segment.bspm.singleBeatAnalysis = []; 
            episode.segment.bspm.averageBeatAnalysis = []; 
    
    end 
else
    episode.segment.bspm = []; 
end 


%% ECGi segment
%----------------------------------------------------------------------
if fileMap == 1

    switch(analysisType)
        case 'MapSingleBeat'
            % ECGi single beat analysis
            if mapAtria == 1
                episode.segment.ecgi.singleBeatAnalysis.atria.voltage = map.mapmodel.Map1.ECGI; 
                episode.segment.ecgi.singleBeatAnalysis.atria.activationTimes.values = map.mapmodel.Map1.ActivationTimes.Values; 
                episode.segment.ecgi.singleBeatAnalysis.atria.activationTimes.maxLAT = max(episode.segment.ecgi.singleBeatAnalysis.atria.activationTimes.values); 
                if iscell(map.mapmodel.Map1.ConductionVelocity.Values)
                    episode.segment.ecgi.singleBeatAnalysis.atria.conductionVelocity.values = str2double(map.mapmodel.Map1.ConductionVelocity.Values);          % No sé si es la variable values o originalValues
                else
                    episode.segment.ecgi.singleBeatAnalysis.atria.conductionVelocity.values = (map.mapmodel.Map1.ConductionVelocity.Values);
                end 
                episode.segment.ecgi.singleBeatAnalysis.atria.conductionVelocity.meanCV = mean(episode.segment.ecgi.singleBeatAnalysis.atria.conductionVelocity.values); 
                episode.segment.ecgi.singleBeatAnalysis.atria.ectopicMap = [];              % no lo devuelve ACORYS, pero serán = size(LATS)
            else
                episode.segment.ecgi.singleBeatAnalysis.atria.voltage = []; 
                episode.segment.ecgi.singleBeatAnalysis.atria.activationTimes.values = []; 
                episode.segment.ecgi.singleBeatAnalysis.atria.activationTimes.maxLAT = []; 
                episode.segment.ecgi.singleBeatAnalysis.atria.conductionVelocity.values = []; 
                episode.segment.ecgi.singleBeatAnalysis.atria.conductionVelocity.meanCV = []; 
                episode.segment.ecgi.singleBeatAnalysis.atria.ectopicMap = []; 
            end 
    
            if mapVentricles == 1
                episode.segment.ecgi.singleBeatAnalysis.ventricles.voltage = map.mapmodel.Map2.ECGI; 
                episode.segment.ecgi.singleBeatAnalysis.ventricles.activationTimes.values = map.mapmodel.Map2.ActivationTimes.Values; 
                episode.segment.ecgi.singleBeatAnalysis.ventricles.activationTimes.maxLAT = max(episode.segment.ecgi.singleBeatAnalysis.ventricles.activationTimes.values);  
                if iscell(map.mapmodel.Map2.ConductionVelocity.Values)
                    episode.segment.ecgi.singleBeatAnalysis.ventricles.conductionVelocity.values = str2double(map.mapmodel.Map2.ConductionVelocity.Values);          % No sé si es la variable values o originalValues
                else
                    episode.segment.ecgi.singleBeatAnalysis.ventricles.conductionVelocity.values = (map.mapmodel.Map2.ConductionVelocity.Values);
                end 
                episode.segment.ecgi.singleBeatAnalysis.ventricles.conductionVelocity.meanCV = mean(episode.segment.ecgi.singleBeatAnalysis.ventricles.conductionVelocity.values); 
                episode.segment.ecgi.singleBeatAnalysis.ventricles.ectopicMap = [];              % no lo devuelve ACORYS, pero serán = size(LATS)
            else
                episode.segment.ecgi.singleBeatAnalysis.ventricles.voltage = []; 
                episode.segment.ecgi.singleBeatAnalysis.ventricles.activationTimes.values = []; 
                episode.segment.ecgi.singleBeatAnalysis.ventricles.activationTimes.maxLAT = []; 
                episode.segment.ecgi.singleBeatAnalysis.ventricles.conductionVelocity.values = []; 
                episode.segment.ecgi.singleBeatAnalysis.ventricles.conductionVelocity.meanCV = []; 
                episode.segment.ecgi.singleBeatAnalysis.ventricles.ectopicMap = []; 
            end 
    
            episode.segment.ecgi.averageBeatAnalysis = []; 
            episode.segment.ecgi.irregularRhythmAnalysis = []; 
    
        
        case 'MapAverageBeat'
            % ECGi average beat analysis
            if mapAtria == 1
                episode.segment.ecgi.averageBeatAnalysis.atria.voltage = map.mapmodel.Map1.ECGI; 
                episode.segment.ecgi.averageBeatAnalysis.atria.activationTimes.values = map.mapmodel.Map1.ActivationTimes.Values; 
                episode.segment.ecgi.averageBeatAnalysis.atria.activationTimes.maxLAT = max(episode.segment.ecgi.averageBeatAnalysis.atria.activationTimes.values);    
                if iscell(map.mapmodel.Map1.ConductionVelocity.Values)
                    episode.segment.ecgi.averageBeatAnalysis.atria.conductionVelocity.values = str2double(map.mapmodel.Map1.ConductionVelocity.Values);          % No sé si es la variable values o originalValues
                else
                    episode.segment.ecgi.averageBeatAnalysis.atria.conductionVelocity.values = (map.mapmodel.Map1.ConductionVelocity.Values);
                end 
                episode.segment.ecgi.averageBeatAnalysis.atria.conductionVelocity.meanCV = mean(episode.segment.ecgi.averageBeatAnalysis.atria.conductionVelocity.values); 
                episode.segment.ecgi.averageBeatAnalysis.atria.ectopicMap = [];              % no lo devuelve ACORYS, pero serán = size(LATS)
            else
                episode.segment.ecgi.averageBeatAnalysis.atria.voltage = []; 
                episode.segment.ecgi.averageBeatAnalysis.atria.activationTimes.values = [];
                episode.segment.ecgi.averageBeatAnalysis.atria.activationTimes.maxLAT = []; 
                episode.segment.ecgi.averageBeatAnalysis.atria.conductionVelocity.values = []; 
                episode.segment.ecgi.averageBeatAnalysis.atria.conductionVelocity.meanCV = []; 
                episode.segment.ecgi.averageBeatAnalysis.atria.ectopicMap = []; 
            end 
            
            if mapVentricles == 1
                episode.segment.ecgi.averageBeatAnalysis.ventricles.voltage = map.mapmodel.Map2.ECGI; 
                episode.segment.ecgi.averageBeatAnalysis.ventricles.activationTimes.values = map.mapmodel.Map2.ActivationTimes.Values; 
                episode.segment.ecgi.averageBeatAnalysis.ventricles.activationTimes.maxLAT = max(episode.segment.ecgi.averageBeatAnalysis.ventricles.activationTimes.values); 
                if iscell(map.mapmodel.Map2.ConductionVelocity.Values)
                    episode.segment.ecgi.averageBeatAnalysis.ventricles.conductionVelocity.values = str2double(dataMap.Map2.ConductionVelocity.Values);          % No sé si es la variable values o originalValues
                else
                    episode.segment.ecgi.averageBeatAnalysis.ventricles.conductionVelocity.values = (map.mapmodel.Map2.ConductionVelocity.Values);
                end 
                episode.segment.ecgi.averageBeatAnalysis.ventricles.conductionVelocity.meanCV = mean(episode.segment.ecgi.averageBeatAnalysis.ventricles.conductionVelocity.values);                         
                episode.segment.ecgi.averageBeatAnalysis.ventricles.ectopicMap = [];              % no lo devuelve ACORYS, pero serán = size(LATS)
            else 
                episode.segment.ecgi.averageBeatAnalysis.ventricles.voltage = []; 
                episode.segment.ecgi.averageBeatAnalysis.ventricles.activationTimes.values = []; 
                episode.segment.ecgi.averageBeatAnalysis.ventricles.activationTimes.maxLAT = []; 
                episode.segment.ecgi.averageBeatAnalysis.ventricles.conductionVelocity.values = []; 
                episode.segment.ecgi.averageBeatAnalysis.ventricles.conductionVelocity.meanCV = []; 
                episode.segment.ecgi.averageBeatAnalysis.ventricles.ectopicMap = []; 
            end 
    
            episode.segment.ecgi.singleBeatAnalysis = []; 
            episode.segment.ecgi.irregularRhythmAnalysis = []; 
    
        
        case 'MapIrregular'
            % ECGi irregular rhythm analysis
            episode.segment.ecgi.irregularRhythmAnalysis.atria.voltage = map.mapmodel.Map1.ECGI;  
            episode.segment.ecgi.irregularRhythmAnalysis.atria.phase = [];                             
            episode.segment.ecgi.irregularRhythmAnalysis.atria.rotorHistogram.values = map.mapmodel.Map1.Rotorhistogram.OriginalValues;             
            episode.segment.ecgi.irregularRhythmAnalysis.atria.dominantFrequency.DF = [];
            episode.segment.ecgi.irregularRhythmAnalysis.atria.dominantFrequency.HDF = [];
            episode.segment.ecgi.irregularRhythmAnalysis.atria.dominantFrequency.meanDF = [];
            episode.segment.ecgi.irregularRhythmAnalysis.atria.dominantFrequency.stdDF = [];
            episode.segment.ecgi.irregularRhythmAnalysis.atria.burdenHistogram.BH = [];
            episode.segment.ecgi.irregularRhythmAnalysis.atria.burdenHistogram.BH_DFs = [];

            episode.segment.ecgi.singleBeatAnalysis = []; 
            episode.segment.ecgi.averageBeatAnalysis = []; 
    
    end 

else
    episode.segment.ecgi = []; 
end 


if fileSignals == 1

    %% BSPM segment
    %----------------------------------------------------------------------
    % Raw BSPM 
    episode.segment.bspm.rawVoltage.rawVoltage = signals.DataRaw(1:128,:); 
    episode.segment.bspm.rawVoltage.filteredVoltage = signals.DataFiltered(1:128,:); 
    episode.segment.bspm.rawVoltage.counter = typecast(single(signals.DataFiltered(129,:)), 'uint32'); % (no lo devuelve ACORYS)

    try

        episode.segment.bspm.rawVoltage.lowerBound = signals.LowerBound;
        episode.segment.bspm.rawVoltage.upperBound = signals.UpperBound;

    catch

    end


end 

end 
