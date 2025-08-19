function episode = generateGeometriesFile(path, session_name)

% Convert .h5 estimated geometry file to .mat 
try
    try % file from acorys converter
        try
            geomEstimated_filename = [session_name, '_get_session_geometries.h5']; 
            path_geom = [path, '\', geomEstimated_filename];
            geometry_estimated = h5loadmod(path_geom); 
        catch
            geomEstimated_filename = [session_name, '_get_session_geometries.hd5'];
            path_geom = [path, '\', geomEstimated_filename];
            geometry_estimated = h5loadmod(path_geom); 
        end
    catch % file from HORTA
        geomEstimated_filename = [session_name, '_GEOMETRIES.h5']; 
        path_geom = [path, '\', geomEstimated_filename];
        geometry_estimated = h5loadmod(path_geom); 
    end

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



end 
