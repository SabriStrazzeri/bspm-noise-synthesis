function transferMatrix = parseTransferMatrix(geometry_estimated)
    if ~ strcmp(geometry_estimated.matricesExternal, 'None')
        transferMatrix.atria.personalizedGeometry.transferMatrixComplete = [];    % (no lo devuelve ACORYS)
        transferMatrix.atria.personalizedGeometry.transferMatrixTruncated = reshape(geometry_estimated.matricesExternal.Atria.Values, [geometry_estimated.matricesExternal.Atria.Columns, geometry_estimated.matricesExternal.Atria.Rows]);    % (no lo devuelve ACORYS)
        transferMatrix.atria.personalizedGeometry.method = geometry_estimated.matricesExternal.AtriaMethod; 
    else 
        transferMatrix.atria.personalizedGeometry = []; 
    end 

    if ~ strcmp(geometry_estimated.matricesExternal, 'None')
        transferMatrix.ventricles.personalizedGeometry.transferMatrixComplete = [];    % (no lo devuelve ACORYS)
        transferMatrix.ventricles.personalizedGeometry.transferMatrixTruncated = reshape(geometry_estimated.matricesExternal.Ventricle.Values, [geometry_estimated.matricesExternal.Ventricle.Columns, geometry_estimated.matricesExternal.Ventricle.Rows]);    % (no lo devuelve ACORYS)
        transferMatrix.ventricles.personalizedGeometry.method = geometry_estimated.matricesExternal.VentricleMethod; 
    else 
        transferMatrix.ventricles.personalizedGeometry = []; 
    end  

    transferMatrix.atria.shapeModel.transferMatrixComplete = [];                % (no lo devuelve ACORYS)
    try
        transferMatrix.atria.shapeModel.transferMatrixTruncated = reshape(geometry_estimated.matricesShape.Atria.Values, [geometry_estimated.matricesShape.Atria.Columns, geometry_estimated.matricesShape.Atria.Rows]);
    catch
        transferMatrix.atria.shapeModel.transferMatrixTruncated = []; % a veces el campo values no está
    end
    transferMatrix.atria.shapeModel.method = geometry_estimated.matricesShape.AtriaMethod; 
    
    transferMatrix.ventricles.shapeModel.transferMatrixComplete = [];           % (no lo devuelve ACORYS)
    try
        transferMatrix.ventricles.shapeModel.transferMatrixTruncated = reshape(geometry_estimated.matricesShape.Ventricle.Values, [geometry_estimated.matricesShape.Ventricle.Columns, geometry_estimated.matricesShape.Ventricle.Rows]);
    catch
        transferMatrix.ventricles.shapeModel.transferMatrixTruncated = []; % a veces el campo values no está
    end
    
    transferMatrix.ventricles.shapeModel.method = geometry_estimated.matricesShape.VentricleMethod; 
end 
