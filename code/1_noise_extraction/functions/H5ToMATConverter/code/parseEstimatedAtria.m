function shapeModel = parseEstimatedAtria(geometry_estimated)    

    % Atrial auxiliar Structures
    %----------------------------------------------------------------------
    shapeModel.auxiliarStructures.description = 'Cardiac auxiliar structures'; 
    shapeModel.auxiliarStructures.vertices = geometry_estimated.Atria.AuxiliarStructures.Vertices.Vertices; 
    shapeModel.auxiliarStructures.faces = double(geometry_estimated.Atria.AuxiliarStructures.Faces.Faces) + 1; 
    shapeModel.auxiliarStructures.tags = geometry_estimated.Atria.AuxiliarStructures.Tags; 
    shapeModel.auxiliarStructures.descriptions = geometry_estimated.Atria.AuxiliarStructures.Descriptions; 
    shapeModel.auxiliarStructures.faceTypes.original = double(geometry_estimated.Atria.AuxiliarStructures.FaceTypes) + 1; 

    labelsOriginal = readStructWithFields(shapeModel.auxiliarStructures.tags, 'Atria'); 
    labelsStandardized = {'LSPV', 'LIPV', 'RSPV', 'RIPV', 'SVC', 'IVC'}; 
    labelsStandardizedDescription = {'Left Superior Pulmonary Vein', 'Left Inferior Pulmonary Vein', 'Right Superior Pulmonary Vein', 'Right Inferior Pulmonary Vein', 'Superior Vena Cava', 'Inferior Vena Cava'}; 
    [nodeTypes_auxStructuresStandardized, faceTypes_auxStructuresStandardized, labelsOriginalDescription, indices] = standardizeLabelsAtria(labelsOriginal, labelsStandardized, shapeModel.auxiliarStructures.faces, shapeModel.auxiliarStructures.faceTypes.original, labelsStandardizedDescription); 
    
    shapeModel.auxiliarStructures.faceTypes.standardized = faceTypes_auxStructuresStandardized'; 
    shapeModel.auxiliarStructures.nodeTypes.original = labels_faces2vertices(shapeModel.auxiliarStructures.faces, shapeModel.auxiliarStructures.faceTypes.original);
    shapeModel.auxiliarStructures.nodeTypes.standardized = nodeTypes_auxStructuresStandardized;
    shapeModel.auxiliarStructures.labels.labelsOriginal = labelsOriginal; 
    shapeModel.auxiliarStructures.labels.labelsStandardized = labelsStandardized; 
    shapeModel.auxiliarStructures.labels.labelsOriginalDescription = labelsOriginalDescription; 
    shapeModel.auxiliarStructures.labels.labelsStandardizedDescription = labelsStandardizedDescription;

    shapeModel.auxiliarStructures.labels.mappingOriginalToStandardized = indices; 
    shapeModel.auxiliarStructures.keyType = geometry_estimated.Atria.AuxiliarStructures.KeyType+1; 
    
    % Atrial closed geometry
    %----------------------------------------------------------------------
    shapeModel.closedGeometry.description = 'Complete conformal geometry returned by core'; 
    shapeModel.closedGeometry.faces = double(geometry_estimated.Atria.ClosedGeometry.Faces.Faces) + 1; 
    shapeModel.closedGeometry.vertices.originalVertices = geometry_estimated.Atria.ClosedGeometry.OriginalVertices.Vertices; 
    shapeModel.closedGeometry.vertices.smoothedVertices = geometry_estimated.Atria.ClosedGeometry.SmoothedVertices.Vertices; 
    shapeModel.closedGeometry.vertices.movedVertices = geometry_estimated.Atria.ClosedGeometry.MovedVertices.Vertices;       % Sale vacío en shape
    shapeModel.closedGeometry.vertices.smoothedAndMovedVertices = geometry_estimated.Atria.ClosedGeometry.SmoothedAndMovedVertices.Vertices; 
    
    % Atrial holey geometry
    %----------------------------------------------------------------------
    shapeModel.holeyGeometry.description = 'Geometry with holes, used for calculation';
    shapeModel.holeyGeometry.faces = double(geometry_estimated.Atria.HoleyGeometry.Faces.Faces) + 1; 
    shapeModel.holeyGeometry.vertices.visualVertices = geometry_estimated.Atria.HoleyGeometry.VisualVertices.Vertices;  
    shapeModel.holeyGeometry.vertices.smoothedVertices = geometry_estimated.Atria.HoleyGeometry.SmoothedVertices.Vertices; 
    shapeModel.holeyGeometry.caps.vertices = geometry_estimated.Atria.HoleyGeometry.Caps.Vertices.Vertices; 
    shapeModel.holeyGeometry.caps.faces = double(geometry_estimated.Atria.HoleyGeometry.Caps.Faces.Faces) + 1; 
    
    % Atrial holey to closed
    %----------------------------------------------------------------------
    shapeModel.holeyToClosed.description = 'Relates the indices of the vertices of the holed geometry with the indices of the vertices of the closed geometry';
    shapeModel.holeyToClosed.faces = double(geometry_estimated.Atria.MapVectors.HoleyFacesToFilledFaces); 
    shapeModel.holeyToClosed.vertices = double(geometry_estimated.Atria.MapVectors.HoleyVerticesToFilledVertices); 
    
    % Atrial conformal mapping
    %----------------------------------------------------------------------
    shapeModel.conformalMapping.description = 'Variables to conformalize the geometry';
    shapeModel.conformalMapping.mappingConformalVertices = double(geometry_estimated.Atria.MappingConformalVertices); 
    shapeModel.conformalMapping.activeVertexForConformal = double(geometry_estimated.Atria.ActiveVertexForConformal); 
    shapeModel.conformalMapping.imageSize = geometry_estimated.Atria.ImageSizeConformal; 
    
    % Atrial regions
    %----------------------------------------------------------------------
    labelsOriginal = readStructWithFields(geometry_estimated.Atria.Regions.region0.Tags, 'Atria'); 

    if length(labelsOriginal) == 23

        % Original labels organized with standarized labels
        labelsOriginal_ordered = {'RA_REGION0', 'RA_REGION05', 'RA_REGION04', 'RA_REGION03', 'RA_REGION02', 'RA_REGION06', 'RA_REGION08', 'LAA', 'LA_REGION09', 'LA_REGION10', 'LA_REGION08', 'LA_REGION04', 'LA_REGION07', ...
            'LA_REGION11', 'LA_REGION06', 'LA_REGION13', 'LA_REGION02', 'LA_REGION03', 'LA_REGION05', 'LA_REGION01', 'LA_REGION12', 'RA_REGION07', 'RA_REGION01'};
        labelsStandardized = {'AUX_STRUCT', 'RA_VEST', 'RA_VECO', 'RA_LW', 'RAA', 'RA_CTI', 'RA_CSOS', 'LAA', 'LA_RSAW', 'LA_RIAW', 'LA_LSAW', 'LA_LIAW', 'LA_LSPW', ...
            'LA_RSPW', 'LA_LIPW', 'LA_RIPW','LA_LFPW', 'LA_RFPW', 'LA_MI', 'LA_RDG', 'LA_SEPWL', 'RA_SEPWL', 'RA_CS'}; 
    
        labelsStandardizedDescription = {'Auxiliar Structures', 'RA vestibule', 'RA venous component', 'RA lateral wall', ...
            'RA appendage', 'RA cavotricuspid isthmus', 'RA coronary sinus ostium', ...
            'LA appendage', 'LA right superior anterior wall', 'LA right inferior anterior wall', ...
            'LA left superior anterior wall', 'LA left inferior anterior wall', 'LA left superior posterior wall', ...
            'LA right superior posterior wall', 'LA left inferior posterior wall', 'LA right inferior posterior wall', ...
            'LA left floor posterior wall ', 'LA right floor posterior wall', 'LA mitral isthmus', 'LA ridge', 'LA septal wall', 'RA septal wall', 'RA coronary sinus'};

    elseif length(labelsOriginal) == 24

        % Original labels organized with standarized labels
        labelsOriginal_ordered = {'RA_REGION0', 'RA_REGION05', 'RA_REGION04', 'RA_REGION03', 'RA_REGION02', 'RA_REGION06', 'RA_REGION08', 'Other' , 'LAA', 'LA_REGION09', 'LA_REGION10', 'LA_REGION08', 'LA_REGION04', 'LA_REGION07', ...
            'LA_REGION11', 'LA_REGION06', 'LA_REGION13', 'LA_REGION02', 'LA_REGION03', 'LA_REGION05', 'LA_REGION01', 'LA_REGION12', 'RA_REGION07', 'RA_REGION01'};
        labelsStandardized = {'AUX_STRUCT', 'RA_VEST', 'RA_VECO', 'RA_LW', 'RAA', 'RA_CTI', 'RA_CSOS', 'SEPWL','LAA', 'LA_RSAW', 'LA_RIAW', 'LA_LSAW', 'LA_LIAW', 'LA_LSPW', ...
            'LA_RSPW', 'LA_LIPW', 'LA_RIPW','LA_LFPW', 'LA_RFPW', 'LA_MI', 'LA_RDG', 'LA_SEPWL', 'RA_SEPWL', 'RA_CS'}; 
    
        labelsStandardizedDescription = {'Auxiliar Structures', 'RA vestibule', 'RA venous component', 'RA lateral wall', ...
            'RA appendage', 'RA cavotricuspid isthmus', 'RA coronary sinus ostium', 'Septal wall', ...
            'LA appendage', 'LA right superior anterior wall', 'LA right inferior anterior wall', ...
            'LA left superior anterior wall', 'LA left inferior anterior wall', 'LA left superior posterior wall', ...
            'LA right superior posterior wall', 'LA left inferior posterior wall', 'LA right inferior posterior wall', ...
            'LA left floor posterior wall ', 'LA right floor posterior wall', 'LA mitral isthmus', 'LA ridge', 'LA septal wall', 'RA septal wall', 'RA coronary sinus'};

    end

    % Closed geometry
    faceTypes_closedGeometryOriginal = double(geometry_estimated.Atria.Regions.region0.FaceTypesComplete) + 1; 
    [nodeTypes_closedGeometryStandardized, faceTypes_closedGeometryStandardized] = standardizeLabelsAtria(labelsOriginal, labelsOriginal_ordered, shapeModel.closedGeometry.faces, faceTypes_closedGeometryOriginal, labelsStandardizedDescription); 
    
    % Holey geometry
    faceTypes_holeyGeometryOriginal = double(geometry_estimated.Atria.Regions.region0.FaceTypesHoley) + 1; 
    [nodeTypes_holeyGeometryStandardized, faceTypes_holeyGeometryStandardized, labelsOriginal_description, indices] = standardizeLabelsAtria(labelsOriginal, labelsOriginal_ordered, shapeModel.holeyGeometry.faces, faceTypes_holeyGeometryOriginal, labelsStandardizedDescription); 

    % Caps
    faceTypes_holeyCapsOriginal = double(geometry_estimated.Atria.Regions.region0.FaceTypesCaps) + 1; 


    shapeModel.regions.description = 'Atrial regions'; 
    shapeModel.regions.tags = geometry_estimated.Atria.Regions.region0.Tags; 
    shapeModel.regions.descriptions = geometry_estimated.Atria.Regions.region0.Descriptions; 

    shapeModel.regions.faceTypes.closedGeometryOriginal = faceTypes_closedGeometryOriginal'; 
    shapeModel.regions.faceTypes.closedGeometryStandardized = faceTypes_closedGeometryStandardized; 
    shapeModel.regions.faceTypes.holeyGeometryOriginal = faceTypes_holeyGeometryOriginal'; 
    shapeModel.regions.faceTypes.holeyGeometryStandardized = faceTypes_holeyGeometryStandardized; 
    shapeModel.regions.faceTypes.holeyCapsOriginal = faceTypes_holeyCapsOriginal';
    shapeModel.regions.faceTypes.holeyCapsStandardized = faceTypes_holeyCapsOriginal'; 

    shapeModel.regions.nodeTypes.closedGeometryOriginal = labels_faces2vertices(shapeModel.closedGeometry.faces, shapeModel.regions.faceTypes.closedGeometryOriginal);
    shapeModel.regions.nodeTypes.closedGeometryStandardized = nodeTypes_closedGeometryStandardized; 
    shapeModel.regions.nodeTypes.holeyGeometryOriginal = labels_faces2vertices(shapeModel.holeyGeometry.faces, shapeModel.regions.faceTypes.holeyGeometryOriginal);
    shapeModel.regions.nodeTypes.holeyGeometryStandardized = nodeTypes_holeyGeometryStandardized; 
    shapeModel.regions.nodeTypes.holeyCapsOriginal = []; 
    shapeModel.regions.nodeTypes.holeyCapsStandardized = []; 

    shapeModel.regions.labels.labelsOriginal = labelsOriginal; 
    shapeModel.regions.labels.labelsStandardized = labelsStandardized; 
    shapeModel.regions.labels.labelsOriginalDescription = labelsOriginal_description; 
    shapeModel.regions.labels.labelsStandardizedDescription = labelsStandardizedDescription;

    shapeModel.regions.labels.mappingOriginalToStandardized = indices; 
    shapeModel.regions.keyType = double(geometry_estimated.Atria.Regions.region0.KeyType)+1; 

    
    % Atrial anatomy
    %----------------------------------------------------------------------
    labelsOriginal = readStructWithFields(geometry_estimated.Atria.Anatomy.Tags, 'Atria'); 

    labelsStandardized = {'LA', 'RA', 'LAA', 'Mitral_valve', 'Tricuspid_valve', 'SVC_cover', 'IVC_cover', 'RSPV_cover', 'RIPV_cover', 'LSPV_cover', 'LIPV_cover', 'Atria_cap', 'AtriaZip'}; 
    labelsStandardizedDescription = {'Left Atrium', 'Right Atrium', 'Left Atrial Appendage', 'Mitral Valve', 'Tricuspid Valve', 'Superior Vena Cava cover', 'Inferior Vena Cava cover', ...
        'Right Superior Pulmonary Vein cover', 'Right Inferior Pulmonary Vein cover', 'Left Superior Pulmonary Vein cover', 'Left Inferior Pulmonary Vein cover', 'Mitral and Tricuspid Valves', 'Atrial Septum'}; 

     % Closed geometry
    faceTypes_closedGeometryOriginal = double(geometry_estimated.Atria.Anatomy.FaceTypesComplete) + 1; 
    [nodeTypes_closedGeometryStandardized, faceTypes_closedGeometryStandardized] = standardizeLabelsAtria(labelsOriginal, labelsStandardized, shapeModel.closedGeometry.faces, faceTypes_closedGeometryOriginal, labelsStandardizedDescription); 
    
    % Holey geometry 
    faceTypes_holeyGeometryOriginal = double(geometry_estimated.Atria.Anatomy.FaceTypesHoley) + 1; 
    [nodeTypes_holeyGeometryStandardized, faceTypes_holeyGeometryStandardized, labelsOriginalDescription, indices] = standardizeLabelsAtria(labelsOriginal, labelsStandardized, shapeModel.holeyGeometry.faces, faceTypes_holeyGeometryOriginal, labelsStandardizedDescription); 

    % Caps
    faceTypes_holeyCapsOriginal= double(geometry_estimated.Atria.Anatomy.FaceTypesCaps) + 1;


    shapeModel.anatomy.description = 'Atrial anatomy'; 
    shapeModel.anatomy.tags = geometry_estimated.Atria.Anatomy.Tags; 
    shapeModel.anatomy.descriptions = geometry_estimated.Atria.Anatomy.Descriptions; 

    shapeModel.anatomy.faceTypes.closedGeometryOriginal = faceTypes_closedGeometryOriginal'; 
    shapeModel.anatomy.faceTypes.closedGeometryStandardized = faceTypes_closedGeometryStandardized; 
    shapeModel.anatomy.faceTypes.holeyGeometryOriginal = faceTypes_holeyGeometryOriginal'; 
    shapeModel.anatomy.faceTypes.holeyGeometryStandardized = faceTypes_holeyGeometryStandardized; 
    shapeModel.anatomy.faceTypes.holeyCapsOriginal = faceTypes_holeyCapsOriginal';
    shapeModel.anatomy.faceTypes.holeyCapsStandardized = faceTypes_holeyCapsOriginal'; 

    shapeModel.anatomy.nodeTypes.closedGeometryOriginal = labels_faces2vertices(shapeModel.closedGeometry.faces, shapeModel.anatomy.faceTypes.closedGeometryOriginal);
    shapeModel.anatomy.nodeTypes.closedGeometryStandardized = nodeTypes_closedGeometryStandardized; 
    shapeModel.anatomy.nodeTypes.holeyGeometryOriginal = labels_faces2vertices(shapeModel.holeyGeometry.faces, shapeModel.anatomy.faceTypes.holeyGeometryOriginal);
    shapeModel.anatomy.nodeTypes.holeyGeometryStandardized = nodeTypes_holeyGeometryStandardized;
    shapeModel.anatomy.nodeTypes.holeyCapsOriginal = []; 
    shapeModel.anatomy.nodeTypes.holeyCapsStandardized = []; 

    shapeModel.anatomy.labels.labelsOriginal = labelsOriginal; 
    shapeModel.anatomy.labels.labelsStandardized = labelsStandardized; 
    shapeModel.anatomy.labels.labelsOriginalDescription = labelsOriginalDescription; 
    shapeModel.anatomy.labels.labelsStandardizedDescription = labelsStandardizedDescription;

    shapeModel.anatomy.labels.mappingOriginalToStandardized = indices;
    shapeModel.anatomy.keyType = double(geometry_estimated.Atria.Anatomy.KeyType)+1; 

end 
