function  personalizedGeometry = parsePersonalizedVentricle(geometry_personalized)       
        % Ventricular auxiliar Structures
        personalizedGeometry.auxiliarStructures.description = 'Cardiac auxiliar structures'; 
        personalizedGeometry.auxiliarStructures.RVOT = geometry_personalized.ventricles.Maingeometry.Auxilar.RVOT;
    
        % Ventricular closed geometry
        personalizedGeometry.closedGeometry.description = 'Complete conformal geometry returned by core'; 
        personalizedGeometry.closedGeometry.faces = geometry_personalized.ventricles.FullGeom.Triangles; 
        personalizedGeometry.closedGeometry.vertices.originalVertices = geometry_personalized.ventricles.FullGeom.Vertices; 
        personalizedGeometry.closedGeometry.vertices.smoothedVertices = [];  
        personalizedGeometry.closedGeometry.vertices.movedVertices = []; 
        personalizedGeometry.closedGeometry.vertices.smoothedAndMovedVertices = []; 
    
        % Ventricular holey geometry
        personalizedGeometry.holeyGeometry.description = 'Geometry with holes, used for calculation';
        personalizedGeometry.holeyGeometry.faces = geometry_personalized.ventricles.Maingeometry.Triangles;  
        personalizedGeometry.holeyGeometry.vertices.visualVertices = geometry_personalized.ventricles.Maingeometry.Vertices;  
        personalizedGeometry.holeyGeometry.vertices.smoothedVertices = geometry_personalized.ventricles.Maingeometry.SmoothVertices; 
        personalizedGeometry.holeyGeometry.caps.vertices = geometry_personalized.ventricles.Maingeometry.Covers.Vertices; 
        personalizedGeometry.holeyGeometry.caps.faces = geometry_personalized.ventricles.Maingeometry.Covers.Triangles; 
    
        % Ventricular holey to closed
        personalizedGeometry.holeyToClosed.description = 'Relates the indices of the vertices of the holed geometry with the indices of the vertices of the closed geometry';
        personalizedGeometry.holeyToClosed.faces = []; 
        personalizedGeometry.holeyToClosed.vertices = double(geometry_personalized.ventricles.FromHoleyToFilledIndex);  
    
        % Ventricular conformal mapping
        personalizedGeometry.conformalMapping.description = 'Variables to conformalize the geometry';
        personalizedGeometry.conformalMapping.mappingConformalVertices = geometry_personalized.ventricles.ImageCorrespondenceConformal;  
        personalizedGeometry.conformalMapping.activeVertexForConformal = double(geometry_personalized.ventricles.VertexIndexActivity);  
        personalizedGeometry.conformalMapping.imageSize = geometry_personalized.ventricles.ImageSize; 
        
        % Ventricular regions
        labelsOriginal={'LV_ANTERO_BASAL', 'LV_ANTERO_MEDIAL', 'LV_ANTERO_APICAL', 'LV_LATERO_BASAL', 'LV_LATERO_MEDIAL', 'LV_LATERO_APICAL', 'LV_INFERO_BASAL', 'LV_INFERO_MEDIAL', 'LV_INFERO_APICAL', ...
                             'RV_ANTERO_BASAL', 'RV_ANTERO_MEDIAL', 'RV_ANTERO_APICAL', 'RV_INFERO_BASAL', 'RV_INFERO_MEDIAL', 'RV_INFERO_APICAL', ''}; 
        labelsStandardized ={'LV_ANTERO_BASAL', 'LV_ANTERO_MEDIAL', 'LV_ANTERO_APICAL', 'LV_LATERO_BASAL', 'LV_LATERO_MEDIAL', 'LV_LATERO_APICAL', 'LV_INFERO_BASAL', 'LV_INFERO_MEDIAL', 'LV_INFERO_APICAL', ...
                             'RV_ANTERO_BASAL', 'RV_ANTERO_MEDIAL', 'RV_ANTERO_APICAL', 'RV_INFERO_BASAL', 'RV_INFERO_MEDIAL', 'RV_INFERO_APICAL', 'BASE'}; 
        correspondenceTable = table(labelsOriginal(:), labelsStandardized(1:length(labelsOriginal))', 'VariableNames', {'Original', 'Standardized'}); 

        unorderedLabelsOriginal = geometry_personalized.ventricles.Maingeometry.labels;
        [~, indices] = ismember(unorderedLabelsOriginal, labelsOriginal);

        nodeTypes = geometry_personalized.ventricles.Maingeometry.nodeTypes + 1;
        newNodeTypes = zeros(length(nodeTypes),1); 
        newFaceTypes = zeros(size(personalizedGeometry.holeyGeometry.faces, 1),1); 
        for i = 1:length(labelsOriginal)
            newNodeTypes(nodeTypes == i) = indices(i);
            newFaceTypes(double(geometry_personalized.Ventricle.Regions.region0.FaceTypesHoley) + 1 == i) = indices(i);
        end

        personalizedGeometry.regions.description = 'Ventricular regions'; 
        personalizedGeometry.regions.nodeTypes.holeyGeometryOriginal = geometry_personalized.ventricles.Maingeometry.labels; 
        personalizedGeometry.regions.nodeTypes.holeyGeometryStandardized = newNodeTypes; 
        personalizedGeometry.regions.labelsOriginal = labelsOriginal; 
        personalizedGeometry.regions.labelsStandardized = {'LV_ANTERO_BASAL', 'LV_ANTERO_MEDIAL', 'LV_ANTERO_APICAL', 'LV_LATERO_BASAL', 'LV_LATERO_MEDIAL', 'LV_LATERO_APICAL', 'LV_INFERO_BASAL', 'LV_INFERO_MEDIAL', 'LV_INFERO_APICAL', ...
                                                                                             'RV_ANTERO_BASAL', 'RV_ANTERO_MEDIAL', 'RV_ANTERO_APICAL', 'RV_INFERO_BASAL', 'RV_INFERO_MEDIAL', 'RV_INFERO_APICAL', 'BASE'}; 
        personalizedGeometry.regions.labelsStandardizedDescription = {'LV_ANTERO_BASAL', 'LV_ANTERO_MEDIAL', 'LV_ANTERO_APICAL', 'LV_LATERO_BASAL', 'LV_LATERO_MEDIAL', 'LV_LATERO_APICAL', 'LV_INFERO_BASAL', 'LV_INFERO_MEDIAL', 'LV_INFERO_APICAL', ...
                                                                                            'RV_ANTERO_BASAL', 'RV_ANTERO_MEDIAL', 'RV_ANTERO_APICAL', 'RV_INFERO_BASAL', 'RV_INFERO_MEDIAL', 'RV_INFERO_APICAL', 'BASE'}; 
        personalizedGeometry.regions.faceTypes.closedGeometry = []; 
        personalizedGeometry.regions.faceTypes.holeyGeometryOriginal = geometry_personalized.ventricles.Maingeometry.faceTypes + 1; 
        personalizedGeometry.regions.faceTypes.holeyGeometryStandardized = newFaceTypes; 
        personalizedGeometry.regions.faceTypes.holeyCaps = [];
        personalizedGeometry.regions.keyType = 1:length(personalizedGeometry.regions.labelsOriginal); 
        
        % Ventricular anatomy
        personalizedGeometry.anatomy.description = 'Ventricular anatomy';
        personalizedGeometry.anatomy.tags = []; 
        personalizedGeometry.anatomy.descriptions = [];
        personalizedGeometry.anatomy.faceTypes.closedGeometry = [];
        personalizedGeometry.anatomy.faceTypes.holeyGeometry = [];
        personalizedGeometry.anatomy.faceTypes.holeyCaps = [];
        personalizedGeometry.anatomy.keyType = [];

end 