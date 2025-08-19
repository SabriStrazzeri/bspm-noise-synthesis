%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% vertices_labels = labels_faces2vertices(faces, faces_labels)
% Converts the face labels to vertice labels. Starts with the smallest
% group of tag.
% Inputs:
%   faces: triangles or tetrahedra
%   faces_labels: labels of the faces
% Outputs:
%   vertices_labels: labels of the vertices
%
%
%
% 
% Created by: Maria Macarulla Rodriguez
% Last update: 05/2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function vertices_labels = labels_faces2vertices(faces, faces_labels)


narginchk(2,2);
vertices_labels = zeros(max(faces(:)),1);
tags = unique(faces_labels);
counts = zeros(size(tags));
for i = 1:numel(tags)
    counts(i) = sum(faces_labels == tags(i));
end
[~,idx] = sort(counts);
tags = tags(idx); %small number of nodes first

for i = 1:numel(vertices_labels)
    log = any(ismember(faces,i),2);
    tag = unique(faces_labels(log));
    vertices_labels(i) = tags(find(ismember(tags,tag),1));  
end

end