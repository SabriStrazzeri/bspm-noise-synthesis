function episode = generateCompleteEpisodeF(path, session_name, ID_map)

    signals = generateSignalsAndMapsDataFile(path, session_name, ID_map);  
    geometries = generateGeometriesFile(path, session_name); 

    episode.geometries = geometries.geometries;
    episode.globalVariables = signals.globalVariables;
    episode.metada = signals.metadata;
    episode.segment = signals.segment;

end
