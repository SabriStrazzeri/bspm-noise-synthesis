function [nodeTypes_standardized, faceTypes_standardized, labelsOriginal_description, indices] = standardizeLabelsAtria(unorderedLabelsOriginal, labelsOriginal, faces, faceTypes_original, labelsStandardizedDescription)

    if numel(unorderedLabelsOriginal) < numel(labelsOriginal)
        unorderedLabelsOriginal{end+1} = 'Other'; 
        [~, indices] = ismember(unorderedLabelsOriginal, labelsOriginal);
        indices(end) = []; 
    else 
        for i = 1:length(labelsOriginal)
            % Encuentra la posición en unorderedLabelsOriginal que contiene el elemento actual de labelsOriginal
            pos = find(contains(unorderedLabelsOriginal, labelsOriginal{i})); 
            if length(pos) == 1
                indices(i) = pos;
            else
                flag = ismember(unorderedLabelsOriginal, labelsOriginal{i});
                indices(i) = find(flag);
            end
        end
    end 
    
    nodeTypes_original = labels_faces2vertices(faces, faceTypes_original);

    nodeTypes_standardized = zeros(length(nodeTypes_original),1); 
    faceTypes_standardized = zeros(size(faces, 1),1); 
    labelsOriginal_description = cell(1, numel(labelsStandardizedDescription)); 
    for i = 1:length(indices)
        nodeTypes_standardized(nodeTypes_original == indices(i)) = i;
        faceTypes_standardized(faceTypes_original == indices(i)) = i; 
        labelsOriginal_description{indices(i)} = labelsStandardizedDescription{i};  % orgnanized description
    end

end 

