function personalizedGeometry = parsePersonalizedAtria(geometry_personalized)

    % Atrial auxiliar Structures
    %----------------------------------------------------------------------
    personalizedGeometry.auxiliarStructures.description = 'Cardiac auxiliar structures'; 
    personalizedGeometry.auxiliarStructures = geometry_personalized.atria.Maingeometry.Auxilar;  % VER CÓMO ES EN ESTIMADA 
    personalizedGeometry.auxiliarStructures.mitralValve = geometry_personalized.atria.Maingeometry.Valves.mitralvalve;   % VER CÓMO ES EN ESTIMADA 
    personalizedGeometry.auxiliarStructures.tricuspidValve = geometry_personalized.atria.Maingeometry.Valves.tricuspidvalve;     % VER CÓMO ES EN ESTIMADA 
%         personalizedGeometry.auxiliarStructures.vertices = geometry.Atria.AuxiliarStructures.Vertices.Vertices; 
%         personalizedGeometry.auxiliarStructures.faces = double(geometry.Atria.AuxiliarStructures.Faces.Faces) + 1; 
%         personalizedGeometry.auxiliarStructures.tags = geometry.Atria.AuxiliarStructures.Tags; 
%         personalizedGeometry.auxiliarStructures.descriptions = geometry.Atria.AuxiliarStructures.Descriptions; 
%         personalizedGeometry.auxiliarStructures.faceTypes = double(geometry.Atria.AuxiliarStructures.FaceTypes) + 1; 
%         personalizedGeometry.auxiliarStructures.keyTypes = geometry.Atria.AuxiliarStructures.KeyType; 

    % Atrial closed geometry
    %----------------------------------------------------------------------
    personalizedGeometry.closedGeometry.description = 'Complete conformal geometry returned by core'; 
    personalizedGeometry.closedGeometry.faces = geometry_personalized.atria.FullGeom.Triangles; 
    personalizedGeometry.closedGeometry.vertices.originalVertices = geometry_personalized.atria.FullGeom.Vertices; 
    personalizedGeometry.closedGeometry.vertices.smoothedVertices = []; 
    personalizedGeometry.closedGeometry.vertices.movedVertices = [];       % Sale vacío en shape
    personalizedGeometry.closedGeometry.vertices.smoothedAndMovedVertices = []; 

    % Atrial holey geometry
    %----------------------------------------------------------------------
    personalizedGeometry.holeyGeometry.description = 'Geometry with holes, used for calculation';
    personalizedGeometry.holeyGeometry.faces = geometry_personalized.atria.Maingeometry.Triangles; 
    personalizedGeometry.holeyGeometry.vertices.visualVertices = geometry_personalized.atria.Maingeometry.Vertices;  
    personalizedGeometry.holeyGeometry.vertices.smoothedVertices = geometry_personalized.atria.Maingeometry.SmoothVertices; 
    personalizedGeometry.holeyGeometry.caps.vertices = geometry_personalized.atria.Maingeometry.Covers.Vertices; 
    personalizedGeometry.holeyGeometry.caps.faces = geometry_personalized.atria.Maingeometry.Covers.Triangles; 

    % Atrial holey to closed
    %----------------------------------------------------------------------
    personalizedGeometry.holeyToClosed.description = 'Relates the indices of the vertices of the holed geometry with the indices of the vertices of the closed geometry'; 
    personalizedGeometry.holeyToClosed.faces = []; 
    personalizedGeometry.holeyToClosed.vertices = double(geometry_personalized.atria.FromHoleyToFilledIndex); 

    % Atrial conformal mapping
    %----------------------------------------------------------------------
    personalizedGeometry.conformalMapping.description = 'Variables to conformalize the geometry'; 
    personalizedGeometry.conformalMapping.mappingConformalVertices = geometry_personalized.atria.ImageCorrespondenceConformal; 
    personalizedGeometry.conformalMapping.activeVertexForConformal = double(geometry_personalized.atria.VertexIndexActivity); 
    personalizedGeometry.conformalMapping.imageSize = geometry_personalized.atria.ImageSize; 
    
    % Atrial regions
    %----------------------------------------------------------------------
    labelsOriginal_ordered = {'rtrvl', 'rvest', 'rveco', 'rlwal', 'raapg', 'rctri','rcsos', 'sepwl', 'llapp', 'lspw1', 'lspw2', 'lspw3', 'lspw4', 'lspw5', 'lspw6', 'lspw7', 'lspw8', 'lspw9', 'lspw10', 'lspw11'};
    labelsStandardized = {'RA_TRVL', 'RA_VEST', 'RA_VECO', 'RA_LW', 'RAA', 'RA_CTI', 'RA_CSOS', 'SEPWL','LAA', 'LA_RSAW', 'LA_RIAW', 'LA_LSAW', 'LA_LIAW', 'LA_LSPW', ...
        'LA_RSPW', 'LA_LIPW', 'LA_RIPW','LA_LFPW', 'LA_RFPW', 'LA_MI', 'LA_RDG', 'LA_SEPWL', 'RA_SEPWL', 'RA_CS'}; 

    labelsStandardizedDescription = {'Auxiliar Structures', 'RA vestibule', 'RA venous component', 'RA lateral wall', ...
        'RA appendage', 'RA cavotricuspid isthmus', 'RA coronary sinus ostium', 'Septal wall', ...
        'LA appendage', 'LA right superior anterior wall', 'LA right inferior anterior wall', ...
        'LA left superior anterior wall', 'LA left inferior anterior wall', 'LA left superior posterior wall', ...
        'LA right superior posterior wall', 'LA left inferior posterior wall', 'LA right inferior posterior wall', ...
        'LA left floor posterior wall ', 'LA right floor posterior wall', 'LA mitral isthmus', 'LA ridge', 'RA septal wall', 'LA septal wall', 'RA coronary sinus'};

    labelsOriginal = geometry_personalized.atria.Maingeometry.labels;

    % Holey geometry
    faceTypes_holeyGeometryOriginal = geometry_personalized.atria.Maingeometry.faceTypes + 1; 
    [nodeTypes_holeyGeometryStandardized, faceTypes_holeyGeometryStandardized, labelsOriginal_description, indices] = standardizeLabelsAtria(labelsOriginal, labelsOriginal_ordered, personalizedGeometry.holeyGeometry.faces, faceTypes_holeyGeometryOriginal, labelsStandardizedDescription); 


