function shapeModel = parseEstimatedVentricles(geometry_estimated)

    % Ventricular auxiliar Structures
    %----------------------------------------------------------------------
    shapeModel.auxiliarStructures.description = 'Cardiac auxiliar structures'; 
    shapeModel.auxiliarStructures.vertices = geometry_estimated.Ventricle.AuxiliarStructures.Vertices.Vertices; 
    shapeModel.auxiliarStructures.faces = double(geometry_estimated.Ventricle.AuxiliarStructures.Faces.Faces) + 1; 
    shapeModel.auxiliarStructures.tags = geometry_estimated.Ventricle.AuxiliarStructures.Tags; 
    shapeModel.auxiliarStructures.descriptions = geometry_estimated.Ventricle.AuxiliarStructures.Descriptions; 
    shapeModel.auxiliarStructures.faceTypes.original = double(geometry_estimated.Ventricle.AuxiliarStructures.FaceTypes) + 1;

    labelsOriginal = readStructWithFields(shapeModel.auxiliarStructures.tags, 'Ventricles'); 
    labelsStandardized = {'LV_endo', 'Septum', 'Aorta'}; 
    labelsStandardizedDescription = {'Left Ventricle endocardium', 'Septum', 'Aorta'}; 
    [nodeTypes_auxStructuresStandardized, faceTypes_auxStructuresStandardized, labelsOriginalDescription, indices] = standardizeLabelsAtria(labelsOriginal, labelsStandardized, shapeModel.auxiliarStructures.faces, shapeModel.auxiliarStructures.faceTypes.original, labelsStandardizedDescription); 
    
    shapeModel.auxiliarStructures.faceTypes.standardized = faceTypes_auxStructuresStandardized'; 
    shapeModel.auxiliarStructures.nodeTypes.original = labels_faces2vertices(shapeModel.auxiliarStructures.faces, shapeModel.auxiliarStructures.faceTypes.original);
    shapeModel.auxiliarStructures.nodeTypes.standardized = nodeTypes_auxStructuresStandardized;
    shapeModel.auxiliarStructures.labels.labelsOriginal = labelsOriginal; 
    shapeModel.auxiliarStructures.labels.labelsStandardized = labelsStandardized; 
    shapeModel.auxiliarStructures.labels.labelsOriginalDescription = labelsOriginalDescription; 
    shapeModel.auxiliarStructures.labels.labelsStandardizedDescription = labelsStandardizedDescription;

    shapeModel.auxiliarStructures.labels.mappingOriginalToStandardized = indices; 
    shapeModel.auxiliarStructures.keyType = geometry_estimated.Ventricle.AuxiliarStructures.KeyType + 1; 
    
    % Ventricular closed geometry
    %----------------------------------------------------------------------
    shapeModel.closedGeometry.description = 'Complete conformal geometry returned by core'; 
    shapeModel.closedGeometry.faces = double(geometry_estimated.Ventricle.ClosedGeometry.Faces.Faces) + 1; 
    shapeModel.closedGeometry.vertices.originalVertices = geometry_estimated.Ventricle.ClosedGeometry.OriginalVertices.Vertices; 
    shapeModel.closedGeometry.vertices.smoothedVertices = geometry_estimated.Ventricle.ClosedGeometry.SmoothedVertices.Vertices; 
    shapeModel.closedGeometry.vertices.movedVertices = geometry_estimated.Ventricle.ClosedGeometry.MovedVertices.Vertices;       % Sale vacío en shape
    shapeModel.closedGeometry.vertices.smoothedAndMovedVertices = geometry_estimated.Ventricle.ClosedGeometry.SmoothedAndMovedVertices.Vertices; 
    
    % Ventricular holey geometry
    %----------------------------------------------------------------------
    shapeModel.holeyGeometry.description = 'Geometry with holes, used for calculation';
    shapeModel.holeyGeometry.faces = double(geometry_estimated.Ventricle.HoleyGeometry.Faces.Faces) + 1; 
    shapeModel.holeyGeometry.vertices.visualVertices = geometry_estimated.Ventricle.HoleyGeometry.VisualVertices.Vertices;  
    shapeModel.holeyGeometry.vertices.smoothedVertices = geometry_estimated.Ventricle.HoleyGeometry.SmoothedVertices.Vertices; 
    shapeModel.holeyGeometry.caps.vertices = geometry_estimated.Ventricle.HoleyGeometry.Caps.Vertices.Vertices; 
    shapeModel.holeyGeometry.caps.faces = double(geometry_estimated.Ventricle.HoleyGeometry.Caps.Faces.Faces) + 1; 
    
    % Ventricular holey to closed
    %----------------------------------------------------------------------
    shapeModel.holeyToClosed.description = 'Relates the indices of the vertices of the holed geometry with the indices of the vertices of the closed geometry';
    shapeModel.holeyToClosed.faces = double(geometry_estimated.Ventricle.MapVectors.HoleyFacesToFilledFaces); 
    shapeModel.holeyToClosed.vertices = double(geometry_estimated.Ventricle.MapVectors.HoleyVerticesToFilledVertices); 
    
    % Ventricular conformal mapping
    %----------------------------------------------------------------------
    shapeModel.conformalMapping.description = 'Variables to conformalize the geometry';
    shapeModel.conformalMapping.mappingConformalVertices = double(geometry_estimated.Ventricle.MappingConformalVertices); 
    shapeModel.conformalMapping.activeVertexForConformal = double(geometry_estimated.Ventricle.ActiveVertexForConformal); 
    shapeModel.conformalMapping.imageSize = geometry_estimated.Ventricle.ImageSizeConformal; 
    
    % Ventricular regions
    %----------------------------------------------------------------------
    labelsOriginal = readStructWithFields(geometry_estimated.Ventricle.Regions.region0.Tags, 'Ventricles'); 

    labelsOriginal_ordered={'LV_ANTERO_BASAL', 'LV_ANTERO_MEDIAL', 'LV_ANTERO_APICAL', 'LV_LATERO_BASAL', 'LV_LATERO_MEDIAL', 'LV_LATERO_APICAL', 'LV_INFERO_BASAL', 'LV_INFERO_MEDIAL', 'LV_INFERO_APICAL', ...
                             'RV_ANTERO_BASAL', 'RV_ANTERO_MEDIAL', 'RV_ANTERO_APICAL', 'RV_INFERO_BASAL', 'RV_INFERO_MEDIAL', 'RV_INFERO_APICAL', 'BASE'}; 
    labelsStandardized ={'LV_ANTERO_BASAL', 'LV_ANTERO_MEDIAL', 'LV_ANTERO_APICAL', 'LV_LATERO_BASAL', 'LV_LATERO_MEDIAL', 'LV_LATERO_APICAL', 'LV_INFERO_BASAL', 'LV_INFERO_MEDIAL', 'LV_INFERO_APICAL', ...
                         'RV_ANTERO_BASAL', 'RV_ANTERO_MEDIAL', 'RV_ANTERO_APICAL', 'RV_INFERO_BASAL', 'RV_INFERO_MEDIAL', 'RV_INFERO_APICAL', 'BASE'}; 

    % Closed geometry
    faceTypes_closedGeometryOriginal = double(geometry_estimated.Ventricle.Regions.region0.FaceTypesComplete) + 1; 
    [nodeTypes_closedGeometryStandardized, faceTypes_closedGeometryStandardized] = standardizeLabelsAtria(labelsOriginal, labelsOriginal_ordered, shapeModel.closedGeometry.faces, faceTypes_closedGeometryOriginal, labelsStandardized); 
    
    % Holey geometry
    faceTypes_holeyGeometryOriginal = double(geometry_estimated.Ventricle.Regions.region0.FaceTypesHoley) + 1; 
    [nodeTypes_holeyGeometryStandardized, faceTypes_holeyGeometryStandardized, labelsOriginal_description, indices] = standardizeLabelsAtria(labelsOriginal, labelsOriginal_ordered, shapeModel.holeyGeometry.faces, faceTypes_holeyGeometryOriginal, labelsStandardized); 

    % Caps
    faceTypes_holeyCapsOriginal = double(geometry_estimated.Ventricle.Regions.region0.FaceTypesCaps) + 1; 


    shapeModel.regions.description = 'Ventricular regions'; 
    shapeModel.regions.tags = geometry_estimated.Ventricle.Regions.region0.Tags; 
    shapeModel.regions.descriptions = geometry_estimated.Ventricle.Regions.region0.Descriptions; 

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
    shapeModel.regions.labels.labelsStandardizedDescription = labelsStandardized;

    shapeModel.regions.labels.mappingOriginalToStandardized = indices; 
    shapeModel.regions.keyType = double(geometry_estimated.Ventricle.Regions.region0.KeyType)+1; 
    
    % Ventricular anatomy
    %----------------------------------------------------------------------
    shapeModel.anatomy.description = 'Ventricular anatomy'; 

    labelsOriginal = readStructWithFields(geometry_estimated.Ventricle.Anatomy.Tags, 'Ventricles'); 
    labelsStandardized = {'RV', 'LV', 'Mitral_valve', 'Tricuspid_valve', 'Pulmonary_valve', 'Ventricle_cap'}; 
    labelsStandardizedDescription = {'Right Ventricle', 'Left Ventricle', 'Mitral Valve', 'Tricuspid Valve', 'Pulmonary Valve', 'Ventricle Cap'}; 

     % Closed geometry
    faceTypes_closedGeometryOriginal = double(geometry_estimated.Ventricle.Anatomy.FaceTypesComplete) + 1; 
    [nodeTypes_closedGeometryStandardized, faceTypes_closedGeometryStandardized] = standardizeLabelsAtria(labelsOriginal, labelsStandardized, shapeModel.closedGeometry.faces, faceTypes_closedGeometryOriginal, labelsStandardizedDescription); 
    
    % Holey geometry 
    faceTypes_holeyGeometryOriginal = double(geometry_estimated.Ventricle.Anatomy.FaceTypesHoley) + 1;
    [nodeTypes_holeyGeometryStandardized, faceTypes_holeyGeometryStandardized, labelsOriginalDescription, indices] = standardizeLabelsAtria(labelsOriginal, labelsStandardized, shapeModel.holeyGeometry.faces, faceTypes_holeyGeometryOriginal, labelsStandardizedDescription); 

    % Caps
    faceTypes_holeyCapsOriginal = double(geometry_estimated.Ventricle.Anatomy.FaceTypesCaps) + 1;


    shapeModel.anatomy.tags = geometry_estimated.Ventricle.Anatomy.Tags; 
    shapeModel.anatomy.descriptions = geometry_estimated.Ventricle.Anatomy.Descriptions; 

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
    shapeModel.anatomy.keyType = double(geometry_estimated.Ventricle.Anatomy.KeyType)+1; 


end
