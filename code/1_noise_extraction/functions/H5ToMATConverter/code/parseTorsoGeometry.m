function torso = parseTorsoGeometry(geometry_estimated)

    % Torso scan
    torso.scan.vertices = geometry_estimated.Torso.Scan.Vertices.Vertices; 
    torso.scan.faces = double(geometry_estimated.Torso.Scan.Faces.Faces) + 1; 
    torso.scan.selectedFaces = double(geometry_estimated.Torso.Scan.SelectedFaces.Faces) + 1; 
    torso.scan.bspmCoord = double(geometry_estimated.Torso.Scan.Bspmcoords) + 1; 
    
    % Torso envelope
    torso.envelope.vertices = geometry_estimated.Torso.Envelope.Vertices.Vertices; 
    torso.envelope.faces = double(geometry_estimated.Torso.Envelope.Faces.Faces) + 1; 
    torso.envelope.bspmCoord = double(geometry_estimated.Torso.Envelope.Bspmcoords) + 1; 
    
    % Torso shape
    torso.shapeModel.vertices = geometry_estimated.Torso.TorsoShape.Vertices.Vertices; 
    torso.shapeModel.faces = double(geometry_estimated.Torso.TorsoShape.Faces.Faces) + 1; 
    torso.shapeModel.tags = geometry_estimated.Torso.TorsoShape.Tags; 
    torso.shapeModel.descriptions = geometry_estimated.Torso.TorsoShape.Descriptions; 
    torso.shapeModel.faceTypes.original = double(geometry_estimated.Torso.TorsoShape.FaceTypes') + 1; 

    labelsOriginal = readStructWithFields(torso.shapeModel.tags); 
    labelsStandardized = {'AXILLA', 'BREAST', 'CLAVICLE', 'NECK', 'SLEEVE', 'SLIP', 'TORSO_back', 'TORSO_front'}; 
    labelsStandardizedDescription = {'AXILLA', 'BREAST', 'CLAVICLE', 'NECK', 'SLEEVE', 'SLIP', 'TORSO_back', 'TORSO_front'}; 
    [nodeTypes_standardized, faceTypes_standardized, labelsOriginalDescription, indices] = standardizeLabelsAtria(labelsOriginal, labelsStandardized, torso.shapeModel.faces, torso.shapeModel.faceTypes.original, labelsStandardizedDescription); 

    torso.shapeModel.faceTypes.standardized = faceTypes_standardized; 

    torso.shapeModel.nodeTypes.original = labels_faces2vertices(torso.shapeModel.faces, torso.shapeModel.faceTypes.original); 
    torso.shapeModel.nodeTypes.standardized = nodeTypes_standardized; 

    torso.shapeModel.labels.labelsOriginal = labelsOriginal; 
    torso.shapeModel.labels.labelsStandardized = labelsStandardized; 
    torso.shapeModel.labels.labelsOriginalDescription = labelsOriginalDescription; 
    torso.shapeModel.labels.labelsStandardizedDescription = labelsStandardizedDescription;
    torso.shapeModel.labels.mappingOriginalToStandardized = indices; 

    torso.shapeModel.faceSide = double(geometry_estimated.Torso.TorsoShape.FaceSide); 
    torso.shapeModel.nodeSide = labels_faces2vertices(torso.shapeModel.faces, torso.shapeModel.faceSide); 
    torso.shapeModel.bspmCoord = double(geometry_estimated.Torso.TorsoShape.Bspmcoords) + 1; 
    torso.shapeModel.keyType = geometry_estimated.Torso.TorsoShape.KeyType + 1; 
    torso.shapeModel.idxMode = geometry_estimated.info.IdxmModes; 
    
    % Rotate to canonical
    torso.rotateToCanonical = reshape(geometry_estimated.Torso.RotateToCanonical, [4,4]);

end