%     [~, indices] = ismember(labelsOriginal, labelsOriginal_ordered);
% 
%     nodeTypes = geometry_personalized.atria.Maingeometry.nodeTypes + 1;
%     newNodeTypes = zeros(length(nodeTypes),1); 
%     newFaceTypes = zeros(size(personalizedGeometry.holeyGeometry.faces, 1),1);
%     for i = 1:length(labelsOriginal_ordered)
%         newNodeTypes(nodeTypes == i) = indices(i);
%         newFaceTypes(double(geometry_personalized.Atria.Regions.region0.FaceTypesHoley) + 1 == i) = indices(i);
%     end

    personalizedGeometry.regions.description = 'Atrial regions'; 

    personalizedGeometry.regions.faceTypes.closedGeometryOriginal = []; 
    personalizedGeometry.regions.faceTypes.closedGeometryStandardized = [];
    personalizedGeometry.regions.faceTypes.holeyGeometryOriginal = faceTypes_holeyGeometryOriginal; 
    personalizedGeometry.regions.faceTypes.holeyGeometryStandardized = faceTypes_holeyGeometryStandardized; 
    personalizedGeometry.regions.faceTypes.holeyCapsOriginal = [];
    personalizedGeometry.regions.faceTypes.holeyCapsStandardized = [];

    personalizedGeometry.regions.nodeTypes.closedGeometryOriginal = []; 
    personalizedGeometry.regions.nodeTypes.closedGeometryStandardized = [];
    personalizedGeometry.regions.nodeTypes.holeyGeometryOriginal = labels_faces2vertices(personalizedGeometry.holeyGeometry.faces, personalizedGeometry.regions.faceTypes.holeyGeometryOriginal);
    personalizedGeometry.regions.nodeTypes.holeyGeometryStandardized = nodeTypes_holeyGeometryStandardized; 
    personalizedGeometry.regions.nodeTypes.holeyCapsOriginal = [];
    personalizedGeometry.regions.nodeTypes.holeyCapsStandardized = [];

    personalizedGeometry.regions.labels.labelsOriginal = labelsOriginal; 
    personalizedGeometry.regions.labels.labelsStandardized = labelsStandardized; 
    personalizedGeometry.regions.labels.labelsOriginalDescription = labelsOriginal_description; 
    personalizedGeometry.regions.labels.labelsStandardizedDescription = labelsStandardizedDescription;

    personalizedGeometry.regions.labels.mappingOriginalToStandardized = indices; 
    personalizedGeometry.regions.keyType = 1:length(personalizedGeometry.regions.labels.labelsOriginal)+1; 
    
    % Atrial anatomy
    %----------------------------------------------------------------------
    personalizedGeometry.anatomy.description = 'Atrial anatomy';
    personalizedGeometry.anatomy.nodeTypes = []; 
    personalizedGeometry.anatomy.labels = []; 
    personalizedGeometry.anatomy.faceTypes.closedGeometry = []; 
    personalizedGeometry.anatomy.faceTypes.holeyGeometry = []; 
    personalizedGeometry.anatomy.faceTypes.holeyCaps = []; 
    personalizedGeometry.anatomy.keyType = []; 

end 